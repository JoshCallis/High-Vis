-- Functions

    fn saveEachObjectToItsOwnSceneFunction folder numberOfUnitsVariable moveToDefaultLayerVariable numberOfUnitsObjectsVariable = (
        -- Delete everything in the scene

            -- Unfreeze all layers

                for i = 0 to LayerManager.count-1 do(
                     (LayerManager.getLayer i).isFrozen = off
                )

            max unhide all

            max select all

            max delete

        -- Variables

            local myNumber
            local myFiles = getFiles (folder + "/*")

        deselect selection

        -- Loop

            -- Get the files

                YYYYYitems = for f in myFiles collect (filenameFromPath f)

                ZZZZZitems = #{1..(YYYYYitems.count)}

            -- Merge

                local toMerge = #()
                local sel = (ZZZZZitems as array)

                for i = 1 to sel.count do append toMerge myFiles[sel[i]]

                -- Autorename

                		DialogMonitorOPS.unRegisterNotification id:#autoRaname
                		DialogMonitorOPS.RegisterNotification checkDialog id:#autoRaname
                		DialogMonitorOPS.Enabled = true

                for i=1 to toMerge.count do(
                		if (mergeMAXFile toMerge[i] #noRedraw #select #mergeDups #renameMtlDups #neverReparent quiet:true) == false then(
                			  importFile toMerge[i] #noPrompt
                		)

                    local finalNumberOfUnits = -((i-1)*numberOfUnitsVariable)

                    print (finalNumberOfUnits as string)

                    local currentMergedObjects = selection as array
                    local currentMergedObjectsSorted = sort(for b in currentMergedObjects collect b.name)

                    for a = 1 to currentMergedObjectsSorted.count do(
                        local objectInSelection = getNodeByName(currentMergedObjectsSorted[a])

                        objectInSelection.pos = [0,0,0]

                        move objectInSelection [((a-1)*numberOfUnitsObjectsVariable),0,0]

                        if moveToDefaultLayerVariable == true then(
                            (LayerManager.getLayerFromName "0").addNode objectInSelection
                        )
                    )

                    for a in currentMergedObjects do(
                        selectMore a
                    )

                    move $ [0,finalNumberOfUnits,0]
                )

                DialogMonitorOPS.Enabled = false
                DialogMonitorOPS.unRegisterNotification id:#autoRaname

            deselect selection
    )

-- Rollout

    rollout saveEachObjectToItsOwnSceneRollout "Save Each Obect To Its Own Scene"(
        -- Variables

            local folderVariable = ""
            local objectsVariable = true
            local considerExistingFilesVariable = true
            local numberOfUnitsVariable = 50
            local numberOfUnitsObjectsVariable = 25
            local moveToDefaultLayerVariable = true

        -- Components

            editText warningOne "" text:"All incoming objects must be uniquely named. All existing scene objects will be deleted" readOnly:true

            editText folderEditText "Folder: " text:""

            spinner numberOfUnitsSpinner "Desired Number Of Units Between Merged Scenes" range:[0,100000,50] type:#integer

            spinner numberOfUnitsObjectsSpinner "Desired Number Of Units Between Each Scene's Objects" range:[0,100000,25] type:#integer

            checkbox moveToDefaultLayerCheckBox "Move Objects To Default Layer" checked:true

            button runButton "Run"

        -- Actions

            on folderEditText entered txt do(
                if txt != undefined and txt != "" then(
                    folderVariable = txt
                )
            )

            on numberOfUnitsSpinner changed int do(
                numberOfUnitsVariable = int
            )

            on numberOfUnitsObjectsSpinner changed int do(
                numberOfUnitsObjectsVariable = int
            )

            on moveToDefaultLayerCheckBox changed state do(
                if state then(
                    moveToDefaultLayerVariable = true
                )else(
                    moveToDefaultLayerVariable = false
                )
            )

            on runButton pressed do(
                saveEachObjectToItsOwnSceneFunction folderVariable numberOfUnitsVariable moveToDefaultLayerVariable numberOfUnitsObjectsVariable

                destroyDialog saveEachObjectToItsOwnSceneRollout
            )
    )

-- Create dialog

    createDialog saveEachObjectToItsOwnSceneRollout 750 160
