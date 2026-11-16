fn replaceTextInFileNamesFunction originalFolderPathText oldTextString newTextString = (
    -- Variables etc.

        local myFiles = getFiles (originalFolderPathText + "/*")

    for a in myFiles do(
        -- Variables etc.

            local sFile = (getFilenameFile a) as string

            local newFileName = (substituteString sFile oldTextString newTextString)

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

Rollout replaceTextInFileNamesRollout "Replace Text In File Names"(
    -- Variables etc.

        local folderPathString = ""

        local oldTextString = ""

        local newTextString = ""

        local appendText = false

    editText folderPathEditText "Folder Path:" text:""

    editText oldText "Old Text:" text:""

    editText newText "New Text:" text:""

    button renameButton "Rename"

    on folderPathEditText entered txt do(
        folderPathString = txt
    )

    on oldText changed txt do(
        oldTextString = txt
    )

    on newText changed txt do(
        newTextString = txt
    )

    on renameButton pressed do(
        if folderPathString.count != 0 and folderPathString != undefined then(
            replaceTextInFileNamesFunction folderPathString oldTextString newTextString

            destroyDialog replaceTextInFileNamesRollout
        )
    )
)

createDialog replaceTextInFileNamesRollout 400 100
