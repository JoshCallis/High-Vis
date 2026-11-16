// MaxBrowser — WKWebView window for the 3ds Max Browser (max_browser/, port 8740).
//
// FusionBrowser's shell, for a Max that runs in Parallels Coherence, full screen on its
// own Space. Differences:
//   • It starts its own server (max_browser/server.py) when nothing answers on 8740 —
//     the Fusion windows' servers live inside Fusion, this one can't live inside Max.
//   • An overlay, not a window: borderless and TRANSPARENT down the left edge of the
//     screen Max is on, so only the rows show over the viewport. Shown only while Max
//     (its Coherence stub, com.parallels.winapp.*, "3ds Max …") or this app is in front;
//     joins every Space so it can sit on Max's full-screen one.
//   • Clicks fall through to Max except over what the page draws: the page posts the
//     rect of its content (`hit` message) and the hover timer flips ignoresMouseEvents.
//   • Hovering onto the rows activates this app (a click must land); hovering back out
//     hands focus back to Max, so Max's keys (the same R/C/D/F) keep working.
// Build: max_browser/MaxBrowserApp/build.sh.

import Cocoa
import WebKit
import CoreGraphics

let PORT = 8740
let URL_STR = "http://127.0.0.1:\(PORT)"
let SERVER = "/Users/josh/Code/Scripts/max_browser/server.py"

let WIDTH: CGFloat = 320               // first launch; then the dragged width (UserDefaults)
let WIDTH_MIN: CGFloat = 220
let WIDTH_KEY = "browserWidth"
// The width grab: an invisible strip at the TOP of the right edge, as on Fusion's dock
// (fusion_dock ResizeHandle) — only the resize cursor shows it. Short, so the rest of
// the right edge stays the viewport's.
let HANDLE_W: CGFloat = 6
let HANDLE_H: CGFloat = 90

final class ResizeHandle: NSView {
    weak var owner: AppDelegate?
    private var startX: CGFloat = 0
    private var startW: CGFloat = 0
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func resetCursorRects() { addCursorRect(bounds, cursor: .resizeLeftRight) }
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for a in trackingAreas { removeTrackingArea(a) }
        addTrackingArea(NSTrackingArea(rect: bounds,
                                       options: [.activeAlways, .mouseEnteredAndExited, .cursorUpdate],
                                       owner: self, userInfo: nil))
    }
    override func cursorUpdate(with event: NSEvent) { NSCursor.resizeLeftRight.set() }
    override func mouseEntered(with event: NSEvent) { NSCursor.resizeLeftRight.set() }
    override func mouseExited(with event: NSEvent)  { if owner?.resizing != true { NSCursor.arrow.set() } }
    override func mouseDown(with event: NSEvent) {
        owner?.resizing = true
        startX = NSEvent.mouseLocation.x
        startW = window?.frame.width ?? 0
        NSCursor.resizeLeftRight.set()
    }
    override func mouseDragged(with event: NSEvent) {
        owner?.setWidth(startW + (NSEvent.mouseLocation.x - startX))
        NSCursor.resizeLeftRight.set()
    }
    override func mouseUp(with event: NSEvent) {
        owner?.resizing = false
        UserDefaults.standard.set(Double(owner?.width ?? WIDTH), forKey: WIDTH_KEY)
    }
}

// Max's Coherence stub app (one per Windows app; Max's is named "3ds Max <year>").
func isMax(_ a: NSRunningApplication?) -> Bool {
    guard let a = a else { return false }
    return (a.bundleIdentifier ?? "").hasPrefix("com.parallels.winapp.")
        && (a.localizedName ?? "").hasPrefix("3ds Max")
}

// Max's stub can be the frontmost app while another desktop is shown (a launch, a
// dialog, Parallels activating it in the background) — and this window joins every
// Space, so it sat over the user's other windows (2026-10-16). Shown only when one of
// Max's windows covers the screen on the Space being shown = Max's full-screen Space.
func maxSpaceShown(_ max: NSRunningApplication) -> Bool {
    guard let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
            as? [[String: Any]], let scr = NSScreen.screens.first?.frame else { return false }
    for d in list where (d[kCGWindowOwnerPID as String] as? pid_t) == max.processIdentifier
                     && (d[kCGWindowLayer as String] as? Int) == 0
                     && ((d[kCGWindowAlpha as String] as? Double) ?? 1) > 0 {
        guard let b = d[kCGWindowBounds as String] as? NSDictionary,
              let r = CGRect(dictionaryRepresentation: b) else { continue }
        if r.width >= scr.width - 2 && r.height >= scr.height - 40 { return true }
    }
    return false
}

// Borderless windows can't take keys by default; the page needs them (rename, ⌘E).
// While the page's right-click menu is up, a clear window over the rest of the screen
// (just under the overlay) takes the next click: it only closes the menu, never reaches Max.
final class CatchView: NSView {
    var onClick: (() -> Void)?
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with event: NSEvent) { onClick?() }
    override func rightMouseDown(with event: NSEvent) { onClick?() }
    override func otherMouseDown(with event: NSEvent) { onClick?() }
}

class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

class AppDelegate: NSObject, NSApplicationDelegate, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
    var window: NSWindow!
    var webView: WKWebView!
    var hoverTimer: Timer!
    var wasInside = false
    var hitRect = CGRect.zero          // the page's content, view coords from the top-left
    var hitAll = false                 // a menu / rename field is open: take every click
    var catcher: NSWindow?             // the screen-wide click catcher while the menu is up
    var maxApp: NSRunningApplication?  // the Max to hand focus back to
    var handle: ResizeHandle!
    var resizing = false               // the width strip is being dragged: keep the mouse
    var width: CGFloat = {
        let w = UserDefaults.standard.double(forKey: WIDTH_KEY)
        return w > 0 ? CGFloat(w) : WIDTH
    }()

    func userContentController(_ c: WKUserContentController, didReceive m: WKScriptMessage) {
        guard let d = m.body as? [String: Any] else { return }
        if let f = d["focus"] as? Bool {
            // A name field opened by a key pressed in Max (New Folder): typing must land
            // here, wherever the pointer is; closed with the pointer away → back to Max.
            if f {
                NSApp.activate(ignoringOtherApps: true)
                window.makeKey()
            } else if NSApp.isActive && !wasInside, let max = maxApp, !max.isTerminated {
                max.activate(options: [])
            }
            return
        }
        if let r = d["rect"] as? [Double], r.count == 4 { hitRect = CGRect(x: pt(r[0]), y: pt(r[1]), width: pt(r[2]), height: pt(r[3])) }
        hitAll = (d["all"] as? Bool) ?? false
        showCatcher((d["menu"] as? Bool) ?? false)
    }

    func showCatcher(_ on: Bool) {
        guard on else { catcher?.orderOut(nil); return }
        guard let s = window.screen ?? NSScreen.main else { return }
        if catcher == nil {
            let c = NSWindow(contentRect: s.frame, styleMask: [.borderless], backing: .buffered, defer: false)
            c.isOpaque = false
            c.backgroundColor = NSColor(white: 0, alpha: 0.004)   // clear, but still hit
            c.hasShadow = false
            c.level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue - 1)
            c.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
            let v = CatchView(frame: NSRect(origin: .zero, size: s.frame.size))
            v.onClick = { [weak self] in
                self?.catcher?.orderOut(nil)
                self?.webView.evaluateJavaScript("window.__dismissMenu && window.__dismissMenu()")
            }
            c.contentView = v
            catcher = c
        }
        catcher!.setFrame(s.frame, display: false)
        catcher!.orderFront(nil)
        window.orderFrontRegardless()
    }

    // Down the left edge of the screen Max is on (the one under the pointer), from just
    // under the menu bar's strip to the bottom — where Fusion's dock starts
    // (fusion_dock menuBarReserve: the bar auto-hides, so visibleFrame reserves nothing,
    // and the window would also sit over the bar's left end when it drops in).
    func place() {
        let mouse = NSEvent.mouseLocation
        guard let s = NSScreen.screens.first(where: { $0.frame.contains(mouse) }) ?? NSScreen.main
        else { return }
        let f = s.frame
        let barH = NSApp.mainMenu?.menuBarHeight ?? NSStatusBar.system.thickness
        let top = max(f.maxY - s.visibleFrame.maxY, barH)
        window.setFrame(NSRect(x: f.minX, y: f.minY, width: width, height: f.height - top), display: true)
        layoutViews()
    }

    // Live from the strip: the left edge stays on the screen's, the right edge follows.
    // The page reflows and posts its new size (`frame`) so Max's panels match.
    func setWidth(_ w: CGFloat) {
        guard let win = window else { return }
        let screen = win.screen ?? NSScreen.main ?? NSScreen.screens.first!
        width = min(max(w.rounded(), WIDTH_MIN), max(WIDTH_MIN, screen.frame.width - 100))
        var f = win.frame
        f.size.width = width
        win.setFrame(f, display: true)
        layoutViews()
    }

    // The page stops short of the strip's column at the top: WKWebView sets the cursor on
    // every move inside it, so overlapping the strip made the arrows flicker (as the dock).
    func layoutViews() {
        guard let c = window.contentView else { return }
        let s = c.bounds.size
        webView.frame = NSRect(x: 0, y: 0, width: max(0, s.width - HANDLE_W), height: s.height)
        handle.frame = NSRect(x: s.width - HANDLE_W, y: s.height - HANDLE_H, width: HANDLE_W, height: HANDLE_H)
    }
    func handleRect() -> CGRect {      // view coords from the top-left, as hitRect
        CGRect(x: window.frame.width - HANDLE_W, y: 0, width: HANDLE_W, height: HANDLE_H)
    }

    func follow(_ front: NSRunningApplication?) {
        if isMax(front), let m = front {
            maxApp = m
            guard maxSpaceShown(m) else {
                window.orderOut(nil)
                catcher?.orderOut(nil)
                return
            }
            if !window.isVisible { place() }
            window.orderFrontRegardless()
        } else if front?.processIdentifier == ProcessInfo.processInfo.processIdentifier {
            // front ourselves (hovered the rows) and the Space flipped away from Max's
            if let m = maxApp, !m.isTerminated, !maxSpaceShown(m) {
                window.orderOut(nil)
                catcher?.orderOut(nil)
            }
        } else {
            window.orderOut(nil)
            catcher?.orderOut(nil)
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        installEditMenu()
        let config = WKWebViewConfiguration()
        config.userContentController.add(self, name: "hit")
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        webView = WKWebView(frame: .zero, configuration: config)
        followUIZoom { [unowned self] in [self.webView] }   // WindowShell § UI zoom
        webView.allowsBackForwardNavigationGestures = false
        webView.allowsMagnification = false
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.setValue(false, forKey: "drawsBackground")
        if #available(macOS 12.0, *) { webView.underPageBackgroundColor = .clear }

        window = OverlayWindow(contentRect: NSRect(x: 0, y: 0, width: width, height: 760),
                               styleMask: [.borderless], backing: .buffered, defer: false)
        window.title = "Max Browser"
        let container = NSView(frame: NSRect(x: 0, y: 0, width: width, height: 760))
        container.addSubview(webView)
        handle = ResizeHandle(frame: .zero)      // added last → on top of the page
        handle.owner = self
        container.addSubview(handle)
        window.contentView = container
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        window.ignoresMouseEvents = true
        follow(NSWorkspace.shared.frontmostApplication)
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main) { [weak self] n in
            self?.follow(n.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)
        }
        // A Space flip with Max still frontmost sends no activation: re-check, after the
        // new Space's windows are on screen (and once more for the full-screen slide).
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
            for ms in [80, 700] {
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(ms)) {
                    self?.follow(NSWorkspace.shared.frontmostApplication)
                }
            }
        }
        // Backstop: Max's window can come and go (launch veil, leaving full screen)
        // without either notification.
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let m = self.maxApp, !m.isTerminated else { return }
            let front = NSWorkspace.shared.frontmostApplication
            if front?.processIdentifier == m.processIdentifier, self.window.isVisible != maxSpaceShown(m) {
                self.follow(m)
            } else if front?.processIdentifier == ProcessInfo.processInfo.processIdentifier, self.window.isVisible {
                self.follow(front)
            }
        }
        startServerIfNeeded()
        tryLoad()

        hoverTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            guard let self = self, let w = self.window, w.isVisible else { return }
            let m = NSEvent.mouseLocation
            let p = CGPoint(x: m.x - w.frame.minX, y: w.frame.maxY - m.y)
            let inside = self.resizing || (w.frame.contains(m) &&
                (self.hitAll || self.hitRect.contains(p) || self.handleRect().contains(p)))
            defer { self.wasInside = inside }
            if w.ignoresMouseEvents == inside { w.ignoresMouseEvents = !inside }
            guard !windowState().menuOpen else { return }
            if inside && !NSApp.isActive {
                NSApp.activate(ignoringOtherApps: true)
                w.makeKey()
            } else if !inside && self.wasInside && NSApp.isActive && !self.hitAll,
                      let max = self.maxApp, !max.isTerminated {
                max.activate(options: [])
            }
        }

        // WebKit swallows ⌘E ("Use Selection for Find") and ⌘R reloads: hand both to the page.
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, event.modifierFlags.contains(.command) else { return event }
            switch event.charactersIgnoringModifiers?.lowercased() ?? "" {
            case "e": self.webView.evaluateJavaScript("window.__toggleVis && window.__toggleVis()"); return nil
            case "r": self.webView.evaluateJavaScript("window.__rename && window.__rename()"); return nil
            default: return event
            }
        }
    }

    func startServerIfNeeded() {
        guard let url = URL(string: "\(URL_STR)/health") else { return }
        let req = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 1)
        URLSession.shared.dataTask(with: req) { _, resp, _ in
            guard (resp as? HTTPURLResponse)?.statusCode != 200 else { return }
            let p = Process()
            p.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
            p.arguments = [SERVER]
            p.standardOutput = FileHandle.nullDevice
            p.standardError = FileHandle.nullDevice
            try? p.run()        // left running when this window quits: it's cheap and stateless
        }.resume()
    }

    func tryLoad() {
        guard let url = URL(string: URL_STR) else { return }
        var req = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 2)
        req.httpMethod = "GET"
        URLSession.shared.dataTask(with: req) { [weak self] _, resp, _ in
            DispatchQueue.main.async {
                if let r = resp as? HTTPURLResponse, r.statusCode == 200 {
                    self?.webView.load(URLRequest(url: url))
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self?.tryLoad() }
                }
            }
        }.resume()
    }

    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(action.request.url?.host == "127.0.0.1" ? .allow : .cancel)
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in self?.tryLoad() }
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation nav: WKNavigation!, withError error: Error) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in self?.tryLoad() }
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        jsAlert(message, on: window, completionHandler)
    }
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        jsConfirm(message, on: window, completionHandler)
    }
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String,
                 defaultText: String?, initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (String?) -> Void) {
        jsPrompt(prompt, defaultText: defaultText, on: window, completionHandler)
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply { exit(0) }
}

for sig in [SIGTERM, SIGINT, SIGHUP, SIGSEGV, SIGBUS, SIGILL, SIGABRT, SIGTRAP, SIGFPE] {
    signal(sig) { _ in _exit(0) }
}

letHeldKeysRepeat()
let app = NSApplication.shared
app.setActivationPolicy(.accessory)   // no Dock icon / ⌘Tab: it belongs to Max
let delegate = AppDelegate()
app.delegate = delegate
app.run()
