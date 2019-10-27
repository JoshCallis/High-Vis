fn replaceFileContentsFunction originalFolderPathText newFolderPathText = (
    -- Variables etc.

        local myOriginalFiles = getFiles (originalFolderPathText + "/*")
        local myNewFiles = getFiles (newFolderPathText + "/*")

    if myOriginalFiles.count == myNewFiles.count then(
        for a = 1 to myOriginalFiles.count do(
            -- Variables

                local b = myOriginalFiles[a]
                local c = myNewFiles[a]

                local sFileOriginal = (getFilenameFile b) as string
                local sFileNew = (getFilenameFile c) as string

            if matchPattern c Pattern:"*.jpg" or matchPattern c Pattern:"*.JPG" then(
                try(
                    renameFile c (newFolderPathText + "/" + sFileOriginal + ".jpg")
                )catch()
            )

            if matchPattern c Pattern:"*.tif" or matchPattern c Pattern:"*.TIF" then(
                try(
                    renameFile c (newFolderPathText + "/" + sFileOriginal + ".tif")
                )catch()
            )

            if matchPattern c Pattern:"*.png" or matchPattern c Pattern:"*.PNG" then(
                try(
                    renameFile c (newFolderPathText + "/" + sFileOriginal + ".png")
                )catch()
            )

            if matchPattern c Pattern:"*.max" or matchPattern c Pattern:"*.MAX" then(
                try(
                    renameFile c (newFolderPathText + "/" + sFileOriginal + ".max")
                )catch()
            )

            print (a as string)
        )
    )else(
        messageBox "Number of original files does not match number of new files. Please correct this and try again"
    )
)

Rollout replaceFileContentsRollout "Append Or Prepend Text To File Names"(
    -- Variables etc.

        local originalFolderPathString = ""
        local newFolderPathString = ""

    -- Components

        editText originalFolderPathEditText "Original Folder Path:" text:""

        editText newFolderPathEditText "New Folder Path:" text:""

        button renameButton "Rename"

    -- Actions

        on originalFolderPathEditText entered txt do(
            originalFolderPathString = txt
        )

        on newFolderPathEditText entered txt do(
            newFolderPathString = txt
        )

        on renameButton pressed do(
            if originalFolderPathString.count != 0 and originalFolderPathString != undefined and newFolderPathString.count != 0 and newFolderPathString != undefined then(
                replaceFileContentsFunction originalFolderPathString newFolderPathString

                destroyDialog replaceFileContentsRollout
            )
        )
)

createDialog replaceFileContentsRollout 400 100
