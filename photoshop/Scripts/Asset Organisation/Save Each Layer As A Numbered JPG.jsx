
var initialPrompt = prompt("Input folder path", "");

if(initialPrompt != "" && initialPrompt != undefined){
    for(i = 0; i < app.activeDocument.layers.length; i++){
        // Select

            app.activeDocument.activeLayer = app.activeDocument.layers[i];

        // Show

            app.activeDocument.activeLayer.visible = true;

        // Save

            // Variables

                var myNamePreliminary = ((i + 1).toString());

                if(myNamePreliminary.length < 4){
                    var myName = (myNamePreliminary)
                };

                if(myNamePreliminary.length < 3){
                    var myName = ("0" + myNamePreliminary)
                };

                if(myNamePreliminary.length < 2){
                    var myName = ("00" + myNamePreliminary)
                };

            // Save

                var saveFolder = new Folder(initialPrompt);
                var fileName = myName;
                var doc= activeDocument
                app.displayDialogs = DialogModes.NO;
                var jpgOptions = new JPEGSaveOptions();
                jpgOptions.quality = 10; //enter number or create a variable to set quality
                jpgOptions.embedColorProfile = true;
                jpgOptions.formatOptions = FormatOptions.STANDARDBASELINE;
                //other options///////////////////////////
                //jpgOptions.formatOptions = FormatOptions.PROGRESSIVE;
                //jpgOptions.formatOptions = FormatOptions.OPTIMIZEDBASELINE;
                if(jpgOptions.formatOptions == FormatOptions.PROGRESSIVE){
                jpgOptions.scans = 3}; //only used with Progressive
                jpgOptions.matte = MatteType.NONE;
                //jpgOptions.matte = MatteType.BACKGROUND;
                //jpgOptions.matte = MatteType.BLACK;
                //jpgOptions.matte = MatteType.FOREGROUND;
                //jpgOptions.matte = MatteType.NETSCAPE;
                //jpgOptions.matte = MatteType.SEMIGRAY;
                //jpgOptions.matte = MatteType.WHITE;
                doc.saveAs (new File(saveFolder +'/' + fileName + '.jpg'), jpgOptions)

        // Hide

            app.activeDocument.activeLayer.visible = false;
    };

    for(i = 0; i < app.activeDocument.layers.length; i++){
        // Select

            app.activeDocument.activeLayer = app.activeDocument.layers[i];

        // Show

            app.activeDocument.activeLayer.visible = true;
    };

    app.activeDocument.activeLayer = app.activeDocument.layers[0];

};
