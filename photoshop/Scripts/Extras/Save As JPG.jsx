
var newDocPath = "~/Desktop/";
var listOfPresetsAI = false; // When set to true the script won't save anything but instead gives you a list of pdf preset names.
var pdfProfileAI = "CMYK - Swop v2s";
var dialogOffsetX = 250; // Subtracts from the center of the screen = Center of the screen horizontally - 250px.
var dialogOffsetY = 200; // Just a static value = 200px from the top of the screen.

var o = {};

o.dialogTitle = "Save As jpg";
o.formats = ['jpg'];
o.app = 'ps';

function dialog(){
    var dlg = new Window("dialog");
    dlg.text = o.dialogTitle;

    var panel = dlg.add('panel');
    panel.alignChildren = ['left','center'];
    panel.orientation = 'row';

    var text1 = panel.add('statictext');
    text1.text = 'Filename: ';

    var text2 = panel.add('editText');

    // Create File name variable

        var hi = app.activeDocument.name.split('.')[0].split(' 16b')[0].split(' High Res')[0].split(' ');
        hi.shift();
        text2.text = hi.join(" ")

    text2.preferredSize = [530,23];
    text2.active = true;

    var button1 = panel.add('button', undefined, undefined, { name: 'cancel'});
    button1.text = "Cancel";

    var button2 = panel.add('button', undefined, undefined, { name: 'ok'});
    button2.text = "Save...";

    button2.onClick = function (e){
        save.init(dlg, text2.text);
    };

    dlg.onShow = function (){
        dlg.location.x = dlg.location.x - dialogOffsetX;
        dlg.location.y = dialogOffsetY;
    }

    dlg.show();
};

var save = {
    init: function(dlg, dialog_filename){
        dlg.close();

        var doc = app.activeDocument;

        var doc_path;

        try{
            doc_path = doc.path.toString();
        }catch(e){
            doc_path = newDocPath;
        };

        var output_folder = Folder.selectDialog('Output folder', doc_path === "" ? newDocPath : doc_path);

        if(output_folder != null){
            for (var i = 0; i < o.formats.length; i++){
                var save_options = save[ o.formats[i] ]();

                doc.saveAs(new File(output_folder + '/' + dialog_filename), save_options, (o.formats[i] === 'jpg' ? true : false), Extension.LOWERCASE);
            }
        };
    },

    jpg: function(){
        var jpg_Options = new JPEGSaveOptions();
        jpg_Options.embedColorProfile = true;
        jpg_Options.FormatOptions = FormatOptions.OPTIMIZEDBASELINE; // OPTIMIZEDBASELINE, PROGRESSIVE, STANDARDBASELINE
        jpg_Options.matte = MatteType.WHITE; // BACKGROUND, BLACK, FOREGROUND, NETSCAPE, NONE, SEMIGRAY, WHITE
        jpg_Options.quality = 12;
        return jpg_Options;
    }
};

function checkPresets(list, testPreset){
    var preset = null;
};

if(app.documents.length > 0){
    dialog();
};
