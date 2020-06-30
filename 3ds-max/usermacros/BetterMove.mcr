-- Progress

    -- Need to implement code so that when world point == an existing reference when another reference is already being inferred to, the reference below the mouse becomes the new active reference
    -- Need code to stop first reference point being overwritten once the 6th reference is made, and instead to skip it and overwrite reference two instead, since reference one is the original click position and will always be relevant.
    -- When no reference is active, dimensions should refer to reference 1 (the original object location), not the last used reference if it is not reference 1
    -- c.modifiers[#Edit_Poly]-type things might need to be rewritten—what happens if there are multiple of the given modifiers on the object. If it chooses the top one, for example, then we have a problem if we're operating on not the top version of the given modifier.
    -- Holding shift should lock to nearest axis, not whatever direction it is currently moved in
    -- If mouse is moved into a position where z reference is activated before tool starts, the object doesn't move. This is because mouse is snapped to the main grid which is horizontal, so worldPointFromHWNDSecondary reading shows z position hasn't changed from the originall position, and z reference wants to only move on z axis.
    -- Need code to add all layer names to the list of toolTips, as one potential toolTip reflects one of any of the layer names. Seems worth the computational saving to just use whatever layer names exist at start of move session, rather than constantly screening for layers created during session. Actually, should maybe screen every few seconds or something.
    -- Need to put correct units in the displayDistance rollout (currently it is always mm)
    -- Distance displayed is sightly wrong. Need to figure out why and fix.
    -- Need code to factor in screen size for dialogs
    -- If function detects undo or redo has just occurred, it doesn't do anything so runs next time as though the user has changed selection. Need to add code here.
    -- Objects that have been scaled move incorrectly in subobject mode until their xForms are reset. Doesn't seem to happen when in a modifier, just when in the base object.

-- Useful pieces of code

    -- $.GetCommandMode()
    -- BetterToolsstartmovesessiontimer.stop()

MacroScript betterMove category:"BetterTools" tooltip:"BetterMove" Icon:#("BetterMove",1)(
    -- Variables etc.

        -- Preferences

            local selectionAutoLockPreference
            local objectReferencePreference
            local disableObjectReferenceWhenEdgeOrFaceSnapsAreEnabledPreference

        -- Variables

            -- Preference

                local betterMoveIni = (getdir #plugcfg_ln) + "/BetterTools/BetterMove.ini"

            -- Get pivot position

                local vertsOfEdge
                local vertSel
                local vertsOfFace

            local mousePosOnFirstClick
            local mousePosOnToolStart
            local pivotPositionOnFirstClick
            local bSelectionPosOnFirstClick
            local pivotPositionOnToolStart
            local bSelectionPosOnToolStart

            local subObjectCountHasChanged
            local subObjectCountOnLastRun

            local moveableSelectionExistedOnLastRun

            local toolWasStarted = false

            local HWNDOnLastRun
            local HWNDOnCurrentRun

            local userHasDraggedSubselection = false

            local mouseHasBeenUnclicked2 = false

            local selectionOnLastRound
            local selectionOnCurrentRound

            local lastFinalSubobjectPos = [0,0,0]

            local objectWasUnderMouseOnFirstClick

            local bSelectionOriginalPos

            local startMovingFromSelectionsPivot = false

            local bSelection1pos

            local SubselectionCount

            global lastUndoWasMove = false

            local selectionPositionsRelativeToFirstClickPointArray = #()

            local ignoreNextCallOfStopClause = false

            local stopCodeHasRun = false

            local lastAxisConstraints

            local mouseHasBeenClicked = false

            local subObjectLevelVariable

            local undoOrRedoJustOccurred = false

            -- Global variables to allow functions from within this script to be run by callbacks

                global callbackItem
                global changeVariableWhenSelectionIsChangedFunction
                global undoTwiceIfRelevantFunction
                global redoTwiceIfRelevantFunction
                global changeVariableOnUndoOrRedo

            -- Variables to organise

                local selectionArrayBeforeUndoOrRedo = #()

                local currentMoveHasAlreadyBeenStopped = false

            -- selectionUnlockedBitmapFile

                if (colorMan.getColorTheme() == #light) then(
                    local selectionUnlockedBitmapFile = (openBitmap @"$scripts/BetterTools/Images/SelectionUnlockedLight.png")
                )else(
                    local selectionUnlockedBitmapFile = (openBitmap @"$scripts/BetterTools/Images/SelectionUnlockedDark.png")
                )

                -- Toggling axis icon

                    local maxINIFile = getMAXIniFile()

                    local turnAxisIconBackOn

                -- Toggling snap visibility

                    local originalGridSnapState = snapMode.getOSnapItemActive 4 1
                    local originalSnapDisplayState = snapMode.display

                local axisReferenceLocked = false

                local shiftKeyStateBoolean = false

                local shiftKeyStateOnLastFreeMoveBoolean = false

                local modifierKeysObject = dotNetClass "system.windows.Forms.Control"

                local distanceEditTextTextString = ""

                local subObjectLevelBeforeModifierParameterChange

                local SubselectionExists = false

                local moveInSubobjectMode
                local selectAndMoveMode = false

                local selectionChanged = false

                local mousePos2D = undefined

                local stopMovingOnMouseUnclicked = false

                local stopTryingToStartBetterToolsStopToolOnMouseUnclickedTimer

                local BetterToolsStopToolOnMouseUnclickedTimerStarted

                local originalDisplayUnits = units.DisplayType
                local turnSelectionLockBackOn = false

                local maxChildrenHWNDs
                local worldPointFromHWND
                local worldPointFromHWNDSecondary = [0,0,0] -- Need to give this a value, as the function defines it in a try-catch statement so in some cases might not define it at all

                local onMousePointFunctionWasRunOnStart = false

                local mouseHasBeenUnclicked = false

                local toggleSelectionLockAfterCurrentMove = false

                global betterMove -- When a distance is entered, the stopTool function doesn't recognise the tool and so can't stop it (which is weird, as it used to recognise it before all the code was added to start the tool on selection change rather than with a while loop).

                local moveToolActive = false

                global clicknoGlobalVariable = 0

                local conditionToSetSelectAndMoveModeVariableToOnStop -- This variable is used when changing selection lock mid-operation. If selection lock is changed, the selectAndMoveMode variable needs to change for the next move, however it can't be changed until the end of the current move, or else the mouseMove/mousePoint code would be told to do different things.

                -- Translated current curves

                    local translatedCurrentCurvesMatrix1
                    local translatedCurrentCurvesMatrix2

                    local translatedCurrentCurvesArray1
                    local translatedCurrentCurvesArray2

                -- Getting max window coordinates to place rollouts

                    local maxWindowHWND
                    local maxWindowSizeAndPosition
                    local bottomRightOfWindow

            -- Stopping move session

                local toolIsInactive = true

                local moveModeIsActive

                local toolTipHWNDIsDisplayingAToolTip = false

                local toolTipHWNDNumber = 1

                local toolTipsArray = #(
                    "",
                    "Select by Name",
                    "Select Object",
                    "Selection Filter",
                    "Create Link from Child to Parent",
                    "Break an Existing Link",
                    "Bind to Space Warp",
                    "Rectangular Selection Region",
                    "Window / Crossing",
                    "Select and Move Objects",
                    "Select and Non-uniformly Scale Objects ",
                    "Select and Rotate Objects",
                    "Use Pivot Point Center",
                    "Reference Coordinate System",
                    "Keyboard Shortcut Override Toggle",
                    "Snaps Toggle",
                    "Angle Snap Toggle",
                    "Percent Snap Toggle",
                    "Spinner Snap Toggle",
                    "Named Selection Sets",
                    "Mirror",
                    "Quick Align",
                    "Schematic View (Open)",
                    "Material Editor",
                    "Render Setup",
                    "Render Production",
                    "Create",
                    "Modify",
                    "Hierarchy",
                    "Motion",
                    "Display",
                    "Utilities",
                    "Isolate Selection Toggle",
                    "Selection Lock Toggle",
                    "Absolute Mode Transform Type-In",
                    "Adaptive Degradation",
                    "3ds Max Educational",
                    "Key Mode Toggle",
                    "Time Configuration",
                    "Go to End",
                    "Next Frame",
                    "Play Animation",
                    "Previous Frame",
                    "Go to Start",
                    "Default In/Out Tangents for New Keys (Auto Tangent)",
                    "Field-of-View",
                    "Pan View",
                    "Orbit Point of Interest",
                    "Maximize Viewport Toggle",
                    "Zoom Extents All Selected",
                    "Zoom Extents Selected",
                    "Zoom All",
                    "Zoom",
                    "0",
                    "Render Presets",
                    ">>> @!&*# <<<",
                    "Spacing Tool",
                    "Transform Gizmo X Constraint",
                    "Transform Gizmo Y Constraint",
                    "Transform Gizmo XY Plane Constraint",
                    "Transform Gizmo YZ Plane Constraint",
                    "Transform Gizmo ZX Plane Constraint",
                    "Circular Selection Region",
                    "Fence Selection Region",
                    "Lasso Selection Region",
                    "Paint Selection Region",
                    "Select and Uniformly Scale Objects",
                    "Select and Squash Objects",
                    "Use Selection Center",
                    "Use Transform Coordinate Center",
                    "Align",
                    "Normal Align",
                    "Place Highlight",
                    "Align Camera",
                    "Align to View",
                    "Default In/Out Tangents for New Keys (Spline)",
                    "Render Iterative",
                    "ActiveShade",
                    "Stop Animation",
                    "Default In/Out Tangents for New Keys (Slow)",
                    "Default In/Out Tangents for New Keys (Fast)",
                    "Default In/Out Tangents for New Keys (Step)",
                    "Default In/Out Tangents for New Keys (Linear)",
                    "Default In/Out Tangents for New Keys (Smooth)",
                    "Zoom Region",
                    "2D Pan Zoom Mode",
                    "Zoom Extents",
                    "Walk Through",
                    "Orbit",
                    "Orbit Selected",
                    "Orbit SubObject",
                    "Zoom Extents All"
                )

            -- Distance editText

                -- Position Distance editText

                    local positionDistanceEditTextBoolean = false
                    global BetterTools32Assembly1

                global distanceEntered = undefined

                distanceEnteredSecondCallbackBoolean = false

            -- Grids

                local originalActiveGrid = activeGrid

                -- Rotating grids to viewport

                    -- Declaring the variables as non-globals before the function called in the callback. For some reason if this isn't done, they come back as undefined when the function is called, despite having values assigned when declared as globals.

                        lastPlaneRotationX
                        lastPlaneRotationY
                        lastPlaneRotationZ

                        global lastPlaneRotationX = 0
                        global lastPlaneRotationY = 0
                        global lastPlaneRotationZ = 0

            -- Reference

                -- Reference screen coordinates, base

                    global referenceScreenCoordinatesBaseArray = #(undefined, undefined, undefined, undefined, undefined)

                -- Reference curve

                    global referenceCurveXArray1 = #(undefined, undefined, undefined, undefined, undefined)
                    global referenceCurveXArray2 = #(undefined, undefined, undefined, undefined, undefined)

                    global referenceCurveYArray1 = #(undefined, undefined, undefined, undefined, undefined)
                    global referenceCurveYArray2 = #(undefined, undefined, undefined, undefined, undefined)

                    global referenceCurveZArray1 = #(undefined, undefined, undefined, undefined, undefined)
                    global referenceCurveZArray2 = #(undefined, undefined, undefined, undefined, undefined)

                -- World point on infer

                    global worldPointOnInferArray = #(undefined, undefined, undefined, undefined, undefined)

                local lastCreatedReferenceNumber = 0
                local totalNumberOfReferences = 0
                local screenCoordinatesCompanionNumber = 1

                snapRadius = 10

                -- Base point translations array

                    basePointTranslationsArray = #([0 ,0])

                    for a = 1 to snapRadius do(
                        append basePointTranslationsArray [a, a]

                        append basePointTranslationsArray [a, -a]

                        append basePointTranslationsArray [-a, a]

                        append basePointTranslationsArray [-a, -a]
                    )

                -- Reference Lines

                    -- Declaring

                        local referenceLineSecondary

                        local referenceLineLocked

                        local referenceLineX

                        local referenceLineY

                        local referenceLineZ

                        local referenceEndPointSecondary

                        local referenceEndPointLocked

                        local referenceEndPointX

                        local referenceEndPointY

                        local referenceEndPointZ

                    -- Defining

                        try(
                            referenceLineSecondary = getNodeByName "Reference Line, Secondary"

                            referenceLineLocked = getNodeByName "Reference Line, Locked"

                            referenceLineX = getNodeByName "Reference Line, X"

                            referenceLineY = getNodeByName "Reference Line, Y"

                            referenceLineZ = getNodeByName "Reference Line, Z"

                            referenceEndPointSecondary = getNodeByName "Reference Point, End, Secondary"

                            referenceEndPointLocked = getNodeByName "Reference Point, End, Locked"

                            referenceEndPointX = getNodeByName "Reference Point, End, X"

                            referenceEndPointY = getNodeByName "Reference Point, End, Y"

                            referenceEndPointZ = getNodeByName "Reference Point, End, Z"
                        )catch()

                -- Last used reference

                    lastUsedReference = "Z"

                -- Last reference number snapped to

                    local lastReferenceNumberSnappedToX
                    local lastReferenceNumberSnappedToY
                    local lastReferenceNumberSnappedToZ
                    local lastReferenceNumberSnappedToAny = 1

            -- Object variables

                global betterMoveCurrentObject
                local currentModifier = undefined
                local currentsubobjectLevel = 0

                local b
                local c
                local bSelection
                local cSelection
                local dSelection
                local eSelection

            -- Variables to organise

                local selectionWireframeLayer = layerManager.getLayerFromName "BetterTools, Selection Wireframes"
                local originalPosition
                global success = false
                global firstClickPos
                local lockToAxis = "none"
                local snapWasOnAtStart
                local nonOrthoAxisLock
                local worldPointOnAxisLock = [0,0,0]
                local worldPointOnShiftCtrlAltClick = [0,0,0]
                local firstMove

                global startMoving
                local txt
                local betterMoveDistance = undefined

            -- Distance variables

                local xPosOne
                local yPosOne
                local zPosOne

                local xPosTwo
                local yPosTwo
                local zPosTwo

                local xMousePosCurrent
                local yMousePosCurrent
                local zMousePosCurrent
                local allMousePosCurrent

                local xObjectPosCurrent = 0
                local yObjectPosCurrent = 0
                local zObjectPosCurrent = 0

                local xChangeOne
                local yChangeOne
                local zChangeOne

                local xChangeTwo
                local yChangeTwo
                local zChangeTwo

                local xChangeThree
                local yChangeThree
                local zChangeThree

                local xChangeFour
                local yChangeFour
                local zChangeFour

                local xMousePosCurrent
                local yMousePosCurrent
                local zMousePosCurrent

                local xMousePosCurrentLocked
                local yMousePosCurrentLocked
                local zMousePosCurrentLocked

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

                local betterMoveDistancePreliminary
                local totalDistanceMoved = 0

                local mainDistance

            -- Position variables

                global currentMousePositionGlobalVariable = [0,0,0]
                local finalSubobjectPos = [0,0,0]
                local bPositionFinal = [0,0,0]

        -- Inclusions

            include "$scripts/Startup/BetterTools/BetterMove.ms"

        -- Functions

            -- Get pivot position

                function VertSelMiddleCenter vertSel obj = (
                    posX = 0
                    posY = 0
                    posZ = 0
                    cnt = 0

                    -- Build coordinate arrays

                        -- Editable poly

                            if (modPanel.getCurrentObject() as string) == "Editable Poly" then(
                                for i in vertSel do(
                                    posX = posX + (in coordsys world (polyop.getVert obj i).x)
                                    posY = posY + (in coordsys world (polyop.getVert obj i).y)
                                    posZ = posZ + (in coordsys world (polyop.getVert obj i).z)
                                    cnt = cnt + 1
                                )
                            )

                        -- Edit poly

                            if matchPattern (modPanel.getCurrentObject() as string) Pattern:"Edit_Poly:*" then(
                                for i in vertSel do(
                                    posX = posX + ((EditPolyMod.getVertex obj.modifiers[#Edit_Poly] i).x)
                                    posY = posY + ((EditPolyMod.getVertex obj.modifiers[#Edit_Poly] i).y)
                                    posZ = posZ + ((EditPolyMod.getVertex obj.modifiers[#Edit_Poly] i).z)
                                    cnt = cnt + 1
                                )
                            )

                    middleX = posX / cnt
                    middleY = posY / cnt
                    middleZ = posZ / cnt

                    point3 middleX middleY middleZ
                )

                function VertsCenter selObj = (
                    vertSel = undefined

                    -- Editable poly

                        if (modPanel.getCurrentObject() as string) == "Editable Poly" then(
                            if (vertSel = polyop.getVertSelection selObj).count > 0 then(
                                (VertSelMiddleCenter vertSel selObj)
                            )
                        )else(
                            -- Edit poly

                                if matchPattern (modPanel.getCurrentObject() as string) Pattern:"Edit_Poly:*" then(
                                    if (vertSel = ((EditPolyMod.GetSelection selObj.modifiers[#Edit_Poly] #Vertex) as array)).count > 0 then(
                                        (VertSelMiddleCenter vertSel selObj)
                                    )
                                )
                        )
                )

                function EdgesCenter selObj = (
                    -- Editable poly

                        if (modPanel.getCurrentObject() as string) == "Editable Poly" then(
                            if (edgeSel = polyop.GetEdgeSelection selObj as array).count > 0 then(
                                vertsOfEdge = #()

                                for i in edgeSel do(
                                    join vertsOfEdge (polyop.getEdgeVerts selObj i)
                                )
                            )
                        )

                    -- Edit poly

                        if matchPattern (modPanel.getCurrentObject() as string) Pattern:"Edit_Poly:*" then(
                            if (edgeSel = ((EditPolyMod.GetSelection selObj.modifiers[#Edit_Poly] #Edge) as array)).count > 0 then(
                                vertsOfEdge = #()

                                for i in edgeSel do(
                                    append vertsOfEdge (EditPolyMod.GetEdgeVertex selObj.modifiers[#Edit_Poly] i 1)
                                    append vertsOfEdge (EditPolyMod.GetEdgeVertex selObj.modifiers[#Edit_Poly] i 2)
                                )
                            )
                        )

                    if vertsOfEdge.count != 0 do(
                        VertSelMiddleCenter vertsOfEdge selObj
                    )
                )

                function FacesCenter selObj = (
                    -- Editable poly

                        if (modPanel.getCurrentObject() as string) == "Editable Poly" then(
                            if (faceSel = polyop.GetFaceSelection selObj as array).count > 0 then(
                                vertsOfFace = #()

                                for i in faceSel do(
                                    join vertsOfFace (polyop.getFaceVerts selObj i)
                                )
                            )
                        )

                    -- Edit poly

                        if matchPattern (modPanel.getCurrentObject() as string) Pattern:"Edit_Poly:*" then(
                            if (faceSel = ((EditPolyMod.GetSelection selObj.modifiers[#Edit_Poly] #Face) as array)).count > 0 then(
                                vertsOfFace = #()

                                for i in faceSel do(
                                    for a = 1 to (EditPolyMod.GetFaceDegree selObj.modifiers[#Edit_Poly] i) do(
                                        append vertsOfFace (EditPolyMod.GetFaceVertex selObj.modifiers[#Edit_Poly] i a)
                                    )
                                )
                            )
                        )

                    if vertsOfFace.count != 0 do(
                        (VertSelMiddleCenter vertsOfFace selObj)
                    )
                )

                fn getPivotPosition = (
                    -- Variables

                        selObj = $

                    case subobjectlevel of(
                        1: (VertsCenter selObj)
                        2: (EdgesCenter selObj)
                        3: (EdgesCenter selObj)
                        4: (FacesCenter selObj)
                        5: (FacesCenter selObj)
                    )
                )

            -- Determine whether subObjectLevel is 0

                fn subObjectLevelIsZero = (
                    if subObjectLevel == 0 or subobjectLevel == undefined then(
                        true
                    )else(
                        false
                    )
                )

            -- Determine whether a moveable modifier is active

                fn isCurrentModifierMoveable = (
                    if (modPanel.getCurrentObject() as string) == "Editable Poly" or (modPanel.getCurrentObject() as string) == "Editable Mesh" or matchPattern (modPanel.getCurrentObject() as string) Pattern:"Edit_Poly:*" then(
                        true
                    )else(
                        if subObjectLevelIsZero() then(
                            true
                        )else(
                            false
                        )
                    )
                )

            -- Determine whether selection is locked

                fn selLocked = (
                    undo off(
                        -- Variables

                            selectionlock = false

                            sel = selection as array

                        clearselection()

                        if selection.count == 0 then(
                            selectionlock = false
                        )else(
                            selectionlock = true
                        )

                        select sel

                        selectionlock
                    ) -- (Undo end bracket)
                )

            -- Determine whether a Subselection exists

                fn determineWhetherSubselectionExistsFunction = (
                    undo off(
                        if isCurrentModifierMoveable() then(
                             SubselectionExists = false

                            -- Editable poly

                                if (modPanel.getCurrentObject() as string) == "Editable Poly" then(
                                    if subObjectLevel == 1 and ((polyop.getVertSelection selection[1]).numberset) != 0 then(
                                        SubselectionExists = true
                                    )

                                    if (subObjectLevel == 2 or subObjectLevel == 3) and ((polyop.getEdgeSelection selection[1]).numberset) != 0 then(
                                        SubselectionExists = true
                                    )

                                    if (subObjectLevel == 4 or subObjectLevel == 5) and ((polyop.getFaceSelection selection[1]).numberset) != 0 then(
                                        SubselectionExists = true
                                    )
                                )

                            -- Edit poly

                                if matchPattern (modPanel.getCurrentObject() as string) Pattern:"Edit_Poly:*" then(
                                    if subObjectLevel == 1 and (EditPolyMod.GetSelection $.Edit_Poly #Vertex) as string != "#{}" then(
                                        SubselectionExists = true
                                    )

                                    if (subObjectLevel == 2 or subObjectLevel == 3) and (EditPolyMod.GetSelection $.Edit_Poly #Edge) as string != "#{}" then(
                                        SubselectionExists = true
                                    )

                                    if (subObjectLevel == 4 or subObjectLevel == 5) and (EditPolyMod.GetSelection $.Edit_Poly #Face) as string != "#{}" then(
                                        SubselectionExists = true
                                    )
                                )

                            -- Editable mesh

                                if (modPanel.getCurrentObject() as string) == "Editable Mesh" then(
                                    if subObjectLevel == 1 and ((getVertSelection selection[1]) as string) != "#{}" then(
                                        SubselectionExists = true
                                    )

                                    if (subObjectLevel == 2 or subObjectLevel == 3) and ((getEdgeSelection selection[1]) as string) != "#{}" then(
                                        SubselectionExists = true
                                    )

                                    if (subObjectLevel == 4 or subObjectLevel == 5) and ((getFaceSelection selection[1]) as string) != "#{}" then(
                                        SubselectionExists = true
                                    )
                                )
                        )else(
                            SubselectionExists = "Not moveable"
                        )

                        SubselectionExists
                    ) -- (Undo end bracket)
                )

            -- Determine whether something moveable is selected

                fn somethingMoveableIsSelected = (
                    if selection.count == 0 or (not subobjectLevelIsZero() and determineWhetherSubselectionExistsFunction() == false) then(
                        false
                    )else(
                        true
                    )
                )

            -- Determine whether moveable selection is 1

                fn moveableSelectionIsOne = (
                    if (selection.count == 1 and subObjectLevelIsZero()) or (not subObjectLevelIsZero() and SubselectionCount == 1) then(
                        true
                    )else(
                        false
                    )
                )

            -- Determine whether the user is clicking on the selected object (or user is clicking anywhere with selection locked)

                fn userIsClickingOnEitherSelectionOrNothing = (
                    if ((mouse.buttonStates as string) == "#{1}" or (mouse.buttonStates as string) == "#{1, 3}") and mouseHasBeenUnclicked == true and (selectionOnCurrentRound as string) == (selectionOnLastRound as string) and somethingMoveableIsSelected() then(
                        true
                    )else(
                        false
                    )
                )

            -- Create BetterTools objects

                fn createBetterToolsObjectsFunction = (
                    -- Selection

                        local selectionToReselect = (selection as array)
                        local subSelectionToReselect = undefined
                        local subobjectLevelToReenter = subObjectLevel
                        local modifierType = undefined

                        if not subObjectLevelIsZero() then(
                            -- Editable poly

                                if (modPanel.getCurrentObject() as string) == "Editable Poly" then(
                                    modifierType = "Editable Poly"

                                    if subObjectLevel == 1 then(
                                        subSelectionToReselect = (polyop.getVertSelection selection[1])
                                    )

                                    if (subObjectLevel == 2 or subObjectLevel == 3) then(
                                        subSelectionToReselect = (polyop.getEdgeSelection selection[1])
                                    )

                                    if (subObjectLevel == 4 or subObjectLevel == 5) then(
                                        subSelectionToReselect = (polyop.getFaceSelection selection[1])
                                    )
                                )

                            -- Edit poly

                                if matchPattern (modPanel.getCurrentObject() as string) Pattern:"Edit_Poly:*" then(
                                    modifierType = "Edit Poly"

                                    if subObjectLevel == 1 then(
                                        subSelectionToReselect = (EditPolyMod.GetSelection $.modifiers[#Edit_Poly] #Vertex)
                                    )

                                    if (subObjectLevel == 2 or subObjectLevel == 3) then(
                                        subSelectionToReselect = (EditPolyMod.GetSelection $.modifiers[#Edit_Poly] #Edge)
                                    )

                                    if (subObjectLevel == 4 or subObjectLevel == 5) then(
                                        subSelectionToReselect = (EditPolyMod.GetSelection $.modifiers[#Edit_Poly] #Face)
                                    )
                                )

                            -- Editable mesh

                                if (modPanel.getCurrentObject() as string) == "Editable Mesh" then(
                                    modifierType = "Editable Mesh"

                                    if subObjectLevel == 1 then(
                                        subSelectionToReselect = (getVertSelection selection[1])
                                    )

                                    if (subObjectLevel == 2 or subObjectLevel == 3) then(
                                        subSelectionToReselect = (getEdgeSelection selection[1])
                                    )

                                    if (subObjectLevel == 4 or subObjectLevel == 5) then(
                                        subSelectionToReselect = (getFaceSelection selection[1])
                                    )
                                )
                        )

                        max select none

                    -- Create layers

                        LayerManager.newLayerFromName "BetterTools"

                        LayerManager.newLayerFromName "BetterTools, Grids"

                        LayerManager.newLayerFromName "BetterTools, Object Reference"

                        LayerManager.newLayerFromName "BetterTools, Selection Wireframes"

                        -- Variables

                            selectionWireframeLayer = layerManager.getLayerFromName "BetterTools, Selection Wireframes"

                    -- Organise layers

                        (LayerManager.getLayerFromName "BetterTools, Grids").setParent (LayerManager.getLayerFromName "BetterTools")

                        (LayerManager.getLayerFromName "BetterTools, Object Reference").setParent (LayerManager.getLayerFromName "BetterTools")

                        (LayerManager.getLayerFromName "BetterTools, Selection Wireframes").setParent (LayerManager.getLayerFromName "BetterTools")

                    -- Create grids

                        grid effect:0 transform:(matrix3 [-1,0,0] [0,-1,0] [0,0,1] [0,0,0]) isSelected:on isHidden:true length:50 width:50 name:"BetterToolsMainGrid"

                        grid effect:0 transform:(matrix3 [-1,0,0] [0,-1,0] [0,0,1] [0,0,0]) isSelected:on isHidden:true length:50 width:50 name:"BetterToolsXGrid"

                        grid effect:0 transform:(matrix3 [-1,0,0] [0,-1,0] [0,0,1] [0,0,0]) isSelected:on isHidden:true length:50 width:50 name:"BetterToolsYGrid"

                        grid effect:0 transform:(matrix3 [-1,0,0] [0,-1,0] [0,0,1] [0,0,0]) isSelected:on isHidden:true length:50 width:50 name:"BetterToolsZGrid"

                        rotate $BetterToolsZGrid (angleaxis 90 [1,0,0])

                    -- Create object reference objects

                        -- Points

                            Point effect:0 transform:(matrix3 [-1,0,0] [0,-1,0] [0,0,1] [0,0,0]) isSelected:off name:"Reference Point, End, Locked" isHidden:true

                            Point effect:0 transform:(matrix3 [-1,0,0] [0,-1,0] [0,0,1] [0,0,0]) isSelected:off name:"Reference Point, End, Secondary" isHidden:true

                            Point effect:0 transform:(matrix3 [-1,0,0] [0,-1,0] [0,0,1] [0,0,0]) isSelected:off name:"Reference Point, End, X" isHidden:true

                            Point effect:0 transform:(matrix3 [-1,0,0] [0,-1,0] [0,0,1] [0,0,0]) isSelected:off name:"Reference Point, End, Y" isHidden:true

                            Point effect:0 transform:(matrix3 [-1,0,0] [0,-1,0] [0,0,1] [0,0,0]) isSelected:off name:"Reference Point, End, Z" isHidden:true

                            -- Variables

                                referenceEndPointSecondary = getNodeByName "Reference Point, End, Locked"

                                referenceEndPointLocked = getNodeByName "Reference Point, End, Secondary"

                                referenceEndPointX = getNodeByName "Reference Point, End, X"

                                referenceEndPointY = getNodeByName "Reference Point, End, Y"

                                referenceEndPointZ = getNodeByName "Reference Point, End, Z"

                        -- Lines

                            addNewSpline (SplineShape pos:[0,0,0] name:"Reference Line, Locked")
                            referenceLineLocked = getNodeByName "Reference Line, Locked"
                            addKnot referenceLineLocked 1 #corner #line [0,0,0]
                            addKnot referenceLineLocked 1 #corner #line [0,0,0]
                            updateShape referenceLineLocked
                            select referenceLineLocked
                            setKnotSelection referenceLineLocked 1 #(2) keep:false
                            macros.run "Modifiers" "Spline_Select"
                            macros.run "Modifiers" "Linked_xform"
                            setKnotSelection referenceLineLocked 1 #() keep:false
                            referenceLineLocked.Linked_XForm.Control = referenceEndPointLocked
                            modPanel.setCurrentObject referenceLineLocked.baseObject
                            setKnotSelection referenceLineLocked 1 #() keep:false
                            modPanel.setCurrentObject referenceLineLocked.modifiers[#Linked_XForm]
                            macros.run "Modifiers" "Spline_Select"
                            subobjectLevel = 3
                            modPanel.setCurrentObject referenceLineLocked.modifiers[#SplineSelect]
                            freeze referenceLineLocked
                            referenceLineLocked.showFrozenInGray = false

                            addNewSpline (SplineShape pos:[0,0,0] name:"Reference Line, Secondary")
                            referenceLineSecondary = getNodeByName "Reference Line, Secondary"
                            addKnot referenceLineSecondary 1 #corner #line [0,0,0]
                            addKnot referenceLineSecondary 1 #corner #line [0,0,0]
                            updateShape referenceLineSecondary
                            select referenceLineSecondary
                            setKnotSelection referenceLineSecondary 1 #(2) keep:false
                            macros.run "Modifiers" "Spline_Select"
                            macros.run "Modifiers" "Linked_xform"
                            setKnotSelection referenceLineSecondary 1 #() keep:false
                            referenceLineSecondary.Linked_XForm.Control = referenceEndPointSecondary
                            modPanel.setCurrentObject referenceLineSecondary.baseObject
                            setKnotSelection referenceLineSecondary 1 #() keep:false
                            modPanel.setCurrentObject referenceLineSecondary.modifiers[#Linked_XForm]
                            macros.run "Modifiers" "Spline_Select"
                            subobjectLevel = 3
                            modPanel.setCurrentObject referenceLineSecondary.modifiers[#SplineSelect]
                            freeze referenceLineSecondary
                            referenceLineSecondary.showFrozenInGray = false

                            addNewSpline (SplineShape pos:[0,0,0] name:"Reference Line, X")
                            referenceLineX = getNodeByName "Reference Line, X"
                            referenceLineX.wirecolor = color 255 0 0
                            addKnot referenceLineX 1 #corner #line [0,0,0]
                            addKnot referenceLineX 1 #corner #line [0,0,0]
                            updateShape referenceLineX
                            select referenceLineX
                            setKnotSelection referenceLineX 1 #(2) keep:false
                            macros.run "Modifiers" "Spline_Select"
                            macros.run "Modifiers" "Linked_xform"
                            referenceLineX.Linked_XForm.Control = referenceEndPointX
                            modPanel.setCurrentObject referenceLineX.baseObject
                            setKnotSelection referenceLineX 1 #() keep:false
                            modPanel.setCurrentObject referenceLineX.modifiers[#Linked_XForm]
                            macros.run "Modifiers" "Spline_Select"
                            subobjectLevel = 3
                            modPanel.setCurrentObject referenceLineX.modifiers[#SplineSelect]
                            freeze referenceLineX
                            referenceLineX.showFrozenInGray = false

                            addNewSpline (SplineShape pos:[0,0,0] name:"Reference Line, Y")
                            referenceLineY = getNodeByName "Reference Line, Y"
                            referenceLineY.wirecolor = color 0 255 0
                            addKnot referenceLineY 1 #corner #line [0,0,0]
                            addKnot referenceLineY 1 #corner #line [0,0,0]
                            updateShape referenceLineY
                            select referenceLineY
                            setKnotSelection referenceLineY 1 #(2) keep:false
                            macros.run "Modifiers" "Spline_Select"
                            macros.run "Modifiers" "Linked_xform"
                            referenceLineY.Linked_XForm.Control = referenceEndPointY
                            modPanel.setCurrentObject referenceLineY.baseObject
                            setKnotSelection referenceLineY 1 #() keep:false
                            modPanel.setCurrentObject referenceLineY.modifiers[#Linked_XForm]
                            macros.run "Modifiers" "Spline_Select"
                            subobjectLevel = 3
                            modPanel.setCurrentObject referenceLineY.modifiers[#SplineSelect]
                            freeze referenceLineY
                            referenceLineY.showFrozenInGray = false

                            addNewSpline (SplineShape pos:[0,0,0] name:"Reference Line, Z")
                            referenceLineZ = getNodeByName "Reference Line, Z"
                            referenceLineZ.wirecolor = color 0 0 255
                            addKnot referenceLineZ 1 #corner #line [0,0,0]
                            addKnot referenceLineZ 1 #corner #line [0,0,0]
                            updateShape referenceLineZ
                            select referenceLineZ
                            setKnotSelection referenceLineZ 1 #(2) keep:false
                            macros.run "Modifiers" "Spline_Select"
                            macros.run "Modifiers" "Linked_xform"
                            referenceLineZ.Linked_XForm.Control = referenceEndPointZ
                            modPanel.setCurrentObject referenceLineZ.baseObject
                            setKnotSelection referenceLineZ 1 #() keep:false
                            modPanel.setCurrentObject referenceLineZ.modifiers[#Linked_XForm]
                            macros.run "Modifiers" "Spline_Select"
                            subobjectLevel = 3
                            modPanel.setCurrentObject referenceLineZ.modifiers[#SplineSelect]
                            freeze referenceLineZ
                            referenceLineZ.showFrozenInGray = false

                    -- Put objects in layers

                        -- Grids

                            (LayerManager.getLayerFromName "BetterTools, Grids").addnode $BetterToolsMainGrid

                            (LayerManager.getLayerFromName "BetterTools, Grids").addnode $BetterToolsXGrid

                            (LayerManager.getLayerFromName "BetterTools, Grids").addnode $BetterToolsYGrid

                            (LayerManager.getLayerFromName "BetterTools, Grids").addnode $BetterToolsZGrid

                        -- Points

                            (LayerManager.getLayerFromName "BetterTools, Object Reference").addnode referenceEndPointSecondary

                            (LayerManager.getLayerFromName "BetterTools, Object Reference").addnode referenceEndPointLocked

                            (LayerManager.getLayerFromName "BetterTools, Object Reference").addnode referenceEndPointX

                            (LayerManager.getLayerFromName "BetterTools, Object Reference").addnode referenceEndPointY

                            (LayerManager.getLayerFromName "BetterTools, Object Reference").addnode referenceEndPointZ

                        -- Lines

                            (LayerManager.getLayerFromName "BetterTools, Object Reference").addnode referenceLineSecondary

                            (LayerManager.getLayerFromName "BetterTools, Object Reference").addnode referenceLineLocked

                            (LayerManager.getLayerFromName "BetterTools, Object Reference").addnode referenceLineX

                            (LayerManager.getLayerFromName "BetterTools, Object Reference").addnode referenceLineY

                            (LayerManager.getLayerFromName "BetterTools, Object Reference").addnode referenceLineZ

                    -- Freeze layers

                        (LayerManager.getLayerFromName "BetterTools").isFrozen = on

                    -- Select original selection

                        deselect selection

                        try(
                            select selectionToReselect

                            if subSelectionToReselect != undefined then(
                                subObjectLevel = subobjectLevelToReenter

                                if modifierType == "Editable Poly" then(
                                    if subObjectLevel == 1 then(
                                        $.EditablePoly.SetSelection #Vertex subSelectionToReselect
                                    )

                                    if subObjectLevel == 2 or subObjectLevel == 3 then(
                                        $.EditablePoly.SetSelection #Edge subSelectionToReselect
                                    )

                                    if subObjectLevel == 4 or subObjectLevel == 5 then(
                                        $.EditablePoly.SetSelection #Face subSelectionToReselect
                                    )
                                )

                                if modifierType == "Edit Poly" then(
                                    if subObjectLevel == 1 then(
                                        EditPolyMod.SetSelection $.modifiers[#Edit_Poly] #Vertex subSelectionToReselect
                                    )

                                    if subObjectLevel == 2 or subObjectLevel == 3 then(
                                        EditPolyMod.SetSelection $.modifiers[#Edit_Poly] #Edge subSelectionToReselect
                                    )

                                    if subObjectLevel == 4 or subObjectLevel == 5 then(
                                        EditPolyMod.SetSelection $.modifiers[#Edit_Poly] #Face subSelectionToReselect
                                    )
                                )

                                if modifierType == "Editable Mesh" then(
                                    if subObjectLevel == 1 then(
                                        setVertSelection $ subSelectionToReselect
                                    )

                                    if subObjectLevel == 2 or subObjectLevel == 3 then(
                                        setEdgeSelection $ subSelectionToReselect
                                    )

                                    if subObjectLevel == 4 or subObjectLevel == 5 then(
                                        setFaceSelection $ subSelectionToReselect
                                    )
                                )
                            )
                        )catch()

                    max move
                )

            -- Distance editText

                function CreateUser32Assembly forceRecompile:on = (
                    if forceRecompile or not iskindof ::BetterTools32Assembly1 dotnetobject or (::BetterTools32Assembly1.GetType()).name != "Assembly" do(
                        source = "using System;\n"
                        source += "using System.Runtime.InteropServices;\n"
                        source += "class user32\n"
                        source += "{\n"
                        source += " [DllImport(\"user32.DLL\", EntryPoint=\"GetWindowLong\")]\n"
                        source += " public static extern Int32 GetWindowLong(IntPtr hWnd, Int32 index);\n"
                        source += " [DllImport(\"user32.DLL\", EntryPoint=\"SetWindowLong\")]\n"
                        source += " public static extern Int32 SetWindowLong(IntPtr hWnd, Int32 index, Int32 newVal);\n"
                        source += "}\n"

                        csharpProvider = dotnetobject "Microsoft.CSharp.CSharpCodeProvider"
                        compilerParams = dotnetobject "System.CodeDom.Compiler.CompilerParameters"

                        compilerParams.GenerateInMemory = true
                        compilerResults = csharpProvider.CompileAssemblyFromSource compilerParams #(source)
                        ::BetterTools32Assembly1 = compilerResults.CompiledAssembly
                    )

                    ::BetterTools32Assembly1.CreateInstance "user32"
                )

                function GetWinClass = (
                    source = ""
                    source += "using System;\n"
                    source += "using System.Runtime.InteropServices;\n"
                    source += "public class Window\n"
                    source += "{\n"
                    source += "	[DllImport(\"user32.dll\")]\n"
                    source += "	public static extern bool SetWindowPos(int hWnd, int hWndArg, int Left, int Top, int Width, int Height, int hWndFlags);\n"
                    source += "	[DllImport(\"user32.dll\")]\n"
                    source += "	public static extern bool GetWindowRect(int hWnd, out POS rect);\n"
                    source += "	public struct POS\n"
                    source += "	{\n"
                    source += "		public int Left;\n"
                    source += "		public int Top;\n"
                    source += "		public int Right;\n"
                    source += "		public int Bottom;\n"
                    source += "	}\n"
                    source += "	public int[] GetWindowPosAndSize(int hWnd)\n"
                    source += "	{\n"
                    source += "		POS rect;\n"
                    source += "		if ( GetWindowRect(hWnd, out rect) )\n"
                    source += "		{\n"
                    source += "			return new int[] { rect.Left, rect.Top, rect.Right - rect.Left, rect.Bottom - rect.Top };\n"
                    source += "		}\n"
                    source += "		return null;\n"
                    source += "	}\n"
                    source += "}\n"

                    csharpProvider = dotnetobject "Microsoft.CSharp.CSharpCodeProvider"
                    compilerParams = dotnetobject "System.CodeDom.Compiler.CompilerParameters"
                    compilerParams.GenerateInMemory = on
                    compilerResults = csharpProvider.CompileAssemblyFromSource compilerParams #(source)
                    compilerResults.CompiledAssembly.CreateInstance "Window"
                )

                global getWinClassGlobalVariable = GetWinClass()

            -- Round number

                fn roundNumber numberToRound numberOfDP = (
                    mult = 10.0 ^ numberOfDP

                    (floor ((numberToRound * mult) + 0.5)) / mult
                )

            -- Reference

                -- Create reference

                    fn BetterToolsCreateReference = (
                        undo off(
                            -- Update current reference number and total number of references variables

                                if lastCreatedReferenceNumber != 5 then(
                                    lastCreatedReferenceNumber = lastCreatedReferenceNumber + 1
                                )else(
                                    lastCreatedReferenceNumber = 1
                                )

                                if totalNumberOfReferences != 5 then(
                                    totalNumberOfReferences = totalNumberOfReferences + 1
                                )else(
                                    totalNumberOfReferences = 5
                                )

                            -- Split current mouse position global variable into its X, Y and Z values

                                local currentMousePositionGlobalVariableX = currentMousePositionGlobalVariable[1]
                                local currentMousePositionGlobalVariableY = currentMousePositionGlobalVariable[2]
                                local currentMousePositionGlobalVariableZ = currentMousePositionGlobalVariable[3]

                            -- Update relevant reference screen coordinates, base variable

                                deleteItem referenceScreenCoordinatesBaseArray lastCreatedReferenceNumber
                                insertItem (gw.transPoint currentMousePositionGlobalVariable) referenceScreenCoordinatesBaseArray lastCreatedReferenceNumber

                            -- Update relevant reference curve variables

                                -- Create X, Y and Z companion variables to compare against the base position in order to calculate each curve

                                    local screenCoordinatesXCompanion = (gw.transPoint [(currentMousePositionGlobalVariableX + screenCoordinatesCompanionNumber),currentMousePositionGlobalVariableY,currentMousePositionGlobalVariableZ])
                                    local screenCoordinatesYCompanion = (gw.transPoint [currentMousePositionGlobalVariableX,(currentMousePositionGlobalVariableY + screenCoordinatesCompanionNumber),currentMousePositionGlobalVariableZ])
                                    local screenCoordinatesZCompanion = (gw.transPoint [currentMousePositionGlobalVariableX,currentMousePositionGlobalVariableY,(currentMousePositionGlobalVariableZ + screenCoordinatesCompanionNumber)])

                                -- Calculate and update each curve

                                    -- X

                                        deleteItem referenceCurveXArray1 lastCreatedReferenceNumber
                                        insertItem ((screenCoordinatesXCompanion[1] - referenceScreenCoordinatesBaseArray[lastCreatedReferenceNumber][1]) / (screenCoordinatesXCompanion[2] - referenceScreenCoordinatesBaseArray[lastCreatedReferenceNumber][2])) referenceCurveXArray1 lastCreatedReferenceNumber

                                        deleteItem referenceCurveXArray2 lastCreatedReferenceNumber
                                        insertItem ((screenCoordinatesXCompanion[2] - referenceScreenCoordinatesBaseArray[lastCreatedReferenceNumber][2]) / (screenCoordinatesXCompanion[1] - referenceScreenCoordinatesBaseArray[lastCreatedReferenceNumber][1])) referenceCurveXArray2 lastCreatedReferenceNumber

                                    -- Y

                                        deleteItem referenceCurveYArray1 lastCreatedReferenceNumber
                                        insertItem ((screenCoordinatesYCompanion[1] - referenceScreenCoordinatesBaseArray[lastCreatedReferenceNumber][1]) / (screenCoordinatesYCompanion[2] - referenceScreenCoordinatesBaseArray[lastCreatedReferenceNumber][2])) referenceCurveYArray1 lastCreatedReferenceNumber

                                        deleteItem referenceCurveYArray2 lastCreatedReferenceNumber
                                        insertItem ((screenCoordinatesYCompanion[2] - referenceScreenCoordinatesBaseArray[lastCreatedReferenceNumber][2]) / (screenCoordinatesYCompanion[1] - referenceScreenCoordinatesBaseArray[lastCreatedReferenceNumber][1])) referenceCurveYArray2 lastCreatedReferenceNumber

                                    -- Z

                                        deleteItem referenceCurveZArray1 lastCreatedReferenceNumber
                                        insertItem ((screenCoordinatesZCompanion[1] - referenceScreenCoordinatesBaseArray[lastCreatedReferenceNumber][1]) / (screenCoordinatesZCompanion[2] - referenceScreenCoordinatesBaseArray[lastCreatedReferenceNumber][2])) referenceCurveZArray1 lastCreatedReferenceNumber

                                        deleteItem referenceCurveZArray2 lastCreatedReferenceNumber
                                        insertItem ((screenCoordinatesZCompanion[2] - referenceScreenCoordinatesBaseArray[lastCreatedReferenceNumber][2]) / (screenCoordinatesZCompanion[1] - referenceScreenCoordinatesBaseArray[lastCreatedReferenceNumber][1])) referenceCurveZArray2 lastCreatedReferenceNumber

                            -- Update relevant reference world coordinates variable

                                deleteItem worldPointOnInferArray lastCreatedReferenceNumber
                                insertItem currentMousePositionGlobalVariable worldPointOnInferArray lastCreatedReferenceNumber

                            BetterToolsCreateReferenceTimer.stop()
                        ) -- (Undo end bracket)
                    )

                -- Recalculate references

                    fn recalculateReferences = (
                        undo off(
                            for a = 1 to totalNumberOfReferences do(
                                i = worldPointOnInferArray[a]

                                -- Update relevant reference screen coordinates, base variable

                                    deleteItem referenceScreenCoordinatesBaseArray a
                                    insertItem (gw.transPoint i) referenceScreenCoordinatesBaseArray a

                                -- Update relevant reference curve variables

                                    -- Create X, Y and Z companion variables to compare against the base position in order to calculate each curve

                                        local screenCoordinatesXCompanion = (gw.transPoint [(i[1] + 10),i[2],i[3]])
                                        local screenCoordinatesYCompanion = (gw.transPoint [i[1],(i[2] + 10),i[3]])
                                        local screenCoordinatesZCompanion = (gw.transPoint [i[1],i[2],(i[3] + 10)])

                                    -- Calculate and update each curve

                                        -- X

                                            deleteItem referenceCurveXArray1 a
                                            insertItem ((screenCoordinatesXCompanion[1] - referenceScreenCoordinatesBaseArray[a][1]) / (screenCoordinatesXCompanion[2] - referenceScreenCoordinatesBaseArray[a][2])) referenceCurveXArray1 a

                                            deleteItem referenceCurveXArray2 a
                                            insertItem ((screenCoordinatesXCompanion[2] - referenceScreenCoordinatesBaseArray[a][2]) / (screenCoordinatesXCompanion[1] - referenceScreenCoordinatesBaseArray[a][1])) referenceCurveXArray2 a

                                        -- Y

                                            deleteItem referenceCurveYArray1 a
                                            insertItem ((screenCoordinatesYCompanion[1] - referenceScreenCoordinatesBaseArray[a][1]) / (screenCoordinatesYCompanion[2] - referenceScreenCoordinatesBaseArray[a][2])) referenceCurveYArray1 a

                                            deleteItem referenceCurveYArray2 a
                                            insertItem ((screenCoordinatesYCompanion[2] - referenceScreenCoordinatesBaseArray[a][2]) / (screenCoordinatesYCompanion[1] - referenceScreenCoordinatesBaseArray[a][1])) referenceCurveYArray2 a

                                        -- Z

                                            deleteItem referenceCurveZArray1 a
                                            insertItem ((screenCoordinatesZCompanion[1] - referenceScreenCoordinatesBaseArray[a][1]) / (screenCoordinatesZCompanion[2] - referenceScreenCoordinatesBaseArray[a][2])) referenceCurveZArray1 a

                                            deleteItem referenceCurveZArray2 a
                                            insertItem ((screenCoordinatesZCompanion[2] - referenceScreenCoordinatesBaseArray[a][2]) / (screenCoordinatesZCompanion[1] - referenceScreenCoordinatesBaseArray[a][1])) referenceCurveZArray2 a
                            )
                        ) -- (Undo end bracket)
                    )

            -- Change cursor

                fn changeCursorFunction = (
                    setSysCur #move
                )

            -- On mouse move

                fn onMouseMoveFunction worldPoint bSelection cSelection betterMoveCurrentObject clickno = (
                    if startMoving == true and success == false then( -- After the final click, one more move is registered. The condition "success == false" ensures this move won't do anything.
                        undo off(
                            -- Position the distance editText if relevant, otherwise proceed as normal

                                if positionDistanceEditTextBoolean == true then(
                                    setdialogPos enterDistanceRollout viewPoint
                                )else(
                                    -- Recalculate references in case viewport has been orbitted, zoomed etc.

                                        recalculateReferences()

                                    -- Variables

                                        currentMousePositionGlobalVariable = worldPoint
                                        gw.setTransform(Matrix3 1)

                                        xPosOne = worldPointOnInferArray[lastReferenceNumberSnappedToAny][1]
                                        yPosOne = worldPointOnInferArray[lastReferenceNumberSnappedToAny][2]
                                        zPosOne = worldPointOnInferArray[lastReferenceNumberSnappedToAny][3]

                                        xPosTwo = worldPointOnAxisLock[1]
                                        yPosTwo = worldPointOnAxisLock[2]
                                        zPosTwo = worldPointOnAxisLock[3]

                                        xMousePosCurrent = worldPoint[1]
                                        yMousePosCurrent = worldPoint[2]
                                        zMousePosCurrent = worldPoint[3]
                                        allMousePosCurrent = [xMousePosCurrent,yMousePosCurrent,zMousePosCurrent]

                                        xObjectPosCurrent = bPositionFinal[1]
                                        yObjectPosCurrent = bPositionFinal[2]
                                        zObjectPosCurrent = bPositionFinal[3]

                                        xChangeOne = xPosTwo - xPosOne
                                        yChangeOne = yPosTwo - yPosOne
                                        zChangeOne = zPosTwo - zPosOne

                                        xChangeTwo = xMousePosCurrent - xPosOne
                                        yChangeTwo = yMousePosCurrent - yPosOne
                                        zChangeTwo = zMousePosCurrent - zPosOne

                                        xChangeThree = xMousePosCurrent - firstClickPos[1]
                                        yChangeThree = yMousePosCurrent - firstClickPos[2]
                                        zChangeThree = zMousePosCurrent - firstClickPos[3]

                                        xChangeFour = xObjectPosCurrent - xPosOne
                                        yChangeFour = yObjectPosCurrent - yPosOne
                                        zChangeFour = zObjectPosCurrent - zPosOne

                                        xMousePosCurrentLocked = xMousePosCurrent
                                        xMousePosCurrentSubobjectLocked = xChangeTwo

                                        yMousePosCurrentLocked = yMousePosCurrent
                                        yMousePosCurrentSubobjectLocked = yChangeTwo

                                        zMousePosCurrentLocked = zMousePosCurrent
                                        zMousePosCurrentSubobjectLocked = zChangeTwo

                                        -- Define totalDistanceMoved variable

                                            xForTotalDistance = xChangeFour ^ 2
                                            yForTotalDistance = yChangeFour ^ 2
                                            zForTotalDistance = zChangeFour ^ 2

                                            xyForTotalDistancePreliminary = sqrt (xForTotalDistance + yForTotalDistance)
                                            xyForTotalDistance = xyForTotalDistancePreliminary ^ 2

                                            totalDistanceMoved = sqrt (xyForTotalDistance + zForTotalDistance)

                                        -- Non-ortho axis lock

                                            -- Master

                                                xNonOrthoAxisLockMaster = xMousePosCurrent
                                                xNonOrthoAxisLockSubobjectMaster = xChangeThree

                                                yNonOrthoAxisLockMaster = yMousePosCurrent
                                                yNonOrthoAxisLockSubobjectMaster = yChangeThree

                                                zNonOrthoAxisLockMaster = zMousePosCurrent
                                                zNonOrthoAxisLockSubobjectMaster = zChangeThree

                                            -- Non-ortho axis lock to x

                                                yNonOrthoAxisLockToX = yChangeOne / xChangeOne * xChangeTwo + yPosOne
                                                zNonOrthoAxisLockToX = zChangeOne / xChangeOne * xChangeTwo + zPosOne

                                                yNonOrthoAxisLockToXSubObject = yChangeOne / xChangeOne * xChangeTwo + yPosOne - firstClickPos[2]
                                                zNonOrthoAxisLockToXSubObject = zChangeOne / xChangeOne * xChangeTwo + zPosOne - firstClickPos[3]

                                            -- Non-ortho axis lock to y

                                                xNonOrthoAxisLockToY = xChangeOne / yChangeOne * yChangeTwo + xPosOne
                                                zNonOrthoAxisLockToY = zChangeOne / yChangeOne * yChangeTwo + zPosOne

                                                xNonOrthoAxisLockToYSubObject = xChangeOne / yChangeOne * yChangeTwo + xPosOne - firstClickPos[1]
                                                zNonOrthoAxisLockToYSubObject = zChangeOne / yChangeOne * yChangeTwo + zPosOne - firstClickPos[3]

                                            -- Non-ortho axis lock to z

                                                xNonOrthoAxisLockToZ = xChangeOne / zChangeOne * zChangeTwo + xPosOne
                                                yNonOrthoAxisLockToZ = yChangeOne / zChangeOne * zChangeTwo + yPosOne

                                                xNonOrthoAxisLockToZSubObject = xChangeOne / zChangeOne * zChangeTwo + xPosOne - firstClickPos[1]
                                                yNonOrthoAxisLockToZSubObject = yChangeOne / zChangeOne * zChangeTwo + yPosOne - firstClickPos[2]

                                        -- Define xDistance variable

                                            if xChangeTwo*-1 > xChangeTwo then(
                                                xDistance = xChangeTwo*-1
                                            )else(
                                                xDistance = xChangeTwo
                                            )

                                        -- Define yDistance variable

                                            if yChangeTwo*-1 > yChangeTwo then(
                                                yDistance = yChangeTwo*-1
                                            )else(
                                                yDistance = yChangeTwo
                                            )

                                        -- Define zDistance variable

                                            if zChangeTwo*-1 > zChangeTwo then(
                                                zDistance = zChangeTwo*-1
                                            )else(
                                                zDistance = zChangeTwo
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

                                    -- If moving in subObject mode, move back to correct position at first move

                                        if not subobjectLevelIsZero() then(
                                            if firstMove == true then(

                                                -- Editable poly

                                                    if (modPanel.getCurrentObject() as string) == "Editable Poly" or (modPanel.getCurrentObject() as string) == "Editable Mesh" then(
                                                        if subObjectLevel == 1 then(
                                                            move $.selectedVerts [0,0,0]
                                                        )

                                                        if subObjectLevel == 2 or subObjectLevel == 3 then(
                                                            move $.selectedEdges [0,0,0]
                                                        )

                                                        if subObjectLevel == 4 or subObjectLevel == 5 then(
                                                            move $.selectedFaces [0,0,0]
                                                        )

                                                        -- Update lastFinalSubobjectPos variable. This variable is used to isolate what happens between each freeMove and the next, since with editable polys the move distance accumulates.

                                                            lastFinalSubobjectPos = finalSubobjectPos
                                                    )

                                                -- Edit poly

                                                    if matchPattern (modPanel.getCurrentObject() as string) Pattern:"Edit_Poly:*" then(
                                                        EditPolyMod.MoveSelection $.modifiers[#Edit_Poly] [0,0,0]
                                                    )

                                                finalSubobjectPos = [0,0,0]
                                            )
                                        )

                                    -- Move

                                        if lockToAxis == "none" then(
                                            hide referenceLineLocked

                                            -- Variables

                                                -- Create rounded reference curve arrays

                                                    roundedReferenceCurveXArray1 = #()
                                                    roundedReferenceCurveXArray2 = #()

                                                    roundedReferenceCurveYArray1 = #()
                                                    roundedReferenceCurveYArray2 = #()

                                                    roundedReferenceCurveZArray1 = #()
                                                    roundedReferenceCurveZArray2 = #()

                                                    for a = 1 to totalNumberOfReferences do(
                                                        append roundedReferenceCurveXArray1 (roundNumber referenceCurveXArray1[a] 1)
                                                        append roundedReferenceCurveXArray2 (roundNumber referenceCurveXArray2[a] 1)

                                                        append roundedReferenceCurveYArray1 (roundNumber referenceCurveYArray1[a] 1)
                                                        append roundedReferenceCurveYArray2 (roundNumber referenceCurveYArray2[a] 1)

                                                        append roundedReferenceCurveZArray1 (roundNumber referenceCurveZArray1[a] 1)
                                                        append roundedReferenceCurveZArray2 (roundNumber referenceCurveZArray2[a] 1)
                                                    )

                                                -- Create translated current curves array

                                                    translatedCurrentCurvesMatrix1 = #()
                                                    translatedCurrentCurvesMatrix2 = #()

                                                    for a = 1 to totalNumberOfReferences do(

                                                        translatedCurrentCurvesArray1 = #()
                                                        translatedCurrentCurvesArray2 = #()

                                                        local x

                                                        for x in basePointTranslationsArray do(

                                                            append translatedCurrentCurvesArray1 (roundNumber (((gw.transPoint currentMousePositionGlobalVariable)[1] - (ReferenceScreenCoordinatesBaseArray[a][1] + x[1])) / ((gw.transPoint currentMousePositionGlobalVariable)[2] - (ReferenceScreenCoordinatesBaseArray[a][2] + x[2]))) 1)

                                                            append translatedCurrentCurvesArray2 (roundNumber (((gw.transPoint currentMousePositionGlobalVariable)[2] - (ReferenceScreenCoordinatesBaseArray[a][2] + x[2])) / ((gw.transPoint currentMousePositionGlobalVariable)[1] - (ReferenceScreenCoordinatesBaseArray[a][1] + x[1]))) 1)

                                                        )

                                                        append translatedCurrentCurvesMatrix1 translatedCurrentCurvesArray1

                                                        append translatedCurrentCurvesMatrix2 translatedCurrentCurvesArray2

                                                    )

                                            -- Determine whether to snap to any of the references

                                                -- Declare snap to reference booleans

                                                    snapToXReference = false
                                                    snapToYReference = false
                                                    snapToZReference = false

                                                    referenceNumberToSnapToX = undefined
                                                    referenceNumberToSnapToY = undefined
                                                    referenceNumberToSnapToZ = undefined

                                                -- Define snap to reference booleans

                                                    for a = 1 to translatedCurrentCurvesMatrix1.count do(
                                                        -- X

                                                            matchWasFoundX = false

                                                            for b = 1 to translatedCurrentCurvesMatrix1[a].count do(
                                                                cc = translatedCurrentCurvesMatrix1[a][b]
                                                                d = translatedCurrentCurvesMatrix2[a][b]

                                                                if cc == roundedReferenceCurveXArray1[a] or d == roundedReferenceCurveXArray2[a] then(
                                                                    snapToXReference = true

                                                                    matchWasFoundX = true
                                                                )
                                                            )

                                                            -- If the loop finds its first match, take it. Any match it finds thereafter (i.e. if several references are trying to be made on the same axis) will only replace the first match if it was the chosen match on the last move.

                                                                if matchWasFoundX == true then(
                                                                    if referenceNumberToSnapToX == undefined then(
                                                                        referenceNumberToSnapToX = a
                                                                    )else(
                                                                        if a == lastReferenceNumberSnappedToX then(
                                                                            referenceNumberToSnapToX = a
                                                                        )
                                                                    )
                                                                )

                                                        -- Y

                                                            matchWasFoundY = false

                                                            for b = 1 to translatedCurrentCurvesMatrix1[a].count do(
                                                                cc = translatedCurrentCurvesMatrix1[a][b]

                                                                d = translatedCurrentCurvesMatrix2[a][b]

                                                                if cc == roundedReferenceCurveYArray1[a] or d == roundedReferenceCurveYArray2[a] then(
                                                                    snapToYReference = true

                                                                    matchWasFoundY = true
                                                                )
                                                            )

                                                            -- If the loop finds its first match, take it. Any match it finds thereafter (i.e. if several references are trying to be made on the same axis) will only replace the first match if it was the chosen match on the last move.

                                                                if matchWasFoundY == true then(
                                                                    if referenceNumberToSnapToY == undefined then(
                                                                        referenceNumberToSnapToY = a
                                                                    )else(
                                                                        if a == lastReferenceNumberSnappedToY then(
                                                                            referenceNumberToSnapToY = a
                                                                        )
                                                                    )
                                                                )

                                                        -- Z

                                                            matchWasFoundZ = false

                                                            for b = 1 to translatedCurrentCurvesMatrix1[a].count do(
                                                                cc = translatedCurrentCurvesMatrix1[a][b]

                                                                d = translatedCurrentCurvesMatrix2[a][b]

                                                                if cc == roundedReferenceCurveZArray1[a] or d == roundedReferenceCurveZArray2[a] then(
                                                                    snapToZReference = true

                                                                    matchWasFoundZ = true
                                                                )
                                                            )

                                                            -- If the loop finds its first match, take it. Any match it finds thereafter (i.e. if several references are trying to be made on the same axis) will only replace the first match if it was the chosen match on the last move.

                                                                if matchWasFoundZ == true then(
                                                                    if referenceNumberToSnapToZ == undefined then(
                                                                        referenceNumberToSnapToZ = a
                                                                    )else(
                                                                        if a == lastReferenceNumberSnappedToZ then(
                                                                            referenceNumberToSnapToZ = a
                                                                        )
                                                                    )
                                                                )
                                                    )

                                                -- Define last reference number snapped to variables

                                                    lastReferenceNumberSnappedToX = referenceNumberToSnapToX
                                                    lastReferenceNumberSnappedToY = referenceNumberToSnapToY
                                                    lastReferenceNumberSnappedToZ = referenceNumberToSnapToZ

                                                -- Secondary reference

                                                    -- Declare snap to secondary reference variable

                                                        referenceNumberToSnapToSecondary = undefined

                                                    -- Define snap to secondary reference variable

                                                        -- Variables

                                                            secondaryReferenceCoordinatesArray = #()

                                                            currentMousePositionCoordinates = gw.transPoint (currentMousePositionGlobalVariable)

                                                            referenceNumberToSnapToSecondary = undefined

                                            -- Move

                                                -- If this is the first move and an reference is to be snapped to, then don't move, as it will move to the wrong place. This has something to do with the mouse's position on the grids, which we should try to solve later, but currently we use this to at least treat the symptoms.

                                                    if ((snapToXReference == false and snapToYReference == false and snapToZReference == false) or snapMode.node == undefined) or firstMove == false then(
                                                        -- Determine where to move

                                                            if (snapToXReference == true or snapToYReference == true or snapToZReference == true) and snapMode.node == undefined then(
                                                                -- If only one reference is being snapped to...

                                                                    if snapToXReference == true and snapToYReference == false and snapToZReference == false then(
                                                                        -- Grid

                                                                            $BetterToolsXGrid.pos = worldPointOnInferArray[ReferenceNumberToSnapToX]

                                                                            activeGrid = $BetterToolsXGrid

                                                                        -- Determine whether to snap to a secondary reference

                                                                            if totalNumberOfReferences >= 2 then(
                                                                                for a = 1 to totalNumberOfReferences do(
                                                                                    append secondaryReferenceCoordinatesArray (gw.transPoint [worldPointOnInferArray[a][1],worldPointOnInferArray[ReferenceNumberToSnapToX][2],worldPointOnInferArray[ReferenceNumberToSnapToX][3]])
                                                                                )

                                                                                for a = 1 to secondaryReferenceCoordinatesArray.count do(
                                                                                    matchWasFound = false
                                                                                    i = secondaryReferenceCoordinatesArray[a]

                                                                                    if i[1] >= currentMousePositionCoordinates[1]-snapRadius and i[1] <= currentMousePositionCoordinates[1]+snapRadius and i[2] >= currentMousePositionCoordinates[2]-snapRadius and i[2] <= currentMousePositionCoordinates[2]+snapRadius then(
                                                                                        matchWasFound = true

                                                                                        referenceNumberToSnapToSecondary = a
                                                                                    )

                                                                                    if matchWasFound == true then(
                                                                                        if referenceNumberToSnapToSecondary == undefined then(
                                                                                            referenceNumberToSnapToSecondary = a
                                                                                        )else(
                                                                                            if lastSecondaryReferenceNumberSnappedTo == a then(
                                                                                                referenceNumberToSnapToSecondary = a
                                                                                            )
                                                                                        )
                                                                                    )
                                                                                )
                                                                            )

                                                                        -- Reference Lines + bPositionFinal

                                                                            referenceLineLocked.pos = worldPointOnInferArray[ReferenceNumberToSnapToX]
                                                                            lastReferenceNumberSnappedToAny = referenceNumberToSnapToX

                                                                            if referenceNumberToSnapToSecondary == undefined then(
                                                                                if distanceEntered != undefined then(
                                                                                    -- If the object is being moved in a negative direction, convert the distance entered into a negative value

                                                                                        if xMousePosCurrent < worldPointOnInferArray[ReferenceNumberToSnapToX][1] then(
                                                                                            distanceEnteredFinal = (- distanceEntered)
                                                                                        )else(
                                                                                            distanceEnteredFinal = distanceEntered
                                                                                        )

                                                                                    bPositionFinal = [worldPointOnInferArray[ReferenceNumberToSnapToX][1] + distanceEnteredFinal,worldPointOnInferArray[ReferenceNumberToSnapToX][2],worldPointOnInferArray[ReferenceNumberToSnapToX][3]]
                                                                                )else(
                                                                                    referenceLineX.pos = worldPointOnInferArray[ReferenceNumberToSnapToX]
                                                                                    referenceEndPointX.pos = [xMousePosCurrent,worldPointOnInferArray[ReferenceNumberToSnapToX][2],worldPointOnInferArray[ReferenceNumberToSnapToX][3]]

                                                                                    unhide referenceLineX
                                                                                    hide referenceLineY
                                                                                    hide referenceLineZ
                                                                                    hide referenceLineSecondary

                                                                                    bPositionFinal = [xMousePosCurrent,worldPointOnInferArray[ReferenceNumberToSnapToX][2],worldPointOnInferArray[ReferenceNumberToSnapToX][3]]
                                                                                )
                                                                            )else(
                                                                                referenceLineX.pos = worldPointOnInferArray[ReferenceNumberToSnapToX]
                                                                                referenceEndPointX.pos = [worldPointOnInferArray[ReferenceNumberToSnapToSecondary][1],worldPointOnInferArray[ReferenceNumberToSnapToX][2],worldPointOnInferArray[ReferenceNumberToSnapToX][3]]
                                                                                referenceLineSecondary.pos = worldPointOnInferArray[ReferenceNumberToSnapToSecondary]
                                                                                referenceEndPointSecondary.pos = [worldPointOnInferArray[ReferenceNumberToSnapToSecondary][1],worldPointOnInferArray[ReferenceNumberToSnapToX][2],worldPointOnInferArray[ReferenceNumberToSnapToX][3]]

                                                                                unhide referenceLineX
                                                                                hide referenceLineY
                                                                                hide referenceLineZ
                                                                                unhide referenceLineSecondary

                                                                                bPositionFinal = [worldPointOnInferArray[ReferenceNumberToSnapToSecondary][1],worldPointOnInferArray[ReferenceNumberToSnapToX][2],worldPointOnInferArray[ReferenceNumberToSnapToX][3]]
                                                                            )

                                                                        -- Define last used reference variable

                                                                            lastUsedReference = "X"
                                                                    )

                                                                    if snapToYReference == true and snapToXReference == false and snapToZReference == false then(
                                                                        -- Grid

                                                                            $BetterToolsYGrid.pos = worldPointOnInferArray[ReferenceNumberToSnapToY]

                                                                            activeGrid = $BetterToolsYGrid

                                                                        -- Determine whether to snap to a secondary reference

                                                                            if totalNumberOfReferences >= 2 then(
                                                                                for a = 1 to totalNumberOfReferences do(
                                                                                    append secondaryReferenceCoordinatesArray (gw.transPoint [worldPointOnInferArray[ReferenceNumberToSnapToY][1],worldPointOnInferArray[a][2],worldPointOnInferArray[ReferenceNumberToSnapToY][3]])
                                                                                )

                                                                                for a = 1 to secondaryReferenceCoordinatesArray.count do(
                                                                                    matchWasFound = false
                                                                                    i = secondaryReferenceCoordinatesArray[a]

                                                                                    if i[1] >= currentMousePositionCoordinates[1]-snapRadius and i[1] <= currentMousePositionCoordinates[1]+snapRadius and i[2] >= currentMousePositionCoordinates[2]-snapRadius and i[2] <= currentMousePositionCoordinates[2]+snapRadius then(
                                                                                        matchWasFound = true

                                                                                        referenceNumberToSnapToSecondary = a
                                                                                    )

                                                                                    if matchWasFound == true then(
                                                                                        if referenceNumberToSnapToSecondary == undefined then(
                                                                                            referenceNumberToSnapToSecondary = a
                                                                                        )else(
                                                                                            if lastSecondaryReferenceNumberSnappedTo == a then(
                                                                                                referenceNumberToSnapToSecondary = a
                                                                                            )
                                                                                        )
                                                                                    )
                                                                                )
                                                                            )

                                                                        -- Reference lines + bPositionFinal

                                                                            referenceLineLocked.pos = worldPointOnInferArray[ReferenceNumberToSnapToY]
                                                                            lastReferenceNumberSnappedToAny = referenceNumberToSnapToY

                                                                            if referenceNumberToSnapToSecondary == undefined then(
                                                                                if distanceEntered != undefined then(
                                                                                    -- If the objects is being moved in the negative direction, convert the distance entered into a negative value

                                                                                        if yMousePosCurrent < worldPointOnInferArray[ReferenceNumberToSnapToY][2] then(
                                                                                            distanceEnteredFinal = (- distanceEntered)
                                                                                        )else(
                                                                                            distanceEnteredFinal = distanceEntered
                                                                                        )

                                                                                    bPositionFinal = [worldPointOnInferArray[ReferenceNumberToSnapToY][1],worldPointOnInferArray[ReferenceNumberToSnapToY][2] + distanceEnteredFinal,worldPointOnInferArray[ReferenceNumberToSnapToY][3]]
                                                                                )else(
                                                                                    referenceLineY.pos = worldPointOnInferArray[ReferenceNumberToSnapToY]
                                                                                    referenceEndPointY.pos = [worldPointOnInferArray[ReferenceNumberToSnapToY][1],yMousePosCurrent,worldPointOnInferArray[ReferenceNumberToSnapToY][3]]

                                                                                    hide referenceLineX
                                                                                    unhide referenceLineY
                                                                                    hide referenceLineZ
                                                                                    hide referenceLineSecondary

                                                                                    bPositionFinal = [worldPointOnInferArray[ReferenceNumberToSnapToY][1],yMousePosCurrent,worldPointOnInferArray[ReferenceNumberToSnapToY][3]]
                                                                                )
                                                                            )else(
                                                                                referenceLineY.pos = worldPointOnInferArray[ReferenceNumberToSnapToY]
                                                                                referenceEndPointY.pos = [worldPointOnInferArray[ReferenceNumberToSnapToY][1],worldPointOnInferArray[ReferenceNumberToSnapToSecondary][2],worldPointOnInferArray[ReferenceNumberToSnapToY][3]]
                                                                                referenceLineSecondary.pos = worldPointOnInferArray[ReferenceNumberToSnapToSecondary]
                                                                                referenceEndPointSecondary.pos = [worldPointOnInferArray[ReferenceNumberToSnapToY][1],worldPointOnInferArray[ReferenceNumberToSnapToSecondary][2],worldPointOnInferArray[ReferenceNumberToSnapToY][3]]

                                                                                hide referenceLineX
                                                                                unhide referenceLineY
                                                                                hide referenceLineZ
                                                                                unhide referenceLineSecondary

                                                                                bPositionFinal = [worldPointOnInferArray[ReferenceNumberToSnapToY][1],worldPointOnInferArray[ReferenceNumberToSnapToSecondary][2],worldPointOnInferArray[ReferenceNumberToSnapToY][3]]
                                                                            )

                                                                        -- Define last used reference variable

                                                                            lastUsedReference = "Y"
                                                                    )

                                                                    if snapToZReference == true and snapToXReference == false and snapToYReference == false then(
                                                                        -- Grid

                                                                            $BetterToolsZGrid.pos = worldPointOnInferArray[ReferenceNumberToSnapToZ]

                                                                            activeGrid = $BetterToolsZGrid

                                                                        -- Determine whether to snap to a secondary reference

                                                                            if totalNumberOfReferences >= 2 then(
                                                                                for a = 1 to totalNumberOfReferences do(
                                                                                    append secondaryReferenceCoordinatesArray (gw.transPoint [worldPointOnInferArray[ReferenceNumberToSnapToZ][1],worldPointOnInferArray[ReferenceNumberToSnapToZ][2],worldPointOnInferArray[a][3]])
                                                                                )

                                                                                for a = 1 to secondaryReferenceCoordinatesArray.count do(
                                                                                    matchWasFound = false
                                                                                    i = secondaryReferenceCoordinatesArray[a]

                                                                                    if i[1] >= currentMousePositionCoordinates[1]-snapRadius and i[1] <= currentMousePositionCoordinates[1]+snapRadius and i[2] >= currentMousePositionCoordinates[2]-snapRadius and i[2] <= currentMousePositionCoordinates[2]+snapRadius then(
                                                                                        matchWasFound = true

                                                                                        referenceNumberToSnapToSecondary = a
                                                                                    )

                                                                                    if matchWasFound == true then(
                                                                                        if referenceNumberToSnapToSecondary == undefined then(
                                                                                            referenceNumberToSnapToSecondary = a
                                                                                        )else(
                                                                                            if lastSecondaryReferenceNumberSnappedTo == a then(
                                                                                                referenceNumberToSnapToSecondary = a
                                                                                            )
                                                                                        )
                                                                                    )
                                                                                )
                                                                            )

                                                                        -- Reference Lines + bPositionFinal

                                                                            referenceLineLocked.pos = worldPointOnInferArray[ReferenceNumberToSnapToZ]
                                                                            lastReferenceNumberSnappedToAny = referenceNumberToSnapToZ

                                                                            if referenceNumberToSnapToSecondary == undefined then(
                                                                                if distanceEntered != undefined then(
                                                                                    -- If the objects is being moved in the negative direction, convert the distance entered into a negative value

                                                                                        if zMousePosCurrent < worldPointOnInferArray[ReferenceNumberToSnapToZ][3] then(
                                                                                            distanceEnteredFinal = (- distanceEntered)
                                                                                        )else(
                                                                                            distanceEnteredFinal = distanceEntered
                                                                                        )

                                                                                    bPositionFinal = [worldPointOnInferArray[ReferenceNumberToSnapToZ][1],worldPointOnInferArray[ReferenceNumberToSnapToZ][2],worldPointOnInferArray[ReferenceNumberToSnapToZ][3] + distanceEnteredFinal]
                                                                                )else(
                                                                                    referenceLineZ.pos = worldPointOnInferArray[ReferenceNumberToSnapToZ]
                                                                                    referenceEndPointZ.pos = [worldPointOnInferArray[ReferenceNumberToSnapToZ][1],worldPointOnInferArray[ReferenceNumberToSnapToZ][2],zMousePosCurrent]

                                                                                    hide referenceLineX
                                                                                    hide referenceLineY
                                                                                    unhide referenceLineZ
                                                                                    hide referenceLineSecondary

                                                                                    bPositionFinal = [worldPointOnInferArray[ReferenceNumberToSnapToZ][1],worldPointOnInferArray[ReferenceNumberToSnapToZ][2],zMousePosCurrent]
                                                                                )
                                                                            )else(
                                                                                referenceLineZ.pos = worldPointOnInferArray[ReferenceNumberToSnapToZ]
                                                                                referenceEndPointZ.pos = [worldPointOnInferArray[ReferenceNumberToSnapToZ][1],worldPointOnInferArray[ReferenceNumberToSnapToZ][2],worldPointOnInferArray[ReferenceNumberToSnapToSecondary][3]]
                                                                                referenceLineSecondary.pos = worldPointOnInferArray[ReferenceNumberToSnapToSecondary]
                                                                                referenceEndPointSecondary.pos = [worldPointOnInferArray[ReferenceNumberToSnapToZ][1],worldPointOnInferArray[ReferenceNumberToSnapToZ][2],worldPointOnInferArray[ReferenceNumberToSnapToSecondary][3]]

                                                                                hide referenceLineX
                                                                                hide referenceLineY
                                                                                unhide referenceLineZ
                                                                                unhide referenceLineSecondary

                                                                                bPositionFinal = [worldPointOnInferArray[ReferenceNumberToSnapToZ][1],worldPointOnInferArray[ReferenceNumberToSnapToZ][2],worldPointOnInferArray[ReferenceNumberToSnapToSecondary][3]]
                                                                            )

                                                                        -- Define last used reference variable

                                                                            lastUsedReference = "Z"
                                                                    )

                                                                -- If two references are being snapped to...

                                                                    if snapToXReference == true and snapToYReference == true and snapToZReference == false then(
                                                                        -- Snap to both references if they share the same Z value but aren't the same reference, or else snap to whatever axis was last snapped to

                                                                            if worldPointOnInferArray[ReferenceNumberToSnapToY][3] == worldPointOnInferArray[ReferenceNumberToSnapToX][3] and referenceNumberToSnapToY != referenceNumberToSnapToX then(
                                                                                -- Reference Lines

                                                                                        referenceLineX.pos = worldPointOnInferArray[ReferenceNumberToSnapToX]
                                                                                        referenceEndPointX.pos = [worldPointOnInferArray[ReferenceNumberToSnapToY][1],worldPointOnInferArray[ReferenceNumberToSnapToX][2],worldPointOnInferArray[ReferenceNumberToSnapToX][3]]

                                                                                        referenceLineY.pos = worldPointOnInferArray[ReferenceNumberToSnapToY]
                                                                                        referenceEndPointY.pos = [worldPointOnInferArray[ReferenceNumberToSnapToY][1],worldPointOnInferArray[ReferenceNumberToSnapToX][2],worldPointOnInferArray[ReferenceNumberToSnapToX][3]]

                                                                                        unhide referenceLineX
                                                                                        unhide referenceLineY
                                                                                        hide referenceLineZ
                                                                                        hide referenceLineSecondary

                                                                                bPositionFinal = [worldPointOnInferArray[ReferenceNumberToSnapToY][1],worldPointOnInferArray[ReferenceNumberToSnapToX][2],worldPointOnInferArray[ReferenceNumberToSnapToX][3]]
                                                                            )else(
                                                                                if lastUsedReference == "X" then(
                                                                                    -- Determine whether to snap to a secondary reference

                                                                                        if totalNumberOfReferences >= 2 then(
                                                                                            for a = 1 to totalNumberOfReferences do(
                                                                                                append secondaryReferenceCoordinatesArray (gw.transPoint [worldPointOnInferArray[a][1],worldPointOnInferArray[ReferenceNumberToSnapToX][2],worldPointOnInferArray[ReferenceNumberToSnapToX][3]])
                                                                                            )

                                                                                            for a = 1 to secondaryReferenceCoordinatesArray.count do(
                                                                                                matchWasFound = false
                                                                                                i = secondaryReferenceCoordinatesArray[a]

                                                                                                if i[1] >= currentMousePositionCoordinates[1]-snapRadius and i[1] <= currentMousePositionCoordinates[1]+snapRadius and i[2] >= currentMousePositionCoordinates[2]-snapRadius and i[2] <= currentMousePositionCoordinates[2]+snapRadius then(
                                                                                                    matchWasFound = true

                                                                                                    referenceNumberToSnapToSecondary = a
                                                                                                )

                                                                                                if matchWasFound == true then(
                                                                                                    if referenceNumberToSnapToSecondary == undefined then(
                                                                                                        referenceNumberToSnapToSecondary = a
                                                                                                    )else(
                                                                                                        if lastSecondaryReferenceNumberSnappedTo == a then(
                                                                                                            referenceNumberToSnapToSecondary = a
                                                                                                        )
                                                                                                    )
                                                                                                )
                                                                                            )
                                                                                        )

                                                                                    -- Reference Lines + bPositionFinal

                                                                                        if referenceNumberToSnapToSecondary == undefined then(
                                                                                            referenceLineX.pos = worldPointOnInferArray[ReferenceNumberToSnapToX]
                                                                                            referenceEndPointX.pos = [xMousePosCurrent,worldPointOnInferArray[ReferenceNumberToSnapToX][2],worldPointOnInferArray[ReferenceNumberToSnapToX][3]]

                                                                                            unhide referenceLineX
                                                                                            hide referenceLineY
                                                                                            hide referenceLineZ
                                                                                            hide referenceLineSecondary

                                                                                            bPositionFinal = [xMousePosCurrent,worldPointOnInferArray[ReferenceNumberToSnapToX][2],worldPointOnInferArray[ReferenceNumberToSnapToX][3]]
                                                                                        )else(
                                                                                            referenceLineX.pos = worldPointOnInferArray[ReferenceNumberToSnapToX]
                                                                                            referenceEndPointX.pos = [worldPointOnInferArray[ReferenceNumberToSnapToSecondary][1],worldPointOnInferArray[ReferenceNumberToSnapToX][2],worldPointOnInferArray[ReferenceNumberToSnapToX][3]]
                                                                                            referenceLineSecondary.pos = worldPointOnInferArray[ReferenceNumberToSnapToSecondary]
                                                                                            referenceEndPointSecondary.pos = [worldPointOnInferArray[ReferenceNumberToSnapToSecondary][1],worldPointOnInferArray[ReferenceNumberToSnapToX][2],worldPointOnInferArray[ReferenceNumberToSnapToX][3]]

                                                                                            unhide referenceLineX
                                                                                            hide referenceLineY
                                                                                            hide referenceLineZ
                                                                                            unhide referenceLineSecondary

                                                                                            bPositionFinal = [worldPointOnInferArray[ReferenceNumberToSnapToSecondary][1],worldPointOnInferArray[ReferenceNumberToSnapToX][2],worldPointOnInferArray[ReferenceNumberToSnapToX][3]]
                                                                                        )
                                                                                )

                                                                                if lastUsedReference == "Y" then(
                                                                                    -- Determine whether to snap to a secondary reference

                                                                                        if totalNumberOfReferences >= 2 then(
                                                                                            for a = 1 to totalNumberOfReferences do(
                                                                                                append secondaryReferenceCoordinatesArray (gw.transPoint [worldPointOnInferArray[ReferenceNumberToSnapToY][1],worldPointOnInferArray[a][2],worldPointOnInferArray[ReferenceNumberToSnapToY][3]])
                                                                                            )

                                                                                            for a = 1 to secondaryReferenceCoordinatesArray.count do(
                                                                                                matchWasFound = false
                                                                                                i = secondaryReferenceCoordinatesArray[a]

                                                                                                if i[1] >= currentMousePositionCoordinates[1]-snapRadius and i[1] <= currentMousePositionCoordinates[1]+snapRadius and i[2] >= currentMousePositionCoordinates[2]-snapRadius and i[2] <= currentMousePositionCoordinates[2]+snapRadius then(
                                                                                                    matchWasFound = true

                                                                                                    referenceNumberToSnapToSecondary = a
                                                                                                )

                                                                                                if matchWasFound == true then(
                                                                                                    if referenceNumberToSnapToSecondary == undefined then(
                                                                                                        referenceNumberToSnapToSecondary = a
                                                                                                    )else(
                                                                                                        if lastSecondaryReferenceNumberSnappedTo == a then(
                                                                                                            referenceNumberToSnapToSecondary = a
                                                                                                        )
                                                                                                    )
                                                                                                )
                                                                                            )
                                                                                        )

                                                                                    -- Reference lines + bPositionFinal

                                                                                        if referenceNumberToSnapToSecondary == undefined then(
                                                                                            referenceLineY.pos = worldPointOnInferArray[ReferenceNumberToSnapToY]
                                                                                            referenceEndPointY.pos = [worldPointOnInferArray[ReferenceNumberToSnapToY][1],yMousePosCurrent,worldPointOnInferArray[ReferenceNumberToSnapToY][3]]

                                                                                            hide referenceLineX
                                                                                            unhide referenceLineY
                                                                                            hide referenceLineZ
                                                                                            hide referenceLineSecondary

                                                                                            bPositionFinal = [worldPointOnInferArray[ReferenceNumberToSnapToY][1],yMousePosCurrent,worldPointOnInferArray[ReferenceNumberToSnapToY][3]]
                                                                                        )else(
                                                                                            referenceLineY.pos = worldPointOnInferArray[ReferenceNumberToSnapToY]
                                                                                            referenceEndPointY.pos = [worldPointOnInferArray[ReferenceNumberToSnapToY][1],worldPointOnInferArray[ReferenceNumberToSnapToSecondary][2],worldPointOnInferArray[ReferenceNumberToSnapToY][3]]
                                                                                            referenceLineSecondary.pos = worldPointOnInferArray[ReferenceNumberToSnapToSecondary]
                                                                                            referenceEndPointSecondary.pos = [worldPointOnInferArray[ReferenceNumberToSnapToY][1],worldPointOnInferArray[ReferenceNumberToSnapToSecondary][2],worldPointOnInferArray[ReferenceNumberToSnapToY][3]]

                                                                                            hide referenceLineX
                                                                                            unhide referenceLineY
                                                                                            hide referenceLineZ
                                                                                            unhide referenceLineSecondary

                                                                                            bPositionFinal = [worldPointOnInferArray[ReferenceNumberToSnapToY][1],worldPointOnInferArray[ReferenceNumberToSnapToSecondary][2],worldPointOnInferArray[ReferenceNumberToSnapToY][3]]
                                                                                        )
                                                                                )
                                                                            )
                                                                    )

                                                                    if snapToXReference == false and snapToYReference == true and snapToZReference == true then(
                                                                        -- Snap to both references if they share the same X value but aren't the same reference, or else snap to whatever axis was last snapped to

                                                                            if worldPointOnInferArray[ReferenceNumberToSnapToZ][1] == worldPointOnInferArray[ReferenceNumberToSnapToY][1] and referenceNumberToSnapToZ != referenceNumberToSnapToY then(
                                                                                -- Reference Lines

                                                                                    referenceLineY.pos = worldPointOnInferArray[ReferenceNumberToSnapToY]
                                                                                    referenceEndPointY.pos = [worldPointOnInferArray[ReferenceNumberToSnapToY][1],worldPointOnInferArray[ReferenceNumberToSnapToZ][2],worldPointOnInferArray[ReferenceNumberToSnapToY][3]]

                                                                                    referenceLineZ.pos = worldPointOnInferArray[ReferenceNumberToSnapToZ]
                                                                                    referenceEndPointZ.pos = [worldPointOnInferArray[ReferenceNumberToSnapToY][1],worldPointOnInferArray[ReferenceNumberToSnapToZ][2],worldPointOnInferArray[ReferenceNumberToSnapToY][3]]

                                                                                    hide referenceLineX
                                                                                    unhide referenceLineY
                                                                                    unhide referenceLineZ

                                                                                bPositionFinal = [worldPointOnInferArray[ReferenceNumberToSnapToY][1],worldPointOnInferArray[ReferenceNumberToSnapToZ][2],worldPointOnInferArray[ReferenceNumberToSnapToY][3]]
                                                                            )else(
                                                                                if lastUsedReference == "Y" then(
                                                                                    -- Determine whether to snap to a secondary reference

                                                                                        if totalNumberOfReferences >= 2 then(
                                                                                            for a = 1 to totalNumberOfReferences do(
                                                                                                append secondaryReferenceCoordinatesArray (gw.transPoint [worldPointOnInferArray[ReferenceNumberToSnapToY][1],worldPointOnInferArray[a][2],worldPointOnInferArray[ReferenceNumberToSnapToY][3]])
                                                                                            )

                                                                                            for a = 1 to secondaryReferenceCoordinatesArray.count do(
                                                                                                matchWasFound = false
                                                                                                i = secondaryReferenceCoordinatesArray[a]

                                                                                                if i[1] >= currentMousePositionCoordinates[1]-snapRadius and i[1] <= currentMousePositionCoordinates[1]+snapRadius and i[2] >= currentMousePositionCoordinates[2]-snapRadius and i[2] <= currentMousePositionCoordinates[2]+snapRadius then(
                                                                                                    matchWasFound = true

                                                                                                    referenceNumberToSnapToSecondary = a
                                                                                                )

                                                                                                if matchWasFound == true then(
                                                                                                    if referenceNumberToSnapToSecondary == undefined then(
                                                                                                        referenceNumberToSnapToSecondary = a
                                                                                                    )else(
                                                                                                        if lastSecondaryReferenceNumberSnappedTo == a then(
                                                                                                            referenceNumberToSnapToSecondary = a
                                                                                                        )
                                                                                                    )
                                                                                                )
                                                                                            )
                                                                                        )

                                                                                    -- Reference lines + bPositionFinal

                                                                                        if referenceNumberToSnapToSecondary == undefined then(
                                                                                            referenceLineY.pos = worldPointOnInferArray[ReferenceNumberToSnapToY]
                                                                                            referenceEndPointY.pos = [worldPointOnInferArray[ReferenceNumberToSnapToY][1],yMousePosCurrent,worldPointOnInferArray[ReferenceNumberToSnapToY][3]]

                                                                                            hide referenceLineX
                                                                                            unhide referenceLineY
                                                                                            hide referenceLineZ
                                                                                            hide referenceLineSecondary

                                                                                            bPositionFinal = [worldPointOnInferArray[ReferenceNumberToSnapToY][1],yMousePosCurrent,worldPointOnInferArray[ReferenceNumberToSnapToY][3]]
                                                                                        )else(
                                                                                            referenceLineY.pos = worldPointOnInferArray[ReferenceNumberToSnapToY]
                                                                                            referenceEndPointY.pos = [worldPointOnInferArray[ReferenceNumberToSnapToY][1],worldPointOnInferArray[ReferenceNumberToSnapToSecondary][2],worldPointOnInferArray[ReferenceNumberToSnapToY][3]]
                                                                                            referenceLineSecondary.pos = worldPointOnInferArray[ReferenceNumberToSnapToSecondary]
                                                                                            referenceEndPointSecondary.pos = [worldPointOnInferArray[ReferenceNumberToSnapToY][1],worldPointOnInferArray[ReferenceNumberToSnapToSecondary][2],worldPointOnInferArray[ReferenceNumberToSnapToY][3]]

                                                                                            hide referenceLineX
                                                                                            unhide referenceLineY
                                                                                            hide referenceLineZ
                                                                                            unhide referenceLineSecondary

                                                                                            bPositionFinal = [worldPointOnInferArray[ReferenceNumberToSnapToY][1],worldPointOnInferArray[ReferenceNumberToSnapToSecondary][2],worldPointOnInferArray[ReferenceNumberToSnapToY][3]]
                                                                                        )
                                                                                )

                                                                                if lastUsedReference == "Z" then(
                                                                                    -- Determine whether to snap to a secondary reference

                                                                                        if totalNumberOfReferences >= 2 then(
                                                                                            for a = 1 to totalNumberOfReferences do(
                                                                                                append secondaryReferenceCoordinatesArray (gw.transPoint [worldPointOnInferArray[ReferenceNumberToSnapToZ][1],worldPointOnInferArray[ReferenceNumberToSnapToZ][2],worldPointOnInferArray[a][3]])
                                                                                            )

                                                                                            for a = 1 to secondaryReferenceCoordinatesArray.count do(
                                                                                                matchWasFound = false
                                                                                                i = secondaryReferenceCoordinatesArray[a]

                                                                                                if i[1] >= currentMousePositionCoordinates[1]-snapRadius and i[1] <= currentMousePositionCoordinates[1]+snapRadius and i[2] >= currentMousePositionCoordinates[2]-snapRadius and i[2] <= currentMousePositionCoordinates[2]+snapRadius then(
                                                                                                    matchWasFound = true

                                                                                                    referenceNumberToSnapToSecondary = a
                                                                                                )

                                                                                                if matchWasFound == true then(
                                                                                                    if referenceNumberToSnapToSecondary == undefined then(
                                                                                                        referenceNumberToSnapToSecondary = a
                                                                                                    )else(
                                                                                                        if lastSecondaryReferenceNumberSnappedTo == a then(
                                                                                                            referenceNumberToSnapToSecondary = a
                                                                                                        )
                                                                                                    )
                                                                                                )
                                                                                            )
                                                                                        )

                                                                                    -- Reference Lines + bPositionFinal

                                                                                        if referenceNumberToSnapToSecondary == undefined then(
                                                                                            referenceLineZ.pos = worldPointOnInferArray[ReferenceNumberToSnapToZ]
                                                                                            referenceEndPointZ.pos = [worldPointOnInferArray[ReferenceNumberToSnapToZ][1],worldPointOnInferArray[ReferenceNumberToSnapToZ][2],zMousePosCurrent]

                                                                                            hide referenceLineX
                                                                                            hide referenceLineY
                                                                                            unhide referenceLineZ
                                                                                            hide referenceLineSecondary

                                                                                            bPositionFinal = [worldPointOnInferArray[ReferenceNumberToSnapToZ][1],worldPointOnInferArray[ReferenceNumberToSnapToZ][2],zMousePosCurrent]
                                                                                        )else(
                                                                                            referenceLineZ.pos = worldPointOnInferArray[ReferenceNumberToSnapToZ]
                                                                                            referenceEndPointZ.pos = [worldPointOnInferArray[ReferenceNumberToSnapToZ][1],worldPointOnInferArray[ReferenceNumberToSnapToZ][2],worldPointOnInferArray[ReferenceNumberToSnapToSecondary][3]]
                                                                                            referenceLineSecondary.pos = worldPointOnInferArray[ReferenceNumberToSnapToSecondary]
                                                                                            referenceEndPointSecondary.pos = [worldPointOnInferArray[ReferenceNumberToSnapToZ][1],worldPointOnInferArray[ReferenceNumberToSnapToZ][2],worldPointOnInferArray[ReferenceNumberToSnapToSecondary][3]]

                                                                                            hide referenceLineX
                                                                                            hide referenceLineY
                                                                                            unhide referenceLineZ
                                                                                            unhide referenceLineSecondary

                                                                                            bPositionFinal = [worldPointOnInferArray[ReferenceNumberToSnapToZ][1],worldPointOnInferArray[ReferenceNumberToSnapToZ][2],worldPointOnInferArray[ReferenceNumberToSnapToSecondary][3]]
                                                                                        )
                                                                                )
                                                                            )
                                                                    )

                                                                    if snapToXReference == true and snapToYReference == false and snapToZReference == true then(
                                                                        -- Snap to both references if they share the same Y value but aren't the same reference, or else snap to whatever axis was last snapped to

                                                                            if worldPointOnInferArray[ReferenceNumberToSnapToX][2] == worldPointOnInferArray[ReferenceNumberToSnapToZ][2] and referenceNumberToSnapToX != referenceNumberToSnapToZ then(
                                                                                -- Reference Lines

                                                                                    referenceLineX.pos = worldPointOnInferArray[ReferenceNumberToSnapToX]
                                                                                    referenceEndPointX.pos = [worldPointOnInferArray[ReferenceNumberToSnapToZ][1],worldPointOnInferArray[ReferenceNumberToSnapToZ][2],worldPointOnInferArray[ReferenceNumberToSnapToX][3]]

                                                                                    referenceLineZ.pos = worldPointOnInferArray[ReferenceNumberToSnapToZ]
                                                                                    referenceEndPointZ.pos = [worldPointOnInferArray[ReferenceNumberToSnapToZ][1],worldPointOnInferArray[ReferenceNumberToSnapToZ][2],worldPointOnInferArray[ReferenceNumberToSnapToX][3]]

                                                                                    unhide referenceLineX
                                                                                    hide referenceLineY
                                                                                    unhide referenceLineZ

                                                                                bPositionFinal = [worldPointOnInferArray[ReferenceNumberToSnapToZ][1],worldPointOnInferArray[ReferenceNumberToSnapToZ][2],worldPointOnInferArray[ReferenceNumberToSnapToX][3]]
                                                                            )else(
                                                                                if lastUsedReference == "X" then(
                                                                                    -- Determine whether to snap to a secondary reference

                                                                                        if totalNumberOfReferences >= 2 then(
                                                                                            for a = 1 to totalNumberOfReferences do(
                                                                                                append secondaryReferenceCoordinatesArray (gw.transPoint [worldPointOnInferArray[a][1],worldPointOnInferArray[ReferenceNumberToSnapToX][2],worldPointOnInferArray[ReferenceNumberToSnapToX][3]])
                                                                                            )

                                                                                            for a = 1 to secondaryReferenceCoordinatesArray.count do(
                                                                                                matchWasFound = false
                                                                                                i = secondaryReferenceCoordinatesArray[a]

                                                                                                if i[1] >= currentMousePositionCoordinates[1]-snapRadius and i[1] <= currentMousePositionCoordinates[1]+snapRadius and i[2] >= currentMousePositionCoordinates[2]-snapRadius and i[2] <= currentMousePositionCoordinates[2]+snapRadius then(
                                                                                                    matchWasFound = true

                                                                                                    referenceNumberToSnapToSecondary = a
                                                                                                )

                                                                                                if matchWasFound == true then(
                                                                                                    if referenceNumberToSnapToSecondary == undefined then(
                                                                                                        referenceNumberToSnapToSecondary = a
                                                                                                    )else(
                                                                                                        if lastSecondaryReferenceNumberSnappedTo == a then(
                                                                                                            referenceNumberToSnapToSecondary = a
                                                                                                        )
                                                                                                    )
                                                                                                )
                                                                                            )
                                                                                        )

                                                                                    -- Reference Lines + bPositionFinal

                                                                                        if referenceNumberToSnapToSecondary == undefined then(
                                                                                            referenceLineX.pos = worldPointOnInferArray[ReferenceNumberToSnapToX]
                                                                                            referenceEndPointX.pos = [xMousePosCurrent,worldPointOnInferArray[ReferenceNumberToSnapToX][2],worldPointOnInferArray[ReferenceNumberToSnapToX][3]]

                                                                                            unhide referenceLineX
                                                                                            hide referenceLineY
                                                                                            hide referenceLineZ
                                                                                            hide referenceLineSecondary

                                                                                            bPositionFinal = [xMousePosCurrent,worldPointOnInferArray[ReferenceNumberToSnapToX][2],worldPointOnInferArray[ReferenceNumberToSnapToX][3]]
                                                                                        )else(
                                                                                            referenceLineX.pos = worldPointOnInferArray[ReferenceNumberToSnapToX]
                                                                                            referenceEndPointX.pos = [worldPointOnInferArray[ReferenceNumberToSnapToSecondary][1],worldPointOnInferArray[ReferenceNumberToSnapToX][2],worldPointOnInferArray[ReferenceNumberToSnapToX][3]]
                                                                                            referenceLineSecondary.pos = worldPointOnInferArray[ReferenceNumberToSnapToSecondary]
                                                                                            referenceEndPointSecondary.pos = [worldPointOnInferArray[ReferenceNumberToSnapToSecondary][1],worldPointOnInferArray[ReferenceNumberToSnapToX][2],worldPointOnInferArray[ReferenceNumberToSnapToX][3]]

                                                                                            unhide referenceLineX
                                                                                            hide referenceLineY
                                                                                            hide referenceLineZ
                                                                                            unhide referenceLineSecondary

                                                                                            bPositionFinal = [worldPointOnInferArray[ReferenceNumberToSnapToSecondary][1],worldPointOnInferArray[ReferenceNumberToSnapToX][2],worldPointOnInferArray[ReferenceNumberToSnapToX][3]]
                                                                                        )
                                                                                )

                                                                                if lastUsedReference == "Z" then(
                                                                                    -- Determine whether to snap to a secondary reference

                                                                                        if totalNumberOfReferences >= 2 then(
                                                                                            for a = 1 to totalNumberOfReferences do(
                                                                                                append secondaryReferenceCoordinatesArray (gw.transPoint [worldPointOnInferArray[ReferenceNumberToSnapToZ][1],worldPointOnInferArray[ReferenceNumberToSnapToZ][2],worldPointOnInferArray[a][3]])
                                                                                            )

                                                                                            for a = 1 to secondaryReferenceCoordinatesArray.count do(
                                                                                                matchWasFound = false
                                                                                                i = secondaryReferenceCoordinatesArray[a]

                                                                                                if i[1] >= currentMousePositionCoordinates[1]-snapRadius and i[1] <= currentMousePositionCoordinates[1]+snapRadius and i[2] >= currentMousePositionCoordinates[2]-snapRadius and i[2] <= currentMousePositionCoordinates[2]+snapRadius then(
                                                                                                    matchWasFound = true

                                                                                                    referenceNumberToSnapToSecondary = a
                                                                                                )

                                                                                                if matchWasFound == true then(
                                                                                                    if referenceNumberToSnapToSecondary == undefined then(
                                                                                                        referenceNumberToSnapToSecondary = a
                                                                                                    )else(
                                                                                                        if lastSecondaryReferenceNumberSnappedTo == a then(
                                                                                                            referenceNumberToSnapToSecondary = a
                                                                                                        )
                                                                                                    )
                                                                                                )
                                                                                            )
                                                                                        )

                                                                                    -- Reference Lines + bPositionFinal

                                                                                        if referenceNumberToSnapToSecondary == undefined then(
                                                                                            referenceLineZ.pos = worldPointOnInferArray[ReferenceNumberToSnapToZ]
                                                                                            referenceEndPointZ.pos = [worldPointOnInferArray[ReferenceNumberToSnapToZ][1],worldPointOnInferArray[ReferenceNumberToSnapToZ][2],zMousePosCurrent]

                                                                                            hide referenceLineX
                                                                                            hide referenceLineY
                                                                                            unhide referenceLineZ
                                                                                            hide referenceLineSecondary

                                                                                            bPositionFinal = [worldPointOnInferArray[ReferenceNumberToSnapToZ][1],worldPointOnInferArray[ReferenceNumberToSnapToZ][2],zMousePosCurrent]
                                                                                        )else(
                                                                                            referenceLineZ.pos = worldPointOnInferArray[ReferenceNumberToSnapToZ]
                                                                                            referenceEndPointZ.pos = [worldPointOnInferArray[ReferenceNumberToSnapToZ][1],worldPointOnInferArray[ReferenceNumberToSnapToZ][2],worldPointOnInferArray[ReferenceNumberToSnapToSecondary][3]]
                                                                                            referenceLineSecondary.pos = worldPointOnInferArray[ReferenceNumberToSnapToSecondary]
                                                                                            referenceEndPointSecondary.pos = [worldPointOnInferArray[ReferenceNumberToSnapToZ][1],worldPointOnInferArray[ReferenceNumberToSnapToZ][2],worldPointOnInferArray[ReferenceNumberToSnapToSecondary][3]]

                                                                                            hide referenceLineX
                                                                                            hide referenceLineY
                                                                                            unhide referenceLineZ
                                                                                            unhide referenceLineSecondary

                                                                                            bPositionFinal = [worldPointOnInferArray[ReferenceNumberToSnapToZ][1],worldPointOnInferArray[ReferenceNumberToSnapToZ][2],worldPointOnInferArray[ReferenceNumberToSnapToSecondary][3]]
                                                                                        )
                                                                                )
                                                                            )
                                                                    )

                                                                -- If all 3 references are being snapped to...

                                                                    if snapToXReference == true and snapToYReference == true and snapToZReference == true then(
                                                                        if referenceNumberToSnapToX == referenceNumberToSnapToY and referenceNumberToSnapToY == referenceNumberToSnapToZ then(
                                                                            if lastUsedReference == "X" then(
                                                                                -- Reference Lines

                                                                                    referenceLineX.pos = worldPointOnInferArray[ReferenceNumberToSnapToX]
                                                                                    referenceEndPointX.pos = [xMousePosCurrent,worldPointOnInferArray[ReferenceNumberToSnapToX][2],worldPointOnInferArray[ReferenceNumberToSnapToX][3]]
                                                                                    unhide referenceLineX
                                                                                    hide referenceLineY
                                                                                    hide referenceLineZ

                                                                                bPositionFinal = [xMousePosCurrent,worldPointOnInferArray[ReferenceNumberToSnapToX][2],worldPointOnInferArray[ReferenceNumberToSnapToX][3]]
                                                                            )

                                                                            if lastUsedReference == "Y" then(
                                                                                -- Reference Lines

                                                                                    referenceLineY.pos = worldPointOnInferArray[ReferenceNumberToSnapToY]
                                                                                    referenceEndPointY.pos = [worldPointOnInferArray[ReferenceNumberToSnapToY][1],yMousePosCurrent,worldPointOnInferArray[ReferenceNumberToSnapToY][3]]

                                                                                    hide referenceLineX
                                                                                    unhide referenceLineY
                                                                                    hide referenceLineZ

                                                                                bPositionFinal = [worldPointOnInferArray[ReferenceNumberToSnapToY][1],yMousePosCurrent,worldPointOnInferArray[ReferenceNumberToSnapToY][3]]
                                                                            )

                                                                            if lastUsedReference == "Z" then(
                                                                                -- Reference Lines

                                                                                    referenceLineZ.pos = worldPointOnInferArray[ReferenceNumberToSnapToZ]
                                                                                    referenceEndPointZ.pos = [worldPointOnInferArray[ReferenceNumberToSnapToZ][1],worldPointOnInferArray[ReferenceNumberToSnapToZ][2],zMousePosCurrent]

                                                                                    hide referenceLineX
                                                                                    hide referenceLineY
                                                                                    unhide referenceLineZ

                                                                                bPositionFinal = [worldPointOnInferArray[ReferenceNumberToSnapToZ][1],worldPointOnInferArray[ReferenceNumberToSnapToZ][2],zMousePosCurrent]
                                                                            )
                                                                        )
                                                                    )
                                                            )else(
                                                                referenceLineLocked.pos = worldPointOnInferArray[1]
                                                                lastReferenceNumberSnappedToAny = 1

                                                                -- Grids

                                                                    $BetterToolsMainGrid.pos = worldPointOnInferArray[1]
                                                                    $BetterToolsXGrid.pos = worldPointOnInferArray[1]
                                                                    $BetterToolsYGrid.pos = worldPointOnInferArray[1]
                                                                    $BetterToolsZGrid.pos = worldPointOnInferArray[1]

                                                                    activeGrid = $BetterToolsMainGrid

                                                                -- Reference Lines

                                                                    hide referenceLineX
                                                                    hide referenceLineY
                                                                    hide referenceLineZ
                                                                    hide referenceLineSecondary

                                                                    for a = 1 to totalNumberOfReferences do(
                                                                        i = worldPointOnInferArray[a]

                                                                        if worldPoint[1] != i[1] and worldPoint[2] == i[2] and worldPoint[3] == i[3] then(
                                                                            referenceLineX.pos = i
                                                                            referenceEndPointX.pos = worldPoint

                                                                            unhide referenceLineX
                                                                        )

                                                                        if worldPoint[1] == i[1] and worldPoint[2] != i[2] and worldPoint[3] == i[3] then(
                                                                            referenceLineY.pos = i
                                                                            referenceEndPointY.pos = worldPoint

                                                                            unhide referenceLineY
                                                                        )

                                                                        if worldPoint[1] == i[1] and worldPoint[2] == i[2] and worldPoint[3] != i[3] then(
                                                                            referenceLineZ.pos = i
                                                                            referenceEndPointZ.pos = worldPoint

                                                                            unhide referenceLineZ
                                                                        )
                                                                    )

                                                                bPositionFinal = [xMousePosCurrent,yMousePosCurrent,zMousePosCurrent]

                                                                -- Define last used reference variable

                                                                    lastUsedReference = "undefined"
                                                            )

                                                        -- Move

                                                            if subObjectLevelIsZero() then(
                                                                for z = 1 to selectionPositionsRelativeToFirstClickPointArray.count do(
                                                                    bSelection[z].pos = [(bPositionFinal[1] + selectionPositionsRelativeToFirstClickPointArray[z][1]), (bPositionFinal[2] + selectionPositionsRelativeToFirstClickPointArray[z][2]), (bPositionFinal[3] + selectionPositionsRelativeToFirstClickPointArray[z][3])]
                                                                )
                                                            )else(
                                                                finalSubobjectPos = [(bPositionFinal[1] - firstClickPos[1]),(bPositionFinal[2] - firstClickPos[2]),(bPositionFinal[3] - firstClickPos[3])]

                                                                -- Editable poly

                                                                    if (modPanel.getCurrentObject() as string) == "Editable Poly" or (modPanel.getCurrentObject() as string) == "Editable Mesh" then(
                                                                        if subObjectLevel == 1 then(
                                                                            move $.selectedVerts [finalSubobjectPos[1] - lastFinalSubobjectPos[1], finalSubobjectPos[2] - lastFinalSubobjectPos[2], finalSubobjectPos[3] - lastFinalSubobjectPos[3]]
                                                                        )

                                                                        if subObjectLevel == 2 or subObjectLevel == 3 then(
                                                                            move $.selectedEdges [finalSubobjectPos[1] - lastFinalSubobjectPos[1], finalSubobjectPos[2] - lastFinalSubobjectPos[2], finalSubobjectPos[3] - lastFinalSubobjectPos[3]]
                                                                        )

                                                                        if subObjectLevel == 4 or subObjectLevel == 5 then(
                                                                            move $.selectedFaces [finalSubobjectPos[1] - lastFinalSubobjectPos[1], finalSubobjectPos[2] - lastFinalSubobjectPos[2], finalSubobjectPos[3] - lastFinalSubobjectPos[3]]
                                                                        )

                                                                        -- Update lastFinalSubobjectPos variable. This variable is used to isolate what happens between each freeMove and the next, since with editable polys the move distance accumulates.

                                                                            lastFinalSubobjectPos = finalSubobjectPos
                                                                    )

                                                                -- Edit poly

                                                                    if matchPattern (modPanel.getCurrentObject() as string) Pattern:"Edit_Poly:*" then(
                                                                        EditPolyMod.MoveSelection $.modifiers[#Edit_Poly] finalSubobjectPos
                                                                    )
                                                            )
                                                    )
                                        )else(
                                            unhide referenceLineLocked
                                            hide referenceLineSecondary
                                            hide referenceLineX
                                            hide referenceLineY
                                            hide referenceLineZ

                                            if lockToAxis == "x" then(
                                                -- Reference lines

                                                    referenceEndPointLocked.pos = [xNonOrthoAxisLockMaster,yNonOrthoAxisLockToX,zNonOrthoAxisLockToX]

                                                    unhide referenceLineLocked

                                                if distanceEntered != undefined then(
                                                    xNonOrthoAxisLockMaster = ((xNonOrthoAxisLockMaster - xPosOne) / totalDistanceMoved * distanceEntered + xPosOne)
                                                    yNonOrthoAxisLockToX = ((yNonOrthoAxisLockToX - yPosOne) / totalDistanceMoved * distanceEntered + yPosOne)
                                                    zNonOrthoAxisLockToX = ((zNonOrthoAxisLockToX - zPosOne) / totalDistanceMoved * distanceEntered + zPosOne)

                                                    xNonOrthoAxisLockSubObjectMaster = (xNonOrthoAxisLockSubObjectMaster / totalDistanceMoved * distanceEntered)
                                                    yNonOrthoAxisLockToXSubObject = (yNonOrthoAxisLockToXSubObject / totalDistanceMoved * distanceEntered)
                                                    zNonOrthoAxisLockToXSubObject = (zNonOrthoAxisLockToXSubObject / totalDistanceMoved * distanceEntered)
                                                )

                                                if distanceEntered != undefined then(
                                                    -- If the object is being moved in a negative direction, convert the distance entered into a negative value

                                                        if xNonOrthoAxisLockMaster < worldPointOnInferArray[1][1] then(
                                                            distanceEnteredFinal = (- distanceEntered)
                                                        )else(
                                                            distanceEnteredFinal = distanceEntered
                                                        )

                                                    bPositionFinal = [(((xNonOrthoAxisLockMaster - worldPointOnInferArray[1][1]) / totalDistanceMoved) * distanceEntered), (((yNonOrthoAxisLockToX - worldPointOnInferArray[1][2]) / totalDistanceMoved) * distanceEntered), (((zNonOrthoAxisLockToX - worldPointOnInferArray[1][3]) / totalDistanceMoved) * distanceEntered)]
                                                )else(
                                                    bPositionFinal = [xNonOrthoAxisLockMaster, yNonOrthoAxisLockToX, zNonOrthoAxisLockToX]
                                                )

                                                if subObjectLevelIsZero() then(
                                                    for z = 1 to selectionPositionsRelativeToFirstClickPointArray.count do(
                                                        bSelection[z].pos = [(bPositionFinal[1] + selectionPositionsRelativeToFirstClickPointArray[z][1]), (bPositionFinal[2] + selectionPositionsRelativeToFirstClickPointArray[z][2]), (bPositionFinal[3] + selectionPositionsRelativeToFirstClickPointArray[z][3])]
                                                    )
                                                )else(
                                                    finalSubobjectPos = [xNonOrthoAxisLockSubObjectMaster,yNonOrthoAxisLockToXSubObject,zNonOrthoAxisLockToXSubObject]

                                                    -- Editable poly

                                                        if (modPanel.getCurrentObject() as string) == "Editable Poly" or (modPanel.getCurrentObject() as string) == "Editable Mesh" then(
                                                            if subObjectLevel == 1 then(
                                                                move $.selectedVerts [finalSubobjectPos[1] - lastFinalSubobjectPos[1], finalSubobjectPos[2] - lastFinalSubobjectPos[2], finalSubobjectPos[3] - lastFinalSubobjectPos[3]]
                                                            )

                                                            if subObjectLevel == 2 or subObjectLevel == 3 then(
                                                                move $.selectedEdges [finalSubobjectPos[1] - lastFinalSubobjectPos[1], finalSubobjectPos[2] - lastFinalSubobjectPos[2], finalSubobjectPos[3] - lastFinalSubobjectPos[3]]
                                                            )

                                                            if subObjectLevel == 4 or subObjectLevel == 5 then(
                                                                move $.selectedFaces [finalSubobjectPos[1] - lastFinalSubobjectPos[1], finalSubobjectPos[2] - lastFinalSubobjectPos[2], finalSubobjectPos[3] - lastFinalSubobjectPos[3]]
                                                            )

                                                            -- Update lastFinalSubobjectPos variable. This variable is used to isolate what happens between each freeMove and the next, since with editable polys the move distance accumulates.

                                                                lastFinalSubobjectPos = finalSubobjectPos
                                                        )

                                                    -- Edit poly

                                                        if matchPattern (modPanel.getCurrentObject() as string) Pattern:"Edit_Poly:*" then(
                                                            EditPolyMod.MoveSelection $.modifiers[#Edit_Poly] finalSubobjectPos
                                                        )
                                                )
                                            )

                                            if lockToAxis == "y" then(
                                                -- Reference lines

                                                    referenceEndPointLocked.pos = [xNonOrthoAxisLockToY,yNonOrthoAxisLockMaster,zNonOrthoAxisLockToY]

                                                    unhide referenceLineLocked

                                                if distanceEntered != undefined then(
                                                        yNonOrthoAxisLockMaster = ((yNonOrthoAxisLockMaster - yPosOne) / totalDistanceMoved * distanceEntered + yPosOne)
                                                        xNonOrthoAxisLockToY = ((xNonOrthoAxisLockToY - xPosOne) / totalDistanceMoved * distanceEntered + xPosOne)
                                                        zNonOrthoAxisLockToY = ((zNonOrthoAxisLockToY - zPosOne) / totalDistanceMoved * distanceEntered + zPosOne)

                                                        yNonOrthoAxisLockSubObjectMaster = (yNonOrthoAxisLockSubObjectMaster / totalDistanceMoved * distanceEntered)
                                                        xNonOrthoAxisLockToYSubObject = (xNonOrthoAxisLockToYSubObject / totalDistanceMoved * distanceEntered)
                                                        zNonOrthoAxisLockToYSubObject = (zNonOrthoAxisLockToYSubObject / totalDistanceMoved * distanceEntered)
                                                )

                                                if distanceEntered != undefined then(
                                                    -- If the object is being moved in a negative direction, convert the distance entered into a negative value

                                                        if yNonOrthoAxisLockMaster < worldPointOnInferArray[1][2] then(
                                                            distanceEnteredFinal = (- distanceEntered)
                                                        )else(
                                                            distanceEnteredFinal = distanceEntered
                                                        )

                                                    bPositionFinal = [(((xNonOrthoAxisLockToY - worldPointOnInferArray[1][1]) / totalDistanceMoved) * distanceEntered), (((yNonOrthoAxisLockMaster - worldPointOnInferArray[1][2]) / totalDistanceMoved) * distanceEntered), (((zNonOrthoAxisLockToY - worldPointOnInferArray[1][3]) / totalDistanceMoved) * distanceEntered)]
                                                )else(
                                                    bPositionFinal = [xNonOrthoAxisLockToY,yNonOrthoAxisLockMaster,zNonOrthoAxisLockToY]
                                                )

                                                if subObjectLevelIsZero() then(
                                                    for z = 1 to selectionPositionsRelativeToFirstClickPointArray.count do(
                                                        bSelection[z].pos = [(bPositionFinal[1] + selectionPositionsRelativeToFirstClickPointArray[z][1]), (bPositionFinal[2] + selectionPositionsRelativeToFirstClickPointArray[z][2]), (bPositionFinal[3] + selectionPositionsRelativeToFirstClickPointArray[z][3])]
                                                    )
                                                )else(
                                                    finalSubobjectPos = [xNonOrthoAxisLockToYSubObject,yNonOrthoAxisLockSubobjectMaster,zNonOrthoAxisLockToYSubObject]

                                                    -- Editable poly

                                                        if (modPanel.getCurrentObject() as string) == "Editable Poly" or (modPanel.getCurrentObject() as string) == "Editable Mesh" then(
                                                            if subObjectLevel == 1 then(
                                                                move $.selectedVerts [finalSubobjectPos[1] - lastFinalSubobjectPos[1], finalSubobjectPos[2] - lastFinalSubobjectPos[2], finalSubobjectPos[3] - lastFinalSubobjectPos[3]]
                                                            )

                                                            if subObjectLevel == 2 or subObjectLevel == 3 then(
                                                                move $.selectedEdges [finalSubobjectPos[1] - lastFinalSubobjectPos[1], finalSubobjectPos[2] - lastFinalSubobjectPos[2], finalSubobjectPos[3] - lastFinalSubobjectPos[3]]
                                                            )

                                                            if subObjectLevel == 4 or subObjectLevel == 5 then(
                                                                move $.selectedFaces [finalSubobjectPos[1] - lastFinalSubobjectPos[1], finalSubobjectPos[2] - lastFinalSubobjectPos[2], finalSubobjectPos[3] - lastFinalSubobjectPos[3]]
                                                            )

                                                            -- Update lastFinalSubobjectPos variable. This variable is used to isolate what happens between each freeMove and the next, since with editable polys the move distance accumulates.

                                                                lastFinalSubobjectPos = finalSubobjectPos
                                                        )

                                                    -- Edit poly

                                                        if matchPattern (modPanel.getCurrentObject() as string) Pattern:"Edit_Poly:*" then(
                                                            EditPolyMod.MoveSelection $.modifiers[#Edit_Poly] finalSubobjectPos
                                                        )
                                                )
                                            )

                                            if lockToAxis == "z" then(
                                                -- Reference lines

                                                    referenceEndPointLocked.pos = [xNonOrthoAxisLockToZ,yNonOrthoAxisLockToZ,zNonOrthoAxisLockMaster]

                                                    unhide referenceLineLocked

                                                if distanceEntered != undefined then(
                                                    zNonOrthoAxisLockMaster = ((zNonOrthoAxisLockMaster - zPosOne) / totalDistanceMoved * distanceEntered + zPosOne)
                                                    xNonOrthoAxisLockToZ = ((xNonOrthoAxisLockToZ - xPosOne) / totalDistanceMoved * distanceEntered + xPosOne)
                                                    yNonOrthoAxisLockToZ = ((yNonOrthoAxisLockToZ - yPosOne) / totalDistanceMoved * distanceEntered + yPosOne)

                                                    zNonOrthoAxisLockSubObjectMaster = (zNonOrthoAxisLockSubObjectMaster / totalDistanceMoved * distanceEntered)
                                                    xNonOrthoAxisLockToZSubObject = (xNonOrthoAxisLockToZSubObject / totalDistanceMoved * distanceEntered)
                                                    yNonOrthoAxisLockToZSubObject = (yNonOrthoAxisLockToZSubObject / totalDistanceMoved * distanceEntered)
                                                )

                                                if distanceEntered != undefined then(
                                                    -- If the object is being moved in a negative direction, convert the distance entered into a negative value

                                                        if zNonOrthoAxisLockMaster < worldPointOnInferArray[1][3] then(
                                                            distanceEnteredFinal = (- distanceEntered)
                                                        )else(
                                                            distanceEnteredFinal = distanceEntered
                                                        )

                                                    bPositionFinal = [(((xNonOrthoAxisLockToZ - worldPointOnInferArray[1][1]) / totalDistanceMoved) * distanceEntered), (((yNonOrthoAxisLockToZ - worldPointOnInferArray[1][2]) / totalDistanceMoved) * distanceEntered), (((zNonOrthoAxisLockMaster - worldPointOnInferArray[1][3]) / totalDistanceMoved) * distanceEntered)]
                                                )else(
                                                    bPositionFinal = [xNonOrthoAxisLockToZ,yNonOrthoAxisLockToZ,zNonOrthoAxisLockMaster]
                                                )

                                                if subObjectLevelIsZero() then(
                                                    for z = 1 to selectionPositionsRelativeToFirstClickPointArray.count do(
                                                        bSelection[z].pos = [(bPositionFinal[1] + selectionPositionsRelativeToFirstClickPointArray[z][1]), (bPositionFinal[2] + selectionPositionsRelativeToFirstClickPointArray[z][2]), (bPositionFinal[3] + selectionPositionsRelativeToFirstClickPointArray[z][3])]
                                                    )
                                                )else(
                                                    finalSubobjectPos = [xNonOrthoAxisLockToZSubObject,yNonOrthoAxisLockToZSubObject,zNonOrthoAxisLockSubobjectMaster]

                                                    -- Editable poly

                                                        if (modPanel.getCurrentObject() as string) == "Editable Poly" or (modPanel.getCurrentObject() as string) == "Editable Mesh" then(
                                                            if subObjectLevel == 1 then(
                                                                move $.selectedVerts [finalSubobjectPos[1] - lastFinalSubobjectPos[1], finalSubobjectPos[2] - lastFinalSubobjectPos[2], finalSubobjectPos[3] - lastFinalSubobjectPos[3]]
                                                            )

                                                            if subObjectLevel == 2 or subObjectLevel == 3 then(
                                                                move $.selectedEdges [finalSubobjectPos[1] - lastFinalSubobjectPos[1], finalSubobjectPos[2] - lastFinalSubobjectPos[2], finalSubobjectPos[3] - lastFinalSubobjectPos[3]]
                                                            )

                                                            if subObjectLevel == 4 or subObjectLevel == 5 then(
                                                                move $.selectedFaces [finalSubobjectPos[1] - lastFinalSubobjectPos[1], finalSubobjectPos[2] - lastFinalSubobjectPos[2], finalSubobjectPos[3] - lastFinalSubobjectPos[3]]
                                                            )

                                                            -- Update lastFinalSubobjectPos variable. This variable is used to isolate what happens between each freeMove and the next, since with editable polys the move distance accumulates.

                                                                lastFinalSubobjectPos = finalSubobjectPos
                                                        )

                                                    -- Edit poly

                                                        if matchPattern (modPanel.getCurrentObject() as string) Pattern:"Edit_Poly:*" then(
                                                            EditPolyMod.MoveSelection $.modifiers[#Edit_Poly] finalSubobjectPos
                                                        )
                                                )
                                            )
                                        )

                                    -- Create reference if relevant

                                        if objectReferencePreference == true then(
                                            if disableObjectReferenceWhenEdgeOrFaceSnapsAreEnabledPreference == false or ((snapMode.getOSnapItemActive 7 3) == false and (snapMode.getOSnapItemActive 7 5) == false) then(
                                                if snapMode.hit and not shiftKeyStateBoolean then(
                                                    BetterToolsCreateReferenceTimer.start()
                                                )else(
                                                    BetterToolsCreateReferenceTimer.stop()
                                                )
                                            )
                                        )
                                )
                        ) -- (Undo end bracket)
                    )
                )

            -- Deselect if selection lock is turned off

                fn BetterToolsDeselectIfSelectionLockIsTurnedOffFunction = (
                    undo off(
                        sel = selection as array

                        if subObjectLevelIsZero() then(
                            subObjectLevelWasZero = true
                        )else(
                            subObjectLevelWasZero = false
                        )

                        deselect selection

                        if selection.count == 0 then(
                            if undoOrRedoJustOccurred == false then(
                                selectAndMoveMode = true

                                -- Hide axis if visible

                                    if (getINISetting maxINIFile "Performance" "showaxisicon") == "1" then(
                                        turnAxisIconBackOn = true

                                        max showaxisicon
                                    )

                                BetterToolsStartToolWhenMouseIsClickedTimer.stop()

                                BetterToolsDeselectIfSelectionLockIsTurnedOffTimer.stop()

                                -- If subObjectLevel isn't 0, reselect the object and deselect the Subselection

                                    if subObjectLevelWasZero == false then(
                                        select sel

                                        -- Toggle selection lock if edit poly or editable mesh. Don't know why this is needed, but it is only needed if edit poly or editable mesh.

                                            if matchPattern (modPanel.getCurrentObject() as string) Pattern:"Edit_Poly:*" then(
                                                max spacebar
                                            )

                                        -- Editable poly

                                            if (modPanel.getCurrentObject() as string) == "Editable Poly" then(
                                                if subObjectLevel == 1 and ((polyop.getVertSelection selection[1]).numberset) != 0 then(
                                                    $.EditablePoly.SetSelection #Vertex #{}
                                                )

                                                if (subObjectLevel == 2 or subObjectLevel == 3) and ((polyop.getEdgeSelection selection[1]).numberset) != 0 then(
                                                    $.EditablePoly.SetSelection #Edge #{}
                                                )

                                                if (subObjectLevel == 4 or subObjectLevel == 5) and ((polyop.getFaceSelection selection[1]).numberset) != 0 then(
                                                    $.EditablePoly.SetSelection #Face #{}
                                                )
                                            )

                                        -- Edit poly

                                            if matchPattern (modPanel.getCurrentObject() as string) Pattern:"Edit_Poly:*" then(
                                                if subObjectLevel == 1 and (EditPolyMod.GetSelection $.Edit_Poly #Vertex) as string != "#{}" then(
                                                    EditPolyMod.SetSelection $.modifiers[#Edit_Poly] #Vertex #{}
                                                )

                                                if (subObjectLevel == 2 or subObjectLevel == 3) and (EditPolyMod.GetSelection $.Edit_Poly #Edge) as string != "#{}" then(
                                                    EditPolyMod.SetSelection $.modifiers[#Edit_Poly] #Edge #{}
                                                )

                                                if (subObjectLevel == 4 or subObjectLevel == 5) and (EditPolyMod.GetSelection $.Edit_Poly #Face) as string != "#{}" then(
                                                    EditPolyMod.SetSelection $.modifiers[#Edit_Poly] #Face #{}
                                                )
                                            )

                                        -- Editable mesh

                                            if (modPanel.getCurrentObject() as string) == "Editable Mesh" then(
                                                if subObjectLevel == 1 and ((getVertSelection selection[1]) as string) != "#{}" then(
                                                    setVertSelection $ #{}
                                                )

                                                if (subObjectLevel == 2 or subObjectLevel == 3) and ((getEdgeSelection selection[1]) as string) != "#{}" then(
                                                    setEdgeSelection $ #{}
                                                )

                                                if (subObjectLevel == 4 or subObjectLevel == 5) and ((getFaceSelection selection[1]) as string) != "#{}" then(
                                                    setFaceSelection $ #{}
                                                )
                                            )
                                    )

                                if subObjectLevelWasZero == true then(
                                    testTimer.start()
                                )else(
                                    testTimer.start()

                                    subObjectLevelBeforeModifierParameterChange = subObjectLevel
                                )
                            )else(
                                -- Reselect and relock the selection if the selection was changed due to undoing or redoing (which are capable of changing the selection even when it is locked, which turns selection lock off and triggers this function). There may be other things that can unwantedly trigger this function—if they are discovered, code shoud be added to catch this here.

                                    select sel

                                    max spacebar
                            )
                        )
                    ) -- (Undo end bracket)
                )

            -- Stop tool on mouse unclicked

                fn stopToolOnMouseUnclickedFunction = (
                    if ((mouse.buttonStates as string) == "#{}" or (mouse.buttonStates as string) == "#{3}") then(
                        undo off(
                            BetterToolsStopToolOnMouseUnclickedTimer.stop()

                            if mouse.pos != mousePos2D then(
                                success = true

                                ignoreNextCallOfStopClause = true

                                stopTool betterMove
                            )
                        ) -- (Undo end bracket)
                    )
                )

            -- Get world point from HWND

                -- Primary function. Gets worldPoint from the transform fields that show current mouse position, but are only really useful when snapped to a point. Otherwise they disregard user grids and always say mouse is at z: 0. Still more reliable than the secondary function so we use it before making first click as the user grid can't know where to go until then anyway.

                    fn getWorldPointFromHWNDsFunction = (
                        undo off(
                            maxChildrenHWNDs = (windows.getChildrenHWND #max)

                            for a = 1 to maxChildrenHWNDs.count do(
                                if maxChildrenHWNDs[a][4] == "Static" and maxChildrenHWNDs[a][5] == "X:" and maxChildrenHWNDs[a][6] == 0P then(
                                    worldPointFromHWND = [((maxChildrenHWNDs[a + 3][5]) as float),((maxChildrenHWNDs[a + 9][5]) as float),((maxChildrenHWNDs[a + 15][5]) as float)]

                                    exit
                                )
                            )
                        ) -- (Undo end bracket)
                    )

                -- Seconday function. This gets worldPoint from the bottom left of the screen, where it says what and where is currently being snapped to. Requires max move to be active, grid point snap to be on, and a grid so fine that it's alway snapped to.

                    fn getWorldPointFromHWNDsSecondaryFunction = (
                        undo off(
                            maxChildrenHWNDs = (windows.getChildrenHWND #max)

                            for a = 1 to maxChildrenHWNDs.count do(
                                if maxChildrenHWNDs[a][4] == "CustStatus" and (matchPattern (maxChildrenHWNDs[a][5]) Pattern:"* snap on *") and maxChildrenHWNDs[a][6] == 0P then(
                                    try(
                                        worldPointFromHWNDSecondary1 = ((filterString (subString ((filterString (maxChildrenHWNDs[a][5]) "[")[2]) 1 (((filterString (maxChildrenHWNDs[a][5]) "[")[2]).count - 1)) ",")[1] as float)
                                        worldPointFromHWNDSecondary2 = ((filterString (subString ((filterString (maxChildrenHWNDs[a][5]) "[")[2]) 1 (((filterString (maxChildrenHWNDs[a][5]) "[")[2]).count - 1)) ",")[2] as float)
                                        worldPointFromHWNDSecondary3 = ((filterString (subString ((filterString (maxChildrenHWNDs[a][5]) "[")[2]) 1 (((filterString (maxChildrenHWNDs[a][5]) "[")[2]).count - 1)) ",")[3] as float)
                                        worldPointFromHWNDSecondary = [worldPointFromHWNDSecondary1,worldPointFromHWNDSecondary2,worldPointFromHWNDSecondary3]
                                    )catch()

                                    exit
                                )
                            )
                        ) -- (Undo end bracket)
                    )

            -- Toggle axis reference lock based on shift key state

                fn toggleAxisReferenceLockBasedOnShiftKeyState = (
                    undo off(
                        -- On shift key press

                            if modifierKeysObject.modifierKeys == modifierKeysObject.modifierKeys.shift and shiftKeyStateOnLastFreeMoveBoolean == false then(
                                shiftKeyStateBoolean = true

                                if startMoving == true and currentMousePositionGlobalVariable != firstClickPos then( -- For some reason (haven't investigated), if axis reference is locked when object hasn't moved, the object moves far away
                                    if orthoSnap == true then(
                                        nonOrthoAxisLock = false
                                    )else(
                                        nonOrthoAxisLock = true
                                    )

                                    if mainDistance == "x" then(
                                        lockToAxis = "x"
                                    )

                                    if mainDistance == "y" then(
                                        lockToAxis = "y"
                                    )

                                    if mainDistance == "z" then(
                                        lockToAxis = "z"

                                        -- Activate Z grid

                                          activeGrid = $BetterToolsZGrid
                                    )

                                    worldPointOnAxisLock = bPositionFinal

                                    shiftKeyStateOnLastFreeMoveBoolean = true

                                    onMouseMoveFunction currentMousePositionGlobalVariable bSelection cSelection betterMoveCurrentObject clicknoGlobalVariable
                                )
                            )

                        -- On shift key release

                            if modifierKeysObject.modifierKeys != modifierKeysObject.modifierKeys.shift and shiftKeyStateOnLastFreeMoveBoolean == true then(
                                shiftKeyStateBoolean = false

                                if startMoving == true then(
                                    -- Activate main grid

                                        activeGrid = $BetterToolsMainGrid

                                    lockToAxis = "none"

                                    nonOrthoAxisLock = false

                                    axisReferenceLocked = false

                                    shiftKeyStateOnLastFreeMoveBoolean = false

                                    onMouseMoveFunction currentMousePositionGlobalVariable bSelection cSelection betterMoveCurrentObject clicknoGlobalVariable
                                )
                            )
                    ) -- (Undo end bracket)
                )

            -- Change variable on undo or redo, so that selection changes caused by undoing or redoing don't cause the tool to start

                fn changeVariableOnUndoOrRedo = (
                    if selectionArrayBeforeUndoOrRedo != selection as array then(
                        undoOrRedoJustOccurred = true
                    )
                )

            -- Detect if undo or redo made no change to the selection set

                fn detectIfUndoOrRedoMadeNoChangeToSelectionSetFunction = (
                    selectionArrayBeforeUndoOrRedo = selection as array
                )

            -- Starting/ending tool callback code

                fn detectIfToolTipHWNDNumberChangesFunction = (
                    undo off(
                        maxChildrenHWNDs = (windows.getChildrenHWND #max)

                        if (maxChildrenHWNDs[toolTipHWNDNumber][4] == "CustStatus" and ((matchPattern (maxChildrenHWNDs[toolTipHWNDNumber][5]) Pattern:"* snap on *") or (matchPattern (maxChildrenHWNDs[toolTipHWNDNumber][5]) Pattern:"Click and drag to select and move objects")) and maxChildrenHWNDs[toolTipHWNDNumber][6] == 0P) then(
                        )else(
                            for a = 1 to maxChildrenHWNDs.count do(
                                if maxChildrenHWNDs[a][4] == "CustStatus" and ((matchPattern (maxChildrenHWNDs[a][5]) Pattern:"* snap on *") or (matchPattern (maxChildrenHWNDs[a][5]) Pattern:"Click and drag to select and move objects")) and maxChildrenHWNDs[a][6] == 0P then(
                                    toolTipHWNDNumber = a

                                    exit
                                )
                            )
                        )
                    ) -- (Undo end bracket)
                )

                fn endMoveToolSessionFunction = (
                    if toolmode.commandmode != #move then(
                        undo off(
                            BetterToolsDeselectIfSelectionLockIsTurnedOffTimer.stop() -- This should stay above the code for removing callbacks, as if the timer ticks after they're removed, it will add them again.

                            -- Remove callbacks

                                testTimer.stop()

                                callBacks.RemoveScripts id:#once

                            -- Ensure rollouts are closed

                                    try(
                                        stopDetectingSubselectionChangesFunction()
                                    )catch()

                                    try(
                                        destroyDialog enterDistanceRollout
                                    )catch()

                                    try(
                                        destroyDialog displayDistanceRollout
                                    )catch()

                            BetterToolsDetectIfUndoOrRedoMadeNoChangeToSelectionSetTimer.stop()

                            BetterToolsDetectWhenMoveToolIsExitedTimer.stop()

                            BetterToolsDetermineWhetherToMoveInSubobjectModeTimer.stop()

                            BetterToolsStartToolWhenMouseIsClickedTimer.stop()

                            -- Toggle selection lock if relevant

                                if selLocked() and turnSelectionLockBackOn == false then(
                                    max spacebar
                                )

                            -- Reactivate whatever grid was active at start

                                activeGrid = originalActiveGrid

                            -- Ensure grid snap is set to what it originally was

                                snapMode.setOSnapItemActive 4 1 originalGridSnapState

                            -- Show gizmo if relevant

                                if (getINISetting maxINIFile "Performance" "showaxisicon") == "0" and turnAxisIconBackOn == true then(
                                    max showaxisicon
                                )

                            -- Set cursor

                                if turnSelectionLockBackOn == true then(
                                    setSysCur #select
                                )else(
                                    setSysCur #arrow
                                )

                            toolIsInactive = true

                            BetterToolsStartMoveSessionTimer.start()
                        ) -- (Undo end bracket)
                    )
                )

                fn determineWhetherToMoveInSubobjectModeFunction = (
                    if subObjectLevelIsZero() then(
                        undo off(
                            -- If the user has just exited subobject mode, change to click and move mode. We know it will always be this as a selection has to exist for the user to have been in subObject mode.

                                if moveInSubobjectMode == true then(
                                    if selectionAutoLockPreference == true then(
                                        selectAndMoveMode = false

                                        -- Ensure the selection changed callbacks are disabled, just in case

                                            testTimer.stop()

                                            try(
                                                stopDetectingSubselectionChangesFunction()
                                            )catch()

                                        -- Lock the selection if it isn't already

                                            if not selLocked() then(
                                                max spacebar
                                            )

                                        BetterToolsDeselectIfSelectionLockIsTurnedOffTimer.start()

                                        BetterToolsStartToolWhenMouseIsClickedTimer.start()
                                    )
                                )

                            -- Variables for the next run

                                moveInSubobjectMode = false
                        ) -- (Undo end bracket)
                    )else(
                        undo off(
                            -- If the user has just entered subobject mode, change from selectAndMoveMode if no Subselection exists

                                if moveInSubobjectMode == false then(
                                    if determineWhetherSubselectionExistsFunction() == false or determineWhetherSubselectionExistsFunction() == "Not moveable" then( -- If a Subselection is present, this will be used as the selection to move and selectAndMoveMode will be false. Since we can only change to subobject mode if selectAndMoveMode was already true, nothing needs to be done in this case.
                                        selectAndMoveMode = true

                                        BetterToolsDeselectIfSelectionLockIsTurnedOffTimer.stop()

                                        -- Unlock the selection if selectionAutoLockPreference is true. If it is, then we have been in click and move mode (as a moveable selection was present), but if it isn't then we weren't.

                                            if selectionAutoLockPreference == true then(
                                                max spacebar
                                            )

                                        -- Start the timer to detect selection change if current modifier is moveable, or else switch to regular move mode

                                            if isCurrentModifierMoveable() then(
                                                -- Start the timer to detect selection change

                                                    testTimer.start()

                                                    subObjectLevelBeforeModifierParameterChange = subObjectLevel

                                                BetterToolsGetWorldPointFromHWNDsTimer.start()
                                            )else(
                                                try(
                                                    stopDetectingSubselectionChangesFunction()
                                                )catch()

                                                BetterToolsStartToolWhenMouseIsClickedTimer.stop()
                                            )
                                    )
                                )

                            -- If the user has just changed from on subObject level to another and this has caused a (meaningful) change in Subselection count, then change to the relevant "and move" mode

                                if moveInSubobjectMode == true then(
                                    if isCurrentModifierMoveable() then(
                                        if subObjectLevel != subObjectLevelBeforeModifierParameterChange then(
                                            if selectionAutoLockPreference == true then(
                                                if determineWhetherSubselectionExistsFunction() == false then(
                                                    if selectAndMoveMode == false then( -- Only do the following if they're not already the case. This is mainly so that selection lock isn't toggled when it shouldn't be (could use selLocked() to get around that if needed, but would rather not run it as it takes time).
                                                        selectAndMoveMode = true

                                                        BetterToolsGetWorldPointFromHWNDsTimer.start()

                                                        max spacebar

                                                        -- Restart timer to detect selection change

                                                            testTimer.start()
                                                    )
                                                )else(
                                                    if selectAndMoveMode == true then( -- Only do the following if they're not already the case. This is mainly so that selection lock isn't toggled when it shouldn't be (could use selLocked() to get around that if needed, but would rather not run it as it takes time).
                                                        selectAndMoveMode = false

                                                        BetterToolsDeselectIfSelectionLockIsTurnedOffTimer.start()

                                                        max spacebar

                                                        try(
                                                            stopDetectingSubselectionChangesFunction()
                                                        )catch()

                                                        BetterToolsStartToolWhenMouseIsClickedTimer.start()
                                                    )
                                                )
                                            )

                                            subObjectLevelBeforeModifierParameterChange = subObjectLevel
                                        )
                                    )
                                )

                            -- Variables for the next run

                                moveInSubobjectMode = true
                        ) -- (Undo end bracket)
                    )
                )

        -- Rollouts

            rollout selectionUnlockedRollout "" (
                bitmap selectionUnlockedBitmap bitmap:selectionUnlockedBitmapFile width:31 height:30 pos:[-3,-3]
            )

            rollout displayDistanceRollout "" (
                -- Components

                    editText distanceEditText2 "" width:238 pos:[5,6] labelOnTop:false

                -- Functions

                    fn matchDisplayDistanceToEnterDistance = (
                        distanceEditText2.text = distanceEditTextTextString
                    )

                    fn matchDisplayDistanceToTotalDistanceMoved = (
                        distanceEditText2.text = (((roundNumber totalDistanceMoved 0) as integer) as string) + "mm"
                    )
            )

            rollout enterDistanceRollout "" (
                -- Components

                    editText distanceEditText "" width:238 pos:[5,6] labelOnTop:false

                    editText distanceEditText2 "" width:238 pos:[5,6] labelOnTop:false text:"Hi" -- Don't remember what this was for, or if it is still needed

                    editText dummyEditText "Hi" -- Don't remember what this was for, or if it is still needed

                    button btnHidden pos:[0,100] visible:OFF

                -- Functions

                    fn setFocusFunction = (
                        if startMoving == true then(
                            setFocus distanceEditText
                        )
                    )

                    fn clearEnterDistance = (
                        distanceEditText.text = ""
                    )

                -- Actions

                    on distanceEditText changed str do(
                        if startMoving == true then(
                            -- Action the input of any special characters

                                if matchPattern str Pattern:"* " then(
                                    max spacebar

                                    if conditionToSetSelectAndMoveModeVariableToOnStop == true then(
                                        conditionToSetSelectAndMoveModeVariableToOnStop = false

                                        if selectAndMoveMode == false then(
                                            try(
                                                destroyDialog selectionUnlockedRollout
                                            )catch()
                                        )
                                    )else(
                                        conditionToSetSelectAndMoveModeVariableToOnStop = true

                                        if selectAndMoveMode == false then(
                                            maxWindowHWND = windows.getMAXHWND()
                                            maxWindowSizeAndPosition = ::getWinClassGlobalVariable.GetWindowPosAndSize maxWindowHWND
                                            bottomRightOfWindow = [(maxWindowSizeAndPosition[1] + maxWindowSizeAndPosition[3]) - 899, (maxWindowSizeAndPosition[2] + maxWindowSizeAndPosition[4]) - 61]

                                            createDialog selectionUnlockedRollout height:26 width:27 pos:bottomRightOfWindow modal:false style:#()
                                        )
                                    )
                                )

                                if matchPattern str Pattern:"*l" then(
                                    if currentMousePositionGlobalVariable != firstClickPos then( -- For some reason (haven't investigated), if axis reference is locked when object hasn't moved, the object moves far away
                                        if lockToAxis == "none" then(
                                            if orthoSnap == true then(
                                                nonOrthoAxisLock = false
                                            )else(
                                                nonOrthoAxisLock = true
                                            )

                                            if mainDistance == "x" then(
                                                lockToAxis = "x"
                                            )

                                            if mainDistance == "y" then(
                                                lockToAxis = "y"
                                            )

                                            if mainDistance == "z" then(
                                                lockToAxis = "z"

                                                -- Activate Z grid

                                                  activeGrid = $BetterToolsZGrid
                                            )

                                            axisReferenceLocked = true

                                            worldPointOnAxisLock = bPositionFinal
                                        )else(
                                            -- Activate main grid

                                                activeGrid = $BetterToolsMainGrid

                                            lockToAxis = "none"

                                            nonOrthoAxisLock = false

                                            axisReferenceLocked = false
                                        )
                                    )

                                    onMouseMoveFunction currentMousePositionGlobalVariable bSelection cSelection betterMoveCurrentObject clicknoGlobalVariable
                                )

                                if matchPattern str Pattern:"*s" then(
                                    if snapMode.active == true then(
                                        snapMode.active = false
                                    )else(
                                        snapMode.active = true
                                    )
                                )

                            -- Change the text back to what it was if the change was adding anything other than a number or decimal point

                                if str.count > distanceEditTextTextString.count then( -- Only attempt to do if text was added, not deleted
                                    if (((str[str.count]) as integer) == undefined and (str[str.count]) != ".") or str[str.count] == " " or matchPattern str Pattern:"*l" or matchPattern str Pattern:"*s" then(
                                        distanceEditText.text = (substring distanceEditText.text 1 (distanceEditText.text.count - 1))
                                    )
                                )

                            -- Update the display rollout to match

                                if distanceEditText.text != distanceEditTextTextString then( -- If a special character has been input and then cleared, we don't want to change the display rollout
                                    distanceEditTextTextString = distanceEditText.text

                                    displayDistanceRollout.matchDisplayDistanceToEnterDistance()
                                )else( -- The variable still needs to updated regardless, but if the if statement returned true, it needed to be updated before the function is called but after the if statement, so the variable still needs to be updated afterwards if the statement returned false
                                    distanceEditTextTextString = distanceEditText.text
                                )
                        )
                    )

                    on distanceEditText entered str do(
                        if startMoving == true then(
                            if str as float != undefined and str as float != 0.0 then( -- Using mouse buttons, such as middle mouse button to orbit, can cause the editText to enter. This at least stops this from happening if the input was nothing/invalid.
                                --if not referenceLineX.isHidden or not referenceLineY.isHidden or not referenceLineZ.isHidden then(
                                    distanceEntered = str as float

                                    BetterToolsSetFocusTimer.stop()

                                    -- Note: there used to be code here to destroy the rollouts, but for some reason removing this code fixed the problem where focus wouldn't be properly set back to the max window, meaning mouse things would be picked up but keyboard input (such as hotkeys) woudn't until the user clicked somewhere in the Max window. The dialogs are still closed later in the code, so no problem removing the code from here.
                                --)
                            )
                        )
                    )
            )

            rollout preferencesRollout "BetterMove Preferences" (
                -- Variables

                -- Components

                    group "Selection Auto-Lock"(
                        checkBox selectionAutoLockCheckBox "Use Selection Auto-Lock" checked:(if (getINISetting betterMoveIni "BetterMove" "Selection Auto-Lock") == "true" then true else false)
                    )

                    group "Object Reference"(
                        checkBox objectReferenceCheckBox "Use Object Reference" checked:(if (getINISetting betterMoveIni "BetterMove" "Object Reference") == "true" then true else false)

                        checkBox disableObjectReferenceWhenEdgeOrFaceSnapsAreEnabledPreferenceCheckBox "Disable when edge or face snaps are enabled" checked:(if (getINISetting betterMoveIni "BetterMove" "Disable Object Reference when edge or face snaps are enabled") == "true" then true else false) enabled:(if objectReferenceCheckBox.checked == true then true else false)
                    )

                -- Actions

                    on selectionAutoLockCheckBox changed value do(
                        if selectionAutoLockCheckBox.checked == true then(
                            try(
                                delIniSetting betterMoveIni "BetterMove" "Selection Auto-Lock"
                            )catch()

                            setINISetting betterMoveIni "BetterMove" "Selection Auto-Lock" "true"

                            selectionAutoLockPreference = true
                        )else(
                            try(
                                delIniSetting betterMoveIni "BetterMove" "Selection Auto-Lock"
                            )catch()

                            setINISetting betterMoveIni "BetterMove" "Selection Auto-Lock" "false"

                            selectionAutoLockPreference = false
                        )
                    )

                    on objectReferenceCheckBox changed value do(
                        if objectReferenceCheckBox.checked == true then(
                            try(
                                delIniSetting betterMoveIni "BetterMove" "Object Reference"
                            )catch()

                            setINISetting betterMoveIni "BetterMove" "Object Reference" "true"

                            disableObjectReferenceWhenEdgeOrFaceSnapsAreEnabledPreferenceCheckBox.enabled = true

                            objectReferencePreference = true
                        )else(
                            try(
                                delIniSetting betterMoveIni "BetterMove" "Object Reference"
                            )catch()

                            setINISetting betterMoveIni "BetterMove" "Object Reference" "false"

                            disableObjectReferenceWhenEdgeOrFaceSnapsAreEnabledPreferenceCheckBox.enabled = false

                            objectReferencePreference = false
                        )
                    )

                    on disableObjectReferenceWhenEdgeOrFaceSnapsAreEnabledPreferenceCheckBox changed value do(
                        if disableObjectReferenceWhenEdgeOrFaceSnapsAreEnabledPreferenceCheckBox.checked == true then(
                            try(
                                delIniSetting betterMoveIni "BetterMove" "Disable Object Reference when edge or face snaps are enabled"
                            )catch()

                            setINISetting betterMoveIni "BetterMove" "Disable Object Reference when edge or face snaps are enabled" "true"

                            disableObjectReferenceWhenEdgeOrFaceSnapsAreEnabledPreference = true
                        )else(
                            try(
                                delIniSetting betterMoveIni "BetterMove" "Disable Object Reference when edge or face snaps are enabled"
                            )catch()

                            setINISetting betterMoveIni "BetterMove" "Disable Object Reference when edge or face snaps are enabled" "false"

                            disableObjectReferenceWhenEdgeOrFaceSnapsAreEnabledPreference = false
                        )
                    )
            )

        -- Functions that need to be declared after rollouts

            -- On mouse point

                -- Subfunctions

                    fn stopToolOnDistanceEnteredFunction = (
                        if distanceEntered != undefined then(
                            if distanceEnteredSecondCallbackBoolean == false then( -- When the callback runs after distance entered, for some reason it runs twice (haven't been able to figure out a fix). This conditional ensures variables are only changed on the second run.
                                undo off(
                                    distanceEnteredSecondCallbackBoolean = true

                                    onMouseMoveFunction currentMousePositionGlobalVariable bSelection cSelection betterMoveCurrentObject clicknoGlobalVariable

                                    success = true

                                    ignoreNextCallOfStopClause = true

                                    stopTool betterMove
                                ) -- (Undo end bracket)
                            )
                        )
                    )

                fn onMousePoint worldPoint bSelection cSelection betterMoveCurrentObject shiftKey clickno = (
                    undo off(
                        -- Position distance editText if relevant, otherwise proceed as normal

                            hi = false -- Variable for whether to position distance editText

                            -- Position distance editText

                                if hi == true and clickno == 1 then(
                                    startMoving = true

                                    positionDistanceEditTextBoolean = true
                                )

                                if clickno != 1 and clickno != 2 and positionDistanceEditTextBoolean == true then(
                                    #stop
                                )

                            -- Proceed as normal

                                if hi == false and positionDistanceEditTextBoolean == false then(
                                    -- New
                                    if firstClickPos == undefined then(
                                        if startMovingFromSelectionsPivot == false then(
                                            firstClickPos = mousePosOnToolStart
                                        )else(
                                            if subObjectLevelIsZero() then(
                                                firstClickPos = bSelectionPosOnToolStart
                                            )else(
                                                firstClickPos = pivotPositionOnToolStart
                                            )
                                        )

                                        -- Define selectionPositionsRelativeToFirstClickPointArray

                                            selectionPositionsRelativeToFirstClickPointArray = #()

                                            for a = 1 to $selection.count do(
                                                append selectionPositionsRelativeToFirstClickPointArray [(firstClickPos[1] - selection[a].pos[1]), (firstClickPos[2] - selection[a].pos[2]), (firstClickPos[3] - selection[a].pos[3])]
                                            )
                                    )

                                    /* Old
                                    if firstClickPos == undefined then(
                                        if startMovingFromSelectionsPivot == false then(
                                            firstClickPos = worldPointFromHWNDSecondary
                                        )else(
                                            if subObjectLevelIsZero() then(
                                                firstClickPos = bSelectionOriginalPos
                                            )else(
                                                firstClickPos = getPivotPosition()
                                            )
                                        )

                                        -- Define selectionPositionsRelativeToFirstClickPointArray

                                            selectionPositionsRelativeToFirstClickPointArray = #()

                                            for a = 1 to bSelection.count do(
                                                append selectionPositionsRelativeToFirstClickPointArray [(selection[a].pos[1] - firstClickPos[1]), (selection[a].pos[2] - firstClickPos[2]), (selection[a].pos[3] - firstClickPos[3])]
                                            )
                                    )
                                    */

                                    if (clickno == 0) then(
                                        -- Toggle and retoggle snap to reset it. Otherwise, any snaps on the same plane as the click point won't register for inferring.

                                            max snap toggle

                                            max snap toggle

                                        startMoving = true

                                        currentMousePositionGlobalVariable = worldPoint
                                        gw.setTransform(Matrix3 1)

                                        if shiftKey then(
                                            if subObjectLevelIsZero() then(
                                                if ctrlKey then(
                                                    maxOps.cloneNodes $ cloneType:#instance newNodes:&nnl
                                                    select nnl
                                                )else(
                                                    maxOps.cloneNodes $ cloneType:#copy newNodes:&nnl
                                                    select nnl
                                                )

                                                -- Set selection variables. Issue: Still need to factor in whether multiple objects were selected, which would mean we need to factor in the group create from them or maybe even need to remake the group here?

                                                    bSelection = $selection
                                                    cSelection = $
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

                                        -- Move and activate the grid, if it wasn't done before tool execution. This is determined by whether selectAndMoveMode is true, as if it was then the worldPointFromHWND timer was run and we had worldPoint data before the tool started. If the timer doesn't impede performance, should run it regardless of selectAndMoveMode, and move this code outside the tool as is the other code (for ease of coding).

                                            if selectAndMoveMode == false then(
                                                $BetterToolsMainGrid.pos = worldPoint

                                                activeGrid = $BetterToolsMainGrid
                                            )

                                        -- Create reference

                                            -- Temporarily redefine currentMousePositionGlobalVariable. This variable needs to be this way so that the reference is still created where the mouse was clicked if it was moved between then and now. We change the variable back in case it needs to stay as worldPoint, which seems true based on other code although I don't know why. Note: Confirmed—Reference can appear in the wrong place if the variable is changed at the start of this function.

                                                if startMovingFromSelectionsPivot == false then(
                                                    currentMousePositionGlobalVariable = mousePosOnFirstClick
                                                )else(
                                                    if subObjectLevelIsZero() then(
                                                        currentMousePositionGlobalVariable = bSelectionPosOnFirstClick
                                                    )else(
                                                        currentMousePositionGlobalVariable = pivotPositionOnFirstClick
                                                    )
                                                )

                                            BetterToolsCreateReference()

                                            currentMousePositionGlobalVariable = worldPoint

                                        $BetterToolsMainGrid.pos = worldPointOnInferArray[1]
                                        $BetterToolsXGrid.pos = worldPointOnInferArray[1]
                                        $BetterToolsYGrid.pos = worldPointOnInferArray[1]
                                        $BetterToolsZGrid.pos = worldPointOnInferArray[1]

                                        success = false

                                        currentsubobjectLevel = subobjectLevel

                                        if currentModifier != undefined then(
                                            modpanel.setCurrentObject currentModifier
                                        )

                                        -- Start timer to detect when a distance is entered

                                            BetterToolsDetectWhenDistanceIsEnteredTimer.start()

                                        -- Freeze the subject(s) so they don't snap to themselves

                                            freeze eSelection

                                        if ((currentMousePositionGlobalVariable as string) != (firstClickPos as string)) then(
                                            if (((gw.transPoint currentMousePositionGlobalVariable)[1]) as string)[1] == "0" and (((gw.transPoint currentMousePositionGlobalVariable)[2]) as string)[1] == "0" then( -- For some reason, sometimes Max thinks worldPoint is the top-left of the viewport on first unclick, and so moves the selection there. This code moves the selection back from there if so.
                                                if subObjectLevelIsZero() then(
                                                    for z = 1 to selectionPositionsRelativeToFirstClickPointArray.count do(
                                                        bSelection[z].pos = [(firstClickPos[1] + selectionPositionsRelativeToFirstClickPointArray[z][1]), (firstClickPos[2] + selectionPositionsRelativeToFirstClickPointArray[z][2]), (firstClickPos[3] + selectionPositionsRelativeToFirstClickPointArray[z][3])]
                                                    )
                                                )else(
                                                    -- If the problem with selection moving to the top-left corner of the viewport on first unclick also happens in subobject mode, insert code here to mimic what the above code is doing. Edit: It does.
                                                )
                                            )
                                        )
                                    )

                                    if clickno == 1 then(
                                        success = true

                                        #stop
                                    )
                                )
                    ) -- (Undo end bracket)
                )

            -- Start tool

                fn startbetterMoveToolFunction = (
                    -- Pre-tool code

                        theHold.begin()

                        units.DisplayType = originalDisplayUnits

                        setSysCur #move

                        -- Remove selection changed callbacks

                            testTimer.stop()

                            try(
                                stopDetectingSubselectionChangesFunction()
                            )catch()

                        selectionChanged = false

                        -- Prompt for distance

                            maxWindowHWND = windows.getMAXHWND()
                            maxWindowSizeAndPosition = ::getWinClassGlobalVariable.GetWindowPosAndSize maxWindowHWND
                            bottomRightOfWindow = [(maxWindowSizeAndPosition[1] + maxWindowSizeAndPosition[3]) - 847, (maxWindowSizeAndPosition[2] + maxWindowSizeAndPosition[4]) - 60]

                            createDialog enterDistanceRollout height: 23 width: 256 pos:[bottomRightOfWindow[1]+4000,bottomRightOfWindow[2]+4000] modal:false style:#()

                            createDialog displayDistanceRollout height: 23 width: 256 pos:bottomRightOfWindow modal:false style:#()

                        BetterToolsDeselectIfSelectionLockIsTurnedOffTimer.stop()

                        BetterToolsDetermineWhetherToMoveInSubobjectModeTimer.stop()

                        BetterToolsDetectWhenMoveToolIsExitedTimer.stop()

                        BetterToolsStartToolWhenMouseIsClickedTimer.stop()

                        -- Variables

                            mouseHasBeenClicked = false

                            mouseHasBeenUnclicked2 = false

                            lastFinalSubobjectPos = [0,0,0]

                            selectionPositionsRelativeToFirstClickPointArray = #()

                            ignoreNextCallOfStopClause = false

                            stopCodeHasRun = false

                            if selection.count == 0 then(
                                moveInSubobjectMode = false
                            )else(
                                BetterToolsDetermineWhetherToMoveInSubobjectModeTimer.start()
                            )

                            currentMoveHasAlreadyBeenStopped = false

                            axisReferenceLocked = false

                            shiftKeyStateBoolean = false

                            shiftKeyStateOnLastFreeMoveBoolean = false

                            startMoving = false

                            clicknoGlobalVariable = 0

                            -- Distance editText

                                -- Position Distance editText

                                    positionDistanceEditTextBoolean = false

                                distanceEntered = undefined

                            -- Rotating grids to viewport

                                -- Declaring the variables as non-globals before the function called in the callback. For some reason if this isn't done, they come back as undefined when the function is called, despite having values assigned when declared as globals.

                                    lastPlaneRotationX = 0
                                    lastPlaneRotationY = 0
                                    lastPlaneRotationZ = 0

                            -- Timers

                                distanceEnteredSecondCallbackBoolean = false

                            -- Reference

                                -- Reference screen coordinates, base

                                    referenceScreenCoordinatesBaseArray = #(undefined, undefined, undefined, undefined, undefined)

                                -- Reference curve

                                    referenceCurveXArray1 = #(undefined, undefined, undefined, undefined, undefined)
                                    referenceCurveXArray2 = #(undefined, undefined, undefined, undefined, undefined)

                                    referenceCurveYArray1 = #(undefined, undefined, undefined, undefined, undefined)
                                    referenceCurveYArray2 = #(undefined, undefined, undefined, undefined, undefined)

                                    referenceCurveZArray1 = #(undefined, undefined, undefined, undefined, undefined)
                                    referenceCurveZArray2 = #(undefined, undefined, undefined, undefined, undefined)

                                -- World point on infer

                                    worldPointOnInferArray = #(undefined, undefined, undefined, undefined, undefined)

                                lastCreatedReferenceNumber = 0
                                totalNumberOfReferences = 0

                                snapRadius = 10
                                screenCoordinatesCompanionNumber = 1

                                basePointTranslationsArray = #([0 ,0])

                                for a = 1 to snapRadius do(
                                    append basePointTranslationsArray [a, a]

                                    append basePointTranslationsArray [a, -a]

                                    append basePointTranslationsArray [-a, a]

                                    append basePointTranslationsArray [-a, -a]
                                )

                                -- Last used reference

                                    lastUsedReference = "Z"

                                -- Last reference number snapped to

                                    lastReferenceNumberSnappedToAny = 1

                            -- Object variables

                                currentModifier = undefined
                                currentsubobjectLevel = 0

                            -- Variables to organise

                                selectionWireframeLayer = layerManager.getLayerFromName "BetterTools, Selection Wireframes"
                                success = false
                                lockToAxis = "none"
                                worldPointOnAxisLock = [0,0,0]
                                worldPointOnShiftCtrlAltClick = [0,0,0]
                                firstMove = true

                                betterMoveDistance = undefined

                            -- Distance variables

                                xObjectPosCurrent = 0
                                yObjectPosCurrent = 0
                                zObjectPosCurrent = 0

                                totalDistanceMoved = 0

                            -- Position variables

                                currentMousePositionGlobalVariable = [0,0,0]
                                finalSubobjectPos = [0,0,0]
                                bPositionFinal = [0,0,0]

                        BetterToolsChangeCursorTimer.start()

                        -- Hide axis if visible and select and move mode isnt true (if it is, this has already been done when the selection changed. We do it there in that case so it happens faster and the gizmo doesn't appear for a moment)

                            if selectAndMoveMode == false then(
                                if (getINISetting maxINIFile "Performance" "showaxisicon") == "1" then(
                                    max showaxisicon
                                )
                            )

                        -- Record selection's position, cancel any dragging operation to temporarily move the selection back to where it was when first clicked, record this position so we know where to reference/undo to, and then move it back. Cancelling the drag and re-moving is needed as otherwise the tool will cancel it and not move it back.

                            if subObjectLevelIsZero() then(
                                bSelectionPosOnToolStart = (selection[1].pos)
                            )else(
                                bSelectionPosOnToolStart = getPivotPosition()
                            )

                            pivotPositionOnToolStart = getPivotPosition()

                            -- Cancel any moving by entering select mode

                                max select

                            -- Record selection's new (so, original) position

                                if subObjectLevelIsZero() then(
                                    bSelectionPosOnFirstClick = (selection[1].pos)
                                )else(
                                    bSelectionPosOnFirstClick = getPivotPosition()
                                )

                                pivotPositionOnFirstClick = getPivotPosition()

                            -- Define the mouse position variables

                                mousePosOnFirstClick = (if startMovingFromSelectionsPivot == true then pivotPositionOnFirstClick else worldPointFromHWNDSecondary)

                                mousePosOnToolStart = [((worldPointFromHWNDSecondary[1] - bSelectionPosOnFirstClick[1]) + bSelectionPosOnToolStart[1]), ((worldPointFromHWNDSecondary[2] - bSelectionPosOnFirstClick[2]) + bSelectionPosOnToolStart[2]), ((worldPointFromHWNDSecondary[3] - bSelectionPosOnFirstClick[3]) + bSelectionPosOnToolStart[3])]

                            -- Move the selection back to where it was in case it was being dragged

                                if subObjectLevelIsZero() then(
                                    $.pos = bSelectionPosOnToolStart
                                )else(
                                    -- Editable poly

                                        if (modPanel.getCurrentObject() as string) == "Editable Poly" or (modPanel.getCurrentObject() as string) == "Editable Mesh" then(
                                            if subObjectLevel == 1 then(
                                                move $.selectedVerts [bSelectionPosOnToolStart[1] - bSelectionPosOnFirstClick[1], bSelectionPosOnToolStart[2] - bSelectionPosOnFirstClick[2], bSelectionPosOnToolStart[3] - bSelectionPosOnFirstClick[3]]
                                            )

                                            if subObjectLevel == 2 or subObjectLevel == 3 then(
                                                move $.selectedEdges [bSelectionPosOnToolStart[1] - bSelectionPosOnFirstClick[1], bSelectionPosOnToolStart[2] - bSelectionPosOnFirstClick[2], bSelectionPosOnToolStart[3] - bSelectionPosOnFirstClick[3]]
                                            )

                                            if subObjectLevel == 4 or subObjectLevel == 5 then(
                                                move $.selectedFaces [bSelectionPosOnToolStart[1] - bSelectionPosOnFirstClick[1], bSelectionPosOnToolStart[2] - bSelectionPosOnFirstClick[2], bSelectionPosOnToolStart[3] - bSelectionPosOnFirstClick[3]]
                                            )
                                        )

                                    -- Edit poly

                                        if matchPattern (modPanel.getCurrentObject() as string) Pattern:"Edit_Poly:*" then(
                                            EditPolyMod.MoveSelection $.modifiers[#Edit_Poly] [bSelectionPosOnToolStart[1] - bSelectionPosOnFirstClick[1], bSelectionPosOnToolStart[2] - bSelectionPosOnFirstClick[2], bSelectionPosOnToolStart[3] - bSelectionPosOnFirstClick[3]]
                                        )
                                )

                    -- Start the tool

                          startTool betterMove

                    -- Post-tool code

                        -- Set the grid back to default

                            activeGrid = undefined

                        -- Set cursor

                            if selection.count != 0 then(
                                setSysCur #move
                            )

                        -- Toggle selection lock if relevant

                            if toggleSelectionLockAfterCurrentMove == true then(
                                max spacebar

                                toggleSelectionLockAfterCurrentMove = false
                            )

                        -- Destroy rollouts

                            destroyDialog enterDistanceRollout

                            destroyDialog displayDistanceRollout

                            try(
                                destroyDialog selectionUnlockedRollout
                            )catch()

                        mousePos2D = undefined

                        -- Define selectionOnLastRound variable

                            if subObjectLevelIsZero() then(
                                selectionOnLastRound = (selection as array)
                            )else(
                                -- Editable poly

                                    if (modPanel.getCurrentObject() as string) == "Editable Poly" then(
                                        if subObjectLevel == 1 then(
                                            selectionOnLastRound = polyop.getVertSelection selection[1]
                                        )

                                        if subObjectLevel == 2 or subObjectLevel == 3 then(
                                            selectionOnLastRound = polyop.getEdgeSelection selection[1]
                                        )

                                        if subObjectLevel == 4 or subObjectLevel == 5 then(
                                            selectionOnLastRound = polyop.getFaceSelection selection[1]
                                        )
                                    )

                                -- Edit poly

                                    if matchPattern (modPanel.getCurrentObject() as string) Pattern:"Edit_Poly:*" then(
                                        if subObjectLevel == 1 then(
                                            selectionOnLastRound = (EditPolyMod.GetSelection $.Edit_Poly #Vertex) as string
                                        )

                                        if subObjectLevel == 2 or subObjectLevel == 3 then(
                                            selectionOnLastRound = (EditPolyMod.GetSelection $.Edit_Poly #Edge) as string
                                        )

                                        if subObjectLevel == 4 or subObjectLevel == 5 then(
                                            selectionOnLastRound = (EditPolyMod.GetSelection $.Edit_Poly #Face) as string
                                        )
                                    )

                                -- Editable mesh

                                    if (modPanel.getCurrentObject() as string) == "Editable Mesh" then(
                                        if subObjectLevel == 1 then(
                                            selectionOnLastRound = getVertSelection selection[1]
                                        )

                                        if subObjectLevel == 2 or subObjectLevel == 3 then(
                                            selectionOnLastRound = getEdgeSelection selection[1]
                                        )

                                        if subObjectLevel == 4 or subObjectLevel == 5 then(
                                            selectionOnLastRound = getFaceSelection selection[1]
                                        )
                                    )
                            )

                        -- Define moveableSelectionExistedOnLastRun variable

                            if somethingMoveableIsSelected() then(
                                moveableSelectionExistedOnLastRun = true
                            )else(
                                moveableSelectionExistedOnLastRun = false
                            )

                        -- Package the move that was just done into an undoable event

                            -- If select and move mode is true, then an object/subobject was selected before the tool was run, and therefore before theHold was begun. This select event should be treated as part of the whole move event. The following conditional statement gives a unique event name to the event if select and move mode was true, so that the undo event handler knows to handle this.

                                if selectAndMoveMode == true then(
                                    theHold.Accept "Move   "
                                )else(
                                    theHold.Accept "Move  "
                                )

                        BetterToolsDetectWhenMoveToolIsExitedTimer.start()

                        -- Ensure axis is shown if relevant

                            if (getINISetting maxINIFile "Performance" "showaxisicon") == "0" and turnAxisIconBackOn == true then(
                                max showaxisicon
                            )

                        if not somethingMoveableIsSelected() or selectionAutoLockPreference == false then(
                            selectAndMoveMode = true

                            BetterToolsGetWorldPointFromHWNDsTimer.start()

                            -- Restart timer to detect selection change

                                if subObjectLevelIsZero() then(
                                    testTimer.start()
                                )else(
                                    testTimer.start()

                                    subObjectLevelBeforeModifierParameterChange = subObjectLevel
                                )
                        )else(
                            selectAndMoveMode = false

                            BetterToolsDeselectIfSelectionLockIsTurnedOffTimer.start()

                            BetterToolsStartToolWhenMouseIsClickedTimer.start()
                        )

                        -- Toggle and retoggle selection lock. If the gizmo is clicked while selection is locked, snap stops working due to a bug in Max. This fixes the issue if it happened. Note that this code was tested at the end of the tool's stop clause and didn't work, so there's something between there and here that this needs to happen after.

                            max spacebar

                            max spacebar
                )

            -- Change variable when mouse is clicked (needs to stay below the startbetterMoveToolFunction function)

                fn changeVariableWhenMouseIsClicked = (
                    -- Set axis constraints to undefined any time the gizmo stops being clicked on. Note: This may need to moved to its own timer-activated function if selection lock functionality is changed from being always on if a selection exists, as if this happens then sometimes select and move mode will be false (meaning this function isn't constantly running on a timer) while a gizmo exists.

                        if toolmode.axisconstraints != undefined then(
                            if ((mouse.buttonStates as string) != "#{1}" and (mouse.buttonStates as string) != "#{1, 3}") then(
                                (dotNetClass "Autodesk.Max.GlobalInterface").Instance.coreinterface7.PushAxisConstraints -2147483646

                                -- Toggle and retoggle selection lock. If the gizmo is clicked while selection is locked, snap stops working due to a bug in Max. This fixes the issue.

                                    max spacebar

                                    max spacebar
                            )
                        )

                    -- If selectAndMoveMode is true, or is false and the mouse has been clicked (and was unclicked since the last move), then start the tool. If not, then the mouse is unclicked now, so we update the variable so next time the mouse is clicked down we know to start the tool. Without this conditional, the tool will start straight away if the mouse is still pressed from the previous move.

                        if ((mouse.buttonStates as string) == "#{1}" or (mouse.buttonStates as string) == "#{1, 3}") and mouseHasBeenUnclicked == true then(
                             -- Set mouseHasBeenUnclicked to false. This needs to be done by the end of the ensuing move, so might as well update it now for readability's sake.

                                mouseHasBeenUnclicked = false

                            if selection.count != 0 then(
                                if toolmode.axisconstraints == undefined then( -- If the user has clicked the gizmo (whether to change constraints or to drag), do nothing
                                    bSelectionOriginalPos = selection[1].pos

                                    startbetterMoveToolFunction()
                                )else(
                                    lastAxisConstraints = toolmode.axisconstraints
                                )
                            )
                        )else(
                            -- Get world point from HWNDs so that if the next time the timer ticks the mouse has been clicked, we have the correct worldPoint value. We do this here rather than just when the selection has changed because by the time this function has detected the selection change, the mouse may have been moved elsewhere, and if it was moved to another snap point then the HWNDs are now wrong.

                                if snapMode.node != undefined then(
                                    startMovingFromSelectionsPivot = false

                                    getWorldPointFromHWNDsSecondaryFunction()
                                )else(
                                    startMovingFromSelectionsPivot = true
                                )

                            if ((mouse.buttonStates as string) != "#{1}" and (mouse.buttonStates as string) != "#{1, 3}") then(
                                if mouseHasBeenUnclicked == false then( -- Not sure if it improves performance to only change a variable if it needs to be changed, but doing this in case it does
                                    mouseHasBeenUnclicked = true
                                )
                            )
                        )
                )

            -- Change variable when selection is changed (needs to stay below the startbetterMoveToolFunction function)

                fn changeVariableWhenSelectionIsChangedFunction = (
                    -- Set axis constraints to undefined any time the gizmo stops being clicked on. Note: This may need to moved to its own timer-activated function if selection lock functionality is changed from being always on if a selection exists, as if this happens then sometimes select and move mode will be false (meaning this function isn't constantly running on a timer) while a gizmo exists.

                        if toolmode.axisconstraints != undefined then(
                            if ((mouse.buttonStates as string) != "#{1}" and (mouse.buttonStates as string) != "#{1, 3}") then(
                                (dotNetClass "Autodesk.Max.GlobalInterface").Instance.coreinterface7.PushAxisConstraints -2147483646

                                -- Toggle and retoggle selection lock. If the gizmo is clicked while selection is locked, snap stops working due to a bug in Max. This fixes the issue.

                                    max spacebar

                                    max spacebar
                            )
                        )

                    if undoOrRedoJustOccurred == false then(
                        if isCurrentModifierMoveable() then( -- If the current modifier isn't moveable, then the tool shouldn't run. Most code wouldn't run regardless of this conditional, but certain things would, such as gizmo hiding whenever it is shown.
                            -- Set axis constraints to undefined any time the gizmo stops being clicked on

                                if toolmode.axisconstraints != undefined then(
                                    if ((mouse.buttonStates as string) != "#{1}" and (mouse.buttonStates as string) != "#{1, 3}") then(
                                        (dotNetClass "Autodesk.Max.GlobalInterface").Instance.coreinterface7.PushAxisConstraints -2147483646

                                        -- Toggle and retoggle selection lock. If the gizmo is clicked while selection is locked, snap stops working due to a bug in Max. This fixes the issue.

                                            max spacebar

                                            max spacebar
                                    )
                                )

                            -- If the gizmo is not being clicked on, continue

                                if toolmode.axisconstraints == undefined then(
                                    -- Variables

                                        -- Define toolWasStarted variable

                                            toolWasStarted = false

                                        -- Define subselectionCount variable

                                            if not subObjectLevelIsZero() then(
                                                SubselectionCount = 0

                                                -- Editable poly

                                                    if (modPanel.getCurrentObject() as string) == "Editable Poly" then(
                                                        if subObjectLevelBeforeModifierParameterChange == subObjectLevel then( -- If not, the change registered was just moving to a different subObjectLevel
                                                            if (subObjectLevel == 1 and ((polyop.getVertSelection selection[1]).numberset) != 0) then(
                                                                SubselectionCount = ((polyop.getVertSelection selection[1]).numberset)
                                                            )

                                                            if ((subObjectLevel == 2 or subObjectLevel == 3) and ((polyop.getEdgeSelection selection[1]).numberset) != 0) then(
                                                                SubselectionCount = ((polyop.getEdgeSelection selection[1]).numberset)
                                                            )

                                                            if ((subObjectLevel == 4 or subObjectLevel == 5 ) and ((polyop.getFaceSelection selection[1]).numberset) != 0) then(
                                                                SubselectionCount = ((polyop.getFaceSelection selection[1]).numberset)
                                                            )
                                                        )
                                                    )

                                                -- Edit poly

                                                    if matchPattern (modPanel.getCurrentObject() as string) Pattern:"Edit_Poly:*" then(
                                                        if subObjectLevelBeforeModifierParameterChange == subObjectLevel then( -- If not, the change registered was just moving to a different subObjectLevel
                                                            if (subObjectLevel == 1 and (EditPolyMod.GetSelection $.Edit_Poly #Vertex) as string != "#{}") then(
                                                                -- Determine whether one or multple subobjects are selected

                                                                    if not matchPattern ((EditPolyMod.GetSelection $.Edit_Poly #Vertex) as string) Pattern:"*.*" and not matchPattern ((EditPolyMod.GetSelection $.Edit_Poly #Vertex) as string) Pattern:"*,*" then(
                                                                        SubselectionCount = 1
                                                                    )else(
                                                                        SubselectionCount = 2
                                                                    )
                                                            )

                                                            if ((subObjectLevel == 2 or subObjectLevel == 3) and (EditPolyMod.GetSelection $.Edit_Poly #Edge) as string != "#{}") then(
                                                                -- Determine whether one or multple subobjects are selected

                                                                    if not matchPattern ((EditPolyMod.GetSelection $.Edit_Poly #Edge) as string) Pattern:"*.*" and not matchPattern ((EditPolyMod.GetSelection $.Edit_Poly #Edge) as string) Pattern:"*,*" then(
                                                                        SubselectionCount = 1
                                                                    )else(
                                                                        SubselectionCount = 2
                                                                    )
                                                            )

                                                            if ((subObjectLevel == 4 or subObjectLevel == 5) and (EditPolyMod.GetSelection $.Edit_Poly #Face) as string != "#{}") then(
                                                                -- Determine whether one or multple subobjects are selected

                                                                    if not matchPattern ((EditPolyMod.GetSelection $.Edit_Poly #Face) as string) Pattern:"*.*" and not matchPattern ((EditPolyMod.GetSelection $.Edit_Poly #Face) as string) Pattern:"*,*" then(
                                                                        SubselectionCount = 1
                                                                    )else(
                                                                        SubselectionCount = 2
                                                                    )
                                                            )
                                                        )
                                                    )

                                                -- Editable mesh

                                                    if (modPanel.getCurrentObject() as string) == "Editable Mesh" then(
                                                        if subObjectLevelBeforeModifierParameterChange == subObjectLevel then( -- If not, the change registered was just moving to a different subObjectLevel
                                                            if subObjectLevel == 1 and ((getVertSelection selection[1]) as string) != "#{}" then(
                                                                -- Determine whether one or multple subobjects are selected

                                                                    if not matchPattern ((getVertSelection selection[1]) as string) Pattern:"*.*" and not matchPattern ((getVertSelection selection[1]) as string) Pattern:"*,*" then(
                                                                        SubselectionCount = 1
                                                                    )else(
                                                                        SubselectionCount = 2
                                                                    )
                                                            )

                                                            if (subObjectLevel == 2 or subObjectLevel == 3) and ((getEdgeSelection selection[1]) as string) != "#{}" then(
                                                                -- Determine whether one or multple subobjects are selected

                                                                    if not matchPattern ((getEdgeSelection selection[1]) as string) Pattern:"*.*" and not matchPattern ((getEdgeSelection selection[1]) as string) Pattern:"*,*" then(
                                                                        SubselectionCount = 1
                                                                    )else(
                                                                        SubselectionCount = 2
                                                                    )
                                                            )

                                                            if (subObjectLevel == 4 or subObjectLevel == 5) and ((getFaceSelection selection[1]) as string) != "#{}" then(
                                                                -- Determine whether one or multple subobjects are selected

                                                                    if not matchPattern ((getFaceSelection selection[1]) as string) Pattern:"*.*" and not matchPattern ((getFaceSelection selection[1]) as string) Pattern:"*,*" then(
                                                                        SubselectionCount = 1
                                                                    )else(
                                                                        SubselectionCount = 2
                                                                    )
                                                            )
                                                        )
                                                    )
                                            )

                                        -- Define selectionOnCurrentRound variable

                                            if subObjectLevelIsZero() then(
                                                selectionOnCurrentRound = (selection as array)
                                            )else(
                                                -- Editable poly

                                                    if (modPanel.getCurrentObject() as string) == "Editable Poly" then(
                                                        if subObjectLevel == 1 then(
                                                            selectionOnCurrentRound = polyop.getVertSelection selection[1]
                                                        )

                                                        if subObjectLevel == 2 or subObjectLevel == 3 then(
                                                            selectionOnCurrentRound = polyop.getEdgeSelection selection[1]
                                                        )

                                                        if subObjectLevel == 4 or subObjectLevel == 5 then(
                                                            selectionOnCurrentRound = polyop.getFaceSelection selection[1]
                                                        )
                                                    )

                                                -- Edit poly

                                                    if matchPattern (modPanel.getCurrentObject() as string) Pattern:"Edit_Poly:*" then(
                                                        if subObjectLevel == 1 then(
                                                            selectionOnCurrentRound = (EditPolyMod.GetSelection $.Edit_Poly #Vertex) as string
                                                        )

                                                        if subObjectLevel == 2 or subObjectLevel == 3 then(
                                                            selectionOnCurrentRound = (EditPolyMod.GetSelection $.Edit_Poly #Edge) as string
                                                        )

                                                        if subObjectLevel == 4 or subObjectLevel == 5 then(
                                                            selectionOnCurrentRound = (EditPolyMod.GetSelection $.Edit_Poly #Face) as string
                                                        )
                                                    )

                                                -- Editable mesh

                                                    if (modPanel.getCurrentObject() as string) == "Editable Mesh" then(
                                                        if subObjectLevel == 1 then(
                                                            selectionOnCurrentRound = getVertSelection selection[1]
                                                        )

                                                        if subObjectLevel == 2 or subObjectLevel == 3 then(
                                                            selectionOnCurrentRound = getEdgeSelection selection[1]
                                                        )

                                                        if subObjectLevel == 4 or subObjectLevel == 5 then(
                                                            selectionOnCurrentRound = getFaceSelection selection[1]
                                                        )
                                                    )
                                            )

                                        -- Set mouseHasBeenUnclicked variable to true if it has

                                            if mouseHasBeenUnclicked == false then( -- Not sure if it improves performance to only change a variable if it needs to be changed, but doing this in case it does
                                                if ((mouse.buttonStates as string) != "#{1}" and (mouse.buttonStates as string) != "#{1, 3}") then(
                                                    mouseHasBeenUnclicked = true
                                                )
                                            )

                                    -- Continue if mouse has been unclicked since last move

                                        if mouseHasBeenUnclicked == true then(
                                            -- Variables

                                                if not subObjectLevelIsZero() then(
                                                    if subObjectCountOnLastRun != (getNumVerts $) then(
                                                        subObjectCountHasChanged = true
                                                    )else(
                                                        subObjectCountHasChanged = false
                                                    )
                                                )else(
                                                    if subObjectCountOnLastRun != (objects.count) then(
                                                        subObjectCountHasChanged = true
                                                    )else(
                                                        subObjectCountHasChanged = false
                                                    )
                                                )

                                            -- Continue if selection count hasn't changed since last run (if it has, then the user has shift-dragged a subobject and the tool shouldn't start)

                                                if subObjectCountHasChanged == false then(
                                                    -- Click and move stuff

                                                        if subObjectLevelIsZero() then(
                                                            if moveInSubobjectMode == false then( -- If not, this means the callback was triggered by changing in or out of subobject level, so nothing should be done
                                                                if userIsClickingOnEitherSelectionOrNothing() then(
                                                                    -- Ensure an object is under the mouse or selection is locked

                                                                        if objectWasUnderMouseOnFirstClick == true or selLocked() then(
                                                                            -- Run the start tool function

                                                                                -- Stop timers

                                                                                    testTimer.stop()

                                                                                    BetterToolsDetectIfUndoOrRedoMadeNoChangeToSelectionSetTimer.stop()

                                                                                    BetterToolsGetWorldPointFromHWNDsTimer.stop()

                                                                                    BetterToolsDetermineWhetherToMoveInSubobjectModeTimer.stop()

                                                                                    BetterToolsDetectWhenMoveToolIsExitedTimer.stop()

                                                                                    startMoveToolWhenAnObjectIsSelectedTimer.stop()

                                                                                -- Variables

                                                                                    selectAndMoveMode = false

                                                                                    toolWasStarted = true

                                                                                    HWNDOnLastRun = undefined

                                                                                    HWNDOnCurrentRun = undefined

                                                                                    mouseHasBeenUnclicked2 = false

                                                                                    mousePos2D = mouse.pos

                                                                                undo off(
                                                                                    -- Ensure axis is hidden

                                                                                        if (getINISetting maxINIFile "Performance" "showaxisicon") == "1" then(
                                                                                            max showaxisicon
                                                                                        )

                                                                                    -- Define worldPointFromHWND variable

                                                                                        maxChildrenHWNDs = (windows.getChildrenHWND #max)

                                                                                        for a = 1 to maxChildrenHWNDs.count do(
                                                                                            if maxChildrenHWNDs[a][4] == "Static" and maxChildrenHWNDs[a][5] == "X:" and maxChildrenHWNDs[a][6] == 0P then(
                                                                                                worldPointFromHWND = [((maxChildrenHWNDs[a + 3][5]) as float),((maxChildrenHWNDs[a + 9][5]) as float),((maxChildrenHWNDs[a + 15][5]) as float)]

                                                                                                exit
                                                                                            )
                                                                                        )

                                                                                    -- Activate tiny grid

                                                                                        -- Ensure grid snap is on so that if mouse moves before tool starts, we're constantly snapped to the active grid's points and HWND readings are accurate, meaning the object is moved to the right place on tool start

                                                                                            snapMode.setOSnapItemActive 4 1 true

                                                                                            snapMode.display = false

                                                                                        -- Set grid sizes to really small

                                                                                            $BetterToolsMainGrid.grid = .125
                                                                                            $BetterToolsXGrid.grid = .125
                                                                                            $BetterToolsYGrid.grid = .125
                                                                                            $BetterToolsZGrid.grid = .125

                                                                                    subObjectLevel = 0
                                                                                ) -- (Undo end bracket)

                                                                                 -- Set mouseHasBeenUnclicked to false. This needs to be done by the end of the ensuing move, so might as well update it now for readability's sake.

                                                                                    mouseHasBeenUnclicked = false

                                                                                bSelectionOriginalPos = selection[1].pos

                                                                                startbetterMoveToolFunction()
                                                                        )
                                                                )
                                                            )
                                                        )else(
                                                            if moveInSubobjectMode == true then( -- If not, this means the callback was triggered by changing in or out of subobject level, so nothing should be done
                                                                -- If mouse is clicking on either selection or nothing, wait until user drags the subselection or unclicks...

                                                                    if userIsClickingOnEitherSelectionOrNothing() then(
                                                                        -- Variables

                                                                            mouseHasBeenClicked = true

                                                                        -- Run the tool if he user has dragged the subselection

                                                                            -- Variables

                                                                                -- Define HWNDOnCurrentRun variable

                                                                                    maxChildrenHWNDs = (windows.getChildrenHWND #max)

                                                                                    for a = 1 to maxChildrenHWNDs.count do(
                                                                                        if maxChildrenHWNDs[a][4] == "Static" and maxChildrenHWNDs[a][5] == "X:" and maxChildrenHWNDs[a][6] == 0P then(
                                                                                            HWNDOnCurrentRun = [((maxChildrenHWNDs[a + 3][5]) as float),((maxChildrenHWNDs[a + 9][5]) as float),((maxChildrenHWNDs[a + 15][5]) as float)]

                                                                                            exit
                                                                                        )
                                                                                    )

                                                                            -- If the current selection position is different from the last, and they are not just different because the last hasn't been defined yet due to this being the first run, then start the tool

                                                                                if HWNDOnCurrentRun != HWNDOnLastRun and HWNDOnCurrentRun != undefined and HWNDOnLastRun != undefined then(
                                                                                    -- Run the start tool function

                                                                                        -- Stop timers

                                                                                            testTimer.stop()

                                                                                            BetterToolsDetectIfUndoOrRedoMadeNoChangeToSelectionSetTimer.stop()

                                                                                            BetterToolsGetWorldPointFromHWNDsTimer.stop()

                                                                                            BetterToolsDetermineWhetherToMoveInSubobjectModeTimer.stop()

                                                                                            BetterToolsDetectWhenMoveToolIsExitedTimer.stop()

                                                                                            startMoveToolWhenAnObjectIsSelectedTimer.stop()

                                                                                        -- Variables

                                                                                            selectAndMoveMode = false

                                                                                            toolWasStarted = true

                                                                                            HWNDOnLastRun = undefined

                                                                                            HWNDOnCurrentRun = undefined

                                                                                            mouseHasBeenUnclicked2 = false

                                                                                            mousePos2D = mouse.pos

                                                                                        undo off(
                                                                                            -- Ensure axis is hidden

                                                                                                if (getINISetting maxINIFile "Performance" "showaxisicon") == "1" then(
                                                                                                    max showaxisicon
                                                                                                )

                                                                                            -- Move and activate the grid if selectAndMoveMode (or else it is done in the tool once worldPoint data is available). This needs to be done here rather than in the tool, so that any mouse moving done between first click and the tool starting is done on the plane we clicked on and the object moves to the expected place (which it otherwise wouldn't on its first move as mouse is still registered as being on the default grid).

                                                                                                $BetterToolsMainGrid.pos = worldPointFromHWND

                                                                                                $BetterToolsXGrid.pos = worldPointFromHWND

                                                                                                $BetterToolsYGrid.pos = worldPointFromHWND

                                                                                                $BetterToolsZGrid.pos = worldPointFromHWND

                                                                                                activeGrid = $BetterToolsMainGrid

                                                                                            -- Ensure grid snap is on so that if mouse moves before tool starts, we're constantly snapped to the active grid's points and HWND readings are accurate, meaning the object is moved to the right place on tool start

                                                                                                snapMode.setOSnapItemActive 4 1 true

                                                                                                snapMode.display = false

                                                                                            -- Set grid sizes to really small

                                                                                                $BetterToolsMainGrid.grid = .125
                                                                                                $BetterToolsXGrid.grid = .125
                                                                                                $BetterToolsYGrid.grid = .125
                                                                                                $BetterToolsZGrid.grid = .125

                                                                                            if moveInSubobjectMode == false then(
                                                                                                subObjectLevel = 0
                                                                                            )

                                                                                            selectionChanged = true
                                                                                        ) -- (Undo end bracket)

                                                                                         -- Set mouseHasBeenUnclicked to false. This needs to be done by the end of the ensuing move, so might as well update it now for readability's sake.

                                                                                            mouseHasBeenUnclicked = false

                                                                                        if toolmode.axisconstraints == undefined then( -- If the user has clicked the gizmo (whether to change constraints or to drag), do nothing
                                                                                            bSelectionOriginalPos = selection[1].pos

                                                                                            startbetterMoveToolFunction()
                                                                                        )else(
                                                                                            lastAxisConstraints = toolmode.axisconstraints
                                                                                        )
                                                                                )

                                                                            -- Variables

                                                                                -- Define HWNDOnLastRun variable

                                                                                    maxChildrenHWNDs = (windows.getChildrenHWND #max)

                                                                                    for a = 1 to maxChildrenHWNDs.count do(
                                                                                        if maxChildrenHWNDs[a][4] == "Static" and maxChildrenHWNDs[a][5] == "X:" and maxChildrenHWNDs[a][6] == 0P then(
                                                                                            HWNDOnLastRun = [((maxChildrenHWNDs[a + 3][5]) as float),((maxChildrenHWNDs[a + 9][5]) as float),((maxChildrenHWNDs[a + 15][5]) as float)]

                                                                                            exit
                                                                                        )
                                                                                    )
                                                                    )

                                                                -- If user has just unclicked from selection or nothing...

                                                                    if not userIsClickingOnEitherSelectionOrNothing() then(
                                                                        if mouseHasBeenClicked == true then(
                                                                            -- Variables

                                                                                mouseHasBeenClicked = false

                                                                            if somethingMoveableIsSelected() then(
                                                                                -- Run the start tool function

                                                                                    -- Stop timers

                                                                                        testTimer.stop()

                                                                                        BetterToolsDetectIfUndoOrRedoMadeNoChangeToSelectionSetTimer.stop()

                                                                                        BetterToolsGetWorldPointFromHWNDsTimer.stop()

                                                                                        BetterToolsDetermineWhetherToMoveInSubobjectModeTimer.stop()

                                                                                        BetterToolsDetectWhenMoveToolIsExitedTimer.stop()

                                                                                        startMoveToolWhenAnObjectIsSelectedTimer.stop()

                                                                                    -- Variables

                                                                                        toolWasStarted = true

                                                                                        HWNDOnLastRun = undefined

                                                                                        HWNDOnCurrentRun = undefined

                                                                                        mouseHasBeenUnclicked2 = false

                                                                                        mousePos2D = mouse.pos

                                                                                    undo off(
                                                                                        -- Ensure axis is hidden

                                                                                            if (getINISetting maxINIFile "Performance" "showaxisicon") == "1" then(
                                                                                                max showaxisicon
                                                                                            )

                                                                                        -- Activate tiny grid

                                                                                            -- Ensure grid snap is on so that if mouse moves before tool starts, we're constantly snapped to the active grid's points and HWND readings are accurate, meaning the object is moved to the right place on tool start

                                                                                                snapMode.setOSnapItemActive 4 1 true

                                                                                                snapMode.display = false

                                                                                            -- Set grid sizes to really small

                                                                                                $BetterToolsMainGrid.grid = .125
                                                                                                $BetterToolsXGrid.grid = .125
                                                                                                $BetterToolsYGrid.grid = .125
                                                                                                $BetterToolsZGrid.grid = .125

                                                                                        if moveInSubobjectMode == false then(
                                                                                            subObjectLevel = 0
                                                                                        )

                                                                                        selectionChanged = true
                                                                                    ) -- (Undo end bracket)

                                                                                     -- Set mouseHasBeenUnclicked to false. This needs to be done by the end of the ensuing move, so might as well update it now for readability's sake.

                                                                                        mouseHasBeenUnclicked = false

                                                                                    if toolmode.axisconstraints == undefined then( -- If the user has clicked the gizmo (whether to change constraints or to drag), do nothing
                                                                                        bSelectionOriginalPos = selection[1].pos

                                                                                        startbetterMoveToolFunction()
                                                                                    )else(
                                                                                        lastAxisConstraints = toolmode.axisconstraints
                                                                                    )
                                                                            )
                                                                        )
                                                                    )
                                                            )
                                                        )

                                                    -- Select and move stuff

                                                        -- If selection has been changed then start the tool...
                                                        print 1
                                                            if moveableSelectionIsOne() and ((selectionOnCurrentRound as string) != (selectionOnLastRound as string)) then( -- The function should only do anything if an object is selected by clicking (not click-dragging or non-viewport-clicking things such as selecting things in scene explorer), and thus only if a single object is selected, unless a selection already existed.
                                                                if subObjectLevelIsZero() then(
                                                                    if moveInSubobjectMode == false then( -- If not, this means the callback was triggered by changing in or out of subobject level, so nothing should be done
                                                                        -- Ensure an object is under the mouse. If not, this means the user has selected the object in a way other than clicking on it (such as through the scene exporer), so nothing should happen.
                                                                        print 2
                                                                            if objectWasUnderMouseOnFirstClick == true then(
                                                                                -- Run the start tool function
                                                                                print 3
                                                                                    testTimer.stop()

                                                                                    undo off(
                                                                                        BetterToolsDetectIfUndoOrRedoMadeNoChangeToSelectionSetTimer.stop()

                                                                                        BetterToolsGetWorldPointFromHWNDsTimer.stop()

                                                                                        BetterToolsDetermineWhetherToMoveInSubobjectModeTimer.stop()

                                                                                        BetterToolsDetectWhenMoveToolIsExitedTimer.stop()

                                                                                        toolWasStarted = true

                                                                                        mousePos2D = mouse.pos

                                                                                        -- Ensure axis is hidden

                                                                                            if (getINISetting maxINIFile "Performance" "showaxisicon") == "1" then(
                                                                                                max showaxisicon
                                                                                            )

                                                                                        -- Define worldPointFromHWND variable

                                                                                            maxChildrenHWNDs = (windows.getChildrenHWND #max)

                                                                                            for a = 1 to maxChildrenHWNDs.count do(
                                                                                                if maxChildrenHWNDs[a][4] == "Static" and maxChildrenHWNDs[a][5] == "X:" and maxChildrenHWNDs[a][6] == 0P then(
                                                                                                    worldPointFromHWND = [((maxChildrenHWNDs[a + 3][5]) as float),((maxChildrenHWNDs[a + 9][5]) as float),((maxChildrenHWNDs[a + 15][5]) as float)]

                                                                                                    exit
                                                                                                )
                                                                                            )

                                                                                        -- Move and activate the grid if selectAndMoveMode (or else it is done in the tool once worldPoint data is available). This needs to be done here rather than in the tool, so that any mouse moving done between first click and the tool starting is done on the plane we clicked on and the object moves to the expected place (which it otherwise wouldn't on its first move as mouse is still registered as being on the default grid).

                                                                                            $BetterToolsMainGrid.pos = worldPointFromHWND

                                                                                            $BetterToolsXGrid.pos = worldPointFromHWND

                                                                                            $BetterToolsYGrid.pos = worldPointFromHWND

                                                                                            $BetterToolsZGrid.pos = worldPointFromHWND

                                                                                            activeGrid = $BetterToolsMainGrid

                                                                                        -- Ensure grid snap is on so that if mouse moves before tool starts, we're constantly snapped to the active grid's points and HWND readings are accurate, meaning the object is moved to the right place on tool start

                                                                                            snapMode.setOSnapItemActive 4 1 true

                                                                                            snapMode.display = false

                                                                                        -- Set grid sizes to really small

                                                                                            $BetterToolsMainGrid.grid = .125
                                                                                            $BetterToolsXGrid.grid = .125
                                                                                            $BetterToolsYGrid.grid = .125
                                                                                            $BetterToolsZGrid.grid = .125

                                                                                        if moveInSubobjectMode == false then(
                                                                                            subObjectLevel = 0
                                                                                        )

                                                                                        selectionChanged = true
                                                                                    ) -- (Undo end bracket)

                                                                                    selectAndMoveMode = true

                                                                                    startMoveToolWhenAnObjectIsSelectedTimer.stop()

                                                                                     -- Set mouseHasBeenUnclicked to false. This needs to be done by the end of the ensuing move, so might as well update it now for readability's sake.

                                                                                        mouseHasBeenUnclicked = false

                                                                                    bSelectionOriginalPos = selection[1].pos

                                                                                    startbetterMoveToolFunction()
                                                                            )
                                                                    )
                                                                )else(
                                                                    if moveInSubobjectMode == true then( -- If not, this means the callback was triggered by changing in or out of subobject level, so nothing should be done
                                                                        -- Run the start tool function

                                                                            testTimer.stop()

                                                                            toolWasStarted = true

                                                                            HWNDOnLastRun = undefined

                                                                            HWNDOnCurrentRun = undefined

                                                                            mouseHasBeenUnclicked2 = false

                                                                            selectAndMoveMode = true

                                                                            undo off(
                                                                                BetterToolsDetectIfUndoOrRedoMadeNoChangeToSelectionSetTimer.stop()

                                                                                BetterToolsGetWorldPointFromHWNDsTimer.stop()

                                                                                BetterToolsDetermineWhetherToMoveInSubobjectModeTimer.stop()

                                                                                BetterToolsDetectWhenMoveToolIsExitedTimer.stop()

                                                                                mousePos2D = mouse.pos

                                                                                -- Ensure axis is hidden

                                                                                    if (getINISetting maxINIFile "Performance" "showaxisicon") == "1" then(
                                                                                        max showaxisicon
                                                                                    )

                                                                                -- Define worldPointFromHWND variable

                                                                                    maxChildrenHWNDs = (windows.getChildrenHWND #max)

                                                                                    for a = 1 to maxChildrenHWNDs.count do(
                                                                                        if maxChildrenHWNDs[a][4] == "Static" and maxChildrenHWNDs[a][5] == "X:" and maxChildrenHWNDs[a][6] == 0P then(
                                                                                            worldPointFromHWND = [((maxChildrenHWNDs[a + 3][5]) as float),((maxChildrenHWNDs[a + 9][5]) as float),((maxChildrenHWNDs[a + 15][5]) as float)]

                                                                                            exit
                                                                                        )
                                                                                    )

                                                                                -- Move and activate the grid if selectAndMoveMode (or else it is done in the tool once worldPoint data is available). This needs to be done here rather than in the tool, so that any mouse moving done between first click and the tool starting is done on the plane we clicked on and the object moves to the expected place (which it otherwise wouldn't on its first move as mouse is still registered as being on the default grid).

                                                                                    $BetterToolsMainGrid.pos = worldPointFromHWND

                                                                                    $BetterToolsXGrid.pos = worldPointFromHWND

                                                                                    $BetterToolsYGrid.pos = worldPointFromHWND

                                                                                    $BetterToolsZGrid.pos = worldPointFromHWND

                                                                                    activeGrid = $BetterToolsMainGrid

                                                                                -- Ensure grid snap is on so that if mouse moves before tool starts, we're constantly snapped to the active grid's points and HWND readings are accurate, meaning the object is moved to the right place on tool start

                                                                                    snapMode.setOSnapItemActive 4 1 true

                                                                                    snapMode.display = false

                                                                                -- Set grid sizes to really small

                                                                                    $BetterToolsMainGrid.grid = .125
                                                                                    $BetterToolsXGrid.grid = .125
                                                                                    $BetterToolsYGrid.grid = .125
                                                                                    $BetterToolsZGrid.grid = .125

                                                                                if moveInSubobjectMode == false then(
                                                                                    subObjectLevel = 0
                                                                                )

                                                                                selectionChanged = true
                                                                            ) -- (Undo end bracket)

                                                                            startMoveToolWhenAnObjectIsSelectedTimer.stop()

                                                                            -- Set axis constraints to undefined any time the gizmo stops being clicked on. This may need to moved to its own timer-activated function if selection lock functionality is changed from being always on if a selection exists, as if this happens then sometimes select and move mode will be false (meaning this function isn't constantly running on a timer) while a gizmo exists.

                                                                                if toolmode.axisconstraints != undefined then(
                                                                                    if ((mouse.buttonStates as string) != "#{1}" and (mouse.buttonStates as string) != "#{1, 3}") then(
                                                                                        (dotNetClass "Autodesk.Max.GlobalInterface").Instance.coreinterface7.PushAxisConstraints -2147483646

                                                                                        -- Toggle and retoggle selection lock. If the gizmo is clicked while selection is locked, snap stops working due to a bug in Max. This fixes the issue.

                                                                                            max spacebar

                                                                                            max spacebar
                                                                                    )
                                                                                )

                                                                            if selectionChanged == true then(
                                                                                 -- Set mouseHasBeenUnclicked to false. This needs to be done by the end of the ensuing move, so might as well update it now for readability's sake.

                                                                                    mouseHasBeenUnclicked = false

                                                                                if selection.count != 0 and undoOrRedoJustOccurred == false then( -- If an undo or redo has triggered the function, the ensuing code shouldn't run
                                                                                    if toolmode.axisconstraints == undefined then( -- If the user has clicked the gizmo (whether to change constraints or to drag), do nothing
                                                                                        bSelectionOriginalPos = selection[1].pos

                                                                                        startbetterMoveToolFunction()
                                                                                    )else(
                                                                                        lastAxisConstraints = toolmode.axisconstraints
                                                                                    )
                                                                                )
                                                                            )
                                                                    )
                                                                )
                                                            )else(
                                                                -- Turn off selectAndMoveMode if any (so, multiple) objects were selected, and selectionAutoLockPreference is true

                                                                    if (subObjectLevelIsZero() and selection.count > 1) or (not subobjectLevelIsZero() and SubselectionCount > 1) then(
                                                                        if selectionAutoLockPreference == true then(
                                                                            testTimer.stop()

                                                                            selectAndMoveMode = false

                                                                            -- Ensure the selection changed callbacks are disabled

                                                                                testTimer.stop()

                                                                                try(
                                                                                    stopDetectingSubselectionChangesFunction()
                                                                                )catch()

                                                                            -- Lock the selection

                                                                                max spacebar

                                                                            -- Show axis

                                                                                if (getINISetting maxINIFile "Performance" "showaxisicon") == "0" and turnAxisIconBackOn == true then(
                                                                                    max showaxisicon
                                                                                )

                                                                            BetterToolsDeselectIfSelectionLockIsTurnedOffTimer.start()

                                                                            BetterToolsStartToolWhenMouseIsClickedTimer.start()
                                                                        )
                                                                    )
                                                            )
                                                )
                                        )
                                )else(
                                    lastAxisConstraints = toolmode.axisconstraints
                                )
                        )
                    )else(
                        -- Turn off selectAndMoveMode if any objects were selected, and selectionAutoLockPreference is true

                            if selection.count > 0 then(
                                if selectionAutoLockPreference == true then(
                                    selectAndMoveMode = false

                                    -- Ensure the selection changed callbacks are disabled

                                        testTimer.stop()

                                        try(
                                            stopDetectingSubselectionChangesFunction()
                                        )catch()

                                    -- Lock the selection

                                        max spacebar

                                    BetterToolsDeselectIfSelectionLockIsTurnedOffTimer.start()

                                    BetterToolsStartToolWhenMouseIsClickedTimer.start()
                                )
                            )

                        undoOrRedoJustOccurred = false
                    )

                    -- Variables for next run, if the tool wasn't started

                        if toolWasStarted == false then(
                            -- Define subObjectCountOnLastRun variable

                                if not subObjectLevelIsZero() then(
                                    subObjectCountOnLastRun = getNumVerts $
                                )else(
                                    subObjectCountOnLastRun = objects.count
                                )

                            -- Turn on the gizmo if it is hidden, a moveable selection has just been made, and the user hasn't turned it off manually

                                if (getINISetting maxINIFile "Performance" "showaxisicon") == "0" then(
                                    if somethingMoveableIsSelected() and moveableSelectionExistedOnLastRun == false then(
                                        if turnAxisIconBackOn == true then(
                                            max showaxisicon
                                        )
                                    )
                                )

                            -- Set the turnAxisIconBackOn variable to false if the user has turned the gizmo off (i.e. if the gizmo visibility has turned off when selection hasn't)

                                if (getINISetting maxINIFile "Performance" "showaxisicon") == "0" then(
                                    if somethingMoveableIsSelected() and moveableSelectionExistedOnLastRun == true then(
                                        if turnAxisIconBackOn == true then(
                                            turnAxisIconBackOn = false
                                        )
                                    )
                                )

                            -- Set the turnAxisIconBackOn variable to true if the user has turned the gizmo on (i.e. if the gizmo visibility has turned on when selection hasn't)

                                if (getINISetting maxINIFile "Performance" "showaxisicon") == "1" then(
                                    if somethingMoveableIsSelected() and moveableSelectionExistedOnLastRun == true then(
                                        if turnAxisIconBackOn == false then(
                                            turnAxisIconBackOn = true
                                        )
                                    )
                                )

                            -- Turn off the gizmo if the user has turned it on mid-session and no moveable selection is present, and note to turn it back on when it should be visible. It needs to stay hidden for now so that it doesn't flash on when a selection is made.

                                if (getINISetting maxINIFile "Performance" "showaxisicon") == "1" then(
                                    if not somethingMoveableIsSelected() then(
                                        if moveableSelectionExistedOnLastRun == true then(
                                            turnAxisIconBackOn = true
                                        )else(
                                            if turnAxisIconBackOn == true then(
                                                turnAxisIconBackOn = false
                                            )else(
                                                turnAxisIconBackOn = true
                                            )
                                        )

                                        max showaxisicon
                                    )
                                )

                            -- Define moveableSelectionExistedOnLastRun variable

                                if somethingMoveableIsSelected() then(
                                    moveableSelectionExistedOnLastRun = true
                                )else(
                                    moveableSelectionExistedOnLastRun = false
                                )

                            -- Define objectWasUnderMouseOnFirstClick variable. We do this here rather than just when the selection has changed because by the time this function has detected the selection change, the mouse may have been moved off the object.

                                -- Variables

                                    ry = mapScreenToWorldRay mouse.pos
                                    myray = ray ry.pos ry.dir
                                    intersect = intersectRayScene myray

                                if intersect.count > 0 then(
                                    objectWasUnderMouseOnFirstClick = true
                                )else(
                                    objectWasUnderMouseOnFirstClick = false
                                )

                            -- Define selectionOnLastRound variable

                                if subObjectLevelIsZero() then(
                                    selectionOnLastRound = (selection as array)
                                )else(
                                    -- Editable poly

                                        if (modPanel.getCurrentObject() as string) == "Editable Poly" then(
                                            if subObjectLevel == 1 then(
                                                selectionOnLastRound = polyop.getVertSelection selection[1]
                                            )

                                            if subObjectLevel == 2 or subObjectLevel == 3 then(
                                                selectionOnLastRound = polyop.getEdgeSelection selection[1]
                                            )

                                            if subObjectLevel == 4 or subObjectLevel == 5 then(
                                                selectionOnLastRound = polyop.getFaceSelection selection[1]
                                            )
                                        )

                                    -- Edit poly

                                        if matchPattern (modPanel.getCurrentObject() as string) Pattern:"Edit_Poly:*" then(
                                            if subObjectLevel == 1 then(
                                                selectionOnLastRound = (EditPolyMod.GetSelection $.Edit_Poly #Vertex) as string
                                            )

                                            if subObjectLevel == 2 or subObjectLevel == 3 then(
                                                selectionOnLastRound = (EditPolyMod.GetSelection $.Edit_Poly #Edge) as string
                                            )

                                            if subObjectLevel == 4 or subObjectLevel == 5 then(
                                                selectionOnLastRound = (EditPolyMod.GetSelection $.Edit_Poly #Face) as string
                                            )
                                        )

                                    -- Editable mesh

                                        if (modPanel.getCurrentObject() as string) == "Editable Mesh" then(
                                            if subObjectLevel == 1 then(
                                                selectionOnLastRound = getVertSelection selection[1]
                                            )

                                            if subObjectLevel == 2 or subObjectLevel == 3 then(
                                                selectionOnLastRound = getEdgeSelection selection[1]
                                            )

                                            if subObjectLevel == 4 or subObjectLevel == 5 then(
                                                selectionOnLastRound = getFaceSelection selection[1]
                                            )
                                        )
                                )

                            -- Get world point from HWNDs so that if the next time the timer ticks the mouse has been clicked, we have the correct worldPoint value. We do this here rather than just when the selection has changed because by the time this function has detected the selection change, the mouse may have been moved elsewhere, and if it was moved to another snap point then the HWNDs are now wrong.

                                if snapMode.node != undefined then(
                                    startMovingFromSelectionsPivot = false

                                    getWorldPointFromHWNDsSecondaryFunction()
                                )else(
                                    startMovingFromSelectionsPivot = true
                                )
                        )else(
                            toolWasStarted = false
                        )
                )

        -- Timers

            -- Detect when distance is entered

                global BetterToolsDetectWhenDistanceIsEnteredTimer = dotNetObject "System.Windows.Forms.Timer"
                dotnet.addEventHandler BetterToolsDetectWhenDistanceIsEnteredTimer "tick" stopToolOnDistanceEnteredFunction
                BetterToolsDetectWhenDistanceIsEnteredTimer.interval = 100

            -- Create reference

                global BetterToolsCreateReferenceTimer = dotNetObject "System.Windows.Forms.Timer"
                dotnet.addEventHandler BetterToolsCreateReferenceTimer "tick" BetterToolsCreateReference
                BetterToolsCreateReferenceTimer.interval = 1000

            -- Set focus on enter distance rollout

                global BetterToolsSetFocusTimer = dotNetObject "System.Windows.Forms.Timer"
                dotnet.addEventHandler BetterToolsSetFocusTimer "tick" enterDistanceRollout.setFocusFunction
                BetterToolsSetFocusTimer.interval = 333

            -- Change cursor to move

                global BetterToolsChangeCursorTimer = dotNetObject "System.Windows.Forms.Timer"
                dotnet.addEventHandler BetterToolsChangeCursorTimer "tick" changeCursorFunction
                BetterToolsChangeCursorTimer.interval = 1

            -- Deselect if selection lock is turned off

                global BetterToolsDeselectIfSelectionLockIsTurnedOffTimer = dotNetObject "System.Windows.Forms.Timer"
                dotnet.addEventHandler BetterToolsDeselectIfSelectionLockIsTurnedOffTimer "tick" BetterToolsDeselectIfSelectionLockIsTurnedOffFunction
                BetterToolsDeselectIfSelectionLockIsTurnedOffTimer.interval = 10

            -- Stop tool on mouse unclicked

                global BetterToolsStopToolOnMouseUnclickedTimer = dotNetObject "System.Windows.Forms.Timer"
                dotnet.addEventHandler BetterToolsStopToolOnMouseUnclickedTimer "tick" stopToolOnMouseUnclickedFunction
                BetterToolsStopToolOnMouseUnclickedTimer.interval = 1

            -- Get worldPoint from HWNDs

                global BetterToolsGetWorldPointFromHWNDsTimer = dotNetObject "System.Windows.Forms.Timer"
                dotnet.addEventHandler BetterToolsGetWorldPointFromHWNDsTimer "tick" getWorldPointFromHWNDsFunction
                BetterToolsGetWorldPointFromHWNDsTimer.interval = 100

            -- Start move tool when an object is selected

                global startMoveToolWhenAnObjectIsSelectedTimer = dotNetObject "System.Windows.Forms.Timer"
                dotnet.addEventHandler startMoveToolWhenAnObjectIsSelectedTimer "tick" startbetterMoveToolFunction
                startMoveToolWhenAnObjectIsSelectedTimer.interval = 10

            -- Detect when move tool is exited

                global BetterToolsDetectWhenMoveToolIsExitedTimer = dotNetObject "System.Windows.Forms.Timer"
                dotnet.addEventHandler BetterToolsDetectWhenMoveToolIsExitedTimer "tick" endMoveToolSessionFunction
                BetterToolsDetectWhenMoveToolIsExitedTimer.interval = 50

            -- Start tool

                global BetterToolsStartToolWhenMouseIsClickedTimer = dotNetObject "System.Windows.Forms.Timer"
                dotnet.addEventHandler BetterToolsStartToolWhenMouseIsClickedTimer "tick" changeVariableWhenMouseIsClicked
                BetterToolsStartToolWhenMouseIsClickedTimer.interval = 10

            -- Determine whether to move in subobject mode

                global BetterToolsDetermineWhetherToMoveInSubobjectModeTimer = dotNetObject "System.Windows.Forms.Timer"
                dotnet.addEventHandler BetterToolsDetermineWhetherToMoveInSubobjectModeTimer "tick" determineWhetherToMoveInSubobjectModeFunction
                BetterToolsDetermineWhetherToMoveInSubobjectModeTimer.interval = 100

            -- Detect shift key state

                global BetterToolsDetectShiftKeyStateTimer = dotNetObject "System.Windows.Forms.Timer"
                dotnet.addEventHandler BetterToolsDetectShiftKeyStateTimer "tick" toggleAxisReferenceLockBasedOnShiftKeyState
                BetterToolsDetectShiftKeyStateTimer.interval = 1

            -- Detect if undo or redo made no change to selection set

                global BetterToolsDetectIfUndoOrRedoMadeNoChangeToSelectionSetTimer = dotNetObject "System.Windows.Forms.Timer"
                dotnet.addEventHandler BetterToolsDetectIfUndoOrRedoMadeNoChangeToSelectionSetTimer "tick" detectIfUndoOrRedoMadeNoChangeToSelectionSetFunction
                BetterToolsDetectIfUndoOrRedoMadeNoChangeToSelectionSetTimer.interval = 50

            -- Test

                global testTimer = dotNetObject "System.Windows.Forms.Timer"
                dotnet.addEventHandler testTimer "tick" changeVariableWhenSelectionIsChangedFunction
                testTimer.interval = 1

    -- Tool

        tool betterMove(
            on start do(
                undo off(
                    setSysCur #move

                    bSelection = $selection
                    cSelection = $
                    dSelection = $selection
                    eSelection = $
                    betterMoveCurrentObject = $

                    bSelection1pos = bSelection[1].pos

                    stopTryingToStartBetterToolsStopToolOnMouseUnclickedTimer = false

                    BetterToolsStopToolOnMouseUnclickedTimerStarted = false

                    if mousePos2D == undefined then(
                        mousePos2D = mouse.pos
                    )

                    -- Hide the selection wireframes layer until mouse is moved. If the wireframe is visible before the object is moved, its grey outline can show over the object and look confusing.

                        if mousePos2D != mouse.pos then(
                            selectionWireframeLayer.isHidden = true
                        )

                    -- Define conditionToSetSelectAndMoveModeVariableToOnStop variable

                        conditionToSetSelectAndMoveModeVariableToOnStop = selectAndMoveMode

                    success = false

                    moveToolActive = true

                    -- Move reference start and end points to 0,0,0, so that if the move is undone (which for some reason unhindes the reference lines), they still can't be seen due to having lengths of 0

                        referenceLineX.pos = [0,0,0]
                        referenceEndPointX.pos = [0,0,0]
                        referenceLineY.pos = [0,0,0]
                        referenceEndPointY.pos = [0,0,0]
                        referenceLineZ.pos = [0,0,0]
                        referenceEndPointZ.pos = [0,0,0]
                        referenceLineSecondary.pos = [0,0,0]
                        referenceEndPointSecondary.pos = [0,0,0]
                        referenceLineLocked.pos = [0,0,0]
                        referenceEndPointLocked.pos = [0,0,0]

                    -- Set object to not show frozen in grey

                        eSelection.showFrozenInGray = false

                    -- Ensure selection is not frozen (why?)

                        try(
                            freeze eSelection

                            unfreeze eSelection
                        )catch()

                    -- Create selection wireframe

                        /*
                            if (selection.count < 100) then(
                                for n in (selection as array) do(
                                    instance n name: "betterMoveToolSelectionWireframe1"
                                    convertTo $betterMoveToolSelectionWireframe1 Editable_Poly
                                    $betterMoveToolSelectionWireframe1.displayByLayer = true
                                    $betterMoveToolSelectionWireframe1.wirecolor = color 100 100 100
                                    selectionWireframeLayer.addnode $betterMoveToolSelectionWireframe1
                                    $betterMoveToolSelectionWireframe1.name = "betterMoveToolSelectionWireframe"
                                )

                                subobjectLevel = currentsubobjectLevel
                            )
                        */

                    -- Clear firstClickPos so that the freeMove registered directly after start can define it. Note: Broken—freeMove doesn't always register.

                        firstClickPos = undefined

                    -- Adding callbacks

                        -- Rotating grids to viewport

                            callbacks.addscript #viewportChange "BetterMoveExternalFunctionsStructVariable.rotateGridsToFaceCamera()" id:#rotateGridsToFaceCamera

                    -- Set plane rotation variables to 0

                        lastPlaneRotationX = 0
                        lastPlaneRotationY = 0
                        lastPlaneRotationZ = 0

                    toolMode.coordsys #world

                    if subObjectLevel != 0 and subobjectLevel != undefined then(
                        currentModifier = modpanel.getCurrentObject()
                    )

                    -- Start the set focus timer

                        BetterToolsSetFocusTimer.start()

                    startMoving = true

                    BetterToolsGetWorldPointFromHWNDsTimer.stop()

                    -- Ensure snaps are as they originally were, in case they were changed on first click

                        snapMode.setOSnapItemActive 4 1 originalGridSnapState

                        snapMode.display = originalSnapDisplayState

                        -- Set grid sizes to home grid size, in case user uses grid snap

                            $BetterToolsMainGrid.grid = getGridSpacing()
                            $BetterToolsXGrid.grid = getGridSpacing()
                            $BetterToolsYGrid.grid = getGridSpacing()
                            $BetterToolsZGrid.grid = getGridSpacing()

                    -- Move the object to the current mouse position if relevant

                        if selectAndMoveMode == true and mousePos2D != mouse.pos then( -- If selectAndMoveMode is true, this means the worldPointFromHWND timer was used before clicking and the worldPointFromHWND variable is defined. If not, we don't have data on worldpoint until the first freeMove, so the equivalent code to what happens below will happen on first freeMove. This does make the code convoluted, but is done so we don't need to use the worldPointFromHWND timer if we don't need to (if selectAndMoveMode is false, the freeMove registers as soon as we click). Need to test how the timer drops performance—if negligable, then we can run it regardless of selectAndMoveMode and have all the code here. The mousePos2D part is because worldPointFromHWND can give strange results if the mouse is in the same place as it was when we first clicked. we compare the 2D values instad of 3D because the latter will be different if a snap was active on click, since we are no longer snapped to that point.
                            onMousePointFunctionWasRunOnStart = true

                            shiftKey = false

                            onMousePoint worldPointFromHWNDSecondary bSelection cSelection betterMoveCurrentObject shiftKey clicknoGlobalVariable

                            currentMousePositionGlobalVariable = worldPointFromHWNDSecondary

                            onMouseMoveFunction worldPointFromHWNDSecondary bSelection cSelection betterMoveCurrentObject clicknoGlobalVariable
                        )

                    currentMousePositionGlobalVariable = worldPointFromHWNDSecondary

                    BetterToolsDetectShiftKeyStateTimer.start()

                    setSysCur #move
                ) -- (Undo end bracket)
            )

            on freeMove do(
                undo off(
                    setToolBtnState #move true -- For some reason this doesn't work in the start clause

                    setSysCur #move

                    if (((gw.transPoint worldPoint)[1]) as string)[1] != "0" and (((gw.transPoint worldPoint)[2]) as string)[1] != "0" and startMoving == true then( -- For some reason, from the second time the tool starts onwards when doing selectAndMoveMode, the tool thinks mouse moves to top corner of viewport and back directly after start
                        -- Define firstClickPos. Since freeMove contains worldPoint data unlike start, this variable is best defined here in case we are moving the subject on tool start.

                            if firstClickPos == undefined then(
                                if startMovingFromSelectionsPivot == false then(
                                    firstClickPos = mousePosOnToolStart
                                )else(
                                    if subObjectLevelIsZero() then(
                                        firstClickPos = bSelectionPosOnToolStart
                                    )else(
                                        firstClickPos = getPivotPosition()
                                    )
                                )

                                -- Define selectionPositionsRelativeToFirstClickPointArray

                                    selectionPositionsRelativeToFirstClickPointArray = #()

                                    for a = 1 to bSelection.count do(
                                        append selectionPositionsRelativeToFirstClickPointArray [(selection[a].pos[1] - firstClickPos[1]), (selection[a].pos[2] - firstClickPos[2]), (selection[a].pos[3] - firstClickPos[3])]
                                    )
                            )

                        if stopTryingToStartBetterToolsStopToolOnMouseUnclickedTimer == false then(
                            if ((mouse.buttonStates as string) == "#{1}" or (mouse.buttonStates as string) == "#{1, 3}") and mousePos2D != mouse.pos then(
                                if bSelection1pos != bSelection[1].pos then( -- Sometimes the mouse has been moved and mouse unclicked, but Max hasn't registered that the mouse has been unclicked yet (or maybe there was a split-second of overlap between mouse being moved and still clicked). When this happens, though, the regular move tool still doesn't move the object, so we can use object's position to know whether to stop on unclick or not.
                                    stopTryingToStartBetterToolsStopToolOnMouseUnclickedTimer = true

                                    BetterToolsStopToolOnMouseUnclickedTimerStarted = true

                                    BetterToolsStopToolOnMouseUnclickedTimer.start()
                                )
                            )

                            if ((mouse.buttonStates as string) == "#{}" or (mouse.buttonStates as string) == "#{3}") and mousePos2D == mouse.pos then(
                                stopTryingToStartBetterToolsStopToolOnMouseUnclickedTimer = true
                            )
                        )

                        if BetterToolsStopToolOnMouseUnclickedTimerStarted == false or ((mouse.buttonStates as string) == "#{1}" or (mouse.buttonStates as string) == "#{1, 3}") then( -- Without this code, sometimes the timer doesn't stop the tool as soon as the mouse is unclicked, so the object keeps moving with the mouse
                            if firstMove == true and onMousePointFunctionWasRunOnStart == false then(
                                onMousePoint worldPoint bSelection cSelection betterMoveCurrentObject shiftKey clicknoGlobalVariable
                            )else(
                                worldPointFromHWND = worldPoint

                                selectionWireframeLayer.isHidden = false
                            )

                            currentMousePositionGlobalVariable = worldPoint

                            setSysCur #move

                            onMouseMoveFunction worldPoint bSelection cSelection betterMoveCurrentObject clicknoGlobalVariable

                            setSysCur #move

                            firstMove = false
                        )

                        displayDistanceRollout.matchDisplayDistanceToTotalDistanceMoved()

                        enterDistanceRollout.clearEnterDistance()
                    )

                    setSysCur #move
                ) -- (Undo end bracket)
            )

            on mousePoint clickno do(
                setSysCur #move

                clicknoGlobalVariable = clickno

                currentMousePositionGlobalVariable = worldPoint

                undo off(
                    onMousePoint currentMousePositionGlobalVariable bSelection cSelection betterMoveCurrentObject shiftKey clicknoGlobalVariable
                ) -- (Undo end bracket)
            )

            on stop do(
                if ignoreNextCallOfStopClause == false then(
                    -- Move the object to its original position with undo off, then back to the new position with undo on. This means if the user undoes, the object will have to go to its original position. Since undo is turned off during freeMove etc. to save performance when undoing, we need this step or else the object would stay at its new position.

                        -- When a drag has been performed, the stop clause runs twice for some reason (probably due to timers). May be worth putting all of the stop clause in this conditional, but for now I'm at least putting this in it as otherwise there is a definite problem—object(s) get moved to the wrong place.

                            -- Move the object back to its original position temporarily, with undo off

                                undo off(
                                    if subObjectLevelIsZero() then(
                                        for z = 1 to selectionPositionsRelativeToFirstClickPointArray.count do(
                                            bSelection[z].pos = [(firstClickPos[1] + selectionPositionsRelativeToFirstClickPointArray[z][1]), (firstClickPos[2] + selectionPositionsRelativeToFirstClickPointArray[z][2]), (firstClickPos[3] + selectionPositionsRelativeToFirstClickPointArray[z][3])] -- Since the pivot hasn't been moved back to its correct position relative to the object, the difference needs to be factored in
                                        )
                                    )else(
                                        try(
                                            -- Editable poly

                                                if (modPanel.getCurrentObject() as string) == "Editable Poly" or (modPanel.getCurrentObject() as string) == "Editable Mesh" then(
                                                    if subObjectLevel == 1 then(
                                                        move $.selectedVerts [- finalSubobjectPos[1], - finalSubobjectPos[2], - finalSubobjectPos[3]]
                                                    )

                                                    if subObjectLevel == 2 or subObjectLevel == 3 then(
                                                        move $.selectedEdges [- finalSubobjectPos[1], - finalSubobjectPos[2], - finalSubobjectPos[3]]
                                                    )

                                                    if subObjectLevel == 4 or subObjectLevel == 5 then(
                                                        move $.selectedFaces [- finalSubobjectPos[1], - finalSubobjectPos[2], - finalSubobjectPos[3]]
                                                    )
                                                )

                                            -- Edit poly

                                                if matchPattern (modPanel.getCurrentObject() as string) Pattern:"Edit_Poly:*" then(
                                                    EditPolyMod.MoveSelection $.modifiers[#Edit_Poly] [0, 0, 0]
                                                )
                                        )catch()
                                    )
                                ) -- (Undo end bracket)

                            -- Move the object to its final poition again, with undo on

                                undo on(
                                    if success == true then(
                                        if subObjectLevelIsZero() then(
                                            for z = 1 to selectionPositionsRelativeToFirstClickPointArray.count do(
                                                bSelection[z].pos = [(bPositionFinal[1] + selectionPositionsRelativeToFirstClickPointArray[z][1]), (bPositionFinal[2] + selectionPositionsRelativeToFirstClickPointArray[z][2]), (bPositionFinal[3] + selectionPositionsRelativeToFirstClickPointArray[z][3])] -- Since the pivot hasn't been moved back to its correct position relative to the object, the difference needs to be factored in
                                            )
                                        )else(
                                            try(
                                                -- Editable poly

                                                    if (modPanel.getCurrentObject() as string) == "Editable Poly" or (modPanel.getCurrentObject() as string) == "Editable Mesh" then(
                                                        if subObjectLevel == 1 then(
                                                            move $.selectedVerts finalSubobjectPos
                                                        )

                                                        if subObjectLevel == 2 or subObjectLevel == 3 then(
                                                            move $.selectedEdges finalSubobjectPos
                                                        )

                                                        if subObjectLevel == 4 or subObjectLevel == 5 then(
                                                            move $.selectedFaces finalSubobjectPos
                                                        )

                                                        -- Update lastFinalSubobjectPos variable. This variable is used to isolate what happens between each freeMove and the next, since with editable polys the move distance accumulates.

                                                            lastFinalSubobjectPos = finalSubobjectPos
                                                    )

                                                -- Edit poly

                                                    if matchPattern (modPanel.getCurrentObject() as string) Pattern:"Edit_Poly:*" then(
                                                        EditPolyMod.commit $.modifiers[#Edit_Poly]

                                                        EditPolyMod.MoveSelection $.modifiers[#Edit_Poly] finalSubobjectPos

                                                        EditPolyMod.commit $.modifiers[#Edit_Poly]
                                                    )
                                            )catch()
                                        )
                                    )
                                ) -- (Undo end bracket)

                    -- Everything else

                        undo off(
                            BetterToolsChangeCursorTimer.stop()

                            BetterToolsDetectShiftKeyStateTimer.stop()

                            -- Delete any selection wireframes

                                if selection.count < 100 then(
                                    for a = 1 to selection.count do(
                                        try(
                                            delete $betterMoveToolSelectionWireframe
                                        )catch()
                                    )
                                )

                            -- Callbacks

                                -- Rotating grids to viewport

                                    callBacks.RemoveScripts id:#rotateGridsToFaceCamera

                                -- Stop timers

                                    -- Ensure the create reference timer is off. Otherwise if the cursor was snapped to an object on stop, the timer would start again.

                                        BetterToolsCreateReferenceTimer.stop()

                                    -- Turn off set focus timer, as it will sti be on if a distance wasn't entered

                                        BetterToolsSetFocusTimer.stop()

                                    BetterToolsDetectWhenDistanceIsEnteredTimer.stop()

                            -- Rotate planes back to 0

                                -- X

                                    theMatrix = rotate (matrix3 1) (eulerangles 90.0 0.0 0.0 as quat)
                                    scale theMatrix $BetterToolsXGrid.scale
                                    translate theMatrix $BetterToolsXGrid.pos
                                    $BetterToolsXGrid.transform = theMatrix

                                -- Y

                                    theMatrix = rotate (matrix3 1) (eulerangles 0.0 90.0 0.0 as quat)
                                    scale theMatrix $BetterToolsYGrid.scale
                                    translate theMatrix $BetterToolsYGrid.pos
                                    $BetterToolsYGrid.transform = theMatrix

                                -- Z

                                    theMatrix = rotate (matrix3 1) (eulerangles 90.0 0.0 0.0 as quat)
                                    scale theMatrix $BetterToolsZGrid.scale
                                    translate theMatrix $BetterToolsZGrid.pos
                                    $BetterToolsZGrid.transform = theMatrix

                            -- Set object to show frozen in grey

                                if selection.count != 0 then(
                                    eSelection.showFrozenInGray = true
                                )

                            -- Unfreeze selection

                                try(
                                    unfreeze eSelection
                                )catch()

                            -- Reference Lines

                                referenceLineX.pos = [0,0,0]
                                referenceEndPointX.pos = [0,0,0]
                                referenceLineY.pos = [0,0,0]
                                referenceEndPointY.pos = [0,0,0]
                                referenceLineZ.pos = [0,0,0]
                                referenceEndPointZ.pos = [0,0,0]
                                referenceLineSecondary.pos = [0,0,0]
                                referenceEndPointSecondary.pos = [0,0,0]
                                referenceLineLocked.pos = [0,0,0]
                                referenceEndPointLocked.pos = [0,0,0]

                                hide referenceLineLocked
                                hide referenceLineSecondary
                                hide referenceLineX
                                hide referenceLineY
                                hide referenceLineZ

                            -- Toggle selection lock if relevant

                                if conditionToSetSelectAndMoveModeVariableToOnStop != selectAndMoveMode then(
                                    max spacebar
                                )

                            -- Deselect if conditionToSetSelectAndMoveModeVariableToOnStop is true

                                if currentMoveHasAlreadyBeenStopped == false then( -- Sometimes, such as when the tool is stopped by the timer that detects distance entered, the stop clause runs twice. Unsure if this does anything undesired, but want to be safe.
                                    if conditionToSetSelectAndMoveModeVariableToOnStop == true then(
                                        if selectionAutoLockPreference == true then(
                                            if subObjectLevelIsZero() then(
                                                deselect selection
                                            )else(
                                                -- Editable poly

                                                    if (modPanel.getCurrentObject() as string) == "Editable Poly" then(
                                                        if subObjectLevel == 1 then(
                                                            c.EditablePoly.SetSelection #Vertex #{}
                                                        )

                                                        if (subObjectLevel == 2 or subObjectLevel == 3) then(
                                                            c.EditablePoly.SetSelection #Edge #{}
                                                        )

                                                        if (subObjectLevel == 4 or subObjectLevel == 5) then(
                                                            c.EditablePoly.SetSelection #Face #{}
                                                        )
                                                    )

                                                -- Edit poly

                                                    if matchPattern (modPanel.getCurrentObject() as string) Pattern:"Edit_Poly:*" then(
                                                        if subObjectLevel == 1 then(
                                                            c.modifiers[#Edit_Poly] #Vertex #{}
                                                        )

                                                        if (subObjectLevel == 2 or subObjectLevel == 3) then(
                                                            c.modifiers[#Edit_Poly] #Edge #{}
                                                        )

                                                        if (subObjectLevel == 4 or subObjectLevel == 5) then(
                                                            c.modifiers[#Edit_Poly] #Face #{}
                                                        )
                                                    )

                                                -- Editable mesh

                                                    if (modPanel.getCurrentObject() as string) == "Editable Mesh" then(
                                                        if subObjectLevel == 1 then(
                                                            setVertSelection $ #{}
                                                        )

                                                        if (subObjectLevel == 2 or subObjectLevel == 3) then(
                                                            setEdgeSelection $ #{}
                                                        )

                                                        if (subObjectLevel == 4 or subObjectLevel == 5) then(
                                                            setFaceSelection $ #{}
                                                        )
                                                    )
                                            )
                                        )
                                    )
                                )

                            -- Variables

                                currentMoveHasAlreadyBeenStopped = true

                                if selectAndMoveMode != conditionToSetSelectAndMoveModeVariableToOnStop then(
                                    selectAndMoveMode = conditionToSetSelectAndMoveModeVariableToOnStop

                                    toggleSelectionLockAfterCurrentMove = true
                                )

                                moveToolActive = false

                                onMousePointFunctionWasRunOnStart = false

                            max move

                        ) -- (Undo end bracket)
                )else(
                    ignoreNextCallOfStopClause = false
                )
            )
        )

    -- Start tool

        -- Variables

            -- C++ guff

                fn getWindowClass = (
                    local source  = "using System;
                    "
                    source += "using System.Runtime.InteropServices;
                    "
                    source += "public class Window
                    "
                    source += "{
                    "
                    source += "	[DllImport(\"user32.dll\")]
                    "
                    source += "	public static extern IntPtr GetForegroundWindow();
                    "
                    source += "	[DllImport(\"user32.dll\")]
                    "
                    source += "	public static extern int SetForegroundWindow(int hwnd);
                    "
                    source += "}
                    "

                    local csharpProvider = dotNetObject "Microsoft.CSharp.CSharpCodeProvider"
                    local compilerParams = dotNetObject "System.CodeDom.Compiler.CompilerParameters"
                    compilerParams.GenerateInMemory = true
                    compilerParams.ReferencedAssemblies.Add "System.dll"
                    local compilerResults = csharpProvider.CompileAssemblyFromSource compilerParams #(source)
                    compilerResults.CompiledAssembly.CreateInstance "Window"
                )

                if NOT isKindOf ::window dotNetObject do window = getWindowClass()

        -- Functions

            -- Start move session

                fn startMoveSessionFunction = (
                    maxChildrenHWNDs = (windows.getChildrenHWND #max)

                    if toolmode.commandmode == #move and toolIsInactive == true then(
                        undo off(
                            try(
                                -- Update preference variables in case they were changed

                                    selectionAutoLockPreference = (if (getINISetting betterMoveIni "BetterMove" "Selection Auto-Lock") == "true" then true else false)

                                    objectReferencePreference = (if (getINISetting betterMoveIni "BetterMove" "Object Reference") == "true" then true else false)

                                    disableObjectReferenceWhenEdgeOrFaceSnapsAreEnabledPreference = (if (getINISetting betterMoveIni "BetterMove" "Disable Object Reference when edge or face snaps are enabled") == "true" then true else false)

                                -- Open preferences if shift key was presssed

                                    if modifierKeysObject.modifierKeys == modifierKeysObject.modifierKeys.shift then(
                                        try(
                                            destroyDialog preferencesRollout
                                        )catch()

                                        createDialog preferencesRollout height:200 width:300 style:#(#style_titlebar, #style_border, #style_sysmenu, #style_minimizebox, #style_maximizebox)
                                    )

                                -- Create BetterTools objects if they don't exist

                                    if $BetterToolsXGrid == undefined then(
                                        createBetterToolsObjectsFunction()
                                    )

                                -- Ensure reference lines are frozen

                                    freeze referenceLineLocked
                                    freeze referenceLineSecondary
                                    freeze referenceLineX
                                    freeze referenceLineY
                                    freeze referenceLineZ

                                BetterToolsStartToolWhenMouseIsClickedTimer.stop()

                                toolIsInactive = false

                                -- Add callback to change variable on undo or redo, so that selection changes caused by undoing or redoing don't cause the tool to start

                                    callBacks.RemoveScripts id:#once

                                    callBacks.addScript #sceneUndo "changeVariableOnUndoOrRedo()" id:#once

                                    callBacks.addScript #sceneRedo "changeVariableOnUndoOrRedo()" id:#once

                                units.DisplayType = #generic

                                -- Variables

                                    -- Define subObjectCountOnLastRun variable

                                        if not subObjectLevelIsZero() then(
                                            subObjectCountOnLastRun = getNumVerts $
                                        )else(
                                            subObjectCountOnLastRun = objects.count
                                        )

                                    -- Define selectionOnLastRound variable

                                        if subObjectLevelIsZero() then(
                                            selectionOnLastRound = (selection as array)
                                        )else(
                                            -- Editable poly

                                                if (modPanel.getCurrentObject() as string) == "Editable Poly" then(
                                                    if subObjectLevel == 1 then(
                                                        selectionOnLastRound = polyop.getVertSelection selection[1]
                                                    )

                                                    if subObjectLevel == 2 or subObjectLevel == 3 then(
                                                        selectionOnLastRound = polyop.getEdgeSelection selection[1]
                                                    )

                                                    if subObjectLevel == 4 or subObjectLevel == 5 then(
                                                        selectionOnLastRound = polyop.getFaceSelection selection[1]
                                                    )
                                                )

                                            -- Edit poly

                                                if matchPattern (modPanel.getCurrentObject() as string) Pattern:"Edit_Poly:*" then(
                                                    if subObjectLevel == 1 then(
                                                        selectionOnLastRound = (EditPolyMod.GetSelection $.Edit_Poly #Vertex) as string
                                                    )

                                                    if subObjectLevel == 2 or subObjectLevel == 3 then(
                                                        selectionOnLastRound = (EditPolyMod.GetSelection $.Edit_Poly #Edge) as string
                                                    )

                                                    if subObjectLevel == 4 or subObjectLevel == 5 then(
                                                        selectionOnLastRound = (EditPolyMod.GetSelection $.Edit_Poly #Face) as string
                                                    )
                                                )

                                            -- Editable mesh

                                                if (modPanel.getCurrentObject() as string) == "Editable Mesh" then(
                                                    if subObjectLevel == 1 then(
                                                        selectionOnLastRound = getVertSelection selection[1]
                                                    )

                                                    if subObjectLevel == 2 or subObjectLevel == 3 then(
                                                        selectionOnLastRound = getEdgeSelection selection[1]
                                                    )

                                                    if subObjectLevel == 4 or subObjectLevel == 5 then(
                                                        selectionOnLastRound = getFaceSelection selection[1]
                                                    )
                                                )
                                        )

                                    -- Define moveableSelectionExistedOnLastRun variable

                                        if somethingMoveableIsSelected() then(
                                            moveableSelectionExistedOnLastRun = true
                                        )else(
                                            moveableSelectionExistedOnLastRun = false
                                        )

                                    if (getINISetting maxINIFile "Performance" "showaxisicon") == "0" then(
                                        turnAxisIconBackOn = false
                                    )else(
                                        turnAxisIconBackOn = true
                                    )

                                    lastAxisConstraints = toolmode.axisconstraints

                                    if subObjectLevelIsZero() then(
                                        moveInSubobjectMode = false
                                    )else(
                                        moveInSubobjectMode = true
                                    )

                                    -- Variables to organise

                                        -- Toggling snap visibility

                                            originalGridSnapState = snapMode.getOSnapItemActive 4 1
                                            originalSnapDisplayState = snapMode.display

                                        shiftKeyStateBoolean = false

                                        shiftKeyStateOnLastFreeMoveBoolean = false

                                        originalDisplayUnits = units.DisplayType

                                        clicknoGlobalVariable = 0

                                    -- Original active grid

                                        originalActiveGrid = activeGrid

                                    axisReferenceLocked = false

                                    shiftKeyStateBoolean = false

                                    shiftKeyStateOnLastFreeMoveBoolean = false

                                    startMoving = false

                                    clicknoGlobalVariable = 0

                                    -- Distance editText

                                        -- Position Distance editText

                                            positionDistanceEditTextBoolean = false

                                        distanceEntered = undefined

                                    -- Rotating grids to viewport

                                        -- Declaring the variables as non-globals before the function called in the callback. For some reason if this isn't done, they come back as undefined when the function is called, despite having values assigned when declared as globals.

                                            lastPlaneRotationX = 0
                                            lastPlaneRotationY = 0
                                            lastPlaneRotationZ = 0

                                    -- Timers

                                        distanceEnteredSecondCallbackBoolean = false

                                    -- Reference

                                        -- Reference screen coordinates, base

                                            referenceScreenCoordinatesBaseArray = #(undefined, undefined, undefined, undefined, undefined)

                                        -- Reference curve

                                            referenceCurveXArray1 = #(undefined, undefined, undefined, undefined, undefined)
                                            referenceCurveXArray2 = #(undefined, undefined, undefined, undefined, undefined)

                                            referenceCurveYArray1 = #(undefined, undefined, undefined, undefined, undefined)
                                            referenceCurveYArray2 = #(undefined, undefined, undefined, undefined, undefined)

                                            referenceCurveZArray1 = #(undefined, undefined, undefined, undefined, undefined)
                                            referenceCurveZArray2 = #(undefined, undefined, undefined, undefined, undefined)

                                        -- World point on infer

                                            worldPointOnInferArray = #(undefined, undefined, undefined, undefined, undefined)

                                        lastCreatedReferenceNumber = 0
                                        totalNumberOfReferences = 0

                                        snapRadius = 10
                                        screenCoordinatesCompanionNumber = 1

                                        basePointTranslationsArray = #([0 ,0])

                                        for a = 1 to snapRadius do(
                                            append basePointTranslationsArray [a, a]

                                            append basePointTranslationsArray [a, -a]

                                            append basePointTranslationsArray [-a, a]

                                            append basePointTranslationsArray [-a, -a]
                                        )

                                        -- Last used reference

                                            lastUsedReference = "Z"

                                        -- Last reference number snapped to

                                            lastReferenceNumberSnappedToAny = 1

                                    -- Object variables

                                        currentModifier = undefined
                                        currentsubobjectLevel = 0

                                    -- Variables to organise

                                        selectionWireframeLayer = layerManager.getLayerFromName "BetterTools, Selection Wireframes"
                                        success = false
                                        lockToAxis = "none"
                                        worldPointOnAxisLock = [0,0,0]
                                        worldPointOnShiftCtrlAltClick = [0,0,0]
                                        firstMove = true

                                        betterMoveDistance = undefined

                                    -- Distance variables

                                        xObjectPosCurrent = 0
                                        yObjectPosCurrent = 0
                                        zObjectPosCurrent = 0

                                        totalDistanceMoved = 0

                                    -- Position variables

                                        currentMousePositionGlobalVariable = [0,0,0]
                                        finalSubobjectPos = [0,0,0]
                                        bPositionFinal = [0,0,0]

                                -- Ensure rollouts are closed

                                    -- Detect Subselection changes

                                        try(
                                            stopDetectingSubselectionChangesFunction()
                                        )catch()

                                -- Set the grid to default

                                    -- There would likely be issues if the grid is a custom grid, as worldPointFromHWND readings would reflect worldspace relative to the active grid rather than absolute worldspace. Haven't tested this, so may not be true, but if the issue exists then this code stops it.

                                    activeGrid = undefined

                                -- Get HWND information for detecting when tool session ends. The timer probably takes care of this so this may be unnecessary, but including this anyway for now to be sure.

                                    detectIfToolTipHWNDNumberChangesFunction()

                                BetterToolsDetectWhenMoveToolIsExitedTimer.start()

                                determineWhetherSubselectionExistsFunction()

                                BetterToolsDetermineWhetherToMoveInSubobjectModeTimer.start()

                                -- Hide axis if it is shown and there is no selection

                                    if not somethingMoveableIsSelected() then(
                                        if isCurrentModifierMoveable() then(
                                            if (getINISetting maxINIFile "Performance" "showaxisicon") == "1" then(
                                                turnAxisIconBackOn = true

                                                max showaxisicon
                                            )
                                        )
                                    )

                                if not somethingMoveableIsSelected() or selectionAutoLockPreference == false then(
                                    selectAndMoveMode = true

                                    if isCurrentModifierMoveable() then(
                                        -- Start timer to detect selection change

                                            BetterToolsDetectIfUndoOrRedoMadeNoChangeToSelectionSetTimer.start()

                                            testTimer.start()

                                            if not subObjectLevelIsZero() then(
                                                subObjectLevelBeforeModifierParameterChange = subObjectLevel
                                            )

                                        BetterToolsGetWorldPointFromHWNDsTimer.start()
                                    )
                                )else(
                                    selectAndMoveMode = false

                                    -- Ensure the selection changed callbacks are disabled, just in case

                                        testTimer.stop()

                                        try(
                                            stopDetectingSubselectionChangesFunction()
                                        )catch()

                                    -- Lock the selection if it isn't already

                                        if selLocked() then(
                                            turnSelectionLockBackOn = true
                                        )else(
                                            max spacebar
                                        )

                                    BetterToolsDeselectIfSelectionLockIsTurnedOffTimer.start()

                                    BetterToolsStartToolWhenMouseIsClickedTimer.start()
                                )
                            )catch(
                                BetterToolsStartMoveSessionTimer.stop()
                            )
                        ) -- (Undo end bracket)
                    )
                )

            -- Undo Function

                fn undoFunction = (
                    BetterToolsUndoTimer.stop()

                    callBacks.RemoveScripts id:#bye

                    max undo

                    callBacks.addScript #sceneUndo "undoTwiceIfRelevantFunction(callbacks.notificationParam())" id:#bye
                )

            -- Redo Function

                fn redoFunction = (
                    BetterToolsRedoTimer.stop()

                    callBacks.RemoveScripts id:#redo

                    max redo

                    callBacks.addScript #sceneRedo "redoTwiceIfRelevantFunction(callbacks.notificationParam())" id:#redo
                )

        -- Timers

            -- BetterToolsStartMoveSessionTimer

                global BetterToolsStartMoveSessionTimer = dotNetObject "System.Windows.Forms.Timer"
                dotnet.addEventHandler BetterToolsStartMoveSessionTimer "tick" startMoveSessionFunction
                BetterToolsStartMoveSessionTimer.interval = 100

            -- BetterToolsUndoTimer

                global BetterToolsUndoTimer = dotNetObject "System.Windows.Forms.Timer"
                dotnet.addEventHandler BetterToolsUndoTimer "tick" undoFunction
                BetterToolsUndoTimer.interval = 1

            -- BetterToolsUndoTimer

            global BetterToolsRedoTimer = dotNetObject "System.Windows.Forms.Timer"
            dotnet.addEventHandler BetterToolsRedoTimer "tick" redoFunction
            BetterToolsRedoTimer.interval = 1

        -- Callbacks

            -- Undo twice if relevant

                fn undoTwiceIfRelevantFunction text = (
                    -- Set the lastUndoWasMove variable based on whether the undo is a move, so the redo callback knows

                        if text == "Move   " or text == "Move  " then(
                            lastUndoWasMove = true
                        )else(
                            lastUndoWasMove = false
                        )

                    if text == "Move   " then(
                        -- Start the undo timer. For some reason just running 'max undo' here doesn't do anything, likely something to do with the fact that it's being called from within an undo callback (still don't seem logical though), so we use a timer instead.

                            BetterToolsUndoTimer.start()
                    )
                )

            -- Redo twice if relevant

                fn redoTwiceIfRelevantFunction text = (
                    if lastUndoWasMove == true and text != "Move   " and text != "Move  " then(
                        -- Start the redo timer. For some reason just running 'max redo' here doesn't do anything, likely something to do with the fact that it's being called from within an redo callback (still don't seem logical though), so we use a timer instead.

                            BetterToolsRedoTimer.start()
                    )
                )

            callBacks.RemoveScripts id:#bye

            callBacks.addScript #sceneUndo "undoTwiceIfRelevantFunction(callbacks.notificationParam())" id:#bye

            callBacks.RemoveScripts id:#redo

            callBacks.addScript #sceneRedo "redoTwiceIfRelevantFunction(callbacks.notificationParam())" id:#redo

        -- Start timers

            BetterToolsStartMoveSessionTimer.start()
)
