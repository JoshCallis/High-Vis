/* ── search.js — the command-search palette, shared ──────────────────────────────
   Born in fusion_value/index.js ("Command search" + "The per-row sheet"); lifted here
   so the Photoshop palette (ps_palette/) is the same code, not a copy. Served as
   /search.js by every window (webwin.SHARED_ASSETS); look in /search.css.

   WHAT IS HERE: the ranker (SearchKit.rank — pure and DOM-free; fusion_value/test/cases.js
   drives it through Fusion's wrapper), the row list, the keys (↑ ↓ Enter, ⌘-click picks),
   the right-click sheet (Name / Shortcut / Show in / Pinned / Hide) and the chord capture.

   WHAT IS NOT: what a command IS and how it runs. A page passes an ADAPTER:

     loadCatalog()      → Promise<{commands, recents:[id], disabled:[id], keymap:{id:chord},
                                   show:{id:[env]}, names:{id:name}, pins:{id:true}}>
     run(item)          run the row (the page hides its window, then executes)
     lookupRow(cmd)     → Promise<Control Room's row for cmd, or null — it isn't running>
     setKey(cmd, chord, row) → Promise<{ok, error}>  ("" = clear)
     stores             {base, show, name, pin} — URLs the sheet's writes POST to
                        (show:{cmd_id, env:[…]|null}, name:{cmd_id, name}, pin:{cmd_id, pinned})
     store(kind, body)  optional → Promise; writes a store itself instead of POSTing to
                        `stores` (kind = "show" / "name" / "pin", body as above)
     envs               optional [[value, label]…] — the sheet's "Show in" row; absent = none
     rankOpts()         optional extra rank opts: skip(c, env), dedup(list), boost(c, env),
                        tie(a, b) — Fusion's env groups, trio dedup, sketch-first
     decorate(c, items) optional → {cls, node, val}: a class, a leading node and a quiet
                        right-hand text for a row
     binding(c, keymap) optional → a string or node: the row's key, drawn on its right
                        (.ac-chord); falsy = nothing
     noRowMsg(cmd)      optional; what the sheet says when lookupRow found no row
     isActive()         optional; false = the palette is not on screen (no re-render)
     onRendered()       optional; after every list render (the page resizes its window)
     fitSheet(el)       optional; the sheet is up (the page asks for its width)
     onSheetClose()     optional; the sheet went (the page puts its width back)
     storageKey         optional; localStorage key for "Show hidden"

   The instance (SearchKit.create({query, results, sheet, adapter})) holds all the state
   (items, index, picks, the stores) and exposes open(), rerun(), reload(), handleKey(e),
   closeSheet(), isSheetOpen(), `env` (settable) and `items`/`index` (read). */
const SearchKit = (function(){

  /* Where in `name` a run of "word starts" begins: index 0, anywhere after a run of
     non-alphanumerics, and every camelCase hump — the shape a command's raw id shows up
     in when it never got a display name. A hit on one of these ranks well above one
     buried inside a word; a mid-word hit still ranks, just lower. */
  function wordStarts(name){
    const idx = [0];
    for (let i = 1; i < name.length; i++){
      const c = name[i], p = name[i - 1];
      if (/[a-z0-9]/i.test(c) && !/[a-z0-9]/i.test(p)) idx.push(i);
      else if (/[A-Z]/.test(c) && /[a-z]/.test(p)) idx.push(i);
    }
    return idx;
  }

  /* The Show In store: {cmd_id: [env,…]}. No entry -> shown everywhere; `[]` -> hidden
     everywhere, even with no env known; otherwise shown iff env is empty (unknown —
     fail open) or listed. Deliberately not part of any key's "applies in": hiding a
     command from search must never change where its key fires, and it has to work for
     commands with no binding at all. */
  function storeHides(c, env, show){
    const entry = (show || {})[c.id];
    if (entry === undefined) return false;
    if (!entry.length) return true;
    return !!env && !entry.includes(env);
  }

  /* Pure and DOM-free on purpose. `commands` is the catalog ({id, name, group, kind});
     `recentIds` is most-recent-first, used only as a tiebreak — an empty query lists
     nothing, the palette is a search box, not a recents list. Every word of a non-empty
     query must appear SOMEWHERE in the name; ranked by the best-placed word first, then
     total offset, then recency, then the shorter, then alphabetically.

     opts.pins {id:true} — a pinned match sorts ahead of every unpinned one, full stop.
     opts.names {id:name} — a search-only rename, applied before anything looks at the
       name; the original rides along as `searchNative`.
     opts.env / opts.show / opts.showHidden — see storeHides; showHidden skips it.
     opts.disabled [id] — dropped outright, ahead of dedup, so a dead same-named copy can
       never win over a live one. showHidden doesn't bring them back.
     opts.skip(c, env) → true drops a command (the page's own "never offered").
     opts.dedup(list) → the list with same-named candidates collapsed.
     opts.boost(c, env) → a number, lower first, after pins (Fusion: sketch commands in a sketch).
     opts.tie(a, b) → a number, after offset/recency (Fusion: solid, sheet metal, surface).
     opts.limit — default 40. */
  function rank(query, commands, recentIds, opts){
    const { env = "", show = {}, showHidden = false, names = {}, pins = {}, disabled = [],
            skip, dedup, boost, tie, limit = 40 } = opts || {};
    const dead = new Set(disabled);
    const recent = new Map((recentIds || []).map((id, i) => [id, i]));
    const words = (query || "").toLowerCase().trim().split(/\s+/).filter(Boolean);
    const renamed = (commands || []).map(c =>
      names[c.id] ? Object.assign({}, c, { name: names[c.id], searchNative: c.name }) : c);
    const filtered = renamed.filter(c => {
      if (dead.has(c.id) || (skip && skip(c, env))) return false;
      return showHidden || !storeHides(c, env, show);
    });
    const pool = dedup ? dedup(filtered) : filtered;

    if (!words.length) return [];

    const scored = [];
    for (const c of pool){
      const name = (c.name || c.id || "").toLowerCase();
      const starts = wordStarts(name);
      let bucket = 3, offset = 0, ok = true;
      for (const w of words){
        const at = name.indexOf(w);
        if (at === -1){ ok = false; break; }
        bucket = Math.min(bucket, at === 0 ? 0 : starts.includes(at) ? 1 : 2);
        offset += at;
      }
      if (ok) scored.push({ c, bucket, offset, rec: recent.has(c.id) ? recent.get(c.id) : Infinity });
    }
    const pinRank = c => pins[c.id] ? 0 : 1;
    scored.sort((a, b) =>
      pinRank(a.c) - pinRank(b.c) ||
      (boost ? boost(a.c, env) - boost(b.c, env) : 0) ||
      a.bucket - b.bucket || a.offset - b.offset || a.rec - b.rec ||
      (tie ? tie(a.c, b.c) : 0) ||
      (a.c.name || "").length - (b.c.name || "").length ||
      (a.c.name || "").localeCompare(b.c.name || ""));
    return scored.map(s => s.c).slice(0, limit);
  }

  function escapeHtml(s){
    return String(s).replace(/[&<>]/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;" }[c]));
  }

  /* Bold the matched letters, word by word. Plain indexOf, the ranker's own, so a
     query with regex metacharacters is harmless. */
  function highlight(name, query){
    const words = (query || "").toLowerCase().trim().split(/\s+/).filter(Boolean);
    if (!words.length) return escapeHtml(name);
    const marks = new Array(name.length).fill(false);
    const lower = name.toLowerCase();
    for (const w of words){
      const at = lower.indexOf(w);
      if (at === -1) continue;
      for (let i = at; i < at + w.length; i++) marks[i] = true;
    }
    let out = "", on = false;
    for (let i = 0; i < name.length; i++){
      if (marks[i] && !on){ out += "<b>"; on = true; }
      if (!marks[i] && on){ out += "</b>"; on = false; }
      out += escapeHtml(name[i]);
    }
    if (on) out += "</b>";
    return out;
  }

  /* Chord capture — a copy of remap/index.js's chordFrom + armed read-only field: the
     page has no native window.__capturedKey bridge, so only the plain keydown path runs
     and a chord WebKit itself eats is simply not capturable here. */
  const CODE = { Space:"space", Enter:"return", Tab:"tab", Backspace:"delete",
    Escape:"escape", ArrowLeft:"left", ArrowRight:"right", ArrowUp:"up", ArrowDown:"down",
    Minus:"-", Equal:"=", BracketLeft:"[", BracketRight:"]", Backslash:"\\",
    Semicolon:";", Quote:"'", Comma:",", Period:".", Slash:"/", Backquote:"`" };
  const MOD_CODES = ["ShiftLeft","ShiftRight","ControlLeft","ControlRight",
                     "AltLeft","AltRight","MetaLeft","MetaRight"];

  function chordFrom(e){
    let k = null;
    if (CODE[e.code]) k = CODE[e.code];
    else if (/^Key[A-Z]$/.test(e.code)) k = e.code.slice(3).toLowerCase();
    else if (/^Digit[0-9]$/.test(e.code)) k = e.code.slice(5);
    else if (/^F([1-9]|1[0-9]|20)$/.test(e.code)) k = e.code.toLowerCase();
    if (!k) return null;
    const mods = [];
    if (e.altKey) mods.push("alt");
    if (e.metaKey) mods.push("cmd");
    if (e.ctrlKey) mods.push("ctrl");
    if (e.shiftKey) mods.push("shift");
    return mods.concat([k]).join("+");
  }

  // "alt+cmd+ctrl+shift+key" → what remapctl.canon_chord and Control Room's /…/set
  // expect: a bare key and the rest as a mods list (remap/index.js's splitChord).
  function splitChord(c){
    const parts = String(c || "").split("+").map(p => p.trim().toLowerCase()).filter(Boolean);
    const key = parts.pop() || "";
    return { key, mods: parts };
  }

  async function postJSON(url, body){
    const r = await fetch(url, { method: "POST", headers: { "Content-Type": "application/json" },
                                 body: JSON.stringify(body || {}) });
    return r.json();
  }

  function create(cfg){
    const A = cfg.adapter;
    const qEl = cfg.query, resEl = cfg.results, sheetEl = cfg.sheet;
    const envs = A.envs || [];
    const ALL_ENVS = envs.map(e => e[0]);

    let commands = [], recentIds = [], keymap = {}, show = {}, names = {}, pins = {}, disabled = [];
    let showHidden = false;
    try { showHidden = localStorage.getItem(A.storageKey || "searchShowHidden") === "1"; } catch (_) {}
    let items = [], index = -1;
    const picked = new Map();   // ⌘-clicked rows {id: command}, kept across queries
    let env = "";

    /* The sheet's store writes all go through one chain so they reach the server in the
       order they were made. storeGen bumps on every local change: a catalog fetch already
       in flight carries the old stores, and applying them would undo the change. */
    let storeChain = Promise.resolve(), storeGen = 0;
    function postStore(kind, body){
      storeGen++;
      // A page with no server (Max's, in a Qt web view) writes through its own call.
      storeChain = storeChain.then(() => A.store ? A.store(kind, body) : fetch(A.stores.base + A.stores[kind], {
        method: "POST", headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body)
      })).catch(() => {});
      return storeChain;
    }

    const active = () => !A.isActive || A.isActive();

    async function reload(){
      try {
        await storeChain;
        const gen = storeGen;
        const d = await A.loadCatalog();
        commands = d.commands || [];
        recentIds = d.recents || [];
        disabled = d.disabled || [];
        if (gen === storeGen){
          show = d.show || {}; names = d.names || {}; pins = d.pins || {};
        }
        keymap = d.keymap || {};
      } catch (_) { /* the catalog's server isn't up yet — the field still works once it answers */ }
      if (active()) rerun();
    }

    function rankOpts(){
      return Object.assign({ env, show, showHidden, names, pins, disabled },
                           A.rankOpts ? A.rankOpts() : {});
    }

    function rerun(){
      items = rank(qEl.value, commands, recentIds, rankOpts());
      index = items.length ? 0 : -1;
      render();
    }

    function runSelection(){
      const item = items[index];
      if (item) A.run(item);
    }

    function render(){
      resEl.innerHTML = "";
      items.forEach((c, i) => {
        const dec = (A.decorate && A.decorate(c, items)) || {};
        const row = document.createElement("div");
        row.className = "ac-row" + (i === index ? " sel" : "") + (dec.cls ? " " + dec.cls : "")
                      + (showHidden && storeHides(c, env, show) ? " ac-hidden" : "")
                      + (picked.has(c.id) ? " picked" : "");
        // Left button only — a right-click's mousedown arrives before its contextmenu,
        // and running here would hide the row before the sheet could open. ⌘-click picks.
        row.addEventListener("mousedown", ev => {
          if (ev.button !== 0 || ev.ctrlKey) return;
          ev.preventDefault(); index = i;
          if (ev.metaKey){
            if (picked.has(c.id)) picked.delete(c.id); else picked.set(c.id, c);
            render();
            return;
          }
          runSelection();
        });
        row.addEventListener("mousemove", () => { if (index !== i){ index = i; render(); } });
        // With a ⌘-picked set, right-click opens the sheet for all of them; an unpicked
        // row is added to the set first.
        row.addEventListener("contextmenu", ev => {
          ev.preventDefault(); index = i;
          if (picked.size && !picked.has(c.id)) picked.set(c.id, c);
          if (picked.size > 1) openMultiSheet([...picked.values()]);
          else openRowSheet(c);
        });

        if (dec.node) row.appendChild(dec.node);
        const nm = document.createElement("span");
        nm.className = "ac-name";
        nm.innerHTML = highlight(c.name || c.id, qEl.value);
        row.appendChild(nm);
        // The dot on the far right that says which row Enter runs (.ac-mark).
        const spacer = document.createElement("span");
        spacer.className = "ac-val";
        if (dec.val) spacer.textContent = dec.val;
        row.appendChild(spacer);
        // The key it is bound to, right-aligned; nothing at all when unbound.
        const bound = A.binding && A.binding(c, keymap);
        if (bound){
          const ch = document.createElement("span");
          ch.className = "ac-chord";
          if (typeof bound === "string") ch.textContent = bound; else ch.appendChild(bound);
          row.appendChild(ch);
        }
        const mark = document.createElement("span");
        mark.className = "ac-mark";
        row.appendChild(mark);
        resEl.appendChild(row);
      });
      if (!items.length && qEl.value.trim()){
        const msg = document.createElement("div");
        msg.className = "ac-empty";
        msg.textContent = "No matching command";
        resEl.appendChild(msg);
      }
      if (active() && A.onRendered) A.onRendered();
    }

    // Fresh session: empty field, nothing picked, no sheet, the catalog fetched.
    function open(opts){
      env = (opts && opts.env) || "";
      closeSheet(true);
      qEl.value = "";
      items = []; index = -1; picked.clear();
      resEl.innerHTML = "";
      reload();
    }

    // ↑ ↓ Enter — true when the key was this list's (always, with the sheet up: the
    // sheet has its own field and buttons, and the list under it is not this key's).
    function handleKey(e){
      if (isSheetOpen()) return true;
      if (e.key === "ArrowDown" || e.key === "ArrowUp"){
        e.preventDefault();
        if (items.length){
          index = e.key === "ArrowDown" ? (index + 1) % items.length
                                        : (index <= 0 ? items.length - 1 : index - 1);
          render();
          const sel = resEl.querySelector(".sel");
          if (sel) sel.scrollIntoView({ block: "nearest" });
        }
        return true;
      }
      if (e.key === "Enter"){ e.preventDefault(); runSelection(); return true; }
      return false;
    }

    // ── The per-row sheet ───────────────────────────────────────────────────
    // Replaces the list in the same panel (a floating menu would need its own clamping).
    let sheetCmd = null;      // the command this sheet is open for, or null when closed
    let crRow = null;         // its Control Room row — null if Control Room isn't running
    let sheetChord = "";      // captured but not yet Set
    let sheetBusy = false;
    let sheetMsg = "";
    let crLoading = false;
    let sheetMulti = null;    // [command,…] when the sheet is for a ⌘-picked set

    function isSheetOpen(){ return !!sheetCmd; }

    function showSheet(){
      resEl.classList.add("hide");
      sheetEl.classList.remove("hide");
    }

    function openMultiSheet(cmds){
      sheetMulti = cmds; sheetCmd = cmds[0]; crRow = null; crLoading = false;
      showSheet();
      renderSheet();
    }

    async function openRowSheet(cmd){
      sheetMulti = null;
      sheetCmd = cmd; crRow = null; sheetChord = ""; sheetBusy = false; sheetMsg = "";
      crLoading = true;
      showSheet();
      renderSheet();
      try { crRow = await A.lookupRow(cmd); } catch (_) { crRow = null; }
      if (sheetCmd === cmd){ crLoading = false; renderSheet(); }
    }

    function closeSheet(quiet){
      if (!sheetCmd) return;
      sheetCmd = null; sheetMulti = null; crRow = null; sheetChord = ""; sheetMsg = "";
      sheetEl.classList.add("hide");
      sheetEl.innerHTML = "";
      resEl.classList.remove("hide");
      if (!quiet){
        if (A.onSheetClose) A.onSheetClose();
        qEl.focus();
      }
    }

    function mk(tag, cls, text){
      const el = document.createElement(tag);
      if (cls) el.className = cls;
      if (text !== undefined) el.textContent = text;
      return el;
    }

    function renderSheet(){
      if (!sheetCmd) return;
      const cmd = sheetCmd, crUp = !!crRow;
      sheetEl.innerHTML = "";
      if (sheetMulti){
        const nm = mk("div", "", sheetMulti.length + " commands");
        nm.id = "ssname";
        sheetEl.appendChild(nm);
        sheetEl.appendChild(sheetActions(sheetMulti));
        fit();
        return;
      }

      const nm = mk("div", "", cmd.name || cmd.id);
      nm.id = "ssname";
      sheetEl.appendChild(nm);

      const nameRow = mk("div", "ssrow");
      nameRow.appendChild(mk("label", "", "Name"));
      const nameIn = mk("input", "ssname-in");
      nameIn.value = cmd.name || cmd.id;
      nameIn.placeholder = cmd.searchNative || cmd.name || cmd.id;
      nameIn.title = cmd.searchNative ? "Original name: " + cmd.searchNative : "";
      nameRow.appendChild(nameIn);
      const saveName = () => rename(cmd, nameIn.value);
      nameIn.addEventListener("keydown", e => {
        if (e.key === "Enter"){ e.preventDefault(); saveName(); }
      });
      const renBtn = mk("button", "", "Rename");
      renBtn.onclick = saveName;
      nameRow.appendChild(renBtn);
      if (cmd.searchNative){
        const resetBtn = mk("button", "", "Reset");
        resetBtn.onclick = () => rename(cmd, "");
        nameRow.appendChild(resetBtn);
      }
      sheetEl.appendChild(nameRow);

      const shortRow = mk("div", "ssrow");
      shortRow.appendChild(mk("label", "", "Shortcut"));
      shortRow.appendChild(mk("span", "ac-chord", keymap[cmd.id] || "unbound"));
      sheetEl.appendChild(shortRow);

      const capRow = mk("div", "ssrow");
      capRow.appendChild(mk("label"));
      const cap = mk("input", "sscapture");
      cap.readOnly = true;
      cap.disabled = !crUp;
      cap.value = sheetChord;
      cap.placeholder = "Shortcut";
      cap.addEventListener("focus", () => cap.classList.add("arm"));
      cap.addEventListener("blur", () => cap.classList.remove("arm"));
      cap.addEventListener("keydown", e => {
        if (MOD_CODES.includes(e.code)) return;   // a bare modifier is not a chord yet
        e.preventDefault(); e.stopPropagation();
        const c = chordFrom(e);
        if (c){ sheetChord = c; cap.value = c; setBtn.disabled = sheetBusy; }
      });
      capRow.appendChild(cap);
      const setBtn = mk("button", "", "Set");
      setBtn.disabled = !crUp || !sheetChord || sheetBusy;
      setBtn.onclick = () => applyShortcut(sheetChord);
      capRow.appendChild(setBtn);
      const clearBtn = mk("button", "danger", "Clear");
      clearBtn.disabled = !crUp || sheetBusy;
      clearBtn.onclick = () => applyShortcut("");
      capRow.appendChild(clearBtn);
      sheetEl.appendChild(capRow);

      const msgText = sheetBusy ? "Setting it…"
                    : sheetMsg ? sheetMsg
                    : !crUp && !crLoading ? (A.noRowMsg ? A.noRowMsg(cmd) : "Control Room isn't running.")
                    : "";
      if (msgText){
        const msg = mk("div", sheetMsg && !sheetBusy ? "err" : "", msgText);
        msg.id = "ssmsg";
        sheetEl.appendChild(msg);
      }

      if (envs.length){
        const showRow = mk("div", "ssrow");
        showRow.appendChild(mk("label", "", "Show in"));
        const checks = mk("div", "sit-checks");
        const entry = show[cmd.id];      // undefined -> everywhere; [] -> nowhere (None)
        const ticked = new Set(entry === undefined ? ALL_ENVS : entry);
        const cbs = {};
        for (const [v, label] of envs){
          const cb = document.createElement("input");
          cb.type = "checkbox"; cb.checked = ticked.has(v);
          cbs[v] = cb;
          const lbl = document.createElement("label");
          lbl.appendChild(cb);
          lbl.appendChild(document.createTextNode(label));
          checks.appendChild(lbl);
        }
        const noneCb = document.createElement("input");
        noneCb.type = "checkbox"; noneCb.checked = !ticked.size;
        const noneLbl = document.createElement("label");
        noneLbl.appendChild(noneCb);
        noneLbl.appendChild(document.createTextNode("None"));
        checks.appendChild(noneLbl);
        for (const v of ALL_ENVS){
          cbs[v].onchange = () => {
            const on = ALL_ENVS.filter(x => cbs[x].checked);
            noneCb.checked = !on.length;
            writeShow([cmd], on);
          };
        }
        noneCb.onchange = () => {
          const on = noneCb.checked ? [] : ALL_ENVS.slice();
          for (const v of ALL_ENVS) cbs[v].checked = !noneCb.checked;
          writeShow([cmd], on);
        };
        showRow.appendChild(checks);
        sheetEl.appendChild(showRow);
      }

      sheetEl.appendChild(sheetActions([cmd]));
      fit();
    }

    function fit(){ if (A.fitSheet) A.fitSheet(sheetEl, isSheetOpen); }

    // One Show In list to every command in `cmds` (null = back to the default).
    function writeShow(cmds, list){
      for (const c of cmds){
        if (list === null) delete show[c.id]; else show[c.id] = list;
        postStore("show", { cmd_id: c.id, env: list });
      }
    }

    function writePin(cmds, pinned){
      for (const c of cmds){
        if (pinned) pins[c.id] = true; else delete pins[c.id];
        postStore("pin", { cmd_id: c.id, pinned });
      }
    }

    /* The bottom button row, shared by the single and multi sheets. Hide = Show In
       "None"; Unhide = back to shown everywhere (offered when every command in the set
       is hidden). The Pinned box sits in this row so a ⌘-picked set can be pinned at
       once, like hidden; it ticks only when every command is pinned. */
    function sheetActions(cmds){
      const actions = mk("div");
      actions.id = "ssactions";
      const pinLbl = mk("label", "sspin");
      const pinCb = document.createElement("input");
      pinCb.type = "checkbox";
      pinCb.checked = cmds.every(c => pins[c.id]);
      pinCb.onchange = () => { writePin(cmds, pinCb.checked); rerun(); };
      pinLbl.appendChild(pinCb);
      pinLbl.appendChild(document.createTextNode("Pinned"));
      actions.appendChild(pinLbl);
      const hidden = cmds.every(c => storeHides(c, env, show));
      const hideBtn = mk("button", "", (hidden ? "Unhide" : "Hide from search")
                                      + (cmds.length > 1 ? " (" + cmds.length + ")" : ""));
      hideBtn.onclick = () => {
        writeShow(cmds, hidden ? (ALL_ENVS.length ? ALL_ENVS.slice() : null) : []);
        picked.clear();
        closeSheet();
        rerun();
      };
      actions.appendChild(hideBtn);
      const toggle = mk("button", "", showHidden ? "Hide hidden" : "Show hidden");
      toggle.onclick = () => {
        showHidden = !showHidden;
        try { localStorage.setItem(A.storageKey || "searchShowHidden", showHidden ? "1" : "0"); } catch (_) {}
        closeSheet();
        rerun();
      };
      actions.appendChild(toggle);
      const spacer = mk("span");
      spacer.style.flex = "1";
      actions.appendChild(spacer);
      const done = mk("button", "", "Done");
      done.onclick = () => closeSheet();
      actions.appendChild(done);
      return actions;
    }

    // The sheet's Rename — search-only. A blank name, or the original, drops the entry.
    function rename(cmd, name){
      name = (name || "").trim();
      if (name === (cmd.searchNative || cmd.name)) name = "";
      if (name) names[cmd.id] = name; else delete names[cmd.id];
      postStore("name", { cmd_id: cmd.id, name });
      closeSheet();
      rerun();
    }

    // Set or Clear (chord === ""): the adapter does the writing (Control Room's own
    // path), the kit shows the outcome and looks again once the binding has landed.
    async function applyShortcut(chord){
      if (!sheetCmd || !crRow) return;
      const cmd = sheetCmd, row = crRow;
      sheetBusy = true; sheetMsg = ""; renderSheet();
      let res;
      try { res = await A.setKey(cmd, chord, row); }
      catch (e){ res = { ok: false, error: String(e) }; }
      sheetBusy = false;
      sheetMsg = (res && res.ok) ? "" : ((res && res.error) || "did not take");
      if (sheetCmd === cmd) renderSheet();
      // The binding is written on the owner's own tick, so it lands a moment after it
      // says yes — one more look.
      setTimeout(() => { if (sheetCmd === cmd) reload(); }, 1300);
    }

    return {
      open, reload, rerun, render, handleKey, closeSheet, isSheetOpen,
      get env(){ return env; }, set env(v){ env = v || ""; },
      get items(){ return items; }, get index(){ return index; },
      get sheetCmd(){ return sheetCmd; },
      get showHidden(){ return showHidden; },
      hides(c){ return storeHides(c, env, show); },
      picked,
    };
  }

  return { wordStarts, rank, storeHides, highlight, escapeHtml, chordFrom, splitChord,
           postJSON, create };
})();
