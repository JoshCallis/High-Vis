fn renameFilesFunction originalFolderPathText extraTextString appendText specifiedFilesOnlyVariable fromFileNumber numberOfFilesNumber = (
    -- Variables etc.

        local myFiles = getFiles (originalFolderPathText + "/*")

    for a = 1 to myFiles.count do(
        -- Variables

            local b = myFiles[a]

        if specifiedFilesOnlyVariable == true then(
            -- Variables etc.

                local sFile = (getFilenameFile b) as string

                if appendText == false then(
                    local newFileName = (extraTextString + sFile)
                )else(
                    local newFileName = (sFile + extraTextString)
                )

            if a >= fromFileNumber and a <= (fromFileNumber + numberOfFilesNumber - 1) then(
                if matchPattern b Pattern:"*.jpg" or matchPattern b Pattern:"*.JPG" then(
                    try(
                        renameFile b (originalFolderPathText + "/" + newFileName + ".jpg")
                    )catch()
                )

                if matchPattern b Pattern:"*.tif" or matchPattern b Pattern:"*.TIF" then(
                    try(
                        renameFile b (originalFolderPathText + "/" + newFileName + ".tif")
                    )catch()
                )

                if matchPattern b Pattern:"*.png" or matchPattern b Pattern:"*.PNG" then(
                    try(
                        renameFile b (originalFolderPathText + "/" + newFileName + ".png")
                    )catch()
                )

                if matchPattern b Pattern:"*.max" or matchPattern b Pattern:"*.MAX" then(
                    try(
                        renameFile b (originalFolderPathText + "/" + newFileName + ".max")
                    )catch()
                )
            )else()
        )else(
            -- Variables etc.

                sFile = (getFilenameFile b) as string

                if appendText == false then(
                    local newFileName = (extraTextString + sFile)
                )else(
                    local newFileName = (sFile + extraTextString)
                )

            if matchPattern b Pattern:"*.jpg" or matchPattern b Pattern:"*.JPG" then(
                try(
                    renameFile b (originalFolderPathText + "/" + newFileName + ".jpg")
                )catch()
            )

            if matchPattern b Pattern:"*.tif" or matchPattern b Pattern:"*.TIF" then(
                try(
                    renameFile b (originalFolderPathText + "/" + newFileName + ".tif")
                )catch()
            )

            if matchPattern b Pattern:"*.png" or matchPattern b Pattern:"*.PNG" then(
                try(
                    renameFile b (originalFolderPathText + "/" + newFileName + ".png")
                )catch()
            )

            if matchPattern b Pattern:"*.max" or matchPattern b Pattern:"*.MAX" then(
                try(
                    renameFile b (originalFolderPathText + "/" + newFileName + ".max")
                )catch()
            )
        )
    )
)

Rollout renameFilesRollout "Append Or Prepend Text To File Names"(
    -- Variables etc.

        local folderPathString = ""
        local extraTextString = ""
        local appendText = false
        local specifiedFilesOnlyVariable = false
        local fromFileNumber = 1
        local numberOfFilesNumber = 1

    editText folderPathEditText "Folder Path:" text:""

    editText newTextEditText "New Text:" text:""

    checkBox endOfTextCheckBox "Append (instead of prepend) new text to file name" checked:false

    checkBox specifiedFilesOnlyCheckBox "Apply only to specified files" checked:false

    spinner fromFileSpinner "From:" type:#integer width:120 range:[1,10000,1] enabled:false

    spinner numberOfFilesSpinner "Number of files:" type:#integer width:120 range:[1,10000,1] enabled:false

    button renameButton "Rename"

    on folderPathEditText entered txt do(
        folderPathString = txt
    )

    on newTextEditText changed txt do(
        extraTextString = txt
    )

    on endOfTextCheckBox changed state do(
        if state then(
            appendText = true
        )else(
            appendText = false
        )
    )

    on specifiedFilesOnlyCheckBox changed state do(
        if state then(
            specifiedFilesOnlyVariable = true

            fromFileSpinner.enabled = true

            numberOfFilesSpinner.enabled = true
        )else(
            specifiedFilesOnlyVariable = false

            fromFileSpinner.enabled = false

            numberOfFilesSpinner.enabled = false
        )
    )

    on fromFileSpinner changed int do(
        fromFileNumber = int
    )

    on numberOfFilesSpinner changed int do(
        numberOfFilesNumber = int
    )

    on renameButton pressed do(
        if folderPathString.count != 0 and folderPathString != undefined then(
            renameFilesFunction folderPathString extraTextString appendText specifiedFilesOnlyVariable fromFileNumber numberOfFilesNumber

            newTextEditText.text = ""

            local extraTextString = ""

            fromFileSpinner.range = [1,10000,(fromFileNumber + numberOfFilesNumber)]

            fromFileNumber = (fromFileNumber + numberOfFilesNumber)
        )
    )
)

createDialog renameFilesRollout 400 200
