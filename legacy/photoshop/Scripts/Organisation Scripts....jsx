// Determine whether script is being run by 3DS Max

    try{
        if(app.activeDocument.name == "3DS Max Metadata.psb"){
            var runBy3dsMax = true
        }else{
            var runBy3dsMax = false
        };
    }catch(e){
        var runBy3dsMax = false
    };

// Prompt

    if(runBy3dsMax != true){
        var initialPrompt = prompt("I: Initial R: Rerender Same Location\n T: Rerender New Location\nS: Shift 16b H: High Resify", "");
    }else{
        var initialPrompt = app.activeDocument.layers.getByName("initialPrompt").layers[0].name
    };

// Globals

    // Global variables

        var layersToHide = [];

    // Polyfills

        // string.endsWith

            if (!String.prototype.endsWith) {
            	String.prototype.endsWith = function(search, this_len) {
            		if (this_len === undefined || this_len > this.length) {
            			this_len = this.length;
            		}
            		return this.substring(this_len - search.length, this_len) === search;
            	};
            }

        // string.startsWith

            if (!String.prototype.startsWith) {
                String.prototype.startsWith = function(search, pos) {
                    return this.substr(!pos || pos < 0 ? 0 : +pos, search.length) === search;
                };
            }

// Time

    /*
    var totalTime = new TimeIt();
    */

// Run the script

        if (initialPrompt == "i" || initialPrompt == "I"){
            initialOrganisationForSpecified();
        };

        if (initialPrompt == "r" || initialPrompt == "R"){
            rerenderOrganisationSameLocationForSpecified();
        };

        if (initialPrompt == "t" || initialPrompt == "T"){
            rerenderOrganisationForSpecified();
        };

        if (initialPrompt == "s" || initialPrompt == "S"){
            // Hide palettes

                if(initialPrompt != undefined){
                    app.togglePalettes();
                };

                if(app.documents.length == 0){
                    var dontShowPalettes = "True"
                }else{
                    var dontShowPalettes = "False"
                };

            shiftTo16bMode();
        };

        if (initialPrompt == "h" || initialPrompt == "H"){
            highResifyForSpecified();
        };

        if (initialPrompt == "m" || initialPrompt == "M"){
            multimatteMasksReplacement();

            collapseAllGroups();
        };

        if (initialPrompt == "0"){
           setCanvasSizeToDiffusePassSizeFromActiveDocumentsLocation(0);
        };

// Close metadata file if open

    try{
        app.documents.getByName("3DS Max Metadata.psb").close(SaveOptions.DONOTSAVECHANGES);
    }catch(e){};

// Show palettes

   if(initialPrompt != undefined){
      app.togglePalettes();
   };

// Functions

    // High Resify

        // For specified

            function highResifyForSpecified(){
                // Prompt for root folder path

                    if(runBy3dsMax != true){
                        var rootFolderPath = prompt("Specify folder path...", "");

                        // Get current folder if relevant

                            if(rootFolderPath == "C" || rootFolderPath == "c"){
                                try{
                                    var rootFolderPath = app.activeDocument.path.fsName.replace(/%20/g, " ");

                                    var rootFolderPathTextToSplitPrelim = rootFolderPath.split("\\");
                                    var rootFolderPathTextToSplit = ("\\" + rootFolderPathTextToSplitPrelim[rootFolderPathTextToSplitPrelim.length - 2] + "\\" + rootFolderPathTextToSplitPrelim[rootFolderPathTextToSplitPrelim.length - 1]);

                                    var rootFolderPath = rootFolderPath.split(rootFolderPathTextToSplit)[0];
                                }catch(e){};
                            };
                    }else{
                        var rootFolderPath = app.activeDocument.layers.getByName("rootFolderPath").layers[0].name
                    };

                    if(rootFolderPath == undefined || rootFolderPath == ""){
                        return;
                    };

                // Prompt for frame number(s)

                    if(runBy3dsMax != true){
                        var promptForFrameNumber = prompt("Specify frame number (if multiple, separate each with a comma and space), or type \'All\'", "");
                    }else{
                        var promptForFrameNumber = app.activeDocument.layers.getByName("promptForFrameNumber").layers[0].name
                    };

                    if(promptForFrameNumber == undefined){
                        return;
                    };

                // Prompt for overwrite decision

                    if(runBy3dsMax != true){
                        var promptForOverWriteDecision = prompt("Overwrite any existing high res files found? Type Y for yes, or leave blank", "");
                    }else{
                        var promptForOverWriteDecision = app.activeDocument.layers.getByName("promptForOverWriteDecision").layers[0].name
                    };

                    if(promptForOverWriteDecision == "Y" || promptForOverWriteDecision == "y"){
                        var overwriteExistingFilesYesNo = "true"
                    }else{
                        var overwriteExistingFilesYesNo = "false"
                    };

                // Set up for "All" if applicable

                    if(promptForFrameNumber == "All" || promptForFrameNumber == "all" || promptForFrameNumber == "ALL" || promptForFrameNumber == "A"|| promptForFrameNumber == "a"){
                        // Get number of frame folders

                            // Variables etc

                                var rootPath = rootFolderPath
                                var targetLayers = new Array;
                                var subDirectory = "/LinkedLayers/";
                                var configFolder = Folder(rootPath);
                                var fileList = configFolder.getFiles();

                                var frameCount = 0

                            // Count frames

                                // Create frameNumbersArray variable

                                    var frameNumbersArray = [];

                                for (var a = 0; a < fileList.length; a++){
                                    var frameNumberToPush = fileList[a].toString().split("/")[fileList[a].toString().split("/").length - 1].replace(/%20/g, " ").split(" ")[0]

                                    frameNumbersArray.push(frameNumberToPush)

                                    frameCount++
                                };

                            // Create listOfFrameNumbers variable

                                var listOfFrameNumbers = frameNumbersArray
                    }else{
                        // Create listOfFrameNumbers variable

                            var listOfFrameNumbers = promptForFrameNumber.split(", ")
                    };

                // Hide palettes

                    if(initialPrompt != undefined){
                        app.togglePalettes();
                    };

                    if(app.documents.length == 0){
                        var dontShowPalettes = "True"
                    }else{
                        var dontShowPalettes = "False"
                    };

                // Loop through frames and run the script

                    for(var a = 0; a < listOfFrameNumbers.length; a++){
                        // Create frameNumber variable

                            var frameNumber = listOfFrameNumbers[a].toString();

                        // Create folder path variable

                            // Loop through all folders in the root folder and find the folder for the current frame number

                                // Variables etc

                                    var rootPath = rootFolderPath
                                    var targetLayers = new Array;
                                    var subDirectory = "/LinkedLayers/";
                                    var configFolder = Folder(rootPath);
                                    var fileList = configFolder.getFiles();

                                // Create empty folder path variable

                                    var folderPath = ""
                                    var frameName = ""

                                // Loop

                                    for (var b = 0; b < fileList.length; b ++){
                                        // Variables etc

                                            var tempPreliminary = fileList[b].toString().replace(/\\/g, "/")
                                            var temp = tempPreliminary.split("/")[tempPreliminary.split("/").length - 1];
                                            var tempNoSpaces = temp.replace(/%20/g, " ").toString()
                                            var frameNumberPlusSpace = frameNumber + " "

                                        if (tempNoSpaces.startsWith(frameNumberPlusSpace)){
                                            // Create folder path variable

                                                var folderPath = rootFolderPath + "/" + tempNoSpaces + "/" + "Low Res"
                                                var frameName = temp.replace(/%20/g, " ");
                                        };
                                    };

                        // Run the script

                            if(folderPath == undefined || folderPath == ""){
                            }else{
                                // Run high resify script

                                    // Variables etc

                                        var rootPath = folderPath
                                        var targetLayers = new Array;
                                        var subDirectory = "/LinkedLayers/";
                                        var configFolder = Folder(rootPath);
                                        var fileList = configFolder.getFiles();

                                    // Run script on relevant files
                                        try{
                                            try{
                                                var fileRef = new File(folderPath + "/" + frameName + ".psb");

                                                app.open(fileRef);

                                                setZoom();
                                            }catch(e){
                                                // Create new file

                                                    app.documents.add()

                                                // Save file as frameName

                                                    SavePSB(folderPath + "/" + frameName)

                                                // Initial Organisation

                                                    initialOrganisation();
                                            };

                                            // High resify

                                                highResify(overwriteExistingFilesYesNo);

                                            // Set zoom

                                                setZoom();
                                        }catch(e){};
                            };
                    };
            };

        // Main function

            function highResify(overwriteExistingFilesYesNo){
                // Test if high res folder exists and contains passes

                    // Variables etc

                        var rootPath = app.activeDocument.path.fsName.replace(/%20/g, " ").split("Low Res")[0] + "High Res"
                        var targetLayers = new Array;
                        var subDirectory = "/LinkedLayers/";
                        var configFolder = Folder(rootPath);
                        var fileList = configFolder.getFiles();
												var wordDiffuse = new RegExp(/diffuse/gim)

                    // Loop

                        for (var b = fileList.length -1; b >= 0  ; b--){
														var temp = fileList[b]

                            if(wordDiffuse.test(temp)){
																var highResPassesExist = true
														};
                        };

                    if(highResPassesExist == true){
                        try{
                            // Save

                                saveFileOnlyIfChangesWereMade(app.activeDocument);

                            // If overwrite variable is true, delete the relevant high res files

                                if(overwriteExistingFilesYesNo == "true"){
                                    var fileToRemove = new File(app.activeDocument.path.fsName.replace(/%20/g, " ").split("Low Res")[0] + "High Res" + "/" + app.activeDocument.name.split(".psb")[0] + " High Res.psb");

                                    if (fileToRemove.exists){
                                        fileToRemove.remove();
                                    };

                                    try{
                                        app.documents.getByName(app.activeDocument.name.split(".psb")[0] + " High Res.psb").close(SaveOptions.DONOTSAVECHANGES);
                                    }catch(e){};

                                    var fileToRemove = new File(app.activeDocument.path.fsName.replace(/%20/g, " ").split("Low Res")[0] + "High Res" + "/" + app.activeDocument.name.split(".psb")[0] + " High Res 16b.psb");

                                    if (fileToRemove.exists){
                                        fileToRemove.remove();
                                    };

                                    try{
                                        app.documents.getByName(app.activeDocument.name.split(".psb")[0] + " High Res 16b.psb").close(SaveOptions.DONOTSAVECHANGES);
                                    }catch(e){};
                                };

                            // Try to open relevant high res file, to determine if it exists

                                try{
                                    var fileRef = new File(app.activeDocument.path.fsName.replace(/%20/g, " ").split("Low Res")[0] + "High Res" + "/" + app.activeDocument.name.split(".psb")[0] + " High Res.psb");
                                    app.open(fileRef);

                                    // Try to open 16b version

                                        try{
                                            var fileRef = new File(app.activeDocument.path.fsName + "/" + app.activeDocument.name.split(".psb")[0] + " 16b.psb");
                                            app.open(fileRef);

                                            // Ensure all modified content is updated

                                                var idplacedLayerUpdateAllModified = stringIDToTypeID( "placedLayerUpdateAllModified" );
                                                executeAction( idplacedLayerUpdateAllModified, undefined, DialogModes.NO );

                                            saveFileOnlyIfChangesWereMade(app.activeDocument)
                                        }catch(e){};

                                    app.documents.getByName(app.activeDocument.name.split(" High Res")[0] + ".psb").close(SaveOptions.DONOTSAVECHANGES)
                                }catch(e){};

                            // If the 16b file didn't exist, create it, otherwise close the original file

                                var tempName = app.activeDocument.name;
                                var wordHighRes16b = new RegExp(/high res 16b/gim);

                                if(!wordHighRes16b.test(tempName)){
                                    // If the 32b file didn't exist, create it, otherwise close the original file

                                        var tempName = app.activeDocument.name;
                                        var wordHighRes = new RegExp(/high res/gim);

                                        if(!wordHighRes.test(tempName)){
                                            try{
                                                // Change resolution to 400% of current resolution

                                                    var idImgS = charIDToTypeID( "ImgS" );
                                                    var desc568 = new ActionDescriptor();
                                                    var idWdth = charIDToTypeID( "Wdth" );
                                                    var idPrc = charIDToTypeID( "#Prc" );
                                                    desc568.putUnitDouble( idWdth, idPrc, 400.000000 );
                                                    var idscaleStyles = stringIDToTypeID( "scaleStyles" );
                                                    desc568.putBoolean( idscaleStyles, true );
                                                    var idCnsP = charIDToTypeID( "CnsP" );
                                                    desc568.putBoolean( idCnsP, true );
                                                    var idIntr = charIDToTypeID( "Intr" );
                                                    var idIntp = charIDToTypeID( "Intp" );
                                                    var idautomaticInterpolation = stringIDToTypeID( "automaticInterpolation" );
                                                    desc568.putEnumerated( idIntr, idIntp, idautomaticInterpolation );
                                                    executeAction( idImgS, desc568, DialogModes.NO );

                                                // Save file in new location

                                                    var pathPreliminary2 = app.activeDocument.path.toString()
                                                    var pathPreliminary = pathPreliminary2.replace(/%20/g, " ")
                                                    var Path = pathPreliminary.split("Low Res")[0] + "High Res";
                                                    var Name = app.activeDocument.name.split(".psb")[0];
                                                    var pathPlusName = File(Path + "/" + Name + " High Res.psb");

                                                    SavePSB(pathPlusName);
                                            }catch(e){};
                                        }else{
                                            //# Close original file (risky, need to improve at some point. If another file with that name is open, things could go very badly)

                                                try{
                                                    app.documents.getByName(app.activeDocument.name.split(" High Res.psb")[0] + ".psb").close(SaveOptions.DONOTSAVECHANGES);
                                                }catch(e){};
                                        };

                                    // Zoom out

                                        setZoom();

                                    //# Run rerender organisation script (need to add code to only do this if ensure variable is true)

                                        rerenderOrganisation();

                                    // Save

                                        saveFileOnlyIfChangesWereMade(app.activeDocument);

                                    // Open 16b version of low res file, or create one

                                        try{
                                            var fileRef = new File(app.activeDocument.path.fsName.replace(/%20/g, " ").split("High Res")[0] + "Low Res" + "/" + app.activeDocument.name.split(" High Res")[0] + " 16b.psb");
                                            app.open( fileRef );
                                        }catch(e){};

                                        var docName = app.activeDocument.name
                                        var word16b = new RegExp (/16b/gim);

                                        if(word16b.test(docName)){
                                            // Close 32b version(s) of file if still open

                                                try{
                                                    app.documents.getByName(app.activeDocument.name.split(" 16b")[0] + ".psb").close(SaveOptions.DONOTSAVECHANGES);
                                                }catch(e){};

                                                try{
                                                    app.documents.getByName(app.activeDocument.name.split(" 16b")[0]).close(SaveOptions.DONOTSAVECHANGES);
                                                }catch(e){};

                                                try{
                                                    app.documents.getByName(app.activeDocument.name.split(" High Res 16b")[0] + ".psb").close(SaveOptions.DONOTSAVECHANGES);
                                                }catch(e){};

                                                try{
                                                    app.documents.getByName(app.activeDocument.name.split(" High Res 16b")[0] + ".psb").close(SaveOptions.DONOTSAVECHANGES);
                                                }catch(e){};

                                            // Ensure all modified content is updated

                                                var idplacedLayerUpdateAllModified = stringIDToTypeID( "placedLayerUpdateAllModified" );
                                                executeAction( idplacedLayerUpdateAllModified, undefined, DialogModes.NO );

                                            // Make sure image is cropped to original image

                                                try{
                                                    app.activeDocument.activeLayer = app.activeDocument.layers.getByName("Total Lighting Group").layers.getByName("Diffuse Group").layers.getByName("Diffuse");

                                                    createSelectionFromActiveLayersThubnail();

                                                    cropToSelection();

                                                    try{
                                                        app.activeDocument.layers.getByName("setCanvasSizeToDiffusePassSizeFromActiveDocumentsLocation Dummy Layer").remove();
                                                    }catch(e){};
                                                }catch(e){};

                                            // Change resolution to 400% of current resolution

                                                var idImgS = charIDToTypeID( "ImgS" );
                                                var desc568 = new ActionDescriptor();
                                                var idWdth = charIDToTypeID( "Wdth" );
                                                var idPrc = charIDToTypeID( "#Prc" );
                                                desc568.putUnitDouble( idWdth, idPrc, 400.000000 );
                                                var idscaleStyles = stringIDToTypeID( "scaleStyles" );
                                                desc568.putBoolean( idscaleStyles, true );
                                                var idCnsP = charIDToTypeID( "CnsP" );
                                                desc568.putBoolean( idCnsP, true );
                                                var idIntr = charIDToTypeID( "Intr" );
                                                var idIntp = charIDToTypeID( "Intp" );
                                                var idautomaticInterpolation = stringIDToTypeID( "automaticInterpolation" );
                                                desc568.putEnumerated( idIntr, idIntp, idautomaticInterpolation );
                                                executeAction( idImgS, desc568, DialogModes.NO );

                                            // Save file in new location

                                                var pathPreliminary2 = app.activeDocument.path.toString()
                                                var pathPreliminary = pathPreliminary2.replace(/%20/g, " ")
                                                var Path = pathPreliminary.split("Low Res")[0] + "High Res";
                                                var Name = app.activeDocument.name.split(" 16b")[0];
                                                var pathPlusName = File(Path + "/" + Name.split(".psb")[0] + " High Res 16b.psb");

                                                SavePSB(pathPlusName);

                                            // Zoom out

                                                setZoom();

                                            // Close 32b version(s) of file if still open

                                                try{
                                                    app.documents.getByName(app.activeDocument.name.split(" 16b")[0] + ".psb").close(SaveOptions.DONOTSAVECHANGES);
                                                }catch(e){};

                                                try{
                                                    app.documents.getByName(app.activeDocument.name.split(" 16b")[0]).close(SaveOptions.DONOTSAVECHANGES);
                                                }catch(e){};

                                                try{
                                                    app.documents.getByName(app.activeDocument.name.split(" High Res 16b")[0] + ".psb").close(SaveOptions.DONOTSAVECHANGES);
                                                }catch(e){};

                                                try{
                                                    app.documents.getByName(app.activeDocument.name.split(" High Res 16b")[0] + ".psb").close(SaveOptions.DONOTSAVECHANGES);
                                                }catch(e){};

                                            // Run rerender organisation same location script

                                                rerenderOrganisationSameLocation(false);

                                            // Scale all linked smart objects to 25%

                                                // Select linked smart objects

                                                    selectAllLayersInSpecifiedLayerSet(app.activeDocument.layers.getByName("Original Image Group"));

                                                // Do for selected layers

                                                    // Do for selected layers setup 1

                                                        function cID (inVal) { return charIDToTypeID(inVal);}
                                                        function sID (inVal) { return stringIDToTypeID(inVal);}

                                                        main();
                                                        function main()
                                                        {
                                                        optionsDialog();
                                                        }
                                                        function optionsDialog()
                                                        {

                                                        OpenOptionsDialog = new Window("dialog");

                                                        mainGroup = OpenOptionsDialog.add("group");

                                                        function runTheScript ()
                                                        {
                                                        var SelectedLayers = getSelectedLayers();

                                                        for (var i = 0; i < SelectedLayers.length; i++)
                                                        {
                                                        activeDocument.activeLayer = SelectedLayers[i];

                                                    // Thing to do

                                                          if (app.activeDocument.activeLayer.kind == LayerKind.SMARTOBJECT){
                                                              // Scale

                                                                  var idTrnf = charIDToTypeID( "Trnf" );
                                                                  var desc741 = new ActionDescriptor();
                                                                  var idnull = charIDToTypeID( "null" );
                                                                  var ref494 = new ActionReference();
                                                                  var idLyr = charIDToTypeID( "Lyr " );
                                                                  var idOrdn = charIDToTypeID( "Ordn" );
                                                                  var idTrgt = charIDToTypeID( "Trgt" );
                                                                  ref494.putEnumerated( idLyr, idOrdn, idTrgt );
                                                                  desc741.putReference( idnull, ref494 );
                                                                  var idFTcs = charIDToTypeID( "FTcs" );
                                                                  var idQCSt = charIDToTypeID( "QCSt" );
                                                                  var idQcsa = charIDToTypeID( "Qcsa" );
                                                                  desc741.putEnumerated( idFTcs, idQCSt, idQcsa );
                                                                  var idOfst = charIDToTypeID( "Ofst" );
                                                                  var desc742 = new ActionDescriptor();
                                                                  var idHrzn = charIDToTypeID( "Hrzn" );
                                                                  var idPxl = charIDToTypeID( "#Pxl" );
                                                                  desc742.putUnitDouble( idHrzn, idPxl, 0.000000 );
                                                                  var idVrtc = charIDToTypeID( "Vrtc" );
                                                                  var idPxl = charIDToTypeID( "#Pxl" );
                                                                  desc742.putUnitDouble( idVrtc, idPxl, 0.000000 );
                                                                  var idOfst = charIDToTypeID( "Ofst" );
                                                                  desc741.putObject( idOfst, idOfst, desc742 );
                                                                  var idWdth = charIDToTypeID( "Wdth" );
                                                                  var idPrc = charIDToTypeID( "#Prc" );
                                                                  desc741.putUnitDouble( idWdth, idPrc, 25.000000 );
                                                                  var idHght = charIDToTypeID( "Hght" );
                                                                  var idPrc = charIDToTypeID( "#Prc" );
                                                                  desc741.putUnitDouble( idHght, idPrc, 25.000000 );
                                                                  var idIntr = charIDToTypeID( "Intr" );
                                                                  var idIntp = charIDToTypeID( "Intp" );
                                                                  var idBlnr = charIDToTypeID( "Blnr" );
                                                                  desc741.putEnumerated( idIntr, idIntp, idBlnr );
                                                                  executeAction( idTrnf, desc741, DialogModes.NO );
                                                          };

                                                    // Do for selected layers setup 2

                                                        };
                                                        OpenOptionsDialog.close()
                                                        };

                                                        runTheScript();

                                                        var result = OpenOptionsDialog.hide();
                                                        };

                                                        function getSelectedLayers(){
                                                            var resultLayers=new Array();

                                                            try{
                                                                var descGrp = new ActionDescriptor();
                                                                var refGrp = new ActionReference();
                                                                refGrp.putEnumerated(cID( "Lyr " ),cID( "Ordn" ),cID( "Trgt" ));
                                                                descGrp.putReference(cID( "null" ), refGrp );
                                                                executeAction( sID( "groupLayersEvent" ), descGrp, DialogModes.NO );
                                                                for (var ix=0;ix<app.activeDocument.activeLayer.layers.length;ix++){resultLayers.push(app.activeDocument.activeLayer.layers[ix])}
                                                                var desc5 = new ActionDescriptor();
                                                                var ref2 = new ActionReference();
                                                                ref2.putEnumerated( cID( "HstS" ), cID( "Ordn" ), cID( "Prvs" ) );
                                                                desc5.putReference( cID( "null" ), ref2 );
                                                                executeAction( cID( "slct" ), desc5, DialogModes.NO );
                                                            }catch(e){};

                                                            return resultLayers;
                                                        };

                                            // Replace all linked smart objects

                                                // Select linked smart object

                                                    app.activeDocument.activeLayer = app.activeDocument.layers.getByName("Original Image Group").layers.getByName("Original Image");

                                                // Replace contents

                                                    var idplacedLayerReplaceContents = stringIDToTypeID( "placedLayerReplaceContents" );
                                                    var desc900 = new ActionDescriptor();
                                                    var idnull = charIDToTypeID( "null" );
                                                    desc900.putPath( idnull, new File( app.activeDocument.path + "/" + app.activeDocument.name.replace(/%20/g, " ").split(" 16b")[0] + ".psb" ) );
                                                    executeAction( idplacedLayerReplaceContents, desc900, DialogModes.NO );

                                            // Make contents of border group opaque

                                                makeContentsOfBorderGroupOpaque();

                                            // Select Multimatte layerSet

                                                try{
                                                    app.activeDocument.activeLayer = app.activeDocument.layers.getByName("Multimatte");
                                                }catch(e){};

                                            // Save

                                                app.activeDocument.save();
                                        }else{
                                            // Open original 32b file

                                                var fileRef = new File(app.activeDocument.path.fsName.replace(/%20/g, " ").split("High Res")[0] + "Low Res" + "/" + app.activeDocument.name.replace(/%20/g, " ").split(" High Res.psb")[0] + ".psb");
                                                app.open( fileRef );

                                            // Shift to 16b Mode

                                                shiftTo16bMode();

                                            // Save

                                                saveFileOnlyIfChangesWereMade(app.activeDocument);

                                            // Open High Res 32b file

                                                var fileRef = new File(app.activeDocument.path.fsName.replace(/%20/g, " ").split("Low Res")[0] + "High Res" + "/" + app.activeDocument.name.replace(/%20/g, " ").split(" 16b.psb")[0] + " High Res.psb");
                                                app.open( fileRef );

                                            // Close original 16b file

                                                try{
                                                    app.documents.getByName(app.activeDocument.name.replace(/%20/g, " ").split(" High Res.psb")[0] + " 16b.psb").close(SaveOptions.DONOTSAVECHANGES);
                                                }catch(e){};

                                            // Shift to 16b Mode

                                                shiftTo16bMode();

                                            // Save

                                                app.activeDocument.save();
                                        };
                                }else{
                                    // Save

                                        saveFileOnlyIfChangesWereMade(app.activeDocument);

                                    // If overwrite variable is true, replace the current file with a new 16b file taken from the low res 16b file

                                        if(overwriteExistingFilesYesNo == "true"){
                                            // Create activeFileRef variable

                                                var activeFileRef = app.activeDocument.path.fsName.replace(/%20/g, " ").split("High Res")[0] + "Low Res" + "/" + app.activeDocument.name.split(" High Res")[0] + " 16b.psb"

                                            // Close active document without saving

                                                app.activeDocument.close(SaveOptions.DONOTSAVECHANGES);

                                            // Open 16b version of file, or create one

                                                try{
                                                    var fileRef = new File(activeFileRef);
                                                    app.open( fileRef );
                                                }catch(e){};

                                                var docName = app.activeDocument.name
                                                var word16b = new RegExp (/16b/gim);

                                                if(word16b.test(docName)){
                                                    // Close 32b version(s) of file if still open

                                                        try{
                                                            app.documents.getByName(app.activeDocument.name.split(" 16b")[0] + ".psb").close(SaveOptions.DONOTSAVECHANGES);
                                                        }catch(e){};

                                                        try{
                                                            app.documents.getByName(app.activeDocument.name.split(" 16b")[0]).close(SaveOptions.DONOTSAVECHANGES);
                                                        }catch(e){};

                                                        try{
                                                            app.documents.getByName(app.activeDocument.name.split(" High Res 16b")[0] + ".psb").close(SaveOptions.DONOTSAVECHANGES);
                                                        }catch(e){};

                                                        try{
                                                            app.documents.getByName(app.activeDocument.name.split(" High Res 16b")[0] + ".psb").close(SaveOptions.DONOTSAVECHANGES);
                                                        }catch(e){};

                                                    // Ensure all modified content is updated

                                                        var idplacedLayerUpdateAllModified = stringIDToTypeID( "placedLayerUpdateAllModified" );
                                                        executeAction( idplacedLayerUpdateAllModified, undefined, DialogModes.NO );

                                                    // Make sure image is cropped to original image

                                                        try{
                                                            app.activeDocument.activeLayer = app.activeDocument.layers.getByName("Total Lighting Group").layers.getByName("Diffuse Group").layers.getByName("Diffuse");

                                                            createSelectionFromActiveLayersThubnail();

                                                            cropToSelection();

                                                            try{
                                                                app.activeDocument.layers.getByName("setCanvasSizeToDiffusePassSizeFromActiveDocumentsLocation Dummy Layer").remove();
                                                            }catch(e){};
                                                        }catch(e){};

                                                    // Change resolution to 400% of current resolution

                                                        var idImgS = charIDToTypeID( "ImgS" );
                                                        var desc568 = new ActionDescriptor();
                                                        var idWdth = charIDToTypeID( "Wdth" );
                                                        var idPrc = charIDToTypeID( "#Prc" );
                                                        desc568.putUnitDouble( idWdth, idPrc, 400.000000 );
                                                        var idscaleStyles = stringIDToTypeID( "scaleStyles" );
                                                        desc568.putBoolean( idscaleStyles, true );
                                                        var idCnsP = charIDToTypeID( "CnsP" );
                                                        desc568.putBoolean( idCnsP, true );
                                                        var idIntr = charIDToTypeID( "Intr" );
                                                        var idIntp = charIDToTypeID( "Intp" );
                                                        var idautomaticInterpolation = stringIDToTypeID( "automaticInterpolation" );
                                                        desc568.putEnumerated( idIntr, idIntp, idautomaticInterpolation );
                                                        executeAction( idImgS, desc568, DialogModes.NO );

                                                    // Save file in new location

                                                        var pathPreliminary2 = app.activeDocument.path.toString()
                                                        var pathPreliminary = pathPreliminary2.replace(/%20/g, " ")
                                                        var Path = pathPreliminary.split("Low Res")[0] + "High Res";
                                                        var Name = app.activeDocument.name.split(" 16b")[0];
                                                        var pathPlusName = File(Path + "/" + Name.split(".psb")[0] + " High Res 16b.psb");

                                                        SavePSB(pathPlusName);

                                                    // Zoom out

                                                        setZoom();

                                                    // Close 32b version(s) of file if still open

                                                        try{
                                                            app.documents.getByName(app.activeDocument.name.split(" 16b")[0] + ".psb").close(SaveOptions.DONOTSAVECHANGES);
                                                        }catch(e){};

                                                        try{
                                                            app.documents.getByName(app.activeDocument.name.split(" 16b")[0]).close(SaveOptions.DONOTSAVECHANGES);
                                                        }catch(e){};

                                                        try{
                                                            app.documents.getByName(app.activeDocument.name.split(" High Res 16b")[0] + ".psb").close(SaveOptions.DONOTSAVECHANGES);
                                                        }catch(e){};

                                                        try{
                                                            app.documents.getByName(app.activeDocument.name.split(" High Res 16b")[0] + ".psb").close(SaveOptions.DONOTSAVECHANGES);
                                                        }catch(e){};

                                                    // Run rerender organisation same location script

                                                        rerenderOrganisationSameLocation(false);

                                                    // Scale all linked smart objects to 25%

                                                        // Select linked smart objects

                                                            selectAllLayersInSpecifiedLayerSet(app.activeDocument.layers.getByName("Original Image Group"));

                                                        // Do for selected layers

                                                            // Do for selected layers setup 1

                                                                function cID (inVal) { return charIDToTypeID(inVal);}
                                                                function sID (inVal) { return stringIDToTypeID(inVal);}

                                                                main();
                                                                function main()
                                                                {
                                                                optionsDialog();
                                                                }
                                                                function optionsDialog()
                                                                {

                                                                OpenOptionsDialog = new Window("dialog");

                                                                mainGroup = OpenOptionsDialog.add("group");

                                                                function runTheScript ()
                                                                {
                                                                var SelectedLayers = getSelectedLayers();

                                                                for (var i = 0; i < SelectedLayers.length; i++)
                                                                {
                                                                activeDocument.activeLayer = SelectedLayers[i];

                                                            // Thing to do

                                                                  if (app.activeDocument.activeLayer.kind == LayerKind.SMARTOBJECT){
                                                                      // Scale

                                                                          var idTrnf = charIDToTypeID( "Trnf" );
                                                                          var desc741 = new ActionDescriptor();
                                                                          var idnull = charIDToTypeID( "null" );
                                                                          var ref494 = new ActionReference();
                                                                          var idLyr = charIDToTypeID( "Lyr " );
                                                                          var idOrdn = charIDToTypeID( "Ordn" );
                                                                          var idTrgt = charIDToTypeID( "Trgt" );
                                                                          ref494.putEnumerated( idLyr, idOrdn, idTrgt );
                                                                          desc741.putReference( idnull, ref494 );
                                                                          var idFTcs = charIDToTypeID( "FTcs" );
                                                                          var idQCSt = charIDToTypeID( "QCSt" );
                                                                          var idQcsa = charIDToTypeID( "Qcsa" );
                                                                          desc741.putEnumerated( idFTcs, idQCSt, idQcsa );
                                                                          var idOfst = charIDToTypeID( "Ofst" );
                                                                          var desc742 = new ActionDescriptor();
                                                                          var idHrzn = charIDToTypeID( "Hrzn" );
                                                                          var idPxl = charIDToTypeID( "#Pxl" );
                                                                          desc742.putUnitDouble( idHrzn, idPxl, 0.000000 );
                                                                          var idVrtc = charIDToTypeID( "Vrtc" );
                                                                          var idPxl = charIDToTypeID( "#Pxl" );
                                                                          desc742.putUnitDouble( idVrtc, idPxl, 0.000000 );
                                                                          var idOfst = charIDToTypeID( "Ofst" );
                                                                          desc741.putObject( idOfst, idOfst, desc742 );
                                                                          var idWdth = charIDToTypeID( "Wdth" );
                                                                          var idPrc = charIDToTypeID( "#Prc" );
                                                                          desc741.putUnitDouble( idWdth, idPrc, 25.000000 );
                                                                          var idHght = charIDToTypeID( "Hght" );
                                                                          var idPrc = charIDToTypeID( "#Prc" );
                                                                          desc741.putUnitDouble( idHght, idPrc, 25.000000 );
                                                                          var idIntr = charIDToTypeID( "Intr" );
                                                                          var idIntp = charIDToTypeID( "Intp" );
                                                                          var idBlnr = charIDToTypeID( "Blnr" );
                                                                          desc741.putEnumerated( idIntr, idIntp, idBlnr );
                                                                          executeAction( idTrnf, desc741, DialogModes.NO );
                                                                  };

                                                            // Do for selected layers setup 2

                                                                };
                                                                OpenOptionsDialog.close()
                                                                };

                                                                runTheScript();

                                                                var result = OpenOptionsDialog.hide();
                                                                };

                                                                function getSelectedLayers(){
                                                                    var resultLayers=new Array();

                                                                    try{
                                                                        var descGrp = new ActionDescriptor();
                                                                        var refGrp = new ActionReference();
                                                                        refGrp.putEnumerated(cID( "Lyr " ),cID( "Ordn" ),cID( "Trgt" ));
                                                                        descGrp.putReference(cID( "null" ), refGrp );
                                                                        executeAction( sID( "groupLayersEvent" ), descGrp, DialogModes.NO );
                                                                        for (var ix=0;ix<app.activeDocument.activeLayer.layers.length;ix++){resultLayers.push(app.activeDocument.activeLayer.layers[ix])}
                                                                        var desc5 = new ActionDescriptor();
                                                                        var ref2 = new ActionReference();
                                                                        ref2.putEnumerated( cID( "HstS" ), cID( "Ordn" ), cID( "Prvs" ) );
                                                                        desc5.putReference( cID( "null" ), ref2 );
                                                                        executeAction( cID( "slct" ), desc5, DialogModes.NO );
                                                                    }catch(e){};

                                                                    return resultLayers;
                                                                };

                                                    // Replace all linked smart objects

                                                        // Select linked smart object

                                                            app.activeDocument.activeLayer = app.activeDocument.layers.getByName("Original Image Group").layers.getByName("Original Image");

                                                        // Replace contents

                                                            var idplacedLayerReplaceContents = stringIDToTypeID( "placedLayerReplaceContents" );
                                                            var desc900 = new ActionDescriptor();
                                                            var idnull = charIDToTypeID( "null" );
                                                            desc900.putPath( idnull, new File( app.activeDocument.path + "/" + app.activeDocument.name.replace(/%20/g, " ").split(" 16b")[0] + ".psb" ) );
                                                            executeAction( idplacedLayerReplaceContents, desc900, DialogModes.NO );

                                                    // Make contents of border group opaque

                                                        makeContentsOfBorderGroupOpaque();

                                                    // Select Multimatte layerSet

                                                        try{
                                                            app.activeDocument.activeLayer = app.activeDocument.layers.getByName("Multimatte");
                                                        }catch(e){};

                                                    // Save

                                                        app.activeDocument.save();
                                                }else{
                                                    // Open original 32b file

                                                        var fileRef = new File(app.activeDocument.path.fsName.replace(/%20/g, " ").split("High Res")[0] + "Low Res" + "/" + app.activeDocument.name.replace(/%20/g, " ").split(" High Res.psb")[0] + ".psb");
                                                        app.open( fileRef );

                                                    // Shift to 16b Mode

                                                        shiftTo16bMode();

                                                    // Save

                                                        saveFileOnlyIfChangesWereMade(app.activeDocument);

                                                    // Open High Res 32b file

                                                        var fileRef = new File(app.activeDocument.path.fsName.replace(/%20/g, " ").split("Low Res") + "High Res" + "/" + app.activeDocument.name.replace(/%20/g, " ").split(" 16b.psb")[0] + " High Res.psb");
                                                        app.open( fileRef );

                                                    // Close original 16b file

                                                        try{
                                                            app.documents.getByName(app.activeDocument.name.replace(/%20/g, " ").split(" High Res.psb")[0] + " 16b.psb").close(SaveOptions.DONOTSAVECHANGES);
                                                        }catch(e){};

                                                    // Shift to 16b Mode

                                                        shiftTo16bMode();

                                                    // Save

                                                        app.activeDocument.save();
                                                };
                                        };
                                }

                            // Close other version(s) of file if still open

                                try{
                                    app.documents.getByName(app.activeDocument.name.split(" 16b")[0] + ".psb").close(SaveOptions.DONOTSAVECHANGES);
                                }catch(e){};

                                try{
                                    app.documents.getByName(app.activeDocument.name.split(" 16b")[0]).close(SaveOptions.DONOTSAVECHANGES);
                                }catch(e){};

                                try{
                                    app.documents.getByName(app.activeDocument.name.split(" High Res 16b")[0] + ".psb").close(SaveOptions.DONOTSAVECHANGES);
                                }catch(e){};

                                try{
                                    app.documents.getByName(app.activeDocument.name.split(" High Res 16b")[0]).close(SaveOptions.DONOTSAVECHANGES);
                                }catch(e){};

                                try{
                                    app.documents.getByName(app.activeDocument.name.split(" High Res")[0] + " 16b.psb").close(SaveOptions.DONOTSAVECHANGES);
                                }catch(e){};

                                try{
                                    app.documents.getByName(app.activeDocument.name.split(" High Res")[0] + " 16b").close(SaveOptions.DONOTSAVECHANGES);
                                }catch(e){};
                        }catch(e){};
                    }else{
                        // Save and close active document and any related documents

                            // Variables etc

                                var word16b = new RegExp(/16b/gim);
                                var docName = app.activeDocument.name;

                            // Save and close active document

                                saveFileOnlyIfChangesWereMade(app.activeDocument);

                                app.activeDocument.close(SaveOptions.DONOTSAVECHANGES);

                            // Save and close and related documents

                                if(word16b.test(docName)){
                                    try{
                                        saveFileOnlyIfChangesWereMade(app.documents.getByName(docName.replace(/ 16b/g, "")));

                                        app.activeDocument.close(SaveOptions.DONOTSAVECHANGES);
                                    }catch(e){};
                                }else{
                                    try{
                                        saveFileOnlyIfChangesWereMade(app.documents.getByName(docName.replace(/ 16b.psb/gim, ".psb")));

                                        app.activeDocument.close(SaveOptions.DONOTSAVECHANGES);
                                    }catch(e){};
                                };
                    };
            };

    // Initial organisation

        // For specified

            function initialOrganisationForSpecified(){
                // Prompt for root folder path

                    if(runBy3dsMax != true){
                        var rootFolderPath = prompt("Specify folder path...", "");

                        // Get current folder if relevant

                            if(rootFolderPath == "C" || rootFolderPath == "c"){
                                try{
                                    var rootFolderPath = app.activeDocument.path.fsName.replace(/%20/g, " ");

                                    var rootFolderPathTextToSplitPrelim = rootFolderPath.split("\\");
                                    var rootFolderPathTextToSplit = ("\\" + rootFolderPathTextToSplitPrelim[rootFolderPathTextToSplitPrelim.length - 2] + "\\" + rootFolderPathTextToSplitPrelim[rootFolderPathTextToSplitPrelim.length - 1]);

                                    var rootFolderPath = rootFolderPath.split(rootFolderPathTextToSplit)[0];
                                }catch(e){};
                            };
                    }else{
                        var rootFolderPath = app.activeDocument.layers.getByName("rootFolderPath").layers[0].name
                    };

                    if(rootFolderPath == undefined || rootFolderPath == ""){
                        return;
                    };

                // Prompt for frame number(s)

                    if(runBy3dsMax != true){
                        var promptForFrameNumber = prompt("Specify frame number (if multiple, separate each with a comma and space), or type \'All\'", "");
                    }else{
                        var promptForFrameNumber = app.activeDocument.layers.getByName("promptForFrameNumber").layers[0].name
                    };

                    if(promptForFrameNumber == undefined){
                        return;
                    };

                // Prompt for High Res

                    if(runBy3dsMax != true){
                        var promptForHighRes = prompt("Do for high res files? Type Y for yes or leave blank for no", "");
                    }else{
                        var promptForHighRes = app.activeDocument.layers.getByName("promptForHighRes").layers[0].name
                    };

                    if(promptForHighRes == "Y" || promptForHighRes == "y" || promptForHighRes == "yes" || promptForHighRes == "Yes" || promptForHighRes == "YES"){
                        var runScriptOnHighResFiles = "true"
                        var wordHighResIfApplicableWithSpace = " High Res"
                        var wordHighResIfApplicable = "High Res"
                    }else{
                        var runScriptOnHighResFiles = "false"
                        var wordHighResIfApplicableWithSpace = ""
                        var wordHighResIfApplicable = ""
                    };

                // Prompt for 16b

                    if(runBy3dsMax != true){
                        var promptFor16b = prompt("Do for both 32b and 16b files? Type Y for yes or leave blank for 32b only", "");
                    }else{
                        var promptFor16b = app.activeDocument.layers.getByName("promptFor16b").layers[0].name
                    };

                    if(promptFor16b == "Y" || promptFor16b == "y" || promptFor16b == "yes" || promptFor16b == "Yes" || promptFor16b == "YES"){
                        var runScriptOn16bFiles = "true"
                    }else{
                        var runScriptOn16bFiles = "false"
                    };

                // Set up for "All" if applicable

                    if(promptForFrameNumber == "All" || promptForFrameNumber == "all" || promptForFrameNumber == "ALL" || promptForFrameNumber == "A"|| promptForFrameNumber == "a"){
                        // Get number of frame folders

                            // Variables etc

                                var rootPath = rootFolderPath
                                var targetLayers = new Array;
                                var subDirectory = "/LinkedLayers/";
                                var configFolder = Folder(rootPath);
                                var fileList = configFolder.getFiles();

                                var frameCount = 0

                            // Count frames

                                // Create frameNumbersArray variable

                                    var frameNumbersArray = [];

                                for (var a = 0; a < fileList.length; a++){
                                    var frameNumberToPush = fileList[a].toString().split("/")[fileList[a].toString().split("/").length - 1].replace(/%20/g, " ").split(" ")[0]

                                    frameNumbersArray.push(frameNumberToPush)

                                    frameCount++
                                };

                            // Create listOfFrameNumbers variable

                                var listOfFrameNumbers = frameNumbersArray
                    }else{
                        // Create listOfFrameNumbers variable

                            var listOfFrameNumbers = promptForFrameNumber.split(", ")
                    };

                // Hide palettes

                    if(initialPrompt != undefined){
                        app.togglePalettes();
                    };

                    if(app.documents.length == 0){
                        var dontShowPalettes = "True"
                    }else{
                        var dontShowPalettes = "False"
                    };

                // Loop through frames and run the script

                    for(var a = 0; a < listOfFrameNumbers.length; a++){
                        // Create frameNumber variable

                            var frameNumber = listOfFrameNumbers[a]

                        // Create folder path variable

                            // Loop through all folders in the root folder and find the folder for the current frame number, to create folderPath and frameName variables

                                // Variables etc

                                    var rootPath = rootFolderPath
                                    var targetLayers = new Array;
                                    var subDirectory = "/LinkedLayers/";
                                    var configFolder = Folder(rootPath);
                                    var fileList = configFolder.getFiles();

                                // Loop

                                    for (var b = fileList.length -1; b >= 0  ; b--){
                                        // Variables etc

                                            var tempPreliminary = fileList[b].toString().replace(/\\/g, "/")
                                            var temp = tempPreliminary.split("/")[tempPreliminary.split("/").length - 1];
                                            var tempNoSpaces = temp.replace(/%20/g, " ")
                                            var frameNumberPlusSpace = frameNumber + " "

                                        if (tempNoSpaces.startsWith(frameNumberPlusSpace)){
                                            // Create folder path variable

                                                if(runScriptOnHighResFiles == "true"){
                                                    var folderPath = rootFolderPath + "/" + temp + "/" + "High Res"

                                                    var frameName = temp.replace(/%20/g, " ") + " High Res";
                                                }else{
                                                    var folderPath = rootFolderPath + "/" + temp + "/" + "Low Res"

                                                    var frameName = temp.replace(/%20/g, " ");
                                                };
                                        };
                                    };

                            // If no folder matched the name, move on in the loop

                                if(folderPath == undefined || folderPath == ""){
                                    return;
                                };

                        // Test whether diffuse pass exists

                            // Variables etc

                                var rootPath = folderPath
                                var targetLayers = new Array;
                                var subDirectory = "/LinkedLayers/";
                                var configFolder = Folder(rootPath);
                                var fileList = configFolder.getFiles();

                            // Create passesExist variable

                                for (var b = fileList.length -1; b >= 0  ; b--){
                                    var tempPreliminary1 = fileList[b].toString();
                                    var tempPreliminary = tempPreliminary1.replace(/\\/g, "/")
                                    var temp = tempPreliminary.split("/")[tempPreliminary.split("/").length - 1]
                                    var reguEx = new RegExp(/.exr/gim);
                                    var reguEx3 = new RegExp(/ultimatte/gim);
                                    var reguEx4 = new RegExp(/wire/i);
                                    var reguEx5 = new RegExp(/psb/i);
                                    var reguEx6 = new RegExp(/orld/i);
                                    var reguEx7 = new RegExp(/alpha/i);
                                    var reguEx8 = new RegExp(/raw(.*)shad/i);
                                    var reguEx9 = new RegExp(/diffuse/i);

                                    if (reguEx.test(temp) &&  !reguEx3.test(temp) && !reguEx4.test(temp) && reguEx9.test(temp)){
                                        // Create passesExist variable

                                            var passesExist = "true"
                                    };
                                };

                        // Run the script, or move on to next loop if diffuse pass didn't exist

                            if(passesExist == "true"){
                                // Try to open relevant file, otherwise create new file and run script

                                    try{
                                        var fileRef = new File(folderPath + "/" + frameName + ".psb");

                                        app.open(fileRef);

                                        setZoom();
                                    }catch(e){
                                        // Create new file

                                            app.documents.add()

                                        // Save file as frameName

                                            SavePSB(folderPath + "/" + frameName)

                                        // Initial Organisation

                                            initialOrganisation();
                                    };

                                // If doing for 16b files, run shift to 16b mode script

                                    if(runScriptOn16bFiles == "true"){
                                        shiftTo16bMode()

                                        // Save

                                            app.activeDocument.save();
                                    };
                            };

                        // Reset passesExist variable

                            var passesExist = "false"
                    };
            };

        // Main function

            function initialOrganisation(){
                // Check if document filetype is .psb

                    var stringPsb = new RegExp(/psb/gim);

                    if(!stringPsb.test(app.activeDocument.name)){
                        alert("Please save the document with the extension '.psb' and try again");
                    }else{
                        // Zoom out

                            setZoom();

                        // Change to 32bit

                            try{
                                var idCnvM = charIDToTypeID( "CnvM" );
                                var desc248 = new ActionDescriptor();
                                var idDpth = charIDToTypeID( "Dpth" );
                                desc248.putInteger( idDpth, 32 );
                                var idMrge = charIDToTypeID( "Mrge" );
                                desc248.putBoolean( idMrge, false );
                                var idRstr = charIDToTypeID( "Rstr" );
                                desc248.putBoolean( idRstr, false );
                                executeAction( idCnvM, desc248, DialogModes.NO );
                            }catch(e){};

                        // Ensure colour mode is RGB

                            var idCnvM = charIDToTypeID( "CnvM" );
                            var desc2052 = new ActionDescriptor();
                            var idT = charIDToTypeID( "T   " );
                            var idRGBM = charIDToTypeID( "RGBM" );
                            desc2052.putClass( idT, idRGBM );
                            executeAction( idCnvM, desc2052, DialogModes.NO );

                        // Change background layer name to deleteme

                            try{
                                var idsetd = charIDToTypeID( "setd" );
                                var desc106 = new ActionDescriptor();
                                var idnull = charIDToTypeID( "null" );
                                var ref83 = new ActionReference();
                                var idLyr = charIDToTypeID( "Lyr " );
                                var idBckg = charIDToTypeID( "Bckg" );
                                ref83.putProperty( idLyr, idBckg );
                                desc106.putReference( idnull, ref83 );
                                var idT = charIDToTypeID( "T   " );
                                var desc107 = new ActionDescriptor();
                                var idOpct = charIDToTypeID( "Opct" );
                                var idPrc = charIDToTypeID( "#Prc" );
                                desc107.putUnitDouble( idOpct, idPrc, 100.000000 );
                                var idMd = charIDToTypeID( "Md  " );
                                var idBlnM = charIDToTypeID( "BlnM" );
                                var idNrml = charIDToTypeID( "Nrml" );
                                desc107.putEnumerated( idMd, idBlnM, idNrml );
                                var idLyr = charIDToTypeID( "Lyr " );
                                desc106.putObject( idT, idLyr, desc107 );
                                executeAction( idsetd, desc106, DialogModes.NO );

                                app.activeDocument.activeLayer.name = "deleteme";
                            }catch(e){};

                        // Change image size to size of diffuse

                            try{
                                app.activeDocument.activeLayer = app.activeDocument.layers.getByName("Total Lighting Group").layers.getByName("Diffuse Group").layers.getByName("Diffuse");

                                createSelectionFromActiveLayersThubnail();

                                cropToSelection();

                                try{
                                    app.activeDocument.layers.getByName("setCanvasSizeToDiffusePassSizeFromActiveDocumentsLocation Dummy Layer").remove();
                                }catch(e){};
                            }catch(e){
                                app.activeDocument.close(SaveOptions.DONOTSAVECHANGES);

                                return;
                            };

                        // Place linked smart object of every non Multimatte pass from folder

                            // Variables etc

                                var rootPath = decodeURI (app.activeDocument.path.fsName);
                                var targetLayers = new Array;
                                var subDirectory = "/LinkedLayers/";
                                targetLayers = app.activeDocument.layers;
                                var configFolder = Folder(rootPath);
                                var fileList = configFolder.getFiles();

                            // Place all non Multimattes

                                for (var i = fileList.length -1; i >= 0  ; i--){
                                    var tempPreliminary1 = fileList[i].toString();
                                    var tempPreliminary = tempPreliminary1.replace(/\\/g, "/")
                                    var temp = tempPreliminary.split("/")[tempPreliminary.split("/").length - 1]
                                    var reguEx = new RegExp(/.exr/gim);
                                    var reguEx2 = new RegExp(/MultiMatte_/gim);
                                    var reguEx3 = new RegExp(/ultimatte/gim);
                                    var reguEx4 = new RegExp(/wire/i);
                                    var reguEx5 = new RegExp(/normals/i);
                                    var reguEx7 = new RegExp(/alpha/i);
                                    var reguEx8 = new RegExp(/raw(.*)shad/i);
                                    var reguEx9 = new RegExp(/fresnel/i);
                                    var reguEx10 = new RegExp(/z(.*)dep/i);
                                    var reguEx11 = new RegExp(/edges/i);

                                    if (reguEx.test(temp) &&  !reguEx2.test(temp) &&  !reguEx3.test(temp) && !reguEx4.test(temp)){
                                        if (reguEx5.test(temp) || reguEx7.test(temp) || reguEx8.test(temp) || reguEx9.test(temp) || reguEx10.test(temp) || reguEx11.test(temp)){
                                        }else{
                                            // Place linked smart object

                                                var idPlc = charIDToTypeID( "Plc " );
                                                var desc13 = new ActionDescriptor();
                                                var idIdnt = charIDToTypeID( "Idnt" );
                                                desc13.putInteger( idIdnt, 130 );
                                                var idnull = charIDToTypeID( "null" );
                                                desc13.putPath( idnull, new File( fileList[i] ) );
                                                var idLnkd = charIDToTypeID( "Lnkd" );
                                                desc13.putBoolean( idLnkd, true );
                                                var idOpAs = charIDToTypeID( "OpAs" );
                                                var desc14 = new ActionDescriptor();
                                                var idAChn = charIDToTypeID( "AChn" );
                                                desc14.putInteger( idAChn, 0 );
                                                var idEXRf = charIDToTypeID( "EXRf" );
                                                desc13.putObject( idOpAs, idEXRf, desc14 );
                                                var idFTcs = charIDToTypeID( "FTcs" );
                                                var idQCSt = charIDToTypeID( "QCSt" );
                                                var idQcsa = charIDToTypeID( "Qcsa" );
                                                desc13.putEnumerated( idFTcs, idQCSt, idQcsa );
                                                var idOfst = charIDToTypeID( "Ofst" );
                                                var desc15 = new ActionDescriptor();
                                                var idHrzn = charIDToTypeID( "Hrzn" );
                                                var idPxl = charIDToTypeID( "#Pxl" );
                                                desc15.putUnitDouble( idHrzn, idPxl, 0.000000 );
                                                var idVrtc = charIDToTypeID( "Vrtc" );
                                                var idPxl = charIDToTypeID( "#Pxl" );
                                                desc15.putUnitDouble( idVrtc, idPxl, 0.000000 );
                                                var idOfst = charIDToTypeID( "Ofst" );
                                                desc13.putObject( idOfst, idOfst, desc15 );
                                                executeAction( idPlc, desc13, DialogModes.NO );

                                            // Split . or _ off name

                                                app.activeDocument.activeLayer.name = app.activeDocument.activeLayer.name.substring(1);
                                        };
                                    };
                                };

                        // Rename all non Multimatte passes

                            // Do for all layers in specified group

                                // Setup 1

                                    var activeLayerByName = app.activeDocument;
                                    var myLength = activeLayerByName.layers.length;
                                    for (var i = 0; i < myLength; i++){
                                    app.activeDocument.activeLayer = activeLayerByName.layers[i]

                                // Thing to do

                                    if (app.activeDocument.activeLayer.kind == LayerKind.SMARTOBJECT){
                                        var searchItems = [
                                            [/solated(.*)lass(.*)/i,'Glass', /disregardthisname/i],
                                            [/alph/i,'Alpha', /disregardthisname/i],
                                            [/ao|amb(.*)oc|ext(.*)tex/i,"AO", /disregardthisname/i],
                                            [/atmosp/i,"Atmosphere", /disregardthisname/i],
                                            [/background/i,"Background", /disregardthisname/i],
                                            [/beaut|rgb/i,"Beauty Pass", /disregardthisname/i],
                                            [/bump(.*)norm/i, "Bump Normals", /disregardthisname/i],
                                            [/diff/i,'Diffuse', /disregardthisname/i],
                                            [/norm/i, "Normals", /world|bump/i],
                                            [/raw(.*)gi|raw(.*)glo/i, "Raw GI", /disregardthisname/i],
                                            [/raw(.*)ligh/i, "Raw Lighting", /disregardthisname/i],
                                            [/raw(.*)refl/i,"Raw Reflection", /disregardthisname/i],
                                            [/raw(.*)refr/i,"Raw Refraction", /disregardthisname/i],
                                            [/raw(.*)shad/i,"Raw Shadow", /disregardthisname/i],
                                            [/refl(.*)filt/i,"Reflection Filter", /disregardthisname/i],
                                            [/refr(.*)filt/i,"Refraction Filter", /disregardthisname/i],
                                            [/sun/i,"Sun", /disregardthisname/i],
                                            [/self(.*)illu/i,"Self Illumination", /disregardthisname/i],
                                            [/spec/i, "Specular", /disregardthisname/i],
                                            [/spec/i, "Specular", /disregardthisname/i],
                                            [/wire/i, "Wire Color", /disregardthisname/i],
                                            [/world(.*)norm(.*)\+(.*)x/i, "World Normals + x", /disregardthisname/i],
                                            [/world(.*)norm(.*)\+(.*)y/i, "World Normals + y", /disregardthisname/i],
                                            [/world(.*)norm(.*)\+(.*)z/i, "World Normals + z", /disregardthisname/i],
                                            [/world(.*)norm(.*)\-(.*)x/i, "World Normals - x", /disregardthisname/i],
                                            [/world(.*)norm(.*)\-(.*)y/i, "World Normals - y", /disregardthisname/i],
                                            [/world(.*)norm(.*)\-(.*)z/i, "World Normals - z", /disregardthisname/i],
                                            [/z(.*)dep/i,"Z-Depth", /disregardthisname/i]
                                        ];

                                        var len = searchItems.length

                                        for (var l = 0; l < len; l++){
                                            var re = new RegExp(searchItems[l][0]);
                                            var antire = new RegExp(searchItems[l][2]);

                                            if (re.test(app.activeDocument.activeLayer.name) && !antire.test(app.activeDocument.activeLayer.name)){
                                                app.activeDocument.activeLayer.name = searchItems[l][1];
                                            };
                                        };
                                    };

                                // Setup 2

                                  };

                        // Group all passes

                            groupAllPasses();

                        // ***Hide irrelevant layers

                            try{
                                app.activeDocument.layers.getByName("Overlay Group").visible = false

                                app.activeDocument.layers.getByName("Background Group").visible = false

                                app.activeDocument.layers.getByName("Diffuse Group").visible = false

                                app.activeDocument.layers.getByName("Raw GI Group").visible = false

                                app.activeDocument.layers.getByName("Raw Lighting Group").visible = false

                                app.activeDocument.layers.getByName("Raw Reflection Group").visible = false

                                app.activeDocument.layers.getByName("Raw Refraction Group").visible = false

                                app.activeDocument.layers.getByName("Reflection Filter Group").visible = false

                                app.activeDocument.layers.getByName("Refraction Filter Group").visible = false

                                app.activeDocument.layers.getByName("Specular Group").visible = false

                                app.activeDocument.layers.getByName("Sun Group").visible = false
                            }catch(e){};

                        // Add selection passes

                            // Expand canvas size to prevent 50% pixel selection problem

                                setCanvasSizeToDiffusePassSizeFromActiveDocumentsLocation(2);

                            // Add Multimatte passes

                                completeAddMultimattePasses();

                            // Add World Normals

                                try{
                                    app.activeDocument.layers.getByName("World Normals Group").remove();
                                }catch(e){};
                                try{
                                    app.activeDocument.layers.getByName("WorldNormalsGroup").remove();
                                }catch(e){};

                                completeAddWorldNormalsPasses();

                            // Place and deal with alpha

                                completeAddAlphaPass();

                            // Reset canvas size

                                setCanvasSizeToDiffusePassSizeFromActiveDocumentsLocation(0);

                        // ***Show irrelevant layers

                            try{
                                app.activeDocument.layers.getByName("Overlay Group").visible = true

                                app.activeDocument.layers.getByName("Background Group").visible = true

                                app.activeDocument.layers.getByName("Diffuse Group").visible = true

                                app.activeDocument.layers.getByName("Raw GI Group").visible = true

                                app.activeDocument.layers.getByName("Raw Lighting Group").visible = true

                                app.activeDocument.layers.getByName("Raw Reflection Group").visible = true

                                app.activeDocument.layers.getByName("Raw Refraction Group").visible = true

                                app.activeDocument.layers.getByName("Reflection Filter Group").visible = true

                                app.activeDocument.layers.getByName("Refraction Filter Group").visible = true

                                app.activeDocument.layers.getByName("Specular Group").visible = true

                                app.activeDocument.layers.getByName("Sun Group").visible = true
                            }catch(e){};

                        // Organise all groups

                            // Background

                                app.activeDocument.activeLayer = app.activeDocument.layers.getByName("Background Group");

                                // Move active layer to top

                                    moveActiveLayerToTop();

                            // Specular

                                app.activeDocument.activeLayer = app.activeDocument.layers.getByName("Specular Group");

                                setActiveLayerBlendingModeToLinearDodge();

                                // Move active layer to top

                                    moveActiveLayerToTop();

                            // Refraction

                                var newLayerSet = app.activeDocument.layerSets.add()
                                newLayerSet.name = "Refraction Group";

                                // Linear dodge

                                    setActiveLayerBlendingModeToLinearDodge();

                                // Move active layer to top

                                    moveActiveLayerToTop();

                                newLayer = app.activeDocument.artLayers.add().name = "Refraction Group Dummy"

                                // Move to refraction group

                                    app.activeDocument.activeLayer.move(app.activeDocument.layerSets.getByName("Refraction Group"), ElementPlacement.INSIDE)

                                app.activeDocument.activeLayer = app.activeDocument.layers.getByName("Refraction Filter Group");

                                // Multiply

                                    setActiveLayerBlendingModeToMultiply();

                                // Move to group via dummy

                                    app.activeDocument.activeLayer.move(app.activeDocument.layerSets.getByName("Refraction Group").layers.getByName("Refraction Group Dummy"), ElementPlacement.PLACEBEFORE);

                                app.activeDocument.activeLayer = app.activeDocument.layers.getByName("Raw Refraction Group");

                                // Move to group via dummy

                                    app.activeDocument.activeLayer.move(app.activeDocument.layerSets.getByName("Refraction Group").layers.getByName("Refraction Group Dummy"), ElementPlacement.PLACEBEFORE)

                                // Remove dummy

                                    app.activeDocument.layerSets.getByName("Refraction Group").layers.getByName("Refraction Group Dummy").remove();

                            // Reflection

                                var newLayerSet = app.activeDocument.layerSets.add()
                                newLayerSet.name = "Reflection Group";

                                // Linear dodge

                                    setActiveLayerBlendingModeToLinearDodge();

                                // Move active layer to top

                                    moveActiveLayerToTop();

                                app.activeDocument.artLayers.add().name = "Reflection Group Dummy";

                                // Move to reflection group

                                    app.activeDocument.activeLayer.move(app.activeDocument.layerSets.getByName("Reflection Group"), ElementPlacement.INSIDE)

                                // Deal with glass group if it exists

                                    try{
                                        app.activeDocument.activeLayer = app.activeDocument.layers.getByName("Glass Group");

                                        // Linear dodge

                                            setActiveLayerBlendingModeToLinearDodge();

                                        // Move to group via dummy

                                            app.activeDocument.activeLayer.move(app.activeDocument.layerSets.getByName("Reflection Group").layers.getByName("Reflection Group Dummy"), ElementPlacement.PLACEBEFORE);
                                    }catch(e){};

                                app.activeDocument.activeLayer = app.activeDocument.layers.getByName("Reflection Filter Group");

                                // Multiply

                                    setActiveLayerBlendingModeToMultiply();

                                // Move to group via dummy

                                    app.activeDocument.activeLayer.move(app.activeDocument.layerSets.getByName("Reflection Group").layers.getByName("Reflection Group Dummy"), ElementPlacement.PLACEBEFORE);

                                app.activeDocument.activeLayer = app.activeDocument.layers.getByName("Raw Reflection Group");

                                // Move to group via dummy

                                    app.activeDocument.activeLayer.move(app.activeDocument.layerSets.getByName("Reflection Group").layers.getByName("Reflection Group Dummy"), ElementPlacement.PLACEBEFORE);

                                // Remove dummy

                                    app.activeDocument.layerSets.getByName("Reflection Group").layers.getByName("Reflection Group Dummy").remove();

                            // Total Lighting

                                // Total Lighting

                                    app.activeDocument.layerSets.add().name = "Total Lighting Group";

                                    // Linear dodge

                                        setActiveLayerBlendingModeToLinearDodge();

                                    // Move active layer to top

                                        moveActiveLayerToTop();

                                    app.activeDocument.artLayers.add().name = "Total Lighting Group Dummy"

                                    // Move to total lighting group

                                        app.activeDocument.activeLayer.move(app.activeDocument.layerSets.getByName("Total Lighting Group"), ElementPlacement.INSIDE);

                                // Diffuse

                                    app.activeDocument.activeLayer = app.activeDocument.layers.getByName("Diffuse Group");

                                    // Multiply

                                        setActiveLayerBlendingModeToMultiply();

                                    // Move to group via dummy

                                        app.activeDocument.activeLayer.move(app.activeDocument.layerSets.getByName("Total Lighting Group").layers.getByName("Total Lighting Group Dummy"), ElementPlacement.PLACEBEFORE);

                                // Sun

                                    try{
                                        app.activeDocument.activeLayer = app.activeDocument.layers.getByName("Sun Group");

                                        // Linear dodge

                                            setActiveLayerBlendingModeToLinearDodge();

                                        // Move to group via dummy

                                            app.activeDocument.activeLayer.move(app.activeDocument.layerSets.getByName("Total Lighting Group").layers.getByName("Total Lighting Group Dummy"), ElementPlacement.PLACEBEFORE);
                                    }catch(e){};

                                // Raw Lighting

                                    app.activeDocument.activeLayer = app.activeDocument.layers.getByName("Raw Lighting Group");

                                    // Linear dodge

                                        setActiveLayerBlendingModeToLinearDodge();

                                    // Move to group via dummy

                                        app.activeDocument.activeLayer.move(app.activeDocument.layerSets.getByName("Total Lighting Group").layers.getByName("Total Lighting Group Dummy"), ElementPlacement.PLACEBEFORE);

                                // Raw GI

                                    app.activeDocument.activeLayer = app.activeDocument.layers.getByName("Raw GI Group");

                                    // Linear dodge

                                        setActiveLayerBlendingModeToLinearDodge();

                                    // Move to group via dummy

                                        app.activeDocument.activeLayer.move(app.activeDocument.layerSets.getByName("Total Lighting Group").layers.getByName("Total Lighting Group Dummy"), ElementPlacement.PLACEBEFORE);

                                // Remove dummy

                                    app.activeDocument.layerSets.getByName("Total Lighting Group").layers.getByName("Total Lighting Group Dummy").remove();

                            // Overlay

                                app.activeDocument.activeLayer = app.activeDocument.layers.getByName("Overlay Group");

                                // Move active layer to top

                                    moveActiveLayerToTop();

                            // Alpha

                                try{
                                    app.activeDocument.activeLayer = app.activeDocument.layers.getByName("Alpha Group");

                                    // Move active layer to top

                                        moveActiveLayerToTop();
                                }catch(e){};

                            // World Normals

                                app.activeDocument.activeLayer = app.activeDocument.layers.getByName("World Normals Group");

                                // Move active layer to top

                                    moveActiveLayerToTop();

                            // Multimatte

                                app.activeDocument.activeLayer = app.activeDocument.layers.getByName("Multimatte");

                                // Move active layer to top

                                    moveActiveLayerToTop();

                        // Delete deleteme layer

                                try{
                                    app.activeDocument.layers.getByName("deleteme").remove();
                                }catch (e){};

                        // Delete selection group

                            app.activeDocument.layerSets.getByName("Selection Group").remove();

                        // Create Overall Adjustments layerSet

                            app.activeDocument.layerSets.add().name = "Overall Adjustments Group";

                            try{
                                app.activeDocument.layers.getByName("Overall Adjustments Group").move(app.activeDocument.layers.getByName("Alpha Group"), ElementPlacement.PLACEAFTER);
                            }catch(e){
                                try{
                                    app.activeDocument.layers.getByName("Overall Adjustments Group").move(app.activeDocument.layers.getByName("World Normals Group"), ElementPlacement.PLACEAFTER);
                                }catch(e){};
                            };

                        // Create Border Group layerSet

                            app.activeDocument.layerSets.add().name = "Border Group";

                            try{
                                app.activeDocument.layers.getByName("Border Group").move(app.activeDocument.layers.getByName("Alpha Group"), ElementPlacement.PLACEAFTER);
                            }catch(e){
                                app.activeDocument.layers.getByName("Border Group").move(app.activeDocument.layers.getByName("World Normals Group"), ElementPlacement.PLACEAFTER);
                            };

                        // Organise overlay passes visibility and/or grouping

                            try{
                                // Beauty Pass

                                    var idHd = charIDToTypeID( "Hd  " );
                                    var desc275 = new ActionDescriptor();
                                    var idnull = charIDToTypeID( "null" );
                                    var list52 = new ActionList();
                                    var ref225 = new ActionReference();
                                    var idLyr = charIDToTypeID( "Lyr " );
                                    ref225.putName( idLyr, "Beauty Pass" );
                                    list52.putReference( ref225 );
                                    desc275.putList( idnull, list52 );
                                    executeAction( idHd, desc275, DialogModes.NO );

                                // Atmosphere

                                    var idHd = charIDToTypeID( "Hd  " );
                                    var desc276 = new ActionDescriptor();
                                    var idnull = charIDToTypeID( "null" );
                                    var list53 = new ActionList();
                                    var ref226 = new ActionReference();
                                    var idLyr = charIDToTypeID( "Lyr " );
                                    ref226.putName( idLyr, "Atmosphere" );
                                    list53.putReference( ref226 );
                                    desc276.putList( idnull, list53 );
                                    executeAction( idHd, desc276, DialogModes.NO );

                                // Make AO group for AO
                                    try{
                                        app.activeDocument.activeLayer = app.activeDocument.layers.getByName("Overlay Group").layers.getByName("AO");

                                        groupActiveLayers();

                                        app.activeDocument.activeLayer.name = "AO Group";

                                        setActiveLayerBlendingModeToMultiply();

                                        var idsetd = charIDToTypeID( "setd" );
                                        var desc280 = new ActionDescriptor();
                                        var idnull = charIDToTypeID( "null" );
                                        var ref229 = new ActionReference();
                                        var idLyr = charIDToTypeID( "Lyr " );
                                        var idOrdn = charIDToTypeID( "Ordn" );
                                        var idTrgt = charIDToTypeID( "Trgt" );
                                        ref229.putEnumerated( idLyr, idOrdn, idTrgt );
                                        desc280.putReference( idnull, ref229 );
                                        var idT = charIDToTypeID( "T   " );
                                        var desc281 = new ActionDescriptor();
                                        var idOpct = charIDToTypeID( "Opct" );
                                        var idPrc = charIDToTypeID( "#Prc" );
                                        desc281.putUnitDouble( idOpct, idPrc, 30.000000 );
                                        var idLyr = charIDToTypeID( "Lyr " );
                                        desc280.putObject( idT, idLyr, desc281 );
                                        executeAction( idsetd, desc280, DialogModes.NO );
                                    }catch(e){};

                                // Self Illumination

                                    var idslct = charIDToTypeID( "slct" );
                                    var desc282 = new ActionDescriptor();
                                    var idnull = charIDToTypeID( "null" );
                                    var ref230 = new ActionReference();
                                    var idLyr = charIDToTypeID( "Lyr " );
                                    ref230.putName( idLyr, "Self Illumination" );
                                    desc282.putReference( idnull, ref230 );
                                    var idMkVs = charIDToTypeID( "MkVs" );
                                    desc282.putBoolean( idMkVs, false );
                                    executeAction( idslct, desc282, DialogModes.NO );

                                    setActiveLayerBlendingModeToLinearDodge();

                                // Z-Depth

                                    var idHd = charIDToTypeID( "Hd  " );
                                    var desc285 = new ActionDescriptor();
                                    var idnull = charIDToTypeID( "null" );
                                    var list54 = new ActionList();
                                    var ref232 = new ActionReference();
                                    var idLyr = charIDToTypeID( "Lyr " );
                                    ref232.putName( idLyr, "Z-Depth" );
                                    list54.putReference( ref232 );
                                    desc285.putList( idnull, list54 );
                                    executeAction( idHd, desc285, DialogModes.NO );
                            }catch(e){};

                        // Create multimatte adjustment groups where needed

                            // AO

                                try{
                                    app.activeDocument.activeLayer = app.activeDocument.layers.getByName("Alpha Group").layers.getByName("Alpha");

                                    selectActiveLayersTransparency();

                                    app.activeDocument.activeLayer = app.activeDocument.layers.getByName("Overlay Group").layers.getByName("AO Group").layers.getByName("AO");

                                    groupActiveLayers();

                                    app.activeDocument.activeLayer.name = "Alpha adjustments";

                                    createMaskFromSelectionOnActiveLayer();
                                }catch(e){};

                            // Glass

                                try{
                                    app.activeDocument.activeLayer = app.activeDocument.layers.getByName("Multimatte").layers.getByName("Isolated Glass");

                                    selectActiveLayersTransparency();

                                    app.activeDocument.activeLayer = app.activeDocument.layers.getByName("Reflection Group").layers.getByName("Glass Group").layers.getByName("Glass");

                                    groupActiveLayers();

                                    app.activeDocument.activeLayer.name = "Isolated Glass adjustments";

                                    createMaskFromSelectionOnActiveLayer();
                                }catch(e){};

                        // Create entourage layer structure

                            // Create sublayers

                                // Entourage Shadow

                                    app.activeDocument.artLayers.add().name = "Entourage Shadow Dummy";

                                    app.activeDocument.activeLayer.move(app.activeDocument.layerSets.getByName("Overall Adjustments Group"), ElementPlacement.INSIDE);

                                // Entourage

                                    app.activeDocument.artLayers.add().name = "Entourage Dummy";

                                    app.activeDocument.activeLayer.move(app.activeDocument.layerSets.getByName("Overall Adjustments Group"), ElementPlacement.INSIDE);

                                    groupActiveLayers();

                                    app.activeDocument.activeLayer.name = "Entourage"

                                    setActiveLayerBlendingModeToNormal();

                            // Group sublayers

                                groupActiveLayers();

                                app.activeDocument.activeLayer.name = "Entourage";

                                app.activeDocument.layers.getByName("Overall Adjustments Group").layers.getByName("Entourage Shadow Dummy").move(app.activeDocument.layerSets.getByName("Overall Adjustments Group").layerSets.getByName("Entourage"), ElementPlacement.INSIDE);

                                app.activeDocument.activeLayer = app.activeDocument.layerSets.getByName("Overall Adjustments Group").layerSets.getByName("Entourage").layers.getByName("Entourage Shadow Dummy");

                                groupActiveLayers();

                                app.activeDocument.activeLayer.name = "Entourage Shadow"

                                app.activeDocument.layers.getByName("Overall Adjustments Group").layers.getByName("Entourage").layerSets.getByName("Entourage Shadow").name = "Shadow"

                            // Delete dummy layers

                                app.activeDocument.layerSets.getByName("Overall Adjustments Group").layerSets.getByName("Entourage").layerSets.getByName("Entourage").layers.getByName("Entourage Dummy").remove();

                                app.activeDocument.layerSets.getByName("Overall Adjustments Group").layerSets.getByName("Entourage").layerSets.getByName("Shadow").layers.getByName("Entourage Shadow Dummy").remove();

                                moveActiveLayerBack();

                                moveActiveLayerBack();

                        // Collapse all groups

                            collapseAllGroups();

                        // Save

                            app.activeDocument.save();
                    };
            };

        // Sub-functions

            // Group all passes

                function groupAllPasses(){
                    // Create groups for non b2b layers

                        app.activeDocument.layerSets.add().name = "Overlay Group";

                        app.activeDocument.layerSets.add().name = "Selection Group";

                        app.activeDocument.artLayers.add().name = "Selection Group Dummy"

                        app.activeDocument.layers.getByName("Selection Group Dummy").move(app.activeDocument.layerSets.getByName("Selection Group"), ElementPlacement.INSIDE);

                    // Select all layers

                        cTID = function(s) { return cTID[s] || (cTID[s] = app.charIDToTypeID(s)); };
                        sTID = function(s) { return app.stringIDToTypeID(s); };

                        selectAllLayers();

                    // Do for selected layers

                        // Do for selected layers setup 1

                            function cID (inVal) { return charIDToTypeID(inVal);}
                            function sID (inVal) { return stringIDToTypeID(inVal);}

                            main();
                            function main()
                            {
                            optionsDialog();
                            }
                            function optionsDialog()
                            {

                            OpenOptionsDialog = new Window("dialog");

                            mainGroup = OpenOptionsDialog.add("group");

                            function runTheScript (){
                            var SelectedLayers = getSelectedLayers();

                            for (var i = 0; i < SelectedLayers.length; i++)
                            {
                            activeDocument.activeLayer = SelectedLayers[i];

                        // Thing to do

                            app.activeDocument.activeLayer = SelectedLayers[i];

                            if (app.activeDocument.activeLayer.kind == LayerKind.SMARTOBJECT){
                                var searchItems = [
                                    [/glass/i,'Glass', /disregardthisname/gim, /b2b/i],
                                    [/alph/i,'Alpha', /disregardthisname/gim, /selection/gim],
                                    [/ao|amb(.*)oc|ext(.*)tex/i,"AO", /disregardthisname/i, /overlay/i],
                                    [/atmosp/i,"Atmosphere", /disregardthisname/i, /overlay/i],
                                    [/background/i,"Background", /disregardthisname/i, /b2b/i, /32bitonly/i],
                                    [/beaut|rgb/i,"Beauty Pass", /disregardthisname/i, /overlay/i],
                                    [/bump(.*)norm/i, "Bump Normals", /disregardthisname/i, /selection/i, /16bitonly/i],
                                    [/diff/i,'Diffuse', /disregardthisname/i, /b2b/i, /32bitonly/i],
                                    [/norm/i, "Normals", /world|bump/i, /selection/i, /16bitonly/i],
                                    [/raw(.*)gi|raw(.*)glo/i, "Raw GI", /disregardthisname/i, /b2b/i],
                                    [/raw(.*)ligh/i, "Raw Lighting", /disregardthisname/i, /b2b/i, /32bitonly/i],
                                    [/raw(.*)refl/i,"Raw Reflection", /disregardthisname/i, /b2b/i, /32bitonly/i],
                                    [/raw(.*)refr/i,"Raw Refraction", /disregardthisname/i, /b2b/i],
                                    [/raw(.*)shad/i,"Raw Shadow", /disregardthisname/i, /overlay/i],
                                    [/refl(.*)filt/i,"Reflection Filter", /disregardthisname/i, /b2b/i, /32bitonly/i],
                                    [/refr(.*)filt/i,"Refraction Filter", /disregardthisname/i, /b2b/i, /32bitonly/i],
                                    [/self(.*)illu/i,"Self Illumination", /disregardthisname/i, /overlay/i, /32bitonly/i],
                                    [/spec/i, "Specular", /disregardthisname/i, /b2b/i, /32bitonly/i],
                                    [/sun/i, "Sun", /disregardthisname/i, /b2b/i, /32bitonly/i],
                                    [/wire/i, "Wire Color", /disregardthisname/i, /selection/i, /16bitonly/i],
                                ];

                                var len = searchItems.length

                                for (var l = 0; l < len; l++){
                                    var re = new RegExp(searchItems[l][0])
                                    var antire = new RegExp(searchItems[l][2])
                                    var layerType = new RegExp(searchItems[l][3])

                                    if (re.test(app.activeDocument.activeLayer.name) && !antire.test(app.activeDocument.activeLayer.name)){
                                        if(layerType.test("b2b")){
                                            var activeLayerNameToString = app.activeDocument.activeLayer.name.toString();

                                            groupActiveLayers();

                                            app.activeDocument.activeLayer.name = activeLayerNameToString + " Group"
                                        };

                                        if(layerType.test("selection")){
                                            app.activeDocument.activeLayer.move(app.activeDocument.layerSets.getByName("Selection Group"), ElementPlacement.INSIDE)
                                        };

                                        if(layerType.test("overlay")){
                                            app.activeDocument.activeLayer.move(app.activeDocument.layerSets.getByName("Overlay Group"), ElementPlacement.INSIDE)
                                        };
                                    };
                                };
                            };

                        // Do for selected layers setup 2

                            };
                            OpenOptionsDialog.close()
                            };

                            runTheScript();

                            var result = OpenOptionsDialog.hide();
                            };

                            function getSelectedLayers()
                            {
                            var resultLayers=new Array();
                            try{
                            var descGrp = new ActionDescriptor();
                            var refGrp = new ActionReference();
                            refGrp.putEnumerated(cID( "Lyr " ),cID( "Ordn" ),cID( "Trgt" ));
                            descGrp.putReference(cID( "null" ), refGrp );
                            executeAction( sID( "groupLayersEvent" ), descGrp, DialogModes.NO );
                            for (var ix=0;ix<app.activeDocument.activeLayer.layers.length;ix++){resultLayers.push(app.activeDocument.activeLayer.layers[ix])}
                            var desc5 = new ActionDescriptor();
                            var ref2 = new ActionReference();
                            ref2.putEnumerated( cID( "HstS" ), cID( "Ordn" ), cID( "Prvs" ) );
                            desc5.putReference( cID( "null" ), ref2 );
                            executeAction( cID( "slct" ), desc5, DialogModes.NO );
                            } catch (err) { }
                            return resultLayers;
                            };
                };

    // Rerender organisation and rerender organisation same location

        // Rerender organisation new location

            // For specified

                function rerenderOrganisationForSpecified(){
                    // Prompt for root folder path

                        if(runBy3dsMax != true){
                            var rootFolderPath = prompt("Specify folder path...", "");

                            // Get current folder if relevant

                                if(rootFolderPath == "C" || rootFolderPath == "c"){
                                    try{
                                        var rootFolderPath = app.activeDocument.path.fsName.replace(/%20/g, " ");

                                        var rootFolderPathTextToSplitPrelim = rootFolderPath.split("\\");
                                        var rootFolderPathTextToSplit = ("\\" + rootFolderPathTextToSplitPrelim[rootFolderPathTextToSplitPrelim.length - 2] + "\\" + rootFolderPathTextToSplitPrelim[rootFolderPathTextToSplitPrelim.length - 1]);

                                        var rootFolderPath = rootFolderPath.split(rootFolderPathTextToSplit)[0];
                                    }catch(e){};
                                };
                        }else{
                            var rootFolderPath = app.activeDocument.layers.getByName("rootFolderPath").layers[0].name
                        };

                        if(rootFolderPath == undefined || rootFolderPath == ""){
                            return;
                        };

                    // Prompt for original frame number

                        if(runBy3dsMax != true){
                            var promptForFrameNumber = prompt("Specify original frame number...", "");
                        }else{
                            var promptForFrameNumber = app.activeDocument.layers.getByName("promptForFrameNumber").layers[0].name
                        };

                        if(promptForFrameNumber == undefined){
                            return;
                        };

                        // Create originalFrameNumber variable

                            var originalFrameNumber = promptForFrameNumber.split(" ").toString();

                    // Prompt for new frame number(s)

                        if(runBy3dsMax != true){
                            var promptForNewFrameNumber = prompt("Specify new frame number (if multiple, separate each with a comma and space), or type \'All\'", "");
                        }else{
                            var promptForNewFrameNumber = app.activeDocument.layers.getByName("promptForNewFrameNumber").layers[0].name
                        };

                        if(promptForNewFrameNumber == undefined){
                            return;
                        };

                    // Prompt for High Res

                        if(runBy3dsMax != true){
                            var promptForHighRes = prompt("Do for high res files? Type Y for yes or leave blank for no", "");
                        }else{
                            var promptForHighRes = app.activeDocument.layers.getByName("promptForHighRes").layers[0].name
                        };

                        if(promptForHighRes == "Y" || promptForHighRes == "y" || promptForHighRes == "yes" || promptForHighRes == "Yes" || promptForHighRes == "YES"){
                            var runScriptOnHighResFiles = "true"
                            var wordHighResIfApplicableWithSpace = " High Res"
                            var wordHighResIfApplicable = "High Res"
                        }else{
                            var runScriptOnHighResFiles = "false"
                            var wordHighResIfApplicableWithSpace = ""
                            var wordHighResIfApplicable = ""
                        };

                    // Prompt for 16b

                        if(runBy3dsMax != true){
                            var promptFor16b = prompt("Do for 16b files as well as 32b files? Type Y for yes, O for only 16b files, or leave blank for no", "");
                        }else{
                            var promptFor16b = app.activeDocument.layers.getByName("promptFor16b").layers[0].name
                        };

                        if(promptFor16b == "Y" || promptFor16b == "y" || promptFor16b == "o" || promptFor16b == "O"){
                            if(promptFor16b == "Y" || promptFor16b == "y"){
                                var runScriptOn16bFiles = "true"
                            }else{
                                var runScriptOn16bFiles = "only"
                            };
                        }else{
                            var runScriptOn16bFiles = "false"
                        };

                    // Create originalFolderPath variable

                        // Loop through all folders in the root folder and find the folder for the current frame number

                            // Variables etc

                                var rootPath = rootFolderPath
                                var targetLayers = new Array;
                                var subDirectory = "/LinkedLayers/";
                                var configFolder = Folder(rootPath);
                                var fileList = configFolder.getFiles();

                            // Loop

                                for (var b = 0; b < fileList.length; b ++){
                                    // Variables etc

                                        var tempPreliminary = fileList[b].toString().replace(/\\/g, "/")
                                        var temp = tempPreliminary.split("/")[tempPreliminary.split("/").length - 1];
                                        var tempNoSpaces = temp.replace(/%20/g, " ")
                                        var frameNumberPlusSpace = originalFrameNumber + " "

                                    if (tempNoSpaces.startsWith(frameNumberPlusSpace)){
                                        // Create folder path variable

                                            if(runScriptOnHighResFiles == "true"){
                                                var originalFolderPath = rootFolderPath + "/" + temp + "/" + "High Res"

                                                var originalFrameName = temp + " High Res"
                                            }else{
                                                var originalFolderPath = rootFolderPath + "/" + temp + "/" + "Low Res"

                                                var originalFrameName = temp
                                            };
                                    };
                                };

                    // Set up for "All" if applicable

                        if(promptForNewFrameNumber == "All" || promptForNewFrameNumber == "all" || promptForNewFrameNumber == "ALL" || promptForNewFrameNumber == "A"|| promptForNewFrameNumber == "a"){
                            // Get number of frame folders

                                // Variables etc

                                    var rootPath = rootFolderPath
                                    var targetLayers = new Array;
                                    var subDirectory = "/LinkedLayers/";
                                    var configFolder = Folder(rootPath);
                                    var fileList = configFolder.getFiles();

                                    var frameCount = 0

                                // Count frames

                                    // Create frameNumbersArray variable

                                        var frameNumbersArray = [];

                                    for (var a = 0; a < fileList.length; a++){
                                        var frameNumberToPush = fileList[a].toString().split("/")[fileList[a].toString().split("/").length - 1].replace(/%20/g, " ").split(" ")[0]

                                        frameNumbersArray.push(frameNumberToPush)

                                        frameCount++
                                    };

                                // Create listOfFrameNumbers variable

                                    var listOfFrameNumbers = frameNumbersArray
                        }else{
                            // Create listOfFrameNumbers variable

                                var listOfFrameNumbers = promptForNewFrameNumber.split(", ")
                        };

                    // Hide palettes

                        if(initialPrompt != undefined){
                            app.togglePalettes();
                        };

                        if(app.documents.length == 0){
                            var dontShowPalettes = "True"
                        }else{
                            var dontShowPalettes = "False"
                        };

                    // Loop through new frames and run the script

                        for(a = 0; a < listOfFrameNumbers.length; a++){
                            // Create newFrameNumber variable

                                var newFrameNumber = listOfFrameNumbers[a]

                            // Create newFolderPath variable

                                // Loop through all folders in the root folder and find the folder for the current frame number

                                    // Variables etc

                                        var rootPath = rootFolderPath
                                        var targetLayers = new Array;
                                        var subDirectory = "/LinkedLayers/";
                                        var configFolder = Folder(rootPath);
                                        var fileList = configFolder.getFiles();

                                    // Loop

                                        for (var b = 0; b < fileList.length; b ++){
                                            // Variables etc

                                                var tempPreliminary = fileList[b].toString().replace(/\\/g, "/")
                                                var temp = tempPreliminary.split("/")[tempPreliminary.split("/").length - 1];
                                                var tempNoSpaces = temp.replace(/%20/g, " ")
                                                var newFrameNumberPlusSpace = newFrameNumber + " "

                                            if (tempNoSpaces.startsWith(newFrameNumberPlusSpace)){
                                                // Create newFolderPath variable

                                                    if(runScriptOnHighResFiles == "true"){
                                                        var newFolderPath = rootFolderPath + "/" + temp + "/" + "High Res"

                                                        var newFrameName = temp.replace(/%20/g, " ") + " High Res";
                                                    }else{
                                                        var newFolderPath = rootFolderPath + "/" + temp + "/" + "Low Res"

                                                        var newFrameName = temp.replace(/%20/g, " ");
                                                    };
                                            };
                                        };

                                if(newFolderPath == undefined || newFolderPath == ""){
                                    return;
                                };

                            // Test whether diffuse pass exists

                                // Variables etc

                                    var rootPath = newFolderPath
                                    var targetLayers = new Array;
                                    var subDirectory = "/LinkedLayers/";
                                    var configFolder = Folder(rootPath);
                                    var fileList = configFolder.getFiles();

                                // Create passesExist variable

                                    for (var b = fileList.length -1; b >= 0  ; b--){
                                        var tempPreliminary1 = fileList[b].toString();
                                        var tempPreliminary = tempPreliminary1.replace(/\\/g, "/")
                                        var temp = tempPreliminary.split("/")[tempPreliminary.split("/").length - 1]
                                        var reguEx = new RegExp(/.exr/gim);
                                        var reguEx3 = new RegExp(/ultimatte/gim);
                                        var reguEx4 = new RegExp(/wire/i);
                                        var reguEx5 = new RegExp(/psb/i);
                                        var reguEx6 = new RegExp(/orld/i);
                                        var reguEx7 = new RegExp(/alpha/i);
                                        var reguEx8 = new RegExp(/raw(.*)shad/i);
                                        var reguEx9 = new RegExp(/diffuse/i);

                                        if (reguEx.test(temp) &&  !reguEx3.test(temp) && !reguEx4.test(temp) && reguEx9.test(temp)){
                                            // Create passesExist variable

                                                var passesExist = "true"
                                        };
                                    };

                            // Run script

                                if(passesExist == "true"){
                                    // Run script on 32b file if applicable

                                        if(runScriptOn16bFiles != "only"){
                                            // Open original file

                                                // Variables etc

                                                    var rootPath = originalFolderPath
                                                    var targetLayers = new Array;
                                                    var subDirectory = "/LinkedLayers/";
                                                    var configFolder = Folder(rootPath);
                                                    var fileList = configFolder.getFiles();

                                                // Open original file

                                                    for (var i = 0; i < fileList.length; i++){
                                                        var tempPreliminary1 = fileList[i].toString();
                                                        var tempPreliminary = tempPreliminary1.replace(/\\/g, "/")
                                                        var temp = tempPreliminary.split("/")[tempPreliminary.split("/").length - 1]
                                                        var reguEx = new RegExp(/.psb/gim);
                                                        var word16b = new RegExp(/16b/gim);

                                                        if (reguEx.test(temp) && !word16b.test(temp)){
                                                            try{
                                                                // Open file

                                                                    app.open(File(fileList[i]));
                                                            }catch(e){};
                                                        };
                                                    };

                                            if(newFrameNumber != originalFrameNumber){
                                                // If the file to replace is open, close it without saving
                                                    try{
                                                        app.documents.getByName(newFrameName + ".psb").close(SaveOptions.DONOTSAVECHANGES);
                                                    }catch(e){}

                                                // Save if first round

                                                    if(a == 0){
                                                        app.activeDocument.save();
                                                    };

                                                // Save as new file

                                                    var pathPlusName = File(newFolderPath + "/" + newFrameName + ".psb");

                                                    SavePSB(pathPlusName);

                                                // Run rerender script

                                                    rerenderOrganisation();

                                                // Save

                                                    app.activeDocument.save();
                                            }else{
                                                // Run rerender script

                                                    rerenderOrganisationSameLocation(false);

                                                // Save

                                                    app.activeDocument.save();
                                            };
                                        };

                                    // Run script on 16b file if applicable

                                        if(runScriptOn16bFiles != "false"){
                                            // Close 32b file if open

                                                try{
                                                    var fileToSave = app.documents.getByName(originalFrameName + ".psb")

                                                    saveFileOnlyIfChangesWereMade(fileToSave);

                                                    app.documents.getByName(originalFrameName + ".psb").close(SaveOptions.DONOTSAVECHANGES);
                                                }catch(e){};

                                            // If the file to replace's 32b version is open, save it and close

                                                try{
                                                    var fileToSave = app.documents.getByName(newFrameName + ".psb");

                                                    saveFileOnlyIfChangesWereMade(fileToSave);

                                                    app.documents.getByName(newFrameName + ".psb").close(SaveOptions.DONOTSAVECHANGES);
                                                }catch(e){}

                                            // Open original file

                                                // Variables etc

                                                    var rootPath = originalFolderPath
                                                    var targetLayers = new Array;
                                                    var subDirectory = "/LinkedLayers/";
                                                    var configFolder = Folder(rootPath);
                                                    var fileList = configFolder.getFiles();

                                                // Open original file

                                                    for (var i = 0; i < fileList.length; i++){
                                                        var tempPreliminary1 = fileList[i].toString();
                                                        var tempPreliminary = tempPreliminary1.replace(/\\/g, "/")
                                                        var temp = tempPreliminary.split("/")[tempPreliminary.split("/").length - 1]
                                                        var reguEx = new RegExp(/.psb/gim);
                                                        var word16b = new RegExp(/16b/gim);

                                                        if (reguEx.test(temp) && word16b.test(temp)){
                                                            try{
                                                                // Open file

                                                                    app.open(File(fileList[i]));
                                                            }catch(e){};
                                                        };
                                                    };

                                            if(newFrameNumber != originalFrameNumber){
                                                // If the file to replace is open, close it without saving

                                                    try{
                                                        app.documents.getByName(newFrameName + " 16b.psb").close(SaveOptions.DONOTSAVECHANGES);
                                                    }catch(e){}

                                                // Save if first round

                                                    if(a == 0){
                                                        app.activeDocument.save();
                                                    };

                                                // Save as new file

                                                    var pathPlusName = File(newFolderPath + "/" + newFrameName + " 16b.psb");

                                                    SavePSB(pathPlusName);

                                                // Replace all linked smart objects

                                                    // Select linked smart object

                                                        app.activeDocument.activeLayer = app.activeDocument.layers.getByName("Original Image Group").layers.getByName("Original Image");

                                                    // Replace contents

                                                        var idplacedLayerReplaceContents = stringIDToTypeID( "placedLayerReplaceContents" );
                                                        var desc900 = new ActionDescriptor();
                                                        var idnull = charIDToTypeID( "null" );
                                                        desc900.putPath( idnull, new File( app.activeDocument.path + "/" + app.activeDocument.name.split(" 16b")[0] + ".psb" ) );
                                                        executeAction( idplacedLayerReplaceContents, desc900, DialogModes.NO );

                                                // Run rerender script

                                                    rerenderOrganisation();

                                                // Save

                                                    app.activeDocument.save();
                                            }else{
                                                // Run rerender script

                                                    rerenderOrganisationSameLocation(false);

                                                // Save

                                                    app.activeDocument.save();
                                            };
                                        };
                                }

                            // Open original file

                                // If running script on 16b files, open original 16b file

                                    if(runScriptOn16bFiles == "false"){
                                        // Open original 32b file

                                            // Variables etc

                                                var rootPath = originalFolderPath
                                                var targetLayers = new Array;
                                                var subDirectory = "/LinkedLayers/";
                                                var configFolder = Folder(rootPath);
                                                var fileList = configFolder.getFiles();

                                            // Open original file

                                                for (var i = 0; i < fileList.length; i++){
                                                    var tempPreliminary1 = fileList[i].toString();
                                                    var tempPreliminary = tempPreliminary1.replace(/\\/g, "/")
                                                    var temp = tempPreliminary.split("/")[tempPreliminary.split("/").length - 1]
                                                    var reguEx = new RegExp(/.psb/gim);
                                                    var word16b = new RegExp(/16b/gim);

                                                    if(reguEx.test(temp) && !word16b.test(temp)){
                                                        try{
                                                            // Open file

                                                                app.open(File(fileList[i]));
                                                        }catch(e){};
                                                    };
                                                };

                                            // Ensure all modified content is updated

                                                var idplacedLayerUpdateAllModified = stringIDToTypeID( "placedLayerUpdateAllModified" );
                                                executeAction( idplacedLayerUpdateAllModified, undefined, DialogModes.NO );

                                            // Save

                                                app.activeDocument.save();
                                    }else{
                                        // Open original 16b file

                                                // Variables etc

                                                    var rootPath = originalFolderPath
                                                    var targetLayers = new Array;
                                                    var subDirectory = "/LinkedLayers/";
                                                    var configFolder = Folder(rootPath);
                                                    var fileList = configFolder.getFiles();

                                                // Open original file

                                                    for (var i = 0; i < fileList.length; i++){
                                                        var tempPreliminary1 = fileList[i].toString();
                                                        var tempPreliminary = tempPreliminary1.replace(/\\/g, "/")
                                                        var temp = tempPreliminary.split("/")[tempPreliminary.split("/").length - 1]
                                                        var reguEx = new RegExp(/.psb/gim);
                                                        var word16b = new RegExp(/16b/gim);

                                                        if (reguEx.test(temp) && word16b.test(temp)){
                                                            try{
                                                                // Open file

                                                                    app.open(File(fileList[i]));
                                                            }catch(e){};
                                                        };
                                                    };

                                                // Ensure all modified content is updated

                                                    var idplacedLayerUpdateAllModified = stringIDToTypeID( "placedLayerUpdateAllModified" );
                                                    executeAction( idplacedLayerUpdateAllModified, undefined, DialogModes.NO );

                                                // Save

                                                    app.activeDocument.save();
                                    };
                        };
                };

            // Main function

                function rerenderOrganisation(){
                    rerenderOrganisation1();

                    rerenderOrganisation2();

                    rerenderOrganisation3(false);

                    rerenderOrganisation4();

                    rerenderOrganisation5();
                };

        // Rerender organisation same location

            // For specified

                function rerenderOrganisationSameLocationForSpecified(){
                    // Prompt for root folder path

                        if(runBy3dsMax != true){
                            var rootFolderPath = prompt("Specify folder path...", "");

                            // Get current folder if relevant

                                if(rootFolderPath == "C" || rootFolderPath == "c"){
                                    try{
                                        var rootFolderPath = app.activeDocument.path.fsName.replace(/%20/g, " ");

                                        var rootFolderPathTextToSplitPrelim = rootFolderPath.split("\\");
                                        var rootFolderPathTextToSplit = ("\\" + rootFolderPathTextToSplitPrelim[rootFolderPathTextToSplitPrelim.length - 2] + "\\" + rootFolderPathTextToSplitPrelim[rootFolderPathTextToSplitPrelim.length - 1]);

                                        var rootFolderPath = rootFolderPath.split(rootFolderPathTextToSplit)[0];
                                    }catch(e){};
                                };
                        }else{
                            var rootFolderPath = app.activeDocument.layers.getByName("rootFolderPath").layers[0].name
                        };

                        if(rootFolderPath == undefined || rootFolderPath == ""){
                            return;
                        };

                    // Prompt for frame number(s)

                        if(runBy3dsMax != true){
                            var promptForFrameNumber = prompt("Specify frame number (if multiple, separate each with a comma and space), or type \'All\'", "");
                        }else{
                            var promptForFrameNumber = app.activeDocument.layers.getByName("promptForFrameNumber").layers[0].name
                        };

                        if(promptForFrameNumber == undefined){
                            return;
                        };

                    // Prompt for High Res

                        if(runBy3dsMax != true){
                            var promptForHighRes = prompt("Do for high res files? Type Y for yes or leave blank for no", "");
                        }else{
                            var promptForHighRes = app.activeDocument.layers.getByName("promptForHighRes").layers[0].name
                        };

                        if(promptForHighRes == "Y" || promptForHighRes == "y" || promptForHighRes == "yes" || promptForHighRes == "Yes" || promptForHighRes == "YES"){
                            var runScriptOnHighResFiles = "true"
                            var wordHighResIfApplicableWithSpace = " High Res"
                            var wordHighResIfApplicable = "High Res"
                        }else{
                            var runScriptOnHighResFiles = "false"
                            var wordHighResIfApplicableWithSpace = ""
                            var wordHighResIfApplicable = ""
                        };

                    // Prompt for 16b

                        if(runBy3dsMax != true){
                            var promptFor16b = prompt("Do for 16b files as well as 32b files? Type Y for yes, O for only 16b files, or leave blank for no", "");
                        }else{
                            var promptFor16b = app.activeDocument.layers.getByName("promptFor16b").layers[0].name
                        };

                        if(promptFor16b == "Y" || promptFor16b == "y" || promptFor16b == "o" || promptFor16b == "O"){
                            if(promptFor16b == "Y" || promptFor16b == "y"){
                                var runScriptOn16bFiles = "true"
                            }else{
                                var runScriptOn16bFiles = "only"
                            };
                        }else{
                            var runScriptOn16bFiles = "false"
                        };

                    // Set up for "All" if applicable

                        if(promptForFrameNumber == "All" || promptForFrameNumber == "all" || promptForFrameNumber == "ALL" || promptForFrameNumber == "A"|| promptForFrameNumber == "a"){
                            // Get number of frame folders

                                // Variables etc

                                    var rootPath = rootFolderPath
                                    var targetLayers = new Array;
                                    var subDirectory = "/LinkedLayers/";
                                    var configFolder = Folder(rootPath);
                                    var fileList = configFolder.getFiles();

                                    var frameCount = 0

                                // Count frames

                                    // Create frameNumbersArray variable

                                        var frameNumbersArray = [];

                                    for (var a = 0; a < fileList.length; a++){
                                        var frameNumberToPush = fileList[a].toString().split("/")[fileList[a].toString().split("/").length - 1].replace(/%20/g, " ").split(" ")[0]

                                        frameNumbersArray.push(frameNumberToPush)

                                        frameCount++
                                    };

                                // Create listOfFrameNumbers variable

                                    var listOfFrameNumbers = frameNumbersArray
                        }else{
                            // Create listOfFrameNumbers variable

                                var listOfFrameNumbers = promptForFrameNumber.split(", ")
                        };

                    // Hide palettes

                        if(initialPrompt != undefined){
                            app.togglePalettes();
                        };

                        if(app.documents.length == 0){
                            var dontShowPalettes = "True"
                        }else{
                            var dontShowPalettes = "False"
                        };

                    // Loop through frames and run the script

                        for(var a = 0; a < listOfFrameNumbers.length; a++){
                            // Variables

                                var copySelectionPassesFrom32bFileBoolean = false;

                            // Create frameNumber variable

                                var frameNumber = listOfFrameNumbers[a]

                            // Create folder path variable

                                // Loop through all folders in the root folder and find the folder for the current frame number

                                    // Variables etc

                                        var rootPath = rootFolderPath
                                        var targetLayers = new Array;
                                        var subDirectory = "/LinkedLayers/";
                                        var configFolder = Folder(rootPath);
                                        var fileList = configFolder.getFiles();

                                    // Loop

                                        for (var b = 0; b < fileList.length; b ++){
                                            // Variables etc

                                                var tempPreliminary = fileList[b].toString().replace(/\\/g, "/")
                                                var temp = tempPreliminary.split("/")[tempPreliminary.split("/").length - 1];
                                                var tempNoSpacesPreliminary = temp.replace(/%20/g, " ")
                                                var tempNoSpaces = tempNoSpacesPreliminary.toString()
                                                var frameNumberPlusSpace = frameNumber + " "

                                            if (tempNoSpaces.startsWith(frameNumberPlusSpace)){
                                                // Create folder path variable

                                                    if(runScriptOnHighResFiles == "true"){
                                                        var folderPath = rootFolderPath + "/" + temp + "/" + "High Res"

                                                        var frameName = temp.replace(/%20/g, " ") + " High Res"
                                                    }else{
                                                        var folderPath = rootFolderPath + "/" + temp + "/" + "Low Res"

                                                        var frameName = temp.replace(/%20/g, " ")
                                                    };
                                            };
                                        };

                                if(folderPath == undefined || folderPath == ""){
                                    return;
                                };

                            // Test whether diffuse pass exists

                                // Variables etc

                                    var rootPath = folderPath
                                    var targetLayers = new Array;
                                    var subDirectory = "/LinkedLayers/";
                                    var configFolder = Folder(rootPath);
                                    var fileList = configFolder.getFiles();

                                // Create passesExist variable

                                    for (var b = fileList.length -1; b >= 0  ; b--){
                                        var tempPreliminary1 = fileList[b].toString();
                                        var tempPreliminary = tempPreliminary1.replace(/\\/g, "/")
                                        var temp = tempPreliminary.split("/")[tempPreliminary.split("/").length - 1]
                                        var reguEx = new RegExp(/.exr/gim);
                                        var reguEx3 = new RegExp(/ultimatte/gim);
                                        var reguEx4 = new RegExp(/wire/i);
                                        var reguEx5 = new RegExp(/psb/i);
                                        var reguEx6 = new RegExp(/orld/i);
                                        var reguEx7 = new RegExp(/alpha/i);
                                        var reguEx8 = new RegExp(/raw(.*)shad/i);
                                        var reguEx9 = new RegExp(/diffuse/i);

                                        if (reguEx.test(temp) &&  !reguEx3.test(temp) && !reguEx4.test(temp) && reguEx9.test(temp)){
                                            // Create passesExist variable

                                                var passesExist = "true"
                                        };
                                    };

                            // Run rerender script

                                if (passesExist == "true"){
                                    if(runScriptOn16bFiles != "false"){
                                        // Variables etc

                                            var rootPath = folderPath
                                            var targetLayers = new Array;
                                            var subDirectory = "/LinkedLayers/";
                                            var configFolder = Folder(rootPath);
                                            var fileList = configFolder.getFiles();

                                        // Run script on 32b file if applicable

                                            if(runScriptOn16bFiles != "only"){
                                                // Run script on 32b files

                                                    for (var i = 0; i < fileList.length; i++){
                                                        var tempPreliminary1 = fileList[i].toString();
                                                        var tempPreliminary = tempPreliminary1.replace(/\\/g, "/")
                                                        var temp = tempPreliminary.split("/")[tempPreliminary.split("/").length - 1]
                                                        var reguEx = new RegExp(/.psb/gim);
                                                        var word16b = new RegExp(/16b/gim);

                                                        if (reguEx.test(temp) && !word16b.test(temp)){
                                                            try{
                                                                // Open file

                                                                    app.open(File(fileList[i]));

                                                                // Rerender organisation same location

                                                                    rerenderOrganisationSameLocation(false);

                                                                // Copy selection passes and redefine copySelectionPassesFrom32bFileBoolean variable

                                                                    try{
                                                                        // Select the groups

                                                                            try{
                                                                                app.activeDocument.activeLayer = app.activeDocument.layerSets.getByName("Multimatte");
                                                                            }catch(e){};

                                                                            try{
                                                                                var idslct = charIDToTypeID( "slct" );
                                                                                var desc208 = new ActionDescriptor();
                                                                                var idnull = charIDToTypeID( "null" );
                                                                                var ref96 = new ActionReference();
                                                                                var idLyr = charIDToTypeID( "Lyr " );
                                                                                ref96.putName( idLyr, "World Normals Group" );
                                                                                desc208.putReference( idnull, ref96 );
                                                                                var idselectionModifier = stringIDToTypeID( "selectionModifier" );
                                                                                var idselectionModifierType = stringIDToTypeID( "selectionModifierType" );
                                                                                var idaddToSelection = stringIDToTypeID( "addToSelection" );
                                                                                desc208.putEnumerated( idselectionModifier, idselectionModifierType, idaddToSelection );
                                                                                var idMkVs = charIDToTypeID( "MkVs" );
                                                                                desc208.putBoolean( idMkVs, false );
                                                                                var idLyrI = charIDToTypeID( "LyrI" );
                                                                                var list36 = new ActionList();
                                                                                list36.putInteger( 200 );
                                                                                list36.putInteger( 176 );
                                                                                desc208.putList( idLyrI, list36 );
                                                                                executeAction( idslct, desc208, DialogModes.NO );
                                                                            }catch(e){};

                                                                            try{
                                                                                var idslct = charIDToTypeID( "slct" );
                                                                                var desc209 = new ActionDescriptor();
                                                                                var idnull = charIDToTypeID( "null" );
                                                                                var ref97 = new ActionReference();
                                                                                var idLyr = charIDToTypeID( "Lyr " );
                                                                                ref97.putName( idLyr, "Alpha Group" );
                                                                                desc209.putReference( idnull, ref97 );
                                                                                var idselectionModifier = stringIDToTypeID( "selectionModifier" );
                                                                                var idselectionModifierType = stringIDToTypeID( "selectionModifierType" );
                                                                                var idaddToSelection = stringIDToTypeID( "addToSelection" );
                                                                                desc209.putEnumerated( idselectionModifier, idselectionModifierType, idaddToSelection );
                                                                                var idMkVs = charIDToTypeID( "MkVs" );
                                                                                desc209.putBoolean( idMkVs, false );
                                                                                var idLyrI = charIDToTypeID( "LyrI" );
                                                                                var list37 = new ActionList();
                                                                                list37.putInteger( 202 );
                                                                                list37.putInteger( 200 );
                                                                                list37.putInteger( 176 );
                                                                                desc209.putList( idLyrI, list37 );
                                                                                executeAction( idslct, desc209, DialogModes.NO );
                                                                            }catch(e){};

                                                                        // Copy

                                                                            var idcopy = charIDToTypeID( "copy" );
                                                                            executeAction( idcopy, undefined, DialogModes.NO );

                                                                        // Update Variable

                                                                            copySelectionPassesFrom32bFileBoolean = true;
                                                                    }catch(e){};

                                                                // Save

                                                                    saveFileOnlyIfChangesWereMade(app.activeDocument);
                                                            }catch(e){};
                                                        };
                                                    };
                                            };

                                            //* Run script on 16b file if it exists (should replace try statement with if (16b file exists) statement to improve speed)

                                                try{
                                                    // Run script on 16b file

                                                        for (var i = 0; i < fileList.length; i++){
                                                            var tempPreliminary1 = fileList[i].toString();
                                                            var tempPreliminary = tempPreliminary1.replace(/\\/g, "/")
                                                            var temp = tempPreliminary.split("/")[tempPreliminary.split("/").length - 1]
                                                            var reguEx = new RegExp(/.psb/gim);
                                                            var word16b = new RegExp(/16b/gim);

                                                            if (reguEx.test(temp) && word16b.test(temp)){
                                                                try{
                                                                    // Close 32b file if open

                                                                        try{
                                                                            var fileToSave = app.documents.getByName(frameName + ".psb")

                                                                            saveFileOnlyIfChangesWereMade(fileToSave);

                                                                            app.documents.getByName(frameName + ".psb").close(SaveOptions.DONOTSAVECHANGES);
                                                                        }catch(e){};

                                                                    // Open file

                                                                        app.open(File(fileList[i]));

                                                                    // Rerender organisation same location

                                                                        if(copySelectionPassesFrom32bFileBoolean == true){
                                                                            rerenderOrganisationSameLocation(true);
                                                                        }else{
                                                                            rerenderOrganisationSameLocation(false);
                                                                        };

                                                                    // Save

                                                                        saveFileOnlyIfChangesWereMade(app.activeDocument);
                                                                }catch(e){};
                                                            };
                                                        };

                                                    // If a 16b file wasn't found (active document's name isn't the relevant 16b file), try opening the relevant 32b file and shifting it to 16b mode

                                                        if(app.activeDocument.name != frameName + " 16b.psb" && app.activeDocument.name != frameName + " High Res 16b.psb"){
                                                            try{
                                                                // Open the 32b file

                                                                    for (var i = 0; i < fileList.length; i++){
                                                                        var tempPreliminary1 = fileList[i].toString();
                                                                        var tempPreliminary = tempPreliminary1.replace(/\\/g, "/")
                                                                        var temp = tempPreliminary.split("/")[tempPreliminary.split("/").length - 1]
                                                                        var reguEx = new RegExp(/.psb/gim);
                                                                        var word16b = new RegExp(/16b/gim);

                                                                        if (reguEx.test(temp) && !word16b.test(temp)){
                                                                            try{
                                                                                // Open file

                                                                                    app.open(File(fileList[i]));

                                                                                // Shift to 16b mode

                                                                                    shiftTo16bMode();

                                                                                // Save

                                                                                    saveFileOnlyIfChangesWereMade(app.activeDocument);
                                                                            }catch(e){};
                                                                        };
                                                                    };
                                                            }catch(e){}
                                                        }

                                                    // Save

                                                        saveFileOnlyIfChangesWereMade(app.activeDocument);
                                                }catch(e){};
                                    }else{
                                        // Variables etc

                                            var rootPath = folderPath
                                            var targetLayers = new Array;
                                            var subDirectory = "/LinkedLayers/";
                                            var configFolder = Folder(rootPath);
                                            var fileList = configFolder.getFiles();

                                        // Run script on 32b files

                                            for (var a = 0; a < fileList.length; a++){
                                                var tempPreliminary1 = fileList[a].toString();
                                                var tempPreliminary = tempPreliminary1.replace(/\\/g, "/")
                                                var temp = tempPreliminary.split("/")[tempPreliminary.split("/").length - 1]
                                                var reguEx = new RegExp(/.psb/gim);
                                                var word16b = new RegExp(/16b/gim);

                                                if (reguEx.test(temp) && !word16b.test(temp)){
                                                    try{
                                                        // Open file

                                                            app.open(File(fileList[a]));

                                                        // Rerender organisation same location

                                                            rerenderOrganisationSameLocation(false);

                                                        // Save

                                                            saveFileOnlyIfChangesWereMade(app.activeDocument);
                                                    }catch(e){};
                                                };
                                            };

                                        // Save

                                            saveFileOnlyIfChangesWereMade(app.activeDocument);
                                    };
                                };
                        };
                };

            // Main function

                function rerenderOrganisationSameLocation(pasteSelectionPassesBoolean){
                    rerenderOrganisation1();

                    rerenderOrganisation3(pasteSelectionPassesBoolean);

                    rerenderOrganisation5();
                };

        // Sub-functions

            // Main function divided

                function rerenderOrganisation1(){
                    // Zoom out

                        setZoom();

                    // Visibility Loop

                        visibilityLoop();

                    // Change image size to size of diffuse layer

                        app.activeDocument.activeLayer = app.activeDocument.layers.getByName("Total Lighting Group").layers.getByName("Diffuse Group").layers.getByName("Diffuse");

                        createSelectionFromActiveLayersThubnail();

                        cropToSelection();

                        try{
                            app.activeDocument.layers.getByName("setCanvasSizeToDiffusePassSizeFromActiveDocumentsLocation Dummy Layer").remove();
                        }catch(e){};

                    // Delete contents of alpha group

                        try{
                            app.activeDocument.layerSets.getByName("Alpha Group").layers.removeAll();
                        }catch(e){};
                };

                function rerenderOrganisation2(){
                    // Group all layers

                        // Select all layers

                            selectAllLayers();

                        // Group

                            groupActiveLayers();

                        // Rename group just made

                            app.activeDocument.layers[0].name = "All Layers Group";

                    // Replace core passes

                        // Select all layers group

                            selectAllLayersInSpecifiedLayerSet(app.activeDocument.layers.getByName("All Layers Group"));

                        // Replace core passes

                            rasterizeSOLayers(app.activeDocument);

                            function rasterizeSOLayers(theParent){
                                for (var m = theParent.layers.length - 1; m >= 0;m--) {

                                    var theLayer = theParent.layers[m];

                                    if(theLayer.typename == "ArtLayer"){
                                        if(theLayer.kind == LayerKind.SMARTOBJECT){
                                            var theVisibility = theLayer.visible;
                                            app.activeDocument.activeLayer = theLayer;

                                            // Replace old pass with new pass

                                                var searchItems = [
                                                    [/Glass/i,".All_Isolated_Glass_To_Rename.", "_All_Isolated_Glass_To_Rename.", /All_Isolated_Glass_To_Rename/i],
                                                    [/AO/i,".AO.","_AO.", /ao|amb(.*)oc|ext(.*)tex/i],
                                                    [/Atmosphere/i,".Atmosphere.","_Atmosphere.", /atmosp/i],
                                                    [/Background/i,".Background.","_Background.", /background/i],
                                                    [/Beauty Pass/i,".RGB_color.","_RGB_color.", /beaut|rgb/i],
                                                    [/Diffuse/i,".Diffuse_Filter.","_Diffuse_Filter.", /diff/i],
                                                    [/Fresnel/i,".Fresnel.","_Fresnel.", /fresnel/i],
                                                    [/Raw GI/i,".Raw_GI.","_Raw_GI.", /raw(.*)gi|raw(.*)glo/i],
                                                    [/Raw Lighting/i,".Raw_Lighting.","_Raw_Lighting.", /raw(.*)ligh/i],
                                                    [/Raw Reflection/i,".Raw_Reflection.","_Raw_Reflection.", /raw(.*)refl/i],
                                                    [/Raw Refraction/i,".Raw_Refraction.","_Raw_Refraction.", /raw(.*)refr/i],
                                                    [/Shadow/i,".Shadow.","_Shadow.", /shadow/i],
                                                    [/Reflection Filter/i,".Reflection_Filter.","_Reflection_Filter.", /refl(.*)filt/i],
                                                    [/Refraction Filter/i,".Refraction_Filter.","_Refraction_Filter.", /refr(.*)filt/i],
                                                    [/Self Illumination/i,".Self_Illumination.","_Self_Illumination.", /self(.*)illu/i],
                                                    [/Specular/i,".Specular.","_Specular.", /spec/i],
                                                    [/Sun/i,".Sun.","_Sun.", /sun/i],
                                                    [/Wire Color/i,".Wire_Color.","_Wire_Color.", /wire/i],
                                                ];

                                                for (var l = 0; l < searchItems.length; l++){
                                                    var re = new RegExp(searchItems[l][0])

                                                    if(re.test(app.activeDocument.activeLayer.name)){
                                                        var passToPlace = new RegExp (searchItems[l][3])
                                                        var myPath = decodeURI (app.activeDocument.path.fsName);

                                                        try{
                                                            // Put old pass's name and attributes to variables

                                                                var activeLayerNameToString = app.activeDocument.activeLayer.name.toString();

                                                                var activeLayerOpacity = app.activeDocument.activeLayer.opacity

                                                                var activeLayerFillOpacity = app.activeDocument.activeLayer.fillOpacity

                                                                var activeLayerBlendMode = app.activeDocument.activeLayer.blendMode

                                                            // Create selection from active layer's mask if it exists

                                                                // Deselect in case selection exists

                                                                    deselect();

                                                                createSelectionFromActiveLayersLayerMask()

                                                            // Place new pass

                                                                try{
                                                                    // Variables etc

                                                                        var rootPath = decodeURI (app.activeDocument.path.fsName);
                                                                        var targetLayers = new Array;
                                                                        var subDirectory = "/LinkedLayers/";
                                                                        targetLayers = app.activeDocument.layers;
                                                                        var configFolder = Folder(rootPath);
                                                                        var fileList = configFolder.getFiles();

                                                                    // Place

                                                                        for (var i = fileList.length -1; i >= 0  ; i--){
                                                                            var tempPreliminary1 = fileList[i].toString();
                                                                            var tempPreliminary = tempPreliminary1.replace(/\\/g, "/")
                                                                            var temp = tempPreliminary.split("/")[tempPreliminary.split("/").length - 1]
                                                                            var reguEx = new RegExp(/.exr/gim);
                                                                            var reguEx3 = new RegExp(/ultimatte/gim);
                                                                            var reguEx4 = new RegExp(/wire/i);
                                                                            var reguEx5 = new RegExp(/normals/i);
                                                                            var reguEx7 = new RegExp(/alpha/i);
                                                                            var reguEx8 = new RegExp(/raw(.*)shad/i);
                                                                            var reguEx9 = new RegExp(/fresnel/i);

                                                                            if (reguEx.test(temp) &&  !reguEx3.test(temp) && !reguEx4.test(temp) && passToPlace.test(temp)){
                                                                                if (!reguEx5.test(temp) || !reguEx7.test(temp) || !reguEx8.test(temp) || !reguEx9.test(temp)){
                                                                                    // Place linked smart object

                                                                                        var idPlc = charIDToTypeID( "Plc " );
                                                                                        var desc13 = new ActionDescriptor();
                                                                                        var idIdnt = charIDToTypeID( "Idnt" );
                                                                                        desc13.putInteger( idIdnt, 130 );
                                                                                        var idnull = charIDToTypeID( "null" );
                                                                                        desc13.putPath( idnull, new File( fileList[i] ) );
                                                                                        var idLnkd = charIDToTypeID( "Lnkd" );
                                                                                        desc13.putBoolean( idLnkd, true );
                                                                                        var idOpAs = charIDToTypeID( "OpAs" );
                                                                                        var desc14 = new ActionDescriptor();
                                                                                        var idAChn = charIDToTypeID( "AChn" );
                                                                                        desc14.putInteger( idAChn, 0 );
                                                                                        var idEXRf = charIDToTypeID( "EXRf" );
                                                                                        desc13.putObject( idOpAs, idEXRf, desc14 );
                                                                                        var idFTcs = charIDToTypeID( "FTcs" );
                                                                                        var idQCSt = charIDToTypeID( "QCSt" );
                                                                                        var idQcsa = charIDToTypeID( "Qcsa" );
                                                                                        desc13.putEnumerated( idFTcs, idQCSt, idQcsa );
                                                                                        var idOfst = charIDToTypeID( "Ofst" );
                                                                                        var desc15 = new ActionDescriptor();
                                                                                        var idHrzn = charIDToTypeID( "Hrzn" );
                                                                                        var idPxl = charIDToTypeID( "#Pxl" );
                                                                                        desc15.putUnitDouble( idHrzn, idPxl, 0.000000 );
                                                                                        var idVrtc = charIDToTypeID( "Vrtc" );
                                                                                        var idPxl = charIDToTypeID( "#Pxl" );
                                                                                        desc15.putUnitDouble( idVrtc, idPxl, 0.000000 );
                                                                                        var idOfst = charIDToTypeID( "Ofst" );
                                                                                        desc13.putObject( idOfst, idOfst, desc15 );
                                                                                        executeAction( idPlc, desc13, DialogModes.NO );
                                                                                };
                                                                            };
                                                                        };
                                                                }catch(e){
                                                                };

                                                            // Rename new pass

                                                                app.activeDocument.activeLayer.name = activeLayerNameToString;

                                                            // Add old layer's attributes and mask (if it exists) to new layer

                                                                app.activeDocument.activeLayer.opacity = activeLayerOpacity

                                                                app.activeDocument.activeLayer.fillOpacity = activeLayerFillOpacity

                                                                app.activeDocument.activeLayer.blendMode = activeLayerBlendMode

                                                            // Move back a layer

                                                                moveBackALayer();

                                                            // Apply filters to new layer if applicable

                                                                duplicateActiveLayersFiltersToLayerAbove();

                                                            // Deselect in case selection exists

                                                                deselect();

                                                            // Try to select active layer's mask

                                                                createSelectionFromActiveLayersLayerMask();

                                                            // Remove old pass

                                                                app.activeDocument.activeLayer.remove();

                                                            // Add mask if it existed

                                                                createMaskFromSelectionOnActiveLayer();

                                                            // Deselect in case selection exists

                                                                deselect();
                                                        }catch(e){};
                                                    };
                                                };
                                        };
                                    }else{
                                        rasterizeSOLayers(theLayer)
                                    }
                                };

                                return;
                            };

                        // Ungroup all layers

                            app.activeDocument.activeLayer = app.activeDocument.layers.getByName("All Layers Group")

                            ungroupActiveGroup()
                };

                function rerenderOrganisation3(pasteSelectionPassesBoolean){
                    // ***Hide irrelevant layers

                        try{
                            app.activeDocument.layers.getByName("Overlay Group").visible = false

                            app.activeDocument.layers.getByName("Total Lighting Group").visible = false

                            app.activeDocument.layers.getByName("Reflection Group").visible = false

                            app.activeDocument.layers.getByName("Refraction Group").visible = false

                            app.activeDocument.layers.getByName("Specular Group").visible = false

                            app.activeDocument.layers.getByName("Background Group").visible = false
                        }catch(e){};

                    // Expand canvas size to prevent 50% pixel selection problem

                        setCanvasSizeToDiffusePassSizeFromActiveDocumentsLocation(2);

                    // Update selection passes

                        if(pasteSelectionPassesBoolean == true){
                            // Remove existing selection passes

                                try{
                                    app.activeDocument.layerSets.getByName("Multimatte").remove();
                                }catch(e){};

                                try{
                                    app.activeDocument.layerSets.getByName("World Normals Group").remove();
                                }catch(e){};

                                try{
                                    app.activeDocument.layerSets.getByName("Alpha Group").remove();
                                }catch(e){};

                            // Select top layer

                                app.activeDocument.activeLayer = app.activeDocument.layers[0];

                            // Paste new selection passes

                                var idpast = charIDToTypeID( "past" );
                                var desc154 = new ActionDescriptor();
                                var idinPlace = stringIDToTypeID( "inPlace" );
                                desc154.putBoolean( idinPlace, true );
                                executeAction( idpast, desc154, DialogModes.NO );
                        }else{
                            // Place and deal with alpha

                                // Delete alpha group

                                    try{
                                        app.activeDocument.layers.getByName("Alpha Group").remove();
                                    }catch(e){};

                                completeAddAlphaPass();

                            // Replace World Normals passes

                                // Delete World Normals group

                                    try{
                                        app.activeDocument.layers.getByName("World Normals Group").remove();
                                    }catch(e){};

                                completeAddWorldNormalsPasses();

                            // Replace Multimatte passes

                                // Delete multimatte group

                                    try{
                                        app.activeDocument.layers.getByName("Multimatte").remove();
                                    }catch(e){};

                                completeAddMultimattePasses();
                        };

                    // Replace masks

                        multimatteMasksReplacement();

                    // Reset canvas size

                        app.activeDocument.activeLayer = app.activeDocument.layers.getByName("Total Lighting Group").layers.getByName("Diffuse Group").layers.getByName("Diffuse");

                        createSelectionFromActiveLayersThubnail();

                        cropToSelection();

                        try{
                            app.activeDocument.layers.getByName("setCanvasSizeToDiffusePassSizeFromActiveDocumentsLocation Dummy Layer").remove();
                        }catch(e){};

                    // ***Show irrelevant layers

                        try{
                            app.activeDocument.layers.getByName("Overlay Group").visible = true;

                            app.activeDocument.layers.getByName("Total Lighting Group").visible = true;

                            app.activeDocument.layers.getByName("Reflection Group").visible = true;

                            app.activeDocument.layers.getByName("Refraction Group").visible = true;

                            app.activeDocument.layers.getByName("Specular Group").visible = true;

                            app.activeDocument.layers.getByName("Background Group").visible = true;
                        }catch(e){};
                };

                function rerenderOrganisation4(){
                    /*
                    // Organise overlay passes visibility and/or grouping

                        // Beauty Pass
                            try{
                                var idHd = charIDToTypeID( "Hd  " );
                                var desc275 = new ActionDescriptor();
                                var idnull = charIDToTypeID( "null" );
                                var list52 = new ActionList();
                                var ref225 = new ActionReference();
                                var idLyr = charIDToTypeID( "Lyr " );
                                ref225.putName( idLyr, "Beauty Pass" );
                                list52.putReference( ref225 );
                                desc275.putList( idnull, list52 );
                                executeAction( idHd, desc275, DialogModes.NO );

                                var idHd = charIDToTypeID( "Hd  " );
                                var desc276 = new ActionDescriptor();
                                var idnull = charIDToTypeID( "null" );
                                var list53 = new ActionList();
                                var ref226 = new ActionReference();
                                var idLyr = charIDToTypeID( "Lyr " );
                                ref226.putName( idLyr, "Atmosphere" );
                                list53.putReference( ref226 );
                                desc276.putList( idnull, list53 );
                                executeAction( idHd, desc276, DialogModes.NO );
                            }catch(e){};

                        // Make AO group for AO
                            try{
                                app.activeDocument.activeLayer = app.activeDocument.layers.getByName("Overlay Group").layers.getByName("AO");

                                groupActiveLayers();

                                app.activeDocument.activeLayer.name = "AO Group"

                                setActiveLayerBlendingModeToMultiply();

                                makeActiveLayersOpacityZero();

                                createMaskOnActiveLayer();

                                try{
                                    app.activeDocument.activeLayer = app.activeDocument.layers.getByName("Overlay Group").layers.getByName("AO Group");

                                    setActiveLayerBlendingModeToMultiply()

                                    var idsetd = charIDToTypeID( "setd" );
                                    var desc280 = new ActionDescriptor();
                                    var idnull = charIDToTypeID( "null" );
                                    var ref229 = new ActionReference();
                                    var idLyr = charIDToTypeID( "Lyr " );
                                    var idOrdn = charIDToTypeID( "Ordn" );
                                    var idTrgt = charIDToTypeID( "Trgt" );
                                    ref229.putEnumerated( idLyr, idOrdn, idTrgt );
                                    desc280.putReference( idnull, ref229 );
                                    var idT = charIDToTypeID( "T   " );
                                    var desc281 = new ActionDescriptor();
                                    var idOpct = charIDToTypeID( "Opct" );
                                    var idPrc = charIDToTypeID( "#Prc" );
                                    desc281.putUnitDouble( idOpct, idPrc, 30.000000 );
                                    var idLyr = charIDToTypeID( "Lyr " );
                                    desc280.putObject( idT, idLyr, desc281 );
                                    executeAction( idsetd, desc280, DialogModes.NO );
                                }catch(e){};
                            }catch(e){};

                        // Self Illumination
                            try{
                                var idslct = charIDToTypeID( "slct" );
                                var desc282 = new ActionDescriptor();
                                var idnull = charIDToTypeID( "null" );
                                var ref230 = new ActionReference();
                                var idLyr = charIDToTypeID( "Lyr " );
                                ref230.putName( idLyr, "Self Illumination" );
                                desc282.putReference( idnull, ref230 );
                                var idMkVs = charIDToTypeID( "MkVs" );
                                desc282.putBoolean( idMkVs, false );
                                executeAction( idslct, desc282, DialogModes.NO );

                                setActiveLayerBlendingModeToLinearDodge();

                            }catch(e){};

                        // Z-Depth
                            try{
                                var idHd = charIDToTypeID( "Hd  " );
                                var desc285 = new ActionDescriptor();
                                var idnull = charIDToTypeID( "null" );
                                var list54 = new ActionList();
                                var ref232 = new ActionReference();
                                var idLyr = charIDToTypeID( "Lyr " );
                                ref232.putName( idLyr, "Z-Depth" );
                                list54.putReference( ref232 );
                                desc285.putList( idnull, list54 );
                                executeAction( idHd, desc285, DialogModes.NO );
                            }catch(e){};
                    */
                };

                function rerenderOrganisation5(){
                    // Ensure all modified content is updated

                        var idplacedLayerUpdateAllModified = stringIDToTypeID( "placedLayerUpdateAllModified" );
                        executeAction( idplacedLayerUpdateAllModified, undefined, DialogModes.NO );

                    // Collapse all groups

                        collapseAllGroups();

                    // Invisibility Loop

                        invisibilityLoop();
                };

            // Replace masks

                function multimatteMasksReplacement(){
                    // Put all selection passes into multimatte group, so we only need to loop over all layers once

                        // Do for world normals

                            for(var l = 0; l < app.activeDocument.layerSets.getByName("World Normals Group").artLayers.length; l++){
                                app.activeDocument.layerSets.getByName("World Normals Group").artLayers[l].duplicate(app.activeDocument.layers.getByName("Multimatte"), ElementPlacement.INSIDE).name = app.activeDocument.layerSets.getByName("World Normals Group").artLayers[l].name;
                            };

                        // Do for alpha

                            try{
                                app.activeDocument.layerSets.getByName("Alpha Group").artLayers.getByName("Alpha").duplicate(app.activeDocument.layers.getByName("Multimatte"), ElementPlacement.INSIDE).name = "Alpha";

                                app.activeDocument.layerSets.getByName("Alpha Group").artLayers.getByName("Z-Depth").duplicate(app.activeDocument.layers.getByName("Multimatte"), ElementPlacement.INSIDE).name = "Z-Depth";
                            }catch(e){};

                    // Select all layers

                        selectAllLayers();

                    // Get names

                        // List of selected layers indices

                            var selectedLayers = getSelectedLayersIndex();
                            var layerNames = new Array();

                        // Get layer names and put them in an array along with the index

                            for(var a in selectedLayers){
                                layerNames.push(getNameByIndex(Number(selectedLayers[a])));
                            };

                    // Functions for above

                        function getNameByIndex(idx){
                            ref = new ActionReference();
                            ref.putProperty( charIDToTypeID("Prpr") , charIDToTypeID( "Nm  " ));
                            ref.putIndex( charIDToTypeID( "Lyr " ), idx );
                            return executeActionGet(ref).getString(charIDToTypeID( "Nm  " ));
                        };

                    // Replace masks

                        for (var l = 0; l < layerNames.length; l++){
                            if(layerNames[l].toString().match("adjustments")){
                                try{
                                    // Select inverse of diffuse pass' or original image's transparency, to get 1-pixel border

                                        try{
                                            app.activeDocument.activeLayer = app.activeDocument.layers.getByName("Total Lighting Group").layers.getByName("Diffuse Group").layers.getByName("Diffuse")
                                        }catch(e){
                                            app.activeDocument.activeLayer = app.activeDocument.layers.getByName("Original Image Group").layers.getByName("Original Image")
                                        }

                                        selectActiveLayersTransparency()

                                        invertSelection()

                                    // Select multimatte pass[l]

                                        try{
                                            app.activeDocument.activeLayer = app.activeDocument.layerSets.getByName("Multimatte").artLayers.getByName(layerNames[l].toString().split(" adjustments")[0]);
                                        }catch(e){
                                            app.activeDocument.activeLayer = app.activeDocument.layerSets.getByName("Multimatte").artLayers.getByName(layerNames[l].toString().split(" adjustments")[0].split("nverse ")[1]);
                                        };

                                    // Select and replace all masks made from active multimatte layer

                                        // Add selection from active layer's transparency

                                            addActiveLayersTransparencyToSelection();

                                        // Select adj groups corresponding to active multimatte layer

                                            try{
                                                selectAllLayersMatchingSpecifiedString(" copy", app.activeDocument.activeLayer.name.split(" copy")[0] +" adjustments", "Inverse " + app.activeDocument.activeLayer.name.split(" copy")[0] +" adjustments");
                                            }catch(e){};

                                        // Replace mask on selected layers

                                            try{
                                                // Do for selected layers setup 1

                                                    function cID (inVal){ return charIDToTypeID(inVal);}
                                                    function sID (inVal){ return stringIDToTypeID(inVal);}

                                                    main();

                                                    function main(){
                                                        optionsDialog();
                                                    }

                                                    function optionsDialog(){
                                                        OpenOptionsDialog = new Window("dialog");

                                                        mainGroup = OpenOptionsDialog.add("group");

                                                        function runTheScript (){
                                                            var SelectedLayers = getSelectedLayers();

                                                            for (var i = 0; i < SelectedLayers.length; i++){
                                                                activeDocument.activeLayer = SelectedLayers[i];

                                                // Thing to do

                                                    // Replace mask on selected layer

                                                        try{
                                                            // Select RGB channel

                                                                selectActiveLayersThumbnail();

                                                            // Delete mask

                                                                deleteActiveLayersLayerMask();

                                                            // Invert if active layer is inverse

                                                                var activeLayerName = app.activeDocument.activeLayer.name;
                                                                var wordInverse = new RegExp(/inverse/i);

                                                                if(wordInverse.test(activeLayerName)){
                                                                    invertSelection();
                                                                };

                                                            // Create mask from selection on active layer

                                                                createMaskFromSelectionOnActiveLayer();

                                                            // Select diffuse pass' or original image's transparency, to exclude 1-pixel border

                                                                try{
                                                                    app.activeDocument.activeLayer = app.activeDocument.layers.getByName("Total Lighting Group").layers.getByName("Diffuse Group").layers.getByName("Diffuse")
                                                                }catch(e){
                                                                    app.activeDocument.activeLayer = app.activeDocument.layers.getByName("Original Image Group").layers.getByName("Original Image")
                                                                }

                                                                selectActiveLayersTransparency()

                                                            // Reselect relevant layer

                                                                activeDocument.activeLayer = SelectedLayers[i];

                                                            // Intersect selection with active layer's layer mask

                                                                intersectCurrentSelectionWithActiveLayersLayerMask()

                                                            // Delete active layer's layer mask

                                                                deleteActiveLayersLayerMask()

                                                            // Add new mask on active layer from selection

                                                                createMaskFromSelectionOnActiveLayer()

                                                            // Select inverse of diffuse pass' or original image's transparency, to get 1-pixel border

                                                                try{
                                                                    app.activeDocument.activeLayer = app.activeDocument.layers.getByName("Total Lighting Group").layers.getByName("Diffuse Group").layers.getByName("Diffuse")
                                                                }catch(e){
                                                                    app.activeDocument.activeLayer = app.activeDocument.layers.getByName("Original Image Group").layers.getByName("Original Image")
                                                                }

                                                                selectActiveLayersTransparency()

                                                                invertSelection()

                                                            // Reselect relevant layer

                                                                activeDocument.activeLayer = SelectedLayers[i];

                                                            // Add selection from active layer's layer mask to selection

                                                                  addSelectionFromActiveLayersLayerMaskToSelection();

                                                            // Reinvert if active layer is inverse

                                                                var activeLayerName = app.activeDocument.activeLayer.name;
                                                                var wordInverse = new RegExp(/inverse/gim);

                                                                if(wordInverse.test(activeLayerName)){
                                                                    invertSelection();
                                                                };
                                                        }catch(e){};

                                                // Do for selected layers setup 2

                                                    }
                                                    OpenOptionsDialog.close()
                                                    }

                                                    runTheScript();

                                                    var result = OpenOptionsDialog.hide();
                                                    }

                                                    function getSelectedLayers()
                                                    {
                                                    var resultLayers=new Array();
                                                    try{
                                                    var descGrp = new ActionDescriptor();
                                                    var refGrp = new ActionReference();
                                                    refGrp.putEnumerated(cID( "Lyr " ),cID( "Ordn" ),cID( "Trgt" ));
                                                    descGrp.putReference(cID( "null" ), refGrp );
                                                    executeAction( sID( "groupLayersEvent" ), descGrp, DialogModes.NO );
                                                    for (var ix=0;ix<app.activeDocument.activeLayer.layers.length;ix++){resultLayers.push(app.activeDocument.activeLayer.layers[ix])}
                                                    var desc5 = new ActionDescriptor();
                                                    var ref2 = new ActionReference();
                                                    ref2.putEnumerated( cID( "HstS" ), cID( "Ordn" ), cID( "Prvs" ) );
                                                    desc5.putReference( cID( "null" ), ref2 );
                                                    executeAction( cID( "slct" ), desc5, DialogModes.NO );
                                                    } catch (err){ }
                                                    return resultLayers;
                                                    }
                                            }catch(e){};
                                }catch(e){};
                            };
                        };

                    // Hide superseded adjustment groups

                        try{
                            // Select all layers ending with " adjustments"

                                selectAllLayersEndingWithSpecifiedString(" copy", " adjustments")

                            // Do for selected layers

                                try{
                                    var SelectedLayers = getSelectedLayers();

                                    for (var i = 0; i < SelectedLayers.length; i++){
                                        activeDocument.activeLayer = SelectedLayers[i];

                                        // Thing to do

                                            // Reset multimatteLayerExists variable to false

                                                var multimatteLayerExists = false

                                            // Create nameToMatch variable

                                                var nameToMatchPreliminary2 = app.activeDocument.activeLayer.name.replace(" adjustments", "")

                                                var nameToMatchPreliminary1 = nameToMatchPreliminary2.replace(" copy", "")

                                                var nameToMatch = nameToMatchPreliminary1.replace("Inverse ", "")

                                            // Determine if corresponding selection layer exists
                                                try{
                                                    for(var a = 0; a < app.activeDocument.layers.getByName("Multimatte").layers.length; a++){
                                                        if(app.activeDocument.layers.getByName("Multimatte").layers[a].name == nameToMatch){
                                                            var multimatteLayerExists = true
                                                        };
                                                    };
                                                }catch(e){};

                                                try{
                                                    for(var a = 0; a < app.activeDocument.layers.getByName("World Normals Group").layers.length; a++){
                                                        if(app.activeDocument.layers.getByName("World Normals Group").layers[a].name == nameToMatch){
                                                            var multimatteLayerExists = true
                                                        };
                                                    };
                                                }catch(e){};

                                                try{
                                                    for(var a = 0; a < app.activeDocument.layers.getByName("Alpha Group").layers.length; a++){
                                                        if(app.activeDocument.layers.getByName("alpha Group").layers[a].name == nameToMatch){
                                                            var multimatteLayerExists = true
                                                        };
                                                    };
                                                }catch(e){};

                                            // If it didn't exist, set the group to be hidden during invisibility loop if regular adjustment group, or remove mask if inverse

                                                if(multimatteLayerExists != true){
                                                    // try{
                                                        var relevantLayerNameToString = app.activeDocument.activeLayer.name.toString();

                                                        if(relevantLayerNameToString.startsWith("Inverse ")){
                                                            // Delete active layer's layer mask

                                                                deleteActiveLayersLayerMask();

                                                            // Select all

                                                                var idsetd = charIDToTypeID( "setd" );
                                                                var desc1469 = new ActionDescriptor();
                                                                var idnull = charIDToTypeID( "null" );
                                                                var ref1311 = new ActionReference();
                                                                var idChnl = charIDToTypeID( "Chnl" );
                                                                var idfsel = charIDToTypeID( "fsel" );
                                                                ref1311.putProperty( idChnl, idfsel );
                                                                desc1469.putReference( idnull, ref1311 );
                                                                var idT = charIDToTypeID( "T   " );
                                                                var idOrdn = charIDToTypeID( "Ordn" );
                                                                var idAl = charIDToTypeID( "Al  " );
                                                                desc1469.putEnumerated( idT, idOrdn, idAl );
                                                                executeAction( idsetd, desc1469, DialogModes.NO );

                                                            // Create mask from selection on active layer

                                                                createMaskFromSelectionOnActiveLayer();
                                                        }else{
                                                            getLayerChain(app.activeDocument.activeLayer);

                                                            layersToHide.push(app.activeDocument.activeLayer.name);

                                                            app.activeDocument.activeLayer.name = relevantLayerNameToString;
                                                        };
                                                    // }catch(e){};
                                                };

                                            // If it did exist, and the layer is "Glass", set the group to be shown during invisibility loop if regular adjustment group, or add mask if inverse

                                                if(multimatteLayerExists != false){
                                                    if(app.activeDocument.activeLayer.name == "Isolated Glass adjustments"){
                                                        // try{
                                                            var relevantLayerNameToString = app.activeDocument.activeLayer.name.toString();

                                                            if(relevantLayerNameToString.startsWith("Inverse ")){
                                                                // Add active layer's layer mask

                                                                    deleteActiveLayersLayerMask()

                                                                    app.activeDocument.activeLayer = app.activeDocument.layers.getByName("Multimatte").layers.getByName(nameToMatch)

                                                                    deselect()

                                                                    addActiveLayersTransparencyToSelection()

                                                                    activeDocument.activeLayer = SelectedLayers[i];

                                                                    createMaskFromSelectionOnActiveLayer()
                                                            }else{
                                                                getLayerChain(app.activeDocument.activeLayer);

                                                                // Remove the layer from the layers to hide array

                                                                    var activeLayersLayerChainToString = app.activeDocument.activeLayer.name.toString();

                                                                    for (var z=layersToHide.length-1; z>=0; z--) {
                                                                        if (layersToHide[z] === activeLayersLayerChainToString){
                                                                            layersToHide.splice(z, 1);
                                                                            break;
                                                                        };
                                                                    };

                                                                app.activeDocument.activeLayer.name = relevantLayerNameToString;
                                                            };
                                                        // }catch(e){};
                                                    };
                                                };
                                    };
                                }catch(e){};
                        }catch(e){};

                    // Deselect

                        deselect();

                    // Delete all the passes added to multimatte group

                        // Remove non-world normals layers

                            try{
                                app.activeDocument.layers.getByName("Multimatte").layers.getByName("Alpha").remove();
                            }catch(e){};

                            try{
                                app.activeDocument.layers.getByName("Multimatte").layers.getByName("Shadow").remove();
                            }catch(e){};

                            try{
                                app.activeDocument.layers.getByName("Multimatte").layers.getByName("Fresnel").remove();
                            }catch(e){};

                            try{
                                app.activeDocument.layers.getByName("Multimatte").layers.getByName("Fresnel (Glass)").remove();
                            }catch(e){};

                            try{
                                app.activeDocument.layers.getByName("Multimatte").layers.getByName("Edges").remove();
                            }catch(e){};

                            try{
                                app.activeDocument.layers.getByName("Multimatte").layers.getByName("Z-Depth").remove();
                            }catch(e){};

                        // Remove world normals layers

                            for(var i = app.activeDocument.layerSets.getByName("Multimatte").layers.length - 1; i >= 0; i--){
                                // Variables

                                    var currentName = app.activeDocument.layerSets.getByName("Multimatte").layers[i].name;

                                if(currentName == "- x" || currentName == "+ x" || currentName == "- y" || currentName == "+ y" || currentName == "- z" || currentName == "+ z" || currentName == "- x (Glass)" || currentName == "+ x (Glass)" || currentName == "- y (Glass)" || currentName == "+ y (Glass)" || currentName == "- z (Glass)" || currentName == "+ z (Glass)"){
                                    app.activeDocument.layerSets.getByName("Multimatte").layers[i].remove();
                                };
                            };

                    // Select multimatte layer

                        app.activeDocument.activeLayer = app.activeDocument.layerSets.getByName("Multimatte");
                };

            // Adding selection passes

                // Add multimatte passes

                    function completeAddMultimattePasses(){
                        completeAddSelectionPasses("ultimatte", "Multimatte", "red");

                        moveGlassLayersToBottomOfGroup();
                    };

                // Add world normals passes

                    function completeAddWorldNormalsPasses(){
                        completeAddSelectionPasses("ormals", "World Normals Group", "green");
                    };

                // Add alpha pass

                    function completeAddAlphaPass(){
                        completeAddSelectionPasses("disregardme", "Alpha Group", "blue");
                    };

                // Add selection passes

                    function completeAddSelectionPasses(lastWordInGroupTypeMinusFirstLetter, groupName, colour){
                        // Create selection pass load layers dummy group

                            app.activeDocument.artLayers.add().name = "Selection Pass Load Layers Dummy";

                        // Move active layer to top

                            moveActiveLayerToTop ();
                            moveActiveLayerToTop ();
                            moveActiveLayerToTop ();

                        // Create layerset around active layer

                            groupActiveLayers();

                        // Set active layer name

                            app.activeDocument.activeLayer.name = groupName;

                        // Set colour

                            if (colour == "none"){
                                setLayerColourToNone();
                            };

                            if (colour == "red"){
                                setLayerColourToRed();
                            };

                            if (colour == "green"){
                                setLayerColourToGreen();
                            };

                            if (colour == "blue"){
                                setLayerColourToBlue();
                            };

                        // Move back a layer

                            moveBackALayer();

                        // Load new passes

                            // Place linked smart object of every relevant exr from folder

                                // Variables etc

                                    var rootPath = decodeURI (app.activeDocument.path.fsName);
                                    var targetLayers = new Array;
                                    var subDirectory = "/LinkedLayers/";
                                    targetLayers = app.activeDocument.layers;
                                    var configFolder = Folder(rootPath);
                                    var fileList = configFolder.getFiles();

                                for (var i = fileList.length -1; i >= 0  ; i--){
                                    // Variables etc

                                        var tempPreliminary1 = fileList[i].toString();
                                        var tempPreliminary = tempPreliminary1.replace(/\\/g, "/")
                                        var temp = tempPreliminary.split("/")[tempPreliminary.split("/").length - 1]
                                        var reguEx = new RegExp(/.exr/gim);

                                        if (groupName == "Multimatte"){
                                            var reguEx2 = new RegExp(/world(.*)normals/gim);
                                            var reguEx3 = new RegExp(/ultimatte/gim);
                                            var reguEx4 = new RegExp(/ultimatte/gim);
                                            var reguEx5 = new RegExp(/ultimatte/gim);
                                            var reguEx6 = new RegExp(/ultimatte/gim);
                                        };

                                        if (groupName == "World Normals Group"){
                                            var reguEx2 = new RegExp(/ultimatte/gim);
                                            var reguEx3 = new RegExp(/world(.*)normals/gim);
                                            var reguEx4 = new RegExp(/shadow/gim);
                                            var reguEx5 = new RegExp(/fresnel/gim);
                                            var reguEx6 = new RegExp(/edges/gim);
                                        };

                                        if (groupName == "Alpha Group"){
                                            var reguEx2 = new RegExp(/ultimatte/gim);
                                            var reguEx3 = new RegExp(/alpha/gim);
                                            var reguEx4 = new RegExp(/z(.*)dep/gim);
                                            var reguEx5 = new RegExp(/alpha/gim);
                                            var reguEx6 = new RegExp(/alpha/gim);
                                        };

                                    // Place

                                        if(reguEx.test(temp) && !reguEx2.test(temp) && (reguEx3.test(temp) || reguEx4.test(temp) || reguEx5.test(temp) || reguEx6.test(temp))){
                                            var idPlc = charIDToTypeID( "Plc " );
                                            var desc13 = new ActionDescriptor();
                                            var idIdnt = charIDToTypeID( "Idnt" );
                                            desc13.putInteger( idIdnt, 130 );
                                            var idnull = charIDToTypeID( "null" );
                                            desc13.putPath( idnull, new File( fileList[i] ) );
                                            var idLnkd = charIDToTypeID( "Lnkd" );
                                            desc13.putBoolean( idLnkd, true );
                                            var idOpAs = charIDToTypeID( "OpAs" );
                                            var desc14 = new ActionDescriptor();
                                            var idAChn = charIDToTypeID( "AChn" );
                                            desc14.putInteger( idAChn, 0 );
                                            var idEXRf = charIDToTypeID( "EXRf" );
                                            desc13.putObject( idOpAs, idEXRf, desc14 );
                                            var idFTcs = charIDToTypeID( "FTcs" );
                                            var idQCSt = charIDToTypeID( "QCSt" );
                                            var idQcsa = charIDToTypeID( "Qcsa" );
                                            desc13.putEnumerated( idFTcs, idQCSt, idQcsa );
                                            var idOfst = charIDToTypeID( "Ofst" );
                                            var desc15 = new ActionDescriptor();
                                            var idHrzn = charIDToTypeID( "Hrzn" );
                                            var idPxl = charIDToTypeID( "#Pxl" );
                                            desc15.putUnitDouble( idHrzn, idPxl, 0.000000 );
                                            var idVrtc = charIDToTypeID( "Vrtc" );
                                            var idPxl = charIDToTypeID( "#Pxl" );
                                            desc15.putUnitDouble( idVrtc, idPxl, 0.000000 );
                                            var idOfst = charIDToTypeID( "Ofst" );
                                            desc13.putObject( idOfst, idOfst, desc15 );
                                            executeAction( idPlc, desc13, DialogModes.NO );
                                        };
                                };

                        // If doing for world normals, rename and reorder passes

                            if (groupName == "World Normals Group"){
                                // Setup 1

                                    var activeLayerByName = app.activeDocument.layerSets.getByName(groupName);
                                    var myLength = activeLayerByName.layers.length;
                                    for (var i = 0; i < myLength; i++){
                                    app.activeDocument.activeLayer = activeLayerByName.layers[i]

                                // Thing to do

                                    var searchItems = [
                                        [/All_Isolated_Glass_To_Rename/i,'Glass', /disregardthisname/gim],
                                        [/alph/i,'Alpha', /disregardthisname/gim],
                                        [/ao|amb(.*)oc|ext(.*)tex/i,"AO", /disregardthisname/gim],
                                        [/atmosp/i,"Atmosphere", /disregardthisname/gim],
                                        [/backgr/i,"Background", /disregardthisname/gim],
                                        [/beaut|rgb/i,"Beauty Pass", /disregardthisname/gim],
                                        [/bump(.*)norm/i, "Bump Normals", /disregardthisname/gim],
                                        [/diff/i,'Diffuse', /disregardthisname/gim],
                                        [/edges/i,'Edges', /disregardthisname/gim],
                                        [/fresnel/i,"Fresnel", /disregardthisname/gim],
                                        [/norm/i, "Normals", /world|bump/gim],
                                        [/raw(.*)gi|raw(.*)glo/i, "Raw GI", /disregardthisname/gim],
                                        [/raw(.*)ligh/i, "Raw Lighting", /disregardthisname/gim],
                                        [/raw(.*)refl/i,"Raw Reflection", /disregardthisname/gim],
                                        [/raw(.*)refr/i,"Raw Refraction", /disregardthisname/gim],
                                        [/shadow/i,"Shadow", /disregardthisname/gim],
                                        [/refl(.*)filt/i,"Reflection Filter", /disregardthisname/gim],
                                        [/refr(.*)filt/i,"Refraction Filter", /disregardthisname/gim],
                                        [/self(.*)illu/i,"Self Illumination", /disregardthisname/gim],
                                        [/spec/i, "Specular", /disregardthisname/gim],
                                        [/spec/i, "Specular", /disregardthisname/gim],
                                        [/sun/i,"Sun", /disregardthisname/gim],
                                        [/wire/i, "Wire Color", /disregardthisname/gim],
                                        [/world(.*)norm(.*)\+(.*)x/i, "+ x", /disregardthisname/gim],
                                        [/world(.*)norm(.*)\+(.*)y/i, "+ y", /disregardthisname/gim],
                                        [/world(.*)norm(.*)\+(.*)z/i, "+ z", /disregardthisname/gim],
                                        [/world(.*)norm(.*)\-(.*)x/i, "- x", /disregardthisname/gim],
                                        [/world(.*)norm(.*)\-(.*)y/i, "- y", /disregardthisname/gim],
                                        [/world(.*)norm(.*)\-(.*)z/i, "- z", /disregardthisname/gim],
                                        [/z(.*)dep/i,"Z-Depth", /disregardthisname/gim]
                                    ];

                                    for (var l = 0; l < searchItems.length; l++){
                                        var re = new RegExp(searchItems[l][0])
                                        var antire = new RegExp(searchItems[l][2])
                                        var re2 = new RegExp(/(Glass)/i)

                                        if(re.test(app.activeDocument.activeLayer.name) && !antire.test(app.activeDocument.activeLayer.name)){
                                            if(re2.test(app.activeDocument.activeLayer.name)){
                                                app.activeDocument.activeLayer.name = searchItems[l][1] + " (Glass)";
                                            }else{
                                                app.activeDocument.activeLayer.name = searchItems[l][1];
                                            };
                                        };
                                    };

                                // Setup 2

                                    };

                                // Reorder

                                    try{
                                        app.activeDocument.layers.getByName(groupName).layers.getByName("- z").move(app.activeDocument.layers.getByName(groupName).layers[0], ElementPlacement.PLACEBEFORE);

                                        app.activeDocument.layers.getByName(groupName).layers.getByName("+ z").move(app.activeDocument.layers.getByName(groupName).layers[0], ElementPlacement.PLACEBEFORE);

                                        app.activeDocument.layers.getByName(groupName).layers.getByName("- y").move(app.activeDocument.layers.getByName(groupName).layers[0], ElementPlacement.PLACEBEFORE);

                                        app.activeDocument.layers.getByName(groupName).layers.getByName("+ y").move(app.activeDocument.layers.getByName(groupName).layers[0], ElementPlacement.PLACEBEFORE);

                                        app.activeDocument.layers.getByName(groupName).layers.getByName("- x").move(app.activeDocument.layers.getByName(groupName).layers[0], ElementPlacement.PLACEBEFORE);

                                        app.activeDocument.layers.getByName(groupName).layers.getByName("+ x").move(app.activeDocument.layers.getByName(groupName).layers[0], ElementPlacement.PLACEBEFORE);
                                    }catch(e){};
                            };

                        // Complete rasterize

                            // Rasterize all relevant layers

                                // Select all relevant layers

                                    selectAllLayersInSpecifiedLayerSet(app.activeDocument.layers.getByName(groupName));

                                // Do for selected layers setup 1

                                    function cID (inVal){ return charIDToTypeID(inVal);}
                                    function sID (inVal){ return stringIDToTypeID(inVal);}

                                    main();
                                    function main()
                                    {
                                    optionsDialog();
                                    }
                                    function optionsDialog()
                                    {

                                    OpenOptionsDialog = new Window("dialog");

                                    mainGroup = OpenOptionsDialog.add("group");

                                    function runTheScript ()
                                    {
                                    var SelectedLayers = getSelectedLayers();

                                    for (var i = 0; i < SelectedLayers.length; i++)
                                    {
                                    activeDocument.activeLayer = SelectedLayers[i];

                                // Thing to do

                                    // Rasterize

                                        rasterizeActiveLayer();

                                    // Put active layer's name to string

                                        var activeLayerNameToString = app.activeDocument.activeLayer.name.toString();

                                    // Duplicate

                                        app.activeDocument.activeLayer.duplicate(app.activeDocument.layers[0], ElementPlacement.PLACEBEFORE).name = "Rasterize Dummy";

                                    // Select

                                        app.activeDocument.activeLayer = app.activeDocument.layers.getByName("Rasterize Dummy");

                                    // Select all, then remove colour of dummy layer

                                        // select all

                                            var idsetd = charIDToTypeID( "setd" );
                                            var desc1469 = new ActionDescriptor();
                                            var idnull = charIDToTypeID( "null" );
                                            var ref1311 = new ActionReference();
                                            var idChnl = charIDToTypeID( "Chnl" );
                                            var idfsel = charIDToTypeID( "fsel" );
                                            ref1311.putProperty( idChnl, idfsel );
                                            desc1469.putReference( idnull, ref1311 );
                                            var idT = charIDToTypeID( "T   " );
                                            var idOrdn = charIDToTypeID( "Ordn" );
                                            var idAl = charIDToTypeID( "Al  " );
                                            desc1469.putEnumerated( idT, idOrdn, idAl );
                                            executeAction( idsetd, desc1469, DialogModes.NO );

                                        if(colour == "red"){
                                            var idSbtr = charIDToTypeID( "Sbtr" );
                                            var desc1471 = new ActionDescriptor();
                                            var idnull = charIDToTypeID( "null" );
                                            var ref1314 = new ActionReference();
                                            var idChnl = charIDToTypeID( "Chnl" );
                                            var idChnl = charIDToTypeID( "Chnl" );
                                            var idRd = charIDToTypeID( "Rd  " );
                                            ref1314.putEnumerated( idChnl, idChnl, idRd );
                                            desc1471.putReference( idnull, ref1314 );
                                            var idFrom = charIDToTypeID( "From" );
                                            var ref1315 = new ActionReference();
                                            var idChnl = charIDToTypeID( "Chnl" );
                                            var idfsel = charIDToTypeID( "fsel" );
                                            ref1315.putProperty( idChnl, idfsel );
                                            desc1471.putReference( idFrom, ref1315 );
                                            executeAction( idSbtr, desc1471, DialogModes.NO );
                                        };

                                        if(colour == "green"){
                                            var idSbtr = charIDToTypeID( "Sbtr" );
                                            var desc1189 = new ActionDescriptor();
                                            var idnull = charIDToTypeID( "null" );
                                            var ref878 = new ActionReference();
                                            var idChnl = charIDToTypeID( "Chnl" );
                                            var idChnl = charIDToTypeID( "Chnl" );
                                            var idGrn = charIDToTypeID( "Grn " );
                                            ref878.putEnumerated( idChnl, idChnl, idGrn );
                                            desc1189.putReference( idnull, ref878 );
                                            var idFrom = charIDToTypeID( "From" );
                                            var ref879 = new ActionReference();
                                            var idChnl = charIDToTypeID( "Chnl" );
                                            var idfsel = charIDToTypeID( "fsel" );
                                            ref879.putProperty( idChnl, idfsel );
                                            desc1189.putReference( idFrom, ref879 );
                                            executeAction( idSbtr, desc1189, DialogModes.NO );
                                        };

                                        if(colour == "blue"){
                                            if(groupName == "Alpha Group"){
                                                var idSbtr = charIDToTypeID( "Sbtr" );
                                                var desc348 = new ActionDescriptor();
                                                var idnull = charIDToTypeID( "null" );
                                                var ref296 = new ActionReference();
                                                var idChnl = charIDToTypeID( "Chnl" );
                                                var idChnl = charIDToTypeID( "Chnl" );
                                                var idRGB = charIDToTypeID( "RGB " );
                                                ref296.putEnumerated( idChnl, idChnl, idRGB );
                                                desc348.putReference( idnull, ref296 );
                                                var idFrom = charIDToTypeID( "From" );
                                                var ref297 = new ActionReference();
                                                var idChnl = charIDToTypeID( "Chnl" );
                                                var idfsel = charIDToTypeID( "fsel" );
                                                ref297.putProperty( idChnl, idfsel );
                                                desc348.putReference( idFrom, ref297 );
                                                executeAction( idSbtr, desc348, DialogModes.NO );
                                            }else{
                                                var idSbtr = charIDToTypeID( "Sbtr" );
                                                var desc1190 = new ActionDescriptor();
                                                var idnull = charIDToTypeID( "null" );
                                                var ref880 = new ActionReference();
                                                var idChnl = charIDToTypeID( "Chnl" );
                                                var idChnl = charIDToTypeID( "Chnl" );
                                                var idBl = charIDToTypeID( "Bl  " );
                                                ref880.putEnumerated( idChnl, idChnl, idBl );
                                                desc1190.putReference( idnull, ref880 );
                                                var idFrom = charIDToTypeID( "From" );
                                                var ref881 = new ActionReference();
                                                var idChnl = charIDToTypeID( "Chnl" );
                                                var idfsel = charIDToTypeID( "fsel" );
                                                ref881.putProperty( idChnl, idfsel );
                                                desc1190.putReference( idFrom, ref881 );
                                                executeAction( idSbtr, desc1190, DialogModes.NO );
                                            };
                                        };

                                    // Do the rest if selection is present, otherwise move on in the loop

                                        try{
                                            var sel = app.activeDocument.selection.bounds;
                                        }catch(e){
                                            var sel = "No Selection";
                                        };

                                        if(sel != "No Selection"){
                                            // Select original

                                                app.activeDocument.activeLayer = app.activeDocument.layers.getByName(groupName).layers.getByName(activeLayerNameToString);

                                            // Delete selection

                                                var idDlt = charIDToTypeID( "Dlt " );
                                                executeAction( idDlt, undefined, DialogModes.NO );

                                            // Deselect

                                                deselect();

                                            // if Alpha, make layer contents blue

                                                if(groupName == "Alpha Group"){
                                                    // Add blue layer on top

                                                        app.activeDocument.artLayers.add().name = "Layer to make blue";

                                                        app.activeDocument.layers.getByName("Layer to make blue").move(app.activeDocument.layerSets.getByName(groupName).artLayers.getByName(activeLayerNameToString), ElementPlacement.PLACEBEFORE)

                                                        app.activeDocument.activeLayer = app.activeDocument.layerSets.getByName(groupName).artLayers.getByName("Layer to make blue");

                                                        var idMk = charIDToTypeID( "Mk  " );
                                                        var desc1952 = new ActionDescriptor();
                                                        var idnull = charIDToTypeID( "null" );
                                                        var ref1657 = new ActionReference();
                                                        var idcontentLayer = stringIDToTypeID( "contentLayer" );
                                                        ref1657.putClass( idcontentLayer );
                                                        desc1952.putReference( idnull, ref1657 );
                                                        var idUsng = charIDToTypeID( "Usng" );
                                                        var desc1953 = new ActionDescriptor();
                                                        var idType = charIDToTypeID( "Type" );
                                                        var desc1954 = new ActionDescriptor();
                                                        var idClr = charIDToTypeID( "Clr " );
                                                        var desc1955 = new ActionDescriptor();
                                                        var idRd = charIDToTypeID( "Rd  " );
                                                        desc1955.putDouble( idRd, 0.000000 );
                                                        var idGrn = charIDToTypeID( "Grn " );
                                                        desc1955.putDouble( idGrn, 0.000000 );
                                                        var idBl = charIDToTypeID( "Bl  " );
                                                        desc1955.putDouble( idBl, 255.000000 );
                                                        var idRGBC = charIDToTypeID( "RGBC" );
                                                        desc1954.putObject( idClr, idRGBC, desc1955 );
                                                        var idsolidColorLayer = stringIDToTypeID( "solidColorLayer" );
                                                        desc1953.putObject( idType, idsolidColorLayer, desc1954 );
                                                        var idcontentLayer = stringIDToTypeID( "contentLayer" );
                                                        desc1952.putObject( idUsng, idcontentLayer, desc1953 );
                                                        executeAction( idMk, desc1952, DialogModes.NO );

                                                    // Clip

                                                        clipActiveLayerToLayerBelow();

                                                    // Merge down

                                                        mergeActiveLayerDown();
                                                };

                                            // Split group type out of name, and replace "_" and "copy"

                                                // Variables etc

                                                    var myRegExp = new RegExp(/multimatte_/gim);

                                                try{
                                                    if(myRegExp.test(app.activeDocument.activeLayer.name)){
                                                        var res = app.activeDocument.activeLayer.name.split(lastWordInGroupTypeMinusFirstLetter + "_");

                                                        app.activeDocument.activeLayer.name = res[1]
                                                    }else{
                                                        if(groupName == "Alpha Group"){
                                                            var res = app.activeDocument.activeLayer.name;
                                                            var res2 = res.slice(1, -5)

                                                            app.activeDocument.activeLayer.name = res2
                                                        };

                                                        var res = app.activeDocument.activeLayer.name.split(lastWordInGroupTypeMinusFirstLetter)[1];
                                                        var res2 = res.slice(0, -5)

                                                        app.activeDocument.activeLayer.name = res2
                                                    };
                                                }catch(e){};

                                                app.activeDocument.activeLayer.name = app.activeDocument.activeLayer.name.replace(/_/g, " ").replace(/ copy/gim, " Duplicate").replace(/inverse/gim, "Inverted");
                                        }else{
                                            app.activeDocument.layers.getByName(groupName).layers.getByName(activeLayerNameToString).remove();
                                        };

                                    // Remove active red selection dummy layer

                                        app.activeDocument.artLayers.getByName("Rasterize Dummy").remove();

                                // Do for selected layers setup 2

                                    }
                                    OpenOptionsDialog.close()
                                    }

                                    runTheScript();

                                    var result = OpenOptionsDialog.hide();
                                    }

                                    function getSelectedLayers(){
                                        var resultLayers = new Array();

                                        try{
                                            var descGrp = new ActionDescriptor();
                                            var refGrp = new ActionReference();
                                            refGrp.putEnumerated(cID( "Lyr " ),cID( "Ordn" ),cID( "Trgt" ));
                                            descGrp.putReference(cID( "null" ), refGrp );
                                            executeAction( sID( "groupLayersEvent" ), descGrp, DialogModes.NO );
                                            for (var ix=0;ix<app.activeDocument.activeLayer.layers.length;ix++){resultLayers.push(app.activeDocument.activeLayer.layers[ix])}
                                            var desc5 = new ActionDescriptor();
                                            var ref2 = new ActionReference();
                                            ref2.putEnumerated( cID( "HstS" ), cID( "Ordn" ), cID( "Prvs" ) );
                                            desc5.putReference( cID( "null" ), ref2 );
                                            executeAction( cID( "slct" ), desc5, DialogModes.NO );
                                        }catch(e){};
                                        return resultLayers;
                                    };

                            // Delete the group if empty, otherwise do the rest

                                if(app.activeDocument.layers.getByName(groupName).layers.length == 0){
                                    app.activeDocument.layers.getByName(groupName).remove();
                                }else{
                                    // Select and remove empty layers

                                        // Select all layers in group

                                            selectAllLayersInSpecifiedLayerSet(app.activeDocument.layers.getByName(groupName));

                                        // Remove empty layers from selection

                                            function cID (inVal){ return charIDToTypeID(inVal);}
                                            function sID (inVal){ return stringIDToTypeID(inVal);}

                                            main2();

                                            function main2(){
                                                optionsDialog2();
                                            };

                                            function optionsDialog2(){
                                                OpenOptionsDialog = new Window("dialog");

                                                main2Group = OpenOptionsDialog.add("group");

                                                function runTheScript2(){
                                                    var SelectedLayers = getSelectedLayers2();

                                                    for (var i = 0; i < SelectedLayers.length; i++){
                                                        activeDocument.activeLayer = SelectedLayers[i];

                                                        if((0 == app.activeDocument.activeLayer.bounds[2]) && (0 == app.activeDocument.activeLayer.bounds[3])){
                                                            app.activeDocument.activeLayer.remove();
                                                        };
                                                    };

                                                    OpenOptionsDialog.close()
                                                };

                                                runTheScript2();

                                                var result = OpenOptionsDialog.hide();
                                            };

                                            function getSelectedLayers2(){
                                                var resultLayers=new Array();

                                                try{
                                                    var descGrp = new ActionDescriptor();
                                                    var refGrp = new ActionReference();

                                                    refGrp.putEnumerated(cID( "Lyr " ),cID( "Ordn" ),cID( "Trgt" ));
                                                    descGrp.putReference(cID( "null" ), refGrp );
                                                    executeAction( sID( "groupLayersEvent" ), descGrp, DialogModes.NO );

                                                    for (var ix=0;ix<app.activeDocument.activeLayer.layers.length;ix++){
                                                        resultLayers.push(app.activeDocument.activeLayer.layers[ix])
                                                    };

                                                    var desc5 = new ActionDescriptor();
                                                    var ref2 = new ActionReference();

                                                    ref2.putEnumerated( cID( "HstS" ), cID( "Ordn" ), cID( "Prvs" ) );
                                                    desc5.putReference( cID( "null" ), ref2 );
                                                    executeAction( cID( "slct" ), desc5, DialogModes.NO );
                                                }catch(e){};

                                                return resultLayers;
                                            };

                                    // Deselect

                                        deselect();

                                    // Select relevant layerset and make opacity 0%

                                        app.activeDocument.activeLayer = app.activeDocument.layerSets.getByName(groupName);

                                        makeActiveLayersOpacityZero();
                                };
                    };

                // Move layers containing string "glass" to bottom of Multimatte group

                    function moveGlassLayersToBottomOfGroup(){
                        // Variables etc
                            var glass = new RegExp(/glass/gim);
                            var glazing = new RegExp(/glaz/gim);

                        // Do for all layers in specified group
                            // Setup 1 (fast)
                                var activeLayerByName = app.activeDocument.layerSets.getByName("Multimatte");
                                var myLength = activeLayerByName.layers.length;
                                for (var i = 0; i < myLength; i++){
                                app.activeDocument.activeLayer = activeLayerByName.layers[i]

                            // Thing to do
                                if(glass.test(app.activeDocument.activeLayer.name) || glazing.test(app.activeDocument.activeLayer.name)){
                                    app.activeDocument.activeLayer.move(app.activeDocument.layers.Multimatte.layers[app.activeDocument.layers.Multimatte.artLayers.length - 1], ElementPlacement.PLACEAFTER);
                                };

                            // Setup 2


                                };
                    };

    // Shift to 16b Mode

        function shiftTo16bMode(){
            // Check if document filetype is .psb

                var stringPsb = new RegExp(/psb/gim);

                if(!stringPsb.test(app.activeDocument.name)){
                    alert("Please save the document with the extension '.psb' and try again");
                }else{
                    // Save
                        try{
                            saveFileOnlyIfChangesWereMade(app.activeDocument);
                        }catch(e){
                            alert("Document has not been saved yet");
                            return;
                        };

                    // Try to open relevant 16b file, to determine if it exists

                        try{
                            var fileRef = new File(app.activeDocument.path.fsName + "/" + app.activeDocument.name.split(".psb")[0] + " 16b.psb");
                            app.open(fileRef);

                            // Zoom out

                                setZoom();
                        }catch(e){};

                    // If the file didn't exist, create it, otherwise close the original file

                        // Variables etc

                            var tempName = app.activeDocument.name;
                            var word16b = new RegExp (/16b/gim);

                        if(!word16b.test(tempName)){
                            // Zoom out

                                setZoom();

                            // Group all layers

                                // Select all layers

                                    selectAllLayers();

                                // Group all layers

                                    groupActiveLayers();

                                // Name group

                                    app.activeDocument.layers[0].name = "All Layers From 32b File";

                            // Create new background layer

                                app.activeDocument.artLayers.add().name = "Background";

                            // Move new background layer to bottom

                                moveActiveLayerToBottom();

                            // Move forward a layer

                                moveForwardALayer();

                            // Save as, in same location with " 16b" appended to name

                                var Path = app.activeDocument.path;
                                var Name = app.activeDocument.name.split(".psb")[0];
                                var pathPlusName = File(Path + "/" + Name + " 16b" + ".psb");

                                SavePSB(pathPlusName);

                            // Try placing a .psb first

                                // Place linked file from same location whose name is app.activeDocument.name.split(" 16b")

                                    // Variables etc

                                        var rootPath = decodeURI (app.activeDocument.path.fsName); // ActiveDocument.path;
                                        var targetLayers = new Array;
                                        var subDirectory = "/LinkedLayers/";
                                        targetLayers = app.activeDocument.layers;
                                        var configFolder = Folder(rootPath);
                                        var fileList = configFolder.getFiles();

                                        for (var i = fileList.length -1; i >= 0  ; i--){
                                            var tempPreliminary1 = fileList[i].toString();
                                            var tempPreliminary = tempPreliminary1.replace(/\\/g, "/")
                                            var temp = tempPreliminary.split("/")[tempPreliminary.split("/").length - 1]
                                            var reguEx = new RegExp(/.psb/gim);
                                            var reguEx2 = new RegExp(/.exr/gim);
                                            var reguEx3 = new RegExp(/16b/gim);

                                            if(reguEx.test(temp) && !reguEx2.test(temp) && !reguEx3.test(temp)){
                                                var idPlc = charIDToTypeID( "Plc " );
                                                var desc13 = new ActionDescriptor();
                                                var idIdnt = charIDToTypeID( "Idnt" );
                                                desc13.putInteger( idIdnt, 130 );
                                                var idnull = charIDToTypeID( "null" );
                                                desc13.putPath( idnull, new File( fileList[i] ) );
                                                var idLnkd = charIDToTypeID( "Lnkd" );
                                                desc13.putBoolean( idLnkd, true );
                                                var idOpAs = charIDToTypeID( "OpAs" );
                                                var desc14 = new ActionDescriptor();
                                                var idAChn = charIDToTypeID( "AChn" );
                                                desc14.putInteger( idAChn, 0 );
                                                var idEXRf = charIDToTypeID( "EXRf" );
                                                desc13.putObject( idOpAs, idEXRf, desc14 );
                                                var idFTcs = charIDToTypeID( "FTcs" );
                                                var idQCSt = charIDToTypeID( "QCSt" );
                                                var idQcsa = charIDToTypeID( "Qcsa" );
                                                desc13.putEnumerated( idFTcs, idQCSt, idQcsa );
                                                var idOfst = charIDToTypeID( "Ofst" );
                                                var desc15 = new ActionDescriptor();
                                                var idHrzn = charIDToTypeID( "Hrzn" );
                                                var idPxl = charIDToTypeID( "#Pxl" );
                                                desc15.putUnitDouble( idHrzn, idPxl, 0.000000 );
                                                var idVrtc = charIDToTypeID( "Vrtc" );
                                                var idPxl = charIDToTypeID( "#Pxl" );
                                                desc15.putUnitDouble( idVrtc, idPxl, 0.000000 );
                                                var idOfst = charIDToTypeID( "Ofst" );
                                                desc13.putObject( idOfst, idOfst, desc15 );
                                                executeAction( idPlc, desc13, DialogModes.NO );
                                            };
                                        };

                                // Delete unneeded layers

                                    // Variables etc

                                        var rootPath = decodeURI (app.activeDocument.path.fsName); // ActiveDocument.path;
                                        var targetLayers = new Array;
                                        var subDirectory = "/LinkedLayers/";
                                        targetLayers = app.activeDocument.layers;
                                        var me = app.activeDocument.name.split(" 16b")[0]
                                        app.activeDocument.activeLayer = app.activeDocument.layers.getByName(me)

                                        for (var i = app.activeDocument.layers.length -1; i >= 0  ; i--){
                                            app.activeDocument.activeLayer = app.activeDocument.layers[i]

                                            if(app.activeDocument.layers[i].name != app.activeDocument.layers.getByName(me).name && app.activeDocument.layers[i].name != "All Layers From 32b File" && app.activeDocument.layers[i].name != "Background"){
                                                app.activeDocument.layers[i].remove();
                                            };
                                        };

                            // Convert canvas mode to 16b

                                var idCnvM = charIDToTypeID( "CnvM" );
                                var desc9 = new ActionDescriptor();
                                var idDpth = charIDToTypeID( "Dpth" );
                                desc9.putInteger( idDpth, 16 );
                                var idMrge = charIDToTypeID( "Mrge" );
                                desc9.putBoolean( idMrge, false );
                                executeAction( idCnvM, desc9, DialogModes.NO );

                            // Rename active layer

                                app.activeDocument.activeLayer.name = "Original Image";

                            // Duplicate active layer

                                app.activeDocument.activeLayer.duplicate();

                            // Move forward a layer

                                moveForwardALayer();

                            // Change name to " Contrast Overlay"

                                app.activeDocument.activeLayer.name = "Contrast Overlay";

                            // Change duplicated layer mode to overlay

                                setActiveLayerBlendingModeToOverlay();

                            // Change fill to 15%

                                var idsetd = charIDToTypeID( "setd" );
                                var desc17 = new ActionDescriptor();
                                var idnull = charIDToTypeID( "null" );
                                var ref14 = new ActionReference();
                                var idLyr = charIDToTypeID( "Lyr " );
                                var idOrdn = charIDToTypeID( "Ordn" );
                                var idTrgt = charIDToTypeID( "Trgt" );
                                ref14.putEnumerated( idLyr, idOrdn, idTrgt );
                                desc17.putReference( idnull, ref14 );
                                var idT = charIDToTypeID( "T   " );
                                var desc18 = new ActionDescriptor();
                                var idfillOpacity = stringIDToTypeID( "fillOpacity" );
                                var idPrc = charIDToTypeID( "#Prc" );
                                desc18.putUnitDouble( idfillOpacity, idPrc, 15.000000 );
                                var idLyr = charIDToTypeID( "Lyr " );
                                desc17.putObject( idT, idLyr, desc18 );
                                executeAction( idsetd, desc17, DialogModes.NO );

                            // Move back a layer

                                moveBackALayer();

                            // Duplicate active layer
                                app.activeDocument.activeLayer.duplicate();

                            // Move forward a layer

                                moveForwardALayer();

                            // Change name to "High Pass"
                                app.activeDocument.activeLayer.name = "High Pass";

                            // Change fill to 15%
                                var idsetd = charIDToTypeID( "setd" );
                                var desc17 = new ActionDescriptor();
                                var idnull = charIDToTypeID( "null" );
                                var ref14 = new ActionReference();
                                var idLyr = charIDToTypeID( "Lyr " );
                                var idOrdn = charIDToTypeID( "Ordn" );
                                var idTrgt = charIDToTypeID( "Trgt" );
                                ref14.putEnumerated( idLyr, idOrdn, idTrgt );
                                desc17.putReference( idnull, ref14 );
                                var idT = charIDToTypeID( "T   " );
                                var desc18 = new ActionDescriptor();
                                var idfillOpacity = stringIDToTypeID( "fillOpacity" );
                                var idPrc = charIDToTypeID( "#Prc" );
                                desc18.putUnitDouble( idfillOpacity, idPrc, 15.000000 );
                                var idLyr = charIDToTypeID( "Lyr " );
                                desc17.putObject( idT, idLyr, desc18 );
                                executeAction( idsetd, desc17, DialogModes.NO );

                            // Change duplicated layer mode to overlay

                                setActiveLayerBlendingModeToOverlay();

                            // High pass filter 1 pixel
                                var idHghP = charIDToTypeID( "HghP" );
                                var desc19 = new ActionDescriptor();
                                var idRds = charIDToTypeID( "Rds " );
                                var idPxl = charIDToTypeID( "#Pxl" );
                                desc19.putUnitDouble( idRds, idPxl, 1.000000 );
                                executeAction( idHghP, desc19, DialogModes.NO );

                            // Create Original Image Group

                                app.activeDocument.layerSets.add().name = "Original Image Group";

                            // Move duplicated layers to Original Image Group

                                app.activeDocument.artLayers.getByName("Original Image").move(app.activeDocument.layerSets.getByName("Original Image Group"), ElementPlacement.INSIDE);
                                app.activeDocument.artLayers.getByName("Contrast Overlay").move(app.activeDocument.layerSets.getByName("Original Image Group"), ElementPlacement.INSIDE);
                                app.activeDocument.artLayers.getByName("High Pass").move(app.activeDocument.layerSets.getByName("Original Image Group"), ElementPlacement.INSIDE);

                            // Create Overall Adjustments Group

                                app.activeDocument.layerSets.add().name = "Overall Adjustments Group";

                            // Extract selection groups
                                try{
                                    app.activeDocument.activeLayer = app.activeDocument.layers.getByName("All Layers From 32b File").layers.getByName("Border Group");
                                    moveActiveLayerToTop ();
                                    moveActiveLayerToTop ();
                                    moveActiveLayerToTop ();
                                }catch(e){};

                                try{
                                    app.activeDocument.activeLayer = app.activeDocument.layers.getByName("All Layers From 32b File").layers.getByName("Alpha Group");
                                    moveActiveLayerToTop ();
                                    moveActiveLayerToTop ();
                                    moveActiveLayerToTop ();
                                }catch(e){};

                                try{
                                    app.activeDocument.activeLayer = app.activeDocument.layers.getByName("All Layers From 32b File").layers.getByName("World Normals Group");
                                    moveActiveLayerToTop ();
                                    moveActiveLayerToTop ();
                                    moveActiveLayerToTop ();
                                }catch(e){};

                                try{
                                    app.activeDocument.activeLayer = app.activeDocument.layers.getByName("All Layers From 32b File").layers.getByName("Multimatte");
                                    moveActiveLayerToTop ();
                                    moveActiveLayerToTop ();
                                    moveActiveLayerToTop ();
                                }catch(e){};

                            // Remove unneeded layers
                                app.activeDocument.layers.getByName("All Layers From 32b File").remove();
                                app.activeDocument.layers.Background.remove();

                            // Make contents of border group opaque

                                makeContentsOfBorderGroupOpaque();

                            // Select multimatte group

                                app.activeDocument.activeLayer = app.activeDocument.layers.getByName("Multimatte");
                        }else{
                            // Close original file

                                try{
                                    app.documents.getByName(app.activeDocument.name.split(" 16b.psb")[0] + ".psb").close(SaveOptions.DONOTSAVECHANGES);
                                }catch(e){};

                            // Ensure all modified content is updated

                                var idplacedLayerUpdateAllModified = stringIDToTypeID( "placedLayerUpdateAllModified" );
                                executeAction( idplacedLayerUpdateAllModified, undefined, DialogModes.NO );
                        };

                    // Collapse all groups

                        collapseAllGroups();
                };
        };

    // Layer visibility maintenance

        // Visibility Loop

            // Main function

                function visibilityLoop(){
                    // Clear layersToHide

                        layersToHide.length = 0;

                    for(var a = 0; a < app.activeDocument.layers.length; a++){
                        var relevantLayer = app.activeDocument.layers[a];

                        if(relevantLayer.visible == false){
                            try{
                                relevantLayer.visible = true;

                                var relevantLayerNameToString = relevantLayer.name.toString();

                                getLayerChain(relevantLayer);

                                layersToHide.push(relevantLayer.name);

                                relevantLayer.name = relevantLayerNameToString;
                            }catch(e){};
                        };
                    };

                    for(var a = 0; a < app.activeDocument.layerSets.length; a++){
                        var relevantLayer1 = app.activeDocument.layerSets[a];

                        if(relevantLayer1.layers.length > 0){
                            for(var b = 0; b < relevantLayer1.layers.length; b++){
                                var relevantLayer = relevantLayer1.layers[b];

                                if(relevantLayer.visible == false){
                                    try{
                                        relevantLayer.visible = true;

                                        var relevantLayerNameToString = relevantLayer.name.toString();

                                        getLayerChain(relevantLayer);

                                        layersToHide.push(relevantLayer.name);

                                        relevantLayer.name = relevantLayerNameToString;
                                    }catch(e){};
                                };
                            };
                        };
                    };

                    for(var a = 0; a < app.activeDocument.layerSets.length; a++){
                        var relevantLayer1 = app.activeDocument.layerSets[a];

                        if(relevantLayer1.layerSets.length > 0){
                            for(var b = 0; b < relevantLayer1.layerSets.length; b++){
                                var relevantLayer2 = relevantLayer1.layerSets[b];

                                if(relevantLayer2.layers.length > 0){
                                    for(var c = 0; c < relevantLayer2.layers.length; c++){
                                        var relevantLayer = relevantLayer2.layers[c];

                                        if(relevantLayer.visible == false){
                                            try{
                                                relevantLayer.visible = true;

                                                var relevantLayerNameToString = relevantLayer.name.toString();

                                                getLayerChain(relevantLayer);

                                                layersToHide.push(relevantLayer.name);

                                                relevantLayer.name = relevantLayerNameToString;
                                            }catch(e){};
                                        };
                                    };
                                };
                            };
                        };
                    };

                    for(var a = 0; a < app.activeDocument.layerSets.length; a++){
                        var relevantLayer1 = app.activeDocument.layerSets[a];

                        if(relevantLayer1.layerSets.length > 0){
                            for(var b = 0; b < relevantLayer1.layerSets.length; b++){
                                var relevantLayer2 = relevantLayer1.layerSets[b];

                                if(relevantLayer2.layerSets.length > 0){
                                    for(var c = 0; c < relevantLayer2.layerSets.length; c++){
                                        var relevantLayer3 = relevantLayer2.layerSets[c];

                                        if(relevantLayer3.layers.length > 0){
                                            for(var d = 0; d < relevantLayer3.layers.length; d++){
                                                var relevantLayer = relevantLayer3.layers[d];

                                                if(relevantLayer.visible == false){
                                                    try{
                                                        relevantLayer.visible = true;

                                                        var relevantLayerNameToString = relevantLayer.name.toString();

                                                        getLayerChain(relevantLayer);

                                                        layersToHide.push(relevantLayer.name);

                                                        relevantLayer.name = relevantLayerNameToString;
                                                    }catch(e){};
                                                };
                                            };
                                        };
                                    };
                                };
                            };
                        };
                    };

                    for(var a = 0; a < app.activeDocument.layerSets.length; a++){
                        var relevantLayer1 = app.activeDocument.layerSets[a];

                        if(relevantLayer1.layerSets.length > 0){
                            for(var b = 0; b < relevantLayer1.layerSets.length; b++){
                                var relevantLayer2 = relevantLayer1.layerSets[b];

                                if(relevantLayer2.layerSets.length > 0){
                                    for(var c = 0; c < relevantLayer2.layerSets.length; c++){
                                        var relevantLayer3 = relevantLayer2.layerSets[c];

                                        if(relevantLayer3.layerSets.length > 0){
                                            for(var d = 0; d < relevantLayer3.layerSets.length; d++){
                                                var relevantLayer4 = relevantLayer3.layerSets[d];

                                                if(relevantLayer4.layers.length > 0){
                                                    for(var e = 0; e < relevantLayer4.layers.length; e++){
                                                        var relevantLayer = relevantLayer4.layers[e];

                                                        if(relevantLayer.visible == false){
                                                            try{
                                                                relevantLayer.visible = true;

                                                                var relevantLayerNameToString = relevantLayer.name.toString();

                                                                getLayerChain(relevantLayer);

                                                                layersToHide.push(relevantLayer.name);

                                                                relevantLayer.name = relevantLayerNameToString;
                                                            }catch(e){};
                                                        };
                                                    };
                                                };
                                            };
                                        };
                                    };
                                };
                            };
                        };
                    };

                    for(var a = 0; a < app.activeDocument.layerSets.length; a++){
                        var relevantLayer1 = app.activeDocument.layerSets[a];

                        if(relevantLayer1.layerSets.length > 0){
                            for(var b = 0; b < relevantLayer1.layerSets.length; b++){
                                var relevantLayer2 = relevantLayer1.layerSets[b];

                                if(relevantLayer2.layerSets.length > 0){
                                    for(var c = 0; c < relevantLayer2.layerSets.length; c++){
                                        var relevantLayer3 = relevantLayer2.layerSets[c];

                                        if(relevantLayer3.layerSets.length > 0){
                                            for(var d = 0; d < relevantLayer3.layerSets.length; d++){
                                                var relevantLayer4 = relevantLayer3.layerSets[d];

                                                if(relevantLayer4.layerSets.length > 0){
                                                    for(var e = 0; e < relevantLayer4.layerSets.length; e++){
                                                        var relevantLayer5 = relevantLayer4.layerSets[e];

                                                        if(relevantLayer5.layers.length > 0){
                                                            for(var f = 0; f < relevantLayer5.layers.length; f++){
                                                                var relevantLayer = relevantLayer5.layers[f];

                                                                if(relevantLayer.visible == false){
                                                                    try{
                                                                        relevantLayer.visible = true;

                                                                        var relevantLayerNameToString = relevantLayer.name.toString();

                                                                        getLayerChain(relevantLayer);

                                                                        layersToHide.push(relevantLayer.name);

                                                                        relevantLayer.name = relevantLayerNameToString;
                                                                    }catch(e){};
                                                                };
                                                            };
                                                        };
                                                    };
                                                };
                                            };
                                        };
                                    };
                                };
                            };
                        };
                    };

                    for(var a = 0; a < app.activeDocument.layerSets.length; a++){
                        var relevantLayer1 = app.activeDocument.layerSets[a];

                        if(relevantLayer1.layerSets.length > 0){
                            for(var b = 0; b < relevantLayer1.layerSets.length; b++){
                                var relevantLayer2 = relevantLayer1.layerSets[b];

                                if(relevantLayer2.layerSets.length > 0){
                                    for(var c = 0; c < relevantLayer2.layerSets.length; c++){
                                        var relevantLayer3 = relevantLayer2.layerSets[c];

                                        if(relevantLayer3.layerSets.length > 0){
                                            for(var d = 0; d < relevantLayer3.layerSets.length; d++){
                                                var relevantLayer4 = relevantLayer3.layerSets[d];

                                                if(relevantLayer4.layerSets.length > 0){
                                                    for(var e = 0; e < relevantLayer4.layerSets.length; e++){
                                                        var relevantLayer5 = relevantLayer4.layerSets[e];

                                                        if(relevantLayer5.layerSets.length > 0){
                                                            for(var f = 0; f < relevantLayer5.layerSets.length; f++){
                                                                var relevantLayer6 = relevantLayer5.layerSets[f];

                                                                if(relevantLayer6.layers.length > 0){
                                                                    for(var g = 0; g < relevantLayer6.layers.length; g++){
                                                                        var relevantLayer = relevantLayer6.layers[g];

                                                                        if(relevantLayer.visible == false){
                                                                            try{
                                                                                relevantLayer.visible = true;

                                                                                var relevantLayerNameToString = relevantLayer.name.toString();

                                                                                getLayerChain(relevantLayer);

                                                                                layersToHide.push(relevantLayer.name);

                                                                                relevantLayer.name = relevantLayerNameToString;
                                                                            }catch(e){};
                                                                        };
                                                                    };
                                                                };
                                                            };
                                                        };
                                                    };
                                                };
                                            };
                                        };
                                    };
                                };
                            };
                        };
                    };

                    for(var a = 0; a < app.activeDocument.layerSets.length; a++){
                        var relevantLayer1 = app.activeDocument.layerSets[a];

                        if(relevantLayer1.layerSets.length > 0){
                            for(var b = 0; b < relevantLayer1.layerSets.length; b++){
                                var relevantLayer2 = relevantLayer1.layerSets[b];

                                if(relevantLayer2.layerSets.length > 0){
                                    for(var c = 0; c < relevantLayer2.layerSets.length; c++){
                                        var relevantLayer3 = relevantLayer2.layerSets[c];

                                        if(relevantLayer3.layerSets.length > 0){
                                            for(var d = 0; d < relevantLayer3.layerSets.length; d++){
                                                var relevantLayer4 = relevantLayer3.layerSets[d];

                                                if(relevantLayer4.layerSets.length > 0){
                                                    for(var e = 0; e < relevantLayer4.layerSets.length; e++){
                                                        var relevantLayer5 = relevantLayer4.layerSets[e];

                                                        if(relevantLayer5.layerSets.length > 0){
                                                            for(var f = 0; f < relevantLayer5.layerSets.length; f++){
                                                                var relevantLayer6 = relevantLayer5.layerSets[f];

                                                                if(relevantLayer6.layerSets.length > 0){
                                                                    for(var g = 0; g < relevantLayer6.layerSets.length; g++){
                                                                        var relevantLayer7 = relevantLayer6.layerSets[g];

                                                                        if(relevantLayer7.layers.length > 0){
                                                                            for(var h = 0; h < relevantLayer7.layers.length; h++){
                                                                                var relevantLayer = relevantLayer7.layers[h];

                                                                                if(relevantLayer.visible == false){
                                                                                    try{
                                                                                        relevantLayer.visible = true;

                                                                                        var relevantLayerNameToString = relevantLayer.name.toString();

                                                                                        getLayerChain(relevantLayer);

                                                                                        layersToHide.push(relevantLayer.name);

                                                                                        relevantLayer.name = relevantLayerNameToString;
                                                                                    }catch(e){};
                                                                                };
                                                                            };
                                                                        };
                                                                    };
                                                                };
                                                            };
                                                        };
                                                    };
                                                };
                                            };
                                        };
                                    };
                                };
                            };
                        };
                    };

                    for(var a = 0; a < app.activeDocument.layerSets.length; a++){
                        var relevantLayer1 = app.activeDocument.layerSets[a];

                        if(relevantLayer1.layerSets.length > 0){
                            for(var b = 0; b < relevantLayer1.layerSets.length; b++){
                                var relevantLayer2 = relevantLayer1.layerSets[b];

                                if(relevantLayer2.layerSets.length > 0){
                                    for(var c = 0; c < relevantLayer2.layerSets.length; c++){
                                        var relevantLayer3 = relevantLayer2.layerSets[c];

                                        if(relevantLayer3.layerSets.length > 0){
                                            for(var d = 0; d < relevantLayer3.layerSets.length; d++){
                                                var relevantLayer4 = relevantLayer3.layerSets[d];

                                                if(relevantLayer4.layerSets.length > 0){
                                                    for(var e = 0; e < relevantLayer4.layerSets.length; e++){
                                                        var relevantLayer5 = relevantLayer4.layerSets[e];

                                                        if(relevantLayer5.layerSets.length > 0){
                                                            for(var f = 0; f < relevantLayer5.layerSets.length; f++){
                                                                var relevantLayer6 = relevantLayer5.layerSets[f];

                                                                if(relevantLayer6.layerSets.length > 0){
                                                                    for(var g = 0; g < relevantLayer6.layerSets.length; g++){
                                                                        var relevantLayer7 = relevantLayer6.layerSets[g];

                                                                        if(relevantLayer7.layerSets.length > 0){
                                                                            for(var h = 0; h < relevantLayer7.layerSets.length; h++){
                                                                                var relevantLayer8 = relevantLayer7.layerSets[h];

                                                                                if(relevantLayer8.layers.length > 0){
                                                                                    for(var i = 0; i < relevantLayer8.layers.length; i++){
                                                                                        var relevantLayer = relevantLayer8.layers[i];

                                                                                        if(relevantLayer.visible == false){
                                                                                            try{
                                                                                                relevantLayer.visible = true;

                                                                                                var relevantLayerNameToString = relevantLayer.name.toString();

                                                                                                getLayerChain(relevantLayer);

                                                                                                layersToHide.push(relevantLayer.name);

                                                                                                relevantLayer.name = relevantLayerNameToString;
                                                                                            }catch(e){};
                                                                                        };
                                                                                    };
                                                                                };
                                                                            };
                                                                        };
                                                                    };
                                                                };
                                                            };
                                                        };
                                                    };
                                                };
                                            };
                                        };
                                    };
                                };
                            };
                        };
                    };

                    for(var a = 0; a < app.activeDocument.layerSets.length; a++){
                        var relevantLayer1 = app.activeDocument.layerSets[a];

                        if(relevantLayer1.layerSets.length > 0){
                            for(var b = 0; b < relevantLayer1.layerSets.length; b++){
                                var relevantLayer2 = relevantLayer1.layerSets[b];

                                if(relevantLayer2.layerSets.length > 0){
                                    for(var c = 0; c < relevantLayer2.layerSets.length; c++){
                                        var relevantLayer3 = relevantLayer2.layerSets[c];

                                        if(relevantLayer3.layerSets.length > 0){
                                            for(var d = 0; d < relevantLayer3.layerSets.length; d++){
                                                var relevantLayer4 = relevantLayer3.layerSets[d];

                                                if(relevantLayer4.layerSets.length > 0){
                                                    for(var e = 0; e < relevantLayer4.layerSets.length; e++){
                                                        var relevantLayer5 = relevantLayer4.layerSets[e];

                                                        if(relevantLayer5.layerSets.length > 0){
                                                            for(var f = 0; f < relevantLayer5.layerSets.length; f++){
                                                                var relevantLayer6 = relevantLayer5.layerSets[f];

                                                                if(relevantLayer6.layerSets.length > 0){
                                                                    for(var g = 0; g < relevantLayer6.layerSets.length; g++){
                                                                        var relevantLayer7 = relevantLayer6.layerSets[g];

                                                                        if(relevantLayer7.layerSets.length > 0){
                                                                            for(var h = 0; h < relevantLayer7.layerSets.length; h++){
                                                                                var relevantLayer8 = relevantLayer7.layerSets[h];

                                                                                if(relevantLayer8.layerSets.length > 0){
                                                                                    for(var i = 0; i < relevantLayer8.layerSets.length; i++){
                                                                                        var relevantLayer9 = relevantLayer8.layerSets[i];

                                                                                        if(relevantLayer9.layers.length > 0){
                                                                                            for(var j = 0; j < relevantLayer9.layers.length; j++){
                                                                                                var relevantLayer = relevantLayer9.layers[j];

                                                                                                if(relevantLayer.visible == false){
                                                                                                    try{
                                                                                                        relevantLayer.visible = true;

                                                                                                        var relevantLayerNameToString = relevantLayer.name.toString();

                                                                                                        getLayerChain(relevantLayer);

                                                                                                        layersToHide.push(relevantLayer.name);

                                                                                                        relevantLayer.name = relevantLayerNameToString;
                                                                                                    }catch(e){};
                                                                                                };
                                                                                            };
                                                                                        };
                                                                                    };
                                                                                };
                                                                            };
                                                                        };
                                                                    };
                                                                };
                                                            };
                                                        };
                                                    };
                                                };
                                            };
                                        };
                                    };
                                };
                            };
                        };
                    };

                    for(var a = 0; a < app.activeDocument.layerSets.length; a++){
                        var relevantLayer1 = app.activeDocument.layerSets[a];

                        if(relevantLayer1.layerSets.length > 0){
                            for(var b = 0; b < relevantLayer1.layerSets.length; b++){
                                var relevantLayer2 = relevantLayer1.layerSets[b];

                                if(relevantLayer2.layerSets.length > 0){
                                    for(var c = 0; c < relevantLayer2.layerSets.length; c++){
                                        var relevantLayer3 = relevantLayer2.layerSets[c];

                                        if(relevantLayer3.layerSets.length > 0){
                                            for(var d = 0; d < relevantLayer3.layerSets.length; d++){
                                                var relevantLayer4 = relevantLayer3.layerSets[d];

                                                if(relevantLayer4.layerSets.length > 0){
                                                    for(var e = 0; e < relevantLayer4.layerSets.length; e++){
                                                        var relevantLayer5 = relevantLayer4.layerSets[e];

                                                        if(relevantLayer5.layerSets.length > 0){
                                                            for(var f = 0; f < relevantLayer5.layerSets.length; f++){
                                                                var relevantLayer6 = relevantLayer5.layerSets[f];

                                                                if(relevantLayer6.layerSets.length > 0){
                                                                    for(var g = 0; g < relevantLayer6.layerSets.length; g++){
                                                                        var relevantLayer7 = relevantLayer6.layerSets[g];

                                                                        if(relevantLayer7.layerSets.length > 0){
                                                                            for(var h = 0; h < relevantLayer7.layerSets.length; h++){
                                                                                var relevantLayer8 = relevantLayer7.layerSets[h];

                                                                                if(relevantLayer8.layerSets.length > 0){
                                                                                    for(var i = 0; i < relevantLayer8.layerSets.length; i++){
                                                                                        var relevantLayer9 = relevantLayer8.layerSets[i];

                                                                                        if(relevantLayer9.layerSets.length > 0){
                                                                                            for(var j = 0; j < relevantLayer9.layerSets.length; j++){
                                                                                                var relevantLayer10 = relevantLayer9.layerSets[j];

                                                                                                if(relevantLayer10.layers.length > 0){
                                                                                                    for(var k = 0; k < relevantLayer10.layers.length; k++){
                                                                                                        var relevantLayer = relevantLayer10.layers[k];

                                                                                                        if(relevantLayer.visible == false){
                                                                                                            try{
                                                                                                                relevantLayer.visible = true;

                                                                                                                var relevantLayerNameToString = relevantLayer.name.toString();

                                                                                                                getLayerChain(relevantLayer);

                                                                                                                layersToHide.push(relevantLayer.name);

                                                                                                                relevantLayer.name = relevantLayerNameToString;
                                                                                                            }catch(e){};
                                                                                                        };
                                                                                                    };
                                                                                                };
                                                                                            };
                                                                                        };
                                                                                    };
                                                                                };
                                                                            };
                                                                        };
                                                                    };
                                                                };
                                                            };
                                                        };
                                                    };
                                                };
                                            };
                                        };
                                    };
                                };
                            };
                        };
                    };

                    deselect();
                };

            // Subfunctions

                // Get names

                    function getLayerChain(relevantLayer){
                        // Put names to arrays

                            // arrayOne = new array()

                            var namePSB = new RegExp(/.psb/gim)
                            var namePhotoshop = new RegExp("Adobe Photoshop")

                            try{
                                var a = relevantLayer.name.toString()
                            }catch(e){};

                            try{
                                var b = relevantLayer.parent.name.toString()

                                if(namePSB.test(b) || namePhotoshop.test(b)){
                                    var b = "emptyString"
                                };
                            }catch(e){
                                var b = "emptyString"
                            };

                            try{
                                var c = relevantLayer.parent.parent.name.toString()

                                if(namePSB.test(c) || namePhotoshop.test(c)){
                                    var c = "emptyString"
                                };
                            }catch(e){
                                var c = "emptyString"
                            };

                            try{
                                var d = relevantLayer.parent.parent.parent.name.toString()

                                if(namePSB.test(d) || namePhotoshop.test(d)){
                                    var d = "emptyString"
                                };
                            }catch(e){
                                var d = "emptyString"
                            };

                            try{
                                var ee = relevantLayer.parent.parent.parent.parent.name.toString()

                                if(namePSB.test(ee) || namePhotoshop.test(ee)){
                                    var ee = "emptyString"
                                };
                            }catch(e){
                                var ee = "emptyString"
                            };

                            try{
                                var f = relevantLayer.parent.parent.parent.parent.parent.name.toString()

                                if(namePSB.test(f) || namePhotoshop.test(f)){
                                    var f = "emptyString"
                                };
                            }catch(e){
                                var f = "emptyString"
                            };

                            try{
                                var g = relevantLayer.parent.parent.parent.parent.parent.parent.name.toString()

                                if(namePSB.test(g) || namePhotoshop.test(g)){
                                    var g = "emptyString"
                                };
                            }catch(e){
                                var g = "emptyString"
                            };

                            try{
                                var h = relevantLayer.parent.parent.parent.parent.parent.parent.parent.name.toString()

                                if(namePSB.test(h) || namePhotoshop.test(h)){
                                    var h = "emptyString"
                                };
                            }catch(e){
                                var h = "emptyString"
                            };

                            try{
                                var i = relevantLayer.parent.parent.parent.parent.parent.parent.parent.parent.name.toString()

                                if(namePSB.test(i) || namePhotoshop.test(i)){
                                    var i = "emptyString"
                                };
                            }catch(e){
                                var i = "emptyString"
                            };

                            try{
                                var j = relevantLayer.parent.parent.parent.parent.parent.parent.parent.parent.parent.name.toString()

                                if(namePSB.test(j) || namePhotoshop.test(j)){
                                    var j = "emptyString"
                                };
                            }catch(e){
                                var j = "emptyString"
                            };

                            try{
                                var k = relevantLayer.parent.parent.parent.parent.parent.parent.parent.parent.parent.parent.name.toString()

                                if(namePSB.test(k) || namePhotoshop.test(k)){
                                    var k = "emptyString"
                                };
                            }catch(e){
                                var k = "emptyString"
                            };

                            try{
                                var l = relevantLayer.parent.parent.parent.parent.parent.parent.parent.parent.parent.parent.parent.name.toString()

                                if(namePSB.test(l) || namePhotoshop.test(l)){
                                    var l = "emptyString"
                                };
                            }catch(e){
                                var l = "emptyString"
                            };

                        // Determine number of parents

                            var layerChain = l + "layerChainSpacer" + k  + "layerChainSpacer" + j + "layerChainSpacer" + i + "layerChainSpacer" + h + "layerChainSpacer" + g + "layerChainSpacer" + f + "layerChainSpacer" + ee + "layerChainSpacer" + d + "layerChainSpacer" + c + "layerChainSpacer" + b + "layerChainSpacer" + a

                            var layerChain2 = (layerChain.split("emptyString")[layerChain.split("emptyString").length - 1])

                            layerChain3 = layerChain2.split("layerChainSpacer")

                        // Arrange names

                            if(layerChain3.length == 2){
                                var layerChainArranged = layerChain3[1]
                            };

                            if(layerChain3.length == 3){
                                var layerChainArranged = layerChain3[1] + ".visibilityScriptSpacer." + layerChain3[2]
                            };

                            if(layerChain3.length == 4){
                                var layerChainArranged = layerChain3[1] + ".visibilityScriptSpacer." + layerChain3[2] + ".visibilityScriptSpacer." + layerChain3[3]
                            };

                            if(layerChain3.length == 5){
                                var layerChainArranged = layerChain3[1] + ".visibilityScriptSpacer." + layerChain3[2] + ".visibilityScriptSpacer." + layerChain3[3] + ".visibilityScriptSpacer." + layerChain3[4]
                            };

                            if(layerChain3.length == 6){
                                var layerChainArranged = layerChain3[1] + ".visibilityScriptSpacer." + layerChain3[2] + ".visibilityScriptSpacer." + layerChain3[3] + ".visibilityScriptSpacer." + layerChain3[4] + ".visibilityScriptSpacer." + layerChain3[5]
                            };

                            if(layerChain3.length == 7){
                                var layerChainArranged = layerChain3[1] + ".visibilityScriptSpacer." + layerChain3[2] + ".visibilityScriptSpacer." + layerChain3[3] + ".visibilityScriptSpacer." + layerChain3[4] + ".visibilityScriptSpacer." + layerChain3[5] + ".visibilityScriptSpacer." + layerChain3[6]
                            };

                            if(layerChain3.length == 8){
                                var layerChainArranged = layerChain3[1] + ".visibilityScriptSpacer." + layerChain3[2] + ".visibilityScriptSpacer." + layerChain3[3] + ".visibilityScriptSpacer." + layerChain3[4] + ".visibilityScriptSpacer." + layerChain3[5] + ".visibilityScriptSpacer." + layerChain3[6] + ".visibilityScriptSpacer." + layerChain3[7]
                            };

                            if(layerChain3.length == 9){
                                var layerChainArranged = layerChain3[1] + ".visibilityScriptSpacer." + layerChain3[2] + ".visibilityScriptSpacer." + layerChain3[3] + ".visibilityScriptSpacer." + layerChain3[4] + ".visibilityScriptSpacer." + layerChain3[5] + ".visibilityScriptSpacer." + layerChain3[6] + ".visibilityScriptSpacer." + layerChain3[7] + ".visibilityScriptSpacer." + layerChain3[8]
                            };

                            if(layerChain3.length == 10){
                                var layerChainArranged = layerChain3[1] + ".visibilityScriptSpacer." + layerChain3[2] + ".visibilityScriptSpacer." + layerChain3[3] + ".visibilityScriptSpacer." + layerChain3[4] + ".visibilityScriptSpacer." + layerChain3[5] + ".visibilityScriptSpacer." + layerChain3[6] + ".visibilityScriptSpacer." + layerChain3[7] + ".visibilityScriptSpacer." + layerChain3[8] + ".visibilityScriptSpacer." + layerChain3[9]
                            };

                            if(layerChain3.length == 11){
                                var layerChainArranged = layerChain3[1] + ".visibilityScriptSpacer." + layerChain3[2] + ".visibilityScriptSpacer." + layerChain3[3] + ".visibilityScriptSpacer." + layerChain3[4] + ".visibilityScriptSpacer." + layerChain3[5] + ".visibilityScriptSpacer." + layerChain3[6] + ".visibilityScriptSpacer." + layerChain3[7] + ".visibilityScriptSpacer." + layerChain3[8] + ".visibilityScriptSpacer." + layerChain3[9] + ".visibilityScriptSpacer." + layerChain3[10]
                            };

                            if(layerChain3.length == 12){
                                var layerChainArranged = layerChain3[1] + ".visibilityScriptSpacer." + layerChain3[2] + ".visibilityScriptSpacer." + layerChain3[3] + ".visibilityScriptSpacer." + layerChain3[4] + ".visibilityScriptSpacer." + layerChain3[5] + ".visibilityScriptSpacer." + layerChain3[6] + ".visibilityScriptSpacer." + layerChain3[7] + ".visibilityScriptSpacer." + layerChain3[8] + ".visibilityScriptSpacer." + layerChain3[9] + ".visibilityScriptSpacer." + layerChain3[10] + ".visibilityScriptSpacer." + layerChain3[11]
                            };

                            relevantLayer.name = layerChainArranged;
                    };

        // Invisibility Loop

            function invisibilityLoop(){
                for(var a = 0; a < layersToHide.length; a++){
                    var layerChainSplit = layersToHide[a].split(".visibilityScriptSpacer.")

                    if(layerChainSplit.length == 11){
                        try{
                            app.activeDocument.layers.getByName(layerChainSplit[0]).layers.getByName(layerChainSplit[1]).layers.getByName(layerChainSplit[2]).layers.getByName(layerChainSplit[3]).layers.getByName(layerChainSplit[4]).layers.getByName(layerChainSplit[5]).layers.getByName(layerChainSplit[6]).layers.getByName(layerChainSplit[7]).layers.getByName(layerChainSplit[8]).layers.getByName(layerChainSplit[9]).layers.getByName(layerChainSplit[10]).visible = false;
                        }catch(e){};
                    };
                };

                for(var a = 0; a < layersToHide.length; a++){
                    var layerChainSplit = layersToHide[a].split(".visibilityScriptSpacer.")

                    if(layerChainSplit.length == 10){
                        try{
                            app.activeDocument.layers.getByName(layerChainSplit[0]).layers.getByName(layerChainSplit[1]).layers.getByName(layerChainSplit[2]).layers.getByName(layerChainSplit[3]).layers.getByName(layerChainSplit[4]).layers.getByName(layerChainSplit[5]).layers.getByName(layerChainSplit[6]).layers.getByName(layerChainSplit[7]).layers.getByName(layerChainSplit[8]).layers.getByName(layerChainSplit[9]).visible = false;
                        }catch(e){};
                    };
                };

                for(var a = 0; a < layersToHide.length; a++){
                    var layerChainSplit = layersToHide[a].split(".visibilityScriptSpacer.")

                    if(layerChainSplit.length == 9){
                        try{
                            app.activeDocument.layers.getByName(layerChainSplit[0]).layers.getByName(layerChainSplit[1]).layers.getByName(layerChainSplit[2]).layers.getByName(layerChainSplit[3]).layers.getByName(layerChainSplit[4]).layers.getByName(layerChainSplit[5]).layers.getByName(layerChainSplit[6]).layers.getByName(layerChainSplit[7]).layers.getByName(layerChainSplit[8]).visible = false;
                        }catch(e){};
                    };
                };

                for(var a = 0; a < layersToHide.length; a++){
                    var layerChainSplit = layersToHide[a].split(".visibilityScriptSpacer.")

                    if(layerChainSplit.length == 8){
                        try{
                            app.activeDocument.layers.getByName(layerChainSplit[0]).layers.getByName(layerChainSplit[1]).layers.getByName(layerChainSplit[2]).layers.getByName(layerChainSplit[3]).layers.getByName(layerChainSplit[4]).layers.getByName(layerChainSplit[5]).layers.getByName(layerChainSplit[6]).layers.getByName(layerChainSplit[7]).visible = false;
                        }catch(e){};
                    };
                };

                for(var a = 0; a < layersToHide.length; a++){
                    var layerChainSplit = layersToHide[a].split(".visibilityScriptSpacer.")

                    if(layerChainSplit.length == 7){
                        try{
                            app.activeDocument.layers.getByName(layerChainSplit[0]).layers.getByName(layerChainSplit[1]).layers.getByName(layerChainSplit[2]).layers.getByName(layerChainSplit[3]).layers.getByName(layerChainSplit[4]).layers.getByName(layerChainSplit[5]).layers.getByName(layerChainSplit[6]).visible = false;
                        }catch(e){};
                    };
                };

                for(var a = 0; a < layersToHide.length; a++){
                    var layerChainSplit = layersToHide[a].split(".visibilityScriptSpacer.")

                    if(layerChainSplit.length == 6){
                        try{
                            app.activeDocument.layers.getByName(layerChainSplit[0]).layers.getByName(layerChainSplit[1]).layers.getByName(layerChainSplit[2]).layers.getByName(layerChainSplit[3]).layers.getByName(layerChainSplit[4]).layers.getByName(layerChainSplit[5]).visible = false;
                        }catch(e){};
                    };
                };

                for(var a = 0; a < layersToHide.length; a++){
                    var layerChainSplit = layersToHide[a].split(".visibilityScriptSpacer.")

                    if(layerChainSplit.length == 5){
                        try{
                            app.activeDocument.layers.getByName(layerChainSplit[0]).layers.getByName(layerChainSplit[1]).layers.getByName(layerChainSplit[2]).layers.getByName(layerChainSplit[3]).layers.getByName(layerChainSplit[4]).visible = false;
                        }catch(e){};
                    };
                };

                for(var a = 0; a < layersToHide.length; a++){
                    var layerChainSplit = layersToHide[a].split(".visibilityScriptSpacer.")

                    if(layerChainSplit.length == 4){
                        try{
                            app.activeDocument.layers.getByName(layerChainSplit[0]).layers.getByName(layerChainSplit[1]).layers.getByName(layerChainSplit[2]).layers.getByName(layerChainSplit[3]).visible = false;
                        }catch(e){};
                    };
                };

                for(var a = 0; a < layersToHide.length; a++){
                    var layerChainSplit = layersToHide[a].split(".visibilityScriptSpacer.")

                    if(layerChainSplit.length == 3){
                        try{
                            app.activeDocument.layers.getByName(layerChainSplit[0]).layers.getByName(layerChainSplit[1]).layers.getByName(layerChainSplit[2]).visible = false;
                        }catch(e){};
                    };
                };

                for(var a = 0; a < layersToHide.length; a++){
                    var layerChainSplit = layersToHide[a].split(".visibilityScriptSpacer.")

                    if(layerChainSplit.length == 2){
                        try{
                            var myLayer = app.activeDocument.layers.getByName(layerChainSplit[0]).layers.getByName(layerChainSplit[1])

                            myLayer.visible = false;

                        }catch(e){};
                    };
                };

                for(var a = 0; a < layersToHide.length; a++){
                    var layerChainSplit = layersToHide[a].split(".visibilityScriptSpacer.")

                    if(layerChainSplit.length == 1){
                        try{
                            app.activeDocument.layers.getByName(layerChainSplit[0]).visible = false;
                        }catch(e){};
                    };
                };

                // Clear layersToHide

                    layersToHide.length = 0;
            };

    // General

        // Layer

            // Layer creation

                // Create adjustment Layers

                    // Levels

                        function createAdjustmentsLayerLevels(name){
                            var idMk = charIDToTypeID( "Mk  " );
                            var desc96 = new ActionDescriptor();
                            var idnull = charIDToTypeID( "null" );
                            var ref47 = new ActionReference();
                            var idAdjL = charIDToTypeID( "AdjL" );
                            ref47.putClass( idAdjL );
                            desc96.putReference( idnull, ref47 );
                            var idUsng = charIDToTypeID( "Usng" );
                            var desc97 = new ActionDescriptor();
                            var idNm = charIDToTypeID( "Nm  " );
                            desc97.putString( idNm, name );
                            var idType = charIDToTypeID( "Type" );
                            var desc98 = new ActionDescriptor();
                            var idpresetKind = stringIDToTypeID( "presetKind" );
                            var idpresetKindType = stringIDToTypeID( "presetKindType" );
                            var idpresetKindDefault = stringIDToTypeID( "presetKindDefault" );
                            desc98.putEnumerated( idpresetKind, idpresetKindType, idpresetKindDefault );
                            var idLvls = charIDToTypeID( "Lvls" );
                            desc97.putObject( idType, idLvls, desc98 );
                            var idAdjL = charIDToTypeID( "AdjL" );
                            desc96.putObject( idUsng, idAdjL, desc97 );
                            executeAction( idMk, desc96, DialogModes.NO );
                        };

            // Layer selection

                // Select all layers

                    function selectAllLayers(){
                        var idselectAllLayers = stringIDToTypeID( "selectAllLayers" );
                        var desc36 = new ActionDescriptor();
                        var idnull = charIDToTypeID( "null" );
                        var ref24 = new ActionReference();
                        var idLyr = charIDToTypeID( "Lyr " );
                        var idOrdn = charIDToTypeID( "Ordn" );
                        var idTrgt = charIDToTypeID( "Trgt" );
                        ref24.putEnumerated( idLyr, idOrdn, idTrgt );
                        desc36.putReference( idnull, ref24 );
                        executeAction( idselectAllLayers, desc36, DialogModes.NO );
                    };

                // Select all layers containing name

                    // Select all layers matching specified string(s) (add try/catch to function call plus anything done to the selected layers afterwards, not to function itself)

                        function selectAllLayersMatchingSpecifiedString(wordToSplit, theName, theOtherName){
                            try{
                                var wordToSplitToString = wordToSplit.toString()
                                var theResults = new Array;
                                selectAllLayers();
                                var selectedLayers = getSelectedLayersIndex();

                                for(var a = 0; a < selectedLayers.length; a++){
                                    var thisName = retrieveLayerName(Number(selectedLayers[a])).split(wordToSplitToString)[0];

                                    if(thisName == theName || thisName == theOtherName){
                                        theResults.push(Number(selectedLayers[a]))
                                    };
                                };

                                if(theResults.length != 0){
                                    selectLayerByLayerIndex(theResults[0], false);
                                    for (var m = 1; m < theResults.length; m++){
                                    selectLayerByLayerIndex(theResults[m], true);
                                    };
                                }else{
                                    selectNoLayers()
                                }

                            }catch(e){};
                        };

                        function getSelectedLayersIndex(){
                            var selectedLayers = new Array;
                            var ref = new ActionReference();
                            ref.putEnumerated( charIDToTypeID("Dcmn"), charIDToTypeID("Ordn"), charIDToTypeID("Trgt") );
                            var desc = executeActionGet(ref);
                            if( desc.hasKey( stringIDToTypeID( 'targetLayers' ) ) ){
                            desc = desc.getList( stringIDToTypeID( 'targetLayers' ));
                            var c = desc.count
                            var selectedLayers = new Array();
                            for(var i=0;i<c;i++){
                            try{
                            activeDocument.backgroundLayer;
                            selectedLayers.push(  desc.getReference( i ).getIndex() );
                            }catch(e){
                            selectedLayers.push(  desc.getReference( i ).getIndex()+1 );
                            };
                            };
                            }else{
                            var ref = new ActionReference();
                            ref.putProperty( charIDToTypeID("Prpr") , charIDToTypeID( "ItmI" ));
                            ref.putEnumerated( charIDToTypeID("Lyr "), charIDToTypeID("Ordn"), charIDToTypeID("Trgt") );
                            try{
                            activeDocument.backgroundLayer;
                            selectedLayers.push( executeActionGet(ref).getInteger(charIDToTypeID( "ItmI" ))-1);
                            }catch(e){
                            selectedLayers.push( executeActionGet(ref).getInteger(charIDToTypeID( "ItmI" )));
                            };
                            };
                            return selectedLayers;
                        };

                        function retrieveLayerName(idx){
                            var ref = new ActionReference();
                            ref.putIndex( charIDToTypeID( "Lyr " ), idx);
                            var desc = executeActionGet(ref);
                            return desc.getString(stringIDToTypeID("name"));
                        };

                        function selectLayerByLayerIndex(index,add){
                            add = undefined ? add = false : add
                            var ref = new ActionReference();
                            ref.putIndex(charIDToTypeID("Lyr "), index);
                            var desc = new ActionDescriptor();
                            desc.putReference(charIDToTypeID("null"), ref );
                            if(add) desc.putEnumerated( stringIDToTypeID( "selectionModifier" ), stringIDToTypeID( "selectionModifierType" ), stringIDToTypeID( "addToSelection" ) );
                            desc.putBoolean( charIDToTypeID( "MkVs" ), false );
                            try{
                                executeAction(charIDToTypeID("slct"), desc, DialogModes.NO );
                            }catch(e){
                            };
                        };

                    // Select all layers ending with specified string (add try/catch to function call plus anything done to the selected layers afterwards, not to function itself)

                            function selectAllLayersEndingWithSpecifiedString(wordToSplit, theString){
                                try{
                                    var wordToSplitToString = wordToSplit.toString()
                                    var theResults = new Array;
                                    selectAllLayers();
                                    var selectedLayers = getSelectedLayersIndex();

                                    for(var a = 0; a < selectedLayers.length; a++){
                                        var thisName = retrieveLayerName(Number(selectedLayers[a])).split(wordToSplitToString)[0];

                                        if(thisName.endsWith(theString)){
                                            theResults.push(Number(selectedLayers[a]))
                                        };
                                    };

                                    if(theResults.length != 0){
                                        selectLayerByLayerIndex(theResults[0], false);
                                        for (var m = 1; m < theResults.length; m++){
                                            selectLayerByLayerIndex(theResults[m], true);
                                        };
                                    }else{
                                        selectNoLayers()
                                    }
                                }catch(e){};
                            };

                            function getSelectedLayersIndex(){
                                var selectedLayers = new Array;
                                var ref = new ActionReference();
                                ref.putEnumerated( charIDToTypeID("Dcmn"), charIDToTypeID("Ordn"), charIDToTypeID("Trgt") );
                                var desc = executeActionGet(ref);
                                if( desc.hasKey( stringIDToTypeID( 'targetLayers' ) ) ){
                                desc = desc.getList( stringIDToTypeID( 'targetLayers' ));
                                var c = desc.count
                                var selectedLayers = new Array();
                                for(var i=0;i<c;i++){
                                try{
                                activeDocument.backgroundLayer;
                                selectedLayers.push(  desc.getReference( i ).getIndex() );
                                }catch(e){
                                selectedLayers.push(  desc.getReference( i ).getIndex()+1 );
                                };
                                };
                                }else{
                                var ref = new ActionReference();
                                ref.putProperty( charIDToTypeID("Prpr") , charIDToTypeID( "ItmI" ));
                                ref.putEnumerated( charIDToTypeID("Lyr "), charIDToTypeID("Ordn"), charIDToTypeID("Trgt") );
                                try{
                                activeDocument.backgroundLayer;
                                selectedLayers.push( executeActionGet(ref).getInteger(charIDToTypeID( "ItmI" ))-1);
                                }catch(e){
                                selectedLayers.push( executeActionGet(ref).getInteger(charIDToTypeID( "ItmI" )));
                                };
                                };
                                return selectedLayers;
                            };

                            function retrieveLayerName(idx){
                                var ref = new ActionReference();
                                ref.putIndex( charIDToTypeID( "Lyr " ), idx);
                                var desc = executeActionGet(ref);
                                return desc.getString(stringIDToTypeID("name"));
                            };

                            function selectLayerByLayerIndex(index,add){
                                add = undefined ? add = false : add
                                var ref = new ActionReference();
                                ref.putIndex(charIDToTypeID("Lyr "), index);
                                var desc = new ActionDescriptor();
                                desc.putReference(charIDToTypeID("null"), ref );
                                if(add) desc.putEnumerated( stringIDToTypeID( "selectionModifier" ), stringIDToTypeID( "selectionModifierType" ), stringIDToTypeID( "addToSelection" ) );
                                desc.putBoolean( charIDToTypeID( "MkVs" ), false );
                                try{
                                    executeAction(charIDToTypeID("slct"), desc, DialogModes.NO );
                                }catch(e){
                                };
                            };

                // Select all layers in specified layerset

                    function selectAllLayersInSpecifiedLayerSet(groupLocation){
                        app.activeDocument.activeLayer = groupLocation;
                        var groupStartIdx = getActiveLayerIndex();
                        app.activeDocument.activeLayer = app.activeDocument.activeLayer.layers[app.activeDocument.activeLayer.layers.length-1];
                        var groupEndIdx = getActiveLayerIndex();

                        for(l=groupEndIdx;l<groupStartIdx;l++){
                            addToLayerSelectionByIndex( l );
                        };

                        function addToLayerSelectionByIndex( idx ){
                            var desc = new ActionDescriptor();
                            var ref = new ActionReference();
                            ref.putIndex( charIDToTypeID('Lyr '), idx );
                            desc.putReference( charIDToTypeID('null'), ref );
                            desc.putEnumerated( stringIDToTypeID('selectionModifier'), stringIDToTypeID('selectionModifierType'), stringIDToTypeID('addToSelection') );
                            desc.putBoolean( charIDToTypeID('MkVs'), false );
                            executeAction( charIDToTypeID('slct'), desc, DialogModes.NO );
                        };

                        function getActiveLayerIndex(){
                            var ref = new ActionReference();
                            ref.putProperty( charIDToTypeID("Prpr") , charIDToTypeID( "ItmI" ));
                            ref.putEnumerated( charIDToTypeID("Lyr "), charIDToTypeID("Ordn"), charIDToTypeID("Trgt") );
                            var res = executeActionGet(ref).getInteger(charIDToTypeID( "ItmI" )) - Number( hasBackground() );
                            return res;
                        };

                        function hasBackground(){
                            var res = undefined;

                            try{
                                var ref = new ActionReference();
                                ref.putProperty( 1349677170 , 1315774496);
                                ref.putIndex( 1283027488, 0 );
                                executeActionGet(ref).getString(1315774496 );;
                                res = true;
                                }catch(e){ res = false}
                                return res;
                        };
                    };

                // Test if specified layer exists

                    function doesLayerExist(groupToSearchThrough, nameToFind) {
                        for (i=0; i<groupToSearchThrough.layers.length; i++) {
                            if (groupToSearchThrough.layers[i].name == nameToFind) return true;
                        };
                        return false;
                    };

                // Select no layers

                    function selectNoLayers(){
                        var idselectNoLayers = stringIDToTypeID( "selectNoLayers" );
                        var desc284 = new ActionDescriptor();
                        var idnull = charIDToTypeID( "null" );
                        var ref156 = new ActionReference();
                        var idLyr = charIDToTypeID( "Lyr " );
                        var idOrdn = charIDToTypeID( "Ordn" );
                        var idTrgt = charIDToTypeID( "Trgt" );
                        ref156.putEnumerated( idLyr, idOrdn, idTrgt );
                        desc284.putReference( idnull, ref156 );
                        executeAction( idselectNoLayers, desc284, DialogModes.NO );
                    };

            // Layer retrieval

                function cID (inVal) { return charIDToTypeID(inVal);}
                function sID (inVal) { return stringIDToTypeID(inVal);}

                function getSelectedLayers(){
                    var resultLayers = new Array();

                    try{
                        var descGrp = new ActionDescriptor();
                        var refGrp = new ActionReference();
                        refGrp.putEnumerated(cID( "Lyr " ),cID( "Ordn" ),cID( "Trgt" ));
                        descGrp.putReference(cID( "null" ), refGrp );
                        executeAction( sID( "groupLayersEvent" ), descGrp, DialogModes.NO );
                        for (var ix=0;ix<app.activeDocument.activeLayer.layers.length;ix++){resultLayers.push(app.activeDocument.activeLayer.layers[ix])}
                        var desc5 = new ActionDescriptor();
                        var ref2 = new ActionReference();
                        ref2.putEnumerated( cID( "HstS" ), cID( "Ordn" ), cID( "Prvs" ) );
                        desc5.putReference( cID( "null" ), ref2 );
                        executeAction( cID( "slct" ), desc5, DialogModes.NO );
                    }catch(e){};

                    return resultLayers;
                };

            // Layer navigation

                // Move forward a layer

                    function moveForwardALayer(){
                        var idslct = charIDToTypeID( "slct" );
                        var desc2909 = new ActionDescriptor();
                        var idnull = charIDToTypeID( "null" );
                        var ref1917 = new ActionReference();
                        var idLyr = charIDToTypeID( "Lyr " );
                        var idOrdn = charIDToTypeID( "Ordn" );
                        var idFrwr = charIDToTypeID( "Frwr" );
                        ref1917.putEnumerated( idLyr, idOrdn, idFrwr );
                        desc2909.putReference( idnull, ref1917 );
                        var idMkVs = charIDToTypeID( "MkVs" );
                        desc2909.putBoolean( idMkVs, false );
                        executeAction( idslct, desc2909, DialogModes.NO );
                    };

                // Move back a layer

                    function moveBackALayer(){
                        var idslct = charIDToTypeID( "slct" );
                        var desc2876 = new ActionDescriptor();
                        var idnull = charIDToTypeID( "null" );
                        var ref2323 = new ActionReference();
                        var idLyr = charIDToTypeID( "Lyr " );
                        var idOrdn = charIDToTypeID( "Ordn" );
                        var idBckw = charIDToTypeID( "Bckw" );
                        ref2323.putEnumerated( idLyr, idOrdn, idBckw );
                        desc2876.putReference( idnull, ref2323 );
                        var idMkVs = charIDToTypeID( "MkVs" );
                        desc2876.putBoolean( idMkVs, false );
                        executeAction( idslct, desc2876, DialogModes.NO );
                    };

            // Layer modification

                // Duplicate active layer's filters to layer above

                    function duplicateActiveLayersFiltersToLayerAbove(){
                        try{
                            // Get active layer's index

                                var selectedLayers = new Array;
                                var ref = new ActionReference();
                                ref.putEnumerated(charIDToTypeID("Dcmn"), charIDToTypeID("Ordn"), charIDToTypeID("Trgt"));
                                var desc = executeActionGet(ref);

                                if(desc.hasKey(stringIDToTypeID("targetLayers"))){
                                    desc = desc.getList(stringIDToTypeID("targetLayers"));
                                    var c = desc.count
                                    var selectedLayers = new Array();
                                    for (var i = 0; i < c; i++){
                                        try {
                                            docRef.backgroundLayer;
                                            selectedLayers.push(desc.getReference(i).getIndex());
                                        } catch (e) {
                                            selectedLayers.push(desc.getReference(i).getIndex() + 1);
                                        }
                                    }
                                }else{
                                    var ref = new ActionReference();
                                    ref.putProperty(charIDToTypeID("Prpr"), charIDToTypeID("ItmI"));
                                    ref.putEnumerated(charIDToTypeID("Lyr "), charIDToTypeID("Ordn"), charIDToTypeID("Trgt"));
                                    try {
                                        docRef.backgroundLayer;
                                        selectedLayers.push(executeActionGet(ref).getInteger(charIDToTypeID("ItmI")) - 1);
                                    } catch (e) {
                                        selectedLayers.push(executeActionGet(ref).getInteger(charIDToTypeID("ItmI")));
                                    }
                                }

                            // Create myNumber variable

                                var myNumber = Number(selectedLayers) + 1

                            // Duplicate Filters

                                try{
                                    var idDplc = charIDToTypeID( "Dplc" );
                                    var desc624 = new ActionDescriptor();
                                    var idnull = charIDToTypeID( "null" );
                                    var ref154 = new ActionReference();
                                    var idfilterFX = stringIDToTypeID( "filterFX" );
                                    ref154.putClass( idfilterFX );
                                    var idLyr = charIDToTypeID( "Lyr " );
                                    var idOrdn = charIDToTypeID( "Ordn" );
                                    var idTrgt = charIDToTypeID( "Trgt" );
                                    ref154.putEnumerated( idLyr, idOrdn, idTrgt );
                                    desc624.putReference( idnull, ref154 );
                                    var idT = charIDToTypeID( "T   " );
                                    var ref155 = new ActionReference();
                                    var idLyr = charIDToTypeID( "Lyr " );
                                    ref155.putIndex( idLyr, myNumber );
                                    desc624.putReference( idT, ref155 );
                                    executeAction( idDplc, desc624, DialogModes.NO );
                                }catch(e){}
                        }catch(e){};
                    };

                // Merge active layer down

                    function mergeActiveLayerDown(){
                        var idMrgtwo = charIDToTypeID( "Mrg2" );
                        var desc57 = new ActionDescriptor();
                        executeAction( idMrgtwo, desc57, DialogModes.NO );
                    };

                // Clip active layer to layer below

                    function clipActiveLayerToLayerBelow(){
                        var idGrpL = charIDToTypeID( "GrpL" );
                        var desc333 = new ActionDescriptor();
                        var idnull = charIDToTypeID( "null" );
                        var ref281 = new ActionReference();
                        var idLyr = charIDToTypeID( "Lyr " );
                        var idOrdn = charIDToTypeID( "Ordn" );
                        var idTrgt = charIDToTypeID( "Trgt" );
                        ref281.putEnumerated( idLyr, idOrdn, idTrgt );
                        desc333.putReference( idnull, ref281 );
                        executeAction( idGrpL, desc333, DialogModes.NO );
                    };

                // Group active layer(s)

                    function groupActiveLayers(){
                        var idMk = charIDToTypeID( "Mk  " );
                        var desc1308 = new ActionDescriptor();
                        var idnull = charIDToTypeID( "null" );
                        var ref974 = new ActionReference();
                        var idlayerSection = stringIDToTypeID( "layerSection" );
                        ref974.putClass( idlayerSection );
                        desc1308.putReference( idnull, ref974 );
                        var idFrom = charIDToTypeID( "From" );
                        var ref975 = new ActionReference();
                        var idLyr = charIDToTypeID( "Lyr " );
                        var idOrdn = charIDToTypeID( "Ordn" );
                        var idTrgt = charIDToTypeID( "Trgt" );
                        ref975.putEnumerated( idLyr, idOrdn, idTrgt );
                        desc1308.putReference( idFrom, ref975 );
                        executeAction( idMk, desc1308, DialogModes.NO );
                    };

                // Ungroup active group
                    function ungroupActiveGroup(){
                        var idungroupLayersEvent = stringIDToTypeID( "ungroupLayersEvent" );
                        var desc5484 = new ActionDescriptor();
                        var idnull = charIDToTypeID( "null" );
                        var ref4113 = new ActionReference();
                        var idLyr = charIDToTypeID( "Lyr " );
                        var idOrdn = charIDToTypeID( "Ordn" );
                        var idTrgt = charIDToTypeID( "Trgt" );
                        ref4113.putEnumerated( idLyr, idOrdn, idTrgt );
                        desc5484.putReference( idnull, ref4113 );
                        executeAction( idungroupLayersEvent, desc5484, DialogModes.NO );
                    };

                // Move active layer back

                    function moveActiveLayerBack(){
                        var idmove = charIDToTypeID( "move" );
                        var desc1737 = new ActionDescriptor();
                        var idnull = charIDToTypeID( "null" );
                        var ref1482 = new ActionReference();
                        var idLyr = charIDToTypeID( "Lyr " );
                        var idOrdn = charIDToTypeID( "Ordn" );
                        var idTrgt = charIDToTypeID( "Trgt" );
                        ref1482.putEnumerated( idLyr, idOrdn, idTrgt );
                        desc1737.putReference( idnull, ref1482 );
                        var idT = charIDToTypeID( "T   " );
                        var ref1483 = new ActionReference();
                        var idLyr = charIDToTypeID( "Lyr " );
                        var idOrdn = charIDToTypeID( "Ordn" );
                        var idPrvs = charIDToTypeID( "Prvs" );
                        ref1483.putEnumerated( idLyr, idOrdn, idPrvs );
                        desc1737.putReference( idT, ref1483 );
                        executeAction( idmove, desc1737, DialogModes.NO );
                    };

                // Rasterize active layer

                    function rasterizeActiveLayer(){
                        var idrasterizeLayer = stringIDToTypeID( "rasterizeLayer" );
                        var desc1252 = new ActionDescriptor();
                        var idnull = charIDToTypeID( "null" );
                        var ref1100 = new ActionReference();
                        var idLyr = charIDToTypeID( "Lyr " );
                        var idOrdn = charIDToTypeID( "Ordn" );
                        var idTrgt = charIDToTypeID( "Trgt" );
                        ref1100.putEnumerated( idLyr, idOrdn, idTrgt );
                        desc1252.putReference( idnull, ref1100 );
                        executeAction( idrasterizeLayer, desc1252, DialogModes.NO );
                    };

                // Create mask on active layer

                    function createMaskOnActiveLayer(){
                        var idMk = charIDToTypeID( "Mk  " );
                        var desc879 = new ActionDescriptor();
                        var idNw = charIDToTypeID( "Nw  " );
                        var idChnl = charIDToTypeID( "Chnl" );
                        desc879.putClass( idNw, idChnl );
                        var idAt = charIDToTypeID( "At  " );
                        var ref612 = new ActionReference();
                        var idChnl = charIDToTypeID( "Chnl" );
                        var idChnl = charIDToTypeID( "Chnl" );
                        var idMsk = charIDToTypeID( "Msk " );
                        ref612.putEnumerated( idChnl, idChnl, idMsk );
                        desc879.putReference( idAt, ref612 );
                        var idUsng = charIDToTypeID( "Usng" );
                        var idUsrM = charIDToTypeID( "UsrM" );
                        var idRvlA = charIDToTypeID( "RvlA" );
                        desc879.putEnumerated( idUsng, idUsrM, idRvlA );
                        executeAction( idMk, desc879, DialogModes.NO );
                    };

                // Create mask from selection on active layer

                    function createMaskFromSelectionOnActiveLayer(){
                        try{
                            try{
                                var sel = app.activeDocument.selection.bounds;
                            }catch(e){};

                            if(sel != null && sel != undefined){
                                deleteActiveLayersLayerMask()

                                var idMk = charIDToTypeID( "Mk  " );
                                var desc1115 = new ActionDescriptor();
                                var idNw = charIDToTypeID( "Nw  " );
                                var idChnl = charIDToTypeID( "Chnl" );
                                desc1115.putClass( idNw, idChnl );
                                var idAt = charIDToTypeID( "At  " );
                                var ref984 = new ActionReference();
                                var idChnl = charIDToTypeID( "Chnl" );
                                var idChnl = charIDToTypeID( "Chnl" );
                                var idMsk = charIDToTypeID( "Msk " );
                                ref984.putEnumerated( idChnl, idChnl, idMsk );
                                desc1115.putReference( idAt, ref984 );
                                var idUsng = charIDToTypeID( "Usng" );
                                var idUsrM = charIDToTypeID( "UsrM" );
                                var idRvlS = charIDToTypeID( "RvlS" );
                                desc1115.putEnumerated( idUsng, idUsrM, idRvlS );
                                executeAction( idMk, desc1115, DialogModes.NO );
                            };
                        }catch(e){};
                    };

                // Delete active layer's layer mask

                    function deleteActiveLayersLayerMask(){
                        try{
                            var idDlt = charIDToTypeID( "Dlt " );
                            var desc1114 = new ActionDescriptor();
                            var idnull = charIDToTypeID( "null" );
                            var ref983 = new ActionReference();
                            var idChnl = charIDToTypeID( "Chnl" );
                            var idChnl = charIDToTypeID( "Chnl" );
                            var idMsk = charIDToTypeID( "Msk " );
                            ref983.putEnumerated( idChnl, idChnl, idMsk );
                            desc1114.putReference( idnull, ref983 );
                            executeAction( idDlt, desc1114, DialogModes.NO );
                        }catch(e){};
                    };

                // Set opacity

                    // Make active layer's opacity 0

                        function makeActiveLayersOpacityZero(){
                            var idsetd = charIDToTypeID( "setd" );
                            var desc2907 = new ActionDescriptor();
                            var idnull = charIDToTypeID( "null" );
                            var ref2344 = new ActionReference();
                            var idLyr = charIDToTypeID( "Lyr " );
                            var idOrdn = charIDToTypeID( "Ordn" );
                            var idTrgt = charIDToTypeID( "Trgt" );
                            ref2344.putEnumerated( idLyr, idOrdn, idTrgt );
                            desc2907.putReference( idnull, ref2344 );
                            var idT = charIDToTypeID( "T   " );
                            var desc2908 = new ActionDescriptor();
                            var idOpct = charIDToTypeID( "Opct" );
                            var idPrc = charIDToTypeID( "#Prc" );
                            desc2908.putUnitDouble( idOpct, idPrc, 0.000000 );
                            var idLyr = charIDToTypeID( "Lyr " );
                            desc2907.putObject( idT, idLyr, desc2908 );
                            executeAction( idsetd, desc2907, DialogModes.NO );
                        };

                // Set fill

                    // Make active layer's fill 15

                        function makeActiveLayersFillFifteen(){
                            var idsetd = charIDToTypeID( "setd" );
                            var desc104 = new ActionDescriptor();
                            var idnull = charIDToTypeID( "null" );
                            var ref63 = new ActionReference();
                            var idLyr = charIDToTypeID( "Lyr " );
                            var idOrdn = charIDToTypeID( "Ordn" );
                            var idTrgt = charIDToTypeID( "Trgt" );
                            ref63.putEnumerated( idLyr, idOrdn, idTrgt );
                            desc104.putReference( idnull, ref63 );
                            var idT = charIDToTypeID( "T   " );
                            var desc105 = new ActionDescriptor();
                            var idfillOpacity = stringIDToTypeID( "fillOpacity" );
                            var idPrc = charIDToTypeID( "#Prc" );
                            desc105.putUnitDouble( idfillOpacity, idPrc, 15.000000 );
                            var idLyr = charIDToTypeID( "Lyr " );
                            desc104.putObject( idT, idLyr, desc105 );
                            executeAction( idsetd, desc104, DialogModes.NO );
                        };

                // Move active layer to top

                    function moveActiveLayerToTop (){
                        var idmove = charIDToTypeID( "move" );
                        var desc1256 = new ActionDescriptor();
                        var idnull = charIDToTypeID( "null" );
                        var ref1104 = new ActionReference();
                        var idLyr = charIDToTypeID( "Lyr " );
                        var idOrdn = charIDToTypeID( "Ordn" );
                        var idTrgt = charIDToTypeID( "Trgt" );
                        ref1104.putEnumerated( idLyr, idOrdn, idTrgt );
                        desc1256.putReference( idnull, ref1104 );
                        var idT = charIDToTypeID( "T   " );
                        var ref1105 = new ActionReference();
                        var idLyr = charIDToTypeID( "Lyr " );
                        var idOrdn = charIDToTypeID( "Ordn" );
                        var idFrnt = charIDToTypeID( "Frnt" );
                        ref1105.putEnumerated( idLyr, idOrdn, idFrnt );
                        desc1256.putReference( idT, ref1105 );
                        executeAction( idmove, desc1256, DialogModes.NO );
                    };

                // Move active layer to bottom

                    function moveActiveLayerToBottom (){
                        var idmove = charIDToTypeID( "move" );
                        var desc2908 = new ActionDescriptor();
                        var idnull = charIDToTypeID( "null" );
                        var ref1915 = new ActionReference();
                        var idLyr = charIDToTypeID( "Lyr " );
                        var idOrdn = charIDToTypeID( "Ordn" );
                        var idTrgt = charIDToTypeID( "Trgt" );
                        ref1915.putEnumerated( idLyr, idOrdn, idTrgt );
                        desc2908.putReference( idnull, ref1915 );
                        var idT = charIDToTypeID( "T   " );
                        var ref1916 = new ActionReference();
                        var idLyr = charIDToTypeID( "Lyr " );
                        var idOrdn = charIDToTypeID( "Ordn" );
                        var idPrvs = charIDToTypeID( "Prvs" );
                        ref1916.putEnumerated( idLyr, idOrdn, idPrvs );
                        desc2908.putReference( idT, ref1916 );
                        executeAction( idmove, desc2908, DialogModes.NO );
                    };

                // Set blending modes

                    // Overlay

                        function setActiveLayerBlendingModeToOverlay(){
                            var idsetd = charIDToTypeID( "setd" );
                            var desc13 = new ActionDescriptor();
                            var idnull = charIDToTypeID( "null" );
                            var ref11 = new ActionReference();
                            var idLyr = charIDToTypeID( "Lyr " );
                            var idOrdn = charIDToTypeID( "Ordn" );
                            var idTrgt = charIDToTypeID( "Trgt" );
                            ref11.putEnumerated( idLyr, idOrdn, idTrgt );
                            desc13.putReference( idnull, ref11 );
                            var idT = charIDToTypeID( "T   " );
                            var desc14 = new ActionDescriptor();
                            var idMd = charIDToTypeID( "Md  " );
                            var idBlnM = charIDToTypeID( "BlnM" );
                            var idOvrl = charIDToTypeID( "Ovrl" );
                            desc14.putEnumerated( idMd, idBlnM, idOvrl );
                            var idLyr = charIDToTypeID( "Lyr " );
                            desc13.putObject( idT, idLyr, desc14 );
                            executeAction( idsetd, desc13, DialogModes.NO );
                        };

                    // Linear Dodge

                        function setActiveLayerBlendingModeToLinearDodge(){
                            var idsetd = charIDToTypeID( "setd" );
                            var desc283 = new ActionDescriptor();
                            var idnull = charIDToTypeID( "null" );
                            var ref231 = new ActionReference();
                            var idLyr = charIDToTypeID( "Lyr " );
                            var idOrdn = charIDToTypeID( "Ordn" );
                            var idTrgt = charIDToTypeID( "Trgt" );
                            ref231.putEnumerated( idLyr, idOrdn, idTrgt );
                            desc283.putReference( idnull, ref231 );
                            var idT = charIDToTypeID( "T   " );
                            var desc284 = new ActionDescriptor();
                            var idMd = charIDToTypeID( "Md  " );
                            var idBlnM = charIDToTypeID( "BlnM" );
                            var idlinearDodge = stringIDToTypeID( "linearDodge" );
                            desc284.putEnumerated( idMd, idBlnM, idlinearDodge );
                            var idLyr = charIDToTypeID( "Lyr " );
                            desc283.putObject( idT, idLyr, desc284 );
                            executeAction( idsetd, desc283, DialogModes.NO );
                        };

                    // Multiply

                        function setActiveLayerBlendingModeToMultiply(){
                            var idsetd = charIDToTypeID( "setd" );
                            var desc1098 = new ActionDescriptor();
                            var idnull = charIDToTypeID( "null" );
                            var ref876 = new ActionReference();
                            var idLyr = charIDToTypeID( "Lyr " );
                            var idOrdn = charIDToTypeID( "Ordn" );
                            var idTrgt = charIDToTypeID( "Trgt" );
                            ref876.putEnumerated( idLyr, idOrdn, idTrgt );
                            desc1098.putReference( idnull, ref876 );
                            var idT = charIDToTypeID( "T   " );
                            var desc1099 = new ActionDescriptor();
                            var idMd = charIDToTypeID( "Md  " );
                            var idBlnM = charIDToTypeID( "BlnM" );
                            var idMltp = charIDToTypeID( "Mltp" );
                            desc1099.putEnumerated( idMd, idBlnM, idMltp );
                            var idLyr = charIDToTypeID( "Lyr " );
                            desc1098.putObject( idT, idLyr, desc1099 );
                            executeAction( idsetd, desc1098, DialogModes.NO );
                        };

                    // Normal

                        function setActiveLayerBlendingModeToNormal(){
                            var idsetd = charIDToTypeID( "setd" );
                            var desc10768 = new ActionDescriptor();
                            var idnull = charIDToTypeID( "null" );
                            var ref3301 = new ActionReference();
                            var idLyr = charIDToTypeID( "Lyr " );
                            var idOrdn = charIDToTypeID( "Ordn" );
                            var idTrgt = charIDToTypeID( "Trgt" );
                            ref3301.putEnumerated( idLyr, idOrdn, idTrgt );
                            desc10768.putReference( idnull, ref3301 );
                            var idT = charIDToTypeID( "T   " );
                            var desc10769 = new ActionDescriptor();
                            var idMd = charIDToTypeID( "Md  " );
                            var idBlnM = charIDToTypeID( "BlnM" );
                            var idNrml = charIDToTypeID( "Nrml" );
                            desc10769.putEnumerated( idMd, idBlnM, idNrml );
                            var idLyr = charIDToTypeID( "Lyr " );
                            desc10768.putObject( idT, idLyr, desc10769 );
                            executeAction( idsetd, desc10768, DialogModes.NO );
                        };

                // Set layer colour

                    // Make group colour none

                        function setLayerColourToNone(){
                            var idsetd = charIDToTypeID( "setd" );
                            var desc102 = new ActionDescriptor();
                            var idnull = charIDToTypeID( "null" );
                            var ref62 = new ActionReference();
                            var idLyr = charIDToTypeID( "Lyr " );
                            var idOrdn = charIDToTypeID( "Ordn" );
                            var idTrgt = charIDToTypeID( "Trgt" );
                            ref62.putEnumerated( idLyr, idOrdn, idTrgt );
                            desc102.putReference( idnull, ref62 );
                            var idT = charIDToTypeID( "T   " );
                            var desc103 = new ActionDescriptor();
                            var idClr = charIDToTypeID( "Clr " );
                            var idClr = charIDToTypeID( "Clr " );
                            var idNone = charIDToTypeID( "None" );
                            desc103.putEnumerated( idClr, idClr, idNone );
                            var idLyr = charIDToTypeID( "Lyr " );
                            desc102.putObject( idT, idLyr, desc103 );
                            executeAction( idsetd, desc102, DialogModes.NO );
                        };

                    // Make group colour red

                        function setLayerColourToRed(){
                            var idsetd = charIDToTypeID( "setd" );
                            var desc1309 = new ActionDescriptor();
                            var idnull = charIDToTypeID( "null" );
                            var ref976 = new ActionReference();
                            var idLyr = charIDToTypeID( "Lyr " );
                            var idOrdn = charIDToTypeID( "Ordn" );
                            var idTrgt = charIDToTypeID( "Trgt" );
                            ref976.putEnumerated( idLyr, idOrdn, idTrgt );
                            desc1309.putReference( idnull, ref976 );
                            var idT = charIDToTypeID( "T   " );
                            var desc1310 = new ActionDescriptor();
                            var idClr = charIDToTypeID( "Clr " );
                            var idClr = charIDToTypeID( "Clr " );
                            var idRd = charIDToTypeID( "Rd  " );
                            desc1310.putEnumerated( idClr, idClr, idRd );
                            var idLyr = charIDToTypeID( "Lyr " );
                            desc1309.putObject( idT, idLyr, desc1310 );
                            executeAction( idsetd, desc1309, DialogModes.NO );
                        };

                    // Make group colour green

                        function setLayerColourToGreen(){
                            var idsetd = charIDToTypeID( "setd" );
                            var desc100 = new ActionDescriptor();
                            var idnull = charIDToTypeID( "null" );
                            var ref61 = new ActionReference();
                            var idLyr = charIDToTypeID( "Lyr " );
                            var idOrdn = charIDToTypeID( "Ordn" );
                            var idTrgt = charIDToTypeID( "Trgt" );
                            ref61.putEnumerated( idLyr, idOrdn, idTrgt );
                            desc100.putReference( idnull, ref61 );
                            var idT = charIDToTypeID( "T   " );
                            var desc101 = new ActionDescriptor();
                            var idClr = charIDToTypeID( "Clr " );
                            var idClr = charIDToTypeID( "Clr " );
                            var idGrn = charIDToTypeID( "Grn " );
                            desc101.putEnumerated( idClr, idClr, idGrn );
                            var idLyr = charIDToTypeID( "Lyr " );
                            desc100.putObject( idT, idLyr, desc101 );
                            executeAction( idsetd, desc100, DialogModes.NO );
                        };

                    // Make group colour blue

                        function setLayerColourToBlue(){
                            var idsetd = charIDToTypeID( "setd" );
                            var desc98 = new ActionDescriptor();
                            var idnull = charIDToTypeID( "null" );
                            var ref60 = new ActionReference();
                            var idLyr = charIDToTypeID( "Lyr " );
                            var idOrdn = charIDToTypeID( "Ordn" );
                            var idTrgt = charIDToTypeID( "Trgt" );
                            ref60.putEnumerated( idLyr, idOrdn, idTrgt );
                            desc98.putReference( idnull, ref60 );
                            var idT = charIDToTypeID( "T   " );
                            var desc99 = new ActionDescriptor();
                            var idClr = charIDToTypeID( "Clr " );
                            var idClr = charIDToTypeID( "Clr " );
                            var idBl = charIDToTypeID( "Bl  " );
                            desc99.putEnumerated( idClr, idClr, idBl );
                            var idLyr = charIDToTypeID( "Lyr " );
                            desc98.putObject( idT, idLyr, desc99 );
                            executeAction( idsetd, desc98, DialogModes.NO );
                        };

                // Invert mask

                    function invertActiveLayersMask(){
                        try{
                            var idInvr = charIDToTypeID( "Invr" );
                            executeAction( idInvr, undefined, DialogModes.NO );
                        }catch(e){};
                    };

        // File

            // File modification

                // Save file only if changes were made

                    function saveFileOnlyIfChangesWereMade(documentToSave){
                        if(!documentToSave.saved){
                            documentToSave.save();
                        };
                    };

                // Save PSB

                    function SavePSB(pathPlusName){
                        function cTID(s) { return app.charIDToTypeID(s); };
                        var desc7 = new ActionDescriptor();
                        var desc8 = new ActionDescriptor();
                        desc7.putObject( cTID('As  '), cTID('Pht8'), desc8 );
                        desc7.putPath( cTID('In  '), new File( pathPlusName ) );
                        desc7.putBoolean( cTID('LwCs'), true );
                        executeAction( cTID('save'), desc7, DialogModes.NO );
                    };

                // Set canvas size to diffuse pass' size from active document's location

                    function setCanvasSizeToDiffusePassSizeFromActiveDocumentsLocation(borderSize){
                            // Create relevantDiffuseLayer variable

                                // Variables etc

                                    var rootPath = decodeURI (app.activeDocument.path.fsName);
                                    var targetLayers = new Array;
                                    var subDirectory = "/LinkedLayers/";
                                    targetLayers = app.activeDocument.layers;
                                    var configFolder = Folder(rootPath);
                                    var fileList = configFolder.getFiles();

                                // Create relevantDiffuseLayer variable

                                    for (var i = fileList.length -1; i >= 0  ; i--){
                                        var tempPreliminary1 = fileList[i].toString();
                                        var tempPreliminary = tempPreliminary1.replace(/\\/g, "/")
                                        var temp = tempPreliminary.split("/")[tempPreliminary.split("/").length - 1]
                                        var reguEx = new RegExp(/.exr/gim);
                                        var reguEx2 = new RegExp(/MultiMatte_/gim);
                                        var reguEx3 = new RegExp(/ultimatte/gim);
                                        var reguEx4 = new RegExp(/wire/i);
                                        var reguEx5 = new RegExp(/normals/i);
                                        var reguEx7 = new RegExp(/alpha/i);
                                        var reguEx8 = new RegExp(/raw(.*)shad/i);
                                        var reguEx9 = new RegExp(/diffuse/i);

                                        if (reguEx.test(temp) && !reguEx3.test(temp) && reguEx9.test(temp)){
                                            // Create relevantDiffuseLayer variable

                                                var relevantDiffuseLayer = fileList[i]
                                        };
                                    };

                            // Get the resolution

                                $.localize = true;

                                var g_StackScriptFolderPath = app.path + "/"+ localize("$$$/ScriptingSupport/InstalledScripts=Presets/Scripts") + "/"
                                                                        + localize("$$$/private/LoadStack/StackScriptOnly=Stack Scripts Only/");
                                $.evalFile(g_StackScriptFolderPath + "StackSupport.jsx");

                                var doc = openViewlessDocument(relevantDiffuseLayer);

                                var docWidth = Number(doc.width.toString().split(" px")[0].toString()) + borderSize
                                var docHeight = Number(doc.height.toString().split(" px")[0].toString()) + borderSize

                                doc.close();

                            // Set canvas size

                                var idCnvS = charIDToTypeID( "CnvS" );
                                var desc391 = new ActionDescriptor();
                                var idWdth = charIDToTypeID( "Wdth" );
                                var idPxl = charIDToTypeID( "#Pxl" );
                                desc391.putUnitDouble( idWdth, idPxl, docWidth );
                                var idHght = charIDToTypeID( "Hght" );
                                var idPxl = charIDToTypeID( "#Pxl" );
                                desc391.putUnitDouble( idHght, idPxl, docHeight );
                                var idHrzn = charIDToTypeID( "Hrzn" );
                                var idHrzL = charIDToTypeID( "HrzL" );
                                var idCntr = charIDToTypeID( "Cntr" );
                                desc391.putEnumerated( idHrzn, idHrzL, idCntr );
                                var idVrtc = charIDToTypeID( "Vrtc" );
                                var idVrtL = charIDToTypeID( "VrtL" );
                                var idCntr = charIDToTypeID( "Cntr" );
                                desc391.putEnumerated( idVrtc, idVrtL, idCntr );
                                executeAction( idCnvS, desc391, DialogModes.NO );

                            // Create layer with black and white pixels, or delete it if border size is zero

                                if(borderSize == 0){
                                    try{
                                        app.activeDocument.layers.getByName("setCanvasSizeToDiffusePassSizeFromActiveDocumentsLocation Dummy Layer").remove();
                                    }catch(e){};
                                }else{
                                    // Create new layer on top

                                        app.activeDocument.artLayers.add().name = "setCanvasSizeToDiffusePassSizeFromActiveDocumentsLocation Dummy Layer";

                                        app.activeDocument.activeLayer = app.activeDocument.layers.getByName("setCanvasSizeToDiffusePassSizeFromActiveDocumentsLocation Dummy Layer");

                                        moveActiveLayerToTop();

                                    // Select top-left pixel

                                        var idsetd = charIDToTypeID( "setd" );
                                        var desc166 = new ActionDescriptor();
                                        var idnull = charIDToTypeID( "null" );
                                        var ref87 = new ActionReference();
                                        var idChnl = charIDToTypeID( "Chnl" );
                                        var idfsel = charIDToTypeID( "fsel" );
                                        ref87.putProperty( idChnl, idfsel );
                                        desc166.putReference( idnull, ref87 );
                                        var idT = charIDToTypeID( "T   " );
                                        var desc167 = new ActionDescriptor();
                                        var idTop = charIDToTypeID( "Top " );
                                        var idPxl = charIDToTypeID( "#Pxl" );
                                        desc167.putUnitDouble( idTop, idPxl, 0.000000 );
                                        var idLeft = charIDToTypeID( "Left" );
                                        var idPxl = charIDToTypeID( "#Pxl" );
                                        desc167.putUnitDouble( idLeft, idPxl, 0.000000 );
                                        var idBtom = charIDToTypeID( "Btom" );
                                        var idPxl = charIDToTypeID( "#Pxl" );
                                        desc167.putUnitDouble( idBtom, idPxl, 1.000000 );
                                        var idRght = charIDToTypeID( "Rght" );
                                        var idPxl = charIDToTypeID( "#Pxl" );
                                        desc167.putUnitDouble( idRght, idPxl, 1.000000 );
                                        var idRctn = charIDToTypeID( "Rctn" );
                                        desc166.putObject( idT, idRctn, desc167 );
                                        executeAction( idsetd, desc166, DialogModes.NO );

                                    // Fill selected pixel black

                                        var idFl = charIDToTypeID( "Fl  " );
                                        var desc219 = new ActionDescriptor();
                                        var idUsng = charIDToTypeID( "Usng" );
                                        var idFlCn = charIDToTypeID( "FlCn" );
                                        var idBlck = charIDToTypeID( "Blck" );
                                        desc219.putEnumerated( idUsng, idFlCn, idBlck );
                                        var idOpct = charIDToTypeID( "Opct" );
                                        var idPrc = charIDToTypeID( "#Prc" );
                                        desc219.putUnitDouble( idOpct, idPrc, 100.000000 );
                                        var idMd = charIDToTypeID( "Md  " );
                                        var idBlnM = charIDToTypeID( "BlnM" );
                                        var idNrml = charIDToTypeID( "Nrml" );
                                        desc219.putEnumerated( idMd, idBlnM, idNrml );
                                        executeAction( idFl, desc219, DialogModes.NO );

                                    // Deselect

                                        deselect();

                                    // Select next top-left pixel

                                        var idsetd = charIDToTypeID( "setd" );
                                        var desc166 = new ActionDescriptor();
                                        var idnull = charIDToTypeID( "null" );
                                        var ref87 = new ActionReference();
                                        var idChnl = charIDToTypeID( "Chnl" );
                                        var idfsel = charIDToTypeID( "fsel" );
                                        ref87.putProperty( idChnl, idfsel );
                                        desc166.putReference( idnull, ref87 );
                                        var idT = charIDToTypeID( "T   " );
                                        var desc167 = new ActionDescriptor();
                                        var idTop = charIDToTypeID( "Top " );
                                        var idPxl = charIDToTypeID( "#Pxl" );
                                        desc167.putUnitDouble( idTop, idPxl, 0.000000 );
                                        var idLeft = charIDToTypeID( "Left" );
                                        var idPxl = charIDToTypeID( "#Pxl" );
                                        desc167.putUnitDouble( idLeft, idPxl, 1.000000 );
                                        var idBtom = charIDToTypeID( "Btom" );
                                        var idPxl = charIDToTypeID( "#Pxl" );
                                        desc167.putUnitDouble( idBtom, idPxl, 1.000000 );
                                        var idRght = charIDToTypeID( "Rght" );
                                        var idPxl = charIDToTypeID( "#Pxl" );
                                        desc167.putUnitDouble( idRght, idPxl, 2.000000 );
                                        var idRctn = charIDToTypeID( "Rctn" );
                                        desc166.putObject( idT, idRctn, desc167 );
                                        executeAction( idsetd, desc166, DialogModes.NO );

                                    // Fill selected pixel white

                                        var idFl = charIDToTypeID( "Fl  " );
                                        var desc228 = new ActionDescriptor();
                                        var idUsng = charIDToTypeID( "Usng" );
                                        var idFlCn = charIDToTypeID( "FlCn" );
                                        var idWht = charIDToTypeID( "Wht " );
                                        desc228.putEnumerated( idUsng, idFlCn, idWht );
                                        var idOpct = charIDToTypeID( "Opct" );
                                        var idPrc = charIDToTypeID( "#Prc" );
                                        desc228.putUnitDouble( idOpct, idPrc, 100.000000 );
                                        var idMd = charIDToTypeID( "Md  " );
                                        var idBlnM = charIDToTypeID( "BlnM" );
                                        var idNrml = charIDToTypeID( "Nrml" );
                                        desc228.putEnumerated( idMd, idBlnM, idNrml );
                                        executeAction( idFl, desc228, DialogModes.NO );

                                    // Deselect

                                        deselect();
                                };

                            // Zoom to fit

                                setZoom();

                            // Select move tool

                                selectMoveTool();
                    };

                // Crop to selection

                    function cropToSelection(){
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

        // Screen

            // Screen selection

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

                // Select active layer's thumbnail

                    function selectActiveLayersThumbnail(){
                        var idslct = charIDToTypeID( "slct" );
                        var desc1113 = new ActionDescriptor();
                        var idnull = charIDToTypeID( "null" );
                        var ref982 = new ActionReference();
                        var idChnl = charIDToTypeID( "Chnl" );
                        var idChnl = charIDToTypeID( "Chnl" );
                        var idRGB = charIDToTypeID( "RGB " );
                        ref982.putEnumerated( idChnl, idChnl, idRGB );
                        desc1113.putReference( idnull, ref982 );
                        var idMkVs = charIDToTypeID( "MkVs" );
                        desc1113.putBoolean( idMkVs, false );
                        executeAction( idslct, desc1113, DialogModes.NO );
                    }

                // Create selection from active layer's thumbnail

                    function createSelectionFromActiveLayersThubnail(){
                        var idsetd = charIDToTypeID( "setd" );
                        var desc134 = new ActionDescriptor();
                        var idnull = charIDToTypeID( "null" );
                        var ref63 = new ActionReference();
                        var idChnl = charIDToTypeID( "Chnl" );
                        var idfsel = charIDToTypeID( "fsel" );
                        ref63.putProperty( idChnl, idfsel );
                        desc134.putReference( idnull, ref63 );
                        var idT = charIDToTypeID( "T   " );
                        var ref64 = new ActionReference();
                        var idChnl = charIDToTypeID( "Chnl" );
                        var idChnl = charIDToTypeID( "Chnl" );
                        var idTrsp = charIDToTypeID( "Trsp" );
                        ref64.putEnumerated( idChnl, idChnl, idTrsp );
                        desc134.putReference( idT, ref64 );
                        executeAction( idsetd, desc134, DialogModes.NO );
                    };

                // Select active layer's transparency

                    function selectActiveLayersTransparency(){
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
                    }

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

                // Select active layer's layer mask

                    function selectActiveLayersLayerMask(){
                        try{
                            var idslct = charIDToTypeID( "slct" );
                            var desc1745 = new ActionDescriptor();
                            var idnull = charIDToTypeID( "null" );
                            var ref1488 = new ActionReference();
                            var idChnl = charIDToTypeID( "Chnl" );
                            var idChnl = charIDToTypeID( "Chnl" );
                            var idMsk = charIDToTypeID( "Msk " );
                            ref1488.putEnumerated( idChnl, idChnl, idMsk );
                            desc1745.putReference( idnull, ref1488 );
                            var idMkVs = charIDToTypeID( "MkVs" );
                            desc1745.putBoolean( idMkVs, false );
                            executeAction( idslct, desc1745, DialogModes.NO );
                        }catch(e){};
                    };

                // Create selection from active layer's layer mask

                    function createSelectionFromActiveLayersLayerMask(){
                        try{
                            // Test if mask exists

                                var hasLayerMask = false;

                                try{
                                    var ref = new ActionReference();
                                    var keyUserMaskEnabled = app.charIDToTypeID('UsrM');
                                    ref.putProperty(app.charIDToTypeID( 'Prpr' ), keyUserMaskEnabled );
                                    ref.putEnumerated(app.charIDToTypeID('Lyr '), app.charIDToTypeID('Ordn'), app.charIDToTypeID('Trgt'));

                                    var desc = executeActionGet(ref);

                                    if(desc.hasKey(keyUserMaskEnabled)){
                                        hasLayerMask = true;
                                    }
                                }catch(e){
                                    hasLayerMask = false;
                                }

                            // Select mask if it exists

                                if(hasLayerMask == true){
                                    selectActiveLayersLayerMask();

                                    var idsetd = charIDToTypeID( "setd" );
                                    var desc1116 = new ActionDescriptor();
                                    var idnull = charIDToTypeID( "null" );
                                    var ref985 = new ActionReference();
                                    var idChnl = charIDToTypeID( "Chnl" );
                                    var idfsel = charIDToTypeID( "fsel" );
                                    ref985.putProperty( idChnl, idfsel );
                                    desc1116.putReference( idnull, ref985 );
                                    var idT = charIDToTypeID( "T   " );
                                    var ref986 = new ActionReference();
                                    var idChnl = charIDToTypeID( "Chnl" );
                                    var idOrdn = charIDToTypeID( "Ordn" );
                                    var idTrgt = charIDToTypeID( "Trgt" );
                                    ref986.putEnumerated( idChnl, idOrdn, idTrgt );
                                    desc1116.putReference( idT, ref986 );
                                    executeAction( idsetd, desc1116, DialogModes.NO );
                                };
                        }catch(e){};
                    };

                // Add selection from active layer's layer mask to selection

                    function addSelectionFromActiveLayersLayerMaskToSelection(){
                        try{
                            // Test if mask exists

                                var hasLayerMask = false;

                                try{
                                    var ref = new ActionReference();
                                    var keyUserMaskEnabled = app.charIDToTypeID('UsrM');
                                    ref.putProperty(app.charIDToTypeID( 'Prpr' ), keyUserMaskEnabled );
                                    ref.putEnumerated(app.charIDToTypeID('Lyr '), app.charIDToTypeID('Ordn'), app.charIDToTypeID('Trgt'));

                                    var desc = executeActionGet(ref);

                                    if(desc.hasKey(keyUserMaskEnabled)){
                                        hasLayerMask = true;
                                    }
                                }catch(e){
                                    hasLayerMask = false;
                                }

                            // Select mask if it exists

                                if(hasLayerMask == true){
                                    selectActiveLayersLayerMask();

                                    try{
                                        var idAdd = charIDToTypeID( "Add " );
                                        var desc467 = new ActionDescriptor();
                                        var idnull = charIDToTypeID( "null" );
                                        var ref189 = new ActionReference();
                                        var idChnl = charIDToTypeID( "Chnl" );
                                        var idOrdn = charIDToTypeID( "Ordn" );
                                        var idTrgt = charIDToTypeID( "Trgt" );
                                        ref189.putEnumerated( idChnl, idOrdn, idTrgt );
                                        desc467.putReference( idnull, ref189 );
                                        var idT = charIDToTypeID( "T   " );
                                        var ref190 = new ActionReference();
                                        var idChnl = charIDToTypeID( "Chnl" );
                                        var idfsel = charIDToTypeID( "fsel" );
                                        ref190.putProperty( idChnl, idfsel );
                                        desc467.putReference( idT, ref190 );
                                        executeAction( idAdd, desc467, DialogModes.NO );
                                    }catch(e){
                                        var idsetd = charIDToTypeID( "setd" );
                                        var desc1116 = new ActionDescriptor();
                                        var idnull = charIDToTypeID( "null" );
                                        var ref985 = new ActionReference();
                                        var idChnl = charIDToTypeID( "Chnl" );
                                        var idfsel = charIDToTypeID( "fsel" );
                                        ref985.putProperty( idChnl, idfsel );
                                        desc1116.putReference( idnull, ref985 );
                                        var idT = charIDToTypeID( "T   " );
                                        var ref986 = new ActionReference();
                                        var idChnl = charIDToTypeID( "Chnl" );
                                        var idOrdn = charIDToTypeID( "Ordn" );
                                        var idTrgt = charIDToTypeID( "Trgt" );
                                        ref986.putEnumerated( idChnl, idOrdn, idTrgt );
                                        desc1116.putReference( idT, ref986 );
                                        executeAction( idsetd, desc1116, DialogModes.NO );
                                    }
                                };
                        }catch(e){};
                    };

                // Intersect current selection with active layer's layer mask

                    function intersectCurrentSelectionWithActiveLayersLayerMask(){
                        selectActiveLayersLayerMask();

                        var idIntr = charIDToTypeID( "Intr" );
                        var desc584 = new ActionDescriptor();
                        var idnull = charIDToTypeID( "null" );
                        var ref242 = new ActionReference();
                        var idChnl = charIDToTypeID( "Chnl" );
                        var idOrdn = charIDToTypeID( "Ordn" );
                        var idTrgt = charIDToTypeID( "Trgt" );
                        ref242.putEnumerated( idChnl, idOrdn, idTrgt );
                        desc584.putReference( idnull, ref242 );
                        var idWith = charIDToTypeID( "With" );
                        var ref243 = new ActionReference();
                        var idChnl = charIDToTypeID( "Chnl" );
                        var idfsel = charIDToTypeID( "fsel" );
                        ref243.putProperty( idChnl, idfsel );
                        desc584.putReference( idWith, ref243 );
                        executeAction( idIntr, desc584, DialogModes.NO );
                    };

                // Select all rgb on screen

                    function selectAllRGBOnScreen(){
                        var idsetd = charIDToTypeID( "setd" );
                        var desc1071 = new ActionDescriptor();
                        var idnull = charIDToTypeID( "null" );
                        var ref856 = new ActionReference();
                        var idChnl = charIDToTypeID( "Chnl" );
                        var idfsel = charIDToTypeID( "fsel" );
                        ref856.putProperty( idChnl, idfsel );
                        desc1071.putReference( idnull, ref856 );
                        var idT = charIDToTypeID( "T   " );
                        var ref857 = new ActionReference();
                        var idChnl = charIDToTypeID( "Chnl" );
                        var idChnl = charIDToTypeID( "Chnl" );
                        var idRGB = charIDToTypeID( "RGB " );
                        ref857.putEnumerated( idChnl, idChnl, idRGB );
                        desc1071.putReference( idT, ref857 );
                        executeAction( idsetd, desc1071, DialogModes.NO );
                    };

                // Invert selection

                    function invertSelection(){
                        try{
                            var idInvs = charIDToTypeID( "Invs" );
                            executeAction( idInvs, undefined, DialogModes.NO );
                        }catch(e){}
                    };

            // Screen modification

                // Set Zoom

                    function setZoom(zoom){
                        runMenuItem(app.charIDToTypeID("FtOn"))

                        runMenuItem(app.charIDToTypeID("ZmOt"))

                        runMenuItem(app.charIDToTypeID("ZmOt"))
                    };

        // Custom

            // Make contents of border group opaque

                function makeContentsOfBorderGroupOpaque(){
                    // Variables etc

                        var docName = app.activeDocument.name;
                        var word16b = new RegExp (/16b/gim);

                    try{
                        if(word16b.test(docName) && app.activeDocument.layers.getByName("Border Group").layers.length > 0){
                            // Select Border Group
                                app.activeDocument.activeLayer = app.activeDocument.layers.getByName("Border Group");

                            // Flatten
                                var idMrgtwo = charIDToTypeID( "Mrg2" );
                                executeAction( idMrgtwo, undefined, DialogModes.NO );

                            // Rename to Border
                                app.activeDocument.activeLayer.name = "Border";

                            // Group and name group

                                groupActiveLayers();

                                app.activeDocument.activeLayer.name = "Border Group";

                            // Select contents
                                app.activeDocument.activeLayer = app.activeDocument.layers.getByName("Border Group").layers.getByName("Border");

                            // Duplicate and merge x 25

                                for(var i = 0; i < 25; i++){
                                    duplicateAndMerge();
                                };
                        };
                    }catch(e){};
                };

                // Make contents of border group opaque scripts

                    function duplicateAndMerge(){
                        app.activeDocument.activeLayer.duplicate().name = "Border Copy"

                        app.activeDocument.activeLayer = app.activeDocument.layers.getByName("Border Group").layers.getByName("Border Copy");

                        var idMrgtwo = charIDToTypeID( "Mrg2" );
                        executeAction( idMrgtwo, undefined, DialogModes.NO );

                        app.activeDocument.activeLayer.name = "Border"
                    };

            // Collapse groups

                // Collapse all groups

                    function collapseAllGroups(){
                        // Collapse world normals group

                            var layerName = "World Normals Group"

                            try{
                                collapseGroup(layerName, app.activeDocument.layers.getByName(layerName), "blendingMode", "green", "0", "fill");
                            }catch(e){};

                        // Collapse alpha group

                            var layerName = "Alpha Group"

                            try{
                                collapseGroup(layerName, app.activeDocument.layers.getByName(layerName), "blendingMode", "blue", "0", "fill");
                            }catch(e){};

                        // Collapse Border group

                            var layerName = "Border Group"

                            try{
                                collapseGroup(layerName, app.activeDocument.layers.getByName(layerName), "blendingMode", "none", "opacity", "fill");
                            }catch(e){};

                        // Collapse Adjustments group

                            var layerName = "Adjustments Group"

                            try{
                                collapseGroup(layerName, app.activeDocument.layers.getByName(layerName), "blendingMode", "none", "opacity", "fill");
                            }catch(e){};

                        // Collapse Overall Adjustments group

                            var layerName = "Overall Adjustments Group";

                            try{
                                collapseGroup(layerName, app.activeDocument.layers.getByName(layerName), "blendingMode", "none", "opacity", "fill");
                            }catch(e){};

                        // Collapse Overlay group

                            var layerName = "Overlay Group";

                            try{
                                collapseGroup(layerName, app.activeDocument.layers.getByName(layerName), "blendingMode", "none", "opacity", "fill");
                            }catch(e){};

                        // Collapse Total Lighting group

                            var layerName = "Total Lighting Group"

                            try{
                                collapseGroup(layerName, app.activeDocument.layers.getByName(layerName), "linearDodge", "none", "opacity", "fill");
                            }catch(e){};

                        // Collapse Reflection group

                            var layerName = "Reflection Group"

                            try{
                                collapseGroup(layerName, app.activeDocument.layers.getByName(layerName), "linearDodge", "none", "opacity", "fill");
                            }catch(e){};

                        // Collapse Refraction group

                            var layerName = "Refraction Group"

                            try{
                                collapseGroup(layerName, app.activeDocument.layers.getByName(layerName), "linearDodge", "none", "opacity", "fill");
                            }catch(e){};

                        // Collapse Specular group

                            var layerName = "Specular Group"

                            try{
                                collapseGroup(layerName, app.activeDocument.layers.getByName(layerName), "linearDodge", "none", "opacity", "fill");
                            }catch(e){};

                        // Collapse Background group

                            var layerName = "Background Group"

                            try{
                                collapseGroup(layerName, app.activeDocument.layers.getByName(layerName), "linearDodge", "none", "opacity", "fill");
                            }catch(e){};

                        // Collapse Original Image group

                            var layerName = "Original Image Group";

                            try{
                                collapseGroup(layerName, app.activeDocument.layers.getByName(layerName), "blendingMode", "none", "opacity", "fill");
                            }catch(e){};

                        // Select top layerset

                            app.activeDocument.activeLayer = app.activeDocument.layers[0]

                        // Collapse multimatte group

                            var layerName = "Multimatte";

                            try{
                                collapseGroup(layerName, app.activeDocument.layers.getByName(layerName), "blendingMode", "red", "0", "fill");
                            }catch(e){};
                    };

                // Collapse group

                    function collapseGroup(groupName, groupLocation, blendingMode, colour, opacity, fill){
                        if(groupLocation.layers.length > 1){
                            // Ungroup Multimatte layers

                                // Select relevant group

                                    app.activeDocument.activeLayer = groupLocation;

                                // Ungroup

                                    ungroupActiveGroup();

                            // Regroup

                                // Regroup

                                    groupActiveLayers();

                                // Name group

                                    app.activeDocument.activeLayer.name = groupName;

                                // Set blending mode

                                    if (blendingMode == "linearDodge"){
                                        setActiveLayerBlendingModeToLinearDodge();
                                    };

                                    if (blendingMode == "multiply"){
                                        setActiveLayerBlendingModeToMultiply();
                                    };

                                    if (blendingMode == "overlay"){
                                        setActiveLayerBlendingModeToOverlay();
                                    };

                                // Set colour

                                    if (colour == "none"){
                                        setLayerColourToNone();
                                    };

                                    if (colour == "red"){
                                        setLayerColourToRed();
                                    };

                                    if (colour == "green"){
                                        setLayerColourToGreen();
                                    };

                                    if (colour == "blue"){
                                        setLayerColourToBlue();
                                    };

                                // Set opacity

                                    if (opacity == "0"){
                                        // Set opacity to 0%

                                            makeActiveLayersOpacityZero();
                                    };

                                // Set fill

                                    if (fill == "15"){
                                        // Make active layer's fill 15

                                            makeActiveLayersFillFifteen();
                                    };
                        }else{
                            // Select group

                                app.activeDocument.activeLayer = groupLocation;

                            // Set colour

                                if (colour == "none"){
                                    setLayerColourToNone();
                                };

                                if (colour == "red"){
                                    setLayerColourToRed();
                                };

                                if (colour == "green"){
                                    setLayerColourToGreen();
                                };

                                if (colour == "blue"){
                                    setLayerColourToBlue();
                                };
                        };
                    };

        // Tools

            // Select move tool

                function selectMoveTool(){
                    try{
                        var idslct = charIDToTypeID( "slct" );
                        var desc461 = new ActionDescriptor();
                        var idnull = charIDToTypeID( "null" );
                        var ref75 = new ActionReference();
                        var idmoveTool = stringIDToTypeID( "moveTool" );
                        ref75.putClass( idmoveTool );
                        desc461.putReference( idnull, ref75 );
                        var iddontRecord = stringIDToTypeID( "dontRecord" );
                        desc461.putBoolean( iddontRecord, true );
                        var idforceNotify = stringIDToTypeID( "forceNotify" );
                        desc461.putBoolean( idforceNotify, true );
                        executeAction( idslct, desc461, DialogModes.NO );
                    }catch(e){};
                };

            // Select brush tool

                function selectBrushTool(){
                    var idslct = charIDToTypeID( "slct" );
                    var desc185 = new ActionDescriptor();
                    var idnull = charIDToTypeID( "null" );
                    var ref48 = new ActionReference();
                    var idPbTl = charIDToTypeID( "PbTl" );
                    ref48.putClass( idPbTl );
                    desc185.putReference( idnull, ref48 );
                    executeAction( idslct, desc185, DialogModes.NO );
                };

            // Select brush tool and set brush colour to white and black

                function selectBrushToolAndSetToWhiteAndBlack(){
                    // Select brush tool

                        var idslct = charIDToTypeID( "slct" );
                        var desc185 = new ActionDescriptor();
                        var idnull = charIDToTypeID( "null" );
                        var ref48 = new ActionReference();
                        var idPbTl = charIDToTypeID( "PbTl" );
                        ref48.putClass( idPbTl );
                        desc185.putReference( idnull, ref48 );
                        executeAction( idslct, desc185, DialogModes.NO );

                    // Set colours to default

                        var idRset = charIDToTypeID( "Rset" );
                        var desc186 = new ActionDescriptor();
                        var idnull = charIDToTypeID( "null" );
                        var ref49 = new ActionReference();
                        var idClr = charIDToTypeID( "Clr " );
                        var idClrs = charIDToTypeID( "Clrs" );
                        ref49.putProperty( idClr, idClrs );
                        desc186.putReference( idnull, ref49 );
                        executeAction( idRset, desc186, DialogModes.NO );

                    // Set colour to white

                        var idsetd = charIDToTypeID( "setd" );
                        var desc177 = new ActionDescriptor();
                        var idnull = charIDToTypeID( "null" );
                        var ref45 = new ActionReference();
                        var idClr = charIDToTypeID( "Clr " );
                        var idFrgC = charIDToTypeID( "FrgC" );
                        ref45.putProperty( idClr, idFrgC );
                        desc177.putReference( idnull, ref45 );
                        var idT = charIDToTypeID( "T   " );
                        var desc178 = new ActionDescriptor();
                        var idH = charIDToTypeID( "H   " );
                        var idAng = charIDToTypeID( "#Ang" );
                        desc178.putUnitDouble( idH, idAng, 0.000000 );
                        var idStrt = charIDToTypeID( "Strt" );
                        desc178.putDouble( idStrt, 0.000000 );
                        var idBrgh = charIDToTypeID( "Brgh" );
                        desc178.putDouble( idBrgh, 100.000000 );
                        var idHSBC = charIDToTypeID( "HSBC" );
                        desc177.putObject( idT, idHSBC, desc178 );
                        var idSrce = charIDToTypeID( "Srce" );
                        desc177.putString( idSrce, """photoshopPicker""" );
                        executeAction( idsetd, desc177, DialogModes.NO );
                };

    // Time

        /*
        totalTime.stop();

        // log it out

        totalTime.getTime();

        function TimeIt() {

          // member variables

          this.startTime = new Date();

          this.endTime = new Date();



          // member functions



          // reset the start time to now

          this.start = function () {

                this.startTime = new Date();

            }



          // reset the end time to now

          this.stop = function () {

                this.endTime = new Date();

            }



          // get the difference in milliseconds between start and stop

          this.getTime = function () {

                alert ((this.endTime.getTime() - this.startTime.getTime()) / 1000).toString();

            }



          // get the current elapsed time from start to now, this sets the endTime

          this.getElapsed = function () {

                this.endTime = new Date(); return this.getTime();

            }
        };
        */
