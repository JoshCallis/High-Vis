// Refresh an existing PSB's linked passes after a re-render or a region patch.
//
//   osascript -e 'tell application id "com.adobe.Photoshop" to do javascript (file "<this>") with arguments {"<file.psb>"}'
//
// The passes are linked smart objects pointing at ps/*.exr, which prepare.py has
// just rewritten — so this is Layer ▸ Smart Objects ▸ Update All Modified Content,
// never a rebuild (a rebuild would throw away the work in the file).
// Already open: updated, NOT saved (your unsaved edits stay yours to save).
// Not open: opened, updated, saved, closed.
#target photoshop

// `arguments` is read HERE, at the top level: inside the function below it would be
// the function's own (empty) arguments, and build fell back to an Open dialog that
// left the osascript call hanging.
var ARGS = (typeof arguments !== "undefined") ? arguments : [];

(function (args) {
    var psb = args.length ? new File(args[0]) : null;
    if (!psb || !psb.exists) { return "no psb"; }

    var doc = null;
    for (var i = 0; i < app.documents.length; i++) {
        try {
            if (app.documents[i].fullName.fsName === psb.fsName) { doc = app.documents[i]; break; }
        } catch (e) { /* unsaved document: no fullName */ }
    }
    var wasOpen = doc !== null;
    var oldDialogs = app.displayDialogs;
    app.displayDialogs = DialogModes.NO;
    if (!wasOpen) { doc = app.open(psb); }
    app.activeDocument = doc;
    try {
        executeAction(stringIDToTypeID("placedLayerUpdateAllModified"), undefined, DialogModes.NO);
    } catch (e) { /* nothing modified */ }
    if (!wasOpen) { doc.close(SaveOptions.SAVECHANGES); }
    app.displayDialogs = oldDialogs;
    return (wasOpen ? "updated (open, not saved) " : "updated ") + psb.fsName;
})(ARGS);
