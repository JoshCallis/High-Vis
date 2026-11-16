// Run the script

    try{
        var idPlc = charIDToTypeID( "Plc " );
        var desc11 = new ActionDescriptor();
        var idnull = charIDToTypeID( "null" );

        var selectedFile = app.openDialog();

        desc11.putPath( idnull, new File(selectedFile) );
        var idFTcs = charIDToTypeID( "FTcs" );
        var idQCSt = charIDToTypeID( "QCSt" );
        var idQcsa = charIDToTypeID( "Qcsa" );
        desc11.putEnumerated( idFTcs, idQCSt, idQcsa );
        var idOfst = charIDToTypeID( "Ofst" );
        var desc12 = new ActionDescriptor();
        var idHrzn = charIDToTypeID( "Hrzn" );
        var idPxl = charIDToTypeID( "#Pxl" );
        desc12.putUnitDouble( idHrzn, idPxl, 0.000000 );
        var idVrtc = charIDToTypeID( "Vrtc" );
        var idPxl = charIDToTypeID( "#Pxl" );
        desc12.putUnitDouble( idVrtc, idPxl, 0.000000 );
        var idOfst = charIDToTypeID( "Ofst" );
        desc11.putObject( idOfst, idOfst, desc12 );
        executeAction( idPlc, desc11, DialogModes.NO );

        app.activeDocument.activeLayer.move(app.activeDocument.layers.getByName("Overall Adjustments Group").layerSets.getByName("Entourage").layerSets.getByName("Entourage"), ElementPlacement.INSIDE);

        var currentLayer = app.activeDocument.activeLayer;

        app.activeDocument.artLayers.add().name = "Reflection Dummy";

        app.activeDocument.activeLayer = app.activeDocument.layers.getByName("Reflection Dummy");

        app.activeDocument.activeLayer.move(currentLayer, ElementPlacement.PLACEBEFORE);

        groupActiveLayers();

        app.activeDocument.activeLayer.name = "Reflection"

        setActiveLayerBlendingModeToNormal();

        app.activeDocument.activeLayer.artLayers[0].remove();

        groupActiveLayers();

        setActiveLayerBlendingModeToNormal();

        // Rename active layer

            app.activeDocument.activeLayer.name = "Main Object Dummy";

        // Move object layer into main object layer

            app.activeDocument.activeLayer = currentLayer

            currentLayer.move(app.activeDocument.layerSets.getByName("Overall Adjustments Group").layerSets.getByName("Entourage").layerSets.getByName("Entourage").layerSets.getByName("Main Object Dummy"), ElementPlacement.INSIDE);

            groupActiveLayers();

            app.activeDocument.activeLayer.name = "Object";

            setActiveLayerBlendingModeToNormal();

        // Select object

            app.activeDocument.activeLayer = app.activeDocument.activeLayer.layers[0];

        // Rename main object layer

            app.activeDocument.layerSets.getByName("Overall Adjustments Group").layerSets.getByName("Entourage").layerSets.getByName("Entourage").layerSets.getByName("Main Object Dummy").name = app.activeDocument.activeLayer.name;
    }catch(e){};

// Functions

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

                            // Zoom to fit

                                setZoom();

                            // Select move tool

                                selectMoveTool();
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

                                duplicateAndMerge();
                                duplicateAndMerge();
                                duplicateAndMerge();
                                duplicateAndMerge();
                                duplicateAndMerge();
                                duplicateAndMerge();
                                duplicateAndMerge();
                                duplicateAndMerge();
                                duplicateAndMerge();
                                duplicateAndMerge();
                                duplicateAndMerge();
                                duplicateAndMerge();
                                duplicateAndMerge();
                                duplicateAndMerge();
                                duplicateAndMerge();
                                duplicateAndMerge();
                                duplicateAndMerge();
                                duplicateAndMerge();
                                duplicateAndMerge();
                                duplicateAndMerge();
                                duplicateAndMerge();
                                duplicateAndMerge();
                                duplicateAndMerge();
                                duplicateAndMerge();
                                duplicateAndMerge();
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
