
// Variables etc

    var myName = "H"
    var myName2 = "initialPrompt"

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
