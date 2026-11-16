-- Functions

    fn saveEachObjectToItsOwnSceneFunction prefixVariable moveToDefaultLayerVariable = (
        -- Variables

            local objectsToProcessPreliminary = (selection as array)
            local objectNamesToProcess = sort(for b in objectsToProcessPreliminary collect b.name)
            local myNumber

        deselect selection

        -- Loop

            for a = 1 to objectNamesToProcess.count do(
                -- Define myNumber variable

                    if a < 1000 then(
                        myNumber = (a as string)
                    )

                    if a < 100 then(
                        myNumber = "0" + (a as string)
                    )

                    if a < 10 then(
                        myNumber = "00" + (a as string)
                    )

                    (getNodeByName(objectNamesToProcess[a])).name = (prefixVariable + myNumber)
            )

        deselect selection
    )

-- Rollout

    rollout saveEachObjectToItsOwnSceneRollout "Save Each Obect To Its Own Scene"(
        -- Variables

            local prefixVariable = ""
            local objectsVariable = true
            local considerExistingFilesVariable = true
            local moveToDefaultLayerVariable = true

        -- Components

            editText warningOne "" text:"If a prefix is used, a space will be added between the prefix and the number" readOnly:true

            editText prexifEditText "Prefix: " text:""

            checkbox moveToDefaultLayerCheckBox "Move Objects To Default Layer" checked:true

            button runButton "Run"

        -- Actions

            on prexifEditText entered txt do(
                if txt != undefined and txt != "" then(
                    prefixVariable = (txt + " ")
                )else(
                    prefixVariable = ""
                )
            )

            on moveToDefaultLayerCheckBox changed state do(
                if state then(
                    moveToDefaultLayerVariable = true
                )else(
                    moveToDefaultLayerVariable = false
                )
            )

            on runButton pressed do(
                saveEachObjectToItsOwnSceneFunction prefixVariable moveToDefaultLayerVariable

                destroyDialog saveEachObjectToItsOwnSceneRollout
            )
    )

-- Create dialog

    createDialog saveEachObjectToItsOwnSceneRollout 750 160
