// Variables

    var layers = activeDocument.layers;
    var layersArray = new Array();
  	var len = layers.length;

// Check for Background layer

    var bgLayer = layers[len - 1];
    if (bgLayer.isBackgroundLayer) {
    	// include Background in sort?
    	if (confirm('Would you like the Background layer included in the sort?', false, 'Sort Background Layer?')) {
    		bgLayer.name = 'Background';
    		layersArray.push(bgLayer);
    	}
    	len--;
    }

// Push all layers to array

    for (var i = 0; i < len; i++){
    		layersArray.push(layers[i].name);
    };

// Arrange array alphabetically

    layersArray.sort();

// Arrange layers

    // Variables

    for (i = 0; i < len; i++){
        app.activeDocument.layers.getByName(layersArray[i]).move(layers[i], ElementPlacement.PLACEBEFORE);
    };
