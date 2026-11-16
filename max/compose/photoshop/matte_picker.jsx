// Matte picker — choose mattes by name and turn them into a selection or a masked group.
//
// Replaces the old "Multimatte" group of rasterised 32-bit layers (one per material,
// all held in RAM). Mattes live as small PNGs in <render folder>/ps/mattes/ and are
// only loaded when you pick one. Every layer and every material that shows has one
// (compose/prepare.py); layer and material PNGs are cropped to what they cover and
// placed back at their plan.json offset. Materials too small to matter are listed
// only with "Show tiny materials" — they have no PNG.
#target photoshop

(function () {
    if (!app.documents.length) { alert("Open a render PSB first."); return; }
    var doc = app.activeDocument;
    var planFile = new File(doc.path + "/ps/plan.json");
    if (!planFile.exists) { alert("No ps/plan.json next to this document — was it built by the render pipeline?"); return; }
    planFile.encoding = "UTF-8";
    planFile.open("r");
    var plan = eval("(" + planFile.read() + ")");
    planFile.close();
    var mattes = plan.mattes;

    var cTID = charIDToTypeID;

    function hasSelection() {
        try { return !!doc.selection.bounds; } catch (e) { return false; }
    }

    function loadMatte(m, type) {
        var src = app.open(new File(plan.folder + "/" + m.file));
        var w = src.width.as("px"), h = src.height.as("px");
        src.selection.selectAll();
        src.selection.copy();
        src.close(SaveOptions.DONOTSAVECHANGES);
        app.activeDocument = doc;
        // Placing a cropped matte needs a selection (paste centres on it), so the
        // selection being added to / subtracted from is kept in a channel meanwhile.
        var keep = null;
        if (type !== SelectionType.REPLACE && hasSelection()) {
            keep = doc.channels.add();
            doc.selection.store(keep);
        }
        var ch = doc.channels.add();
        doc.activeChannels = [ch];
        if (m.offset) {
            var x = m.offset[0], y = m.offset[1];
            doc.selection.select([[x, y], [x + w, y], [x + w, y + h], [x, y + h]]);
        } else {
            doc.selection.deselect();
        }
        doc.paste();
        doc.selection.deselect();
        doc.activeChannels = doc.componentChannels;
        if (keep) {
            doc.selection.load(keep, SelectionType.REPLACE);
            keep.remove();
        }
        doc.selection.load(ch, type);
        ch.remove();
    }

    function groupWithMask(name) {
        var set = doc.layerSets.add();
        set.name = name;
        set.blendMode = BlendMode.PASSTHROUGH;
        var d = new ActionDescriptor();
        d.putClass(cTID("Nw  "), cTID("Chnl"));
        var r = new ActionReference();
        r.putEnumerated(cTID("Chnl"), cTID("Chnl"), cTID("Msk "));
        d.putReference(cTID("At  "), r);
        d.putEnumerated(cTID("Usng"), cTID("UsrM"), cTID("RvlS"));
        executeAction(cTID("Mk  "), d, DialogModes.NO);
        doc.selection.deselect();
    }

    function pct(c) {
        var p = c * 100;
        return p >= 1 ? Math.round(p) + "%" : p >= 0.1 ? p.toFixed(1) + "%" : "<0.1%";
    }

    // Sections, in order. Layers keep the scene's tree order (prepare writes parents
    // first); materials biggest first.
    var SECTIONS = [
        {title: "LAYERS", test: function (m) { return m.group === "layer" || m.group === "object"; }},
        {title: "MATERIALS", test: function (m) { return m.group === "material"; }, sort: true},
        {title: "OTHER", test: function (m) { return m.group !== "layer" && m.group !== "object" && m.group !== "material"; }}
    ];

    // ── Dialog ──────────────────────────────────────────────────────────────
    var w = new Window("dialog", "Mattes — " + plan.name);
    w.alignChildren = "fill";
    var search = w.add("edittext", undefined, "");
    search.helpTip = "Type to filter";
    var list = w.add("listbox", [0, 0, 380, 460], [], {multiselect: true});
    var tiny = w.add("checkbox", undefined, "Show tiny materials (no matte file)");

    function fill() {
        list.removeAll();
        var q = search.text.toLowerCase();
        for (var s = 0; s < SECTIONS.length; s++) {
            var sec = SECTIONS[s], rows = [];
            for (var i = 0; i < mattes.length; i++) {
                var m = mattes[i];
                if (!sec.test(m) || (m.skipped && !tiny.value)) { continue; }
                if (q && m.name.toLowerCase().indexOf(q) < 0) { continue; }
                rows.push(m);
            }
            if (!rows.length) { continue; }
            if (sec.sort) { rows.sort(function (a, b) { return (b.coverage || 0) - (a.coverage || 0); }); }
            list.add("item", "— " + sec.title + " —");
            for (var j = 0; j < rows.length; j++) {
                var r = rows[j], label = r.name;
                if (r.group === "layer") {
                    var parts = r.name.split("/");
                    label = new Array(parts.length).join("    ") + parts[parts.length - 1];
                }
                if (r.coverage !== undefined) { label += "   " + pct(r.coverage); }
                if (r.skipped) { label += "  · tiny"; }
                var item = list.add("item", label);
                item.matte = r;
            }
        }
    }
    fill();
    search.onChanging = fill;
    tiny.onClick = fill;

    var row = w.add("group");
    var bSel = row.add("button", undefined, "Select");
    var bAdd = row.add("button", undefined, "Add");
    var bSub = row.add("button", undefined, "Subtract");
    var bGrp = row.add("button", undefined, "Group with mask");
    var bClose = w.add("button", undefined, "Close", {name: "cancel"});
    bGrp.helpTip = "New group above the active layer, masked to the chosen mattes — put adjustments inside";

    function chosen() {
        var out = [];
        if (!list.selection) { return out; }
        for (var i = 0; i < list.selection.length; i++) {
            var m = list.selection[i].matte;
            if (m && m.file) { out.push(m); }    // headers and tiny materials have no file
        }
        return out;
    }

    var oldUnits = app.preferences.rulerUnits;
    function withPixels(fn) {
        app.preferences.rulerUnits = Units.PIXELS;
        try { return fn(); } finally { app.preferences.rulerUnits = oldUnits; }
    }

    function apply(first) {
        var c = chosen();
        if (!c.length) { return null; }
        withPixels(function () {
            for (var i = 0; i < c.length; i++) {
                loadMatte(c[i], i === 0 ? first : SelectionType.EXTEND);
            }
        });
        return c;
    }

    bSel.onClick = function () { if (apply(SelectionType.REPLACE)) { w.close(); } };
    bAdd.onClick = function () { if (apply(SelectionType.EXTEND)) { w.close(); } };
    bSub.onClick = function () {
        var c = chosen();
        withPixels(function () {
            for (var i = 0; i < c.length; i++) { loadMatte(c[i], SelectionType.DIMINISH); }
        });
        if (c.length) { w.close(); }
    };
    bGrp.onClick = function () {
        var c = apply(SelectionType.REPLACE);
        if (!c) { return; }
        var names = [];
        for (var i = 0; i < c.length; i++) { names.push(c[i].name); }
        groupWithMask(names.join(" + "));
        w.close();
    };
    list.onDoubleClick = bSel.onClick;
    w.show();
})();
