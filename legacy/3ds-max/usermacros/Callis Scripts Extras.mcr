
-- Global variables

    global callisScriptslastActiveMaterial
    global callisScriptsPerspectiveFocalLength
    global onNodeAddedEventHandlersOn = true

-- Toggle On Node Added Event Handlers

    MacroScript toggleOnNodeAddedEventHandlers category:"Callis Scripts Extras" tooltip:"Toggle On Node Added Event Handlers" Icon:#("Toggle On Node Added Event Handlers",1)

    (
        -- Variables

            include "$scripts/Startup/Callis Scripts/General Event Handling.ms"

        if onNodeAddedEventHandlersOn == false then(
            disableRelevantEventHandlersForCertainOperationsVariable.enableOnNodeAddedEventHandlers()

            onNodeAddedEventHandlersOn = true

            print "Event Handlers On"
        )else(
            disableRelevantEventHandlersForCertainOperationsVariable.disableOnNodeAddedEventHandlers()

            onNodeAddedEventHandlersOn = false

            print "Event Handlers Off"
        )
    )

-- Rename selected object

    MacroScript renameSelectedObject category:"Callis Scripts Extras" tooltip:"Rename Selected Object" Icon:#("Rename Selected Object",1)

    (
        -- Dialog

            rollout objectNameDialog ""(
                edittext prefix_txt "Object name:" fieldWidth:190 labelOnTop:false enabled:true

                on prefix_txt entered txt do(
                    if txt != "" do(
                        $.name = txt

                        destroyDialog objectNameDialog
                    )
                )
            )

            if selection.count == 1 then(
                createDialog objectNameDialog 300 50
            )
    )

-- Cycle Viewport Layouts

    MacroScript cycleViewportLayouts category:"Callis Scripts Extras" tooltip:"Cycle Viewport Layouts" Icon:#("Cycle Viewport Layouts",1)

    (
        -- Variables etc.

            include "$scripts/CallisScripts/scripts/All Scripts.ms"

        try(
            if getActiveFramesCamera() != undefined then(
                if viewport.getLayout () == #layout_2v then(
                    viewport.setLayout #layout_1

                    viewport.setCamera (getActiveFramesCamera())

                    displaySafeFrames = true

                    viewport.EnableSolidBackgroundColorMode false
                )else(
                    if viewport.getLayout () == #layout_1 then(
                        viewport.setLayout #layout_2h

                        viewport.activeViewport = 2

                        viewport.setCamera (getActiveFramesCamera())

                        displaySafeFrames = true

                        viewport.EnableSolidBackgroundColorMode false

                        viewport.activeViewport = 1

                        viewport.setType #view_persp_user

                        displaySafeFrames = false

                        viewport.EnableSolidBackgroundColorMode false
                    )else(
                        if viewport.getLayout () == #layout_2h then(
                            viewport.setLayout #layout_2v

                            viewport.activeViewport = 2

                            viewport.setCamera (getActiveFramesCamera())

                            displaySafeFrames = true

                            viewport.EnableSolidBackgroundColorMode false

                            viewport.activeViewport = 1

                            viewport.setType #view_persp_user

                            displaySafeFrames = false

                            viewport.EnableSolidBackgroundColorMode false
                        )
                    )
                )

                if viewport.getLayout () != #layout_1 and viewport.getLayout () != #layout_2h and viewport.getLayout () != #layout_2v do(
                    viewport.setLayout #layout_1

                    viewport.setCamera (getActiveFramesCamera())

                    displaySafeFrames = true

                    viewport.EnableSolidBackgroundColorMode false
                )

                redrawViews()
            )
        )catch()
    )

-- Toggle Camera/Perspective View

    MacroScript toggleCameraPerspectiveView category:"Callis Scripts Extras" tooltip:"Toggle Camera/Perspective View" Icon:#("Toggle Camera/Perspective View",1)

    (
        -- Variables

            include "$scripts/CallisScripts/scripts/All Scripts.ms"
            include "$scripts/Startup/Callis Scripts/General Event Handling.ms"
            oldLayer = LayerManager.current
            layer = layerManager.getLayerFromName "Temporary Script Objects"
            toggleCameraPerspectiveVieworiginalSelection = (selection as array)

        disableRelevantEventHandlersForCertainOperationsVariable.disableOnNodeAddedEventHandlers()

        deselect cameras

        if viewport.getType() == #view_persp_user then(
            try(
                if getActiveFramesCamera() != undefined then(
                    try(
                        callisScriptsPerspectiveFocalLength = viewport.GetFOV()
                    )catch()

                    try(
                        delete $CallisScriptsTemporaryPerspectiveCamera
                    )catch()

                    layer.current = true

                    macros.run "Lights and Cameras" "PhysicalCamera_CreateFromView"

                    activeCamera = getactivecamera()

                    viewport.setCamera (getActiveFramesCamera())

                    activeCamera.name = "CallisScriptsTemporaryPerspectiveCamera"

                    deselect $CallisScriptsTemporaryPerspectiveCamera

                    hide activeCamera

                    hide $CallisScriptsTemporaryPerspectiveCamera.Target

                    oldLayer.current = true

                    displaySafeFrames = true

                    viewport.EnableSolidBackgroundColorMode false
                )
            )catch()
        )else(
            try(
                try(
                    viewport.setCamera $CallisScriptsTemporaryPerspectiveCamera
                )catch(
                    max vpt persp user
                )

                redrawViews()

                displaySafeFrames = false

                viewport.EnableSolidBackgroundColorMode false

                actionMan.executeAction 0 "40182"  -- Views: Perspective User View

                try(
                    viewport.SetFOV callisScriptsPerspectiveFocalLength
                )catch()
            )catch()
        )

        disableRelevantEventHandlersForCertainOperationsVariable.enableOnNodeAddedEventHandlers()

        -- Reselect original selection

            for a in toggleCameraPerspectiveVieworiginalSelection do(
                selectMore a
            )

        -- Reset variables

            toggleCameraPerspectiveVieworiginalSelection = undefined

        redrawViews()
    )

--@ Copy

    macroScript copy Category:"Callis Scripts Extras, Hold" toolTip:"Copy"

    (
    		thecopypastedir = getdir #autoback
    		thecopypastefile = "\pastefile.max"
    		thecopypastestring = thecopypastedir + thecopypastefile

    		if $ != undefined do
    				saveNodes $ thecopypastestring
    )

--@ Paste

    macroScript paste Category:"Callis Scripts Extras" toolTip:"Paste"

    (
        -- Variables

            include "$scripts/Startup/Callis Scripts/General Event Handling.ms"
            local layer = layerManager.getLayerFromName "Temporary Script Objects"
            local wasViewPerspective = false

        disableRelevantEventHandlersForCertainOperationsVariable.disableOnNodeAddedEventHandlers()

        deselect selection

        -- Move tool

            tool moveAfterPaste(
                -- Variables

                    local b
                    local layer = layerManager.getLayerFromName "Temporary Script Objects"
                    local originalPosition
                    local success = false
                    local xDistance
                    local yDistance
                    local zDistance
                    local mainDistance
                    local bOriginalPos
                    local lockToAxis = "none"
                    local turnSnapBackOnAfterAltKeyReleased = false
                    local snapWasOnAtStart
                    local orthoSnap = true
                    local nonOrthoAxisLock
                    local worldPointOnAxisLock = [0,0,0]
                    local b

                on start do(
                    if selection.count > 0 then(
                        try(
                            b = $callisSCriptsCopyToolGroup
                        )catch(
                            b = $selection
                        )

                        if selection.count == 0 then(
                            #stop
                        )

                        if snapMode.active == true then(
                            snapWasOnAtStart = true
                        )else(
                            snapWasOnAtStart = false
                        )
                    )else(
                        #stop
                    )
                )

                on freeMove do(
                    b.pos = worldPoint

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

                on mousePoint clickno do(
                    success = true

                    #stop
                )

                on mouseAbort clickno do(
                    #stop
                )

                on stop do(
                    try(
                        if success != true and selection.count != 0 do(
                            delete $
                        )

                        if snapWasOnAtStart == true then(
                            snapMode.active = true
                        )

                        select b

                        max group ungroup

                        max select
                    )catch()
                )
            )

        -- Paste

            max modify mode

          	thecopypastedir = getdir #autoback
          	thecopypastefile = "\pastefile.max"
          	thecopypastestring = thecopypastedir + thecopypastefile

          	mergemaxfile (thecopypastedir + thecopypastefile) #select

                group selection name:"callisSCriptsCopyToolGroup"

                -- Move

                if selection.count > 0 then(
                    startTool moveAfterPaste
                )

        disableRelevantEventHandlersForCertainOperationsVariable.enableOnNodeAddedEventHandlers()
    )

--@ Paste in place

    macroScript pasteInPlace Category:"Callis Scripts Extras" toolTip:"Paste in Place"

    (
        max modify mode

      	thecopypastedir = getdir #autoback
      	thecopypastefile = "\pastefile.max"
      	thecopypastestring = thecopypastedir + thecopypastefile

      	mergemaxfile (thecopypastedir + thecopypastefile) #select

        max group ungroup
    )

-- Import

    macroScript import Category:"Callis Scripts Extras" toolTip:"Import"

    (
        -- Variables

            local listOfPerspectiveViewports = #()
            local wasViewPerspective = false
            local currentCamera

        -- Create camera to preserve view if persective

            for i = 1 to viewport.numViews do(
                viewport.activeViewport = i

                if viewport.getType() == #view_persp_user then(
                    macros.run "Lights and Cameras" "PhysicalCamera_CreateFromView"

                    currentCamera = try(getActiveCamera()) catch()
                    if currentCamera != undefined do select currentCamera

                    $.name = "Import Tool Temporary Camera" + i as string

                    hide $

                    actionMan.executeAction 0 "40248"  -- Views: Select Viewport Node Target

                    $.name = "Import Tool Temporary Camera " + i as string + ".Target"

                    hide $

                    append listOfPerspectiveViewports i

                    wasViewPerspective = true
                )
            )

            max select none

        -- Import

            actionMan.executeAction 0 "40010"  -- File: Import File

        --@ Remove temporary camera if it was created

            if wasViewPerspective == true then(
                for i in listOfPerspectiveViewports do(
                    viewport.activeViewport = listOfPerspectiveViewports[i]

                    currentCamera = try(getActiveCamera()) catch()
                    if currentCamera != undefined do select currentCamera

                    delete $
                )
            )

        max modify mode
    )

-- Collapse stack

    macroScript collapseStack Category:"Callis Scripts Extras" toolTip:"Collapse Stack"

    (
        max modify mode

        macros.run "Modifier Stack" "Collapse_Stack"

        modPanel.addModToSelection (Edit_Poly ()) ui:on
    )

-- Deselect

    macroScript deselect Category:"Callis Scripts Extras" toolTip:"Deselect"

    (
        subobjectLevel = 0

        deselect selection

        subobjectLevel = 0

        deselect selection

        max select
    )

-- Attach objects

    MacroScript attachObjects category:"Callis Scripts Extras" tooltip:"Attach Objects/Target Weld" Icon:#("Attach Objects/Target Weld",1)

  	(
        -- Variables

            include "$scripts/Startup/Callis Scripts/General Event Handling.ms"

        -- Functions

            (
                -- Globals

                global objectAttacher
                global objectAttacherDefaults
                global objectAttacherUI

                global aSOCloseOpenUI

                global aSOWarning
                global aSOAttachSelection
                global aSOPoly
                global aSOMesh
                global aSOSpline

                global aSODo
                global aSOApply
                global aSOHelp
                global aSOLoadDef
                global aSOSaveDef

                global aSODefineUI
                global aSORollout
                global aSOFloater

                -- Includes

                include "$scripts\SoulburnScripts\lib\sLib.ms"

                -- Variables

                aSOModeValue = 1
                aSOShowWarningValue = false
                aSOUndoOnValue = true
                aSOKeepOriginalsValue = false
                aSOCenterPivotValue = true
                aSOPivotPlacementValue = 1
                aSOPosValue = [400,400]

                -- Functions

                fn objectAttacher aSOMode aSOShowWarning aSOUndoOn aSOKeepOriginals aSOCenterPivot aSOPivotPlacement =
                  (
                  if aSOUndoOn == true then
                    (
                    undo "objectAttacher" on
                      (
                      aSOWarning aSOMode aSOShowWarning aSOKeepOriginals aSOCenterPivot aSOPivotPlacement
                      )
                    )
                  else aSOWarning aSOMode aSOShowWarning aSOKeepOriginals aSOCenterPivot aSOPivotPlacement
                  )

                fn objectAttacherDefaults =
                  (
                  aSOLoadDef()
                  objectAttacher aSOModeValue aSOShowWarningValue aSOUndoOnValue aSOKeepOriginalsValue aSOCenterPivotValue aSOPivotPlacementValue
                  )

                fn objectAttacherUI =
                  (
                  aSOLoadDef()
                  aSOCloseOpenUI aSOPosValue
                  )

                fn aSOCloseOpenUI pos =
                  (
                  if aSOFloater != undefined then CloseRolloutFloater aSOFloater
                  aSODefineUI()
                  aSOFloater = newRolloutFloater "objectAttacher v1.14" 187 201 pos.x pos.y
                  addRollout aSORollout aSOFloater
                  )

                fn aSOWarning aSOMode aSOShowWarning aSOKeepOriginals aSOCenterPivot aSOPivotPlacement =
                  (
                  if aSOShowWarning == true then
                    (
                    if (queryBox "Attach Selected Objects?" title:"objectAttacher") == true then aSOAttachSelection aSOMode aSOKeepOriginals aSOCenterPivot aSOPivotPlacement
                    )
                  else aSOAttachSelection aSOMode aSOKeepOriginals aSOCenterPivot aSOPivotPlacement
                  )

                fn aSOAttachSelection aSOMode aSOKeepOriginals aSOCenterPivot aSOPivotPlacement =
                  (
                  objs = for i in selection collect i
                  if objs.count < 2 then MessageBox "Please select 2 objects or more." title:"objectAttacher"
                  else
                    (
                    if aSOMode == 1 then aSOPoly objs aSOKeepOriginals aSOCenterPivot aSOPivotPlacement
                    else if aSOMode == 2 then aSOMesh objs aSOKeepOriginals aSOCenterPivot aSOPivotPlacement
                    else if aSOMode == 3 then aSOSpline objs aSOKeepOriginals aSOCenterPivot aSOPivotPlacement
                    else if aSOMode == 4 then
                      (
                      ispoly = true
                      ismesh = true
                      isspline = true
                      for o in objs do
                        (
                        if classof o != Editable_Poly then ispoly = false
                        if classof o != Editable_mesh then ismesh = false
                        if superclassof o != shape then isspline = false
                        )
                      if ispoly == true then aSOPoly objs aSOKeepOriginals aSOCenterPivot aSOPivotPlacement
                      else if ismesh == true then aSOMesh objs aSOKeepOriginals aSOCenterPivot aSOPivotPlacement
                      else if isspline == true then aSOSpline objs aSOKeepOriginals aSOCenterPivot aSOPivotPlacement
                      else MessageBox "Auto-detect only works if all selected objects are of the same type." title:"objectAttacher"
                      )
                    )
                  )

                fn aSOPoly objs keepOriginals centerPivot pivotPlacement =
                  (
                  allpoly = true
                  for o in objs do
                    (
                    if (canConvertTo o PolyMeshObject) == false then allpoly = false
                    )
                  if allpoly == false then
                    (
                    MessageBox "Not all of the selected objects can be converted to an EditablePoly. Please choose a different selection or run this script in a different mode." title:"objectAttacher"
                    )
                  else
                    (
                    disableSceneRedraw()
                    try
                      (
                      -- copy objects
                      oldObjs = #()
                      newObjs = #()
                      maxops.clonenodes objs cloneType:#copy actualNodeList:&oldObjs newNodes:&newObjs

                      -- Convert Objects
                      for o in newObjs do (if (classOf o != Editable_Poly) do (convertToPoly o))
                      InstanceMgr.MakeObjectsUnique newObjs #individual

                      -- Prep Progressbar
                      progressStart "objectAttacher"
                      escapeEnable = false
                      numOfItems = objs.count
                      currentIteration = 0

                      -- Start process
                      while (newObjs.count > 1) do
                        (
                        for i = newObjs.count to 2 by -2 do
                          (
                          if getProgressCancel() == true then exit
                          currentIteration += 1
                          m = ((currentIteration as float)/(numOfItems as float))*100
                          attachTo = newObjs[i]
                          attachTo.EditablePoly.attach newObjs[i-1] attachTo
                          deleteItem newObjs (i-1)
                          progressUpdate m
                          )
                        )
                      progressEnd()

                      -- Convert
                      convertTo newObjs[1] PolyMeshObject
                      if centerPivot == true then
                        (
                        if pivotPlacement == 1 then newObjs[1].pivot = [(newObjs[1].max.x+newObjs[1].min.x)/2, (newObjs[1].max.y+newObjs[1].min.y)/2, (newObjs[1].max.z+newObjs[1].min.z)/2]
                        else if pivotPlacement == 2 then newObjs[1].pivot = [(newObjs[1].max.x+newObjs[1].min.x)/2, (newObjs[1].max.y+newObjs[1].min.y)/2, newObjs[1].min.z]
                        else if pivotPlacement == 3 then newObjs[1].pivot = [0,0,0]
                        )
                      if keepOriginals == false then for i in oldObjs do delete i
                      select newObjs[1]
                      )
                    catch (MessageBox "An error has occured when trying to attach one of the objects. You may want to undo." title:"objectAttacher")
                    enableSceneRedraw()
                    completeRedraw()
                    )
                  )

                fn aSOMesh objs keepOriginals centerPivot pivotPlacement =
                  (
                  allmesh = true
                  for o in objs do
                    (
                    if (canConvertTo o TriMeshGeometry) == false then allmesh = false
                    )
                  if allmesh == false then
                    (
                    MessageBox "Not all of the selected objects can be converted to an EditableMesh. Please choose a different selection or run this script in a different mode." title:"objectAttacher"
                    )
                  else
                    (
                    disableSceneRedraw()
                    try
                      (
                      -- copy objects
                      oldObjs = #()
                      newObjs = #()
                      maxops.clonenodes objs cloneType:#copy actualNodeList:&oldObjs newNodes:&newObjs

                      -- Convert Objects
                      for o in newObjs do (if (classOf o != Editable_mesh) do (convertToMesh o))
                      InstanceMgr.MakeObjectsUnique newObjs #individual

                      -- Prep Progressbar
                      progressStart "objectAttacher"
                      escapeEnable = false
                      numOfItems = objs.count
                      currentIteration = 0

                      -- Start process
                      while (newObjs.count > 1) do
                        (
                        for i = newObjs.count to 2 by -2 do
                          (
                          if getProgressCancel() == true then exit
                          currentIteration += 1
                          m = ((currentIteration as float)/(numOfItems as float))*100
                          attachTo = newObjs[i]
                          attach attachTo newObjs[i-1]
                          deleteItem newObjs (i-1)
                          progressUpdate m
                          )
                        )
                      progressEnd()

                      -- Convert
                      convertTo newObjs[1] TriMeshGeometry
                      if centerPivot == true then
                        (
                        if pivotPlacement == 1 then newObjs[1].pivot = [(newObjs[1].max.x+newObjs[1].min.x)/2, (newObjs[1].max.y+newObjs[1].min.y)/2, (newObjs[1].max.z+newObjs[1].min.z)/2]
                        else if pivotPlacement == 2 then newObjs[1].pivot = [(newObjs[1].max.x+newObjs[1].min.x)/2, (newObjs[1].max.y+newObjs[1].min.y)/2, newObjs[1].min.z]
                        else if pivotPlacement == 3 then newObjs[1].pivot = [0,0,0]
                        )
                      if keepOriginals == false then for i in oldObjs do delete i
                      select newObjs[1]
                      )
                    catch (MessageBox "An error has occured when trying to attach one of the objects. You may want to undo." title:"objectAttacher")
                    enableSceneRedraw()
                    completeRedraw()
                    )
                  )

                fn aSOSpline objs keepOriginals centerPivot pivotPlacement =
                  (
                  allspline = true
                  for o in objs do
                    (
                    if (canConvertTo o SplineShape) == false then allspline = false
                    )
                  if allspline == false then
                    (
                    MessageBox "Not all of the selected objects are splines. Please choose a different selection or run this script in a different mode." title:"objectAttacher"
                    )
                  else
                    (
                    disableSceneRedraw()
                    try
                      (
                      -- copy objects
                      oldObjs = #()
                      newObjs = #()
                      maxops.clonenodes objs cloneType:#copy actualNodeList:&oldObjs newNodes:&newObjs
                      firstObj = newObjs[1]

                      -- Convert First Object
                      convertTo firstObj SplineShape

                      -- Prep Progressbar
                      progressStart "objectAttacher"
                      escapeEnable = false
                      numOfItems = newObjs.count
                      currentIteration = 0

                      -- Start process
                      for i = 2 to numOfItems do
                        (
                        if getProgressCancel() == true then exit
                        convertTo newObjs[i] SplineShape
                        currentIteration += 1
                        m = ((currentIteration as float)/(numOfItems as float))*100
                        addandweld firstObj newObjs[i] -1
                        progressUpdate m
                        )
                      progressEnd()

                      -- Convert
                      if centerPivot == true then
                        (
                        if pivotPlacement == 1 then newObjs[1].pivot = [(newObjs[1].max.x+newObjs[1].min.x)/2, (newObjs[1].max.y+newObjs[1].min.y)/2, (newObjs[1].max.z+newObjs[1].min.z)/2]
                        else if pivotPlacement == 2 then newObjs[1].pivot = [(newObjs[1].max.x+newObjs[1].min.x)/2, (newObjs[1].max.y+newObjs[1].min.y)/2, newObjs[1].min.z]
                        else if pivotPlacement == 3 then newObjs[1].pivot = [0,0,0]
                        )
                      if keepOriginals == false then for i in oldObjs do delete i
                      select newObjs[1]
                      )
                    catch (MessageBox "An error has occured when trying to attach one of the objects. You may want to undo." title:"objectAttacher")
                    enableSceneRedraw()
                    completeRedraw()
                    )
                  )

                fn aSODo =
                  (
                  objectAttacher aSOModeValue aSOShowWarningValue aSOUndoOnValue aSOKeepOriginalsValue aSOCenterPivotValue aSOPivotPlacementValue
                  if aSOFloater != undefined then CloseRolloutFloater aSOFloater
                  )

                fn aSOApply =
                  (
                  objectAttacher aSOModeValue aSOShowWarningValue aSOUndoOnValue aSOKeepOriginalsValue aSOCenterPivotValue aSOPivotPlacementValue
                  )

                fn aSOHelp =
                  (
                  sLibSSPrintHelp "objectAttacher"
                  )

                fn aSOLoadDef =
                  (
                  presetDir = ((getdir #plugcfg) + "\\SoulburnScripts\\presets\\")
                  aSOInputFilename = presetDir + "objectAttacher.ini"
                  if (sLibFileExist aSOInputFilename == true) then
                    (
                    aSOModeValue = execute (getINISetting aSOInputFilename "objectAttacher" "aSOModeValue")
                    aSOShowWarningValue = execute (getINISetting aSOInputFilename "objectAttacher" "aSOShowWarningValue")
                    aSOUndoOnValue = execute (getINISetting aSOInputFilename "objectAttacher" "aSOUndoOnValue")
                    aSOKeepOriginalsValue = execute (getINISetting aSOInputFilename "objectAttacher" "aSOKeepOriginalsValue")
                    aSOCenterPivotValue = execute (getINISetting aSOInputFilename "objectAttacher" "aSOCenterPivotValue")
                    aSOPivotPlacementValue = execute (getINISetting aSOInputFilename "objectAttacher" "aSOPivotPlacementValue")
                    aSOPosValue = execute (getINISetting aSOInputFilename "objectAttacher" "aSOPosValue")

                    if aSOModeValue == OK then aSOModeValue = 1
                    if aSOShowWarningValue == OK then aSOShowWarningValue = false
                    if aSOUndoOnValue == OK then aSOUndoOnValue = true
                    if aSOKeepOriginalsValue == OK then aSOKeepOriginalsValue = false
                    if aSOCenterPivotValue == OK then aSOCenterPivotValue = true
                    if aSOPivotPlacementValue == OK then aSOPivotPlacementValue = 1
                    if aSOPosValue == OK then aSOPosValue = [400,400]
                    )
                  else
                    (
                    aSOModeValue = 1
                    aSOShowWarningValue = false
                    aSOUndoOnValue = true
                    aSOKeepOriginalsValue = false
                    aSOCenterPivotValue = true
                    aSOPivotPlacementValue = 1
                    aSOPosValue = [400,400]
                    )
                  )

                fn aSOSaveDef =
                  (
                  presetDir = ((getdir #plugcfg) + "\\SoulburnScripts\\presets\\")
                  if (getDirectories presetDir).count == 0 then makeDir presetDir
                  aSOOutputFilename = presetDir + "objectAttacher.ini"
                  if (sLibFileExist aSOOutputFilename == true) then deleteFile aSOOutputFilename
                  setINISetting aSOOutputFilename "objectAttacher" "aSOModeValue" (aSOModeValue as string)
                  setINISetting aSOOutputFilename "objectAttacher" "aSOShowWarningValue" (aSOShowWarningValue as string)
                  setINISetting aSOOutputFilename "objectAttacher" "aSOUndoOnValue" (aSOUndoOnValue as string)
                  setINISetting aSOOutputFilename "objectAttacher" "aSOKeepOriginalsValue" (aSOKeepOriginalsValue as string)
                  setINISetting aSOOutputFilename "objectAttacher" "aSOCenterPivotValue" (aSOCenterPivotValue as string)
                  setINISetting aSOOutputFilename "objectAttacher" "aSOPivotPlacementValue" (aSOPivotPlacementValue as string)
                  setINISetting aSOOutputFilename "objectAttacher" "aSOPosValue" (aSOFloater.pos as string)
                  )

                fn aSODefineUI =
                  (
                  rollout aSORollout "objectAttacher"
                    (
                    label label1 "Mode:" pos:[10,10]
                    dropdownlist aSOModeDropdown "" items:#("Poly", "Mesh", "Spline", "Auto-detect") selection:aSOModeValue pos:[47,7] width:112
                    on aSOModeDropdown selected i do aSOModeValue = i

                    checkbox aSOShowWarningCheckbox "Show Warning?" checked:aSOShowWarningValue align:#left
                    checkbox aSOUndoOnCheckbox "Undo On?" checked:aSOUndoOnValue align:#left
                    checkbox aSOKeepOriginalsCheckbox "Keep Original Objects?" checked:aSOKeepOriginalsValue align:#left

                    on aSOShowWarningCheckbox changed state do aSOShowWarningValue = state
                    on aSOUndoOnCheckbox changed state do aSOUndoOnValue = state
                    on aSOKeepOriginalsCheckbox changed state do aSOKeepOriginalsValue = state

                    checkbox aSOCenterPivotCheckbox "Align Pivot?" checked:aSOCenterPivotValue align:#left across:2
                    dropdownlist aSOPivotPlacementDropdown "" items:#("Center", "Bottom Center", "Origin") selection:aSOPivotPlacementValue width:70 align:#right offset:[0,-2]

                    on aSOCenterPivotCheckbox changed state do aSOCenterPivotValue = state
                    on aSOPivotPlacementDropdown selected i do aSOPivotPlacementValue = i

                    button aSODoButton "Do" width:70 toolTip:"Do It and Close UI" pos:[15,118]
                    on aSODoButton pressed do aSODo()
                    button aSOApplyButton "Apply" width:70 toolTip:"Do It and Keep UI Open" pos:[87,118]
                    on aSOApplyButton pressed do aSOApply()
                    button aSOHelpButton "Help" width:70 toolTip:"Help" pos:[15,142]
                    on aSOHelpButton pressed do aSOHelp()
                    button aSOSaveDefButton "SaveDef" width:70 toolTip:"Save Current Settings as Default" pos:[87,142]
                    on aSOSaveDefButton pressed do aSOSaveDef()
                    )
                  )
            )

      	on execute do(
            if subobjectLevel == 0 then(
                disableRelevantEventHandlersForCertainOperationsVariable.disableOnNodeAddedEventHandlers()

                objectAttacherDefaults()

                disableRelevantEventHandlersForCertainOperationsVariable.enableOnNodeAddedEventHandlers()
            )else(
                try(
                    macros.run "Editable Polygon Object" "EPoly_TargetWeld"
                )catch()
            )
        )
  	)

-- Undo

    MacroScript callisScriptsUndo category:"Callis Scripts Extras" tooltip:"Undo" Icon:#("Undo",1)

  	(
        -- Variables

            include "$scripts/Startup/Callis Scripts/General Event Handling.ms"

      	on execute do(
            disableRelevantEventHandlersForCertainOperationsVariable.disableOnNodeAddedEventHandlers()

            max undo

            disableRelevantEventHandlersForCertainOperationsVariable.enableOnNodeAddedEventHandlers()
        )
  	)

-- Select active frame's camera

    MacroScript selectActiveFramesCamera category:"Callis Scripts Extras" tooltip:"Select active frame's camera" Icon:#("Select active frame's camera",1)

  	(
      	on execute do(
            try(
                -- Get frame number

                    currentFrameNumberPreliminary = sliderTime as string

                    currentFrameNumberAsStringPreliminary = filterString currentFrameNumberPreliminary "f" splitEmptyTokens:false

                    currentFrameNumberAsString = currentFrameNumberAsStringPreliminary[1]

                    frameNumber = currentFrameNumberAsString as integer

                camerasLayer = (layermanager.getLayerFromName "Cameras")

                camerasLayer.nodes &camerasLayerNodes

                for i = 1 to camerasLayerNodes.count do(

                    if matchPattern (camerasLayerNodes[i].name) pattern:"All *" == true and superClassOf camerasLayerNodes[i] == camera then(
                        select camerasLayerNodes[i]
                    )else(
                        cameraNumber = filterString camerasLayerNodes[i].name " "

                        for b = 1 to cameraNumber.count do(
                            if (substituteString cameraNumber[b] "," "") == (frameNumber as string) and superClassOf camerasLayerNodes[i] == camera then(
                                select camerasLayerNodes[i]
                            )
                        )
                    )
                )

                max modify mode

                activeFramesCamera
            )catch()
        )
  	)

-- Select active frame's sun

    MacroScript selectActiveFramesSun category:"Callis Scripts Extras" tooltip:"Select active frame's sun" Icon:#("Select active frame's sun",1)

  	(
      	on execute do(
            try(
                -- Get frame number

                    currentFrameNumberPreliminary = sliderTime as string

                    currentFrameNumberAsStringPreliminary = filterString currentFrameNumberPreliminary "f" splitEmptyTokens:false

                    currentFrameNumberAsString = currentFrameNumberAsStringPreliminary[1]

                    frameNumber = currentFrameNumberAsString as integer

                sunLayer = (layermanager.getLayerFromName "Sun")

                sunLayer.nodes &sunLayerNodes

                for i = 1 to sunLayerNodes.count do(

                    if matchPattern (sunLayerNodes[i].name) pattern:"All *" == true and superClassOf sunLayerNodes[i] == light then(
                        select sunLayerNodes[i]
                    )else(
                        sunNumber = filterString sunLayerNodes[i].name " "

                        for b = 1 to sunNumber.count do(
                            if (substituteString sunNumber[b] "," "") == (frameNumber as string) and superClassOf sunLayerNodes[i] == light then(
                                select sunLayerNodes[i]
                            )
                        )
                    )
                )

                max modify mode

                activeFramesCamera
            )catch()
        )
  	)

-- Select active frame's sky

    MacroScript selectActiveFramesSky category:"Callis Scripts Extras" tooltip:"Select active frame's sky" Icon:#("Select active frame's sky",1)

  	(
      	on execute do(
            try(
                -- Get frame number

                    currentFrameNumberPreliminary = sliderTime as string

                    currentFrameNumberAsStringPreliminary = filterString currentFrameNumberPreliminary "f" splitEmptyTokens:false

                    currentFrameNumberAsString = currentFrameNumberAsStringPreliminary[1]

                    frameNumber = currentFrameNumberAsString as integer

                skyLayer = (layermanager.getLayerFromName "Sky")

                skyLayer.nodes &skyLayerNodes

                for i = 1 to skyLayerNodes.count do(

                    if matchPattern (skyLayerNodes[i].name) pattern:"All *" == true and superClassOf skyLayerNodes[i] == light then(
                        select skyLayerNodes[i]
                    )else(
                        skyNumber = filterString skyLayerNodes[i].name " "

                        for b = 1 to skyNumber.count do(
                            if (substituteString skyNumber[b] "," "") == (frameNumber as string) and superClassOf skyLayerNodes[i] == light then(
                                select skyLayerNodes[i]
                            )
                        )
                    )
                )

                max modify mode

                activeFramesCamera
            )catch()
        )
  	)

-- Select Similar

    MacroScript callisScriptsSelectSimilar category:"Callis Scripts Extras" tooltip:"Select Similar" Icon:#("Select Similar",1)

  	(
      	on execute do(
            if subobjectLevel == 0 then(
                actionMan.executeAction 0 "40099"  -- Selection: Select Similar
            )else(
                macros.run "PolyTools" "Similar"
            )
        )
  	)

-- Show end result toggle

    MacroScript toggleShowEndResult category:"Callis Scripts Extras" tooltip:"Toggle Show End Result" Icon:#("Toggle Show End Result",1)

  	(
      	on execute do(
            macros.run "Ribbon - Modeling" "ShowEndResultToggle"
        )
  	)

-- Swift Loop

    MacroScript swiftLoop category:"Callis Scripts Extras" tooltip:"Swift Loop" Icon:#("Swift Loop",1)

    (
        on execute do(
            try(
                macros.run "PolyTools" "SwiftLoop"
            )catch()
        )
    )

-- Add Material To Selection

    MacroScript addMaterialToSelection category:"Callis Scripts Extras" tooltip:"Add Material To Selection" Icon:#("Add Material To Selection",1)

    (
        on execute do(
            function SMEGetSelMats = (
                viewNode = sme.GetView (sme.activeView)
                smeSelMats = #()
                for n = 1 to trackViewNodes[#sme][(sme.activeView)].numSubs do(
                  m = trackViewNodes[#sme][(sme.activeView)][n].reference
                  b = viewNode.GetNodeByRef m
                  if b.selected do append smeSelMats m
                )

                if smeSelMats.count > 0 then(
                   return smeSelMats[1]
                )
            )

            try(
                if SMEGetSelMats() != undefined then(
                    try(
                        $.material = SMEGetSelMats()
                    )catch()

                    callisScriptslastActiveMaterial = SMEGetSelMats()
                )else(
                    if callisScriptslastActiveMaterial != undefined then(
                        $.material = callisScriptslastActiveMaterial
                    )
                )
            )catch()
        )
    )

-- Pick Material From Selection

    -- Issues:

        -- Doesn't unconditionally pick closest object to camera

    MacroScript pickMaterialFromSelection category:"Callis Scripts Extras" tooltip:"Pick Material From Selection" Icon:#("Pick Material From Selection",1)

    (
        tool pickMaterialFromSelectionTool(
            on start do(
            )

            on mousePoint clickno do(
                try(
                    if snapMode.node != undefined then(
                        objectsUnderCursor = #(snapMode.node)

                        -- objectsUnderCursor = (boxPickNode (box2 (mouse.pos - [2,2]) (mouse.pos + [2,2])) crossing:true)

                        callisScriptslastActiveMaterial = objectsUnderCursor[1].material

                        if (sme.ActiveView) == 0 then(
                            MatEditor.Open()
                            MatEditor.Close()
                        )

                        (sme.getView (sme.ActiveView)).createNode objectsUnderCursor[1].material [0,0]

                        (sme.getView (sme.ActiveView)).SetSelectedNodes objectsUnderCursor[1].material
                    )
                )catch()

                #stop
            )

            on mouseAbort clickno do(
            )

            on stop do(
            )
        )

        on execute do(
            startTool pickMaterialFromSelectionTool
        )
    )

-- Boolean difference

        MacroScript booleanDifference category:"Callis Scripts Extras" tooltip:"Boolean difference" Icon:#("Boolean difference",1)

        (
            -- Variables

                include "$scripts/Startup/Callis Scripts/General Event Handling.ms"

            tool booleanDifference(
                -- Variables

                    local initialObject
                    local operandObjects = #()
                    local objectsUnderCursor
                    local operandObjectsToRemove

                on start do(
                    if selection.count > 1 then(
                        messageBox "Please select only one base object"

                        #stop
                    )

                    initialObject = $
                )

                on mousePoint clickno do(
                    if not ctrlKey and not shiftKey and not altKey then(
                        try(
                            objectsUnderCursor = (boxPickNode (box2 (mouse.pos - [2,2]) (mouse.pos + [2,2])) crossing:true)

                            if objectsUnderCursor[1] != initialObject then(
                                select initialObject

                                selectMore objectsUnderCursor[1]

                                operandObjects = #(objectsUnderCursor[1])
                            )
                        )catch(
                            select initialObject

                            operandObjects = #()
                        )
                    )

                    if ctrlKey and not shiftKey and not altKey then(
                        try(
                            objectsUnderCursor = (boxPickNode (box2 (mouse.pos - [2,2]) (mouse.pos + [2,2])) crossing:true)

                            if objectsUnderCursor[1] != initialObject then(
                                selectMore objectsUnderCursor[1]

                                appendIfUnique operandObjects objectsUnderCursor[1]
                            )
                        )catch()
                    )

                    if not ctrlKey and not shiftKey and altKey then(
                        try(
                            objectsUnderCursor = (boxPickNode (box2 (mouse.pos - [2,2]) (mouse.pos + [2,2])) crossing:true)

                            if objectsUnderCursor[1] != initialObject then(
                                deselect objectsUnderCursor[1]

                                operandObjectsToRemove = findItem operandObjects objectsUnderCursor[1]

                                deleteItem operandObjects operandObjectsToRemove
                            )
                        )catch()
                    )

                    if shiftKey then(
                        sleep .8

                        convertTo initialObject Editable_Poly

                        for o in operandObjects do(
                            convertTo o Editable_Poly
                        )

                        if ctrlKey then(
                            ProBoolean.CreateBooleanObjects initialObject operandObjects 2 1 1
                        )else(
                            ProBoolean.CreateBooleanObjects initialObject operandObjects 2 2 1
                        )

                        convertTo initialObject Editable_Poly

                        addModifier initialObject (Edit_Poly ())

                        #stop
                    )
                )

                on mouseAbort clickno do(
                )
            )

            disableRelevantEventHandlersForCertainOperationsVariable.disableOnNodeAddedEventHandlers()

            startTool booleanDifference

            disableRelevantEventHandlersForCertainOperationsVariable.enableOnNodeAddedEventHandlers()
        )

-- Move Pivot To Bottom/Detach

    MacroScript movePivotToBottomDetach category:"Callis Scripts Extras" tooltip:"Move Pivot To Bottom/Detach" Icon:#("Move Pivot To Bottom/Detach",1)

    (
        -- Variables

            include "$scripts/CallisScripts/scripts/All Scripts.ms"

        -- Run the script

            try(
                if subobjectLevel == 0 or selection == undefined then(
                    --pivotPlacer 15 1 true 1
                )else(
                    $.modifiers[#Edit_Poly].DetachToObject "Object"
                )
            )catch()
    )

-- Move cameras, lights etc. into correct locations

        MacroScript moveCamerasLightsEtcIntoCorrectLocations category:"Callis Scripts Extras" tooltip:"Move cameras, lights etc. into correct locations" Icon:#("Move cameras, lights etc. into correct locations",1)

        (
            -- Variables etc.

                include "$scripts/CallisScripts/scripts/All Scripts.ms"

            try(
                moveCamerasLightsEtcIntoCorrectLocations()
            )catch()
        )

-- Zoom selected

    MacroScript zoomSelected category:"Callis Scripts Extras" tooltip:"Zoom Selected" Icon:#("Zoom Selected",1)

    (
        -- Variables etc.

        -- Run the script

            if viewport.getLayout () == #layout_2v or viewport.getLayout () == #layout_2h then(
                if viewport.getType() == #view_persp_user then(
                    max zoomext sel
                )else(
                    if viewport.activeViewport == 1 then(
                        viewport.activeViewport = 2
                    )else(
                        viewport.activeViewport = 1
                    )

                    max zoomext sel
                )
            )else(
                if viewport.getType() == #view_camera then(
                    macros.run "Callis Scripts Extras" "toggleCameraPerspectiveView"

                    max zoomext sel
                )else(
                    max zoomext sel
                )
            )
    )

-- Add UVW Map To Selection

    MacroScript addUVWMapToSelection category:"Callis Scripts Extras" tooltip:"Add UVW Map To Selection" Icon:#("Add UVW Map To Selection",1)

    (
        -- Variables etc.

        -- Run the script

            for a in selection do(
                macros.run "Modifiers" "Uvwmap"

                a.modifiers[#UVW_Map].maptype = 4
            )
    )

-- Enter subobject modes

    -- Level 1

        MacroScript enterSubobjectLevel1 category:"Callis Scripts Extras" tooltip:"Enter Subobject Level 1" Icon:#("Enter Subobject Level 1",1)

        (
            if selection.count == 1 then(
                max modify mode

                -- Select correct modifier

                    while modPanel.getCurrentObject() != $.modifiers[#Edit_Poly] and modPanel.getCurrentObject() != $.modifiers[#Edit_Mesh] and modPanel.getCurrentObject() != $.modifiers[#Poly_Select] and modPanel.getCurrentObject() != $.baseObject do
                    			(
                    				max prev mod
                    			)

                subobjectLevel = 1
            )
        )

    -- Level 2

        MacroScript enterSubobjectLevel2 category:"Callis Scripts Extras" tooltip:"Enter Subobject Level 2" Icon:#("Enter Subobject Level 2",1)

        (
            max modify mode

            if selection.count == 1 then(
                -- Select correct modifier

                    while modPanel.getCurrentObject() != $.modifiers[#Edit_Poly] and modPanel.getCurrentObject() != $.modifiers[#Edit_Mesh] and modPanel.getCurrentObject() != $.modifiers[#Poly_Select] and modPanel.getCurrentObject() != $.baseObject do
                    			(
                    				max prev mod
                    			)

                subobjectLevel = 2
            )
        )

    -- Level 3

        MacroScript enterSubobjectLevel3 category:"Callis Scripts Extras" tooltip:"Enter Subobject Level 3" Icon:#("Enter Subobject Level 3",1)

        (
            if selection.count == 1 then(
                max modify mode

                -- Select correct modifier

                    while modPanel.getCurrentObject() != $.modifiers[#Edit_Poly] and modPanel.getCurrentObject() != $.modifiers[#Edit_Mesh] and modPanel.getCurrentObject() != $.modifiers[#Poly_Select] and modPanel.getCurrentObject() != $.baseObject do
                    			(
                    				max prev mod
                    			)

                subobjectLevel = 3
            )
        )

    -- Level 4

        MacroScript enterSubobjectLevel4 category:"Callis Scripts Extras" tooltip:"Enter Subobject Level 4" Icon:#("Enter Subobject Level 4",1)

        (
            if selection.count == 1 then(
                max modify mode

                -- Select correct modifier

                    while modPanel.getCurrentObject() != $.modifiers[#Edit_Poly] and modPanel.getCurrentObject() != $.modifiers[#Edit_Mesh] and modPanel.getCurrentObject() != $.modifiers[#Poly_Select] and modPanel.getCurrentObject() != $.baseObject do
                    			(
                    				max prev mod
                    			)

                subobjectLevel = 4
            )
        )

    -- Level 5

        MacroScript enterSubobjectLevel5 category:"Callis Scripts Extras" tooltip:"Enter Subobject Level 5" Icon:#("Enter Subobject Level 5",1)

        (
            if selection.count == 1 then(
                max modify mode

                -- Select correct modifier

                    while modPanel.getCurrentObject() != $.modifiers[#Edit_Poly] and modPanel.getCurrentObject() != $.modifiers[#Edit_Mesh] and modPanel.getCurrentObject() != $.modifiers[#Poly_Select] and modPanel.getCurrentObject() != $.baseObject do
                    			(
                    				max prev mod
                    			)

                subobjectLevel = 5
            )
        )

    -- Level 0

        MacroScript enterSubobjectLevel0 category:"Callis Scripts Extras" tooltip:"Enter Subobject Level 0" Icon:#("Enter Subobject Level 0",1)

        (
            subobjectLevel = 0

            max create mode
        )

-- Set project folder

    MacroScript callisScriptsSetProjectFolder category:"Callis Scripts Extras" tooltip:"Set Project Folder" Icon:#("Set Project Folder",1)

    (
        include "$scripts/CallisScripts/scripts/All Scripts.ms"

        on execute do setProjectFolderFunction()
    )

-- Set metadata

    MacroScript callisScriptsSetMetadata category:"Callis Scripts Extras" tooltip:"Set Metadata" Icon:#("Set Metadata",1)

    (
        include "$scripts/CallisScripts/scripts/All Scripts.ms"

        on execute do SetMetadataFunction()
    )

-- Collect assets

    MacroScript callisScriptsCollectAssets category:"Callis Scripts Extras" tooltip:"Collect Assets To Project Folder" Icon:#("Collect Assets To Project Folder",1)

    (
        try(
            destroyDialog patheditor
        )catch()

        rollout patheditor "patheditor" width:0 height:0(
            -- Variables

                local map_list = #()
                local mat_array = #()
                local full_list = #()
                local environ_tmp_list = #()

                local newPathText

                local index = 0
                local w = #(300, 140, 60, 60, 80)

            -- Components

                dotNetControl lv "System.Windows.Forms.ListView" width:657 height:200 pos:[5,5]

            -- Functions

                fn fill_mat_array = (
                    materials=#()
                    for obj in geometry do
                      (
                      a= (finditem materials obj.mat)
                      if a==0 then
                        (
                        append materials obj.mat
                        append mat_array #(obj.mat, #(obj))
                        )else(
                        append mat_array[a][2] obj
                        )
                      )

                    for mat = 1 to mat_array.count do
                      (
                      tex_maps=#()
                      bit_maps=#()
                      hdri_maps=#()
                      mats=#(mat_array[mat][1])

                      for i in mats do
                        (
                        try
                        if (getNumSubMtls i)>=1 then
                          (
                          for j = 1 to (getNumSubMtls i) do
                            (
                            append mats (getSubMtl i j)
                            )
                          )
                        catch ()

                        try
                          (
                          for m = 1 to (getNumSubTexmaps i) do
                            (
                            if (getSubTexmap i m)!=undefined then
                              (
                              append 	tex_maps (getSubTexmap i m)
                              )
                            )
                          )
                        catch()
                        )


                      for i in tex_maps do
                        (
                        if (classof i ) == Bitmaptexture then appendifunique bit_maps i.filename
                        if (classof i ) == CoronaBitmap then appendifunique bit_maps i.filename
                        if (classof i ) == VRayHDRI then appendifunique hdri_maps i.HDRIMapName
                        if (getNumSubTexmaps i)>0 then
                          (
                          for j= 1 to (getNumSubTexmaps i) do
                            (
                            if (getSubTexmap i j)!=undefined then
                              (
                              append tex_maps (getSubTexmap i j)
                              )
                            )
                          )
                        )

                      mat_array[mat][3]=bit_maps
                      mat_array[mat][4]=hdri_maps
                      )
                )

                fn compareFN v1 v2 col: = (
                    if col>0 then
                      (
                      case of
                        (
                        (toLower(v1[col])>toLower(v2[col])) : 1
                        (toLower(v1[col])<toLower(v2[col])) : -1
                        default: 0
                        )
                      )else(
                      case of
                        (
                        (toLower(v1[col*-1])>toLower(v2[col*-1])) : -1
                        (toLower(v1[col*-1])<toLower(v2[col*-1])) : 1
                        default: 0
                        )
                      )
                )

                fn setupListView index = (
                  local topItemNum=0; if lv.items.count>0 then topItemNum=lv.TopItem.index -- record the scroll position so we can use it later

                  lv.clear()

                  lv.View = (dotNetClass "System.Windows.Forms.View").Details -- this is what allows the grid-like format to be used
                  lv.fullRowSelect = true
                  lv.gridLines = true
                  lv.HideSelection=false
                  lv.BorderStyle=lv.BorderStyle.FixedSingle
                  lv.HeaderStyle=lv.HeaderStyle.Clickable
                  lv.backColor=lv.backColor.FromArgb 220 220 220

                  lv.Columns.add "file path" w[1]
                  lv.Columns.add "file name" w[2]
                  lv.Columns.add "ext" w[3]
                  lv.Columns.add "type" w[4]
                  lv.Columns.add "use" w[5]

                  map_list=#()
                  mat_array=#()
                  full_list=#()
                  rows=#()
                  map_tmp_list=#()
                  map_list=#()
                  proxy_list=#()
                  proxy_tmp_list=#()
                  ies_tmp_list=#()
                  ies_list=#()
                  environ_tmp_list=#()
                  environ_list=#()

                  for m in getClassInstances BitmapTexture do
                    (
                    if m.filename!=undefined then
                      (
                      if (findItem map_tmp_list m.filename) == 0 then
                        (
                        append map_tmp_list m.filename
                        append map_list #((getFilenamePath m.filename),(getFilenameFile  m.filename), (getFilenameType  m.filename), "bitmap","unused", #()  )
                        )
                      )
                    )

                  fill_mat_array ()

                  for i in mat_array do
                    (
                    for j in i[3] do
                      (
                      for m=1 to map_list.count do
                        (
                        if j==map_tmp_list[m] then
                          (
                          map_list[m][5]="used"
                          join map_list[m][6] i[2]
                          )
                        )
                      )
                    )

                  for obj in geometry where (classof obj == VRayProxy ) or (classof obj == CProxy ) do
                    (
                    ok=true
                    for arg in proxy_tmp_list do
                      (
                      if (areNodesInstances obj arg) then
                        (
                        ok=false
                        a=finditem proxy_tmp_list arg
                        append proxy_list[a][6] obj
                        )
                      )
                    if ok then
                      (
                      append proxy_tmp_list obj
                        n=(classof obj) as string
                      append proxy_list #((getFilenamePath obj.filename),(getFilenameFile  obj.filename), (getFilenameType  obj.filename), n, "used" , #(obj))
                      )
                    )

                  for obj in lights where iskindof obj light do
                    (
                    ok=true
                    m=""
                    if ((classof obj==Target_Light) or  (classof obj==Free_Disc) or (classof obj==Free_Light) or (classof obj==Target_Disc)) do (m= obj.webFile)
                    if classof obj==VRayIES  do (m= obj.ies_file)
                    if classof obj==CoronaLight and obj.iesOn do (m= obj.iesFile)
                    if m!="" and m!=undefined then
                      (
                      for arg in ies_tmp_list do
                        (
                        if (areNodesInstances obj arg) then
                          (
                          ok=false
                          a=finditem ies_tmp_list arg
                          append ies_list[a][6] obj
                          )
                        )
                      if ok then
                        (

                        append ies_tmp_list obj ;
                        append ies_list #((getFilenamePath m),(getFilenameFile  m), (getFilenameType  m), "IES", "used" , #(obj))
                        )
                      )
                    )

                  if proxy_list.count>1 then
                    (
                    for i = 1 to proxy_list.count do
                      (
                      for j in proxy_list.count to i by -1 do
                        (
                        if i!=j then
                          (
                          if proxy_list[i][2]==proxy_list[j][2] then
                            (
                            if proxy_list[i][3]==proxy_list[j][3] then
                              (
                              join proxy_list[i][6] proxy_list[j][6]
                              deleteitem proxy_list j
                              )
                            )
                          )
                        )
                      )
                    )

                  if ies_list.count>1 then
                    (
                    for i = 1 to ies_list.count do
                      (
                      for j in ies_list.count to i by -1 do
                        (
                        if i!=j then
                          (
                          if ies_list[i][2]==ies_list[j][2] then
                            (
                            if ies_list[i][3]==ies_list[j][3] then
                              (
                              join ies_list[i][6] ies_list[j][6]
                              deleteitem ies_list j
                              )
                            )
                          )
                        )
                      )
                    )

                  if environmentMap != undefined then(
                      append environ_tmp_list environmentMap
                  )

                  try(
                      if renderers.current.environment_gi_map !=undefined then append environ_tmp_list renderers.current.environment_gi_map
                  )catch()

                  try(
                      if renderers.current.environment_rr_map !=undefined then append environ_tmp_list renderers.current.environment_rr_map
                  )catch()

                  try(
                      if renderers.current.environment_refract_map !=undefined then append environ_tmp_list renderers.current.environment_refract_map
                  )catch()

                  for i in environ_tmp_list do(
                      if (classof i ) == Bitmaptexture then appendifunique environ_list  #((getFilenamePath i.filename),(getFilenameFile  i.filename), (getFilenameType  i.filename), "Map", "environment" )

                      if (classof i ) == CoronaBitmap then appendifunique environ_list  #((getFilenamePath i.filename),(getFilenameFile  i.filename), (getFilenameType  i.filename), "Map", "environment" )

                      if (classof i ) == VRayHDRI then appendifunique environ_list  #((getFilenamePath i.HDRIMapName),(getFilenameFile  i.HDRIMapName), (getFilenameType  i.HDRIMapName), "Map", "environment" )

                      if (getNumSubTexmaps i)>0 then(
                          for j= 1 to (getNumSubTexmaps i) do(
                            if (getSubTexmap i j)!=undefined then(
                                append environ_tmp_list (getSubTexmap i j)
                            )
                          )
                      )
                  )

                  data = #()

                  for i in map_list do(
                      append full_list i[6]
                      append data i
                  )

                  for i in proxy_list do
                    (
                    append full_list i[6]
                    append data i
                    )

                  for i in ies_list do
                    (
                    append full_list i[6]
                    append data i
                    )

                  for i in environ_list do
                    (
                    append full_list i[6]
                    append data i
                    )

                  if index !=0 then (qsort data compareFN col:(index))

                  for i in data do(
                      jolesz=true

                      li = dotNetObject "System.Windows.Forms.ListViewItem"  i[1]
                      li.subitems.add i[2]
                      li.subitems.add i[3]
                      li.subitems.add i[4]
                      li.subitems.add i[5]
                      append rows li
                  )

                  lv.items.addRange rows
                )

                local missing_maps=#()

                fn addmap mapfile =
                    (
                    appendifunique missing_maps mapfile
                    )

                fn set_bitmap	old_file new_file =
                  (
                  for m in getClassInstances BitmapTexture do
                    (
                    if m.filename == old_file do ( m.fileName=new_file)
                    )
                  if CoronaBitmap != undefined then (
                    for m in getClassInstances CoronaBitmap do
                      (
                      if m.filename == old_file do ( m.fileName=new_file)
                      )
                    )
                  )

                fn set_proxy	old_file new_file =
                  (
                  for obj in geometry where classof obj == VRayProxy do
                    (
                    if obj.filename == old_file do ( obj.fileName=new_file)
                    )
                  for obj in geometry where classof obj == CProxy do
                    (
                    if obj.filename == old_file do ( obj.fileName=new_file)
                    )
                  )

                fn set_ies	old_file new_file =
                  (
                  for obj in lights where iskindof obj light do
                    (
                    if ((classof obj==Target_Light) or  (classof obj==Free_Disc) or (classof obj==Free_Light) or (classof obj==Target_Disc)) then
                      (
                      if  obj.webFile == old_file then (obj.webFile=new_file)
                      )
                    if classof obj==VRayIES  then
                      (
                      if  obj.ies_file == old_file then (obj.ies_file=new_file)
                      )
                    if classof obj==CoronaLight  then
                      (
                      if  obj.iesFile == old_file then (obj.iesFile=new_file)
                      )
                    )
                  )

                fn set_map	old_file new_file =
                  (
                  for i in environ_tmp_list do
                    (
                    try (if  i.filename == old_file then (i.filename=new_file))catch ()
                    try (if  i.HDRIMapName == old_file then (i.HDRIMapName=new_file))catch ()
                    )
                  )

            -- Actions

                on patheditor open do(
                    setupListView index

                    for i =1 to lv.Items.count do(
                        lv.items.item[i-1].selected = true
                    )

                    local hi = $'Project Folder Path Dummy'.layer.name
                    local hi2 = substituteString hi "Project Folder Path: " ""

                    if hi2 != "" and hi2 != undefined then(
                        -- Variables

                            newPathText = hi2

                            if (substring newPathText newPathText.count 1) != "\\" then(
                                newPathText = newPathText + "\\"
                            )

                            newPathText = (newPathText + "sceneassets\\images\\")

                            tmp = #()

                        for i =1 to lv.SelectedItems.count do(
                            old_file=lv.SelectedItems.item[i-1].subitems.item[0].text+lv.SelectedItems.item[i-1].subitems.item[1].text+lv.SelectedItems.item[i-1].subitems.item[2].text

                            new_file = newPathText + lv.SelectedItems.item[i-1].subitems.item[1].text+lv.SelectedItems.item[i-1].subitems.item[2].text

                            try (copyFile old_file new_file) catch ()
                        )

                        for i =1 to lv.SelectedItems.count do(
                            old_file=lv.SelectedItems.item[i-1].subitems.item[0].text+lv.SelectedItems.item[i-1].subitems.item[1].text+lv.SelectedItems.item[i-1].subitems.item[2].text
                            type=lv.SelectedItems.item[i-1].subitems.item[3].text
                            new_file = newPathText + lv.SelectedItems.item[i-1].subitems.item[1].text+lv.SelectedItems.item[i-1].subitems.item[2].text

                            if type=="bitmap"	then set_bitmap		old_file new_file
                            if type=="IES" 		then set_ies			old_file new_file
                            if type=="VRayProxy"	then set_proxy	 	old_file new_file
                            if type=="CProxy"	then set_proxy	 	old_file new_file
                            if type=="Map"		then set_map	 		old_file new_file
                        )

                        setupListView index
                    )

                    -- Close dialog

                        try(
                            destroyDialog patheditor
                        )catch()
                )
        )

        createdialog patheditor style:#( #style_resizing,#style_toolwindow, #style_sysmenu ) pos:[5,115]
    )

-- Toggle group open

    MacroScript callisScriptsToggleGroupOpen category:"Callis Scripts Extras" tooltip:"Toggle Group Open" Icon:#("Toggle Group Open",1)

    (
    		if isGroupHead selection[1] and isOpenGroupHead selection[1] then(
    				max group close
    		)else(
    				max group open
    		)
    )

-- Toggle group open

    MacroScript callisScriptsHideSelected category:"Callis Scripts Extras" tooltip:"Hide Selected" Icon:#("Hide Selected",1)

    (
    		max hide selection
    )
