// Variables

    var strtRulerUnits = app.preferences.rulerUnits;
    var strtTypeUnits = app.preferences.typeUnits;
    app.preferences.rulerUnits = Units.PIXELS;
    app.preferences.typeUnits = TypeUnits.PIXELS;

    var pathLayerName = new RegExp(/path: /gim);
    var boundsLayerName = new RegExp(/Bounds Layer/gim);

    var currentLayer = app.activeDocument.activeLayer;

    if(app.activeDocument.activeLayer.visible == true){
        var currentLayerWasVisible = true;
    }else{
        var currentLayerWasVisible = false;
    };

try{
    if (boundsLayerName.test(app.activeDocument.layers[1].name) && pathLayerName.test(app.activeDocument.layers[0].name)){
        // Put current selection to variable

            var currentSelection = app.activeDocument.selection.bounds;

        // Crop

            cropToSelection();

        // Define path variable

            try{
                var myPathPreliminary = (app.activeDocument.layers[0].name).split("ath: ")[1];
                var myPath = Folder(myPathPreliminary);
            }catch(e){};

        if (myPath != undefined){
            // Define listOfFiles variable

                var listOfFiles = myPath.getFiles();

                if(listOfFiles.length < 10){
                    var newFileName = ("00" + (listOfFiles.length + 1).toString())
                };

                if(listOfFiles.length < 100 && listOfFiles.length > 9){
                    var newFileName = ("0" + (listOfFiles.length + 1).toString())
                };

                if(listOfFiles.length < 1000 && listOfFiles.length > 99){
                    var newFileName = ((listOfFiles.length + 1).toString())
                };

            SaveJPEG(File(myPath + "\\" + newFileName + ".jpg" ), 10);
        };

        // Select original image bounds

            app.activeDocument.activeLayer = app.activeDocument.layers[1];

            addActiveLayersTransparencyToSelection();

            app.activeDocument.activeLayer.visible = false;

        // Uncrop

            cropToSelection();

        // Deselect

            deselect();

        // Select orignal layer

            app.activeDocument.activeLayer = currentLayer;

        // Recreate screen selection

            var idsetd = charIDToTypeID( "setd" );
            var desc759 = new ActionDescriptor();
            var idnull = charIDToTypeID( "null" );
            var ref303 = new ActionReference();
            var idChnl = charIDToTypeID( "Chnl" );
            var idfsel = charIDToTypeID( "fsel" );
            ref303.putProperty( idChnl, idfsel );
            desc759.putReference( idnull, ref303 );
            var idT = charIDToTypeID( "T   " );
            var desc760 = new ActionDescriptor();
            var idTop = charIDToTypeID( "Top " );
            var idPxl = charIDToTypeID( "#Pxl" );
            desc760.putUnitDouble( idTop, idPxl, currentSelection[1] );
            var idLeft = charIDToTypeID( "Left" );
            var idPxl = charIDToTypeID( "#Pxl" );
            desc760.putUnitDouble( idLeft, idPxl, currentSelection[0] );
            var idBtom = charIDToTypeID( "Btom" );
            var idPxl = charIDToTypeID( "#Pxl" );
            desc760.putUnitDouble( idBtom, idPxl, currentSelection[3] );
            var idRght = charIDToTypeID( "Rght" );
            var idPxl = charIDToTypeID( "#Pxl" );
            desc760.putUnitDouble( idRght, idPxl, currentSelection[2] );
            var idRctn = charIDToTypeID( "Rctn" );
            desc759.putObject( idT, idRctn, desc760 );
            executeAction( idsetd, desc759, DialogModes.NO );

        // Ensure actuve lauyer's visiblity is correct

            app.activeDocument.activeLayer.visible = currentLayerWasVisible;
    }else{
        alert("Something is wrong with the first two layers' naming. Top layer should be named 'Path: [path]', and second layer from top should be named 'Bounds Layer' with the layer content matching desired bounds of the canvas")
    };
}catch(e){};

// Functions

    function SaveJPEG(saveFile, jpegQuality){
        var doc = activeDocument;
        if (doc.bitsPerChannel != BitsPerChannelType.EIGHT) doc.bitsPerChannel = BitsPerChannelType.EIGHT;
        jpgSaveOptions = new JPEGSaveOptions();
        jpgSaveOptions.embedColorProfile = true;
        jpgSaveOptions.formatOptions = FormatOptions.STANDARDBASELINE;
        jpgSaveOptions.matte = MatteType.NONE;
        jpgSaveOptions.quality = jpegQuality;
        activeDocument.saveAs(saveFile, jpgSaveOptions, true, Extension.LOWERCASE);
    };

    function cropToSelection() {
        try{
            var strtRulerUnits = app.preferences.rulerUnits;
            var strtTypeUnits = app.preferences.typeUnits;
            app.preferences.rulerUnits = Units.PIXELS;
            app.preferences.typeUnits = TypeUnits.PIXELS;
            var SB = activeDocument.selection.bounds;
            var desc14 = new ActionDescriptor();
            var desc15 = new ActionDescriptor();
            desc15.putUnitDouble( charIDToTypeID('Left'), charIDToTypeID('#Pxl'), SB[0].value );
            desc15.putUnitDouble( charIDToTypeID('Top '), charIDToTypeID('#Pxl'), SB[1].value  );
            desc15.putUnitDouble( charIDToTypeID('Rght'), charIDToTypeID('#Pxl'), SB[2].value  );
            desc15.putUnitDouble( charIDToTypeID('Btom'), charIDToTypeID('#Pxl'), SB[3].value  );
            desc14.putObject( charIDToTypeID('T   '), charIDToTypeID('Rctn'), desc15 );
            desc14.putUnitDouble( charIDToTypeID('Angl'), charIDToTypeID('#Ang'), 0.000000 );
            desc14.putBoolean( charIDToTypeID('Dlt '), false );
            desc14.putEnumerated( stringIDToTypeID('cropAspectRatioModeKey'), stringIDToTypeID('cropAspectRatioModeClass'), stringIDToTypeID('unconstrained') );
            executeAction( charIDToTypeID('Crop'), desc14, DialogModes.NO );
        }catch(e){
            alert("There is no selection!");
            }
        finally{
            app.preferences.rulerUnits = strtRulerUnits;
            app.preferences.typeUnits = strtTypeUnits;
        }
    };

    // Add active layer's transparency to existing selection

        function addActiveLayersTransparencyToSelection(){
            try{
                var idAdd = charIDToTypeID( "Add " );
                var desc390 = new ActionDescriptor();
                var idnull = charIDToTypeID( "null" );
                var ref148 = new ActionReference();
                var idChnl = charIDToTypeID( "Chnl" );
                var idChnl = charIDToTypeID( "Chnl" );
                var idTrsp = charIDToTypeID( "Trsp" );
                ref148.putEnumerated( idChnl, idChnl, idTrsp );
                desc390.putReference( idnull, ref148 );
                var idT = charIDToTypeID( "T   " );
                var ref149 = new ActionReference();
                var idChnl = charIDToTypeID( "Chnl" );
                var idfsel = charIDToTypeID( "fsel" );
                ref149.putProperty( idChnl, idfsel );
                desc390.putReference( idT, ref149 );
                executeAction( idAdd, desc390, DialogModes.NO );
            }catch(e){
                var idsetd = charIDToTypeID( "setd" );
                var desc1290 = new ActionDescriptor();
                var idnull = charIDToTypeID( "null" );
                var ref1102 = new ActionReference();
                var idChnl = charIDToTypeID( "Chnl" );
                var idfsel = charIDToTypeID( "fsel" );
                ref1102.putProperty( idChnl, idfsel );
                desc1290.putReference( idnull, ref1102 );
                var idT = charIDToTypeID( "T   " );
                var ref1103 = new ActionReference();
                var idChnl = charIDToTypeID( "Chnl" );
                var idChnl = charIDToTypeID( "Chnl" );
                var idTrsp = charIDToTypeID( "Trsp" );
                ref1103.putEnumerated( idChnl, idChnl, idTrsp );
                desc1290.putReference( idT, ref1103 );
                executeAction( idsetd, desc1290, DialogModes.NO );
            };
        };

    // Deselect

        function deselect(){
            var idsetd = charIDToTypeID( "setd" );
            var desc1389 = new ActionDescriptor();
            var idnull = charIDToTypeID( "null" );
            var ref1185 = new ActionReference();
            var idChnl = charIDToTypeID( "Chnl" );
            var idfsel = charIDToTypeID( "fsel" );
            ref1185.putProperty( idChnl, idfsel );
            desc1389.putReference( idnull, ref1185 );
            var idT = charIDToTypeID( "T   " );
            var idOrdn = charIDToTypeID( "Ordn" );
            var idNone = charIDToTypeID( "None" );
            desc1389.putEnumerated( idT, idOrdn, idNone );
            executeAction( idsetd, desc1389, DialogModes.NO );
        };
