// Run the script

    try{
        deleteActiveLayersLayerMask()

        createMaskFromSelectionOnActiveLayer()
    }catch(e){}

// General

    // Layer

        // Layer modification

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
                        }else{
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
