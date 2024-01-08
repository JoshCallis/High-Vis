-- Global variables

    addModifiersOnObjectCreation -- Need this declared at top level so its value can be changed by external scripts that include this script
    lastTargetedObjectCreated = "undefined"
    global callisSCriptsCamerasLocked = true
    callisScriptsMoveObjectsToLLayerFunctionInAction = false

-- Default material

    -- Functions

        fn defaulMaterialFunction obj = (
            local matLib = getDir #scripts + "\\CallisScripts\\Material Libraries\\Default Material.mat"

            local str = matLib
            loadMaterialLibrary str

            local theMaterial = currentMaterialLibrary[1]

            if superclassof theMaterial != texturemap do
            obj.material = theMaterial
        )

-- Default wirecolor

    -- Functions

        struct defaulWireColourStruct(
            -- Functions

              	-- Set colour

                  	mapped fn defaulWireColourFunction obj = (
              			    obj.wireColor = color 0 0 0
                  	),

              	-- Callback functions

                  	fn callDefaulWireColourFunction obj = (
                  		  defaulWireColourFunction obj
                  	)
        )

        defaulWireColourStructVariable = defaulWireColourStruct()

-- Show material in viewport when added

    -- Functions

        fn showMaterialFunction myMat = (
            try(
                showTextureMap myMat on
            )catch()
        )

-- Add modifiers to new objects

    -- Functions

        struct addModifiersOnObjectCreationStruct(
            fn addModifiersOnCreationFunction ev nd = (
                local obj
                local originalObjectPos

                if selection.count == 1 do(
                    obj = $

                    if classof obj == box or classof obj == cone or classof obj == sphere or classof obj == geoSphere or classof obj == cylinder or classof obj == tube or classof obj == torus or classof obj == pyramid or classof obj == teapot or classof obj == plane or classof obj == textPlus or classof obj == rectangle or classof obj == circle or classof obj == text or classof obj == ellipse or classof obj == nGon or classof obj == line then(
                        if not isKindOf obj line then(
                            deselect obj

                            if validModifier obj Edit_Poly then(
                                if not isKindOf obj Editable_Poly do(
                                    if obj.modifiers.count == 0 then(
                                        if validModifier obj uvwMap then(
                                            try(
                                                addModifier obj (Uvwmap ())
                                            )catch()

                                            obj.uvwMap.cap = true
                                            obj.uvwMap.mapType = 4
                                            obj.uvwMap.realWorldMapSize = true
                                        )

                                        addModifier obj (Edit_Poly ())
                                    )

                                    if obj.modifiers.count == 1 and obj.modifiers[1].name == "UVW Map" then(
                                        addModifier obj (Edit_Poly ())
                                    )
                                )

                                max modify mode
                            )
                        )else(
                            obj.name = "Callis Scripts Object: Line To Convert To Poly"
                        )
                    )
                )
            ),

            fn addModifiersOnCreationLINEFunction ev nd = (
                local obj

                if selection.count == 1 do(
                    obj = $

                    if isKindOf obj line and obj.name == "Callis Scripts Object: Line To Convert To Poly" then(
                        deselect obj

                        if validModifier obj Edit_Poly then(
                            if not isKindOf obj Editable_Poly do(
                                if obj.modifiers.count == 0 then(
                                    if validModifier obj uvwMap then(
                                        addModifier obj (Uvwmap ())
                                        obj.uvwMap.cap = true
                                        obj.uvwMap.mapType = 4
                                        obj.uvwMap.realWorldMapSize = true
                                    )

                                    addModifier obj (Edit_Poly ())
                                )

                                if obj.modifiers.count == 1 and obj.modifiers[1].name == "UVW Map" then(
                                    addModifier obj (Edit_Poly ())
                                )
                            )
                        )

                        obj.name = "Line"

                        max modify mode
                    )
                )
            )
        )

    -- Run the script

        addModifiersOnObjectCreationVariable = addModifiersOnObjectCreationStruct()

        addModifiersOnObjectCreation = NodeEventCallback mouseUp:true added:addModifiersOnObjectCreationVariable.addModifiersOnCreationFunction

        addModifiersOnObjectCreationLINE = NodeEventCallback mouseUp:true geometryChanged:addModifiersOnObjectCreationVariable.addModifiersOnCreationLINEFunction

-- Put new objects in the correct layer etc.

    struct putNewObjectsInTheCorrectLayerStruct(
        -- Put object in layer

            mapped fn putNewObjectsInTheCorrectLayerFunction obj = (
                -- Variables

                    local camerasLayer = layermanager.getLayerFromName "Cameras"
                    local sunLayer = layermanager.
                    getLayerFromName "Sun"
                    local skyLayer = layermanager.getLayerFromName "Sky"
                    local lightsLayer = layermanager.getLayerFromName "Lights"
                    local selectedCamerasTarget
                    local selectedSunsTarget

                if superclassof obj == camera then(
                    try(
                        camerasLayer.addNode obj

                        lastTargetedObjectCreated = obj.name

                        try(
                            obj.targeted = off
                        )catch()

                        try(
                            obj.auto_vertical_tilt_correction = on
                        )catch()

                        if callisSCriptsCamerasLocked == true then(
                            setTransformLockFlags cameras #all
                        )
                    )catch()
                )

                if classof obj == VRaySun then(
                    try(
                        sunLayer.addNode obj

                        lastTargetedObjectCreated = obj.name
                    )catch()
                )

                if classof obj == Targetobject then(
                    try(
                        if matchPattern (lastTargetedObjectCreated) pattern:"*amera*" == true then(
                            camerasLayer.addNode obj
                        )

                        if matchPattern (lastTargetedObjectCreated) pattern:"*Sun*" == true then(
                            sunLayer.addNode obj
                        )
                    )catch()

                    lastTargetedObjectCreated = "undefined"
                )

                if classof obj == VRayLight and obj.type == 1 then(
                    try(
                        skyLayer.addNode obj
                    )catch()
                )

                if classof obj == VRayLight and obj.type == 0 then(
                    try(
                        lightsLayer.addNode obj

                        -- Set temperature

                            try(
                                $.color_mode = 1

                                $.color_temperature = 5800

                                $.color = color 255 235.856 211.566
                            )catch()
                    )catch()
                )
            ),

        -- Callback functions

            fn callputNewObjectsInTheCorrectLayerFunction obj = (
                putNewObjectsInTheCorrectLayerFunction obj
            )
    )

    putNewObjectsInTheCorrectLayerStructVariable = putNewObjectsInTheCorrectLayerStruct()

-- Put objects in L layer

    -- Issues:

        -- Only works on single objects. getting it to work on several at once has been a nightmare.

    struct putObjectsInLLayerStruct(
        -- Put object in layer

            mapped fn putObjectsInLLayerFunction obj = (
                if callisScriptsMoveObjectsToLLayerFunctionInAction == false then(
                    -- Variables

                        local activeObjectsLayer
                        callisScriptsMoveObjectsToLLayerFunctionInAction = true

                    try(
                        activeObjectsLayer = layerManager.getLayerFromName ((substituteString (selection[1].layer).name " —" "") + " (L)")

                        print activeObjectsLayer.name

                        for a in getCurrentSelection() do(
                            activeObjectsLayer.addNode a
                        )
                    )catch()

                    callisScriptsMoveObjectsToLLayerFunctionInAction = false
                )
            ),

        -- Callback functions

            fn callputObjectsInLLayerFunction obj = (
                putObjectsInLLayerFunction obj
            )
    )

    putObjectsInLLayerStructVariable = putObjectsInLLayerStruct()

-- Disable relevant event handlers for certain operations

    -- Functions

        struct disableRelevantEventHandlersForCertainOperationsStruct(
            fn disableOnNodeAddedEventHandlers = (
                -- Change default material to default wire colour

                    callBacks.RemoveScripts id:#defaultMaterial

                    defaulWireColourStructVariable = defaulWireColourStruct()

                -- Add modifiers on object creation

                    addModifiersOnObjectCreationVariable = addModifiersOnObjectCreationStruct()

                    addModifiersOnObjectCreation = undefined

                    gc light:true

                -- Put new objects in the correct layer

                    putNewObjectsInTheCorrectLayerStructVariable = putNewObjectsInTheCorrectLayerStruct()

                    callBacks.RemoveScripts id:#putNewObjectsInTheCorrectLayerID
            ),

            fn enableOnNodeAddedEventHandlers = (

                -- Change default wire colour to default material

                    callbacks.addscript #nodeCreated "defaulMaterialFunction(callbacks.notificationParam())" id:#defaultMaterial

                    defaulWireColourStructVariable = defaulWireColourStruct()

                -- Add modifiers on object creation

                    addModifiersOnObjectCreationVariable = addModifiersOnObjectCreationStruct()

                    addModifiersOnObjectCreation = NodeEventCallback mouseUp:true added:addModifiersOnObjectCreationVariable.addModifiersOnCreationFunction

                -- Put new objects in the correct layer

                    putNewObjectsInTheCorrectLayerStructVariable = putNewObjectsInTheCorrectLayerStruct()

                    callBacks.addScript #sceneNodeAdded "putNewObjectsInTheCorrectLayerStructVariable.callputNewObjectsInTheCorrectLayerFunction (callbacks.notificationParam())" id:#putNewObjectsInTheCorrectLayerID
            )
        )

        disableRelevantEventHandlersForCertainOperationsVariable = disableRelevantEventHandlersForCertainOperationsStruct()
