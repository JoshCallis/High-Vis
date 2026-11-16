/*
Export .max files in a folder as .dwg files
*/

-- Create a rollout window
rollout exportMaxToDwg "Export .max to .dwg" width:280
(
    -- Create a text field for folder path
    edittext folderPath "Folder Path:" fieldWidth:230 align:#left

    -- Create a button to start export
    button startBtn "Start Export" align:#center

    -- Set the button's behavior
    on startBtn pressed do
    (
        -- Get the folder path from the text field
        local folder = folderPath.text as string

        -- Check if the folder path is valid
        if folder == "" or not doesFileExist folder do
        (
            messageBox "Invalid folder path!" title:"Error"
        )

        -- Create a 'DWG' folder if it doesn't exist
        local dwgFolder = (getFilenamePath folder) + "\\DWG\\"
        if not doesFileExist dwgFolder do makeDir dwgFolder

        -- Get all .max files in the folder
        local maxFiles = getFiles (folder + "\\*.max")

        -- Delete all current geometry

            max unhide all

            max unfreeze all

            max select all

            max delete $

        -- Merge all objects from the .max files into the scene
        for maxFile in maxFiles do
        (
            -- Import the contents of the max file into the scene
            mergeMaxFile maxFile

            -- Ungroup everything and then select all

                max select all

                max group ungroup

                max select all

                max group ungroup

                max select all

                max group ungroup

                max select all

                max group ungroup

                max select all

                max group ungroup

                max select all

            -- Remove any materials applied to the objects
            for obj in objects where classof obj.material != StandardMaterial do
            (
                obj.material = StandardMaterial()
            )

            -- Convert all objects to editable meshes
            for obj in objects where canConvertTo obj Editable_Mesh do
            (
                try(
                    convertToMesh obj
                )catch()
            )

            -- Attach all meshes into one editable mesh
            local allMeshes = #()
            for obj in objects where classof obj == Editable_Mesh do
            (
                append allMeshes obj
            )

            local baseName = allMeshes[1].name

            if allMeshes.count > 1 then(
                local attachedMesh = meshop.attach allMeshes[1] allMeshes[2]

                if allMeshes.count > 2 then(
                    for i = 3 to allMeshes.count do
                    (
                        local baseObject = (getNodeByName baseName)
                        meshop.attach baseObject allMeshes[i]
                    )
                )
            )

            -- Reduce face count if necessary

            baseObject = (getNodeByName baseName)

            local vertexCount = meshOp.getNumVerts baseObject

            if vertexCount > 18000 do
            (
                -- Reduce vertex count to 18000
                polyReducer = ProOptimizer()

                addModifier baseObject polyReducer

                polyReducer.calculate = on

                completeredraw()

                polyReducer.vertexCount = 18000

                -- Collapse the modifier stack
                convertTo baseObject Editable_Mesh

                local hy = meshOp.getNumVerts baseObject
                print hy

                -- Delete all objects except the merged mesh
                for obj in objects where obj != baseObject do
                (
                    delete obj
                )
            )

            -- Export the mesh as a .dwg file with the same name as the current scene
            local dwgFile = (dwgFolder + "\\" + (getFilenameFile maxFile) + ".dwg")
            exportFile dwgFile #noPrompt
            format "Exported % to %.\n" (getFilenameFile maxFile) dwgFile

            -- Delete everything

                max select all

                max delete $

        )

        destroyDialog exportMaxToDwg
    )
)

-- Create the rollout window
createDialog exportMaxToDwg
