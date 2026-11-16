// Max Browser — draws what 3ds Max publishes (max/callis/browser.py) and posts what
// you click or type back to it. Holds no state of its own beyond an open rename
// field and menu: the tree, where you are, what's open and the cursor are all Max's,
// so the same keys work identically in Max's viewport and here.
"use strict";

let snap = null;          // the last snapshot from /wait
let renaming = null;      // token whose name is being edited
let seenRename = null;    // the last snapshot's rename request number (null: none seen yet)
let seenARename = null;   // the same for Appearances
const tree = document.getElementById("tree");
const appear = document.getElementById("appear");
const ctx = document.getElementById("ctx");
const pdrop = document.getElementById("pdrop");   // an open drop-down setting's choices
const msg = document.getElementById("msg");

// ── Talking to Max ──────────────────────────────────────────────────────────
async function poll() {
  for (;;) {
    try {
      const r = await fetch("/wait?t=" + (snap && snap.t || 0));
      const s = await r.json();
      if (!s.waiting) {
        snap = s;
        // New Folder asks for a name field (one per request — `n` — never replayed on load)
        const rn = s.rename;
        if (rn && seenRename !== null && rn.n !== seenRename) { renaming = rn.tok; focusShell(true); }
        seenRename = rn ? rn.n : 0;
        // …and so do Appearances' New Group / Rename (callis/appearance.py)
        const an = s.appear && s.appear.rename;
        if (an && seenARename !== null && an.n !== seenARename) { renaming = an.tok; focusShell(true); }
        seenARename = an ? an.n : 0;
        if ((!drag || !drag.on) && (!adrag || !adrag.on)) render();
      }
    } catch (e) {
      await new Promise(res => setTimeout(res, 1000));
    }
  }
}
async function act(a) {
  try {
    const r = await fetch("/act", { method: "POST", headers: { "Content-Type": "application/json" },
                                    body: JSON.stringify(a) });
    const j = await r.json();
    if (!j.ok) flash(j.error);
  } catch (e) { flash(String(e)); }
}
// The shell (MaxBrowserApp) takes the keyboard for a name field opened from Max, and
// hands it back after.
function focusShell(on) {
  const h = window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.hit;
  if (h) h.postMessage({ focus: on });
}
function flash(text) {
  msg.textContent = String(text || "").split("\n").filter(Boolean).pop() || "";
  msg.hidden = false;
  clearTimeout(flash.t);
  flash.t = setTimeout(() => { msg.hidden = true; }, 4000);
}

// ── Drawing ─────────────────────────────────────────────────────────────────
function el(tag, cls, text) {
  const e = document.createElement(tag);
  if (cls) e.className = cls;
  if (text != null) e.textContent = text;
  return e;
}

function render() {
  if (!snap) return;
  redrawing = true;
  tree.textContent = "";
  appear.textContent = "";
  redrawing = false;
  appear.hidden = true;
  pdrop.hidden = true;
  if (snap.away) { hideMenu(); return; }   // a Max panel has our place (callis/side.py)
  if (snap.panel) { if (!ctx.dataset.panel) hideMenu(); renderPanel(snap.panel); return; }
  if (snap.appear) renderAppear(snap.appear);
  if (snap.error) { tree.appendChild(el("div", "card err", snap.error)); return; }
  if (!snap.rows.length) return;            // nothing in it: draw nothing
  for (const r of snap.rows) tree.appendChild(drawRow(r));
  const cur = tree.querySelector(".row.cursor");
  if (cur) cur.scrollIntoView({ block: "nearest" });
}

// Fusion's Browser rows (fusion_browser/index.js render()): no twirls — a click opens
// a thing — the same indent, and "(Name)" for a folder or group with nothing in it.
function drawRow(r) {
  const row = el("div", "row");
  row.dataset.kind = r.kind;
  row.dataset.tok = r.tok;
  row.style.paddingLeft = (10 + r.depth * 17) + "px";
  if (r.tok === snap.cursor) row.classList.add("cursor");
  if (r.sel) row.classList.add("sel");
  if (r.hidden) row.classList.add("hidden");
  if (r.dim) row.classList.add("dim");
  if (r.frozen) row.classList.add("frozen");
  if (r.off) row.classList.add("off");
  if (r.cut) row.classList.add("cut");

  if (renaming === r.tok) {
    const inp = el("input", "rename");
    inp.value = r.name;
    inp.onkeydown = e => {
      e.stopPropagation();
      if (e.key === "Enter") { renaming = null; focusShell(false); act({ op: "rename", tok: r.tok, name: inp.value }); }
      if (e.key === "Escape") { renaming = null; focusShell(false); render(); }
    };
    inp.onblur = () => { if (renaming === r.tok) { renaming = null; render(); } };
    row.appendChild(inp);
    setTimeout(() => { inp.focus(); inp.select(); }, 0);
    return row;
  }

  row.appendChild(el("span", "name", r.empty ? "(" + r.name + ")" : r.name));

  row.onclick = e => {
    if (justDragged) { justDragged = false; return; }
    // ⌘ add/remove, ⇧ range, Option = Space held (remapd adds it) select only.
    act({ op: "click", tok: r.tok, meta: e.metaKey, shift: e.shiftKey, alt: e.altKey });
  };
  row.onmousedown = e => {
    if (e.button === 0 && r.kind !== "mod" && r.kind !== "base") drag = { r, x: e.clientX, y: e.clientY, on: false };
  };
  row.oncontextmenu = e => { e.preventDefault(); showMenu(r, e.clientX, e.clientY); };
  return row;
}

// ── A settings panel in the tree's place (callis/panel.py) ──────────────────
// Shot camera / sun / a modifier's settings: Max holds the rows, the cursor and what's
// open; the same keys drive it (R/C, F in, D out). An open drop-down lists its choices
// under its row; an open number is a text field (Enter / F commit, Esc / D cancel).
let panelEdit = 0;        // the last number field opened (snap.panel.edit)
let panelText = null;     // what's typed in it so far (kept across redraws)
let redrawing = false;    // a redraw removes the field: that blur isn't a cancel
let panelRename = null;   // the head whose name field is open (a section name)
let seenPanelRename = 0;  // the last p.rename.n acted on
function renderPanel(p) {
  // The title (the camera's name) is the parent row: only with Show Parent ticked.
  const base = p.parent ? 27 : 10;
  if (p.parent) {
    const head = el("div", "row ptitle");
    head.style.paddingLeft = "10px";
    head.appendChild(el("span", "name", p.title));
    tree.appendChild(head);
  }
  if (!p.rows.length) { tree.appendChild(el("div", "empty", "Nothing to adjust")); return; }
  if (p.rename && p.rename.n !== seenPanelRename) {
    seenPanelRename = p.rename.n; panelRename = p.rename.h; focusShell(true);
  }
  let input = null, dropRow = null;
  const opening = p.edit && p.edit !== panelEdit;
  panelEdit = p.edit;
  if (opening || !p.edit) panelText = null;
  for (const r of p.rows) {
    if (r.h !== undefined) { tree.appendChild(drawHead(r, base)); continue; }
    const row = el("div", "row prow");
    row.style.paddingLeft = (base + 17) + "px";
    row.dataset.kind = r.kind;
    if (r.cursor) row.classList.add("cursor");
    if (r.open) row.classList.add("open");
    row.appendChild(el("span", "name plabel", r.label));
    if (r.open && p.edit && (r.kind === "int" || r.kind === "float")) {
      input = el("input", "rename pinput");
      input.value = panelText !== null ? panelText : r.num;
      input.oninput = () => { panelText = input.value; };
      input.onkeydown = e => {
        e.stopPropagation();
        const k = e.key;
        if (k === "Enter" || k === "f" || k === "F") {
          e.preventDefault(); focusShell(false); act({ op: "panel", set: input.value });
        } else if (k === "Escape" || k === "d" || k === "D") {
          e.preventDefault(); focusShell(false); act({ op: "panel", cancel: true });
        }
      };
      input.onblur = () => {
        if (!redrawing && snap.panel && snap.panel.edit) { focusShell(false); act({ op: "panel", cancel: true }); }
      };
      row.appendChild(input);
    } else {
      const v = r.kind === "bool" ? (r.value ? "On" : "Off") : r.text;
      const val = el("span", "name pval", v);
      if (r.kind === "bool" && !r.value) val.classList.add("offval");
      row.appendChild(val);
    }
    row.onclick = () => act({ op: "panel", i: r.i });
    tree.appendChild(row);
    if (r.open && r.choices) dropRow = [row, r];
  }
  // A drop-down setting is one row: open, its choices drop down under the value.
  if (dropRow) openDrop(...dropRow);
  if (input) {
    if (opening) focusShell(true);
    const typed = panelText !== null;
    setTimeout(() => { input.focus(); if (!typed) input.select(); }, 0);
  }
  const cur = tree.querySelector(".row.cursor");
  if (cur) cur.scrollIntoView({ block: "nearest" });
}

function openDrop(row, r) {
  pdrop.textContent = "";
  r.choices.forEach((c, k) => {
    const it = el("div", "facetitem" + (k === r.pick ? " cur" : ""), c);
    it.onclick = e => { e.stopPropagation(); act({ op: "panel", i: r.i, choice: k }); };
    pdrop.appendChild(it);
  });
  pdrop.hidden = false;
  const v = (row.querySelector(".pval") || row).getBoundingClientRect();
  pdrop.style.left = Math.max(4, Math.min(v.right - pdrop.offsetWidth, innerWidth - pdrop.offsetWidth - 4)) + "px";
  pdrop.style.top = Math.max(4, Math.min(v.bottom + 2, innerHeight - pdrop.offsetHeight - 6)) + "px";
  const cur = pdrop.querySelector(".cur");
  if (cur) cur.scrollIntoView({ block: "nearest" });
}
// A click off an open drop-down and off every row (its own row shuts it, another row's
// click closes it Max-side) cancels it.
document.addEventListener("mousedown", e => {
  if (pdrop.hidden || pdrop.contains(e.target) || e.button !== 0) return;
  if (e.target.closest && e.target.closest(".row")) return;
  act({ op: "panel", cancel: true });
});

// A section head = a Browser group: a click opens / shuts it, Space / ⌘ / ⇧ clicks pick
// it, ⌃R in Max (or the menu's Rename) renames it. Max keeps which are shut and their names.
function drawHead(r, base) {
  const row = el("div", "row psec");
  row.style.paddingLeft = base + "px";
  if (r.cursor) row.classList.add("cursor");
  if (r.pick) row.classList.add("sel");
  if (panelRename === r.h) {
    const inp = el("input", "rename");
    inp.value = r.name;
    const done = msg => { panelRename = null; focusShell(false); act(Object.assign({ op: "panel", h: r.h }, msg)); };
    inp.onkeydown = e => {
      e.stopPropagation();
      if (e.key === "Enter") done({ name: inp.value });
      if (e.key === "Escape") done({ renamed: true });
    };
    inp.onblur = () => { if (!redrawing && panelRename === r.h) done({ renamed: true }); };
    row.appendChild(inp);
    setTimeout(() => { inp.focus(); inp.select(); }, 0);
    return row;
  }
  row.appendChild(el("span", "name", r.name));
  row.onclick = e => act({ op: "panel", h: r.h, meta: e.metaKey, shift: e.shiftKey, alt: e.altKey });
  row.oncontextmenu = e => {
    e.preventDefault();
    showPanelMenu(e.clientX, e.clientY, () => { panelRename = r.h; focusShell(true); render(); });
  };
  return row;
}

// ── Appearances (callis/appearance.py) ──────────────────────────────────────
// Fusion's Appearance panel above the tree: In This Model, then the shared libraries.
// Max holds where you are and the cursor; the Browser's keys drive whichever section has
// the focus (snap.appear.focus). A swatch per material; a model material names the
// libraries it's stored in.
function renderAppear(a) {
  appear.hidden = false;
  appear.classList.toggle("focus", !!a.focus);
  if (a.error) { appear.appendChild(el("div", "card err", a.error)); return; }
  for (const r of a.rows) appear.appendChild(drawARow(r, a));
  appear.appendChild(el("div", "asep"));
  const cur = appear.querySelector(".row.cursor");
  if (cur) cur.scrollIntoView({ block: "nearest" });
}
function drawARow(r, a) {
  const row = el("div", "row arow");
  row.dataset.kind = r.kind;
  row.dataset.tok = r.tok;
  row.style.paddingLeft = (10 + r.depth * 17) + "px";
  if (r.tok === a.cursor) row.classList.add(a.focus ? "cursor" : "acur");
  if (r.sel) row.classList.add("sel");
  if (r.cut) row.classList.add("cut");
  if (r.unused) row.classList.add("unused");
  if (r.kind === "amat") {
    const sw = r.sw ? el("img", "sw") : el("span", "sw none");
    if (r.sw) { sw.src = r.sw; sw.draggable = false; }
    row.appendChild(sw);
  }
  if (renaming === r.tok) {
    const inp = el("input", "rename");
    inp.value = r.name;
    inp.onkeydown = e => {
      e.stopPropagation();
      if (e.key === "Enter") { renaming = null; focusShell(false); act({ op: "rename", tok: r.tok, name: inp.value }); }
      if (e.key === "Escape") { renaming = null; focusShell(false); render(); }
    };
    inp.onblur = () => { if (renaming === r.tok && !redrawing) { renaming = null; render(); } };
    row.appendChild(inp);
    setTimeout(() => { inp.focus(); inp.select(); }, 0);
    return row;
  }
  row.appendChild(el("span", "name", r.empty ? "(" + r.name + ")" : r.name));
  if (r.libs && r.libs.length) row.appendChild(el("span", "libs", r.libs.join(", ")));
  row.onclick = e => {
    if (justDragged) { justDragged = false; return; }
    act({ op: "click", tok: r.tok, meta: e.metaKey, shift: e.shiftKey, alt: e.altKey });
  };
  row.ondblclick = () => { if (r.kind === "amat") act({ op: "slate", tok: r.tok }); };
  row.onmousedown = e => {
    if (e.button === 0 && !r.root && r.kind !== "amodel") adrag = { r, x: e.clientX, y: e.clientY, on: false };
  };
  row.oncontextmenu = e => { e.preventDefault(); showAMenu(r, a, e.clientX, e.clientY); };
  return row;
}
function showAMenu(r, a, x, y) {
  const items = [], tok = r.tok, mat = r.kind === "amat";
  if (mat) {
    items.push(["Apply to Selection", () => act({ op: "apply", tok })]);
    items.push(["Edit in Slate", () => act({ op: "slate", tok })]);
  } else if (!r.root) items.push(["Go In", () => act({ op: "enter", tok })]);
  if (r.kind !== "amodel") items.push(["Rename", () => act({ op: "askname", tok })]);
  if (mat) items.push(["Duplicate", () => act({ op: "duplicate", tok })]);
  if (mat && a.libs.length) {
    items.push(["sep"], ["Stored In", null, "head"]);
    for (const l of a.libs)
      items.push([l.name, () => act({ op: "storedin", tok, lib: l.gid }),
                  "check" + ((r.libgids || []).includes(l.gid) ? " on" : "")]);
  }
  items.push(["sep"]);
  if (r.kind !== "amodel") {
    if (!tok.startsWith("A:s:")) items.push(["Cut", () => act({ op: "cut", tok })]);
    items.push(["Copy", () => act({ op: "copy", tok })]);
  }
  if (a.pastable && !mat) items.push(["Paste", () => act({ op: "paste", tok })]);
  if (r.kind === "agroup") items.push(["New Group", () => act({ op: "newgroup", tok })]);
  items.push(["New Library", () => act({ op: "newlib" })]);
  if (r.kind !== "amodel") {
    const del = r.kind === "agroup" ? (r.lib ? "Delete Library" : "Delete Group")
              : tok.startsWith("A:s:") ? "Remove from Model" : "Remove from Group";
    if (!(tok.startsWith("A:s:") && !r.unused)) items.push(["sep"], [del, () => act({ op: "delete", tok }), "danger"]);
  }
  items.push(["sep"], ["Hide Appearances", () => act({ op: "hideappear" })]);
  openMenu(items, x, y);
}

// Drag in Appearances: onto a group / In This Model = move (⌥ = copy); let go outside the
// Browser = over Max: onto Slate adds it, onto an object assigns it (Max decides by the point).
let adrag = null;
function aTarget(e) {
  const t = document.elementFromPoint(e.clientX, e.clientY);
  const re = t && t.closest && t.closest(".arow");
  if (!re) return null;
  const k = re.dataset.kind;
  return { el: k === "agroup" || k === "amodel" ? re : null,
           into: k === "agroup" || k === "amodel" ? re.dataset.tok : null };
}
document.addEventListener("mousemove", e => {
  if (!adrag) return;
  if (!adrag.on) {
    if (Math.hypot(e.clientX - adrag.x, e.clientY - adrag.y) < 4) return;
    adrag.on = true;
    adrag.toks = adrag.r.sel ? snap.appear.rows.filter(x => x.sel).map(x => x.tok) : [adrag.r.tok];
    document.body.classList.add("dragging");
  }
  for (const x of appear.querySelectorAll(".droptarget")) x.classList.remove("droptarget");
  const t = aTarget(e);
  if (t && t.el) t.el.classList.add("droptarget");
});
document.addEventListener("mouseup", e => {
  const d = adrag;
  adrag = null;
  if (!d || !d.on) return;
  document.body.classList.remove("dragging");
  justDragged = true;
  setTimeout(() => { justDragged = false; }, 0);
  const outside = e.clientX < 0 || e.clientY < 0 || e.clientX > innerWidth || e.clientY > innerHeight;
  const t = outside ? null : aTarget(e);
  if (t && t.into) act({ op: "move", tok: d.r.tok, toks: d.toks, into: t.into, copy: e.altKey });
  else if (outside && d.r.kind === "amat") act({ op: "dropmat", tok: d.r.tok, sx: e.screenX, sy: e.screenY });
  render();
});

// ── The row menu ────────────────────────────────────────────────────────────
function showMenu(r, x, y) {
  const items = [];
  const vis = r.kind === "mod" ? (r.off ? "Switch On" : "Switch Off") : (r.hidden ? "Show" : "Hide");
  if (r.kind !== "base") items.push([vis, () => act({ op: "vis", tok: r.tok })]);
  if (r.kind !== "base") items.push(["Rename", () => beginRename(r.tok)]);
  if (r.kind === "folder") items.push(["Go In", () => act({ op: "enter", tok: r.tok })]);
  if (r.kind === "group") items.push(["Go In", () => act({ op: "enter", tok: r.tok })]);
  if (r.kind !== "mod" && r.kind !== "base") {
    items.push(["Isolate", () => act({ op: "isolate", tok: r.tok })]);
    items.push(["Cut", () => { act({ op: "cut", tok: r.tok }); }]);
    if (snap && snap.rows.some(x => x.cut)) items.push(["Paste", () => act({ op: "paste" })]);
  }
  // a Browser folder is a component (organisation only); a group is Max's (selects as one)
  items.push(["sep"], ["New Component", () => act({ op: "newfolder", tok: r.tok })]);
  items.push(["New Group", () => act({ op: "newgroup", tok: r.tok })]);
  if (r.kind === "group") items.push(["Ungroup", () => act({ op: "ungroup", tok: r.tok })]);
  // a component's Delete keeps what's in it (it moves up a level)
  if (r.kind !== "base") items.push(["sep"], [r.kind === "folder" ? "Delete Component" : "Delete",
                                               () => act({ op: "delete", tok: r.tok }), "danger"]);
  // a hidden folder ticked here shows for a production render (not Quick Render), then hides again
  if (r.kind === "folder")
    items.push(["sep"], ["Show When Rendering", () => act({ op: "renderon", tok: r.tok }), "check" + (r.render ? " on" : "")]);
  // What the tree shows (Fusion's view ticks) — Max keeps them (snap.hide), tree only
  items.push(["sep"]);
  const hide = (snap && snap.hide) || [];
  for (const [kind, label] of [["targets", "Targets"], ["helpers", "Helpers"], ["splines", "Splines"]])
    items.push([label, () => act({ op: "showkind", kind }), "check" + (hide.includes(kind) ? "" : " on")]);
  // empty components/groups (nothing in the tree, or only empty ones) and the entered folder's own row
  items.push(["sep"],
    ["Hide Empty Groups", () => act({ op: "showkind", kind: "empty" }), "check" + (hide.includes("empty") ? " on" : "")],
    ["Show Parent", () => act({ op: "showkind", kind: "root" }), "check" + (hide.includes("root") ? "" : " on")]);
  openMenu(items, x, y);
}
// items: [label, fn, cls] — "sep" a separator; cls "check[ on]" a tick, "head" a heading
function openMenu(items, x, y) {
  ctx.textContent = "";
  delete ctx.dataset.panel;
  for (const [label, fn, cls] of items) {
    if (label === "sep") { ctx.appendChild(el("div", "menusep")); continue; }
    const it = el("div", "facetitem" + (cls ? " " + cls : ""), label);
    if (cls && cls.startsWith("check")) it.prepend(el("span", "tick", "✓"));
    if (cls !== "head") it.onclick = () => { hideMenu(); fn(); };
    ctx.appendChild(it);
  }
  ctx.hidden = false;
  ctx.style.left = Math.max(4, Math.min(x, innerWidth - ctx.offsetWidth - 4)) + "px";
  ctx.style.top = Math.min(y, innerHeight - ctx.offsetHeight - 6) + "px";
}
function hideMenu() { ctx.hidden = true; }
// With the menu up, a click anywhere else only closes it — in the page (here) and on the
// rest of the screen (the shell's catcher window calls __dismissMenu) — never acts too.
let swallow = false;
addEventListener("mousedown", e => {
  if (ctx.hidden || ctx.contains(e.target)) return;
  e.preventDefault(); e.stopImmediatePropagation();
  hideMenu(); swallow = true;
}, true);
for (const t of ["mouseup", "click", "dblclick", "contextmenu", "auxclick"])
  addEventListener(t, e => {
    if (!swallow) return;
    e.preventDefault(); e.stopImmediatePropagation();
    if (t === "mouseup") setTimeout(() => { swallow = false; }, 0);
  }, true);
window.__dismissMenu = () => { hideMenu(); };
// The settings panel's menu (anywhere in it): Rename on a section head, close it, Show Parent.
// Right-click never renames by itself.
function showPanelMenu(x, y, rename) {
  const hide = (snap && snap.hide) || [];
  openMenu([...(rename ? [["Rename", rename], ["sep"]] : []),
            ["Close Panel", () => act({ op: "closepanel" })], ["sep"],
            ["Show Parent", () => act({ op: "showkind", kind: "root" }), "check" + (hide.includes("root") ? "" : " on")]], x, y);
  ctx.dataset.panel = "1";   // a panel redraw keeps it open
}
// Anything without its own menu: never WebKit's (Reload / Inspect).
document.addEventListener("contextmenu", e => {
  if (e.defaultPrevented || (e.target.closest && e.target.closest("input"))) return;
  e.preventDefault();
  if (snap && snap.panel && !snap.away) showPanelMenu(e.clientX, e.clientY);
});

function beginRename(tok) {
  tok = tok || (snap && snap.cursor);
  if (!tok || tok.endsWith(":base")) return;
  renaming = tok;
  render();
}

// ── Keys — the same as in Max's viewport (callis/browser.py KEYS) ───────────
const KEYMAP = { r: "up", c: "down", f: "in", d: "out", a: "deselect",
                 R: "top", C: "bottom", F: "deep" };
document.addEventListener("keydown", e => {
  if (renaming || e.target.tagName === "INPUT") return;
  if (snap && snap.panel) {                       // the settings panel: Enter = F, Esc closes it
    if (e.key === "Escape") { e.preventDefault(); act(pdrop.hidden ? { op: "closepanel" } : { op: "panel", cancel: true }); return; }
    if (e.key === "Enter") { e.preventDefault(); act({ op: "key", key: "in" }); return; }
  }
  const ap = snap && snap.appear;
  if (ap && ap.focus) {                          // Appearances: Enter = F; ⌘ keys on its cursor row
    const tok = ap.cursor || "";
    if (e.key === "Enter") { e.preventDefault(); act({ op: "key", key: "in" }); return; }
    if (e.key === "Escape") { e.preventDefault(); hideMenu(); act({ op: "uncut", tok }); return; }
    if (e.metaKey) {
      const k = e.key.toLowerCase();
      const op = { x: "cut", c: "copy", v: "paste", g: "newgroup", backspace: "delete" }[k];
      if (op) { e.preventDefault(); act({ op, tok }); }
      return;
    }
  }
  if (e.key === "Escape") {
    hideMenu();
    if (drag && drag.on) endDrag(false); else act({ op: "uncut" });
    return;
  }
  if (e.altKey && e.shiftKey && e.code === "KeyF") { e.preventDefault(); act({ op: "toggleiso" }); return; }
  if (e.metaKey) {
    const k = e.key.toLowerCase();
    if (k === "x") { e.preventDefault(); act({ op: "cut" }); }
    if (k === "c") { e.preventDefault(); act({ op: "copy" }); }
    if (k === "v") { e.preventDefault(); act({ op: "paste" }); }
    if (k === "g") { e.preventDefault(); act({ op: e.shiftKey ? "newgroup" : "newfolder" }); }
    if (k === "backspace" && snap && snap.cursor) { e.preventDefault(); act({ op: "delete", tok: snap.cursor }); }
    return;
  }
  const name = KEYMAP[e.shiftKey ? e.key.toUpperCase() : e.key.toLowerCase()];
  if (name) { e.preventDefault(); act({ op: "key", key: name }); }
  else if (e.key === "Enter") { e.preventDefault(); beginRename(); }
});
// WebKit eats ⌘E and ⌘R before the page sees them; the shell forwards them here.
window.__toggleVis = () => act({ op: "key", key: "hide" });
window.__rename = () => beginRename();

// ── Drag and drop ───────────────────────────────────────────────────────────
// Mousedown on a row, 4 px → drag: the render is frozen (poll skips it) so the rows stay
// put under the pointer. The dragged set is the selection when the grabbed row is in it,
// else that row. Target: a folder or group row = into it; any other row = the folder or
// group it's in; blank space = the entered folder. Drop posts {op:"move"}; Max does the move (one undo step).
let drag = null, justDragged = false;
function folderOf(tok) {
  const rows = snap.rows, i = rows.findIndex(x => x.tok === tok);
  if (i < 0) return "";
  const box = k => k === "folder" || k === "group";
  if (box(rows[i].kind)) return tok;
  // the nearest folder or group above it at a shallower depth (a member's group, an
  // object's folder) — a modifier row belongs to its object, which is never a box
  let d = rows[i].depth;
  for (let j = i - 1; j >= 0; j--) {
    if (rows[j].depth >= d) continue;
    if (box(rows[j].kind)) return rows[j].tok;
    d = rows[j].depth;
  }
  return "";
}
function dropTarget(e) {
  const row = document.elementFromPoint(e.clientX, e.clientY);
  const re = row && row.closest && row.closest(".row");
  if (re && re.dataset.tok) return { into: folderOf(re.dataset.tok),
                                     el: re.dataset.kind === "folder" || re.dataset.kind === "group" ? re : null };
  const top = snap.rows[0];
  return { into: top && top.root ? top.tok : "", el: null };
}
function markTarget(t) {
  for (const x of tree.querySelectorAll(".droptarget")) x.classList.remove("droptarget");
  tree.classList.toggle("dropblank", !!t && !t.el);
  if (t && t.el) t.el.classList.add("droptarget");
  else if (t) {
    const e = tree.querySelector('.row[data-tok="' + CSS.escape(t.into) + '"]');
    if (e) e.classList.add("droptarget");
  }
}
function endDrag(drop, e) {
  const d = drag;
  drag = null;
  document.body.classList.remove("dragging");
  markTarget(null);
  if (d && d.on) {
    justDragged = true;
    setTimeout(() => { justDragged = false; }, 0);
    if (drop && e) {
      const t = dropTarget(e);
      act({ op: "move", toks: d.toks, into: t.into });
    }
    render();
  }
}
document.addEventListener("mousemove", e => {
  if (!drag) return;
  if (!drag.on) {
    if (Math.hypot(e.clientX - drag.x, e.clientY - drag.y) < 4) return;
    drag.on = true;
    drag.toks = drag.r.sel ? snap.rows.filter(x => x.sel).map(x => x.tok) : [drag.r.tok];
    document.body.classList.add("dragging");
  }
  markTarget(dropTarget(e));
});
document.addEventListener("mouseup", e => { if (drag) endDrag(e.button === 0, e); });

poll();

// Max puts its panels in our place (callis/side.py): tell it our size, in Mac points.
let lastFrame = "";
function sendFrame() {
  // only the real overlay (MaxBrowserApp) — a page opened in some other browser isn't the strip
  if (!(window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.hit)) return;
  const f ={ op: "frame", w: innerWidth, h: innerHeight, sw: screen.width, sh: screen.height };
  const k = JSON.stringify(f);
  if (k !== lastFrame && innerWidth && innerHeight) { lastFrame = k; act(f); }
}
addEventListener("resize", sendFrame);
setTimeout(sendFrame, 1000);

// ── Click-through ───────────────────────────────────────────────────────────
// The window is a transparent overlay on Max's viewport (MaxBrowserApp): it takes clicks
// only over what this page draws. Tell it where that is — the top down to the last
// visible row — and to take everything while a menu or a rename field is open.
let lastHit = "";
setInterval(() => {
  const h = window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.hit;
  if (!h) return;
  const tr = tree.getBoundingClientRect();
  let bottom = appear.hidden ? tr.top : Math.max(tr.top, appear.getBoundingClientRect().bottom);
  for (const e of tree.children) bottom = Math.max(bottom, Math.min(e.getBoundingClientRect().bottom, tr.bottom));
  if (!msg.hidden) bottom = Math.max(bottom, msg.getBoundingClientRect().bottom);
  const all = !ctx.hidden || !pdrop.hidden || !!document.querySelector("input.rename") || !!(drag && drag.on) ||
              !!(adrag && adrag.on);
  const menu = !ctx.hidden;                         // the shell catches clicks off the window
  const key = bottom + "|" + all + "|" + menu + "|" + innerWidth;
  if (key === lastHit) return;
  lastHit = key;
  h.postMessage({ rect: [0, 0, innerWidth, bottom], all, menu });
}, 150);
