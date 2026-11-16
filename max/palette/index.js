/* max/palette/index.js — the 3ds Max adapter for fusion_ui/search.js.

   The ranking, list, keys and right-click sheet (pin, hide, rename, Show hidden) are the
   shared kit. What is Max's: there is no server — the page sits in a QWebEngineView inside
   Max (callis/palette.py) and talks to it over a QWebChannel object `palette`:
     catalog()            → JSON {commands, recents, keymap, show, names, pins}
     run(id)              hide the window, run the action after it's gone
     store(kind, json)    the sheet's writes (show / name / pin) → .state/palette.json
     size(w, h)           the panel's size, so the window is only that big
     close()              Escape / a click beside the panel
   and Max calls window.paletteOpen() each time X shows it.

   Keys: Max's own hotkey set is the truth (it travels with Max); a held trigger
   (fingers / Space / ⌘ from the Mac's Karabiner) is drawn as its REACH, as Control Room
   draws it — the keymap entry says which. Setting a key stays Control Room's job. */
const $ = id => document.getElementById(id);
const panel = $("spanel"), queryEl = $("squery"), resultsEl = $("sresults"), sheetEl = $("ssheet");

let max = null;          // the channel object
const ready = new Promise(res => {
  new QWebChannel(qt.webChannelTransport, ch => { max = ch.objects.palette; res(); });
});
const call = (fn, ...args) => ready.then(() => new Promise(res => max[fn](...args, res)));

// fusion_value's sBinding, for Max's keymap entries ({kind, seq | key, fingers}).
const MOD_SYMBOL = { ctrl: "⌃", alt: "⌥", shift: "⇧", cmd: "⌘" };
const MOD_ORDER = ["⌃", "⌥", "⇧", "⌘"];
function keyWord(k){
  k = String(k || "");
  return k.length === 1 ? k.toUpperCase() : k.charAt(0).toUpperCase() + k.slice(1);
}
function chordText(seq){
  const parts = String(seq || "").split("+").filter(Boolean);
  const key = parts.pop();
  if (!key) return "";
  const syms = new Set(parts.map(p => MOD_SYMBOL[p.toLowerCase()] || ""));
  return MOD_ORDER.filter(s => syms.has(s)).join("") + keyWord(key);
}
let reach = {};          // id → {kind, seq | key, fingers} — the kit's keymap is the TEXT of it
function bindingText(t){
  if (t.kind === "space")   return "Space + " + keyWord(t.key);
  if (t.kind === "fingers") return (t.fingers || 0) + (t.fingers === 1 ? " Finger + " : " Fingers + ") + keyWord(t.key);
  return chordText(t.seq);
}
function binding(c){
  const t = reach[c.id];
  if (!t) return null;
  if ((t.kind === "space" || t.kind === "fingers") && window.Glyphs && t.key){
    const span = document.createElement("span");
    span.innerHTML = t.kind === "fingers" ? Glyphs.hand(t.fingers || 0) : Glyphs.saturn();
    span.appendChild(document.createTextNode(keyWord(t.key)));
    span.title = (t.kind === "fingers" ? (t.fingers || 0) + " fingers + " : "Space + ") + keyWord(t.key);
    return span;
  }
  return bindingText(t) || null;
}

// Same-named actions from different tables are told apart by their category.
let decItems = null, decCounts = null;
function decorate(c, items){
  if (decItems !== items){
    decItems = items; decCounts = new Map();
    items.forEach(x => {
      const k = (x.name || "").toLowerCase();
      decCounts.set(k, (decCounts.get(k) || 0) + 1);
    });
  }
  return decCounts.get((c.name || "").toLowerCase()) > 1 ? { val: c.group } : null;
}

const kit = SearchKit.create({
  query: queryEl, results: resultsEl, sheet: sheetEl,
  adapter: {
    stores: { base: "", show: "show", name: "name", pin: "pin" },
    store: (kind, body) => call("store", kind, JSON.stringify(body)),
    storageKey: "maxSearchShowHidden",
    decorate, binding,
    async loadCatalog(){
      const d = JSON.parse(await call("catalog"));
      reach = d.keymap || {};
      const keymap = {};
      for (const id in reach) keymap[id] = bindingText(reach[id]);
      return Object.assign(d, { keymap });
    },
    run: item => { kit.closeSheet(true); call("run", item.id); },
    lookupRow: async () => null,
    noRowMsg: () => "Set it in Control Room ▸ 3ds Max ▸ Shortcuts.",
    fitSheet: () => { panel.classList.add("wide"); reportSize(); },
    onSheetClose: () => { panel.classList.remove("wide"); reportSize(); },
    onRendered: () => reportSize(),
  },
});

function reportSize(){
  const r = panel.getBoundingClientRect(), g = parseFloat(getComputedStyle(panel).marginLeft) || 0;
  call("size", Math.ceil(r.width + g * 2), Math.ceil(r.height + g * 2));
}
if (typeof ResizeObserver === "function") new ResizeObserver(reportSize).observe(panel);

window.paletteOpen = function(){
  panel.classList.remove("wide");
  kit.open({ env: "" });
  reportSize();
  queryEl.focus();
};

function dismiss(){ kit.closeSheet(true); panel.classList.remove("wide"); call("close"); }

document.addEventListener("keydown", e => {
  if (e.key === "Escape"){
    e.preventDefault();
    if (kit.isSheetOpen()) kit.closeSheet(); else dismiss();
    return;
  }
  if (e.target === queryEl || !kit.isSheetOpen()) kit.handleKey(e);
});
queryEl.addEventListener("input", () => kit.rerun());
// A click on the transparent margin around the panel is a click away from it.
document.addEventListener("mousedown", e => { if (!panel.contains(e.target)) dismiss(); });
window.addEventListener("focus", () => { if (!kit.isSheetOpen()) queryEl.focus(); });
