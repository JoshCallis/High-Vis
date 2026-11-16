/* fingers.js — a finger count is drawn as a hand, never spelled. Also: No Modifier
 * (a fist), Space Held and ␣ (Saturn), Command Held (⌘), and No Key in a By Modifier
 * heading (—). Same technique for all: the words stay, hidden, inside the glyph.
 *
 * "One Finger", "Two Fingers", "2 Fingers", "Three-Finger Tap", "Four Or More
 * Fingers", "One finger down"… anywhere on the page become a small hand with that
 * many fingers up (lowered ones show as knuckles, five = the thumb out too). The
 * pages keep writing words — this is display only, done to the DOM after the fact
 * by a MutationObserver, so nothing that builds or matches a label changes.
 *
 * The words stay in the DOM, visually hidden inside the icon's span, so
 * textContent, search, copy and every label → value lookup read exactly what
 * they did before; the hover title says them too.
 *
 * Skipped: inputs, textareas, contenteditable (a rename in progress), and
 * anything already inside an icon (which is what stops the observer re-feeding
 * itself on its own hidden text).
 */
(() => {
  const WORD = { no: 0, zero: 0, one: 1, two: 2, three: 3, four: 4, five: 5 };
  const N = "(No|Zero|One|Two|Three|Four|Five|[0-5])";
  // Groups: 1-3 a finger count, 4 No Modifier, 5 Space Held, 6 Command Held, 7 No Key,
  // 8 the ␣ glyph. A finger count swallows a trailing " down" ("One finger down").
  const RE = new RegExp(
    `\\b(?:${N} (?:Or More|To ${N}) Fingers|${N}[ -]Fingers?)(?: down)?\\b`
    + `|\\b(No Modifier)\\b|\\b(Space Held)\\b|\\b(Command Held)\\b|\\b(No Key)\\b|(\u2423)`, "gi");
  const num = s => s == null ? null : (/\d/.test(s) ? Number(s) : WORD[s.toLowerCase()]);

  // viewBox 0 0 24 24. Slim round-capped fingers on a palm that narrows to a
  // wrist; index, middle, ring, pinky left → right, so a count reads left to right
  // like counting on a hand. Each count is its own natural pose (POSES): one is
  // the index straight up, two a peace sign (both leaning out equally), three
  // fans round a vertical middle, four and five spread like an open hand — so the
  // gaps open toward the tips and stay countable small. Lowered fingers are
  // curled: a knuckle just above the palm.
  // The palm is upright and mirror-symmetric about x 12.8 (the knuckles' centre too),
  // so a finger's lean is its direction on screen — a skewed palm made a vertical
  // finger look bent against the hand.
  const PALM = "M6.2 13.6C6.2 12.5 7 11.8 8.1 11.8H17.5C18.6 11.8 19.4 12.5 19.4 13.6"
             + "L18.9 18C18.6 19.8 17.7 21 16.6 21.8V23.4H9V21.8C7.9 21 7 19.8 6.7 18Z";
  const FINGERS = [   // [knuckle x, raised length] — index, middle, ring, pinky
    [7.7, 10.2], [11.2, 11.8], [14.7, 10.8], [17.9, 8.4]];
  const POSES = {     // count → each raised finger's lean in degrees (− left, + right)
    1: [0], 2: [-11, 11], 3: [-15, 0, 15], 4: [-17, -5, 7, 20], 5: [-17, -5, 7, 20]};
  const BASE = 13, CURLED = 10.9;
  const r1 = v => Math.round(v * 10) / 10;
  function hand(n) {
    let s = `<path d="${PALM}" stroke-width="1" stroke-linejoin="round"/>`;
    const pose = POSES[n] || [];
    FINGERS.forEach(([x, len], i) => {
      const t = (pose[i] || 0) * Math.PI / 180;
      const [x2, y2] = i < n ? [x + len * Math.sin(t), BASE - len * Math.cos(t)] : [x, CURLED];
      s += `<line x1="${x}" y1="${BASE}" x2="${r1(x2)}" y2="${r1(y2)}"/>`;
    });
    // The thumb: folded against the palm's side, or out wide for five.
    s += n >= 5 ? '<line x1="7.6" y1="19.4" x2="2.4" y2="13.4"/>'
                : '<line x1="7" y1="19.8" x2="5.2" y2="16.6"/>';
    return '<svg class="fing-h" viewBox="0 0 24 24" aria-hidden="true" fill="currentColor" '
         + 'stroke="currentColor" stroke-width="2.6" stroke-linecap="round">' + s + "</svg>";
  }

  // Saturn: a ball with its flat ring, for Space (held). viewBox 0 0 24 24. The ring is a band
  // seen obliquely: wide at the ends, thin across the middle, with the far half hidden behind
  // the ball and a gap cut round the near half so it reads as lying in front.
  function saturn() {
    const ring = '<path fill-rule="evenodd" d="M0.2 12a11.8 3.6 0 1 0 23.6 0a11.8 3.6 0 1 0-23.6 0Z'
               + 'M4.2 12a7.8 1.9 0 1 0 15.6 0a7.8 1.9 0 1 0-15.6 0Z"/>';
    const box = 'maskUnits="userSpaceOnUse" x="-6" y="-6" width="36" height="36"';
    return '<svg class="fing-s" viewBox="0 0 24 24" aria-hidden="true" fill="currentColor" stroke="none">'
      + '<g transform="rotate(-24 12 12)"><defs>'
      + '<clipPath id="sat-f"><rect x="-6" y="12" width="36" height="18"/></clipPath>'
      + '<mask id="sat-b" ' + box + '><rect x="-6" y="-6" width="36" height="18" fill="#fff"/>'
      + '<circle cx="12" cy="12" r="5.6" fill="#000"/></mask>'
      + '<mask id="sat-p" ' + box + '><rect x="-6" y="-6" width="36" height="36" fill="#fff"/>'
      + '<g clip-path="url(#sat-f)" fill="#000" stroke="#000" stroke-width="1.8">' + ring + '</g></mask></defs>'
      + '<g mask="url(#sat-b)">' + ring + '</g>'
      + '<circle cx="12" cy="12" r="5.6" mask="url(#sat-p)"/>'
      + '<g clip-path="url(#sat-f)">' + ring + '</g></g></svg>';
  }

  function icon(phrase, m) {
    const span = document.createElement("span");
    span.className = "fing";
    span.title = phrase;
    let html;
    if (m[3] != null) html = hand(num(m[3]));                                    // "Two Fingers"
    else if (m[2] != null) html = hand(num(m[1])) + '<span class="fing-x">–</span>' + hand(num(m[2]));
    else if (m[1] != null) html = hand(num(m[1])) + '<span class="fing-x">+</span>';   // "Four Or More"
    else if (m[4] != null) html = hand(0);                                       // No Modifier
    else if (m[5] != null || m[8] != null) html = saturn();                      // Space Held, ␣
    else if (m[6] != null) html = '<span class="fing-g">\u2318</span>';          // Command Held
    else html = '<span class="fing-g">\u2014</span>';                            // No Key
    span.innerHTML = html;
    const t = document.createElement("span");
    t.className = "fing-t";
    t.textContent = phrase;
    span.appendChild(t);
    return span;
  }

  const SKIP = "input, textarea, script, style, [contenteditable=''], [contenteditable='true'], .fing";
  function decorate(node) {
    const text = node.nodeValue;
    RE.lastIndex = 0;
    if (!RE.test(text)) return;
    const p = node.parentElement;
    if (!p || p.closest(SKIP)) return;
    const frag = document.createDocumentFragment();
    let last = 0, m, any = false;
    RE.lastIndex = 0;
    while ((m = RE.exec(text))) {
      if (m[7] != null && !p.closest(".modhead")) continue;      // No Key is a word elsewhere
      any = true;
      if (m.index > last) frag.appendChild(document.createTextNode(text.slice(last, m.index)));
      frag.appendChild(icon(m[0], m));
      last = m.index + m[0].length;
    }
    if (!any) return;
    if (last < text.length) frag.appendChild(document.createTextNode(text.slice(last)));
    p.replaceChild(frag, node);
  }
  function scan(root) {
    if (root.nodeType === 3) return decorate(root);
    if (root.nodeType !== 1 || root.closest && root.closest(SKIP)) return;
    const w = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
    const hits = [];
    for (let n; (n = w.nextNode());) { RE.lastIndex = 0; if (RE.test(n.nodeValue)) hits.push(n); }
    hits.forEach(decorate);
  }

  const css = document.createElement("style");
  css.textContent = `
    .fing { display: inline-flex; align-items: flex-end; gap: 0.05em;
            vertical-align: -0.32em; margin: 0 0.12em; position: relative; }
    .fing:first-child { margin-left: 0; }
    .fing-h { width: 1.55em; height: 1.55em; flex: none; overflow: visible; }
    .fing-s { width: 1.7em; height: 1.7em; flex: none; overflow: visible; align-self: center; }
    .fing-g { font-size: 1.05em; line-height: 1; align-self: center; }
    .fing-x { font-size: 0.8em; line-height: 1; padding-bottom: 0.15em; opacity: 0.8; }
    .fing-t { position: absolute; width: 1px; height: 1px; overflow: hidden;
              clip-path: inset(50%); white-space: nowrap; }`;
  document.head.appendChild(css);

  function start() {
    scan(document.body);
    new MutationObserver(muts => {
      for (const mu of muts) {
        if (mu.type === "characterData") decorate(mu.target);
        else mu.addedNodes.forEach(scan);
      }
    }).observe(document.body, { childList: true, subtree: true, characterData: true });
  }
  // A page that only wants the glyphs (fusion_value's search rows) sets
  // window.FINGERS_GLYPHS_ONLY before loading this — no scan, no observer.
  if (window.FINGERS_GLYPHS_ONLY) {}
  else if (document.body) start();
  else document.addEventListener("DOMContentLoaded", start);

  window.Fingers = { hand, saturn };
  window.Glyphs = { saturn, hand };
})();
