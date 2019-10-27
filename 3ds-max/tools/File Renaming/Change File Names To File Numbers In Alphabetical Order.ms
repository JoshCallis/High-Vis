-- Function

    fn renameFilesFunction originalFolderPathText replaceAllTextBoolean retainSpecifiedTextBoolean retainAllTextBoolean prependNumberToTextBoolean phraseToSplitWithString numberOfIndicesToRemoveFromStartInteger numberOfIndicesToRemoveFromEndInteger = (
        -- Variables etc.

            local myFiles = getFiles (originalFolderPathText + "/*")

        for i = 1 to myFiles.count do(
            -- Variables etc.

                a = myFiles[i]

                -- Define fileNumberString variable

                    if i < 1000 then(
                        local fileNumberString = (i as string)
                    )

                    if i < 100 then(
                        local fileNumberString = ("0" + (i as string))
                    )

                    if i < 10 then(
                        local fileNumberString = ("00" + (i as string))
                    )

                local sFile = (getFilenameFile a) as string

                -- newFileName variable

                    if replaceAllTextBoolean == true then(
                        local newFileName = (fileNumberString)
                    )

                    if retainSpecifiedTextBoolean == true then(
                        -- Redefine sFile variable

                            sFile = filterString sFile phraseToSplitWithString

                            for b = 1 to numberOfIndicesToRemoveFromStartInteger do(
                                sFile = deleteItem sFile 1
                            )

                            for b = 1 to numberOfIndicesToRemoveFromEndInteger do(
                                sFile = deleteItem sFile (sFile.count)
                            )

                            local sFile2 = ""

                            for b = 1 to sFile.count do(
                                append sFile2 sFile[b]

                                if b != sFile.count then(
                                    append sFile2 " "
                                )
                            )

                            sFile = sFile2

                            -- Capitalise first letter of each word

                                local lastStringItemWasSpace = false

                                for b = 1 to sFile.count do(
                                    if lastStringItemWasSpace == true then(
                                        print (sFile[b])

                                        sFile = replace sFile b 1 (toUpper sFile[b])

                                        print (sFile[b])

                                        lastStringItemWasSpace = false
                                    )

                                    if b == 1 then(
                                        sFile = replace sFile b 1 (toUpper sFile[b])
                                    )

                                    if sFile[b] == " " then(
                                        lastStringItemWasSpace = true
                                    )
                                )

                        -- Define newFileName variable

                            if prependNumberToTextBoolean == true then(
                                local newFileName = (fileNumberString + " " + sFile)
                            )else(
                                local newFileName = (sFile + " " + fileNumberString)
                            )
                    )

                    if retainAllTextBoolean == true then(
                        if prependNumberToTextBoolean == true then(
                            local newFileName = (fileNumberString + " " + sFile)
                        )else(
                            local newFileName = (sFile + " " + fileNumberString)
                        )
                    )

            if matchPattern a Pattern:"*.jpg" or matchPattern a Pattern:"*.JPG" then(
                try(
                    renameFile a (originalFolderPathText + "/" + newFileName + ".jpg")
                )catch()
            )

            if matchPattern a Pattern:"*.tif" or matchPattern a Pattern:"*.TIF" then(
                try(
                    renameFile a (originalFolderPathText + "/" + newFileName + ".tif")
                )catch()
            )

            if matchPattern a Pattern:"*.png" or matchPattern a Pattern:"*.PNG" then(
                try(
                    renameFile a (originalFolderPathText + "/" + newFileName + ".png")
                )catch()
            )

            if matchPattern a Pattern:"*.max" or matchPattern a Pattern:"*.MAX" then(
                try(
                    renameFile a (originalFolderPathText + "/" + newFileName + ".max")
                )catch()
            )
        )
    )

-- Rollout

    Rollout renameFilesRollout "Change File Names To File Numbers In Alphabetical Order"(
        -- Variables etc.

            local folderPathString = ""

            local replaceAllTextBoolean = true
            local retainSpecifiedTextBoolean = false
            local retainAllTextBoolean = false

            local prependNumberToTextBoolean = true

            local phraseToSplitWithString = ""
            local numberOfIndicesToRemoveFromStartInteger = 0
            local numberOfIndicesToRemoveFromEndInteger = 0

        -- Components

            editText folderPathEditText "Folder Path:" text:""

            group ""(
                checkBox replaceAllTextCheckBox "Replace all text" checked:true

                checkBox retainSpecifiedTextCheckBox "Retain specified text" checked:false

                checkBox retainAllTextCheckBox "Retain all text" checked:false toolTip:"If left unchecked, file names will be replaced by their respective numbers. If checked, numbers will be appended to the end of the files' names (following a space)"
            )

            group ""(
                checkBox prependNumberToTextCheckBox "Prepend number to text" checked:true enabled:false

                checkBox appendNumberToTextCheckBox "Append number to text" checked:false enabled:false
            )

            group ""(
                editText phraseToSplitWithEditText "Phrase to split with:" text:"" enabled:false

                spinner numberOfIndicesToRemoveFromStartSpinner "Number of indices to remove from start:" type:#integer range:[0,100,0] enabled:false

                spinner numberOfIndicesToRemoveFromEndSpinner "Number of indices to remove from end:" type:#integer range:[0,100,0] enabled:false
            )

            button renameButton "Rename"

        -- Actions

            -- Folder path

                on folderPathEditText entered txt do(
                    folderPathString = txt
                )

            -- Group 1

                on replaceAllTextCheckBox changed state do(
                    if replaceAllTextCheckBox.checked == true then(
                        -- Variables

                            replaceAllTextBoolean = true

                        -- Other components

                            -- Checking

                                retainSpecifiedTextCheckBox.checked = false

                                retainAllTextCheckBox.checked = false

                            -- Enabling/disabling

                                prependNumberToTextCheckBox.enabled = false

                                appendNumberToTextCheckBox.enabled = false

                                phraseToSplitWithEditText.enabled = false

                                numberOfIndicesToRemoveFromStartSpinner.enabled = false

                                numberOfIndicesToRemoveFromEndSpinner.enabled = false
                    )else(
                        replaceAllTextCheckBox.checked = true
                    )
                )

                on retainSpecifiedTextCheckBox changed state do(
                    if retainSpecifiedTextCheckBox.checked == true then(
                        -- Variables

                            retainSpecifiedTextBoolean = true

                        -- Other components

                            -- Checking

                                replaceAllTextCheckBox.checked = false

                                retainAllTextCheckBox.checked = false

                            -- Enabling/disabling

                                prependNumberToTextCheckBox.enabled = true

                                appendNumberToTextCheckBox.enabled = true

                                phraseToSplitWithEditText.enabled = true

                                numberOfIndicesToRemoveFromStartSpinner.enabled = true

                                numberOfIndicesToRemoveFromEndSpinner.enabled = true
                    )else(
                        retainSpecifiedTextCheckBox.checked = true
                    )
                )

                on retainAllTextCheckBox changed state do(
                    if retainAllTextCheckBox.checked == true then(
                        -- Variables

                            retainAllTextBoolean = true

                        -- Other components

                            -- Checking

                                replaceAllTextCheckBox.checked = false

                                retainSpecifiedTextCheckBox.checked = false

                            -- Enabling/disabling

                                prependNumberToTextCheckBox.enabled = true

                                appendNumberToTextCheckBox.enabled = true

                                phraseToSplitWithEditText.enabled = false

                                numberOfIndicesToRemoveFromStartSpinner.enabled = false

                                numberOfIndicesToRemoveFromEndSpinner.enabled = false
                    )else(
                        retainAllTextCheckBox.checked = true
                    )
                )

            -- Group 2

                on prependNumberToTextCheckBox changed state do(
                    if state then(
                        prependNumberToTextBoolean = true

                        appendNumberToTextCheckBox.checked = false
                    )else(
                        prependNumberToTextBoolean = false

                        appendNumberToTextCheckBox.checked = true
                    )
                )

                on appendNumberToTextCheckBox changed state do(
                    if state then(
                        prependNumberToTextBoolean = false

                        prependNumberToTextCheckBox.checked = false
                    )else(
                        prependNumberToTextBoolean = true

                        prependNumberToTextCheckBox.checked = true
                    )
                )

            -- Group 3

                on phraseToSplitWithEditText entered txt do(
                    if txt != "" then(
                        phraseToSplitWithString = txt
                    )else(
                        phraseToSplitWithString = ""
                    )
                )

                on numberOfIndicesToRemoveFromStartSpinner changed int do(
                    numberOfIndicesToRemoveFromStartInteger = int
                )

                on numberOfIndicesToRemoveFromEndSpinner changed int do(
                    numberOfIndicesToRemoveFromEndInteger = int
                )

            -- Rename

                on renameButton pressed do(
                    if folderPathString.count != 0 and folderPathString != undefined then(
                        renameFilesFunction folderPathString replaceAllTextBoolean retainSpecifiedTextBoolean retainAllTextBoolean prependNumberToTextBoolean phraseToSplitWithString numberOfIndicesToRemoveFromStartInteger numberOfIndicesToRemoveFromEndInteger

                        destroyDialog renameFilesRollout
                    )
                )
    )

createDialog renameFilesRollout 410 300
