// Build a layered PSB from compose/prepare.py's plan.json.
//
//   osascript -e 'tell application id "com.adobe.Photoshop" to do javascript (file "<this>") with arguments {"<plan.json>"}'
//
// One pass of the plan, top to bottom — no loading everything and then sorting
// it layer by layer, no folder-name messages. Passes are LINKED smart objects
// (a re-render updates them in place). Mattes stay as small PNGs beside the PSB
// and are pulled in on demand by matte_picker.jsx; only the Glass layer gets
// its mask baked in here.
#target photoshop

// `arguments` is read HERE, at the top level: inside the function below it would be
// the function's own (empty) arguments, and build fell back to an Open dialog that
// left the osascript call hanging.
var ARGS = (typeof arguments !== "undefined") ? arguments : [];

(function (args) {
    var planFile = args.length ? new File(args[0])
                                                                          : File.openDialog("plan.json", "*.json");
    if (!planFile || !planFile.exists) { return "no plan"; }
    planFile.encoding = "UTF-8";
    planFile.open("r");
    var plan = eval("(" + planFile.read() + ")");   // ExtendScript has no JSON
    planFile.close();

    var cTID = charIDToTypeID, sTID = stringIDToTypeID;
    var BLEND = {
        "normal": BlendMode.NORMAL, "multiply": BlendMode.MULTIPLY, "screen": BlendMode.SCREEN,
        "linear dodge": BlendMode.LINEARDODGE, "pass through": BlendMode.PASSTHROUGH
    };

    var oldDialogs = app.displayDialogs;
    var oldUnits = app.preferences.rulerUnits;
    app.displayDialogs = DialogModes.NO;
    app.preferences.rulerUnits = Units.PIXELS;

    var doc = app.documents.add(plan.width, plan.height, 72, plan.name, NewDocumentMode.RGB,
                                DocumentFill.TRANSPARENT, 1, BitsPerChannelType.THIRTYTWO);

    function placeLinked(path) {
        var d = new ActionDescriptor();
        d.putPath(cTID("null"), new File(path));
        d.putBoolean(cTID("Lnkd"), true);
        d.putEnumerated(cTID("FTcs"), cTID("QCSt"), cTID("Qcsa"));
        var off = new ActionDescriptor();
        off.putUnitDouble(cTID("Hrzn"), cTID("#Pxl"), 0);
        off.putUnitDouble(cTID("Vrtc"), cTID("#Pxl"), 0);
        d.putObject(cTID("Ofst"), cTID("Ofst"), off);
        executeAction(cTID("Plc "), d, DialogModes.NO);
        return doc.activeLayer;
    }

    // Load an 8-bit PNG as the current selection (via a temporary channel).
    function selectFromPng(path) {
        var src = app.open(new File(path));
        src.selection.selectAll();
        src.selection.copy();
        src.close(SaveOptions.DONOTSAVECHANGES);
        app.activeDocument = doc;
        var ch = doc.channels.add();
        doc.activeChannels = [ch];
        doc.paste();
        doc.selection.load(ch, SelectionType.REPLACE);
        doc.activeChannels = doc.componentChannels;
        ch.remove();
    }

    function maskFromSelection() {
        var d = new ActionDescriptor();
        d.putClass(cTID("Nw  "), cTID("Chnl"));
        var r = new ActionReference();
        r.putEnumerated(cTID("Chnl"), cTID("Chnl"), cTID("Msk "));
        d.putReference(cTID("At  "), r);
        d.putEnumerated(cTID("Usng"), cTID("UsrM"), cTID("RvlS"));
        executeAction(cTID("Mk  "), d, DialogModes.NO);
        doc.selection.deselect();
    }

    function style(layer, node) {
        if (node.blend && BLEND[node.blend]) { layer.blendMode = BLEND[node.blend]; }
        if (node.opacity !== undefined) { layer.opacity = node.opacity; }
        if (node.visible === false) { layer.visible = false; }
    }

    // Build bottom-up, each new item going to the top of its container, so the
    // finished order matches the plan's top-to-bottom order.
    function build(nodes, parent) {
        for (var i = nodes.length - 1; i >= 0; i--) {
            var node = nodes[i];
            if (node.group !== undefined) {
                var set = parent.layerSets.add();
                set.name = node.group;
                if (!node.blend) { set.blendMode = BlendMode.PASSTHROUGH; }
                style(set, node);
                build(node.children || [], set);
            } else if (node.file) {
                var layer = placeLinked(plan.folder + "/" + node.file);
                layer.name = node.name;
                if (parent !== doc) { layer.move(parent, ElementPlacement.PLACEATBEGINNING); }
                style(layer, node);
                if (node.mask) {
                    doc.activeLayer = layer;
                    selectFromPng(plan.folder + "/" + node.mask);
                    doc.activeLayer = layer;
                    maskFromSelection();
                }
            }
        }
    }

    build(plan.stack, doc);

    // A black base so the additive groups have something defined to add onto.
    var base = doc.artLayers.add();
    base.name = "Base";
    doc.selection.selectAll();
    var black = new SolidColor(); black.rgb.red = black.rgb.green = black.rgb.blue = 0;
    doc.selection.fill(black);
    doc.selection.deselect();
    base.move(doc.layers[doc.layers.length - 1], ElementPlacement.PLACEAFTER);

    if (plan.bit_depth === 16) {
        var cd = new ActionDescriptor();
        cd.putInteger(cTID("Dpth"), 16);
        cd.putBoolean(cTID("Mrge"), false);
        cd.putBoolean(cTID("Rstr"), false);
        executeAction(cTID("CnvM"), cd, DialogModes.NO);
    }

    // Save as PSB (Large Document Format).
    var sd = new ActionDescriptor();
    var opts = new ActionDescriptor();
    opts.putBoolean(sTID("maximizeCompatibility"), false);
    sd.putObject(cTID("As  "), cTID("Pht8"), opts);
    sd.putPath(cTID("In  "), new File(plan.psb));
    sd.putBoolean(cTID("LwCs"), true);
    executeAction(cTID("save"), sd, DialogModes.NO);

    app.displayDialogs = oldDialogs;
    app.preferences.rulerUnits = oldUnits;
    return "built " + plan.psb;
})(ARGS);
