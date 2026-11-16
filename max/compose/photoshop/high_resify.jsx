// High-resify — turn a finished Low Res PSB into the High Res one, keeping all your work.
//
// The old "H" mode: scale the document up to the high-res size (masks and painted
// adjustments scale with it), then relink every linked pass to the same file from
// the High Res render, and save it into the High Res folder. Needs the High Res
// render already prepared (High Res/ps/ exists).
#target photoshop

(function () {
    if (!app.documents.length) { alert("Open the Low Res PSB first."); return; }
    var src = app.activeDocument;
    var lowFolder = src.path;                                // …/<View>/Low Res
    var highPs = new Folder(lowFolder.parent + "/High Res/ps");
    var highPlan = new File(highPs + "/plan.json");
    if (!highPlan.exists) { alert("No High Res render found at\n" + highPs.fsName + "\nRender High Res first."); return; }
    highPlan.encoding = "UTF-8";
    highPlan.open("r");
    var plan = eval("(" + highPlan.read() + ")");
    highPlan.close();

    var cTID = charIDToTypeID, sTID = stringIDToTypeID;
    var oldUnits = app.preferences.rulerUnits;
    app.preferences.rulerUnits = Units.PIXELS;

    var doc = src.duplicate(plan.name, false);
    doc.resizeImage(UnitValue(plan.width, "px"), UnitValue(plan.height, "px"), doc.resolution, ResampleMethod.BICUBIC);

    var relinked = 0, missing = [];
    function relink(container) {
        for (var i = 0; i < container.layers.length; i++) {
            var layer = container.layers[i];
            if (layer.typename === "LayerSet") { relink(layer); continue; }
            if (layer.kind !== LayerKind.SMARTOBJECT) { continue; }
            doc.activeLayer = layer;
            var ref = new ActionReference();
            ref.putEnumerated(cTID("Lyr "), cTID("Ordn"), cTID("Trgt"));
            var so = executeActionGet(ref).getObjectValue(sTID("smartObject"));
            if (!so.hasKey(sTID("link"))) { continue; }       // embedded — leave it
            var name = File(so.getPath(sTID("link"))).name;
            var target = new File(highPs + "/" + decodeURI(name));
            if (!target.exists) { missing.push(decodeURI(name)); continue; }
            var d = new ActionDescriptor();
            d.putPath(cTID("null"), target);
            executeAction(sTID("placedLayerRelinkToFile"), d, DialogModes.NO);
            relinked++;
        }
    }
    relink(doc);

    var sd = new ActionDescriptor();
    var opts = new ActionDescriptor();
    opts.putBoolean(sTID("maximizeCompatibility"), false);
    sd.putObject(cTID("As  "), cTID("Pht8"), opts);
    sd.putPath(cTID("In  "), new File(plan.psb));
    executeAction(cTID("save"), sd, DialogModes.NO);
    app.preferences.rulerUnits = oldUnits;

    alert("High Res saved: " + plan.psb + "\n" + relinked + " passes relinked" +
          (missing.length ? "\nNot in the High Res render: " + missing.join(", ") : ""));
})();
