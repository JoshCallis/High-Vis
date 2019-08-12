try{
    if(app.activeDocument.layerSets.getByName("Multimatte").visible == true){
        app.activeDocument.layerSets.getByName("Multimatte").visible = false;
    }else{
        app.activeDocument.layerSets.getByName("Multimatte").visible = true;
    };
}catch(e){};
