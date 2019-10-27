-- To do

    -- Make the script rename folders as well as files, to propare folders for multi all at once script

-- Rollout

    rollout callisScriptsRenameFilesForAllAtOnceScriptRollout("Rename Files For All At Once Script")(
        -- Variables

            local prefixText
            local originalFolderPathText = ""
            local digitsNumber = 3
            local prefixCharactersNumber = 1
            local afterDecision = false
            local previewsDecision = false

        editText originalFolderEditText "Folder:" text:""

        editText infoEditText text:"Provide a path containing all padding-number-folders that collectively contain\nall model volumes to be processed. The script will open\neach volume, and for each volume open the Vray and Previews\n folders to process. Ensure nothing is contained within the root folder that\nis not intended for the script." height:100 readOnly:true
        /*
        spinner digitsNumberSpinner "Num digits in base number:" type:#integer width:120 range:[1,10,3]

        spinner prefixCharactersNumberSpinner "Num characters before/after base number excluding file extension:" type:#integer width:120 range:[0,30,0]

        group ""(
            checkbox beforeCheckbox "Before" checked:true

            checkbox afterCheckbox "After" checked:false
        )
        */

        group ""(
            checkbox vrayCheckbox "Vray" checked:true

            checkbox previewsCheckbox "Previews" checked:false
        )

        button renameFilesButton "Rename Files"

        on originalFolderEditText entered txt do(
            if txt != "" then(
                originalFolderPathText = txt
            )
        )
        /*
        on digitsNumberSpinner changed num do(
            digitsNumber = num
        )

        on prefixCharactersNumberSpinner changed num do(
            prefixCharactersNumber = (num + 1)
        )

        on beforeCheckbox changed beforeState do(
            if beforeState then(
                afterCheckbox.checked = false

                afterDecision = false
            )else(
                afterCheckbox.checked = true

                afterDecision = true
            )
        )

        on afterCheckbox changed afterState do(
            if afterState then(
                beforeCheckbox.checked = false

                afterDecision = true
            )else(
                beforeCheckbox.checked = true

                afterDecision = true
            )
        )
        */
        on vrayCheckbox changed vrayState do(
            if vrayState then(
                previewsCheckbox.checked = false

                previewsDecision = false
            )else(
                previewsCheckbox.checked = true

                previewsDecision = true
            )
        )

        on previewsCheckbox changed previewsState do(
            if previewsState then(
                vrayCheckbox.checked = false

                previewsDecision = true
            )else(
                vrayCheckbox.checked = true

                previewsDecision = true
            )
        )

        on renameFilesButton pressed do(
            if originalFolderPathText != undefined then(
                -- Run the script

                    destroyDialog callisScriptsRenameFilesForAllAtOnceScriptRollout

                    --try(
                        callisScriptsRenameFilesForAllAtOnceScriptFunction originalFolderPathText previewsDecision
                    --)catch()
            )
        )
    )

    createDialog callisScriptsRenameFilesForAllAtOnceScriptRollout 700 350

-- Function

    fn callisScriptsRenameFilesForAllAtOnceScriptFunction originalFolderPathText previewsDecision = (
        endOfDirPreliminary = filterString originalFolderPathText "\\"
        endOfDir = endOfDirPreliminary[endOfDirPreliminary.count]

        -- Variables

            local oldPreviewsPath = undefined
            local oldVrayPath
            local myPreviewFilePreliminary
            local myPreviewFile
            local endOfRootDirPreliminary
            local endOfRootDir

            for o in getDirectories (originalFolderPathText + "/*") do(
                -- Variables etc

                    -- End of root dir

                        endOfRootDirPreliminary = filterString (o as string) "\\"
                        endOfRootDir = endOfRootDirPreliminary[endOfRootDirPreliminary.count]

                    -- Digits number

                        local digitsNumberNew

                        if matchPattern (endOfRootDir) Pattern:"*2 Digit*" or matchPattern (endOfRootDir) Pattern:"*2 digit*" then(
                            digitsNumberNew = 2
                        )

                        if matchPattern (endOfRootDir) Pattern:"*1 Digit*" or matchPattern (endOfRootDir) Pattern:"*1 digit*" then(
                            digitsNumberNew = 1
                        )

                        if not matchPattern (endOfRootDir) Pattern:"*2 Digit*" and not matchPattern (endOfRootDir) Pattern:"*2 digit*" and not matchPattern (endOfRootDir) Pattern:"*1 Digit*" and not matchPattern (endOfRootDir) Pattern:"*1 digit*" then(
                            digitsNumberNew = 3
                        )

                    -- Before/after

                        local isBefore = false
                        local isAfter = false

                        if matchPattern (o as string) Pattern:"*after*" or matchPattern (o as string) Pattern:"*After*" then(
                            isAfter = true
                        )

                    -- Padding number

                        local paddingNumberPreliminary = 1
                        local paddingNumber = 1

                        paddingNumberPreliminary = filterString endOfRootDir " "
                        paddingNumber = (((paddingNumberPreliminary[1]) as integer) + 1)

                for z in getDirectories (o + "/*") do(
                    -- Define old paths variables

                        for i in getDirectories (z + "/*") do(
                            endOfDirPreliminary = filterString (i as string) "\\"
                            endOfDir = endOfDirPreliminary[endOfDirPreliminary.count]

                            if matchPattern endOfDir Pattern: ("*Preview*") or matchPattern endOfDir Pattern: ("*preview*") or matchPattern endOfDir Pattern: ("*Render*") or matchPattern endOfDir Pattern: ("*render*") then(
                                oldPreviewsPath = (i as string) -- Note: this will end in \
                            )

                            if matchPattern endOfDir Pattern: ("*Vray*") or matchPattern endOfDir Pattern: ("*vray*") then(
                                oldVrayPath = (i as string) -- Note: this will end in \
                            )
                        )

                    -- Define myFiles variable

                        if previewsDecision == true then(
                            myFiles = getFiles (oldPreviewsPath + "/*")
                        )else(
                            myFiles = getFiles (oldVrayPath + "/*")
                        )

                    -- Process

                        for a in myFiles do(
                              endOfFileNamePreliminary = filterString (a as string) "\\"
                              endOfFileName = endOfFileNamePreliminary[endOfFileNamePreliminary.count]

                              -- Create fileNumber variable

                                  if isAfter == true then(
                                      fileNumber = substring endOfFileName ((endOfFileName.count + 1) - (paddingNumber + 4 + digitsNumberNew - 1)) digitsNumberNew
                                  )else(
                                      fileNumber = substring endOfFileName paddingNumber digitsNumberNew
                                  )

                              -- Rename file

                                  if previewsDecision == true then(
                                      if digitsNumberNew == 1 then(
                                          if matchPattern a Pattern:"*.jpg" or matchPattern a Pattern:"*.JPG" then(
                                              renameFile a (oldPreviewsPath + "/" + "00" + fileNumber + ".jpg")
                                          )

                                          if matchPattern a Pattern:"*.tif" or matchPattern a Pattern:"*.TIF" then(
                                              renameFile a (oldPreviewsPath + "/" + "00" + fileNumber + ".tif")
                                          )
                                      )

                                      if digitsNumberNew == 2 then(
                                          if matchPattern a Pattern:"*.jpg" or matchPattern a Pattern:"*.JPG" then(
                                              renameFile a (oldPreviewsPath + "/" + "0" + fileNumber + ".jpg")
                                          )

                                          if matchPattern a Pattern:"*.tif" or matchPattern a Pattern:"*.TIF" then(
                                              renameFile a (oldPreviewsPath + "/" + "0" + fileNumber + ".tif")
                                          )
                                      )

                                      if digitsNumberNew == 3 then(
                                          if matchPattern a Pattern:"*.jpg" or matchPattern a Pattern:"*.JPG" then(
                                              renameFile a (oldPreviewsPath + "/" + fileNumber + ".jpg")
                                          )

                                          if matchPattern a Pattern:"*.tif" or matchPattern a Pattern:"*.TIF" then(
                                              renameFile a (oldPreviewsPath + "/" + fileNumber + ".tif")
                                          )

                                          if matchPattern a Pattern:"*.png" or matchPattern a Pattern:"*.PNG" then(
                                              renameFile a (oldPreviewsPath + "/" + fileNumber + ".png")
                                          )

                                          if matchPattern a Pattern:"*.EXR" or matchPattern a Pattern:"*.exr" then(
                                              renameFile a (oldPreviewsPath + "/" + fileNumber + ".exr")
                                          )

                                          if matchPattern a Pattern:"*.hdr" or matchPattern a Pattern:"*.HDR" then(
                                              renameFile a (oldPreviewsPath + "/" + fileNumber + ".hdr")
                                          )
                                      )
                                  )else(
                                      if matchPattern endOfFileName Pattern:"*.max" then(
                                          if digitsNumberNew == 1 then(
                                              renameFile a (oldVrayPath + "/" + "00" + fileNumber + ".max")
                                          )

                                          if digitsNumberNew == 2 then(
                                              renameFile a (oldVrayPath + "/" + "0" + fileNumber + ".max")
                                          )

                                          if digitsNumberNew == 3 then(
                                              renameFile a (oldVrayPath + "/" + fileNumber + ".max")
                                          )
                                      )
                                  )
                        )
                )
            )
    )
