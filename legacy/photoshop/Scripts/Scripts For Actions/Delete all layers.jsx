var allLayersArray = [];

for(var a = 0; a < app.activeDocument.layers.length - 1; a++){
    allLayersArray.push(app.activeDocument.layers[a].name)
}

for(var a = 0; a < allLayersArray.length; a++){
    app.activeDocument.layers.getByName(allLayersArray[a]).remove()
}
