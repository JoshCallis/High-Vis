// winlink.cs -- the Windows end of max/winlink (see README.md there).
//
// A windowless process in the user's desktop session (HKCU Run). It dials OUT to the
// Mac -- winlink.py on 10.211.55.2:27121, outbound so Windows' firewall needs no rule
// -- and keeps one line-based TCP connection:
//   -> Mac  "text 0|1"        keyboard focus left / entered a text field (UIA)
//   -> Mac  "dialog 0|1"      a modal dialog is (no longer) the foreground window
//   -> Mac  "re <id> <what>"  the answer to a command
//   <- Mac  "<id> explorer"   raise the frontmost File Explorer window, or open one
//   <- Mac  "<id> button N"   press the foreground dialog's Nth button from the left
//   <- Mac  "<id> ping"
// Never TOPMOST: Parallels answers a topmost Windows window by pinning its Mac window
// to every (non-full-screen) Mac desktop and never undoes it. Explorer's float is all
// on the Mac side (coherence_home.py --explorer).
//
// ASCII only: install.ps1 compiles it with the in-box csc (.NET Framework 4, C# 5).
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Net.Sockets;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using System.Windows.Automation;
using System.Windows.Forms;

static class WinLink
{
    const string HOST = "10.211.55.2";
    const int PORT = 27121;
    const string EXPLORER_CLASS = "CabinetWClass";

    static readonly object sendLock = new object();
    static StreamWriter writer;
    static int lastText = -1;
    static int lastDialog = -1;
    static Control ui;                  // owns the UI thread: foreground calls

    [STAThread]
    static void Main()
    {
        bool fresh;
        var single = new Mutex(true, "Local\\CallisWinLink", out fresh);
        if (!fresh) return;
        ui = new Control();
        ui.CreateControl();
        // UIA events off the UI thread (MTA), as UIA asks of a client with a window.
        var t = new Thread(() => Automation.AddAutomationFocusChangedEventHandler(OnFocus));
        t.SetApartmentState(ApartmentState.MTA);
        t.Start();
        new Thread(NetLoop) { IsBackground = true }.Start();
        // The dialog flag is a foreground check (plain Win32, no UIA): polled, as a
        // dialog can open or close without a focus event reaching us.
        var poll = new System.Windows.Forms.Timer { Interval = 150 };
        poll.Tick += (s, e) => CheckDialog();
        poll.Start();
        Application.Run();
        GC.KeepAlive(single);
    }

    // -- the text-field flag ------------------------------------------------------
    // What Karabiner's `vm_text_field` variable says: typing goes into a field, so
    // Explorer's letter keys (A deselect, D back, F open...) must stand aside.
    static void OnFocus(object sender, AutomationFocusChangedEventArgs e)
    {
        int text = 0;
        try
        {
            var el = sender as AutomationElement;
            if (el != null && IsText(el)) text = 1;
        }
        catch (Exception) { }           // gone mid-read (ElementNotAvailable)
        lock (sendLock)
        {
            if (text == lastText) return;
            lastText = text;
        }
        Send("text " + text);
    }

    static bool IsText(AutomationElement el)
    {
        var ct = el.Current.ControlType;
        if (ct != ControlType.Edit && ct != ControlType.Document && ct != ControlType.ComboBox)
            return false;
        object p;
        if (el.TryGetCurrentPattern(ValuePattern.Pattern, out p))
            return !((ValuePattern)p).Current.IsReadOnly;
        return ct == ControlType.Edit;
    }

    // -- the dialog flag ----------------------------------------------------------
    // Karabiner's `vm_dialog`: a modal dialog is in front (Save changes? / Yes No
    // Cancel), so D / F are Left / Right between its buttons (remap bindings.json,
    // "dialog": true). Modal = the classic dialog class #32770, or a window whose
    // owner is disabled -- how Win32 and Qt (3ds Max) both make a dialog modal.
    static void CheckDialog()
    {
        int d = 0;
        try
        {
            IntPtr w = GetForegroundWindow();
            if (w != IntPtr.Zero)
            {
                IntPtr owner = GetWindow(w, GW_OWNER);
                if (ClassOf(w) == "#32770" || (owner != IntPtr.Zero && !IsWindowEnabled(owner))) d = 1;
            }
        }
        catch (Exception) { }
        lock (sendLock)
        {
            if (d == lastDialog) return;
            lastDialog = d;
        }
        Send("dialog " + d);
    }

    // "button N": press the Nth button from the left of the foreground dialog's bottom
    // row (D = 0, F = 1 -- remap bindings.json vm.dialog.*). The bottom row, so a
    // Browse... button above it never counts; title-bar buttons never do. A Win32
    // button gets BM_CLICK (UIA Invoke is refused on some, e.g. Max's Image I/O
    // Error), anything else (Qt, TaskDialog) UIA Invoke.
    static string DialogButton(int n)
    {
        IntPtr w = GetForegroundWindow();
        IntPtr owner = GetWindow(w, GW_OWNER);
        if (w == IntPtr.Zero || !(ClassOf(w) == "#32770" || (owner != IntPtr.Zero && !IsWindowEnabled(owner))))
            return "no dialog";
        var root = AutomationElement.FromHandle(w);
        var all = root.FindAll(TreeScope.Descendants,
            new PropertyCondition(AutomationElement.ControlTypeProperty, ControlType.Button));
        var btns = new List<AutomationElement>();
        var walker = TreeWalker.ControlViewWalker;
        foreach (AutomationElement b in all)
        {
            try
            {
                var c = b.Current;
                if (c.IsOffscreen || !c.IsEnabled || c.BoundingRectangle.IsEmpty) continue;
                var p = walker.GetParent(b);
                if (p != null && p.Current.ControlType == ControlType.TitleBar) continue;
                btns.Add(b);
            }
            catch (Exception) { }
        }
        if (btns.Count == 0) return "no buttons";
        double bottom = 0;
        foreach (var b in btns) bottom = Math.Max(bottom, b.Current.BoundingRectangle.Bottom);
        var row = btns.FindAll(b => b.Current.BoundingRectangle.Bottom > bottom - b.Current.BoundingRectangle.Height / 2);
        row.Sort((a, b) => a.Current.BoundingRectangle.Left.CompareTo(b.Current.BoundingRectangle.Left));
        if (n >= row.Count) return "only " + row.Count;
        var t = row[n];
        string name = t.Current.Name;
        var h = new IntPtr(t.Current.NativeWindowHandle);
        if (h != IntPtr.Zero && ClassOf(h) == "Button") PostMessage(h, BM_CLICK, IntPtr.Zero, IntPtr.Zero);
        else
        {
            object ip;
            if (!t.TryGetCurrentPattern(InvokePattern.Pattern, out ip)) return "not invokable " + name;
            ((InvokePattern)ip).Invoke();
        }
        return "pressed " + name;
    }

    // -- the link -----------------------------------------------------------------
    static void NetLoop()
    {
        while (true)
        {
            try
            {
                using (var c = new TcpClient())
                {
                    c.NoDelay = true;
                    c.Connect(HOST, PORT);
                    var s = c.GetStream();
                    var r = new StreamReader(s, new UTF8Encoding(false));
                    lock (sendLock)
                    {
                        writer = new StreamWriter(s, new UTF8Encoding(false));
                        writer.NewLine = "\n";
                        writer.AutoFlush = true;
                    }
                    Send("hello " + Environment.UserName);
                    if (lastText >= 0) Send("text " + lastText);
                    if (lastDialog >= 0) Send("dialog " + lastDialog);
                    string line;
                    while ((line = r.ReadLine()) != null) Handle(line.Trim());
                }
            }
            catch (Exception) { }
            lock (sendLock) { writer = null; }
            Thread.Sleep(2000);
        }
    }

    static void Send(string line)
    {
        lock (sendLock)
        {
            if (writer == null) return;
            try { writer.WriteLine(line); }
            catch (Exception) { writer = null; }
        }
    }

    static void Handle(string line)
    {
        var parts = line.Split(new[] { ' ' }, 2);
        if (parts.Length < 2) return;
        string res;
        try
        {
            if (parts[1] == "explorer") res = Explorer();
            else if (parts[1].StartsWith("button ")) res = DialogButton(int.Parse(parts[1].Substring(7)));
            else if (parts[1] == "ping") res = "pong";
            else res = "unknown";
        }
        catch (Exception ex) { res = "error " + ex.GetType().Name; }
        Send("re " + parts[0] + " " + res);
    }

    // -- File Explorer --------------------------------------------------------------
    // The frontmost Explorer window comes forward (restored if minimised); with none
    // open, explorer.exe opens one (Home) and we wait for it. Waits run on the link
    // thread; only the foreground call is made on the UI thread.
    static string Explorer()
    {
        var wins = ExplorerWindows();
        string how = "raised";
        IntPtr w = wins.Count > 0 ? wins[0] : IntPtr.Zero;
        if (w == IntPtr.Zero)
        {
            how = "opened";
            Process.Start("explorer.exe");
            for (int i = 0; i < 80 && w == IntPtr.Zero; i++)
            {
                Thread.Sleep(50);
                wins = ExplorerWindows();
                if (wins.Count > 0) w = wins[0];
            }
            if (w == IntPtr.Zero) return "timeout";
        }
        ui.Invoke(new Action(() => Front(w)));
        return how + " " + w.ToInt64();
    }

    static void Front(IntPtr w)
    {
        if (IsIconic(w)) ShowWindow(w, SW_RESTORE);
        // Windows refuses SetForegroundWindow to a background process unless it shares
        // the foreground thread's input state for the moment.
        uint pid;
        uint fgThread = GetWindowThreadProcessId(GetForegroundWindow(), out pid);
        uint me = GetCurrentThreadId();
        bool attached = fgThread != 0 && fgThread != me && AttachThreadInput(me, fgThread, true);
        BringWindowToTop(w);
        SetForegroundWindow(w);
        if (attached) AttachThreadInput(me, fgThread, false);
    }

    static List<IntPtr> ExplorerWindows()       // visible, top of the z-order first
    {
        var o = new List<IntPtr>();
        EnumWindows((h, l) =>
        {
            if (IsWindowVisible(h) && ClassOf(h) == EXPLORER_CLASS) o.Add(h);
            return true;
        }, IntPtr.Zero);
        return o;
    }

    static string ClassOf(IntPtr h)
    {
        var sb = new StringBuilder(64);
        GetClassName(h, sb, sb.Capacity);
        return sb.ToString();
    }

    // -- Win32 ------------------------------------------------------------------------
    const int SW_RESTORE = 9;
    const uint GW_OWNER = 4;
    const uint BM_CLICK = 0x00F5;

    delegate bool EnumWindowsProc(IntPtr h, IntPtr l);

    [DllImport("user32.dll")] static extern bool EnumWindows(EnumWindowsProc f, IntPtr l);
    [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] static extern bool IsIconic(IntPtr h);
    [DllImport("user32.dll")] static extern bool ShowWindow(IntPtr h, int cmd);
    [DllImport("user32.dll")] static extern bool BringWindowToTop(IntPtr h);
    [DllImport("user32.dll")] static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] static extern IntPtr GetWindow(IntPtr h, uint cmd);
    [DllImport("user32.dll")] static extern bool IsWindowEnabled(IntPtr h);
    [DllImport("user32.dll")] static extern bool PostMessage(IntPtr h, uint msg, IntPtr w, IntPtr l);
    [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
    [DllImport("user32.dll")] static extern bool AttachThreadInput(uint a, uint b, bool attach);
    [DllImport("kernel32.dll")] static extern uint GetCurrentThreadId();
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetClassName(IntPtr h, StringBuilder s, int n);
}
