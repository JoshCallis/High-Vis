-- Issues:

    -- Coordinate centre is set to system during the script, and not changed back to whatever it was before
    -- If reference coordinate system was hybrid before running the script, it will be changed to world after running, as opposed to what the hybrid was specifically

tool scale1DTool(
    -- Variables

        local currentModifier
        local currentsubobjectLevel = 0
        local originalScale
        local newScale
        local originalCoordSys
        local originalCoordCentre
        local addEditPoly

        local b
        local bName
        local layer = layerManager.getLayerFromName "Temporary Script Objects"
        local originalPosition
        local success = false
        local xDistance
        local yDistance
        local zDistance
        local mainDistance
        local firstClick
        local firstClickReal
        local lockToAxis = "none"
        local turnSnapBackOnAfterAltKeyReleased = false
        local snapWasOnAtStart
        local orthoSnap = false
        local nonOrthoAxisLock
        local secondClick = [0,0,0]
        local worldPointOnShiftCtrlAltClick = [0,0,0]
        local firstMove = true

        -- Distance variables

            local xPosOne
            local yPosOne
            local zPosOne

            local xPosTwo
            local yPosTwo
            local zPosTwo

            local xPosCurrent
            local yPosCurrent
            local zPosCurrent

            local xChangeOne
            local yChangeOne
            local zChangeOne

            local xChangeTwo
            local yChangeTwo
            local zChangeTwo

            local xposCurrentAdvanced
            local yposCurrentAdvanced
            local zposCurrentAdvanced

            local xposCurrentLocked
            local yposCurrentLocked
            local zposCurrentLocked

            local yNonOrthoAxisLockToX
            local zNonOrthoAxisLockToX
            local yNonOrthoAxisLockToXSubObject
            local zNonOrthoAxisLockToXSubObject

            local xNonOrthoAxisLockToY
            local zNonOrthoAxisLockToY
            local xNonOrthoAxisLockToYSubObject
            local zNonOrthoAxisLockToYSubObject

            local xNonOrthoAxisLockToZ
            local yNonOrthoAxisLockToZ
            local xNonOrthoAxisLockToZSubObject
            local yNonOrthoAxisLockToZSubObject

            local xNonOrthoAxisLockMaster
            local yNonOrthoAxisLockMaster
            local zNonOrthoAxisLockMaster

        local scale1DFactorPreliminary
        local totalDistanceMoved = undefined

        local startScaling
        local scale1DFactor = undefined
        local myCoolDialogs = undefined

        local newOriginalPos = false
        local finalSubobjectPos = [0,0,0]

        local moveSubobjectBackToOriginalPos = [0,0,0]

    on start do(
        -- Stop if nothing was selected

            if selection.count > 1 then(
                messageBox "Please select only one object"

                #stop
            )

        if subobjectLevel != 0 then(
            currentModifier = modpanel.getCurrentObject()

            currentsubobjectLevel = subobjectLevel
        )else(
            addEditPoly = Edit_Poly()

            addModifier $ addEditPoly

            currentModifier = modpanel.getCurrentObject()
        )

        -- Define variables

            firstMove = true

            b = $

            originalCoordSys = getRefCoordSys()

            originalScale = b.scale

            if snapMode.active == true then(
                snapWasOnAtStart = true
            )else(
                snapWasOnAtStart = false
            )

        -- Change settings as needed

            setCoordCenter #system

            max modify mode
    )

    on mouseMove clickno do(
        -- Redraw views

            redrawViews()

        if startScaling == true then(
            -- Define variables for each axis

                xPosCurrent = worldPoint[1]
                yPosCurrent = worldPoint[2]
                zPosCurrent = worldPoint[3]

                xChangeTwo = xPosCurrent-xPosOne
                yChangeTwo = yPosCurrent-yPosOne
                zChangeTwo = zPosCurrent-zPosOne

                xPosCurrentAdvanced = xPosOne + xChangeTwo
                yPosCurrentAdvanced = yPosOne + yChangeTwo
                zPosCurrentAdvanced = zPosOne + zChangeTwo

                xPosCurrentLocked = xPosCurrentAdvanced
                xPosCurrentSubobjectLocked = xChangeTwo

                yPosCurrentLocked = yPosCurrentAdvanced
                yPosCurrentSubobjectLocked = yChangeTwo

                zPosCurrentLocked = zPosCurrentAdvanced
                zPosCurrentSubobjectLocked = zChangeTwo

                -- Non-ortho axis lock

                    -- Master

                        xNonOrthoAxisLockMaster = xposCurrentAdvanced
                        xNonOrthoAxisLockSubobjectMaster = xChangeTwo

                        yNonOrthoAxisLockMaster = yposCurrentAdvanced
                        yNonOrthoAxisLockSubobjectMaster = yChangeTwo

                        zNonOrthoAxisLockMaster = zposCurrentAdvanced
                        zNonOrthoAxisLockSubobjectMaster = zChangeTwo

                    -- Non-ortho axis lock to x

                        yNonOrthoAxisLockToX = yChangeOne/xChangeOne*xChangeTwo+yPosOne
                        zNonOrthoAxisLockToX = zChangeOne/xChangeOne*xChangeTwo+zPosOne

                        yNonOrthoAxisLockToXSubObject = yChangeOne/xChangeOne*xChangeTwo
                        zNonOrthoAxisLockToXSubObject = zChangeOne/xChangeOne*xChangeTwo

                    -- Non-ortho axis lock to y

                        xNonOrthoAxisLockToY = xChangeOne/yChangeOne*yChangeTwo+xPosOne
                        zNonOrthoAxisLockToY = zChangeOne/yChangeOne*yChangeTwo+zPosOne

                        xNonOrthoAxisLockToYSubObject = xChangeOne/yChangeOne*yChangeTwo
                        zNonOrthoAxisLockToYSubObject = zChangeOne/yChangeOne*yChangeTwo

                    -- Non-ortho axis lock to z

                        xNonOrthoAxisLockToZ = xChangeOne/zChangeOne*zChangeTwo+xPosOne
                        yNonOrthoAxisLockToZ = yChangeOne/zChangeOne*zChangeTwo+yPosOne

                        xNonOrthoAxisLockToZSubObject = xChangeOne/zChangeOne*zChangeTwo
                        yNonOrthoAxisLockToZSubObject = yChangeOne/zChangeOne*zChangeTwo

            -- If subobject, move back to correct position at first move

                if subobjectLevel != 0 then(
                    try(
                        if firstMove == true then(
                            $.modifiers[#Edit_Poly].ScaleSelection [1,1,1] axis:$.transform

                            finalSubobjectPos = [0,0,0]

                            firstMove = false
                        )
                    )catch()
                )

            if lockToAxis == "x" then(
                if subobjectLevel == 0 then(
                    $.scale = [1,1,((1/xChangeOne)*xChangeTwo)]
                )else(
                    try(
                        $.modifiers[#Edit_Poly].ScaleSelection [1,1,((1/xChangeOne)*xChangeTwo)] axis:$.transform

                        finalSubobjectPos = [1,1,((1/xChangeOne)*xChangeTwo)]
                    )catch()
                )
            )

            if lockToAxis == "y" then(
                if subobjectLevel == 0 then(
                    $.scale = [1,1,((1/yChangeOne)*yChangeTwo)]
                )else(
                    try(
                        $.modifiers[#Edit_Poly].ScaleSelection [1,1,((1/yChangeOne)*yChangeTwo)] axis:$.transform

                        finalSubobjectPos = [1,1,((1/yChangeOne)*yChangeTwo)]
                    )catch()
                )
            )

            if lockToAxis == "z" then(
                if subobjectLevel == 0 then(
                    $.scale = [1,1,((1/zChangeOne)*zChangeTwo)]
                )else(
                    try(
                        $.modifiers[#Edit_Poly].ScaleSelection [1,1,((1/zChangeOne)*zChangeTwo)] axis:$.transform

                        finalSubobjectPos = [1,1,((1/zChangeOne)*zChangeTwo)]
                    )catch()
                )
            )

            if altKey then(
                if snapMode.active == true then(
                    snapMode.active = false

                    turnSnapBackOnAfterAltKeyReleased = true
                )
            )else(
                if turnSnapBackOnAfterAltKeyReleased == true then(
                    snapMode.active = true

                    turnSnapBackOnAfterAltKeyReleased = false
                )
            )
        )
    )

    on mousePoint clickno do(
        if clickno == 1 or clickno == 2 or clickno == 3 then(
            if clickno == 1 or clickno == 2 then(
                if clickno == 1 then(
                    if shiftKey then(
                        if subobjectLevel == 0 then(
                            if ctrlKey then(
                                maxOps.cloneNodes $ cloneType:#instance newNodes:&nnl
                                select nnl
                            )else(
                                maxOps.cloneNodes $ cloneType:#instance newNodes:&nnl
                                select nnl
                            )

                            b = $
                        )else(
                            if subobjectLevel == 1 then(
                                try(
                                    $.modifiers[#Edit_Poly].ButtonOp #CloneVertex
                                )catch()
                            )

                            if subobjectLevel == 2 or subobjectLevel == 3 then(
                                try(
                                    $.modifiers[#Edit_Poly].ButtonOp #CloneEdge
                                )catch()
                            )

                            if subobjectLevel == 4 or subobjectLevel == 5 then(
                                try(
                                    $.modifiers[#Edit_Poly].ButtonOp #CloneFace
                                )catch()
                            )
                        )
                    )
                )

                firstClick = worldPoint
                firstClickReal = worldPoint

                b.pivot = worldPoint

                success = false

                -- Create wireframe of original object

                    if (not shiftKey and subobjectLevel == 0) or subobjectLevel != 0 then(
                        if selection.count < 100 and clickno == 1 then(
                            for n in (selection as array) do(
                                instance n name: "TwoClickMoveToolCopy1"
                                convertTo $TwoClickMoveToolCopy1 Editable_Poly
                                $TwoClickMoveToolCopy1.displayByLayer = true
                                $TwoClickMoveToolCopy1.wirecolor = color 100 100 100
                                layer.addnode $TwoClickMoveToolCopy1
                                $TwoClickMoveToolCopy1.name = "TwoClickMoveToolCopy"
                            )
                        )
                    )

                if clickno == 2 then(
                    modpanel.setCurrentObject currentModifier

                    --subobjectLevel = currentsubobjectLevel
                )
            )else(
                -- Variables (plus setting vertical grid if relevant)

                    nonOrthoAxisLock = true

                    secondClick = worldPoint

                    startScaling = true

                    -- Position variables

                        xPosOne = firstClick[1]
                        yPosOne = firstClick[2]
                        zPosOne = firstClick[3]

                        xPosTwo = secondClick[1]
                        yPosTwo = secondClick[2]
                        zPosTwo = secondClick[3]

                        xChangeOne = worldDist[1]
                        yChangeOne = worldDist[2]
                        zChangeOne = worldDist[3]

                    -- Define xDistance variable

                        if xChangeOne*-1 > xChangeOne then(
                            xDistance = xChangeOne*-1
                        )else(
                            xDistance = xChangeOne
                        )

                    -- Define yDistance variable

                        if yChangeOne*-1 > yChangeOne then(
                            yDistance = yChangeOne*-1
                        )else(
                            yDistance = yChangeOne
                        )

                    -- Define zDistance variable

                        if zChangeOne*-1 > zChangeOne then(
                            zDistance = zChangeOne*-1
                        )else(
                            zDistance = zChangeOne
                        )

                    -- Define mainDistance variable

                        if xDistance > yDistance and xDistance > zDistance then(
                            mainDistance = "x"
                        )

                        if yDistance > xDistance and yDistance > zDistance then(
                            mainDistance = "y"
                        )

                        if zDistance > xDistance and zDistance > yDistance then(
                            mainDistance = "z"
                        )

                    if mainDistance == "x" then(
                        lockToAxis = "x"
                    )

                    if mainDistance == "y" then(
                        lockToAxis = "y"
                    )

                    if mainDistance == "z" then(
                        lockToAxis = "z"

                        -- Create vertical grid

                            scriptingLayer = (layermanager.getLayerFromName "Temporary Script Objects")

                            hi = grid displayPlane:1 effect:0 pos:[0,0,0] isSelected:on
                            hi.name = "callisScriptsVerticalGrid"
                            macros.run "Objects Helpers" "ActivateGrid"

                            scriptingLayer.addNode $callisScriptsVerticalGrid

                            hide $callisScriptsVerticalGrid

                            select b
                    )

                -- Change pivot

                    -- Set subobject mode to 0

                        subobjectLevel = 0

                    -- Instance

                        instance $ name: "Scale1DToolCopy1"
                        convertTo $Scale1DToolCopy1 Editable_Poly
                        $Scale1DToolCopy1.displayByLayer = true
                        $Scale1DToolCopy1.wirecolor = color 100 100 100
                        layer.addnode $Scale1DToolCopy1
                        $Scale1DToolCopy1.name = "Scale1DToolCopy"

                    -- Change instance's direction

                        $Scale1DToolCopy.dir = [xChangeOne, yChangeOne, zChangeOne]

                    -- Match object's pivot to instance's pivot

                    		-- Get matrix from object

                    		    Trgt = $Scale1DToolCopy.transform

                    		-- Store child transforms

                    		    local ChldTms = in coordSys Trgt ( for Chld in $.children collect Chld.transform )

                    		-- Current offset transform matrix

                        		local TmScale = scaleMatrix $.objectOffsetScale
                        		local TmRot = $.objectOffsetRot as matrix3
                        		local TmPos = transMatrix $.objectOffsetPos
                        		local TmOffset = TmScale * TmRot * TmPos

                    		-- New offset transform matrix

                    		    TmOffset *= $.transform * inverse Trgt

                    		-- Apply matrix

                    		    $.transform = Trgt

                    		-- Restore offsets

                        		$.objectOffsetPos = TmOffset.translation
                        		$.objectOffsetRot = TmOffset.rotation
                        		$.objectOffsetScale = TmOffset.scale

                    		-- Restore child transforms

                    		    for i = 1 to $.children.count do $.children[i].transform = ChldTms[i] * inverse Trgt * $.transform

                    -- Delete Instance

                        delete $Scale1DToolCopy

                    -- Set modifier and subobject mode to what it originally was

                        modpanel.setCurrentObject currentModifier

                        subobjectLevel = currentsubobjectLevel
            )
        )else(
            if ctrlKey and not shiftKey then(
                -- Prompt for distance

                    struct myCoolDialogs
                     (
                      labelStr,

                      stringQuery = rollout stringQuery "String Query"
                      (
                        local returnStr

                        label lblHeader
                        editText etInput

                        fn launch label: =
                        (
                          destroyDialog myCoolDialogs.stringQuery
                          if label != unsupplied then
                            myCoolDialogs.labelStr = label
                          else myCoolDialogs.labelStr = "Enter some text:"
                          createDialog myCoolDialogs.stringQuery modal:true
                          returnStr -- only put it here if the dialog is modal
                        )

                        on stringQuery open do
                        (
                          lblHeader.text = myCoolDialogs.labelStr
                          setFocus etInput
                        )

                        on etInput entered str do
                        (
                          destroyDialog myCoolDialogs.stringQuery
                          returnStr = str
                        )
                      )
                     )

                     myCoolDialogs = myCoolDialogs() -- as there are variables, an instance is needed
                     result = myCoolDialogs.stringQuery.launch label:"Enter your credentials"

                     format "Returned String: %
                    " result

                -- Define scale1DFactor variable

                    try(
                        scale1DFactorPreliminary = result
                        scale1DFactor = scale1DFactorPreliminary as integer

                        if scale1DFactor == 0 then(
                            scale1DFactor = undefined
                        )
                    )catch()
            )else(
                if startScaling == true then(
                    if shiftKey and ctrlKey and altKey then(
                        if newOriginalPos == false then(
                            if subobjectLevel != 0 then(
                                $.modifiers[#Edit_Poly].Commit ()

                                worldPointOnShiftCtrlAltClick = worldPoint

                                moveSubobjectBackToOriginalPos = [-(worldPointOnShiftCtrlAltClick[1]-firstClickReal[1]),-(worldPointOnShiftCtrlAltClick[2]-firstClickReal[2]),-(worldPointOnShiftCtrlAltClick[3]-firstClickReal[3])]
                            )

                            firstClick = worldPoint

                            newOriginalPos = true
                        )else(
                            firstClick = firstClickReal

                            $.modifiers[#Edit_Poly].MoveSelection moveSubobjectBackToOriginalPos

                            $.modifiers[#Edit_Poly].Commit ()

                            newOriginalPos = false
                        )
                    )else(
                        success = true

                        if subobjectLevel == 0 then(
                            newScale = b.scale

                            b.scale = originalScale

                            subobjectLevel = 5

                            setCoordCenter #system

                            toolMode.coordsys #gimbal

                            max select all

                            $.modifiers[#Edit_Poly].ScaleSelection newScale axis:$.transform

                            $.modifiers[#Edit_Poly].Commit ()

                            max select none

                            subobjectLevel = 0

                            -- Set coordinate system back to what it originally was if possible

                                if originalCoordSys == #hybrid then(
                                    toolMode.coordsys #world
                                )else(
                                    toolMode.coordsys originalCoordSys
                                )

                            --addEditPoly.name = "Scale 1D"

                            max create mode

                            max modify mode
                        )

                        #stop
                    )
                )
            )
        )
    )

    on mouseAbort clickno do(
        try(
            #stop
        )catch()
    )

    on stop do(

        -- If cancelled
            if success != true and selection.count != 0 then(
                try(
                    if subobjectLevel == 0 then(
                        b.scale = [1,1,1]
                    )else(
                        try(
                            $.modifiers[#Edit_Poly].Cancel ()
                        )catch()
                    )
                )catch()
            )

        if success == true then(
            try(
                $.modifiers[#Edit_Poly].Cancel ()

                $.modifiers[#Edit_Poly].ScaleSelection finalSubobjectPos axis:$.transform

                $.modifiers[#Edit_Poly].Commit ()
            )catch()
        )

        if selection.count < 100 then(
            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()

            try(
                delete $TwoClickMoveToolCopy
            )catch()
        )

        if snapWasOnAtStart == true then(
            snapMode.active = true
        )

        -- Remove vertical grid if it exists

            if mainDistance == "z" then(
                try(
                    delete $callisScriptsVerticalGrid
                )catch()
            )

        max select

        myCoolDialogs = undefined
    )
)

disableRelevantEventHandlersForCertainOperationsVariable.disableOnNodeAddedEventHandlers()

startTool scale1DTool

disableRelevantEventHandlersForCertainOperationsVariable.enableOnNodeAddedEventHandlers()
