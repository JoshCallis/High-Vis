// General variables

    var me = "Adjustments"

// Run the script

    createAllAdjustmentsGroups();

// Functions

    // Create All Adjustments Groups

        function createAllAdjustmentsGroups(){
            // Do for selected layers

                // Do for selected layers setup 1

                    function cID (inVal) { return charIDToTypeID(inVal);}
                    function sID (inVal) { return stringIDToTypeID(inVal);}

                    OpenOptionsDialog = new Window("dialog");

                    mainGroup = OpenOptionsDialog.add("group");

                // Run the script

                    var SelectedLayers = getSelectedLayers();

                    if(SelectedLayers.length == 2){
                        // Prompt for inverse
                            var promptForInverse = prompt("Input I for inverse adjustment, or any other key for regular adjustment", "");

                            try{
                                if(promptForInverse == "i" || promptForInverse == "I"){
                                    var ifInverse = "true";
                                }else{
                                    var ifInverse = "false";
                                };
                            }catch(e){
                                var ifInverse = "false";
                            };

                        // Create groupLocation1 variable

                            try{
                                app.activeDocument.artLayers.add().name = "Adjustment Script Dummy";

                                app.activeDocument.layers.getByName("Adjustment Script Dummy").move(SelectedLayers[1], ElementPlacement.INSIDE)

                                SelectedLayers[1].layers.getByName("Adjustment Script Dummy").remove();

                                var groupLocation1 = SelectedLayers[1];
                            }catch(e){
                                var groupLocation1 = SelectedLayers[1].parent;
                            };

                        // Remove dummy if still present (need to fix actual problem at some point)

                            try{
                                app.activeDocument.layers.getByName("Adjustment Script Dummy").remove();
                            }catch(e){};
                    };

                    if(SelectedLayers.length == 1){
                        // General variables

                            var me = "Adjustments"

                        // Variables etc

                            var word16b = new RegExp (/16b/gim);

                        // Decide what to do based on document's bit depth

                            if(word16b.test(app.activeDocument.name)){
                                // Prompt

                                    var promptForInverse = prompt("Input I for inverse adjustment, or any other key for regular adjustment", "");

                                try{
                                    if(promptForInverse == "i" || promptForInverse == "I"){
                                        var ifInverse = "true";
                                    }else{
                                        var ifInverse = "false";
                                    };
                                }catch(e){
                                    var ifInverse = "false";
                                };

                                if(promptForInverse == null || promptForInverse == ""){
                                    var groupLocation1 = "noString";
                                }else{
                                    var groupLocation1 = app.activeDocument.layers.getByName("Overall Adjustments Group");
                                };
                            }else{
                                // Prompt

                                    var tess = prompt("A: Overall Adjustments, B: Background, D: Diffuse G: GI \nL: Raw Lighting, W: Raw Reflection, R: Raw Refraction, \nE: Reflection Filter, T: Refraction Filter X: Specular, S: Sun", "");

                                try{
                                    if(tess.toString().substring(0, 1) == "a" || tess.toString().substring(0, 1) == "A"){
                                        var groupLocation1 = app.activeDocument.layers.getByName("Overall Adjustments Group");
                                    };
                                }catch(e){};

                                try{
                                    if(tess.toString().substring(0, 1) == "b" || tess.toString().substring(0, 1) == "B"){
                                        var groupLocation1 = app.activeDocument.layers.getByName("Background Group");
                                    };
                                }catch(e){};

                                try{
                                    if(tess.toString().substring(0, 1) == "d" || tess.toString().substring(0, 1) == "D"){
                                        var groupLocation1 = app.activeDocument.layers.getByName("Total Lighting Group").layers.getByName("Diffuse Group");
                                    };
                                }catch(e){};

                                try{
                                    if(tess.toString().substring(0, 1) == "g" || tess.toString().substring(0, 1) == "G"){
                                        var groupLocation1 = app.activeDocument.layers.getByName("Total Lighting Group").layers.getByName("Raw GI Group");
                                    };
                                }catch(e){};

                                try{
                                    if(tess.toString().substring(0, 1) == "l" || tess.toString().substring(0, 1) == "L"){
                                        var groupLocation1 = app.activeDocument.layers.getByName("Total Lighting Group").layers.getByName("Raw Lighting Group");
                                    };
                                }catch(e){};

                                try{
                                    if(tess.toString().substring(0, 1) == "w" || tess.toString().substring(0, 1) == "W"){
                                        var groupLocation1 = app.activeDocument.layers.getByName("Reflection Group").layers.getByName("Raw Reflection Group");
                                    };
                                }catch(e){};

                                try{
                                    if(tess.toString().substring(0, 1) == "e" || tess.toString().substring(0, 1) == "E"){
                                        var groupLocation1 = app.activeDocument.layers.getByName("Refraction Group").layers.getByName("Raw Refraction Group");
                                    };
                                }catch(e){};

                                try{
                                    if(tess.toString().substring(0, 1) == "r" || tess.toString().substring(0, 1) == "R"){
                                        var groupLocation1 = app.activeDocument.layers.getByName("Reflection Group").layers.getByName("Reflection Filter Group");
                                    };
                                }catch(e){};

                                try{
                                    if(tess.toString().substring(0, 1) == "t" || tess.toString().substring(0, 1) == "T"){
                                        var groupLocation1 = app.activeDocument.layers.getByName("Refraction Group").layers.getByName("Refraction Filter Group");
                                    };
                                }catch(e){};

                                try{
                                    if(tess.toString().substring(0, 1) == "x" || tess.toString().substring(0, 1) == "X"){
                                        var groupLocation1 = app.activeDocument.layers.getByName("Specular Group");
                                    };
                                }catch(e){};

                                try{
                                    if(tess.toString().substring(0, 1) == "s" || tess.toString().substring(0, 1) == "S"){
                                        var groupLocation1 = app.activeDocument.layers.getByName("Total Lighting Group").layers.getByName("Sun Group");
                                    };
                                }catch(e){};

                                if(tess == null || tess == ""){
                                    var groupLocation1 = "noString";
                                };

                                try{
                                    if(tess.toString().length > 1){
                                        if(tess.toString().substring(1, 2) == "i" || tess.toString().substring(1, 2) == "I"){
                                            var ifInverse = "true";
                                        }else{
                                            var ifInverse = "false";
                                        };
                                    }else{
                                        var ifInverse = "false";
                                    };
                                }catch(e){
                                    var ifInverse = "false";
                                };
                            };
                    };

                // Do for selected layers setup 2

                    OpenOptionsDialog.close()

                    var result = OpenOptionsDialog.hide();

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

            // Make Selection Layer active

                app.activeDocument.activeLayer = SelectedLayers[0];

            // Run the script

                createAdjustmentsGroup(groupLocation1, "adjustments", ifInverse);
        };

        // Create adjustments group

            function createAdjustmentsGroup(groupLocation, targetAdjustment, ifInverse){
                // Return if wrong keyboard entry

                    if (groupLocation == "noString"){
                        return;
                    };

                // Throw error and return if group doesn't exist

                    if(groupLocation == null){
                        alert("The specified group doesn't exist");

                        return;
                    };

                // Main

                    if(groupLocation.visible == true){
                        // Parent layer name to string

                            var activeLayersParentNameToString = app.activeDocument.activeLayer.parent.name.toString();

                        // Change "copy" to "duplicate" if necessary

                            if(app.activeDocument.activeLayer.testREGEXPENDINGINCOPY){
                                app.activeDocument.activeLayer.name = app.activeDocument.activeLayer.name.split(" copy")[0] + " Duplicate";
                            };

                        // To String

                            if(ifInverse == "true"){
                                var activeLayerNameToString = "Inverse " + app.activeDocument.activeLayer.name.toString();
                            }else{
                                var activeLayerNameToString = app.activeDocument.activeLayer.name.toString();
                            };

                        // If adjustment group already exists...

                            if(doesLayerExist(groupLocation, activeLayerNameToString + " " + targetAdjustment)){

                                // Collapse selection groups

                                    // Collapse multimatte group

                                        var layerName = "Multimatte";

                                        try{
                                            collapseGroup(layerName, app.activeDocument.layers.getByName(layerName), "blendingMode", "red", "0", "fill");
                                        }catch(e){};

                                // Select relevant adj layer

                                    app.activeDocument.activeLayer = groupLocation.layers.getByName(activeLayerNameToString + " " + targetAdjustment);

                                    // Select bottom layer of group, or make one if group is empty

                                        try{
                                            app.activeDocument.activeLayer = app.activeDocument.activeLayer.layers[app.activeDocument.activeLayer.layers.length - 1];
                                        }catch(e){
                                            // Create adjustment layer

                                                var name16b = new RegExp(/16b/gim);

                                                if(name16b.test(app.activeDocument.name)){
                                                    createAdjustmentsLayerLevels(app.activeDocument.activeLayer.name.split(" " + targetAdjustment)[0] + " levels");
                                                }else{
                                                    createAdjustmentsLayerExposure();

                                                    app.activeDocument.activeLayer.name = app.activeDocument.activeLayer.parent.name.split(" " + targetAdjustment)[0] + " exposure";
                                                };
                                        };

                        // Else...

                            }else{
                                // Select layer's transparency

                                    var idsetd = charIDToTypeID( "setd" );
                                    var desc1298 = new ActionDescriptor();
                                    var idnull = charIDToTypeID( "null" );
                                    var ref963 = new ActionReference();
                                    var idChnl = charIDToTypeID( "Chnl" );
                                    var idfsel = charIDToTypeID( "fsel" );
                                    ref963.putProperty( idChnl, idfsel );
                                    desc1298.putReference( idnull, ref963 );
                                    var idT = charIDToTypeID( "T   " );
                                    var ref964 = new ActionReference();
                                    var idChnl = charIDToTypeID( "Chnl" );
                                    var idChnl = charIDToTypeID( "Chnl" );
                                    var idTrsp = charIDToTypeID( "Trsp" );
                                    ref964.putEnumerated( idChnl, idChnl, idTrsp );
                                    desc1298.putReference( idT, ref964 );
                                    executeAction( idsetd, desc1298, DialogModes.NO );

                                // Invert Selection if inverse

                                    if(ifInverse == "true"){
                                        var idInvs = charIDToTypeID( "Invs" );
                                        executeAction( idInvs, undefined, DialogModes.NO );
                                    };

                                // Collapse selection groups

                                    // Collapse multimatte group

                                        var layerName = "Multimatte";

                                        try{
                                            collapseGroup(layerName, app.activeDocument.layers.getByName(layerName), "blendingMode", "red", "0", "fill");
                                        }catch(e){};

                                // Create layer in relevant location

                                    app.activeDocument.artLayers.add().move(groupLocation, ElementPlacement.INSIDE);

                                    groupActiveLayers();

                                    app.activeDocument.activeLayer.name = activeLayerNameToString + " " + targetAdjustment;

                                    app.activeDocument.activeLayer.layers[0].remove();

                                // Mask layerset

                                    var idMk = charIDToTypeID( "Mk  " );
                                    var desc367 = new ActionDescriptor();
                                    var idNw = charIDToTypeID( "Nw  " );
                                    var idChnl = charIDToTypeID( "Chnl" );
                                    desc367.putClass( idNw, idChnl );
                                    var idAt = charIDToTypeID( "At  " );
                                    var ref266 = new ActionReference();
                                    var idChnl = charIDToTypeID( "Chnl" );
                                    var idChnl = charIDToTypeID( "Chnl" );
                                    var idMsk = charIDToTypeID( "Msk " );
                                    ref266.putEnumerated( idChnl, idChnl, idMsk );
                                    desc367.putReference( idAt, ref266 );
                                    var idUsng = charIDToTypeID( "Usng" );
                                    var idUsrM = charIDToTypeID( "UsrM" );
                                    var idRvlS = charIDToTypeID( "RvlS" );
                                    desc367.putEnumerated( idUsng, idUsrM, idRvlS );
                                    executeAction( idMk, desc367, DialogModes.NO );

                                // Create adjustment layer

                                    var name16b = new RegExp(/16b/gim);

                                    if(name16b.test(app.activeDocument.name)){
                                        createAdjustmentsLayerLevels(app.activeDocument.activeLayer.name.split(" " + targetAdjustment)[0] + " levels");
                                    }else{
                                        createAdjustmentsLayerExposure();

                                        app.activeDocument.activeLayer.name = app.activeDocument.activeLayer.parent.name.split(" " + targetAdjustment)[0] + " exposure";
                                    };

                                // Ensure Multimatte group is visible

                                    app.activeDocument.layers.getByName("Multimatte").visible = true;
                            };
                    }else{
                        alert("Targeted group is currently hidden");
                    };
            };

    // General

        // Test if specified layer exists

            function doesLayerExist(groupToSearchThrough, nameToFind) {
                for (i=0; i<groupToSearchThrough.layers.length; i++) {
                    if (groupToSearchThrough.layers[i].name == nameToFind) return true;
                };
                return false;
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

        // Delete active layer's layer mask if selected

            function deleteActiveLayersLayerMaskIfSelected(){
                try{
                    var idDlt = charIDToTypeID( "Dlt " );
                    var desc1746 = new ActionDescriptor();
                    var idnull = charIDToTypeID( "null" );
                    var ref1489 = new ActionReference();
                    var idChnl = charIDToTypeID( "Chnl" );
                    var idOrdn = charIDToTypeID( "Ordn" );
                    var idTrgt = charIDToTypeID( "Trgt" );
                    ref1489.putEnumerated( idChnl, idOrdn, idTrgt );
                    desc1746.putReference( idnull, ref1489 );
                    executeAction( idDlt, desc1746, DialogModes.NO );
                }catch(e){};
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

                function createAdjustmentsLayerExposure(){
                    var idMk = charIDToTypeID( "Mk  " );
                    var desc335 = new ActionDescriptor();
                    var idnull = charIDToTypeID( "null" );
                    var ref242 = new ActionReference();
                    var idAdjL = charIDToTypeID( "AdjL" );
                    ref242.putClass( idAdjL );
                    desc335.putReference( idnull, ref242 );
                    var idUsng = charIDToTypeID( "Usng" );
                    var desc336 = new ActionDescriptor();
                    var idType = charIDToTypeID( "Type" );
                    var desc337 = new ActionDescriptor();
                    var idpresetKind = stringIDToTypeID( "presetKind" );
                    var idpresetKindType = stringIDToTypeID( "presetKindType" );
                    var idpresetKindDefault = stringIDToTypeID( "presetKindDefault" );
                    desc337.putEnumerated( idpresetKind, idpresetKindType, idpresetKindDefault );
                    var idExps = charIDToTypeID( "Exps" );
                    desc337.putDouble( idExps, 0.000000 );
                    var idOfst = charIDToTypeID( "Ofst" );
                    desc337.putDouble( idOfst, 0.000000 );
                    var idgammaCorrection = stringIDToTypeID( "gammaCorrection" );
                    desc337.putDouble( idgammaCorrection, 1.000000 );
                    var idExps = charIDToTypeID( "Exps" );
                    desc336.putObject( idType, idExps, desc337 );
                    var idAdjL = charIDToTypeID( "AdjL" );
                    desc335.putObject( idUsng, idAdjL, desc336 );
                    executeAction( idMk, desc335, DialogModes.NO );
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

        // Collapse groups

            // Collapse all groups

                function collapseAllGroups(){
                    // Collapse multimatte group

                        var layerName = "Multimatte";

                        try{
                            collapseGroup(layerName, app.activeDocument.layers.getByName(layerName), "blendingMode", "red", "0", "fill");
                        }catch(e){};

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

                    // Collapse Leftover Layers From Relink group

                        var layerName = "Leftover Layers From Relink"

                        try{
                            collapseGroup(layerName, app.activeDocument.layers.getByName(layerName), "blendingMode", "none", "opacity", "fill");
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

                        var layerName = "Overall Adjustments Group"

                        try{
                            collapseGroup(layerName, app.activeDocument.layers.getByName(layerName), "blendingMode", "none", "opacity", "fill");
                        }catch(e){};

                    // Collapse Overlay group

                        var layerName = "Overlay Group"

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
