-- Global variables

    include "$scripts/Startup/Callis Scripts/General Event Handling.ms"

-- Default material

    -- Run the script

        callbacks.addscript #nodeCreated "defaulMaterialFunction(callbacks.notificationParam())" id:#defaultMaterial

-- Default wirecolor

    -- Run the script

            defaulWireColourStructVariable = defaulWireColourStruct()

            callBacks.addScript #sceneNodeAdded "defaulWireColourStructVariable.callDefaulWireColourFunction (callbacks.notificationParam())" id:#defaultWireColorID

-- Put new objects in the correct layer

    -- Run the script

            putNewObjectsInTheCorrectLayerStructVariable = putNewObjectsInTheCorrectLayerStruct()

            callBacks.addScript #sceneNodeAdded "putNewObjectsInTheCorrectLayerStructVariable.callputNewObjectsInTheCorrectLayerFunction (callbacks.notificationParam())" id:#putNewObjectsInTheCorrectLayerID

-- Try to put objects in (L) layer if added to base layer

    -- Run the script

        putObjectsInLLayerStructVariable = putObjectsInLLayerStruct()

        callBacks.addScript #nodeLayerChanged "putObjectsInLLayerStructVariable.callputObjectsInLLayerFunction (callbacks.notificationParam())" id:#putObjectsInLLayerID

-- Show material in viewport when added

    -- Run the script

        callbacks.addscript #mtlRefAdded "showMaterialFunction(callbacks.notificationParam())" id:#showMaterialInViewport

-- Disable relevant event handlers for certain operations

    -- Run the script

        disableRelevantEventHandlersForCertainOperationsVariable = disableRelevantEventHandlersForCertainOperationsStruct()

        callbacks.addScript #preImport "disableRelevantEventHandlersForCertainOperationsVariable.disableOnNodeAddedEventHandlers()" id:#disableOnNodeAddedEventHandlersID

        callbacks.addScript #postImport "disableRelevantEventHandlersForCertainOperationsVariable.enableOnNodeAddedEventHandlers()" id:#enableOnNodeAddedEventHandlersID

        callbacks.addScript #importFailed "disableRelevantEventHandlersForCertainOperationsVariable.enableOnNodeAddedEventHandlers()" id:#enableOnNodeAddedEventHandlersID

        callbacks.addScript #filePreMerge "disableRelevantEventHandlersForCertainOperationsVariable.disableOnNodeAddedEventHandlers()" id:#disableOnNodeAddedEventHandlersID

        callbacks.addScript #filePostMergeProcess "disableRelevantEventHandlersForCertainOperationsVariable.enableOnNodeAddedEventHandlers()" id:#enableOnNodeAddedEventHandlersID

        -- Undo and redo

            callbacks.addScript #preSceneUndo "disableRelevantEventHandlersForCertainOperationsVariable.disableOnNodeAddedEventHandlers()" id:#disableOnNodeAddedEventHandlersID

            callbacks.addScript #preSceneRedo "disableRelevantEventHandlersForCertainOperationsVariable.disableOnNodeAddedEventHandlers()" id:#disableOnNodeAddedEventHandlersID

            callbacks.addScript #sceneUndo "disableRelevantEventHandlersForCertainOperationsVariable.enableOnNodeAddedEventHandlers()" id:#enableOnNodeAddedEventHandlersID

            callbacks.addScript #sceneRedo "disableRelevantEventHandlersForCertainOperationsVariable.enableOnNodeAddedEventHandlers()" id:#enableOnNodeAddedEventHandlersID

        -- Cloning

            callbacks.addScript #preNodesCloned "disableRelevantEventHandlersForCertainOperationsVariable.disableOnNodeAddedEventHandlers()" id:#disableOnNodeAddedEventHandlersID

            callbacks.addScript #postNodesCloned "disableRelevantEventHandlersForCertainOperationsVariable.enableOnNodeAddedEventHandlers()" id:#enableOnNodeAddedEventHandlersID
