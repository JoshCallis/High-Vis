app.documents.add()

savePSB("C:\\Callis Scripts\\3DS Max Metadata.psb")

// Functions

    // Save PSB

        function savePSB(pathPlusName){
            function cTID(s) { return app.charIDToTypeID(s); };
            var desc7 = new ActionDescriptor();
            var desc8 = new ActionDescriptor();
            desc7.putObject( cTID('As  '), cTID('Pht8'), desc8 );
            desc7.putPath( cTID('In  '), new File( pathPlusName ) );
            desc7.putBoolean( cTID('LwCs'), true );
            executeAction( cTID('save'), desc7, DialogModes.NO );
        };
