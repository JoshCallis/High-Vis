fn truncateFilenamesFunction originalFolderPathText lengthOfNewFileNamesInteger endVariable = (
    local myFiles = getFiles (originalFolderPathText + "/*")

    for a in myFiles do(
        local sFile = (getFilenameFile a) as string

        if matchPattern a Pattern:"*.jpg" or matchPattern a Pattern:"*.JPG" then(
            try(
                if endVariable == true then(
                    local hi = (subString sFile 1 lengthOfNewFileNamesInteger)
                )else(
                    local hi = (subString sFile (sFile.count - (lengthOfNewFileNamesInteger - 1)) lengthOfNewFileNamesInteger)
                )

                renameFile a (originalFolderPathText + "/" + hi + ".jpg")
            )catch()
        )

        if matchPattern a Pattern:"*.max" or matchPattern a Pattern:"*.MAX" then(
            try(
                if endVariable == true then(
                    local hi = (subString sFile 1 lengthOfNewFileNamesInteger)
                )else(
                    local hi = (subString sFile (sFile.count - (lengthOfNewFileNamesInteger - 1)) lengthOfNewFileNamesInteger)
                )

                renameFile a (originalFolderPathText + "/" + hi + ".max")
            )catch()
        )
    )
)

Rollout truncateFileNamesRollout "Truncate File Names"(
    -- Variables etc.

        local folderPathString = ""
        local lengthOfNewFileNamesInteger = 18
        local startVariable = true

    -- Components

        editText folderPathEditText "Folder Path:" text:""

        spinner lengthOfNewFileNames "Length Of New File Names:" type:#integer width:120 range:[1,100,18]

        checkBox startCheckBox "Truncate From Start Of Name" checked:true

        checkBox endCheckBox "Truncate From End Of Name" checked:false

        button truncateButton "Truncate"

    -- Actions

        on folderPathEditText entered txt do(
            folderPathString = txt
        )

        on lengthOfNewFileNames changed int do(
            lengthOfNewFileNamesInteger = int
        )

        on startCheckBox changed state do(
            if state then(
                startVariable = true

                endCheckBox.checked = false
            )else(
                startvariable = false

                endCheckBox.checked = true
            )
        )

        on endCheckBox changed state do(
            if state then(
                startVariable = false

                startCheckBox.checked = false
            )else(
                startvariable = true

                startCheckBox.checked = true
            )
        )

        on truncateButton pressed do(
            if folderPathString.count != 0 and folderPathString != undefined then(
                truncateFilenamesFunction folderPathString lengthOfNewFileNamesInteger startVariable

                destroyDialog truncateFileNamesRollout
            )
        )
)

createDialog truncateFileNamesRollout 400 150
