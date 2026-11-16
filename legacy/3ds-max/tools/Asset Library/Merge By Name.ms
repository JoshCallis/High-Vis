-- Subfunctions

    -- Attach

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

-- Functions

    -- Merge

        fn callisScriptsMergeByName prefix = (
            max select none

            for myNum = 0 to 99 do(
                -- Variables

                    -- Zeros variable

                        local zeros

                        if myNum < 1000 do(
                            zeros = "0"
                        )

                        if myNum < 100 do(
                            zeros = "0"
                        )

                        if myNum < 10 do(
                            zeros = "00"
                        )

                    local objectsToAttach = #()

                for obj in geometry do(
                    if matchPattern obj.name Pattern:(prefix + zeros + (myNum as string) + "_*")then(
                        append objectsToAttach obj
                    )
                )

                for objectsToSelect in objectsToAttach do(
                    selectMore objectsToSelect
                )

                if selection.count > 1 then(
                    try(
                        disableRelevantEventHandlersForCertainOperationsVariable.disableOnNodeAddedEventHandlers()

                        objectAttacherDefaults()

                        disableRelevantEventHandlersForCertainOperationsVariable.enableOnNodeAddedEventHandlers()
                    )catch()
                )

                max select none
            )
        )

        rollout callisScriptsMergeByNameRollout("Merge By Name")(
            -- Variables

                local prefixText

            editText prefix "Common Name Prefix:"

            editText warning "Note: this will run on ALL scene geometry" readOnly:true

            button mergeButton "Merge"

            on prefix entered txt do(
                if txt != "" then(
                    prefixText = txt
                )
            )

            on mergeButton pressed do(
                if prefixText != undefined then(
                    callisScriptsMergeByName prefixText

                    destryDialog callisScriptsMergeByNameRollout
                )
            )
        )

        createDialog callisScriptsMergeByNameRollout 230 100
