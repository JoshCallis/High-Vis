// Loop through all folders in the root folder and find the folder for the current frame number

    // Variables etc

        var rootPath = "C:\\Callis Scripts\\Metadata"
        var targetLayers = new Array;
        var subDirectory = "/LinkedLayers/";
        var configFolder = Folder(rootPath);
        var fileList = configFolder.getFiles();
        var tempPreliminary2 = fileList[0].toString().replace(/%20/g, " ")
        var tempPreliminary = tempPreliminary2.replace(/\\/g, "/")
        var temp9 = tempPreliminary.replace(/xxslashxx/gi, "/").replace(/xxcolonxx/gi, ":")
        var temp = temp9.split("dialogOutputFolderSpacer")[temp9.split("dialogOutputFolderSpacer").length - 1];

// Variables etc

    var myName = temp
    var myName2 = "rootFolderPath"

// Main script

    app.activeDocument.artLayers.add().name = myName

    app.activeDocument.activeLayer = app.activeDocument.artLayers.getByName(myName)

    groupActiveLayers();

    app.activeDocument.activeLayer.name = myName2

// Functions

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
