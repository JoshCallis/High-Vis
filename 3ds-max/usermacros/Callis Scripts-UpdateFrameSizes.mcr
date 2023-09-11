macroScript UpdateFrameSizes category:"Callis Scripts" tooltip:"Update Frame Sizes"

(
    rollout FrameSizesRollout "Frame Sizes"

    (
        -- Initialize the spinner to the current frame

            local currentFrame = animationRange.start

        spinner frameSpinner "Frame:" range:[1, 10, currentFrame]

        group "Current Frame" (
            -- label lblWidth "Width:" align:#right offset:[0,2]

                editText txtWidth width:50 align:#left

            -- label lblHeight "Height:" align:#right offset:[0,2]

                editText txtHeight width:50 align:#left
        )

        button updateButton "Update Layer Name" width:150 height:30

        on frameSpinner changed val do(
            -- Update the editTextes with the width and height for the selected frame

                local layerName = getLayerNameForFrame val
                local width, height = parseLayerName(layerName)
                txtWidth.text = width as string
                txtHeight.text = height as string
        )

        on updateButton pressed do(
            local newLayerName = generateLayerName()

            -- Find the 'Frame Sizes Dummy' object

                local dummyObject = getNodeByName "Frame Sizes Dummy"

            -- Check if the dummy object exists and is a dummy object

                if isValidNode dummyObject and isDummyObject dummyObject then(
                    -- Get the parent layer and update its name

                        local parentLayer = getParentLayer dummyObject

                        if parentLayer != undefined then(
                            parentLayer.name = newLayerName
                            messageBox "Layer name updated successfully!"
                        )else(
                            messageBox "Parent layer not found."
                        )
                )else(
                    messageBox "Dummy object 'Frame Sizes Dummy' not found."
                )
        )

        -- Function to get the parent layer of an object

            fn getParentLayer obj = (
                for layer in layerManager where findItem layer.nodes obj != 0 do
                (
                    return layer
                )
                undefined
            )

        -- Function to get the layer name for a specific frame

            fn getLayerNameForFrame frameNum = (
                local dummyObject = getNodeByName "Frame Sizes Dummy"

                if isValidNode dummyObject and isDummyObject dummyObject do(
                    local parentLayer = getParentLayer dummyObject

                    if parentLayer != undefined do(
                        local layerName = parentLayer.name

                        local pattern = "Frame #(frameNum) .*"

                        local regex = substitutePattern layerName pattern

                        return regex.result
                    )
                )

                ""
            )

        -- Function to parse the width and height from a layer name

            fn parseLayerName layerName = (
                local pattern = ".* ([0-9]+)x([0-9]+),? .*"

                local regex = substitutePattern layerName pattern

                if regex != undefined do(
                    local width = (execute (regex.result[1])) as integer

                    local height = (execute (regex.result[2])) as integer

                    local both = #(width, height)

                    return both
                )

                0
            )

        -- Function to generate a new layer name based on user input

            fn generateLayerName = (
                local frameNum = frameSpinner.value
                local width = txtWidth.text as integer
                local height = txtHeight.text as integer
                local layerName = getLayerNameForFrame frameNum
                local newLayerName = replace pattern:("Frame #(frameNum) .*") name:layerName with:("Frame #(frameNum) " + width as string + "x" + height as string + ",")
                newLayerName
            )
    )

    createDialog FrameSizesRollout width:300 height:200
)
