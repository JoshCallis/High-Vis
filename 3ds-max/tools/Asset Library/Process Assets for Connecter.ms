-- Instructions

    -- How it works:

        -- mergeAllFiles function merges in everything from the original Scenes folder, attaches all geometry, proxies the result and groups this together with any lights/cameras (if user chose to include).

    -- If there are two versions of the same volume (e.g. lights on and off), have two separate volumes, with " (Alternate)" appended to the name of one. For further alternate versions, add a number e.g. " (Alternate 2)"
    -- If using volume number, ensure volume numbers for each volume's name contain exactly 3 digits (e.g. 023)
    -- Original Folder field takes a folder containing all the volumes to process. Destination Folder takes a folder where all the processed volumes will be saved.
    -- If using keyword, user must go into files and see if there is any string in the desired objects' nmaes that isn't in the other objects' names. This must be true for all files being processed.
    -- Note that using a 'phrase to split with' in file naming continued will replace any instances of this phrase (which may be contained within the text desired to retain) with a space.

-- Progress

    -- Function works! Now just need to have errors save to an ini file.
    -- Also change the error object names to remove the last underscore and anything after, and then remove the "everything else from their files" part of the error message.
    -- Also need to convert have spinners for the numbers, for convenience and so we don't need to convert string numbers to integers.

    -- Superseded 190617 Have added keyword filter editText. Now need to do everything else for it
    -- 190705 Keyword filter works

    -- 190705 Need to add interface for choosing what layer to put new objects in, with default layer as default

    -- 190712 proxies decision code is added everywhere (rollout + function arguments) except for within the function itself
    -- 190724 proxies decision code is added everywhere

    -- 190724 Need to set script to find how many volumes are currently in the destination folder, and then name new volumes added based on this rather than based on what their current numbers are.
    -- Current numbers will no longer be needed/relevant. Will work alphabetically.

    -- 190724 the above has been actioned. Now need to add the renaming functionality from the other vaious scripts to make this tool very powerful.
    -- Need to rename each object 'category + volume name + file name + number of object' with the group having no number of object, or 'category + volume name + file name + number of object' if single object

    -- 190725 Change file names to file numbers in alphabetical order code has been added to everything.

    -- 190726 Need to add option to not attach

    -- 190808 Need to add this to warnings: Note that using a 'phrase to split with' in file naming continued will replace any instances of this phrase (which may be contained within the text desired to retain) with a space.
    -- 190808 Need to rework to failsafes for when pressing process button, as they no longer work with the new 'volume to configure' functionality.
    -- 190808 Need to update the code before the main for loop in the main function to match the new 'volume to configure' functionality.

    -- 190819 Need to add tooltip to phrase to split with and retain text from specified checkboxes saying that where the chosen phrase if found within the text to keep, it will be replaced with a space and the next letter will be capitalised.

    -- 190823 Need to add option to place pivots on top and middle

-- Variables

    try(
        include "$scripts/Startup/Callis Scripts/General Event Handling.ms"
    )catch()

    global callisScriptsAssetOrganisationFailedObjects = #()

    global callisScriptsAssetOrganisationObjectsToDelete = #()

-- Disabling callbacks

    disableRelevantEventHandlersForCertainOperationsVariable.disableOnNodeAddedEventHandlers()

-- Functions

    -- Subfunctions

        -- Sort objects

            fn sortObjectsFunction v1 v2 = (
                local string1 = v1.name

                local string2 = v2.name

                local stringsArray = #(string1,string2)

                sort stringsArray

                case of(
                    (stringsArray[1] == string1): -1
                    (stringsArray[1] == string2): 1
                    default: 0
                )
            )

        -- Does file exist

            fn existFile fname = (getfiles fname).count != 0

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

                    -- Include scripts

                        include "$scripts\CallisScripts\scripts\Libraries\Callis Scripts Library.ms"

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
                            for o in objs do(
                                append callisScriptsAssetOrganisationObjectsToDelete o

                                appendIfUnique callisScriptsAssetOrganisationFailedObjects (objs[1].name)
                            )
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

        -- Attach selected objects

            fn attachSelectedObjects = (
                try(
                    disableRelevantEventHandlersForCertainOperationsVariable.disableOnNodeAddedEventHandlers()
                )catch()

                objectAttacherDefaults()

                try(
                    disableRelevantEventHandlersForCertainOperationsVariable.enableOnNodeAddedEventHandlers()
                )catch()
            )

        -- Place pivots at bottom

            -- Variables

                global pivotPlacer
                global pivotPlacerDefaults
                global pivotPlacerUI
                global pivotPlacerExpertMode

                global pPCloseOpenUI

                global pPCalcMinMax
                global pPGetSelectedVertexesEditablePoly
                global pPGetSelectedEdgesEditablePoly
                global pPGetSelectedFacesEditablePoly

                global pPDo
                global pPApply
                global pPHelp
                global pPLoadDef
                global pPSaveDef

                global pPDefineUI
                global pPDefineEMUI
                global pPRollout
                global pPEMRollout
                global pPFloater

            -- Functions

                fn pivotPlacer pPPlace pPType pPGroups pPAlignTo =
                	(
                	undo "pivotPlacer" on
                		(
                		for obj in selection do
                			(

                				(

                					(

                						(
                						error = 0
                						try
                							(
                							if pPAlignTo == 1 then
                								(
                								-- if using local space, calculate center and rotation and then reset the rotation
                								if pPType == 1 then
                									(
                									minmax = pPCalcMinMax obj
                									originalCenter = [(minmax[1].x+minmax[2].x)/2, (minmax[1].y+minmax[2].y)/2, (minmax[1].z+minmax[2].z)/2]
                									originalRotation = coordsys world obj.rotation
                									obj.rotation = quat 0 0 0 1
                									)

                								-- place the pivot
                								minmax = pPCalcMinMax obj
                								if pPPlace == 1 then obj.pivot = [minmax[2].x, minmax[2].y, minmax[1].z]
                								if pPPlace == 2 then obj.pivot = [minmax[2].x, minmax[2].y, (minmax[1].z+minmax[2].z)/2]
                								if pPPlace == 3 then obj.pivot = [minmax[2].x, minmax[2].y, minmax[2].z]
                								if pPPlace == 4 then obj.pivot = [(minmax[1].x+minmax[2].x)/2, minmax[2].y, minmax[1].z]
                								if pPPlace == 5 then obj.pivot = [(minmax[1].x+minmax[2].x)/2, minmax[2].y, (minmax[1].z+minmax[2].z)/2]
                								if pPPlace == 6 then obj.pivot = [(minmax[1].x+minmax[2].x)/2, minmax[2].y, minmax[2].z]
                								if pPPlace == 7 then obj.pivot = [minmax[1].x, minmax[2].y, minmax[1].z]
                								if pPPlace == 8 then obj.pivot = [minmax[1].x, minmax[2].y, (minmax[1].z+minmax[2].z)/2]
                								if pPPlace == 9 then obj.pivot = [minmax[1].x, minmax[2].y, minmax[2].z]

                								if pPPlace == 10 then obj.pivot = [minmax[2].x, (minmax[1].y+minmax[2].y)/2, minmax[1].z]
                								if pPPlace == 11 then obj.pivot = [minmax[2].x, (minmax[1].y+minmax[2].y)/2, (minmax[1].z+minmax[2].z)/2]
                								if pPPlace == 12 then obj.pivot = [minmax[2].x, (minmax[1].y+minmax[2].y)/2, minmax[2].z]
                								if pPPlace == 13 then obj.pivot = [(minmax[1].x+minmax[2].x)/2, (minmax[1].y+minmax[2].y)/2, minmax[1].z]

                								if pPPlace == 14 then obj.pivot = [(minmax[1].x+minmax[2].x)/2, (minmax[1].y+minmax[2].y)/2, (minmax[1].z+minmax[2].z)/2]

                								if pPPlace == 15 then obj.pivot = [(minmax[1].x+minmax[2].x)/2, (minmax[1].y+minmax[2].y)/2, minmax[2].z]
                								if pPPlace == 16 then obj.pivot = [minmax[1].x, (minmax[1].y+minmax[2].y)/2, minmax[1].z]
                								if pPPlace == 17 then obj.pivot = [minmax[1].x, (minmax[1].y+minmax[2].y)/2, (minmax[1].z+minmax[2].z)/2]
                								if pPPlace == 18 then obj.pivot = [minmax[1].x, (minmax[1].y+minmax[2].y)/2, minmax[2].z]

                								if pPPlace == 19 then obj.pivot = [minmax[2].x, minmax[1].y, minmax[1].z]
                								if pPPlace == 20 then obj.pivot = [minmax[2].x, minmax[1].y, (minmax[1].z+minmax[2].z)/2]
                								if pPPlace == 21 then obj.pivot = [minmax[2].x, minmax[1].y, minmax[2].z]
                								if pPPlace == 22 then obj.pivot = [(minmax[1].x+minmax[2].x)/2, minmax[1].y, minmax[1].z]
                								if pPPlace == 23 then obj.pivot = [(minmax[1].x+minmax[2].x)/2, minmax[1].y, (minmax[1].z+minmax[2].z)/2]
                								if pPPlace == 24 then obj.pivot = [(minmax[1].x+minmax[2].x)/2, minmax[1].y, minmax[2].z]
                								if pPPlace == 25 then obj.pivot = [minmax[1].x, minmax[1].y, minmax[1].z]
                								if pPPlace == 26 then obj.pivot = [minmax[1].x, minmax[1].y, (minmax[1].z+minmax[2].z)/2]
                								if pPPlace == 27 then obj.pivot = [minmax[1].x, minmax[1].y, minmax[2].z]

                								-- if using local space, rotate the object back
                								if pPType == 1 then
                									(
                									obj.rotation = originalRotation
                									midPivot = obj.pivot
                									minmax = pPCalcMinMax obj
                									obj.pivot = [(minmax[1].x+minmax[2].x)/2, (minmax[1].y+minmax[2].y)/2, (minmax[1].z+minmax[2].z)/2]
                									midPosition = obj.pos
                									obj.pos = originalCenter
                									changeInPosition = obj.pos - midPosition
                									obj.pivot = midPivot + changeInPosition
                									)
                								)
                							else if pPAlignTo == 2 then
                								(
                								Verts = (pPGetSelectedVertexesEditablePoly obj)
                								if Verts.count != 0 then
                									(
                									pPAllXValues = #()
                									pPAllYValues = #()
                									pPAllZValues = #()
                									for i in Verts do append pPAllXValues (polyop.getvert obj i).x
                									pPAverageX = sLibAverageMinMaxOfArray pPAllXValues
                									for i in Verts do append pPAllYValues (polyop.getvert obj i).y
                									pPAverageY = sLibAverageMinMaxOfArray pPAllYValues
                									for i in Verts do append pPAllZValues (polyop.getvert obj i).z
                									pPAverageZ = sLibAverageMinMaxOfArray pPAllZValues
                									obj.pivot = [pPAverageX,pPAverageY,pPAverageZ]
                									)
                								)
                							else if pPAlignTo == 3 then
                								(
                								Edges = (pPGetSelectedEdgesEditablePoly obj)
                								if Edges.count != 0 then
                									(
                									pPAllXValues = #()
                									pPAllYValues = #()
                									pPAllZValues = #()
                									for i in Edges do
                										(
                										e = polyop.getVertsUsingEdge obj i
                										for w in e do (append pPAllXValues (polyop.getvert obj w).x)
                										)
                									pPAverageX = sLibAverageMinMaxOfArray pPAllXValues
                									for i in Edges do
                										(
                										e = polyop.getVertsUsingEdge obj i
                										for w in e do (append pPAllYValues (polyop.getvert obj w).y)
                										)
                									pPAverageY = sLibAverageMinMaxOfArray pPAllYValues
                									for i in Edges do
                										(
                										e = polyop.getVertsUsingEdge obj i
                										for w in e do (append pPAllZValues (polyop.getvert obj w).z)
                										)
                									pPAverageZ = sLibAverageMinMaxOfArray pPAllZValues
                									obj.pivot = [pPAverageX,pPAverageY,pPAverageZ]
                									)
                								)
                							else if pPAlignTo == 4 then
                								(
                								Faces = (pPGetSelectedFacesEditablePoly obj)
                								if Faces.count != 0 then
                									(
                									pPAllXValues = #()
                									pPAllYValues = #()
                									pPAllZValues = #()
                									for i in Faces do append pPAllXValues (polyop.getFaceCenter obj i).x
                									pPAverageX = sLibAverageMinMaxOfArray pPAllXValues
                									for i in Faces do append pPAllYValues (polyop.getFaceCenter obj i).y
                									pPAverageY = sLibAverageMinMaxOfArray pPAllYValues
                									for i in Faces do append pPAllZValues (polyop.getFaceCenter obj i).z
                									pPAverageZ = sLibAverageMinMaxOfArray pPAllZValues
                									obj.pivot = [pPAverageX,pPAverageY,pPAverageZ]
                									)
                								)
                							)
                						catch (error = 1)
                						)
                					)
                				)
                			)

                		)
                	)

                fn pPCalcMinMax obj =
                	(
                	mymax = obj.max
                	mymin = obj.min
                	if isgrouphead obj == true then
                		(
                		objs = #()
                		for i in obj.children do
                			(
                			if isGroupMember i == true then append objs i
                			)
                		a = sLibGetCollectionBBox objs
                		mymax = a[1]
                		mymin = a[2]
                		)
                	return #(mymax, mymin)
                	)

        -- Merge all files

            -- Variables

                global rlt_BatchMerge
                global bm_directory = ""
                global filesToMerge = #()

                global mergeFileTypeExtensions = #( "fbx", "prj", "dwg", "dxf", "ige", "igs", "iges", "max", "3ds", "shp", "skp", "stl", "obj")
                global getMergableFiles
                global checkDialog
                global YYYYYitems
                global ZZZZZitems

            fn checkDialog = (
              	local hwnd = dialogMonitorOps.getWindowHandle()

              	if (uiAccessor.getWindowText hwnd == "Import Name Conflict") do (
              		uiAccessor.PressButtonByName hwnd "OK"
              	)

              	true
            )

            fn getMergableFiles dir = (
              	local theFiles = #()

              	for f in mergeFileTypeExtensions do(
                		local tempFiles = getFiles (dir + "/*." + f)

                		if tempFiles.count > 0 then(
                			join theFiles tempFiles
                		)
              	)

              	theFiles
            )

            fn mergeAllFiles oldScenesPath volumeNumber proxiesPath volumeName catergoryName volumeNameSuffixString fileNameExtraTextString keywordFilterString includeCamerasBoolean includeLightsBoolean saveEachObjectSeparatelyBoolean attachObjectsBoolean proxyObjectsBoolean coronaBoolean replaceAllTextBoolean retainSpecifiedTextFromFileNameBoolean retainSpecifiedTextFromObjectNameBoolean retainAllTextFromFileNameBoolean phraseToSplitWithString numberOfIndicesToRemoveFromStartInteger numberOfIndicesToRemoveFromEndInteger = (
                -- Variables

                    -- Volume number

                        local volumeNumberReal = volumeNumber

                        -- Add '0's to volumeNumberReal as needed

                            if volumeNumber.count == 2 then(
                                volumeNumberReal = "0" + volumeNumber
                            )

                            if volumeNumber.count == 1 then(
                                volumeNumberReal = "00" + volumeNumber
                            )

                    local currentFileToSaveCount = 1

                -- Get the files

                    filesToMerge = getMergableFiles oldScenesPath
                    YYYYYitems = for f in filesToMerge collect (filenameFromPath f)

                    ZZZZZitems = #{1..(YYYYYitems.count)}

                -- Merge and process

                    local toMerge = #()
                    local sel = (ZZZZZitems as array)

                    for i = 1 to sel.count do(
                        append toMerge filesToMerge[sel[i]]
                    )

                    -- Autorename

                    		DialogMonitorOPS.unRegisterNotification id:#autoRaname
                    		DialogMonitorOPS.RegisterNotification checkDialog id:#autoRaname
                    		DialogMonitorOPS.Enabled = true

                    for i = 1 to toMerge.count do(
                        -- Merge

                        		if (mergeMAXFile toMerge[i] #noRedraw #select #mergeDups #renameMtlDups #neverReparent quiet:true) == false and not (matchPattern (toMerge[i] as string) Pattern:"proxy") and not (matchPattern (toMerge[i] as string) Pattern:"Proxy") then(
                        			  importFile toMerge[i] #noPrompt
                        		)

                        -- Ungroup everything

                            for a in (geometry) do(
                                try(
                                    max group ungroup
                                )catch()

                                try(
                                    max group ungroup
                                )catch()

                                try(
                                    max group ungroup
                                )catch()

                                try(
                                    max group ungroup
                                )catch()

                                try(
                                    max group ungroup
                                )catch()

                                try(
                                    max group ungroup
                                )catch()

                                try(
                                    max group ungroup
                                )catch()

                                try(
                                    max group ungroup
                                )catch()

                                try(
                                    max group ungroup
                                )catch()

                                try(
                                    max group ungroup
                                )catch()
                            )

                        -- Move objects into temporary layer

                            try(
                                for a in selection do(
                                    (LayerManager.getLayerFromName "Callis Scripts Temporary Proxy Layer").addnode a
                                )
                            )catch()

                        -- Delete certain kinds of object if relevant

                            temporaryProxyLayerNodes = #()

                            temporaryProxyLayer = layermanager.getLayerFromName "Callis Scripts Temporary Proxy Layer"
                            temporaryProxyLayer.nodes &temporaryProxyLayerNodes

                            if includeCamerasBoolean == false then(
                                for a in temporaryProxyLayerNodes do(
                                    if superClassof a == camera then(
                                        delete a
                                    )
                                )
                            )

                            temporaryProxyLayerNodes = #()

                            temporaryProxyLayer.nodes &temporaryProxyLayerNodes

                            if includeLightsBoolean == false then(
                                for a in temporaryProxyLayerNodes do(
                                    if superClassof a == light then(
                                        delete a
                                    )
                                )
                            )

                            temporaryProxyLayerNodes = #()

                            temporaryProxyLayer.nodes &temporaryProxyLayerNodes

                            for a in temporaryProxyLayerNodes do(
                                if classof a == VrayPlane then(
                                    delete a
                                )
                            )

                        -- Delete non-keyword objects if relevant

                            -- Select all objects in the temporary group

                                deselect selection

                                temporaryProxyLayer = layermanager.getLayerFromName "Callis Scripts Temporary Proxy Layer"
                                temporaryProxyLayer.nodes &temporaryProxyLayerNodes

                                for a in temporaryProxyLayerNodes do(
                                    selectmore a
                                )

                            -- Define nonKeywordObjectsToDelete array

                                local nonKeywordObjectsToDelete = #()

                            -- Delete relevant objects

                                if keywordFilterString != "" and keywordFilterString != undefined then(
                                    for a in selection do(
                                        if not matchPattern a.name Pattern:keywordFilterString then(
                                            append nonKeywordObjectsToDelete (a)
                                        )
                                    )
                                )

                                for a in nonKeywordObjectsToDelete do(
                                    delete a
                                )

                            -- Reset nonKeywordObjectsToDelete array

                                nonKeywordObjectsToDelete = #()

                        -- Select everything in the temporary group

                            deselect selection

                            temporaryProxyLayer = layermanager.getLayerFromName "Callis Scripts Temporary Proxy Layer"
                            temporaryProxyLayer.nodes &temporaryProxyLayerNodes

                            for a in temporaryProxyLayerNodes do(
                                selectmore a
                            )

                        -- Create groups to deal with

                            -- Activate temporary proxy layer

                                temporaryProxyLayer.current = true

                            if saveEachObjectSeparatelyBoolean == true then( -- Note: save separately option current acts on the basis that each object is to become its own file. Would be good to later have functionality to use logic to determine the basis e.g. based on object names.
                                local objs = getCurrentSelection()

                                qsort objs sortObjectsFunction

                                for a = 1 to objs.count do(
                                    deselect selection

                                    select objs[a]

                                    if a < 10 then(
                                        group selection name:("Callis Scripts Subgroup 00" + (a as string))
                                    )

                                    if a > 9 and a < 100 then(
                                        group selection name:("Callis Scripts Subgroup 0" + (a as string))
                                    )

                                    if a > 99 and a < 1000 then(
                                        group selection name:("Callis Scripts Subgroup " + (a as string))
                                    )

                                    if a > 999 and a < 10000 then(
                                        group selection name:("Callis Scripts Subgroup " + (a as string))
                                    )

                                    deselect selection
                                )
                            )else(
                                group selection name:"Callis Scripts Subgroup 001"
                            )

                            -- Activate default layer

                                defaultLayer = layermanager.getLayerFromName "0"
                                defaultLayer.current = true

                        -- Select none

                            deselect selection

                        temporaryProxyLayer = layermanager.getLayerFromName "Callis Scripts Temporary Proxy Layer"
                        temporaryProxyLayer.nodes &temporaryProxyLayerNodes

                        local SubgroupsToMoveToSublayer = for a in temporaryProxyLayerNodes where (isGroupHead a) collect a

                        qsort SubgroupsToMoveToSublayer sortObjectsFunction

                        for currentSubgroup in SubgroupsToMoveToSublayer do(
                            -- Ungroup and move to sublayer

                                select currentSubgroup

                                -- Ungroup

                                    try(
                                        max group ungroup
                                    )catch()

                                    try(
                                        max group ungroup
                                    )catch()

                                    try(
                                        max group ungroup
                                    )catch()

                                -- Variables

                                    local currentSelection = getCurrentSelection()

                                for a in currentSelection do(
                                    (LayerManager.getLayerFromName "Callis Scripts Temporary Proxy Sublayer").addnode a
                                )

                                deselect selection

                                -- Define currentObjectNameForFile variable in case needed for file naming

                                    temporaryProxySublayer = layermanager.getLayerFromName "Callis Scripts Temporary Proxy Sublayer"
                                    temporaryProxySublayer.nodes &temporaryProxySublayerNodes

                                    local currentObjectNameForFile = temporaryProxySublayerNodes[1].name

                            -- Create newFileName variable

                                a = toMerge[i]

                                -- Define fileNumberString variable

                                    if currentFileToSaveCount < 10000 then(
                                        local fileNumberString = (currentFileToSaveCount as string)
                                    )

                                    if currentFileToSaveCount < 1000 then(
                                        local fileNumberString = (currentFileToSaveCount as string)
                                    )

                                    if currentFileToSaveCount < 100 then(
                                        local fileNumberString = ("0" + (currentFileToSaveCount as string))
                                    )

                                    if currentFileToSaveCount < 10 then(
                                        local fileNumberString = ("00" + (currentFileToSaveCount as string))
                                    )

                                -- Define sFile variable

                                    local sFile = (getFilenameFile a) as string

                                -- Define newFileName variable

                                    if replaceAllTextBoolean == true then(
                                        local newFileName = (fileNumberString + fileNameExtraTextString)
                                    )

                                    if retainSpecifiedTextFromFileNameBoolean == true then(
                                        -- Redefine sFile variable

                                            sFile = filterString sFile phraseToSplitWithString

                                            for b = 1 to numberOfIndicesToRemoveFromStartInteger do(
                                                sFile = deleteItem sFile 1
                                            )

                                            for b = 1 to numberOfIndicesToRemoveFromEndInteger do(
                                                sFile = deleteItem sFile (sFile.count)
                                            )

                                            local sFile2 = ""

                                            for b = 1 to sFile.count do(
                                                append sFile2 sFile[b]

                                                if b != sFile.count then(
                                                    append sFile2 " "
                                                )
                                            )

                                            sFile = sFile2

                                            -- Capitalise first letter of each word

                                                local lastStringItemWasSpace = false

                                                for b = 1 to sFile.count do(
                                                    if lastStringItemWasSpace == true then(
                                                        sFile = replace sFile b 1 (toUpper sFile[b])

                                                        lastStringItemWasSpace = false
                                                    )

                                                    if b == 1 then(
                                                        sFile = replace sFile b 1 (toUpper sFile[b])
                                                    )

                                                    if sFile[b] == " " then(
                                                        lastStringItemWasSpace = true
                                                    )
                                                )

                                        -- Define newFileName variable

                                            local newFileName = (fileNumberString + fileNameExtraTextString + " " + sFile)
                                    )

                                    if retainSpecifiedTextFromObjectNameBoolean == true then(
                                        -- Redefine sFile variable

                                            sFile = filterString currentObjectNameForFile phraseToSplitWithString

                                            for b = 1 to numberOfIndicesToRemoveFromStartInteger do(
                                                sFile = deleteItem sFile 1
                                            )

                                            for b = 1 to numberOfIndicesToRemoveFromEndInteger do(
                                                sFile = deleteItem sFile (sFile.count)
                                            )

                                            local sFile2 = ""

                                            for b = 1 to sFile.count do(
                                                append sFile2 sFile[b]

                                                if b != sFile.count then(
                                                    append sFile2 " "
                                                )
                                            )

                                            sFile = sFile2

                                            -- Capitalise first letter of each word

                                                local lastStringItemWasSpace = false

                                                for b = 1 to sFile.count do(
                                                    if lastStringItemWasSpace == true then(
                                                        sFile = replace sFile b 1 (toUpper sFile[b])

                                                        lastStringItemWasSpace = false
                                                    )

                                                    if b == 1 then(
                                                        sFile = replace sFile b 1 (toUpper sFile[b])
                                                    )

                                                    if sFile[b] == " " then(
                                                        lastStringItemWasSpace = true
                                                    )
                                                )

                                        -- Define newFileName variable

                                            local newFileName = (fileNumberString + fileNameExtraTextString + " " + sFile)
                                    )

                                    if retainAllTextFromFileNameBoolean == true then(
                                        -- Don't retain file name if it is just a number

                                            if sFile as integer == undefined then(
                                                local newFileName = (fileNumberString + fileNameExtraTextString + " " + sFile)
                                            )else(
                                                local newFileName = (fileNumberString + fileNameExtraTextString)
                                            )
                                    )

                            -- Select all the geometry in the sublayer

                                temporaryProxySublayer = layermanager.getLayerFromName "Callis Scripts Temporary Proxy Sublayer"
                                temporaryProxySublayer.nodes &temporaryProxySublayerNodes

                                for a in temporaryProxySublayerNodes do(
                                    if ((superclassof a == geometryclass or superclassof a == shape) and classof a != Targetobject) and classof a != VrayProxy and classof a != CProxy then(
                                        selectmore a
                                    )
                                )

                            -- Attach selected objects if relevant

                                if attachObjectsBoolean == true then(
                                    if selection.count > 1 then(
                                        -- Attach

                                            try(
                                                attachSelectedObjects()
                                            )catch(
                                                append callisScriptsAssetOrganisationFailedObjects (selection[1].name)
                                            )
                                    )
                                )

                            -- Proxy selected objects if relevant

                                if proxyObjectsBoolean == true then(
                                    objs = getCurrentSelection()

                                    if objs.count != 0 then(
                                        if objs.count == 1 then(
                                            if coronaBoolean == false then(
                                                vrayMeshExport meshFile:(proxiesPath + "/" + catergoryName + ", " + volumeNumber + ", " + newFileName + ".vrmesh") autoCreateProxies:true exportMultiple:false maxPreviewFaces:30000 animation:off nodes:objs oneVoxelPerMesh:true
                                            )else(
                                                CProxy.ProxyFp.fromScene (CProxy()) objs[1] (proxiesPath + "/" + catergoryName + ", " + volumeNumber + ", " + newFileName + ".cgeo")

                                                select (getnodebyname "Corona Proxy001")

                                                temporaryProxySublayer.addnode (getnodebyname "Corona Proxy001")

                                                (getnodebyname "Corona Proxy001").name = objs[1].name

                                                delete objs[1]
                                            )
                                        )else(
                                            for a = 1 to objs.count do(
                                                -- Proxy

                                                    if a < 10 then(
                                                        if coronaBoolean == false then(
                                                            vrayMeshExport meshFile:(proxiesPath + "/" + catergoryName + ", " + volumeNumber + ", " + newFileName + " " + "00" + (a as string) + ".vrmesh") autoCreateProxies:true exportMultiple:false maxPreviewFaces:30000 animation:off nodes:objs[a] oneVoxelPerMesh:true
                                                        )else(
                                                            CProxy.ProxyFp.fromScene (CProxy()) objs[a] (proxiesPath + "/" + catergoryName + ", " + volumeNumber + ", " + newFileName + " " + "00" + (a as string) + ".cgeo")

                                                            select (getnodebyname "Corona Proxy001")

                                                            temporaryProxySublayer.addnode (getnodebyname "Corona Proxy001")

                                                            (getnodebyname "Corona Proxy001").name = objs[a].name

                                                            delete objs[a]
                                                        )
                                                    )

                                                    if a > 9 and a < 100 then(
                                                        if coronaBoolean == false then(
                                                            vrayMeshExport meshFile:(proxiesPath + "/" + catergoryName + ", " + volumeNumber + ", " + newFileName + " " + "0" + (a as string) + ".vrmesh") autoCreateProxies:true exportMultiple:false maxPreviewFaces:30000 animation:off nodes:objs[a] oneVoxelPerMesh:true
                                                        )else(
                                                            CProxy.ProxyFp.fromScene (CProxy()) objs[a] (proxiesPath + "/" + catergoryName + ", " + volumeNumber + ", " + newFileName + " " + "0" + (a as string) + ".cgeo")

                                                            select (getnodebyname "Corona Proxy001")

                                                            temporaryProxySublayer.addnode (getnodebyname "Corona Proxy001")

                                                            (getnodebyname "Corona Proxy001").name = objs[a].name

                                                            delete objs[a]
                                                        )
                                                    )

                                                    if a > 99 and a < 1000 then(
                                                        if coronaBoolean == false then(
                                                            vrayMeshExport meshFile:(proxiesPath + "/" + catergoryName + ", " + volumeNumber + ", " + newFileName + " " + (a as string) + ".vrmesh") autoCreateProxies:true exportMultiple:false maxPreviewFaces:30000 animation:off nodes:objs[a] oneVoxelPerMesh:true
                                                        )else(
                                                            CProxy.ProxyFp.fromScene (CProxy()) objs[a] (proxiesPath + "/" + catergoryName + ", " + volumeNumber + ", " + newFileName + " " + (a as string) + ".cgeo")

                                                            select (getnodebyname "Corona Proxy001")

                                                            temporaryProxySublayer.addnode (getnodebyname "Corona Proxy001")

                                                            (getnodebyname "Corona Proxy001").name = objs[a].name

                                                            delete objs[a]
                                                        )
                                                    )
                                            )
                                        )
                                    )
                                )

                                -- Set all proxies to display as whole mesh

                                    -- Select all the geometry in the sublayer

                                        deselect selection

                                        temporaryProxySublayer = layermanager.getLayerFromName "Callis Scripts Temporary Proxy Sublayer"
                                        temporaryProxySublayer.nodes &temporaryProxySublayerNodes

                                        for a in temporaryProxySublayerNodes do(
                                            if classof a == VrayProxy or classOf a == CProxy then(
                                                selectmore a
                                            )
                                        )

                                    for a in selection do(
                                        if classOf a == VRayProxy or classOf a == CProxy then(
                                            try(
                                                if coronaBoolean == false then(
                                                    a.display = 4
                                                )else(
                                                    try(
                                                        $.previzType = 3
                                                    )catch()
                                                )
                                            )catch()
                                        )
                                    )

                            -- Rename all geometry in the subgroup

                                deselect selection

                                temporaryProxySublayerNodes = undefined
                                temporaryProxySublayer.nodes &temporaryProxySublayerNodes

                                for d = 1 to temporaryProxySublayerNodes.count do(
                                    -- Variables

                                        c = temporaryProxySublayerNodes[d]

                                        -- Create objectNumber variable

                                            objectNumber = (d as string)

                                    if temporaryProxySublayerNodes.count > 1 then(
                                        c.name = (catergoryName + ", " + volumeNumber + ", " + newFileName + ", " + objectNumber)
                                    )else(
                                        c.name = (catergoryName + ", " + volumeNumber + ", " + newFileName)
                                    )
                                )

                            -- Group everything in the subgroup and move back to layer 0

                                deselect selection

                                temporaryProxySublayerNodes = undefined
                                temporaryProxySublayer.nodes &temporaryProxySublayerNodes

                                for a in temporaryProxySublayerNodes do(
                                    selectmore a

                                    (LayerManager.getLayerFromName "0").addnode a
                                )

                                -- Group objects(s) (Note: the fact that even single objects get grouped is deliberate, as this is used later in the script)

                                    group selection name:(catergoryName + ", " + volumeName + ", " + newFileName)

                            -- Increment currentFileToSaveCount variable

                                currentFileToSaveCount = (currentFileToSaveCount + 1)
                        )
                    )

                    DialogMonitorOPS.Enabled = false
                    DialogMonitorOPS.unRegisterNotification id:#autoRaname
            )

        -- Move objects incrementally

            fn callisScriptsMoveIncrementally distanceToMove = (
                -- Variables

                    local mySelection = getCurrentSelection()

                for myNum = 1 to mySelection.count do(
                    (selection[myNum]).pos = [(myNum*distanceToMove),0,0]
                )
            )

    -- Functions

        fn callisScriptsProcessAssetsForConnecterFunction folderPathContainingOriginalFiles destinationFolderRoot useOriginalVolumeNameAsSuffixBooleanArray volumeNameSuffixStringArray fileNameExtraTextStringArray keywordFilterStringArray convertSceneToVrayOrCoronaBooleanArray saveEachObjectSeparatelyBooleanArray attachObjectsBooleanArray proxyObjectsBooleanArray previewFacesNumberArray coronaBooleanArray includeCamerasBooleanArray includeLightsBooleanArray replaceAllTextBooleanArray retainSpecifiedTextFromFileNameBooleanArray retainSpecifiedTextFromObjectNameBooleanArray retainAllTextFromFileNameBooleanArray phraseToSplitWithStringArray numberOfIndicesToRemoveFromStartIntegerArray numberOfIndicesToRemoveFromEndIntegerArray layerToMoveObjectsToStringArray relinkMapsBooleanArray = (
            -- Variables

                -- Adding space to suffixes if relevant

                    -- Volume

                        for i = 1 to volumeNameSuffixStringArray.count do(
                            if volumeNameSuffixStringArray[i] != undefined and volumeNameSuffixStringArray[i] != "" and volumeNameSuffixStringArray[i] != " " then(
                                if volumeNameSuffixStringArray[i][1] != " " then(
                                    insertItem (" " + volumeNameSuffixStringArray[i]) volumeNameSuffixStringArray (i + 1)

                                    deleteItem volumeNameSuffixStringArray i
                                )
                            )else(
                                insertItem ("") volumeNameSuffixStringArray (i + 1)

                                deleteItem volumeNameSuffixStringArray i
                            )
                        )

                    -- File

                        for i = 1 to fileNameExtraTextStringArray.count do(
                            if fileNameExtraTextStringArray[i] != undefined and fileNameExtraTextStringArray[i] != "" and fileNameExtraTextStringArray[i] != " " then(
                                if fileNameExtraTextStringArray[i][1] != " " then(
                                    insertItem (" " + fileNameExtraTextStringArray[i]) fileNameExtraTextStringArray (i + 1)

                                    deleteItem fileNameExtraTextStringArray i
                                )
                            )else(
                                insertItem ("") fileNameExtraTextStringArray (i + 1)

                                deleteItem fileNameExtraTextStringArray i
                            )
                        )

                -- Defining variables for ensuring volume naming in the destination folder is in order

                    -- Variables

                        local hi = ""
                        local bye = ""
                        local nonFolderFilesArePresentInDestinationFolder = false

                    if (getDirectories (destinationFolderRoot + "/*")).count > 0 then(
                        -- Ensuring last file's name matches number of files

                            local hiPreliminary1 = ((getDirectories (destinationFolderRoot + "/*")).count)

                            if hiPreliminary1 < 10000 then(
                                hi = (hiPreliminary1 as string)
                            )

                            if hiPreliminary1 < 1000 then(
                                hi = (hiPreliminary1 as string)
                            )

                            if hiPreliminary1 < 100 then(
                                hi = ("0" + (hiPreliminary1 as string))
                            )

                            if hiPreliminary1 < 10 then(
                                hi = ("00" + (hiPreliminary1 as string))
                            )

                            local byePreliminary2 = (((getDirectories (destinationFolderRoot + "/*"))[(getDirectories (destinationFolderRoot + "/*")).count]) as string)
                            local byePreliminary1 = filterString byePreliminary2 "\\"
                            bye = byePreliminary1[byePreliminary1.count]

                        -- Ensuring only folders are present

                            for a in (getDirectories (destinationFolderRoot + "/*")) do(
                                hiPreliminary1 = filterString a "\\"
                                hi = hiPreliminary1[hiPreliminary1.count]

                                if matchPattern hi Pattern:"*.*" then(
                                    nonFolderFilesArePresentInDestinationFolder = true
                                )
                            )
                    )

            if (matchpattern hi Pattern:bye and nonFolderFilesArePresentInDestinationFolder == false) then(
                -- Print "Not done"

                    print "Not done"

                for currentInteger = 1 to ((getDirectories (folderPathContainingOriginalFiles + "\\*")).count) do(
                    -- Make subfolders

                        -- Variables

                            currentOriginalFolder = ((getDirectories (folderPathContainingOriginalFiles + "\\*"))[currentInteger])

                            endOfRootDirPreliminary2 = filterString (currentOriginalFolder as string) "\\"
                            endOfRootDir = endOfRootDirPreliminary2[endOfRootDirPreliminary2.count]

                            -- Define volumeNumber variable

                                local volumeNumberPreliminary1 = (((getDirectories (destinationFolderRoot + "\\*")).count) + 1)

                                if volumeNumberPreliminary1 < 1000 then(
                                    local volumeNumber = (volumeNumberPreliminary1 as string)
                                )

                                if volumeNumberPreliminary1 < 100 then(
                                    local volumeNumber = ("0" + (volumeNumberPreliminary1 as string))
                                )

                                if volumeNumberPreliminary1 < 10 then(
                                    local volumeNumber = ("00" + (volumeNumberPreliminary1 as string))
                                )

                                if useOriginalVolumeNameAsSuffixBoolean == false then(
                                    destinationFolder = (destinationFolderRoot + "\\" + volumeNumber + volumeNameSuffixString)
                                )else(
                                    destinationFolder = (destinationFolderRoot + "\\" + volumeNumber + " " + endOfRootDir)
                                )

                        -- Make subfolders

                            makeDir (destinationFolder + "/" + "Proxies")

                            makeDir (destinationFolder + "/" + "Scenes")

                            makeDir (destinationFolder + "/" + "Previews")

                            makeDir (destinationFolder + "/" + "Maps")

                    -- Variables

                        -- Isolating relevant array items

                            local useOriginalVolumeNameAsSuffixBoolean = useOriginalVolumeNameAsSuffixBooleanArray[currentInteger]
                            local volumeNameSuffixString = volumeNameSuffixStringArray[currentInteger]
                            local fileNameExtraTextString = fileNameExtraTextStringArray[currentInteger]
                            local keywordFilterString = keywordFilterStringArray[currentInteger]
                            local convertSceneToVrayOrCoronaBoolean = convertSceneToVrayOrCoronaBooleanArray[currentInteger]
                            local saveEachObjectSeparatelyBoolean = saveEachObjectSeparatelyBooleanArray[currentInteger]
                            local attachObjectsBoolean = attachObjectsBooleanArray[currentInteger]
                            local proxyObjectsBoolean = proxyObjectsBooleanArray[currentInteger]
                            local previewFacesNumber = previewFacesNumberArray[currentInteger]
                            local coronaBoolean = coronaBooleanArray[currentInteger]
                            local includeCamerasBoolean = includeCamerasBooleanArray[currentInteger]
                            local includeLightsBoolean = includeLightsBooleanArray[currentInteger]
                            local replaceAllTextBoolean = replaceAllTextBooleanArray[currentInteger]
                            local retainSpecifiedTextFromFileNameBoolean = retainSpecifiedTextFromFileNameBooleanArray[currentInteger]
                            local retainSpecifiedTextFromObjectNameBoolean = retainSpecifiedTextFromObjectNameBooleanArray[currentInteger]
                            local retainAllTextFromFileNameBoolean = retainAllTextFromFileNameBooleanArray[currentInteger]
                            local phraseToSplitWithString = phraseToSplitWithStringArray[currentInteger]
                            local numberOfIndicesToRemoveFromStartInteger = numberOfIndicesToRemoveFromStartIntegerArray[currentInteger]
                            local numberOfIndicesToRemoveFromEndInteger = numberOfIndicesToRemoveFromEndIntegerArray[currentInteger]
                            local layerToMoveObjectsToString = layerToMoveObjectsToStringArray[currentInteger]
                            local relinkMapsBoolean = relinkMapsBooleanArray[currentInteger]

                        -- Everything else

                            local newScenesPath = destinationFolder + "\\Scenes"
                            local proxiesPath = destinationFolder + "\\Proxies"
                            local mapsPath = destinationFolder + "\\Maps"
                            local volumeName = (filterString destinationFolder "\\")[(filterString destinationFolder "\\").count]
                            local catergoryName = (filterString destinationFolder "\\")[(filterString destinationFolder "\\").count - 1]
                            local oldPreviewsPath = undefined
                            local oldScenesPath = undefined
                            local oldMapsPath = undefined
                            local oldIESPath = undefined
                            local oldProxiesPath = undefined
                            local previewFacesNumberAsInteger = (previewFacesNumber as integer)
                            local lastThreeCharOfObjNamePreliminary = undefined
                            local lastThreeCharOfObjName = undefined
                            local myPreviewFilePreliminary = undefined
                            local myPreviewFile = undefined
                            local myIESFiles = undefined
                            local myProxyFiles = undefined
                            local newPreviewsPath = destinationFolder + "/Previews"
                            local mySelection = undefined
                            local myMapFiles = undefined
                            local currentMapName = undefined
                            local currentMapType = undefined

                        -- Define old paths variables

                            for i in getDirectories (currentOriginalFolder + "/*") do(
                                endOfDirPreliminary = filterString (i as string) "\\"
                                endOfDir = endOfDirPreliminary[endOfDirPreliminary.count]

                                if matchPattern endOfDir Pattern: ("*Preview*") or matchPattern endOfDir Pattern: ("*preview*") or matchPattern endOfDir Pattern: ("*Render*") or matchPattern endOfDir Pattern: ("*render*") then(
                                    oldPreviewsPath = (i as string) -- Note: this will end in \
                                )

                                if matchPattern endOfDir Pattern: ("*Maps*") or matchPattern endOfDir Pattern: ("*maps*") or matchPattern endOfDir Pattern: ("*extu*") then(
                                    oldMapsPath = (i as string) -- Note: this will end in \
                                )

                                if matchPattern endOfDir Pattern: ("*Scenes*") or matchPattern endOfDir Pattern: ("*scenes*") then(
                                    oldScenesPath = (i as string) -- Note: this will end in \
                                )

                                if (matchPattern endOfDir Pattern: ("*IES*") or matchPattern endOfDir Pattern: ("*ies*")) and not matchPattern endOfDir Pattern: ("*XIES*") and not matchPattern endOfDir Pattern: ("*xies*")then(
                                    oldIESPath = (i as string) -- Note: this will end in \
                                )

                                if (matchPattern endOfDir Pattern: ("*prox*") or matchPattern endOfDir Pattern: ("*Prox*")) or matchPattern endOfDir Pattern: ("*PROX*") then(
                                    oldProxiesPath = (i as string) -- Note: this will end in \
                                )
                            )

                    -- Add volume number and spacer to failed objects text

                        append callisScriptsAssetOrganisationFailedObjects ((volumeNumber as string) + "\n\n")

                    -- Delete everything in the scene

                        -- Unhide and unfreeze all layers

                            for i = 0 to LayerManager.count-1 do(
                      			     (LayerManager.getLayer i).isHidden = off
                            )

                            for i = 0 to LayerManager.count-1 do(
                      			     (LayerManager.getLayer i).isFrozen = off
                            )

                        max unhide all

                        max select all

                        max delete

                    -- Create temporary layers

                        LayerManager.newLayerFromName "Callis Scripts Temporary Proxy Layer"

                        LayerManager.newLayerFromName "Callis Scripts Temporary Proxy Sublayer"

                    -- Merge all the files in and proxy if relevant

                        mergeAllFiles oldScenesPath volumeNumber proxiesPath volumeName catergoryName volumeNameSuffixString fileNameExtraTextString keywordFilterString includeCamerasBoolean includeLightsBoolean saveEachObjectSeparatelyBoolean attachObjectsBoolean proxyObjectsBoolean coronaBoolean replaceAllTextBoolean retainSpecifiedTextFromFileNameBoolean retainSpecifiedTextFromObjectNameBoolean retainAllTextFromFileNameBoolean phraseToSplitWithString numberOfIndicesToRemoveFromStartInteger numberOfIndicesToRemoveFromEndInteger

                        -- Delete any unwanted objects

                            for o in callisScriptsAssetOrganisationObjectsToDelete do(
                                try(
                                    select o

                                    max delete
                                )catch()
                            )

                    -- Place pivots at bottom

                        max select all

                        pivotPlacer 15 1 true 1

                    -- Move everything to centre

                        max select all

                        for i in selection where (isGroupHead i) do(
                            i.pos = [0,0,0]
                        )

                    -- Deal with any assets

                        -- Relocate maps

                            if oldMapsPath != undefined then(
                                myMapFiles = getFiles (oldMapsPath + "*")

                                for a in myMapFiles do(
                                    currentMapName = getFilenameFile a
                                    currentMapType = getFilenameType a

                                    copyFile a (mapsPath + "\\" + currentMapName + currentMapType)
                                )
                            )

                        -- Relocate IES files

                            if oldIESPath != undefined then(
                                myIESFiles = getFiles (oldIESPath + "*")

                                for a in myIESFiles do(
                                    currentMapName = getFilenameFile a
                                    currentMapType = getFilenameType a

                                    copyFile a (mapsPath + "\\" + currentMapName + currentMapType)
                                )
                            )

                        -- Relocate proxies

                            if oldProxiesPath != undefined then(
                                myProxyFiles = getFiles (oldproxiesPath + "*")

                                for a in myProxyFiles do(
                                    currentMapName = getFilenameFile a
                                    currentMapType = getFilenameType a

                                    copyFile a (proxiesPath + "\\" + currentMapName + currentMapType)
                                )
                            )

                        -- Repath textures

                            if relinkMapsBoolean == true then(
                                try(
                                    local aBmaps = getClassInstances BitmapTexture

                                    for Bmap in aBmaps do (
                                        local sFilename = Bmap.filename
                                        local sPath = getFilenamePath sFilename
                                        local sFile = getFilenameFile sFilename

                                        Bmap.filename = mapsPath + "\\" + sFile + (getFilenameType sFilename)
                                    )
                                )catch()

                                try(
                                    local cMaps = getClassInstances coronaBitmap

                                    for Bmap in cMaps do (
                                        sFilename = Bmap.filename
                                        sPath = getFilenamePath sFilename
                                        sFile = getFilenameFile sFilename

                                        Bmap.filename = mapsPath + "\\" + sFile + (getFilenameType sFilename)
                                    )
                                )catch()
                            )

                        -- Repath IES files

                            if relinkMapsBoolean == true then(
                                for obj in lights where iskindof obj light do(
                                    if classof obj==VRayIES then(
                                        local IESFileNamePreliminary = obj.ies_File
                                        local IESFileName = getFileNameFile IESFileNamePreliminary

                                        copyFile (IESFileNamePreliminary) (mapsPath + "/" + IESFileName + ".ies")

                                        obj.ies_File = mapsPath + "\\" + IESFileName + ".ies"
                                    )
                                )
                            )

                        -- Repath proxies

                            for obj in geometry where iskindof obj vrayProxy do(
                                local proxyFileNamePreliminary = obj.fileName
                                local proxyFileName = getFileNameFile proxyFileNamePreliminary

                                obj.fileName = proxiesPath + "\\" + proxyFileName + ".vrmesh"
                            )

                            for obj in geometry where iskindof obj CProxy do(
                                local proxyFileNamePreliminary = obj.fileName
                                local proxyFileName = getFileNameFile proxyFileNamePreliminary

                                obj.fileName = proxiesPath + "\\" + proxyFileName + ".cgeo"
                            )

                    -- Convert scene to Vray or Corona if relevant

                        if convertSceneToVrayOrCoronaBoolean == true then(
                            if coronaBoolean == false then(
                                macros.run "VRay" "VRaySceneConverter"
                            )else(
                                macros.run "Corona Renderer" "CoronaConverter"
                            )
                        )

                    -- Relocate previews

                        if oldPreviewsPath != undefined then(
                            -- Variables

                                local oldPreviewFiles = getFiles (oldPreviewsPath + "*")
                                local groups = for o in helpers where isGroupHead o collect o

                                for a = 1 to oldPreviewFiles.count do(
                                    if matchPattern oldPreviewFiles[a] Pattern:"*humbs.db" then(
                                        deleteItem oldPreviewFiles a
                                    )
                                )

                            for a = 1 to oldPreviewFiles.count do(
                                if a <= groups.count then(
                                    -- Variables etc.

                                        b = oldPreviewFiles[a]
                                        c = groups[a]

                                        cName = c.name
                                        local nameForNewFilePreliminary = (filterString cName ",")[(filterString cName ",").count]
                                        local nameForNewFile = (substituteString nameForNewFilePreliminary "  " " ")

                                    if matchPattern (b as string) Pattern:"*.jpg" or matchPattern (myPreviewFile as string) Pattern:"*.JPG" or matchPattern (myPreviewFile as string) Pattern:"*.jpeg" or matchPattern (myPreviewFile as string) Pattern:"*.JPEG" then(
                                        copyFile (b) (newPreviewsPath + "/" + catergoryName + ", " + (volumeNumber as string) + "," + nameForNewFile + ".jpg")
                                    )

                                    if matchPattern (myPreviewFile as string) Pattern:"*.tif" or matchPattern (myPreviewFile as string) Pattern:"*.TIF" then(
                                        copyFile (myPreviewFile) (newPreviewsPath + "/" + catergoryName + ", " + (volumeNumber as string) + "," + nameForNewFile + ".tif")
                                    )

                                    if matchPattern (myPreviewFile as string) Pattern:"*.exr" or matchPattern (myPreviewFile as string) Pattern:"*.EXR" then(
                                        copyFile (myPreviewFile) (newPreviewsPath + "/" + catergoryName + ", " + (volumeNumber as string) + "," + nameForNewFile + ".exr")
                                    )

                                    if matchPattern (myPreviewFile as string) Pattern:"*.hdr" or matchPattern (myPreviewFile as string) Pattern:"*.HDR" then(
                                        copyFile (myPreviewFile) (newPreviewsPath + "/" + catergoryName + ", " + (volumeNumber as string) + "," + nameForNewFile + ".hdr")
                                    )
                                )
                            )
                        )else(
                            print "Original previews path was undefined"
                        )

                    -- Remove temporary layers

                        try(
                            LayerManager.deleteLayerByName "Callis Scripts Temporary Proxy Layer"

                            LayerManager.deleteLayerByName "Callis Scripts Temporary Proxy Sublayer"
                        )catch()

                    -- Remove any other empty layers

                        try(
                            macros.run "Scene Explorer" "SERemoveEmptyLayers"
                        )catch()

                        try(
                            macros.run "Scene Explorer" "SERemoveEmptyLayers"

                            macros.run "Scene Explorer" "SERemoveEmptyLayers"

                            macros.run "Scene Explorer" "SERemoveEmptyLayers"
                        )catch()

                    -- Create layer (or layer structure) based on user's input if relevant

                        if layerToMoveObjectsToString != "" then(
                            local currentLayerStructureNameArray = (filterString layerToMoveObjectsToString ">")

                            local previousLayerNameInStructure

                            for i = 1 to (currentLayerStructureNameArray.count) do(
                                LayerManager.newLayerFromName currentLayerStructureNameArray[i]

                                if i > 1 then(
                                    (LayerManager.getLayerFromName currentLayerStructureNameArray[i]).setParent (LayerManager.getLayerFromName previousLayerNameInStructure)
                                )

                                previousLayerNameInStructure = currentLayerStructureNameArray[i]
                            )
                        )

                    -- Layer and save everything

                        groups = for o in helpers where isGroupHead o collect o

                        for a = 1 to groups.count do(

                            b = groups[a]

                            bName = b.name

                            select b

                            nameForNewFilePreliminary = (filterString bName ",")[(filterString bName ",").count]
                            nameForNewFile = (substituteString nameForNewFilePreliminary "  " " ")
                            local f = newScenesPath + "/" + catergoryName + ", " + (volumeNumber as string) + "," + nameForNewFile + ".max"

                            -- Create layer to go within the bottommost layer just created named after the scene of this/these object(s)

                                LayerManager.newLayerFromName (catergoryName + ", " + (volumeNumber as string) + "," + nameForNewFile)

                                -- Layer the new layer based on the user's input

                                    if layerToMoveObjectsToString != "" then(
                                        (LayerManager.getLayerFromName (catergoryName + ", " + (volumeNumber as string) + "," + nameForNewFile)).setParent (LayerManager.getLayerFromName (currentLayerStructureNameArray[currentLayerStructureNameArray.count]))
                                    )else(
                                        (LayerManager.getLayerFromName (catergoryName + ", " + (volumeNumber as string) + "," + nameForNewFile)).setParent (LayerManager.getLayerFromName "0")
                                    )

                            max group ungroup

                            -- Ensure pivots are placed at bottom

                                pivotPlacer 15 1 true 1

                            -- Move all objects to correct layer

                                local currentLayer = (layermanager.getLayerFromName (catergoryName + ", " + (volumeNumber as string) + "," + nameForNewFile))

                                for i in selection do(
                                    currentLayer.addNode i
                                )

                            if selection.count > 1 then(
                                group selection name:bName

                                saveNodes selection f quiet:true

                                if not doesFileExist(f) then(
                                    saveNodes selection f quiet:true

                                    if not doesFileExist(f) then(
                                        saveNodes selection f quiet:true

                                        if not doesFileExist(f) then(
                                            saveNodes selection f quiet:true

                                            if not doesFileExist(f) then(
                                                saveNodes selection f quiet:true

                                                if not doesFileExist(f) then(
                                                    saveNodes selection f quiet:true

                                                    if not doesFileExist(f) then(
                                                        saveNodes selection f quiet:true

                                                        if not doesFileExist(f) then(
                                                            saveNodes selection f quiet:true

                                                            if not doesFileExist(f) then(
                                                                saveNodes selection f quiet:true

                                                                if not doesFileExist(f) then(
                                                                    saveNodes selection f quiet:true

                                                                    if not doesFileExist(f) then(
                                                                        saveNodes selection f quiet:true

                                                                        if not doesFileExist(f) then(
                                                                            saveNodes selection f quiet:true

                                                                            if not doesFileExist(f) then(
                                                                                saveNodes selection f quiet:true

                                                                                if not doesFileExist(f) then(
                                                                                    saveNodes selection f quiet:true

                                                                                    if not doesFileExist(f) then(
                                                                                        saveNodes selection f quiet:true
                                                                                    )
                                                                                )
                                                                            )
                                                                        )
                                                                    )
                                                                )
                                                            )
                                                        )
                                                    )
                                                )
                                            )
                                        )
                                    )
                                )
                            )else(
                                $.name = bName

                                saveNodes selection f quiet:true

                                if not doesFileExist(f) then(
                                    saveNodes selection f quiet:true

                                    if not doesFileExist(f) then(
                                        saveNodes selection f quiet:true

                                        if not doesFileExist(f) then(
                                            saveNodes selection f quiet:true

                                            if not doesFileExist(f) then(
                                                saveNodes selection f quiet:true

                                                if not doesFileExist(f) then(
                                                    saveNodes selection f quiet:true

                                                    if not doesFileExist(f) then(
                                                        saveNodes selection f quiet:true

                                                        if not doesFileExist(f) then(
                                                            saveNodes selection f quiet:true

                                                            if not doesFileExist(f) then(
                                                                saveNodes selection f quiet:true

                                                                if not doesFileExist(f) then(
                                                                    saveNodes selection f quiet:true

                                                                    if not doesFileExist(f) then(
                                                                        saveNodes selection f quiet:true

                                                                        if not doesFileExist(f) then(
                                                                            saveNodes selection f quiet:true

                                                                            if not doesFileExist(f) then(
                                                                                saveNodes selection f quiet:true

                                                                                if not doesFileExist(f) then(
                                                                                    saveNodes selection f quiet:true
                                                                                )
                                                                            )
                                                                        )
                                                                    )
                                                                )
                                                            )
                                                        )
                                                    )
                                                )
                                            )
                                        )
                                    )
                                )
                            )
                        )

                    -- Delete all scene objects

                        max unhide all

                        max select all

                        max delete

                    -- Add spacer to failed objects text, or remove the current volume number if none of its objects failed

                        if callisScriptsAssetOrganisationFailedObjects[callisScriptsAssetOrganisationFailedObjects.count] == ((volumeNumber as string) + "\n\n") then(
                            deleteItem callisScriptsAssetOrganisationFailedObjects callisScriptsAssetOrganisationFailedObjects.count
                        )else(
                            append callisScriptsAssetOrganisationFailedObjects ("\n\n")
                        )
                )

                -- Alert if errors

                    if callisScriptsAssetOrganisationFailedObjects.count > 0 then(
                        local errorMessageAsString = ""
                        local newErrorMessageAsString

                        for a in callisScriptsAssetOrganisationFailedObjects do(
                            newErrorMessageAsString = errorMessageAsString + a + "\n"

                            errorMessageAsString = newErrorMessageAsString
                        )

                        local realErrorMessageAsString = "Sorry - these objects (and all other objects from their files) could not be processed and must be processed manually:\n\n" + errorMessageAsString

                        MessageBox (realErrorMessageAsString)
                    )

                -- Print "Done"

                    print "Done"
            )else(
                MessageBox "Please ensure the destination folder contains only volume folders, and that there are no gaps in the volumes' numbering"
            )
        )

-- Rollout

    rollout callisScriptsProcessAssetsForConnecterRollout("Process Assets For Connecter")(
        -- Variables

            -- Main

                -- Arrays

                    local useOriginalVolumeNameAsSuffixBooleanArray = #()
                    local volumeNameSuffixStringArray = #()
                    local fileNameExtraTextStringArray = #()
                    local keywordFilterStringArray = #()
                    local convertSceneToVrayOrCoronaBooleanArray = #()
                    local saveEachObjectSeparatelyBooleanArray = #()
                    local attachObjectsBooleanArray = #()
                    local proxyObjectsBooleanArray = #()
                    local facesNumberIntegerArray = #()
                    local coronaBooleanArray = #()
                    local includeCamerasBooleanArray = #()
                    local includeLightsBooleanArray = #()
                    local replaceAllTextBooleanArray = #()
                    local retainSpecifiedTextFromFileNameBooleanArray = #()
                    local retainSpecifiedTextFromObjectNameBooleanArray = #()
                    local retainAllTextFromFileNameBooleanArray = #()
                    local phraseToSplitWithStringArray = #()
                    local numberOfIndicesToRemoveFromStartIntegerArray = #()
                    local numberOfIndicesToRemoveFromEndIntegerArray = #()
                    local layerToMoveObjectsToStringArray = #()
                    local relinkMapsBooleanArray = #()

                -- File Locations

                    local originalFolderPathText
                    local destinationFolderText

                -- Volume to configure

                    local listOfOriginalVolumeNames
                    local currentVolumeDropDownListSelectionInteger = 1
                    local volumeToConfigureDropDownListEnabled = false

                -- Naming

                    -- useOriginalVolumeNameAsSuffixBoolean

                        local useOriginalVolumeNameAsSuffixBoolean1 = true
                        local useOriginalVolumeNameAsSuffixBoolean2 = true
                        local useOriginalVolumeNameAsSuffixBoolean3 = true
                        local useOriginalVolumeNameAsSuffixBoolean4 = true
                        local useOriginalVolumeNameAsSuffixBoolean5 = true
                        local useOriginalVolumeNameAsSuffixBoolean6 = true
                        local useOriginalVolumeNameAsSuffixBoolean7 = true
                        local useOriginalVolumeNameAsSuffixBoolean8 = true
                        local useOriginalVolumeNameAsSuffixBoolean9 = true
                        local useOriginalVolumeNameAsSuffixBoolean10 = true
                        local useOriginalVolumeNameAsSuffixBoolean11 = true
                        local useOriginalVolumeNameAsSuffixBoolean12 = true
                        local useOriginalVolumeNameAsSuffixBoolean13 = true
                        local useOriginalVolumeNameAsSuffixBoolean14 = true
                        local useOriginalVolumeNameAsSuffixBoolean15 = true
                        local useOriginalVolumeNameAsSuffixBoolean16 = true
                        local useOriginalVolumeNameAsSuffixBoolean17 = true
                        local useOriginalVolumeNameAsSuffixBoolean18 = true
                        local useOriginalVolumeNameAsSuffixBoolean19 = true
                        local useOriginalVolumeNameAsSuffixBoolean20 = true

                        local useOriginalVolumeNameAsSuffixCheckBoxEnabled1 = false
                        local useOriginalVolumeNameAsSuffixCheckBoxEnabled2 = false
                        local useOriginalVolumeNameAsSuffixCheckBoxEnabled3 = false
                        local useOriginalVolumeNameAsSuffixCheckBoxEnabled4 = false
                        local useOriginalVolumeNameAsSuffixCheckBoxEnabled5 = false
                        local useOriginalVolumeNameAsSuffixCheckBoxEnabled6 = false
                        local useOriginalVolumeNameAsSuffixCheckBoxEnabled7 = false
                        local useOriginalVolumeNameAsSuffixCheckBoxEnabled8 = false
                        local useOriginalVolumeNameAsSuffixCheckBoxEnabled9 = false
                        local useOriginalVolumeNameAsSuffixCheckBoxEnabled10 = false
                        local useOriginalVolumeNameAsSuffixCheckBoxEnabled11 = false
                        local useOriginalVolumeNameAsSuffixCheckBoxEnabled12 = false
                        local useOriginalVolumeNameAsSuffixCheckBoxEnabled13 = false
                        local useOriginalVolumeNameAsSuffixCheckBoxEnabled14 = false
                        local useOriginalVolumeNameAsSuffixCheckBoxEnabled15 = false
                        local useOriginalVolumeNameAsSuffixCheckBoxEnabled16 = false
                        local useOriginalVolumeNameAsSuffixCheckBoxEnabled17 = false
                        local useOriginalVolumeNameAsSuffixCheckBoxEnabled18 = false
                        local useOriginalVolumeNameAsSuffixCheckBoxEnabled19 = false
                        local useOriginalVolumeNameAsSuffixCheckBoxEnabled20 = false

                    -- volumeNameSuffixString

                        local volumeNameSuffixString1 = ""
                        local volumeNameSuffixString2 = ""
                        local volumeNameSuffixString3 = ""
                        local volumeNameSuffixString4 = ""
                        local volumeNameSuffixString5 = ""
                        local volumeNameSuffixString6 = ""
                        local volumeNameSuffixString7 = ""
                        local volumeNameSuffixString8 = ""
                        local volumeNameSuffixString9 = ""
                        local volumeNameSuffixString10 = ""
                        local volumeNameSuffixString11 = ""
                        local volumeNameSuffixString12 = ""
                        local volumeNameSuffixString13 = ""
                        local volumeNameSuffixString14 = ""
                        local volumeNameSuffixString15 = ""
                        local volumeNameSuffixString16 = ""
                        local volumeNameSuffixString17 = ""
                        local volumeNameSuffixString18 = ""
                        local volumeNameSuffixString19 = ""
                        local volumeNameSuffixString20 = ""

                        local volumeNameSuffixEditTextEnabled1 = false
                        local volumeNameSuffixEditTextEnabled2 = false
                        local volumeNameSuffixEditTextEnabled3 = false
                        local volumeNameSuffixEditTextEnabled4 = false
                        local volumeNameSuffixEditTextEnabled5 = false
                        local volumeNameSuffixEditTextEnabled6 = false
                        local volumeNameSuffixEditTextEnabled7 = false
                        local volumeNameSuffixEditTextEnabled8 = false
                        local volumeNameSuffixEditTextEnabled9 = false
                        local volumeNameSuffixEditTextEnabled10 = false
                        local volumeNameSuffixEditTextEnabled11 = false
                        local volumeNameSuffixEditTextEnabled12 = false
                        local volumeNameSuffixEditTextEnabled13 = false
                        local volumeNameSuffixEditTextEnabled14 = false
                        local volumeNameSuffixEditTextEnabled15 = false
                        local volumeNameSuffixEditTextEnabled16 = false
                        local volumeNameSuffixEditTextEnabled17 = false
                        local volumeNameSuffixEditTextEnabled18 = false
                        local volumeNameSuffixEditTextEnabled19 = false
                        local volumeNameSuffixEditTextEnabled20 = false

                    -- fileNameExtraTextString

                        local fileNameExtraTextString1 = ""
                        local fileNameExtraTextString2 = ""
                        local fileNameExtraTextString3 = ""
                        local fileNameExtraTextString4 = ""
                        local fileNameExtraTextString5 = ""
                        local fileNameExtraTextString6 = ""
                        local fileNameExtraTextString7 = ""
                        local fileNameExtraTextString8 = ""
                        local fileNameExtraTextString9 = ""
                        local fileNameExtraTextString10 = ""
                        local fileNameExtraTextString11 = ""
                        local fileNameExtraTextString12 = ""
                        local fileNameExtraTextString13 = ""
                        local fileNameExtraTextString14 = ""
                        local fileNameExtraTextString15 = ""
                        local fileNameExtraTextString16 = ""
                        local fileNameExtraTextString17 = ""
                        local fileNameExtraTextString18 = ""
                        local fileNameExtraTextString19 = ""
                        local fileNameExtraTextString20 = ""

                        local fileNameExtraTextEditTextEnabled1 = false
                        local fileNameExtraTextEditTextEnabled2 = false
                        local fileNameExtraTextEditTextEnabled3 = false
                        local fileNameExtraTextEditTextEnabled4 = false
                        local fileNameExtraTextEditTextEnabled5 = false
                        local fileNameExtraTextEditTextEnabled6 = false
                        local fileNameExtraTextEditTextEnabled7 = false
                        local fileNameExtraTextEditTextEnabled8 = false
                        local fileNameExtraTextEditTextEnabled9 = false
                        local fileNameExtraTextEditTextEnabled10 = false
                        local fileNameExtraTextEditTextEnabled11 = false
                        local fileNameExtraTextEditTextEnabled12 = false
                        local fileNameExtraTextEditTextEnabled13 = false
                        local fileNameExtraTextEditTextEnabled14 = false
                        local fileNameExtraTextEditTextEnabled15 = false
                        local fileNameExtraTextEditTextEnabled16 = false
                        local fileNameExtraTextEditTextEnabled17 = false
                        local fileNameExtraTextEditTextEnabled18 = false
                        local fileNameExtraTextEditTextEnabled19 = false
                        local fileNameExtraTextEditTextEnabled20 = false

                    -- keywordFilterString

                        local keywordFilterString1 = ""
                        local keywordFilterString2 = ""
                        local keywordFilterString3 = ""
                        local keywordFilterString4 = ""
                        local keywordFilterString5 = ""
                        local keywordFilterString6 = ""
                        local keywordFilterString7 = ""
                        local keywordFilterString8 = ""
                        local keywordFilterString9 = ""
                        local keywordFilterString10 = ""
                        local keywordFilterString11 = ""
                        local keywordFilterString12 = ""
                        local keywordFilterString13 = ""
                        local keywordFilterString14 = ""
                        local keywordFilterString15 = ""
                        local keywordFilterString16 = ""
                        local keywordFilterString17 = ""
                        local keywordFilterString18 = ""
                        local keywordFilterString19 = ""
                        local keywordFilterString20 = ""

                        local keywordFilterEditTextEnabled1 = false
                        local keywordFilterEditTextEnabled2 = false
                        local keywordFilterEditTextEnabled3 = false
                        local keywordFilterEditTextEnabled4 = false
                        local keywordFilterEditTextEnabled5 = false
                        local keywordFilterEditTextEnabled6 = false
                        local keywordFilterEditTextEnabled7 = false
                        local keywordFilterEditTextEnabled8 = false
                        local keywordFilterEditTextEnabled9 = false
                        local keywordFilterEditTextEnabled10 = false
                        local keywordFilterEditTextEnabled11 = false
                        local keywordFilterEditTextEnabled12 = false
                        local keywordFilterEditTextEnabled13 = false
                        local keywordFilterEditTextEnabled14 = false
                        local keywordFilterEditTextEnabled15 = false
                        local keywordFilterEditTextEnabled16 = false
                        local keywordFilterEditTextEnabled17 = false
                        local keywordFilterEditTextEnabled18 = false
                        local keywordFilterEditTextEnabled19 = false
                        local keywordFilterEditTextEnabled20 = false

                -- Convert scene to Vray or Corona

                    local convertSceneToVrayOrCoronaBoolean1 = false
                    local convertSceneToVrayOrCoronaBoolean2 = false
                    local convertSceneToVrayOrCoronaBoolean3 = false
                    local convertSceneToVrayOrCoronaBoolean4 = false
                    local convertSceneToVrayOrCoronaBoolean5 = false
                    local convertSceneToVrayOrCoronaBoolean6 = false
                    local convertSceneToVrayOrCoronaBoolean7 = false
                    local convertSceneToVrayOrCoronaBoolean8 = false
                    local convertSceneToVrayOrCoronaBoolean9 = false
                    local convertSceneToVrayOrCoronaBoolean10 = false
                    local convertSceneToVrayOrCoronaBoolean11 = false
                    local convertSceneToVrayOrCoronaBoolean12 = false
                    local convertSceneToVrayOrCoronaBoolean13 = false
                    local convertSceneToVrayOrCoronaBoolean14 = false
                    local convertSceneToVrayOrCoronaBoolean15 = false
                    local convertSceneToVrayOrCoronaBoolean16 = false
                    local convertSceneToVrayOrCoronaBoolean17 = false
                    local convertSceneToVrayOrCoronaBoolean18 = false
                    local convertSceneToVrayOrCoronaBoolean19 = false
                    local convertSceneToVrayOrCoronaBoolean20 = false

                    local convertSceneToVrayOrCoronaCheckBoxEnabled1 = false
                    local convertSceneToVrayOrCoronaCheckBoxEnabled2 = false
                    local convertSceneToVrayOrCoronaCheckBoxEnabled3 = false
                    local convertSceneToVrayOrCoronaCheckBoxEnabled4 = false
                    local convertSceneToVrayOrCoronaCheckBoxEnabled5 = false
                    local convertSceneToVrayOrCoronaCheckBoxEnabled6 = false
                    local convertSceneToVrayOrCoronaCheckBoxEnabled7 = false
                    local convertSceneToVrayOrCoronaCheckBoxEnabled8 = false
                    local convertSceneToVrayOrCoronaCheckBoxEnabled9 = false
                    local convertSceneToVrayOrCoronaCheckBoxEnabled10 = false
                    local convertSceneToVrayOrCoronaCheckBoxEnabled11 = false
                    local convertSceneToVrayOrCoronaCheckBoxEnabled12 = false
                    local convertSceneToVrayOrCoronaCheckBoxEnabled13 = false
                    local convertSceneToVrayOrCoronaCheckBoxEnabled14 = false
                    local convertSceneToVrayOrCoronaCheckBoxEnabled15 = false
                    local convertSceneToVrayOrCoronaCheckBoxEnabled16 = false
                    local convertSceneToVrayOrCoronaCheckBoxEnabled17 = false
                    local convertSceneToVrayOrCoronaCheckBoxEnabled18 = false
                    local convertSceneToVrayOrCoronaCheckBoxEnabled19 = false
                    local convertSceneToVrayOrCoronaCheckBoxEnabled20 = false

                -- Object handling

                    -- saveEachObjectSeparatelyBoolean

                        local saveEachObjectSeparatelyBoolean1 = false
                        local saveEachObjectSeparatelyBoolean2 = false
                        local saveEachObjectSeparatelyBoolean3 = false
                        local saveEachObjectSeparatelyBoolean4 = false
                        local saveEachObjectSeparatelyBoolean5 = false
                        local saveEachObjectSeparatelyBoolean6 = false
                        local saveEachObjectSeparatelyBoolean7 = false
                        local saveEachObjectSeparatelyBoolean8 = false
                        local saveEachObjectSeparatelyBoolean9 = false
                        local saveEachObjectSeparatelyBoolean10 = false
                        local saveEachObjectSeparatelyBoolean11 = false
                        local saveEachObjectSeparatelyBoolean12 = false
                        local saveEachObjectSeparatelyBoolean13 = false
                        local saveEachObjectSeparatelyBoolean14 = false
                        local saveEachObjectSeparatelyBoolean15 = false
                        local saveEachObjectSeparatelyBoolean16 = false
                        local saveEachObjectSeparatelyBoolean17 = false
                        local saveEachObjectSeparatelyBoolean18 = false
                        local saveEachObjectSeparatelyBoolean19 = false
                        local saveEachObjectSeparatelyBoolean20 = false

                        local saveEachObjectSeparatelyCheckBoxEnabled1 = false
                        local saveEachObjectSeparatelyCheckBoxEnabled2 = false
                        local saveEachObjectSeparatelyCheckBoxEnabled3 = false
                        local saveEachObjectSeparatelyCheckBoxEnabled4 = false
                        local saveEachObjectSeparatelyCheckBoxEnabled5 = false
                        local saveEachObjectSeparatelyCheckBoxEnabled6 = false
                        local saveEachObjectSeparatelyCheckBoxEnabled7 = false
                        local saveEachObjectSeparatelyCheckBoxEnabled8 = false
                        local saveEachObjectSeparatelyCheckBoxEnabled9 = false
                        local saveEachObjectSeparatelyCheckBoxEnabled10 = false
                        local saveEachObjectSeparatelyCheckBoxEnabled11 = false
                        local saveEachObjectSeparatelyCheckBoxEnabled12 = false
                        local saveEachObjectSeparatelyCheckBoxEnabled13 = false
                        local saveEachObjectSeparatelyCheckBoxEnabled14 = false
                        local saveEachObjectSeparatelyCheckBoxEnabled15 = false
                        local saveEachObjectSeparatelyCheckBoxEnabled16 = false
                        local saveEachObjectSeparatelyCheckBoxEnabled17 = false
                        local saveEachObjectSeparatelyCheckBoxEnabled18 = false
                        local saveEachObjectSeparatelyCheckBoxEnabled19 = false
                        local saveEachObjectSeparatelyCheckBoxEnabled20 = false

                    -- attachObjectsBoolean

                        local attachObjectsBoolean1 = false
                        local attachObjectsBoolean2 = false
                        local attachObjectsBoolean3 = false
                        local attachObjectsBoolean4 = false
                        local attachObjectsBoolean5 = false
                        local attachObjectsBoolean6 = false
                        local attachObjectsBoolean7 = false
                        local attachObjectsBoolean8 = false
                        local attachObjectsBoolean9 = false
                        local attachObjectsBoolean10 = false
                        local attachObjectsBoolean11 = false
                        local attachObjectsBoolean12 = false
                        local attachObjectsBoolean13 = false
                        local attachObjectsBoolean14 = false
                        local attachObjectsBoolean15 = false
                        local attachObjectsBoolean16 = false
                        local attachObjectsBoolean17 = false
                        local attachObjectsBoolean18 = false
                        local attachObjectsBoolean19 = false
                        local attachObjectsBoolean20 = false

                        local attachObjectsCheckBoxEnabled1 = false
                        local attachObjectsCheckBoxEnabled2 = false
                        local attachObjectsCheckBoxEnabled3 = false
                        local attachObjectsCheckBoxEnabled4 = false
                        local attachObjectsCheckBoxEnabled5 = false
                        local attachObjectsCheckBoxEnabled6 = false
                        local attachObjectsCheckBoxEnabled7 = false
                        local attachObjectsCheckBoxEnabled8 = false
                        local attachObjectsCheckBoxEnabled9 = false
                        local attachObjectsCheckBoxEnabled10 = false
                        local attachObjectsCheckBoxEnabled11 = false
                        local attachObjectsCheckBoxEnabled12 = false
                        local attachObjectsCheckBoxEnabled13 = false
                        local attachObjectsCheckBoxEnabled14 = false
                        local attachObjectsCheckBoxEnabled15 = false
                        local attachObjectsCheckBoxEnabled16 = false
                        local attachObjectsCheckBoxEnabled17 = false
                        local attachObjectsCheckBoxEnabled18 = false
                        local attachObjectsCheckBoxEnabled19 = false
                        local attachObjectsCheckBoxEnabled20 = false

                    -- proxyObjectsBoolean

                        local proxyObjectsBoolean1 = true
                        local proxyObjectsBoolean2 = true
                        local proxyObjectsBoolean3 = true
                        local proxyObjectsBoolean4 = true
                        local proxyObjectsBoolean5 = true
                        local proxyObjectsBoolean6 = true
                        local proxyObjectsBoolean7 = true
                        local proxyObjectsBoolean8 = true
                        local proxyObjectsBoolean9 = true
                        local proxyObjectsBoolean10 = true
                        local proxyObjectsBoolean11 = true
                        local proxyObjectsBoolean12 = true
                        local proxyObjectsBoolean13 = true
                        local proxyObjectsBoolean14 = true
                        local proxyObjectsBoolean15 = true
                        local proxyObjectsBoolean16 = true
                        local proxyObjectsBoolean17 = true
                        local proxyObjectsBoolean18 = true
                        local proxyObjectsBoolean19 = true
                        local proxyObjectsBoolean20 = true

                        local proxyObjectsCheckBoxEnabled1 = true
                        local proxyObjectsCheckBoxEnabled2 = true
                        local proxyObjectsCheckBoxEnabled3 = true
                        local proxyObjectsCheckBoxEnabled4 = true
                        local proxyObjectsCheckBoxEnabled5 = true
                        local proxyObjectsCheckBoxEnabled6 = true
                        local proxyObjectsCheckBoxEnabled7 = true
                        local proxyObjectsCheckBoxEnabled8 = true
                        local proxyObjectsCheckBoxEnabled9 = true
                        local proxyObjectsCheckBoxEnabled10 = true
                        local proxyObjectsCheckBoxEnabled11 = true
                        local proxyObjectsCheckBoxEnabled12 = true
                        local proxyObjectsCheckBoxEnabled13 = true
                        local proxyObjectsCheckBoxEnabled14 = true
                        local proxyObjectsCheckBoxEnabled15 = true
                        local proxyObjectsCheckBoxEnabled16 = true
                        local proxyObjectsCheckBoxEnabled17 = true
                        local proxyObjectsCheckBoxEnabled18 = true
                        local proxyObjectsCheckBoxEnabled19 = true
                        local proxyObjectsCheckBoxEnabled20 = true

                    -- facesNumberInteger

                        local facesNumberInteger1 = 30000
                        local facesNumberInteger2 = 30000
                        local facesNumberInteger3 = 30000
                        local facesNumberInteger4 = 30000
                        local facesNumberInteger5 = 30000
                        local facesNumberInteger6 = 30000
                        local facesNumberInteger7 = 30000
                        local facesNumberInteger8 = 30000
                        local facesNumberInteger9 = 30000
                        local facesNumberInteger10 = 30000
                        local facesNumberInteger11 = 30000
                        local facesNumberInteger12 = 30000
                        local facesNumberInteger13 = 30000
                        local facesNumberInteger14 = 30000
                        local facesNumberInteger15 = 30000
                        local facesNumberInteger16 = 30000
                        local facesNumberInteger17 = 30000
                        local facesNumberInteger18 = 30000
                        local facesNumberInteger19 = 30000
                        local facesNumberInteger20 = 30000

                        local facesNumberSpinnerEnabled1 = false
                        local facesNumberSpinnerEnabled2 = false
                        local facesNumberSpinnerEnabled3 = false
                        local facesNumberSpinnerEnabled4 = false
                        local facesNumberSpinnerEnabled5 = false
                        local facesNumberSpinnerEnabled6 = false
                        local facesNumberSpinnerEnabled7 = false
                        local facesNumberSpinnerEnabled8 = false
                        local facesNumberSpinnerEnabled9 = false
                        local facesNumberSpinnerEnabled10 = false
                        local facesNumberSpinnerEnabled11 = false
                        local facesNumberSpinnerEnabled12 = false
                        local facesNumberSpinnerEnabled13 = false
                        local facesNumberSpinnerEnabled14 = false
                        local facesNumberSpinnerEnabled15 = false
                        local facesNumberSpinnerEnabled16 = false
                        local facesNumberSpinnerEnabled17 = false
                        local facesNumberSpinnerEnabled18 = false
                        local facesNumberSpinnerEnabled19 = false
                        local facesNumberSpinnerEnabled20 = false

                    -- coronaBoolean

                        local coronaBoolean1 = false
                        local coronaBoolean2 = false
                        local coronaBoolean3 = false
                        local coronaBoolean4 = false
                        local coronaBoolean5 = false
                        local coronaBoolean6 = false
                        local coronaBoolean7 = false
                        local coronaBoolean8 = false
                        local coronaBoolean9 = false
                        local coronaBoolean10 = false
                        local coronaBoolean11 = false
                        local coronaBoolean12 = false
                        local coronaBoolean13 = false
                        local coronaBoolean14 = false
                        local coronaBoolean15 = false
                        local coronaBoolean16 = false
                        local coronaBoolean17 = false
                        local coronaBoolean18 = false
                        local coronaBoolean19 = false
                        local coronaBoolean20 = false

                        local coronaCheckboxEnabled1 = false
                        local coronaCheckboxEnabled2 = false
                        local coronaCheckboxEnabled3 = false
                        local coronaCheckboxEnabled4 = false
                        local coronaCheckboxEnabled5 = false
                        local coronaCheckboxEnabled6 = false
                        local coronaCheckboxEnabled7 = false
                        local coronaCheckboxEnabled8 = false
                        local coronaCheckboxEnabled9 = false
                        local coronaCheckboxEnabled10 = false
                        local coronaCheckboxEnabled11 = false
                        local coronaCheckboxEnabled12 = false
                        local coronaCheckboxEnabled13 = false
                        local coronaCheckboxEnabled14 = false
                        local coronaCheckboxEnabled15 = false
                        local coronaCheckboxEnabled16 = false
                        local coronaCheckboxEnabled17 = false
                        local coronaCheckboxEnabled18 = false
                        local coronaCheckboxEnabled19 = false
                        local coronaCheckboxEnabled20 = false

                -- Output Filters

                    -- includeCamerasBoolean

                        local includeCamerasBoolean1 = false
                        local includeCamerasBoolean2 = false
                        local includeCamerasBoolean3 = false
                        local includeCamerasBoolean4 = false
                        local includeCamerasBoolean5 = false
                        local includeCamerasBoolean6 = false
                        local includeCamerasBoolean7 = false
                        local includeCamerasBoolean8 = false
                        local includeCamerasBoolean9 = false
                        local includeCamerasBoolean10 = false
                        local includeCamerasBoolean11 = false
                        local includeCamerasBoolean12 = false
                        local includeCamerasBoolean13 = false
                        local includeCamerasBoolean14 = false
                        local includeCamerasBoolean15 = false
                        local includeCamerasBoolean16 = false
                        local includeCamerasBoolean17 = false
                        local includeCamerasBoolean18 = false
                        local includeCamerasBoolean19 = false
                        local includeCamerasBoolean20 = false

                        local includeCamerasCheckBoxEnabled1 = false
                        local includeCamerasCheckBoxEnabled2 = false
                        local includeCamerasCheckBoxEnabled3 = false
                        local includeCamerasCheckBoxEnabled4 = false
                        local includeCamerasCheckBoxEnabled5 = false
                        local includeCamerasCheckBoxEnabled6 = false
                        local includeCamerasCheckBoxEnabled7 = false
                        local includeCamerasCheckBoxEnabled8 = false
                        local includeCamerasCheckBoxEnabled9 = false
                        local includeCamerasCheckBoxEnabled10 = false
                        local includeCamerasCheckBoxEnabled11 = false
                        local includeCamerasCheckBoxEnabled12 = false
                        local includeCamerasCheckBoxEnabled13 = false
                        local includeCamerasCheckBoxEnabled14 = false
                        local includeCamerasCheckBoxEnabled15 = false
                        local includeCamerasCheckBoxEnabled16 = false
                        local includeCamerasCheckBoxEnabled17 = false
                        local includeCamerasCheckBoxEnabled18 = false
                        local includeCamerasCheckBoxEnabled19 = false
                        local includeCamerasCheckBoxEnabled20 = false

                    -- includeLightsBoolean

                        local includeLightsBoolean1 = true
                        local includeLightsBoolean2 = true
                        local includeLightsBoolean3 = true
                        local includeLightsBoolean4 = true
                        local includeLightsBoolean5 = true
                        local includeLightsBoolean6 = true
                        local includeLightsBoolean7 = true
                        local includeLightsBoolean8 = true
                        local includeLightsBoolean9 = true
                        local includeLightsBoolean10 = true
                        local includeLightsBoolean11 = true
                        local includeLightsBoolean12 = true
                        local includeLightsBoolean13 = true
                        local includeLightsBoolean14 = true
                        local includeLightsBoolean15 = true
                        local includeLightsBoolean16 = true
                        local includeLightsBoolean17 = true
                        local includeLightsBoolean18 = true
                        local includeLightsBoolean19 = true
                        local includeLightsBoolean20 = true

                        local includeLightsCheckBoxEnabled1 = false
                        local includeLightsCheckBoxEnabled2 = false
                        local includeLightsCheckBoxEnabled3 = false
                        local includeLightsCheckBoxEnabled4 = false
                        local includeLightsCheckBoxEnabled5 = false
                        local includeLightsCheckBoxEnabled6 = false
                        local includeLightsCheckBoxEnabled7 = false
                        local includeLightsCheckBoxEnabled8 = false
                        local includeLightsCheckBoxEnabled9 = false
                        local includeLightsCheckBoxEnabled10 = false
                        local includeLightsCheckBoxEnabled11 = false
                        local includeLightsCheckBoxEnabled12 = false
                        local includeLightsCheckBoxEnabled13 = false
                        local includeLightsCheckBoxEnabled14 = false
                        local includeLightsCheckBoxEnabled15 = false
                        local includeLightsCheckBoxEnabled16 = false
                        local includeLightsCheckBoxEnabled17 = false
                        local includeLightsCheckBoxEnabled18 = false
                        local includeLightsCheckBoxEnabled19 = false
                        local includeLightsCheckBoxEnabled20 = false

                -- File naming

                    -- replaceAllTextBoolean

                        local replaceAllTextBoolean1 = true
                        local replaceAllTextBoolean2 = true
                        local replaceAllTextBoolean3 = true
                        local replaceAllTextBoolean4 = true
                        local replaceAllTextBoolean5 = true
                        local replaceAllTextBoolean6 = true
                        local replaceAllTextBoolean7 = true
                        local replaceAllTextBoolean8 = true
                        local replaceAllTextBoolean9 = true
                        local replaceAllTextBoolean10 = true
                        local replaceAllTextBoolean11 = true
                        local replaceAllTextBoolean12 = true
                        local replaceAllTextBoolean13 = true
                        local replaceAllTextBoolean14 = true
                        local replaceAllTextBoolean15 = true
                        local replaceAllTextBoolean16 = true
                        local replaceAllTextBoolean17 = true
                        local replaceAllTextBoolean18 = true
                        local replaceAllTextBoolean19 = true
                        local replaceAllTextBoolean20 = true

                        local replaceAllTextCheckBoxEnabled1 = false
                        local replaceAllTextCheckBoxEnabled2 = false
                        local replaceAllTextCheckBoxEnabled3 = false
                        local replaceAllTextCheckBoxEnabled4 = false
                        local replaceAllTextCheckBoxEnabled5 = false
                        local replaceAllTextCheckBoxEnabled6 = false
                        local replaceAllTextCheckBoxEnabled7 = false
                        local replaceAllTextCheckBoxEnabled8 = false
                        local replaceAllTextCheckBoxEnabled9 = false
                        local replaceAllTextCheckBoxEnabled10 = false
                        local replaceAllTextCheckBoxEnabled11 = false
                        local replaceAllTextCheckBoxEnabled12 = false
                        local replaceAllTextCheckBoxEnabled13 = false
                        local replaceAllTextCheckBoxEnabled14 = false
                        local replaceAllTextCheckBoxEnabled15 = false
                        local replaceAllTextCheckBoxEnabled16 = false
                        local replaceAllTextCheckBoxEnabled17 = false
                        local replaceAllTextCheckBoxEnabled18 = false
                        local replaceAllTextCheckBoxEnabled19 = false
                        local replaceAllTextCheckBoxEnabled20 = false

                    -- retainSpecifiedTextFromFileNameBoolean

                        local retainSpecifiedTextFromFileNameBoolean1 = false
                        local retainSpecifiedTextFromFileNameBoolean2 = false
                        local retainSpecifiedTextFromFileNameBoolean3 = false
                        local retainSpecifiedTextFromFileNameBoolean4 = false
                        local retainSpecifiedTextFromFileNameBoolean5 = false
                        local retainSpecifiedTextFromFileNameBoolean6 = false
                        local retainSpecifiedTextFromFileNameBoolean7 = false
                        local retainSpecifiedTextFromFileNameBoolean8 = false
                        local retainSpecifiedTextFromFileNameBoolean9 = false
                        local retainSpecifiedTextFromFileNameBoolean10 = false
                        local retainSpecifiedTextFromFileNameBoolean11 = false
                        local retainSpecifiedTextFromFileNameBoolean12 = false
                        local retainSpecifiedTextFromFileNameBoolean13 = false
                        local retainSpecifiedTextFromFileNameBoolean14 = false
                        local retainSpecifiedTextFromFileNameBoolean15 = false
                        local retainSpecifiedTextFromFileNameBoolean16 = false
                        local retainSpecifiedTextFromFileNameBoolean17 = false
                        local retainSpecifiedTextFromFileNameBoolean18 = false
                        local retainSpecifiedTextFromFileNameBoolean19 = false
                        local retainSpecifiedTextFromFileNameBoolean20 = false

                        local retainSpecifiedTextFromFileNameCheckBoxEnabled1 = false
                        local retainSpecifiedTextFromFileNameCheckBoxEnabled2 = false
                        local retainSpecifiedTextFromFileNameCheckBoxEnabled3 = false
                        local retainSpecifiedTextFromFileNameCheckBoxEnabled4 = false
                        local retainSpecifiedTextFromFileNameCheckBoxEnabled5 = false
                        local retainSpecifiedTextFromFileNameCheckBoxEnabled6 = false
                        local retainSpecifiedTextFromFileNameCheckBoxEnabled7 = false
                        local retainSpecifiedTextFromFileNameCheckBoxEnabled8 = false
                        local retainSpecifiedTextFromFileNameCheckBoxEnabled9 = false
                        local retainSpecifiedTextFromFileNameCheckBoxEnabled10 = false
                        local retainSpecifiedTextFromFileNameCheckBoxEnabled11 = false
                        local retainSpecifiedTextFromFileNameCheckBoxEnabled12 = false
                        local retainSpecifiedTextFromFileNameCheckBoxEnabled13 = false
                        local retainSpecifiedTextFromFileNameCheckBoxEnabled14 = false
                        local retainSpecifiedTextFromFileNameCheckBoxEnabled15 = false
                        local retainSpecifiedTextFromFileNameCheckBoxEnabled16 = false
                        local retainSpecifiedTextFromFileNameCheckBoxEnabled17 = false
                        local retainSpecifiedTextFromFileNameCheckBoxEnabled18 = false
                        local retainSpecifiedTextFromFileNameCheckBoxEnabled19 = false
                        local retainSpecifiedTextFromFileNameCheckBoxEnabled20 = false

                    -- retainSpecifiedTextFromObjectNameBoolean

                        local retainSpecifiedTextFromObjectNameBoolean1 = false
                        local retainSpecifiedTextFromObjectNameBoolean2 = false
                        local retainSpecifiedTextFromObjectNameBoolean3 = false
                        local retainSpecifiedTextFromObjectNameBoolean4 = false
                        local retainSpecifiedTextFromObjectNameBoolean5 = false
                        local retainSpecifiedTextFromObjectNameBoolean6 = false
                        local retainSpecifiedTextFromObjectNameBoolean7 = false
                        local retainSpecifiedTextFromObjectNameBoolean8 = false
                        local retainSpecifiedTextFromObjectNameBoolean9 = false
                        local retainSpecifiedTextFromObjectNameBoolean10 = false
                        local retainSpecifiedTextFromObjectNameBoolean11 = false
                        local retainSpecifiedTextFromObjectNameBoolean12 = false
                        local retainSpecifiedTextFromObjectNameBoolean13 = false
                        local retainSpecifiedTextFromObjectNameBoolean14 = false
                        local retainSpecifiedTextFromObjectNameBoolean15 = false
                        local retainSpecifiedTextFromObjectNameBoolean16 = false
                        local retainSpecifiedTextFromObjectNameBoolean17 = false
                        local retainSpecifiedTextFromObjectNameBoolean18 = false
                        local retainSpecifiedTextFromObjectNameBoolean19 = false
                        local retainSpecifiedTextFromObjectNameBoolean20 = false

                        local retainSpecifiedTextFromObjectNameCheckBoxEnabled1 = false
                        local retainSpecifiedTextFromObjectNameCheckBoxEnabled2 = false
                        local retainSpecifiedTextFromObjectNameCheckBoxEnabled3 = false
                        local retainSpecifiedTextFromObjectNameCheckBoxEnabled4 = false
                        local retainSpecifiedTextFromObjectNameCheckBoxEnabled5 = false
                        local retainSpecifiedTextFromObjectNameCheckBoxEnabled6 = false
                        local retainSpecifiedTextFromObjectNameCheckBoxEnabled7 = false
                        local retainSpecifiedTextFromObjectNameCheckBoxEnabled8 = false
                        local retainSpecifiedTextFromObjectNameCheckBoxEnabled9 = false
                        local retainSpecifiedTextFromObjectNameCheckBoxEnabled10 = false
                        local retainSpecifiedTextFromObjectNameCheckBoxEnabled11 = false
                        local retainSpecifiedTextFromObjectNameCheckBoxEnabled12 = false
                        local retainSpecifiedTextFromObjectNameCheckBoxEnabled13 = false
                        local retainSpecifiedTextFromObjectNameCheckBoxEnabled14 = false
                        local retainSpecifiedTextFromObjectNameCheckBoxEnabled15 = false
                        local retainSpecifiedTextFromObjectNameCheckBoxEnabled16 = false
                        local retainSpecifiedTextFromObjectNameCheckBoxEnabled17 = false
                        local retainSpecifiedTextFromObjectNameCheckBoxEnabled18 = false
                        local retainSpecifiedTextFromObjectNameCheckBoxEnabled19 = false
                        local retainSpecifiedTextFromObjectNameCheckBoxEnabled20 = false

                    -- retainAllTextFromFileNameBoolean

                        local retainAllTextFromFileNameBoolean1 = false
                        local retainAllTextFromFileNameBoolean2 = false
                        local retainAllTextFromFileNameBoolean3 = false
                        local retainAllTextFromFileNameBoolean4 = false
                        local retainAllTextFromFileNameBoolean5 = false
                        local retainAllTextFromFileNameBoolean6 = false
                        local retainAllTextFromFileNameBoolean7 = false
                        local retainAllTextFromFileNameBoolean8 = false
                        local retainAllTextFromFileNameBoolean9 = false
                        local retainAllTextFromFileNameBoolean10 = false
                        local retainAllTextFromFileNameBoolean11 = false
                        local retainAllTextFromFileNameBoolean12 = false
                        local retainAllTextFromFileNameBoolean13 = false
                        local retainAllTextFromFileNameBoolean14 = false
                        local retainAllTextFromFileNameBoolean15 = false
                        local retainAllTextFromFileNameBoolean16 = false
                        local retainAllTextFromFileNameBoolean17 = false
                        local retainAllTextFromFileNameBoolean18 = false
                        local retainAllTextFromFileNameBoolean19 = false
                        local retainAllTextFromFileNameBoolean20 = false

                        local retainAllTextFromFileNameCheckBoxEnabled1 = false
                        local retainAllTextFromFileNameCheckBoxEnabled2 = false
                        local retainAllTextFromFileNameCheckBoxEnabled3 = false
                        local retainAllTextFromFileNameCheckBoxEnabled4 = false
                        local retainAllTextFromFileNameCheckBoxEnabled5 = false
                        local retainAllTextFromFileNameCheckBoxEnabled6 = false
                        local retainAllTextFromFileNameCheckBoxEnabled7 = false
                        local retainAllTextFromFileNameCheckBoxEnabled8 = false
                        local retainAllTextFromFileNameCheckBoxEnabled9 = false
                        local retainAllTextFromFileNameCheckBoxEnabled10 = false
                        local retainAllTextFromFileNameCheckBoxEnabled11 = false
                        local retainAllTextFromFileNameCheckBoxEnabled12 = false
                        local retainAllTextFromFileNameCheckBoxEnabled13 = false
                        local retainAllTextFromFileNameCheckBoxEnabled14 = false
                        local retainAllTextFromFileNameCheckBoxEnabled15 = false
                        local retainAllTextFromFileNameCheckBoxEnabled16 = false
                        local retainAllTextFromFileNameCheckBoxEnabled17 = false
                        local retainAllTextFromFileNameCheckBoxEnabled18 = false
                        local retainAllTextFromFileNameCheckBoxEnabled19 = false
                        local retainAllTextFromFileNameCheckBoxEnabled20 = false

                -- File naming continued

                    -- phraseToSplitWithString

                        local phraseToSplitWithString1 = ""
                        local phraseToSplitWithString2 = ""
                        local phraseToSplitWithString3 = ""
                        local phraseToSplitWithString4 = ""
                        local phraseToSplitWithString5 = ""
                        local phraseToSplitWithString6 = ""
                        local phraseToSplitWithString7 = ""
                        local phraseToSplitWithString8 = ""
                        local phraseToSplitWithString9 = ""
                        local phraseToSplitWithString10 = ""
                        local phraseToSplitWithString11 = ""
                        local phraseToSplitWithString12 = ""
                        local phraseToSplitWithString13 = ""
                        local phraseToSplitWithString14 = ""
                        local phraseToSplitWithString15 = ""
                        local phraseToSplitWithString16 = ""
                        local phraseToSplitWithString17 = ""
                        local phraseToSplitWithString18 = ""
                        local phraseToSplitWithString19 = ""
                        local phraseToSplitWithString20 = ""

                        local phraseToSplitWithEditTextEnabled1 = false
                        local phraseToSplitWithEditTextEnabled2 = false
                        local phraseToSplitWithEditTextEnabled3 = false
                        local phraseToSplitWithEditTextEnabled4 = false
                        local phraseToSplitWithEditTextEnabled5 = false
                        local phraseToSplitWithEditTextEnabled6 = false
                        local phraseToSplitWithEditTextEnabled7 = false
                        local phraseToSplitWithEditTextEnabled8 = false
                        local phraseToSplitWithEditTextEnabled9 = false
                        local phraseToSplitWithEditTextEnabled10 = false
                        local phraseToSplitWithEditTextEnabled11 = false
                        local phraseToSplitWithEditTextEnabled12 = false
                        local phraseToSplitWithEditTextEnabled13 = false
                        local phraseToSplitWithEditTextEnabled14 = false
                        local phraseToSplitWithEditTextEnabled15 = false
                        local phraseToSplitWithEditTextEnabled16 = false
                        local phraseToSplitWithEditTextEnabled17 = false
                        local phraseToSplitWithEditTextEnabled18 = false
                        local phraseToSplitWithEditTextEnabled19 = false
                        local phraseToSplitWithEditTextEnabled20 = false

                    -- numberOfIndicesToRemoveFromStartInteger

                        local numberOfIndicesToRemoveFromStartInteger1 = 0
                        local numberOfIndicesToRemoveFromStartInteger2 = 0
                        local numberOfIndicesToRemoveFromStartInteger3 = 0
                        local numberOfIndicesToRemoveFromStartInteger4 = 0
                        local numberOfIndicesToRemoveFromStartInteger5 = 0
                        local numberOfIndicesToRemoveFromStartInteger6 = 0
                        local numberOfIndicesToRemoveFromStartInteger7 = 0
                        local numberOfIndicesToRemoveFromStartInteger8 = 0
                        local numberOfIndicesToRemoveFromStartInteger9 = 0
                        local numberOfIndicesToRemoveFromStartInteger10 = 0
                        local numberOfIndicesToRemoveFromStartInteger11 = 0
                        local numberOfIndicesToRemoveFromStartInteger12 = 0
                        local numberOfIndicesToRemoveFromStartInteger13 = 0
                        local numberOfIndicesToRemoveFromStartInteger14 = 0
                        local numberOfIndicesToRemoveFromStartInteger15 = 0
                        local numberOfIndicesToRemoveFromStartInteger16 = 0
                        local numberOfIndicesToRemoveFromStartInteger17 = 0
                        local numberOfIndicesToRemoveFromStartInteger18 = 0
                        local numberOfIndicesToRemoveFromStartInteger19 = 0
                        local numberOfIndicesToRemoveFromStartInteger20 = 0

                        local numberOfIndicesToRemoveFromStartSpinnerEnabled1 = false
                        local numberOfIndicesToRemoveFromStartSpinnerEnabled2 = false
                        local numberOfIndicesToRemoveFromStartSpinnerEnabled3 = false
                        local numberOfIndicesToRemoveFromStartSpinnerEnabled4 = false
                        local numberOfIndicesToRemoveFromStartSpinnerEnabled5 = false
                        local numberOfIndicesToRemoveFromStartSpinnerEnabled6 = false
                        local numberOfIndicesToRemoveFromStartSpinnerEnabled7 = false
                        local numberOfIndicesToRemoveFromStartSpinnerEnabled8 = false
                        local numberOfIndicesToRemoveFromStartSpinnerEnabled9 = false
                        local numberOfIndicesToRemoveFromStartSpinnerEnabled10 = false
                        local numberOfIndicesToRemoveFromStartSpinnerEnabled11 = false
                        local numberOfIndicesToRemoveFromStartSpinnerEnabled12 = false
                        local numberOfIndicesToRemoveFromStartSpinnerEnabled13 = false
                        local numberOfIndicesToRemoveFromStartSpinnerEnabled14 = false
                        local numberOfIndicesToRemoveFromStartSpinnerEnabled15 = false
                        local numberOfIndicesToRemoveFromStartSpinnerEnabled16 = false
                        local numberOfIndicesToRemoveFromStartSpinnerEnabled17 = false
                        local numberOfIndicesToRemoveFromStartSpinnerEnabled18 = false
                        local numberOfIndicesToRemoveFromStartSpinnerEnabled19 = false
                        local numberOfIndicesToRemoveFromStartSpinnerEnabled20 = false

                    -- numberOfIndicesToRemoveFromEndInteger

                        local numberOfIndicesToRemoveFromEndInteger1 = 0
                        local numberOfIndicesToRemoveFromEndInteger2 = 0
                        local numberOfIndicesToRemoveFromEndInteger3 = 0
                        local numberOfIndicesToRemoveFromEndInteger4 = 0
                        local numberOfIndicesToRemoveFromEndInteger5 = 0
                        local numberOfIndicesToRemoveFromEndInteger6 = 0
                        local numberOfIndicesToRemoveFromEndInteger7 = 0
                        local numberOfIndicesToRemoveFromEndInteger8 = 0
                        local numberOfIndicesToRemoveFromEndInteger9 = 0
                        local numberOfIndicesToRemoveFromEndInteger10 = 0
                        local numberOfIndicesToRemoveFromEndInteger11 = 0
                        local numberOfIndicesToRemoveFromEndInteger12 = 0
                        local numberOfIndicesToRemoveFromEndInteger13 = 0
                        local numberOfIndicesToRemoveFromEndInteger14 = 0
                        local numberOfIndicesToRemoveFromEndInteger15 = 0
                        local numberOfIndicesToRemoveFromEndInteger16 = 0
                        local numberOfIndicesToRemoveFromEndInteger17 = 0
                        local numberOfIndicesToRemoveFromEndInteger18 = 0
                        local numberOfIndicesToRemoveFromEndInteger19 = 0
                        local numberOfIndicesToRemoveFromEndInteger20 = 0

                        local numberOfIndicesToRemoveFromEndSpinnerEnabled1 = false
                        local numberOfIndicesToRemoveFromEndSpinnerEnabled2 = false
                        local numberOfIndicesToRemoveFromEndSpinnerEnabled3 = false
                        local numberOfIndicesToRemoveFromEndSpinnerEnabled4 = false
                        local numberOfIndicesToRemoveFromEndSpinnerEnabled5 = false
                        local numberOfIndicesToRemoveFromEndSpinnerEnabled6 = false
                        local numberOfIndicesToRemoveFromEndSpinnerEnabled7 = false
                        local numberOfIndicesToRemoveFromEndSpinnerEnabled8 = false
                        local numberOfIndicesToRemoveFromEndSpinnerEnabled9 = false
                        local numberOfIndicesToRemoveFromEndSpinnerEnabled10 = false
                        local numberOfIndicesToRemoveFromEndSpinnerEnabled11 = false
                        local numberOfIndicesToRemoveFromEndSpinnerEnabled12 = false
                        local numberOfIndicesToRemoveFromEndSpinnerEnabled13 = false
                        local numberOfIndicesToRemoveFromEndSpinnerEnabled14 = false
                        local numberOfIndicesToRemoveFromEndSpinnerEnabled15 = false
                        local numberOfIndicesToRemoveFromEndSpinnerEnabled16 = false
                        local numberOfIndicesToRemoveFromEndSpinnerEnabled17 = false
                        local numberOfIndicesToRemoveFromEndSpinnerEnabled18 = false
                        local numberOfIndicesToRemoveFromEndSpinnerEnabled19 = false
                        local numberOfIndicesToRemoveFromEndSpinnerEnabled20 = false

                -- Layering

                    -- layerToMoveObjectsToString

                        local layerToMoveObjectsToString1 = ""
                        local layerToMoveObjectsToString2 = ""
                        local layerToMoveObjectsToString3 = ""
                        local layerToMoveObjectsToString4 = ""
                        local layerToMoveObjectsToString5 = ""
                        local layerToMoveObjectsToString6 = ""
                        local layerToMoveObjectsToString7 = ""
                        local layerToMoveObjectsToString8 = ""
                        local layerToMoveObjectsToString9 = ""
                        local layerToMoveObjectsToString10 = ""
                        local layerToMoveObjectsToString11 = ""
                        local layerToMoveObjectsToString12 = ""
                        local layerToMoveObjectsToString13 = ""
                        local layerToMoveObjectsToString14 = ""
                        local layerToMoveObjectsToString15 = ""
                        local layerToMoveObjectsToString16 = ""
                        local layerToMoveObjectsToString17 = ""
                        local layerToMoveObjectsToString18 = ""
                        local layerToMoveObjectsToString19 = ""
                        local layerToMoveObjectsToString20 = ""

                -- Maps

                    -- relinkMapsBoolean

                        local relinkMapsBoolean1 = true
                        local relinkMapsBoolean2 = true
                        local relinkMapsBoolean3 = true
                        local relinkMapsBoolean4 = true
                        local relinkMapsBoolean5 = true
                        local relinkMapsBoolean6 = true
                        local relinkMapsBoolean7 = true
                        local relinkMapsBoolean8 = true
                        local relinkMapsBoolean9 = true
                        local relinkMapsBoolean10 = true
                        local relinkMapsBoolean11 = true
                        local relinkMapsBoolean12 = true
                        local relinkMapsBoolean13 = true
                        local relinkMapsBoolean14 = true
                        local relinkMapsBoolean15 = true
                        local relinkMapsBoolean16 = true
                        local relinkMapsBoolean17 = true
                        local relinkMapsBoolean18 = true
                        local relinkMapsBoolean19 = true
                        local relinkMapsBoolean20 = true

        -- Components

            -- Main

                group "Instructions"(
                    editText warningOne "" text:"- Incoming scenes must correspond to incoming previews when arranged alphabetically.\n\n- Volume numbers will be assigned to new volumes based on the existing volumes in the destination\nfolder.\n\n- Max number of volumes that can be processed at once is 20.\n\n- Files whose names are just a number will lose their name regardless of 'File naming' setting." readOnly:true height:140
                )

                group "File Locations"(
                    editText originalFolderEditText "Original Folder:" text:"" toolTip:"This is the parent folder containing all original volume folders"

                    editText destinationFolderEditText "Destination Folder:" text:"" toolTip:"This is the parent where all new volume folders will be saved"
                )

                group ""(
                    dropDownList volumeToConfigureDropDownList "Volume to configure:" items:#() enabled:false toolTip:"Choose which volume number to configure"
                )

                group "Naming"(
                    checkBox useOriginalVolumeNameAsSuffixCheckBox "Use original volume name as suffix" checked:true enabled:false tooltip:"If checked, the name of each original volume will be appended to the number of each new volume"

                    editText volumeNameSuffixEditText "Volume name suffix" text:"" enabled:false tooltip:"Text entered here will be appended to the name of each new volume in the destination folder. A space will be automatically added if omitted"

                    editText fileNameExtraTextEditText "File name extra text" text:"" enabled:false tooltip:"Text entered here will be added to the name of each new file in the destination folder, between the file number and any text being retained. A space will be automatically added if omitted"

                    editText keywordFilterEditText "Keyword filter:" text:"" enabled:false tooltip:"If text is entered here, only objects whose names contain this text will be saved in the destination scenes. Useful if the original scene contains lighting rigs, cameras etc."
                )

                group ""(
                    checkbox convertSceneToVrayOrCoronaCheckbox "Convert scene to Vray" checked:false enabled:false toolTip:"If already Vray, save time by leaving unchecked"
                )

                group "Object handling"(
                    checkBox saveEachObjectSeparatelyCheckBox "Save each object separately" checked:false enabled:false

                    checkBox attachObjectsCheckBox "Attach objects" checked:false enabled:false

                    checkBox proxyObjectsCheckBox "Proxy objects" checked:true enabled:false

                    checkBox coronaCheckbox "Corona scene (not Vray)" checked:false enabled:false

                    spinner facesNumberSpinner "Maximum face number for proxies:" type:#integer width:120 range:[1,100000,30000] enabled:false
                )

                group "Output Filters"(
                    checkbox includeCamerasCheckbox "Include Cameras" checked:false enabled:false

                    checkbox includeLightsCheckbox "Include Lights" checked:true enabled:false
                )

                group "File naming"(
                    checkBox replaceAllTextCheckBox "Replace all text" checked:true enabled:false

                    checkBox retainSpecifiedTextFromFileNameCheckBox "Retain specified text from file name" checked:false enabled:false

                    checkBox retainSpecifiedTextFromObjectNameCheckBox "Retain specified text from object name" checked:false enabled:false toolTip:"Note: If the number of objects to save to any individual file are greater than 1, the name of the first of these objects (alphabetically) is used"

                    checkBox retainAllTextFromFileNameCheckBox "Retain all text" checked:false enabled:false toolTip:"If left unchecked, file names will be replaced by their respective numbers. If checked, numbers will be appended to the end of the files' names (following a space)"
                )

                group "File naming continued"(
                    editText phraseToSplitWithEditText "Phrase to split with:" text:"" enabled:false

                    spinner numberOfIndicesToRemoveFromStartSpinner "Number of indices to remove from start:" type:#integer range:[0,100,0] enabled:false

                    spinner numberOfIndicesToRemoveFromEndSpinner "Number of indices to remove from end:" type:#integer range:[0,100,0] enabled:false
                )

                group "Layering"(
                    editText layerToMoveObjectsIntoEditText "Name of layer to place objects in:" text:"" enabled:true tooltip: "For nested layers, provide all layer names in the hierarchy, starting with the topmost layer, separated by \'>\'. No text entered will result in objects being placed in the default layer."
                )

                group "Maps"(
                    checkbox relinkMapsCheckbox "Relink Maps" checked:false enabled:true tooltip:"If checked, all maps will be relinked to the maps directory created within the new folder structure during processing"
                )

            -- Execution

                button processButton "Process"

        -- Actions

            -- Main

                -- Folders

                    on originalFolderEditText entered txt do(
                        if txt != "" then(
                            originalFolderPathText = txt

                            -- Update dropdown list

                                try(
                                    listOfOriginalVolumeNames = getDirectories (txt + "/*")

                                    -- sort listOfOriginalVolumeNames

                                    for a = 1 to listOfOriginalVolumeNames.count do(
                                        insertItem ((filterString (listOfOriginalVolumeNames[a]) "\\")[(filterString (listOfOriginalVolumeNames[a]) "\\").count]) listOfOriginalVolumeNames (a + 1)

                                        deleteItem listOfOriginalVolumeNames a
                                    )

                                    volumeToConfigureDropDownList.items = listOfOriginalVolumeNames
                                )catch()

                            -- Other components

                                -- Dropdown

                                    volumeToConfigureDropDownList.enabled = true

                                    volumeToConfigureDropDownListEnabled = true

                                -- Naming

                                    useOriginalVolumeNameAsSuffixCheckBox.enabled = true

                                    useOriginalVolumeNameAsSuffixCheckBoxEnabled1 = true
                                    useOriginalVolumeNameAsSuffixCheckBoxEnabled2 = true
                                    useOriginalVolumeNameAsSuffixCheckBoxEnabled3 = true
                                    useOriginalVolumeNameAsSuffixCheckBoxEnabled4 = true
                                    useOriginalVolumeNameAsSuffixCheckBoxEnabled5 = true
                                    useOriginalVolumeNameAsSuffixCheckBoxEnabled6 = true
                                    useOriginalVolumeNameAsSuffixCheckBoxEnabled7 = true
                                    useOriginalVolumeNameAsSuffixCheckBoxEnabled8 = true
                                    useOriginalVolumeNameAsSuffixCheckBoxEnabled9 = true
                                    useOriginalVolumeNameAsSuffixCheckBoxEnabled10 = true
                                    useOriginalVolumeNameAsSuffixCheckBoxEnabled11 = true
                                    useOriginalVolumeNameAsSuffixCheckBoxEnabled12 = true
                                    useOriginalVolumeNameAsSuffixCheckBoxEnabled13 = true
                                    useOriginalVolumeNameAsSuffixCheckBoxEnabled14 = true
                                    useOriginalVolumeNameAsSuffixCheckBoxEnabled15 = true
                                    useOriginalVolumeNameAsSuffixCheckBoxEnabled16 = true
                                    useOriginalVolumeNameAsSuffixCheckBoxEnabled17 = true
                                    useOriginalVolumeNameAsSuffixCheckBoxEnabled18 = true
                                    useOriginalVolumeNameAsSuffixCheckBoxEnabled19 = true
                                    useOriginalVolumeNameAsSuffixCheckBoxEnabled20 = true

                                    volumeNameSuffixEditText.enabled = false

                                    volumeNameSuffixEditTextEnabled1 = false
                                    volumeNameSuffixEditTextEnabled2 = false
                                    volumeNameSuffixEditTextEnabled3 = false
                                    volumeNameSuffixEditTextEnabled4 = false
                                    volumeNameSuffixEditTextEnabled5 = false
                                    volumeNameSuffixEditTextEnabled6 = false
                                    volumeNameSuffixEditTextEnabled7 = false
                                    volumeNameSuffixEditTextEnabled8 = false
                                    volumeNameSuffixEditTextEnabled9 = false
                                    volumeNameSuffixEditTextEnabled10 = false
                                    volumeNameSuffixEditTextEnabled11 = false
                                    volumeNameSuffixEditTextEnabled12 = false
                                    volumeNameSuffixEditTextEnabled13 = false
                                    volumeNameSuffixEditTextEnabled14 = false
                                    volumeNameSuffixEditTextEnabled15 = false
                                    volumeNameSuffixEditTextEnabled16 = false
                                    volumeNameSuffixEditTextEnabled17 = false
                                    volumeNameSuffixEditTextEnabled18 = false
                                    volumeNameSuffixEditTextEnabled19 = false
                                    volumeNameSuffixEditTextEnabled20 = false

                                    fileNameExtraTextEditText.enabled = true

                                    fileNameExtraTextEditTextEnabled1 = true
                                    fileNameExtraTextEditTextEnabled2 = true
                                    fileNameExtraTextEditTextEnabled3 = true
                                    fileNameExtraTextEditTextEnabled4 = true
                                    fileNameExtraTextEditTextEnabled5 = true
                                    fileNameExtraTextEditTextEnabled6 = true
                                    fileNameExtraTextEditTextEnabled7 = true
                                    fileNameExtraTextEditTextEnabled8 = true
                                    fileNameExtraTextEditTextEnabled9 = true
                                    fileNameExtraTextEditTextEnabled10 = true
                                    fileNameExtraTextEditTextEnabled11 = true
                                    fileNameExtraTextEditTextEnabled12 = true
                                    fileNameExtraTextEditTextEnabled13 = true
                                    fileNameExtraTextEditTextEnabled14 = true
                                    fileNameExtraTextEditTextEnabled15 = true
                                    fileNameExtraTextEditTextEnabled16 = true
                                    fileNameExtraTextEditTextEnabled17 = true
                                    fileNameExtraTextEditTextEnabled18 = true
                                    fileNameExtraTextEditTextEnabled19 = true
                                    fileNameExtraTextEditTextEnabled20 = true

                                    keywordFilterEditText.enabled = true

                                    keywordFilterEditTextEnabled1 = true
                                    keywordFilterEditTextEnabled2 = true
                                    keywordFilterEditTextEnabled3 = true
                                    keywordFilterEditTextEnabled4 = true
                                    keywordFilterEditTextEnabled5 = true
                                    keywordFilterEditTextEnabled6 = true
                                    keywordFilterEditTextEnabled7 = true
                                    keywordFilterEditTextEnabled8 = true
                                    keywordFilterEditTextEnabled9 = true
                                    keywordFilterEditTextEnabled10 = true
                                    keywordFilterEditTextEnabled11 = true
                                    keywordFilterEditTextEnabled12 = true
                                    keywordFilterEditTextEnabled13 = true
                                    keywordFilterEditTextEnabled14 = true
                                    keywordFilterEditTextEnabled15 = true
                                    keywordFilterEditTextEnabled16 = true
                                    keywordFilterEditTextEnabled17 = true
                                    keywordFilterEditTextEnabled18 = true
                                    keywordFilterEditTextEnabled19 = true
                                    keywordFilterEditTextEnabled20 = true

                                -- Convert scene to Vray

                                    convertSceneToVrayOrCoronaCheckbox.enabled = true

                                    convertSceneToVrayOrCoronaCheckboxEnabled1 = true
                                    convertSceneToVrayOrCoronaCheckboxEnabled2 = true
                                    convertSceneToVrayOrCoronaCheckboxEnabled3 = true
                                    convertSceneToVrayOrCoronaCheckboxEnabled4 = true
                                    convertSceneToVrayOrCoronaCheckboxEnabled5 = true
                                    convertSceneToVrayOrCoronaCheckboxEnabled6 = true
                                    convertSceneToVrayOrCoronaCheckboxEnabled7 = true
                                    convertSceneToVrayOrCoronaCheckboxEnabled8 = true
                                    convertSceneToVrayOrCoronaCheckboxEnabled9 = true
                                    convertSceneToVrayOrCoronaCheckboxEnabled10 = true
                                    convertSceneToVrayOrCoronaCheckboxEnabled11 = true
                                    convertSceneToVrayOrCoronaCheckboxEnabled12 = true
                                    convertSceneToVrayOrCoronaCheckboxEnabled13 = true
                                    convertSceneToVrayOrCoronaCheckboxEnabled14 = true
                                    convertSceneToVrayOrCoronaCheckboxEnabled15 = true
                                    convertSceneToVrayOrCoronaCheckboxEnabled16 = true
                                    convertSceneToVrayOrCoronaCheckboxEnabled17 = true
                                    convertSceneToVrayOrCoronaCheckboxEnabled18 = true
                                    convertSceneToVrayOrCoronaCheckboxEnabled19 = true
                                    convertSceneToVrayOrCoronaCheckboxEnabled20 = true

                                -- Object handling

                                    -- Save each object separately

                                        saveEachObjectSeparatelyCheckBox.enabled = true

                                        saveEachObjectSeparatelyCheckBoxEnabled1 = true
                                        saveEachObjectSeparatelyCheckBoxEnabled2 = true
                                        saveEachObjectSeparatelyCheckBoxEnabled3 = true
                                        saveEachObjectSeparatelyCheckBoxEnabled4 = true
                                        saveEachObjectSeparatelyCheckBoxEnabled5 = true
                                        saveEachObjectSeparatelyCheckBoxEnabled6 = true
                                        saveEachObjectSeparatelyCheckBoxEnabled7 = true
                                        saveEachObjectSeparatelyCheckBoxEnabled8 = true
                                        saveEachObjectSeparatelyCheckBoxEnabled9 = true
                                        saveEachObjectSeparatelyCheckBoxEnabled10 = true
                                        saveEachObjectSeparatelyCheckBoxEnabled11 = true
                                        saveEachObjectSeparatelyCheckBoxEnabled12 = true
                                        saveEachObjectSeparatelyCheckBoxEnabled13 = true
                                        saveEachObjectSeparatelyCheckBoxEnabled14 = true
                                        saveEachObjectSeparatelyCheckBoxEnabled15 = true
                                        saveEachObjectSeparatelyCheckBoxEnabled16 = true
                                        saveEachObjectSeparatelyCheckBoxEnabled17 = true
                                        saveEachObjectSeparatelyCheckBoxEnabled18 = true
                                        saveEachObjectSeparatelyCheckBoxEnabled19 = true
                                        saveEachObjectSeparatelyCheckBoxEnabled20 = true

                                    -- Attach objects

                                        attachObjectsCheckBox.enabled = true

                                        attachObjectsCheckBoxEnabled1 = true
                                        attachObjectsCheckBoxEnabled2 = true
                                        attachObjectsCheckBoxEnabled3 = true
                                        attachObjectsCheckBoxEnabled4 = true
                                        attachObjectsCheckBoxEnabled5 = true
                                        attachObjectsCheckBoxEnabled6 = true
                                        attachObjectsCheckBoxEnabled7 = true
                                        attachObjectsCheckBoxEnabled8 = true
                                        attachObjectsCheckBoxEnabled9 = true
                                        attachObjectsCheckBoxEnabled10 = true
                                        attachObjectsCheckBoxEnabled11 = true
                                        attachObjectsCheckBoxEnabled12 = true
                                        attachObjectsCheckBoxEnabled13 = true
                                        attachObjectsCheckBoxEnabled14 = true
                                        attachObjectsCheckBoxEnabled15 = true
                                        attachObjectsCheckBoxEnabled16 = true
                                        attachObjectsCheckBoxEnabled17 = true
                                        attachObjectsCheckBoxEnabled18 = true
                                        attachObjectsCheckBoxEnabled19 = true
                                        attachObjectsCheckBoxEnabled20 = true

                                    -- Proxy objects

                                        proxyObjectsCheckBox.enabled = true

                                        proxyObjectsCheckBoxEnabled1 = true
                                        proxyObjectsCheckBoxEnabled2 = true
                                        proxyObjectsCheckBoxEnabled3 = true
                                        proxyObjectsCheckBoxEnabled4 = true
                                        proxyObjectsCheckBoxEnabled5 = true
                                        proxyObjectsCheckBoxEnabled6 = true
                                        proxyObjectsCheckBoxEnabled7 = true
                                        proxyObjectsCheckBoxEnabled8 = true
                                        proxyObjectsCheckBoxEnabled9 = true
                                        proxyObjectsCheckBoxEnabled10 = true
                                        proxyObjectsCheckBoxEnabled11 = true
                                        proxyObjectsCheckBoxEnabled12 = true
                                        proxyObjectsCheckBoxEnabled13 = true
                                        proxyObjectsCheckBoxEnabled14 = true
                                        proxyObjectsCheckBoxEnabled15 = true
                                        proxyObjectsCheckBoxEnabled16 = true
                                        proxyObjectsCheckBoxEnabled17 = true
                                        proxyObjectsCheckBoxEnabled18 = true
                                        proxyObjectsCheckBoxEnabled19 = true
                                        proxyObjectsCheckBoxEnabled20 = true

                                    -- Number of faces

                                        facesNumberSpinner.enabled = true

                                        facesNumberSpinnerEnabled1 = true
                                        facesNumberSpinnerEnabled2 = true
                                        facesNumberSpinnerEnabled3 = true
                                        facesNumberSpinnerEnabled4 = true
                                        facesNumberSpinnerEnabled5 = true
                                        facesNumberSpinnerEnabled6 = true
                                        facesNumberSpinnerEnabled7 = true
                                        facesNumberSpinnerEnabled8 = true
                                        facesNumberSpinnerEnabled9 = true
                                        facesNumberSpinnerEnabled10 = true
                                        facesNumberSpinnerEnabled11 = true
                                        facesNumberSpinnerEnabled12 = true
                                        facesNumberSpinnerEnabled13 = true
                                        facesNumberSpinnerEnabled14 = true
                                        facesNumberSpinnerEnabled15 = true
                                        facesNumberSpinnerEnabled16 = true
                                        facesNumberSpinnerEnabled17 = true
                                        facesNumberSpinnerEnabled18 = true
                                        facesNumberSpinnerEnabled19 = true
                                        facesNumberSpinnerEnabled20 = true

                                    -- Corona

                                        coronaCheckbox.enabled = true

                                        coronaCheckboxEnabled1 = true
                                        coronaCheckboxEnabled2 = true
                                        coronaCheckboxEnabled3 = true
                                        coronaCheckboxEnabled4 = true
                                        coronaCheckboxEnabled5 = true
                                        coronaCheckboxEnabled6 = true
                                        coronaCheckboxEnabled7 = true
                                        coronaCheckboxEnabled8 = true
                                        coronaCheckboxEnabled9 = true
                                        coronaCheckboxEnabled10 = true
                                        coronaCheckboxEnabled11 = true
                                        coronaCheckboxEnabled12 = true
                                        coronaCheckboxEnabled13 = true
                                        coronaCheckboxEnabled14 = true
                                        coronaCheckboxEnabled15 = true
                                        coronaCheckboxEnabled16 = true
                                        coronaCheckboxEnabled17 = true
                                        coronaCheckboxEnabled18 = true
                                        coronaCheckboxEnabled19 = true
                                        coronaCheckboxEnabled20 = true

                                -- Output Filters

                                    includeCamerasCheckbox.enabled = true

                                    includeCamerasCheckboxEnabled1 = true
                                    includeCamerasCheckboxEnabled2 = true
                                    includeCamerasCheckboxEnabled3 = true
                                    includeCamerasCheckboxEnabled4 = true
                                    includeCamerasCheckboxEnabled5 = true
                                    includeCamerasCheckboxEnabled6 = true
                                    includeCamerasCheckboxEnabled7 = true
                                    includeCamerasCheckboxEnabled8 = true
                                    includeCamerasCheckboxEnabled9 = true
                                    includeCamerasCheckboxEnabled10 = true
                                    includeCamerasCheckboxEnabled11 = true
                                    includeCamerasCheckboxEnabled12 = true
                                    includeCamerasCheckboxEnabled13 = true
                                    includeCamerasCheckboxEnabled14 = true
                                    includeCamerasCheckboxEnabled15 = true
                                    includeCamerasCheckboxEnabled16 = true
                                    includeCamerasCheckboxEnabled17 = true
                                    includeCamerasCheckboxEnabled18 = true
                                    includeCamerasCheckboxEnabled19 = true
                                    includeCamerasCheckboxEnabled20 = true

                                    includeLightsCheckbox.enabled = true

                                    includeLightsCheckboxEnabled1 = true
                                    includeLightsCheckboxEnabled2 = true
                                    includeLightsCheckboxEnabled3 = true
                                    includeLightsCheckboxEnabled4 = true
                                    includeLightsCheckboxEnabled5 = true
                                    includeLightsCheckboxEnabled6 = true
                                    includeLightsCheckboxEnabled7 = true
                                    includeLightsCheckboxEnabled8 = true
                                    includeLightsCheckboxEnabled9 = true
                                    includeLightsCheckboxEnabled10 = true
                                    includeLightsCheckboxEnabled11 = true
                                    includeLightsCheckboxEnabled12 = true
                                    includeLightsCheckboxEnabled13 = true
                                    includeLightsCheckboxEnabled14 = true
                                    includeLightsCheckboxEnabled15 = true
                                    includeLightsCheckboxEnabled16 = true
                                    includeLightsCheckboxEnabled17 = true
                                    includeLightsCheckboxEnabled18 = true
                                    includeLightsCheckboxEnabled19 = true
                                    includeLightsCheckboxEnabled20 = true

                                -- File naming

                                    replaceAllTextCheckBox.enabled = true

                                    replaceAllTextCheckBoxEnabled1 = true
                                    replaceAllTextCheckBoxEnabled2 = true
                                    replaceAllTextCheckBoxEnabled3 = true
                                    replaceAllTextCheckBoxEnabled4 = true
                                    replaceAllTextCheckBoxEnabled5 = true
                                    replaceAllTextCheckBoxEnabled6 = true
                                    replaceAllTextCheckBoxEnabled7 = true
                                    replaceAllTextCheckBoxEnabled8 = true
                                    replaceAllTextCheckBoxEnabled9 = true
                                    replaceAllTextCheckBoxEnabled10 = true
                                    replaceAllTextCheckBoxEnabled11 = true
                                    replaceAllTextCheckBoxEnabled12 = true
                                    replaceAllTextCheckBoxEnabled13 = true
                                    replaceAllTextCheckBoxEnabled14 = true
                                    replaceAllTextCheckBoxEnabled15 = true
                                    replaceAllTextCheckBoxEnabled16 = true
                                    replaceAllTextCheckBoxEnabled17 = true
                                    replaceAllTextCheckBoxEnabled18 = true
                                    replaceAllTextCheckBoxEnabled19 = true
                                    replaceAllTextCheckBoxEnabled20 = true

                                    retainSpecifiedTextFromFileNameCheckBox.enabled = true

                                    retainSpecifiedTextFromFileNameCheckBoxEnabled1 = true
                                    retainSpecifiedTextFromFileNameCheckBoxEnabled2 = true
                                    retainSpecifiedTextFromFileNameCheckBoxEnabled3 = true
                                    retainSpecifiedTextFromFileNameCheckBoxEnabled4 = true
                                    retainSpecifiedTextFromFileNameCheckBoxEnabled5 = true
                                    retainSpecifiedTextFromFileNameCheckBoxEnabled6 = true
                                    retainSpecifiedTextFromFileNameCheckBoxEnabled7 = true
                                    retainSpecifiedTextFromFileNameCheckBoxEnabled8 = true
                                    retainSpecifiedTextFromFileNameCheckBoxEnabled9 = true
                                    retainSpecifiedTextFromFileNameCheckBoxEnabled10 = true
                                    retainSpecifiedTextFromFileNameCheckBoxEnabled11 = true
                                    retainSpecifiedTextFromFileNameCheckBoxEnabled12 = true
                                    retainSpecifiedTextFromFileNameCheckBoxEnabled13 = true
                                    retainSpecifiedTextFromFileNameCheckBoxEnabled14 = true
                                    retainSpecifiedTextFromFileNameCheckBoxEnabled15 = true
                                    retainSpecifiedTextFromFileNameCheckBoxEnabled16 = true
                                    retainSpecifiedTextFromFileNameCheckBoxEnabled17 = true
                                    retainSpecifiedTextFromFileNameCheckBoxEnabled18 = true
                                    retainSpecifiedTextFromFileNameCheckBoxEnabled19 = true
                                    retainSpecifiedTextFromFileNameCheckBoxEnabled20 = true

                                    retainSpecifiedTextFromObjectNameCheckBox.enabled = true

                                    retainSpecifiedTextFromObjectNameCheckBoxEnabled1 = true
                                    retainSpecifiedTextFromObjectNameCheckBoxEnabled2 = true
                                    retainSpecifiedTextFromObjectNameCheckBoxEnabled3 = true
                                    retainSpecifiedTextFromObjectNameCheckBoxEnabled4 = true
                                    retainSpecifiedTextFromObjectNameCheckBoxEnabled5 = true
                                    retainSpecifiedTextFromObjectNameCheckBoxEnabled6 = true
                                    retainSpecifiedTextFromObjectNameCheckBoxEnabled7 = true
                                    retainSpecifiedTextFromObjectNameCheckBoxEnabled8 = true
                                    retainSpecifiedTextFromObjectNameCheckBoxEnabled9 = true
                                    retainSpecifiedTextFromObjectNameCheckBoxEnabled10 = true
                                    retainSpecifiedTextFromObjectNameCheckBoxEnabled11 = true
                                    retainSpecifiedTextFromObjectNameCheckBoxEnabled12 = true
                                    retainSpecifiedTextFromObjectNameCheckBoxEnabled13 = true
                                    retainSpecifiedTextFromObjectNameCheckBoxEnabled14 = true
                                    retainSpecifiedTextFromObjectNameCheckBoxEnabled15 = true
                                    retainSpecifiedTextFromObjectNameCheckBoxEnabled16 = true
                                    retainSpecifiedTextFromObjectNameCheckBoxEnabled17 = true
                                    retainSpecifiedTextFromObjectNameCheckBoxEnabled18 = true
                                    retainSpecifiedTextFromObjectNameCheckBoxEnabled19 = true
                                    retainSpecifiedTextFromObjectNameCheckBoxEnabled20 = true

                                    retainAllTextFromFileNameCheckBox.enabled = true

                                    retainAllTextFromFileNameCheckBoxEnabled1 = true
                                    retainAllTextFromFileNameCheckBoxEnabled2 = true
                                    retainAllTextFromFileNameCheckBoxEnabled3 = true
                                    retainAllTextFromFileNameCheckBoxEnabled4 = true
                                    retainAllTextFromFileNameCheckBoxEnabled5 = true
                                    retainAllTextFromFileNameCheckBoxEnabled6 = true
                                    retainAllTextFromFileNameCheckBoxEnabled7 = true
                                    retainAllTextFromFileNameCheckBoxEnabled8 = true
                                    retainAllTextFromFileNameCheckBoxEnabled9 = true
                                    retainAllTextFromFileNameCheckBoxEnabled10 = true
                                    retainAllTextFromFileNameCheckBoxEnabled11 = true
                                    retainAllTextFromFileNameCheckBoxEnabled12 = true
                                    retainAllTextFromFileNameCheckBoxEnabled13 = true
                                    retainAllTextFromFileNameCheckBoxEnabled14 = true
                                    retainAllTextFromFileNameCheckBoxEnabled15 = true
                                    retainAllTextFromFileNameCheckBoxEnabled16 = true
                                    retainAllTextFromFileNameCheckBoxEnabled17 = true
                                    retainAllTextFromFileNameCheckBoxEnabled18 = true
                                    retainAllTextFromFileNameCheckBoxEnabled19 = true
                                    retainAllTextFromFileNameCheckBoxEnabled20 = true

                                -- File naming continued

                                    phraseToSplitWithEditText.enabled = false

                                    phraseToSplitWithEditTextEnabled1 = false
                                    phraseToSplitWithEditTextEnabled2 = false
                                    phraseToSplitWithEditTextEnabled3 = false
                                    phraseToSplitWithEditTextEnabled4 = false
                                    phraseToSplitWithEditTextEnabled5 = false
                                    phraseToSplitWithEditTextEnabled6 = false
                                    phraseToSplitWithEditTextEnabled7 = false
                                    phraseToSplitWithEditTextEnabled8 = false
                                    phraseToSplitWithEditTextEnabled9 = false
                                    phraseToSplitWithEditTextEnabled10 = false
                                    phraseToSplitWithEditTextEnabled11 = false
                                    phraseToSplitWithEditTextEnabled12 = false
                                    phraseToSplitWithEditTextEnabled13 = false
                                    phraseToSplitWithEditTextEnabled14 = false
                                    phraseToSplitWithEditTextEnabled15 = false
                                    phraseToSplitWithEditTextEnabled16 = false
                                    phraseToSplitWithEditTextEnabled17 = false
                                    phraseToSplitWithEditTextEnabled18 = false
                                    phraseToSplitWithEditTextEnabled19 = false
                                    phraseToSplitWithEditTextEnabled20 = false

                                    numberOfIndicesToRemoveFromStartSpinner.enabled = false

                                    numberOfIndicesToRemoveFromStartSpinnerEnabled1 = false
                                    numberOfIndicesToRemoveFromStartSpinnerEnabled2 = false
                                    numberOfIndicesToRemoveFromStartSpinnerEnabled3 = false
                                    numberOfIndicesToRemoveFromStartSpinnerEnabled4 = false
                                    numberOfIndicesToRemoveFromStartSpinnerEnabled5 = false
                                    numberOfIndicesToRemoveFromStartSpinnerEnabled6 = false
                                    numberOfIndicesToRemoveFromStartSpinnerEnabled7 = false
                                    numberOfIndicesToRemoveFromStartSpinnerEnabled8 = false
                                    numberOfIndicesToRemoveFromStartSpinnerEnabled9 = false
                                    numberOfIndicesToRemoveFromStartSpinnerEnabled10 = false
                                    numberOfIndicesToRemoveFromStartSpinnerEnabled11 = false
                                    numberOfIndicesToRemoveFromStartSpinnerEnabled12 = false
                                    numberOfIndicesToRemoveFromStartSpinnerEnabled13 = false
                                    numberOfIndicesToRemoveFromStartSpinnerEnabled14 = false
                                    numberOfIndicesToRemoveFromStartSpinnerEnabled15 = false
                                    numberOfIndicesToRemoveFromStartSpinnerEnabled16 = false
                                    numberOfIndicesToRemoveFromStartSpinnerEnabled17 = false
                                    numberOfIndicesToRemoveFromStartSpinnerEnabled18 = false
                                    numberOfIndicesToRemoveFromStartSpinnerEnabled19 = false
                                    numberOfIndicesToRemoveFromStartSpinnerEnabled20 = false

                                    numberOfIndicesToRemoveFromEndSpinner.enabled = false

                                    numberOfIndicesToRemoveFromEndSpinnerEnabled1 = false
                                    numberOfIndicesToRemoveFromEndSpinnerEnabled2 = false
                                    numberOfIndicesToRemoveFromEndSpinnerEnabled3 = false
                                    numberOfIndicesToRemoveFromEndSpinnerEnabled4 = false
                                    numberOfIndicesToRemoveFromEndSpinnerEnabled5 = false
                                    numberOfIndicesToRemoveFromEndSpinnerEnabled6 = false
                                    numberOfIndicesToRemoveFromEndSpinnerEnabled7 = false
                                    numberOfIndicesToRemoveFromEndSpinnerEnabled8 = false
                                    numberOfIndicesToRemoveFromEndSpinnerEnabled9 = false
                                    numberOfIndicesToRemoveFromEndSpinnerEnabled10 = false
                                    numberOfIndicesToRemoveFromEndSpinnerEnabled11 = false
                                    numberOfIndicesToRemoveFromEndSpinnerEnabled12 = false
                                    numberOfIndicesToRemoveFromEndSpinnerEnabled13 = false
                                    numberOfIndicesToRemoveFromEndSpinnerEnabled14 = false
                                    numberOfIndicesToRemoveFromEndSpinnerEnabled15 = false
                                    numberOfIndicesToRemoveFromEndSpinnerEnabled16 = false
                                    numberOfIndicesToRemoveFromEndSpinnerEnabled17 = false
                                    numberOfIndicesToRemoveFromEndSpinnerEnabled18 = false
                                    numberOfIndicesToRemoveFromEndSpinnerEnabled19 = false
                                    numberOfIndicesToRemoveFromEndSpinnerEnabled20 = false
                        )else(
                            listOfOriginalVolumeNames = #()

                            volumeToConfigureDropDownList.items = listOfOriginalVolumeNames

                            -- Other components

                                -- Dropdown

                                    volumeToConfigureDropDownList.enabled = false
                                    volumeToConfigureDropDownListEnabled = false

                                -- Naming

                                    useOriginalVolumeNameAsSuffixCheckBox.enabled = false
                                    useOriginalVolumeNameAsSuffixCheckBoxEnabled = false

                                    volumeNameSuffixEditText.enabled = false
                                    volumeNameSuffixEditTextEnabled = false

                                    fileNameExtraTextEditText.enabled = false
                                    fileNameExtraTextEditTextEnabled = false

                                    keywordFilterEditText.enabled = false
                                    keywordFilterEditTextEnabled = false

                                -- Convert scene to Vray

                                    convertSceneToVrayOrCoronaCheckbox.enabled = false
                                    convertSceneToVrayOrCoronaCheckboxEnabled = false

                                -- Object handling

                                    saveEachObjectSeparatelyCheckBox.enabled = false

                                    saveEachObjectSeparatelyCheckBoxEnabled1 = false
                                    saveEachObjectSeparatelyCheckBoxEnabled2 = false
                                    saveEachObjectSeparatelyCheckBoxEnabled3 = false
                                    saveEachObjectSeparatelyCheckBoxEnabled4 = false
                                    saveEachObjectSeparatelyCheckBoxEnabled5 = false
                                    saveEachObjectSeparatelyCheckBoxEnabled6 = false
                                    saveEachObjectSeparatelyCheckBoxEnabled7 = false
                                    saveEachObjectSeparatelyCheckBoxEnabled8 = false
                                    saveEachObjectSeparatelyCheckBoxEnabled9 = false
                                    saveEachObjectSeparatelyCheckBoxEnabled10 = false
                                    saveEachObjectSeparatelyCheckBoxEnabled11 = false
                                    saveEachObjectSeparatelyCheckBoxEnabled12 = false
                                    saveEachObjectSeparatelyCheckBoxEnabled13 = false
                                    saveEachObjectSeparatelyCheckBoxEnabled14 = false
                                    saveEachObjectSeparatelyCheckBoxEnabled15 = false
                                    saveEachObjectSeparatelyCheckBoxEnabled16 = false
                                    saveEachObjectSeparatelyCheckBoxEnabled17 = false
                                    saveEachObjectSeparatelyCheckBoxEnabled18 = false
                                    saveEachObjectSeparatelyCheckBoxEnabled19 = false
                                    saveEachObjectSeparatelyCheckBoxEnabled20 = false

                                    attachObjectsCheckBox.enabled = false

                                    attachObjectsCheckBoxEnabled1 = false
                                    attachObjectsCheckBoxEnabled2 = false
                                    attachObjectsCheckBoxEnabled3 = false
                                    attachObjectsCheckBoxEnabled4 = false
                                    attachObjectsCheckBoxEnabled5 = false
                                    attachObjectsCheckBoxEnabled6 = false
                                    attachObjectsCheckBoxEnabled7 = false
                                    attachObjectsCheckBoxEnabled8 = false
                                    attachObjectsCheckBoxEnabled9 = false
                                    attachObjectsCheckBoxEnabled10 = false
                                    attachObjectsCheckBoxEnabled11 = false
                                    attachObjectsCheckBoxEnabled12 = false
                                    attachObjectsCheckBoxEnabled13 = false
                                    attachObjectsCheckBoxEnabled14 = false
                                    attachObjectsCheckBoxEnabled15 = false
                                    attachObjectsCheckBoxEnabled16 = false
                                    attachObjectsCheckBoxEnabled17 = false
                                    attachObjectsCheckBoxEnabled18 = false
                                    attachObjectsCheckBoxEnabled19 = false
                                    attachObjectsCheckBoxEnabled20 = false

                                    proxyObjectsCheckBox.enabled = false

                                    proxyObjectsCheckBoxEnabled1 = false
                                    proxyObjectsCheckBoxEnabled2 = false
                                    proxyObjectsCheckBoxEnabled3 = false
                                    proxyObjectsCheckBoxEnabled4 = false
                                    proxyObjectsCheckBoxEnabled5 = false
                                    proxyObjectsCheckBoxEnabled6 = false
                                    proxyObjectsCheckBoxEnabled7 = false
                                    proxyObjectsCheckBoxEnabled8 = false
                                    proxyObjectsCheckBoxEnabled9 = false
                                    proxyObjectsCheckBoxEnabled10 = false
                                    proxyObjectsCheckBoxEnabled11 = false
                                    proxyObjectsCheckBoxEnabled12 = false
                                    proxyObjectsCheckBoxEnabled13 = false
                                    proxyObjectsCheckBoxEnabled14 = false
                                    proxyObjectsCheckBoxEnabled15 = false
                                    proxyObjectsCheckBoxEnabled16 = false
                                    proxyObjectsCheckBoxEnabled17 = false
                                    proxyObjectsCheckBoxEnabled18 = false
                                    proxyObjectsCheckBoxEnabled19 = false
                                    proxyObjectsCheckBoxEnabled20 = false

                                    facesNumberSpinner.enabled = false

                                    facesNumberSpinnerEnabled1 = false
                                    facesNumberSpinnerEnabled2 = false
                                    facesNumberSpinnerEnabled3 = false
                                    facesNumberSpinnerEnabled4 = false
                                    facesNumberSpinnerEnabled5 = false
                                    facesNumberSpinnerEnabled6 = false
                                    facesNumberSpinnerEnabled7 = false
                                    facesNumberSpinnerEnabled8 = false
                                    facesNumberSpinnerEnabled9 = false
                                    facesNumberSpinnerEnabled10 = false
                                    facesNumberSpinnerEnabled11 = false
                                    facesNumberSpinnerEnabled12 = false
                                    facesNumberSpinnerEnabled13 = false
                                    facesNumberSpinnerEnabled14 = false
                                    facesNumberSpinnerEnabled15 = false
                                    facesNumberSpinnerEnabled16 = false
                                    facesNumberSpinnerEnabled17 = false
                                    facesNumberSpinnerEnabled18 = false
                                    facesNumberSpinnerEnabled19 = false
                                    facesNumberSpinnerEnabled20 = false

                                    coronaCheckbox.enabled = false

                                    coronaCheckboxEnabled1 = false
                                    coronaCheckboxEnabled2 = false
                                    coronaCheckboxEnabled3 = false
                                    coronaCheckboxEnabled4 = false
                                    coronaCheckboxEnabled5 = false
                                    coronaCheckboxEnabled6 = false
                                    coronaCheckboxEnabled7 = false
                                    coronaCheckboxEnabled8 = false
                                    coronaCheckboxEnabled9 = false
                                    coronaCheckboxEnabled10 = false
                                    coronaCheckboxEnabled11 = false
                                    coronaCheckboxEnabled12 = false
                                    coronaCheckboxEnabled13 = false
                                    coronaCheckboxEnabled14 = false
                                    coronaCheckboxEnabled15 = false
                                    coronaCheckboxEnabled16 = false
                                    coronaCheckboxEnabled17 = false
                                    coronaCheckboxEnabled18 = false
                                    coronaCheckboxEnabled19 = false
                                    coronaCheckboxEnabled20 = false

                                -- Output Filters

                                    includeCamerasCheckbox.enabled = false
                                    includeCamerasCheckboxEnabled = false

                                    includeLightsCheckbox.enabled = false
                                    includeLightsCheckboxEnabled = false

                                -- File naming

                                    replaceAllTextCheckBox.enabled = false
                                    replaceAllTextCheckBoxEnabled = false

                                    retainSpecifiedTextFromFileNameCheckBox.enabled = false
                                    retainSpecifiedTextFromFileNameCheckBoxEnabled = false

                                    retainSpecifiedTextFromObjectNameCheckBox.enabled = false
                                    retainSpecifiedTextFromObjectNameCheckBoxEnabled = false

                                    retainAllTextFromFileNameCheckBox.enabled = false
                                    retainAllTextFromFileNameCheckBoxEnabled = false

                                -- File naming continued

                                    phraseToSplitWithEditText.enabled = false
                                    phraseToSplitWithEditTextEnabled = false

                                    numberOfIndicesToRemoveFromStartSpinner.enabled = false
                                    numberOfIndicesToRemoveFromStartSpinnerEnabled = false

                                    numberOfIndicesToRemoveFromEndSpinner.enabled = false
                                    numberOfIndicesToRemoveFromEndSpinnerEnabled = false
                        )
                    )

                    on destinationFolderEditText entered txt do(
                        if txt != "" then(
                            destinationFolderText = txt
                        )
                    )

                -- Volume to configure

                    on volumeToConfigureDropDownList selected arg do(
                        -- Define currentVolumeDropDownListSelectionInteger variable

                            currentVolumeDropDownListSelectionInteger = volumeToConfigureDropDownList.selection

                        -- Other Components

                            if currentVolumeDropDownListSelectionInteger == 1 then(

                                -- Naming

                                    -- useOriginalVolumeNameAsSuffixBoolean

                                        useOriginalVolumeNameAsSuffixCheckBox.checked = useOriginalVolumeNameAsSuffixBoolean1
                                        useOriginalVolumeNameAsSuffixCheckBox.enabled = useOriginalVolumeNameAsSuffixcheckBoxEnabled1

                                        useOriginalVolumeNameAsSuffixCheckBox.checked = useOriginalVolumeNameAsSuffixBoolean1
                                        useOriginalVolumeNameAsSuffixCheckBox.enabled = useOriginalVolumeNameAsSuffixcheckBoxEnabled1

                                    -- volumeNameSuffixString

                                        volumeNameSuffixEditText.text = volumeNameSuffixString1
                                        volumeNameSuffixEditText.enabled = volumeNameSuffixEditTextEnabled1

                                    -- fileNameExtraTextString

                                        fileNameExtraTextEditText.text = fileNameExtraTextString1
                                        fileNameExtraTextEditText.enabled = fileNameExtraTextEditTextEnabled1

                                    -- keywordFilterString

                                        keywordFilterEditText.text = keywordFilterString1
                                        keywordFilterEditText.enabled = keywordFilterEditTextEnabled1

                                -- Convert scene to Vray

                                    convertSceneToVrayOrCoronaCheckBox.checked = convertSceneToVrayOrCoronaBoolean1
                                    convertSceneToVrayOrCoronaCheckBox.enabled = convertSceneToVrayOrCoronacheckBoxEnabled1

                                -- Object handling

                                    -- saveEachObjectSeparatelyBoolean

                                        saveEachObjectSeparatelyCheckBox.checked = saveEachObjectSeparatelyBoolean1
                                        saveEachObjectSeparatelyCheckBox.enabled = saveEachObjectSeparatelycheckBoxEnabled1

                                    -- attachObjectsBoolean

                                        attachObjectsCheckBox.checked = attachObjectsBoolean1
                                        attachObjectsCheckBox.enabled = attachObjectscheckBoxEnabled1

                                    -- proxyObjectsBoolean

                                        proxyObjectsCheckBox.checked = proxyObjectsBoolean1
                                        proxyObjectsCheckBox.enabled = proxyObjectscheckBoxEnabled1

                                    -- facesNumberInteger

                                        facesNumberSpinner.value = facesNumberInteger1
                                        facesNumberSpinner.enabled = facesNumberSpinnerEnabled1

                                    -- coronaBoolean

                                        coronaCheckbox.checked = coronaBoolean1
                                        coronaCheckbox.enabled = coronaCheckboxEnabled1

                                -- Output Filters

                                    -- includeCamerasBoolean

                                        includeCamerasCheckBox.checked = includeCamerasBoolean1
                                        includeCamerasCheckBox.enabled = includeCamerascheckBoxEnabled1

                                    -- includeLightsBoolean

                                        includeLightsCheckBox.checked = includeLightsBoolean1
                                        includeLightsCheckBox.enabled = includeLightscheckBoxEnabled1

                                -- File naming

                                    -- replaceAllTextBoolean

                                        replaceAllTextCheckBox.checked = replaceAllTextBoolean1
                                        replaceAllTextCheckBox.enabled = replaceAllTextcheckBoxEnabled1

                                    -- retainSpecifiedTextFromFileNameBoolean

                                        retainSpecifiedTextFromFileNameCheckBox.checked = retainSpecifiedTextFromFileNameBoolean1
                                        retainSpecifiedTextFromFileNameCheckBox.enabled = retainSpecifiedTextFromFileNamecheckBoxEnabled1

                                    -- retainSpecifiedTextFromObjectNameBoolean

                                        retainSpecifiedTextFromObjectNameCheckBox.checked = retainSpecifiedTextFromObjectNameBoolean1
                                        retainSpecifiedTextFromObjectNameCheckBox.enabled = retainSpecifiedTextFromObjectNamecheckBoxEnabled1

                                    -- retainAllTextFromFileNameBoolean

                                        retainAllTextFromFileNameCheckBox.checked = retainAllTextFromFileNameBoolean1
                                        retainAllTextFromFileNameCheckBox.enabled = retainAllTextFromFileNamecheckBoxEnabled1

                                -- File naming continued

                                    -- phraseToSplitWithString

                                        phraseToSplitWithEditText.text = phraseToSplitWithString1
                                        phraseToSplitWithEditText.enabled = phraseToSplitWithEditTextEnabled1

                                    -- numberOfIndicesToRemoveFromStartInteger

                                        numberOfIndicesToRemoveFromStartSpinner.value = numberOfIndicesToRemoveFromStartInteger1
                                        numberOfIndicesToRemoveFromStartSpinner.enabled = numberOfIndicesToRemoveFromStartSpinnerEnabled1

                                    -- numberOfIndicesToRemoveFromEndInteger

                                        numberOfIndicesToRemoveFromEndSpinner.value = numberOfIndicesToRemoveFromEndInteger1
                                        numberOfIndicesToRemoveFromEndSpinner.enabled = numberOfIndicesToRemoveFromEndSpinnerEnabled1

                                -- Layering

                                    -- layerToMoveObjectsToString

                                        layerToMoveObjectsIntoEditText.text = layerToMoveObjectsToString1
                            )

                            if currentVolumeDropDownListSelectionInteger == 2 then(

                                -- Naming

                                    -- useOriginalVolumeNameAsSuffixBoolean

                                        useOriginalVolumeNameAsSuffixCheckBox.checked = useOriginalVolumeNameAsSuffixBoolean2
                                        useOriginalVolumeNameAsSuffixCheckBox.enabled = useOriginalVolumeNameAsSuffixcheckBoxEnabled2

                                        useOriginalVolumeNameAsSuffixCheckBox.checked = useOriginalVolumeNameAsSuffixBoolean2
                                        useOriginalVolumeNameAsSuffixCheckBox.enabled = useOriginalVolumeNameAsSuffixcheckBoxEnabled2

                                    -- volumeNameSuffixString

                                        volumeNameSuffixEditText.text = volumeNameSuffixString2
                                        volumeNameSuffixEditText.enabled = volumeNameSuffixEditTextEnabled2

                                    -- fileNameExtraTextString

                                        fileNameExtraTextEditText.text = fileNameExtraTextString2
                                        fileNameExtraTextEditText.enabled = fileNameExtraTextEditTextEnabled2

                                    -- keywordFilterString

                                        keywordFilterEditText.text = keywordFilterString2
                                        keywordFilterEditText.enabled = keywordFilterEditTextEnabled2

                                -- Convert scene to Vray

                                    convertSceneToVrayOrCoronaCheckBox.checked = convertSceneToVrayOrCoronaBoolean2
                                    convertSceneToVrayOrCoronaCheckBox.enabled = convertSceneToVrayOrCoronacheckBoxEnabled2

                                -- Object handling

                                    -- saveEachObjectSeparatelyBoolean

                                        saveEachObjectSeparatelyCheckBox.checked = saveEachObjectSeparatelyBoolean2
                                        saveEachObjectSeparatelyCheckBox.enabled = saveEachObjectSeparatelycheckBoxEnabled2

                                    -- attachObjectsBoolean

                                        attachObjectsCheckBox.checked = attachObjectsBoolean2
                                        attachObjectsCheckBox.enabled = attachObjectscheckBoxEnabled2

                                    -- proxyObjectsBoolean

                                        proxyObjectsCheckBox.checked = proxyObjectsBoolean2
                                        proxyObjectsCheckBox.enabled = proxyObjectscheckBoxEnabled2

                                    -- facesNumberInteger

                                        facesNumberSpinner.value = facesNumberInteger2
                                        facesNumberSpinner.enabled = facesNumberSpinnerEnabled2

                                    -- coronaBoolean

                                        coronaCheckbox.checked = coronaBoolean2
                                        coronaCheckbox.enabled = coronaCheckboxEnabled2

                                -- Output Filters

                                    -- includeCamerasBoolean

                                        includeCamerasCheckBox.checked = includeCamerasBoolean2
                                        includeCamerasCheckBox.enabled = includeCamerascheckBoxEnabled2

                                    -- includeLightsBoolean

                                        includeLightsCheckBox.checked = includeLightsBoolean2
                                        includeLightsCheckBox.enabled = includeLightscheckBoxEnabled2

                                -- File naming

                                    -- replaceAllTextBoolean

                                        replaceAllTextCheckBox.checked = replaceAllTextBoolean2
                                        replaceAllTextCheckBox.enabled = replaceAllTextcheckBoxEnabled2

                                    -- retainSpecifiedTextFromFileNameBoolean

                                        retainSpecifiedTextFromFileNameCheckBox.checked = retainSpecifiedTextFromFileNameBoolean2
                                        retainSpecifiedTextFromFileNameCheckBox.enabled = retainSpecifiedTextFromFileNamecheckBoxEnabled2

                                    -- retainSpecifiedTextFromObjectNameBoolean

                                        retainSpecifiedTextFromObjectNameCheckBox.checked = retainSpecifiedTextFromObjectNameBoolean2
                                        retainSpecifiedTextFromObjectNameCheckBox.enabled = retainSpecifiedTextFromObjectNamecheckBoxEnabled2

                                    -- retainAllTextFromFileNameBoolean

                                        retainAllTextFromFileNameCheckBox.checked = retainAllTextFromFileNameBoolean2
                                        retainAllTextFromFileNameCheckBox.enabled = retainAllTextFromFileNamecheckBoxEnabled2

                                -- File naming continued

                                    -- phraseToSplitWithString

                                        phraseToSplitWithEditText.text = phraseToSplitWithString2
                                        phraseToSplitWithEditText.enabled = phraseToSplitWithEditTextEnabled2

                                    -- numberOfIndicesToRemoveFromStartInteger

                                        numberOfIndicesToRemoveFromStartSpinner.value = numberOfIndicesToRemoveFromStartInteger2
                                        numberOfIndicesToRemoveFromStartSpinner.enabled = numberOfIndicesToRemoveFromStartSpinnerEnabled2

                                    -- numberOfIndicesToRemoveFromEndInteger

                                        numberOfIndicesToRemoveFromEndSpinner.value = numberOfIndicesToRemoveFromEndInteger2
                                        numberOfIndicesToRemoveFromEndSpinner.enabled = numberOfIndicesToRemoveFromEndSpinnerEnabled2

                                -- Layering

                                    -- layerToMoveObjectsToString

                                        layerToMoveObjectsIntoEditText.text = layerToMoveObjectsToString2
                            )

                            if currentVolumeDropDownListSelectionInteger == 3 then(

                                -- Naming

                                    -- useOriginalVolumeNameAsSuffixBoolean

                                        useOriginalVolumeNameAsSuffixCheckBox.checked = useOriginalVolumeNameAsSuffixBoolean3
                                        useOriginalVolumeNameAsSuffixCheckBox.enabled = useOriginalVolumeNameAsSuffixcheckBoxEnabled3

                                        useOriginalVolumeNameAsSuffixCheckBox.checked = useOriginalVolumeNameAsSuffixBoolean3
                                        useOriginalVolumeNameAsSuffixCheckBox.enabled = useOriginalVolumeNameAsSuffixcheckBoxEnabled3

                                    -- volumeNameSuffixString

                                        volumeNameSuffixEditText.text = volumeNameSuffixString3
                                        volumeNameSuffixEditText.enabled = volumeNameSuffixEditTextEnabled3

                                    -- fileNameExtraTextString

                                        fileNameExtraTextEditText.text = fileNameExtraTextString3
                                        fileNameExtraTextEditText.enabled = fileNameExtraTextEditTextEnabled3

                                    -- keywordFilterString

                                        keywordFilterEditText.text = keywordFilterString3
                                        keywordFilterEditText.enabled = keywordFilterEditTextEnabled3

                                -- Convert scene to Vray

                                    convertSceneToVrayOrCoronaCheckBox.checked = convertSceneToVrayOrCoronaBoolean3
                                    convertSceneToVrayOrCoronaCheckBox.enabled = convertSceneToVrayOrCoronacheckBoxEnabled3

                                -- Object handling

                                    -- saveEachObjectSeparatelyBoolean

                                        saveEachObjectSeparatelyCheckBox.checked = saveEachObjectSeparatelyBoolean3
                                        saveEachObjectSeparatelyCheckBox.enabled = saveEachObjectSeparatelycheckBoxEnabled3

                                    -- attachObjectsBoolean

                                        attachObjectsCheckBox.checked = attachObjectsBoolean3
                                        attachObjectsCheckBox.enabled = attachObjectscheckBoxEnabled3

                                    -- proxyObjectsBoolean

                                        proxyObjectsCheckBox.checked = proxyObjectsBoolean3
                                        proxyObjectsCheckBox.enabled = proxyObjectscheckBoxEnabled3

                                    -- facesNumberInteger

                                        facesNumberSpinner.value = facesNumberInteger3
                                        facesNumberSpinner.enabled = facesNumberSpinnerEnabled3

                                    -- coronaBoolean

                                        coronaCheckbox.checked = coronaBoolean3
                                        coronaCheckbox.enabled = coronaCheckboxEnabled3

                                -- Output Filters

                                    -- includeCamerasBoolean

                                        includeCamerasCheckBox.checked = includeCamerasBoolean3
                                        includeCamerasCheckBox.enabled = includeCamerascheckBoxEnabled3

                                    -- includeLightsBoolean

                                        includeLightsCheckBox.checked = includeLightsBoolean3
                                        includeLightsCheckBox.enabled = includeLightscheckBoxEnabled3

                                -- File naming

                                    -- replaceAllTextBoolean

                                        replaceAllTextCheckBox.checked = replaceAllTextBoolean3
                                        replaceAllTextCheckBox.enabled = replaceAllTextcheckBoxEnabled3

                                    -- retainSpecifiedTextFromFileNameBoolean

                                        retainSpecifiedTextFromFileNameCheckBox.checked = retainSpecifiedTextFromFileNameBoolean3
                                        retainSpecifiedTextFromFileNameCheckBox.enabled = retainSpecifiedTextFromFileNamecheckBoxEnabled3

                                    -- retainSpecifiedTextFromObjectNameBoolean

                                        retainSpecifiedTextFromObjectNameCheckBox.checked = retainSpecifiedTextFromObjectNameBoolean3
                                        retainSpecifiedTextFromObjectNameCheckBox.enabled = retainSpecifiedTextFromObjectNamecheckBoxEnabled3

                                    -- retainAllTextFromFileNameBoolean

                                        retainAllTextFromFileNameCheckBox.checked = retainAllTextFromFileNameBoolean3
                                        retainAllTextFromFileNameCheckBox.enabled = retainAllTextFromFileNamecheckBoxEnabled3

                                -- File naming continued

                                    -- phraseToSplitWithString

                                        phraseToSplitWithEditText.text = phraseToSplitWithString3
                                        phraseToSplitWithEditText.enabled = phraseToSplitWithEditTextEnabled3

                                    -- numberOfIndicesToRemoveFromStartInteger

                                        numberOfIndicesToRemoveFromStartSpinner.value = numberOfIndicesToRemoveFromStartInteger3
                                        numberOfIndicesToRemoveFromStartSpinner.enabled = numberOfIndicesToRemoveFromStartSpinnerEnabled3

                                    -- numberOfIndicesToRemoveFromEndInteger

                                        numberOfIndicesToRemoveFromEndSpinner.value = numberOfIndicesToRemoveFromEndInteger3
                                        numberOfIndicesToRemoveFromEndSpinner.enabled = numberOfIndicesToRemoveFromEndSpinnerEnabled3

                                -- Layering

                                    -- layerToMoveObjectsToString

                                        layerToMoveObjectsIntoEditText.text = layerToMoveObjectsToString3
                            )

                            if currentVolumeDropDownListSelectionInteger == 4 then(

                                -- Naming

                                    -- useOriginalVolumeNameAsSuffixBoolean

                                        useOriginalVolumeNameAsSuffixCheckBox.checked = useOriginalVolumeNameAsSuffixBoolean4
                                        useOriginalVolumeNameAsSuffixCheckBox.enabled = useOriginalVolumeNameAsSuffixcheckBoxEnabled4

                                        useOriginalVolumeNameAsSuffixCheckBox.checked = useOriginalVolumeNameAsSuffixBoolean4
                                        useOriginalVolumeNameAsSuffixCheckBox.enabled = useOriginalVolumeNameAsSuffixcheckBoxEnabled4

                                    -- volumeNameSuffixString

                                        volumeNameSuffixEditText.text = volumeNameSuffixString4
                                        volumeNameSuffixEditText.enabled = volumeNameSuffixEditTextEnabled4

                                    -- fileNameExtraTextString

                                        fileNameExtraTextEditText.text = fileNameExtraTextString4
                                        fileNameExtraTextEditText.enabled = fileNameExtraTextEditTextEnabled4

                                    -- keywordFilterString

                                        keywordFilterEditText.text = keywordFilterString4
                                        keywordFilterEditText.enabled = keywordFilterEditTextEnabled4

                                -- Convert scene to Vray

                                    convertSceneToVrayOrCoronaCheckBox.checked = convertSceneToVrayOrCoronaBoolean4
                                    convertSceneToVrayOrCoronaCheckBox.enabled = convertSceneToVrayOrCoronacheckBoxEnabled4

                                -- Object handling

                                    -- saveEachObjectSeparatelyBoolean

                                        saveEachObjectSeparatelyCheckBox.checked = saveEachObjectSeparatelyBoolean4
                                        saveEachObjectSeparatelyCheckBox.enabled = saveEachObjectSeparatelycheckBoxEnabled4

                                    -- attachObjectsBoolean

                                        attachObjectsCheckBox.checked = attachObjectsBoolean4
                                        attachObjectsCheckBox.enabled = attachObjectscheckBoxEnabled4

                                    -- proxyObjectsBoolean

                                        proxyObjectsCheckBox.checked = proxyObjectsBoolean4
                                        proxyObjectsCheckBox.enabled = proxyObjectscheckBoxEnabled4

                                    -- facesNumberInteger

                                        facesNumberSpinner.value = facesNumberInteger4
                                        facesNumberSpinner.enabled = facesNumberSpinnerEnabled4

                                    -- coronaBoolean

                                        coronaCheckbox.checked = coronaBoolean4
                                        coronaCheckbox.enabled = coronaCheckboxEnabled4

                                -- Output Filters

                                    -- includeCamerasBoolean

                                        includeCamerasCheckBox.checked = includeCamerasBoolean4
                                        includeCamerasCheckBox.enabled = includeCamerascheckBoxEnabled4

                                    -- includeLightsBoolean

                                        includeLightsCheckBox.checked = includeLightsBoolean4
                                        includeLightsCheckBox.enabled = includeLightscheckBoxEnabled4

                                -- File naming

                                    -- replaceAllTextBoolean

                                        replaceAllTextCheckBox.checked = replaceAllTextBoolean4
                                        replaceAllTextCheckBox.enabled = replaceAllTextcheckBoxEnabled4

                                    -- retainSpecifiedTextFromFileNameBoolean

                                        retainSpecifiedTextFromFileNameCheckBox.checked = retainSpecifiedTextFromFileNameBoolean4
                                        retainSpecifiedTextFromFileNameCheckBox.enabled = retainSpecifiedTextFromFileNamecheckBoxEnabled4

                                    -- retainSpecifiedTextFromObjectNameBoolean

                                        retainSpecifiedTextFromObjectNameCheckBox.checked = retainSpecifiedTextFromObjectNameBoolean4
                                        retainSpecifiedTextFromObjectNameCheckBox.enabled = retainSpecifiedTextFromObjectNamecheckBoxEnabled4

                                    -- retainAllTextFromFileNameBoolean

                                        retainAllTextFromFileNameCheckBox.checked = retainAllTextFromFileNameBoolean4
                                        retainAllTextFromFileNameCheckBox.enabled = retainAllTextFromFileNamecheckBoxEnabled4

                                -- File naming continued

                                    -- phraseToSplitWithString

                                        phraseToSplitWithEditText.text = phraseToSplitWithString4
                                        phraseToSplitWithEditText.enabled = phraseToSplitWithEditTextEnabled4

                                    -- numberOfIndicesToRemoveFromStartInteger

                                        numberOfIndicesToRemoveFromStartSpinner.value = numberOfIndicesToRemoveFromStartInteger4
                                        numberOfIndicesToRemoveFromStartSpinner.enabled = numberOfIndicesToRemoveFromStartSpinnerEnabled4

                                    -- numberOfIndicesToRemoveFromEndInteger

                                        numberOfIndicesToRemoveFromEndSpinner.value = numberOfIndicesToRemoveFromEndInteger4
                                        numberOfIndicesToRemoveFromEndSpinner.enabled = numberOfIndicesToRemoveFromEndSpinnerEnabled4

                                -- Layering

                                    -- layerToMoveObjectsToString

                                        layerToMoveObjectsIntoEditText.text = layerToMoveObjectsToString4
                            )

                            if currentVolumeDropDownListSelectionInteger == 5 then(

                                -- Naming

                                    -- useOriginalVolumeNameAsSuffixBoolean

                                        useOriginalVolumeNameAsSuffixCheckBox.checked = useOriginalVolumeNameAsSuffixBoolean5
                                        useOriginalVolumeNameAsSuffixCheckBox.enabled = useOriginalVolumeNameAsSuffixcheckBoxEnabled5

                                        useOriginalVolumeNameAsSuffixCheckBox.checked = useOriginalVolumeNameAsSuffixBoolean5
                                        useOriginalVolumeNameAsSuffixCheckBox.enabled = useOriginalVolumeNameAsSuffixcheckBoxEnabled5

                                    -- volumeNameSuffixString

                                        volumeNameSuffixEditText.text = volumeNameSuffixString5
                                        volumeNameSuffixEditText.enabled = volumeNameSuffixEditTextEnabled5

                                    -- fileNameExtraTextString

                                        fileNameExtraTextEditText.text = fileNameExtraTextString5
                                        fileNameExtraTextEditText.enabled = fileNameExtraTextEditTextEnabled5

                                    -- keywordFilterString

                                        keywordFilterEditText.text = keywordFilterString5
                                        keywordFilterEditText.enabled = keywordFilterEditTextEnabled5

                                -- Convert scene to Vray

                                    convertSceneToVrayOrCoronaCheckBox.checked = convertSceneToVrayOrCoronaBoolean5
                                    convertSceneToVrayOrCoronaCheckBox.enabled = convertSceneToVrayOrCoronacheckBoxEnabled5

                                -- Object handling

                                    -- saveEachObjectSeparatelyBoolean

                                        saveEachObjectSeparatelyCheckBox.checked = saveEachObjectSeparatelyBoolean5
                                        saveEachObjectSeparatelyCheckBox.enabled = saveEachObjectSeparatelycheckBoxEnabled5

                                    -- attachObjectsBoolean

                                        attachObjectsCheckBox.checked = attachObjectsBoolean5
                                        attachObjectsCheckBox.enabled = attachObjectscheckBoxEnabled5

                                    -- proxyObjectsBoolean

                                        proxyObjectsCheckBox.checked = proxyObjectsBoolean5
                                        proxyObjectsCheckBox.enabled = proxyObjectscheckBoxEnabled5

                                    -- facesNumberInteger

                                        facesNumberSpinner.value = facesNumberInteger5
                                        facesNumberSpinner.enabled = facesNumberSpinnerEnabled5

                                    -- coronaBoolean

                                        coronaCheckbox.checked = coronaBoolean5
                                        coronaCheckbox.enabled = coronaCheckboxEnabled5

                                -- Output Filters

                                    -- includeCamerasBoolean

                                        includeCamerasCheckBox.checked = includeCamerasBoolean5
                                        includeCamerasCheckBox.enabled = includeCamerascheckBoxEnabled5

                                    -- includeLightsBoolean

                                        includeLightsCheckBox.checked = includeLightsBoolean5
                                        includeLightsCheckBox.enabled = includeLightscheckBoxEnabled5

                                -- File naming

                                    -- replaceAllTextBoolean

                                        replaceAllTextCheckBox.checked = replaceAllTextBoolean5
                                        replaceAllTextCheckBox.enabled = replaceAllTextcheckBoxEnabled5

                                    -- retainSpecifiedTextFromFileNameBoolean

                                        retainSpecifiedTextFromFileNameCheckBox.checked = retainSpecifiedTextFromFileNameBoolean5
                                        retainSpecifiedTextFromFileNameCheckBox.enabled = retainSpecifiedTextFromFileNamecheckBoxEnabled5

                                    -- retainSpecifiedTextFromObjectNameBoolean

                                        retainSpecifiedTextFromObjectNameCheckBox.checked = retainSpecifiedTextFromObjectNameBoolean5
                                        retainSpecifiedTextFromObjectNameCheckBox.enabled = retainSpecifiedTextFromObjectNamecheckBoxEnabled5

                                    -- retainAllTextFromFileNameBoolean

                                        retainAllTextFromFileNameCheckBox.checked = retainAllTextFromFileNameBoolean5
                                        retainAllTextFromFileNameCheckBox.enabled = retainAllTextFromFileNamecheckBoxEnabled5

                                -- File naming continued

                                    -- phraseToSplitWithString

                                        phraseToSplitWithEditText.text = phraseToSplitWithString5
                                        phraseToSplitWithEditText.enabled = phraseToSplitWithEditTextEnabled5

                                    -- numberOfIndicesToRemoveFromStartInteger

                                        numberOfIndicesToRemoveFromStartSpinner.value = numberOfIndicesToRemoveFromStartInteger5
                                        numberOfIndicesToRemoveFromStartSpinner.enabled = numberOfIndicesToRemoveFromStartSpinnerEnabled5

                                    -- numberOfIndicesToRemoveFromEndInteger

                                        numberOfIndicesToRemoveFromEndSpinner.value = numberOfIndicesToRemoveFromEndInteger5
                                        numberOfIndicesToRemoveFromEndSpinner.enabled = numberOfIndicesToRemoveFromEndSpinnerEnabled5

                                -- Layering

                                    -- layerToMoveObjectsToString

                                        layerToMoveObjectsIntoEditText.text = layerToMoveObjectsToString5
                            )

                            if currentVolumeDropDownListSelectionInteger == 6 then(

                                -- Naming

                                    -- useOriginalVolumeNameAsSuffixBoolean

                                        useOriginalVolumeNameAsSuffixCheckBox.checked = useOriginalVolumeNameAsSuffixBoolean6
                                        useOriginalVolumeNameAsSuffixCheckBox.enabled = useOriginalVolumeNameAsSuffixcheckBoxEnabled6

                                        useOriginalVolumeNameAsSuffixCheckBox.checked = useOriginalVolumeNameAsSuffixBoolean6
                                        useOriginalVolumeNameAsSuffixCheckBox.enabled = useOriginalVolumeNameAsSuffixcheckBoxEnabled6

                                    -- volumeNameSuffixString

                                        volumeNameSuffixEditText.text = volumeNameSuffixString6
                                        volumeNameSuffixEditText.enabled = volumeNameSuffixEditTextEnabled6

                                    -- fileNameExtraTextString

                                        fileNameExtraTextEditText.text = fileNameExtraTextString6
                                        fileNameExtraTextEditText.enabled = fileNameExtraTextEditTextEnabled6

                                    -- keywordFilterString

                                        keywordFilterEditText.text = keywordFilterString6
                                        keywordFilterEditText.enabled = keywordFilterEditTextEnabled6

                                -- Convert scene to Vray

                                    convertSceneToVrayOrCoronaCheckBox.checked = convertSceneToVrayOrCoronaBoolean6
                                    convertSceneToVrayOrCoronaCheckBox.enabled = convertSceneToVrayOrCoronacheckBoxEnabled6

                                -- Object handling

                                    -- saveEachObjectSeparatelyBoolean

                                        saveEachObjectSeparatelyCheckBox.checked = saveEachObjectSeparatelyBoolean6
                                        saveEachObjectSeparatelyCheckBox.enabled = saveEachObjectSeparatelycheckBoxEnabled6

                                    -- attachObjectsBoolean

                                        attachObjectsCheckBox.checked = attachObjectsBoolean6
                                        attachObjectsCheckBox.enabled = attachObjectscheckBoxEnabled6

                                    -- proxyObjectsBoolean

                                        proxyObjectsCheckBox.checked = proxyObjectsBoolean6
                                        proxyObjectsCheckBox.enabled = proxyObjectscheckBoxEnabled6

                                    -- facesNumberInteger

                                        facesNumberSpinner.value = facesNumberInteger6
                                        facesNumberSpinner.enabled = facesNumberSpinnerEnabled6

                                    -- coronaBoolean

                                        coronaCheckbox.checked = coronaBoolean6
                                        coronaCheckbox.enabled = coronaCheckboxEnabled6

                                -- Output Filters

                                    -- includeCamerasBoolean

                                        includeCamerasCheckBox.checked = includeCamerasBoolean6
                                        includeCamerasCheckBox.enabled = includeCamerascheckBoxEnabled6

                                    -- includeLightsBoolean

                                        includeLightsCheckBox.checked = includeLightsBoolean6
                                        includeLightsCheckBox.enabled = includeLightscheckBoxEnabled6

                                -- File naming

                                    -- replaceAllTextBoolean

                                        replaceAllTextCheckBox.checked = replaceAllTextBoolean6
                                        replaceAllTextCheckBox.enabled = replaceAllTextcheckBoxEnabled6

                                    -- retainSpecifiedTextFromFileNameBoolean

                                        retainSpecifiedTextFromFileNameCheckBox.checked = retainSpecifiedTextFromFileNameBoolean6
                                        retainSpecifiedTextFromFileNameCheckBox.enabled = retainSpecifiedTextFromFileNamecheckBoxEnabled6

                                    -- retainSpecifiedTextFromObjectNameBoolean

                                        retainSpecifiedTextFromObjectNameCheckBox.checked = retainSpecifiedTextFromObjectNameBoolean6
                                        retainSpecifiedTextFromObjectNameCheckBox.enabled = retainSpecifiedTextFromObjectNamecheckBoxEnabled6

                                    -- retainAllTextFromFileNameBoolean

                                        retainAllTextFromFileNameCheckBox.checked = retainAllTextFromFileNameBoolean6
                                        retainAllTextFromFileNameCheckBox.enabled = retainAllTextFromFileNamecheckBoxEnabled6

                                -- File naming continued

                                    -- phraseToSplitWithString

                                        phraseToSplitWithEditText.text = phraseToSplitWithString6
                                        phraseToSplitWithEditText.enabled = phraseToSplitWithEditTextEnabled6

                                    -- numberOfIndicesToRemoveFromStartInteger

                                        numberOfIndicesToRemoveFromStartSpinner.value = numberOfIndicesToRemoveFromStartInteger6
                                        numberOfIndicesToRemoveFromStartSpinner.enabled = numberOfIndicesToRemoveFromStartSpinnerEnabled6

                                    -- numberOfIndicesToRemoveFromEndInteger

                                        numberOfIndicesToRemoveFromEndSpinner.value = numberOfIndicesToRemoveFromEndInteger6
                                        numberOfIndicesToRemoveFromEndSpinner.enabled = numberOfIndicesToRemoveFromEndSpinnerEnabled6

                                -- Layering

                                    -- layerToMoveObjectsToString

                                        layerToMoveObjectsIntoEditText.text = layerToMoveObjectsToString6
                            )

                            if currentVolumeDropDownListSelectionInteger == 7 then(

                                -- Naming

                                    -- useOriginalVolumeNameAsSuffixBoolean

                                        useOriginalVolumeNameAsSuffixCheckBox.checked = useOriginalVolumeNameAsSuffixBoolean7
                                        useOriginalVolumeNameAsSuffixCheckBox.enabled = useOriginalVolumeNameAsSuffixcheckBoxEnabled7

                                        useOriginalVolumeNameAsSuffixCheckBox.checked = useOriginalVolumeNameAsSuffixBoolean7
                                        useOriginalVolumeNameAsSuffixCheckBox.enabled = useOriginalVolumeNameAsSuffixcheckBoxEnabled7

                                    -- volumeNameSuffixString

                                        volumeNameSuffixEditText.text = volumeNameSuffixString7
                                        volumeNameSuffixEditText.enabled = volumeNameSuffixEditTextEnabled7

                                    -- fileNameExtraTextString

                                        fileNameExtraTextEditText.text = fileNameExtraTextString7
                                        fileNameExtraTextEditText.enabled = fileNameExtraTextEditTextEnabled7

                                    -- keywordFilterString

                                        keywordFilterEditText.text = keywordFilterString7
                                        keywordFilterEditText.enabled = keywordFilterEditTextEnabled7

                                -- Convert scene to Vray

                                    convertSceneToVrayOrCoronaCheckBox.checked = convertSceneToVrayOrCoronaBoolean7
                                    convertSceneToVrayOrCoronaCheckBox.enabled = convertSceneToVrayOrCoronacheckBoxEnabled7

                                -- Object handling

                                    -- saveEachObjectSeparatelyBoolean

                                        saveEachObjectSeparatelyCheckBox.checked = saveEachObjectSeparatelyBoolean7
                                        saveEachObjectSeparatelyCheckBox.enabled = saveEachObjectSeparatelycheckBoxEnabled7

                                    -- attachObjectsBoolean

                                        attachObjectsCheckBox.checked = attachObjectsBoolean7
                                        attachObjectsCheckBox.enabled = attachObjectscheckBoxEnabled7

                                    -- proxyObjectsBoolean

                                        proxyObjectsCheckBox.checked = proxyObjectsBoolean7
                                        proxyObjectsCheckBox.enabled = proxyObjectscheckBoxEnabled7

                                    -- facesNumberInteger

                                        facesNumberSpinner.value = facesNumberInteger7
                                        facesNumberSpinner.enabled = facesNumberSpinnerEnabled7

                                    -- coronaBoolean

                                        coronaCheckbox.checked = coronaBoolean7
                                        coronaCheckbox.enabled = coronaCheckboxEnabled7

                                -- Output Filters

                                    -- includeCamerasBoolean

                                        includeCamerasCheckBox.checked = includeCamerasBoolean7
                                        includeCamerasCheckBox.enabled = includeCamerascheckBoxEnabled7

                                    -- includeLightsBoolean

                                        includeLightsCheckBox.checked = includeLightsBoolean7
                                        includeLightsCheckBox.enabled = includeLightscheckBoxEnabled7

                                -- File naming

                                    -- replaceAllTextBoolean

                                        replaceAllTextCheckBox.checked = replaceAllTextBoolean7
                                        replaceAllTextCheckBox.enabled = replaceAllTextcheckBoxEnabled7

                                    -- retainSpecifiedTextFromFileNameBoolean

                                        retainSpecifiedTextFromFileNameCheckBox.checked = retainSpecifiedTextFromFileNameBoolean7
                                        retainSpecifiedTextFromFileNameCheckBox.enabled = retainSpecifiedTextFromFileNamecheckBoxEnabled7

                                    -- retainSpecifiedTextFromObjectNameBoolean

                                        retainSpecifiedTextFromFileNameCheckBox.checked = retainSpecifiedTextFromFileNameBoolean7
                                        retainSpecifiedTextFromFileNameCheckBox.enabled = retainSpecifiedTextFromFileNamecheckBoxEnabled7

                                    -- retainAllTextFromFileNameBoolean

                                        retainAllTextFromFileNameCheckBox.checked = retainAllTextFromFileNameBoolean7
                                        retainAllTextFromFileNameCheckBox.enabled = retainAllTextFromFileNamecheckBoxEnabled7

                                -- File naming continued

                                    -- phraseToSplitWithString

                                        phraseToSplitWithEditText.text = phraseToSplitWithString7
                                        phraseToSplitWithEditText.enabled = phraseToSplitWithEditTextEnabled7

                                    -- numberOfIndicesToRemoveFromStartInteger

                                        numberOfIndicesToRemoveFromStartSpinner.value = numberOfIndicesToRemoveFromStartInteger7
                                        numberOfIndicesToRemoveFromStartSpinner.enabled = numberOfIndicesToRemoveFromStartSpinnerEnabled7

                                    -- numberOfIndicesToRemoveFromEndInteger

                                        numberOfIndicesToRemoveFromEndSpinner.value = numberOfIndicesToRemoveFromEndInteger7
                                        numberOfIndicesToRemoveFromEndSpinner.enabled = numberOfIndicesToRemoveFromEndSpinnerEnabled7

                                -- Layering

                                    -- layerToMoveObjectsToString

                                        layerToMoveObjectsIntoEditText.text = layerToMoveObjectsToString7
                            )

                            if currentVolumeDropDownListSelectionInteger == 8 then(

                                -- Naming

                                    -- useOriginalVolumeNameAsSuffixBoolean

                                        useOriginalVolumeNameAsSuffixCheckBox.checked = useOriginalVolumeNameAsSuffixBoolean8
                                        useOriginalVolumeNameAsSuffixCheckBox.enabled = useOriginalVolumeNameAsSuffixcheckBoxEnabled8

                                        useOriginalVolumeNameAsSuffixCheckBox.checked = useOriginalVolumeNameAsSuffixBoolean8
                                        useOriginalVolumeNameAsSuffixCheckBox.enabled = useOriginalVolumeNameAsSuffixcheckBoxEnabled8

                                    -- volumeNameSuffixString

                                        volumeNameSuffixEditText.text = volumeNameSuffixString8
                                        volumeNameSuffixEditText.enabled = volumeNameSuffixEditTextEnabled8

                                    -- fileNameExtraTextString

                                        fileNameExtraTextEditText.text = fileNameExtraTextString8
                                        fileNameExtraTextEditText.enabled = fileNameExtraTextEditTextEnabled8

                                    -- keywordFilterString

                                        keywordFilterEditText.text = keywordFilterString8
                                        keywordFilterEditText.enabled = keywordFilterEditTextEnabled8

                                -- Convert scene to Vray

                                    convertSceneToVrayOrCoronaCheckBox.checked = convertSceneToVrayOrCoronaBoolean8
                                    convertSceneToVrayOrCoronaCheckBox.enabled = convertSceneToVrayOrCoronacheckBoxEnabled8

                                -- Object handling

                                    -- saveEachObjectSeparatelyBoolean

                                        saveEachObjectSeparatelyCheckBox.checked = saveEachObjectSeparatelyBoolean8
                                        saveEachObjectSeparatelyCheckBox.enabled = saveEachObjectSeparatelycheckBoxEnabled8

                                    -- attachObjectsBoolean

                                        attachObjectsCheckBox.checked = attachObjectsBoolean8
                                        attachObjectsCheckBox.enabled = attachObjectscheckBoxEnabled8

                                    -- proxyObjectsBoolean

                                        proxyObjectsCheckBox.checked = proxyObjectsBoolean8
                                        proxyObjectsCheckBox.enabled = proxyObjectscheckBoxEnabled8

                                    -- facesNumberInteger

                                        facesNumberSpinner.value = facesNumberInteger8
                                        facesNumberSpinner.enabled = facesNumberSpinnerEnabled8

                                    -- coronaBoolean

                                        coronaCheckbox.checked = coronaBoolean8
                                        coronaCheckbox.enabled = coronaCheckboxEnabled8

                                -- Output Filters

                                    -- includeCamerasBoolean

                                        includeCamerasCheckBox.checked = includeCamerasBoolean8
                                        includeCamerasCheckBox.enabled = includeCamerascheckBoxEnabled8

                                    -- includeLightsBoolean

                                        includeLightsCheckBox.checked = includeLightsBoolean8
                                        includeLightsCheckBox.enabled = includeLightscheckBoxEnabled8

                                -- File naming

                                    -- replaceAllTextBoolean

                                        replaceAllTextCheckBox.checked = replaceAllTextBoolean8
                                        replaceAllTextCheckBox.enabled = replaceAllTextcheckBoxEnabled8

                                    -- retainSpecifiedTextFromFileNameBoolean

                                        retainSpecifiedTextFromFileNameCheckBox.checked = retainSpecifiedTextFromFileNameBoolean8
                                        retainSpecifiedTextFromFileNameCheckBox.enabled = retainSpecifiedTextFromFileNamecheckBoxEnabled8

                                    -- retainSpecifiedTextFromObjectNameBoolean

                                        retainSpecifiedTextFromFileNameCheckBox.checked = retainSpecifiedTextFromFileNameBoolean8
                                        retainSpecifiedTextFromFileNameCheckBox.enabled = retainSpecifiedTextFromFileNamecheckBoxEnabled8

                                    -- retainAllTextFromFileNameBoolean

                                        retainAllTextFromFileNameCheckBox.checked = retainAllTextFromFileNameBoolean8
                                        retainAllTextFromFileNameCheckBox.enabled = retainAllTextFromFileNamecheckBoxEnabled8

                                -- File naming continued

                                    -- phraseToSplitWithString

                                        phraseToSplitWithEditText.text = phraseToSplitWithString8
                                        phraseToSplitWithEditText.enabled = phraseToSplitWithEditTextEnabled8

                                    -- numberOfIndicesToRemoveFromStartInteger

                                        numberOfIndicesToRemoveFromStartSpinner.value = numberOfIndicesToRemoveFromStartInteger8
                                        numberOfIndicesToRemoveFromStartSpinner.enabled = numberOfIndicesToRemoveFromStartSpinnerEnabled8

                                    -- numberOfIndicesToRemoveFromEndInteger

                                        numberOfIndicesToRemoveFromEndSpinner.value = numberOfIndicesToRemoveFromEndInteger8
                                        numberOfIndicesToRemoveFromEndSpinner.enabled = numberOfIndicesToRemoveFromEndSpinnerEnabled8

                                -- Layering

                                    -- layerToMoveObjectsToString

                                        layerToMoveObjectsIntoEditText.text = layerToMoveObjectsToString8
                            )

                            if currentVolumeDropDownListSelectionInteger == 9 then(

                                -- Naming

                                    -- useOriginalVolumeNameAsSuffixBoolean

                                        useOriginalVolumeNameAsSuffixCheckBox.checked = useOriginalVolumeNameAsSuffixBoolean9
                                        useOriginalVolumeNameAsSuffixCheckBox.enabled = useOriginalVolumeNameAsSuffixcheckBoxEnabled9

                                        useOriginalVolumeNameAsSuffixCheckBox.checked = useOriginalVolumeNameAsSuffixBoolean9
                                        useOriginalVolumeNameAsSuffixCheckBox.enabled = useOriginalVolumeNameAsSuffixcheckBoxEnabled9

                                    -- volumeNameSuffixString

                                        volumeNameSuffixEditText.text = volumeNameSuffixString9
                                        volumeNameSuffixEditText.enabled = volumeNameSuffixEditTextEnabled9

                                    -- fileNameExtraTextString

                                        fileNameExtraTextEditText.text = fileNameExtraTextString9
                                        fileNameExtraTextEditText.enabled = fileNameExtraTextEditTextEnabled9

                                    -- keywordFilterString

                                        keywordFilterEditText.text = keywordFilterString9
                                        keywordFilterEditText.enabled = keywordFilterEditTextEnabled9

                                -- Convert scene to Vray

                                    convertSceneToVrayOrCoronaCheckBox.checked = convertSceneToVrayOrCoronaBoolean9
                                    convertSceneToVrayOrCoronaCheckBox.enabled = convertSceneToVrayOrCoronacheckBoxEnabled9

                                -- Object handling

                                    -- saveEachObjectSeparatelyBoolean

                                        saveEachObjectSeparatelyCheckBox.checked = saveEachObjectSeparatelyBoolean9
                                        saveEachObjectSeparatelyCheckBox.enabled = saveEachObjectSeparatelycheckBoxEnabled9

                                    -- attachObjectsBoolean

                                        attachObjectsCheckBox.checked = attachObjectsBoolean9
                                        attachObjectsCheckBox.enabled = attachObjectscheckBoxEnabled9

                                    -- proxyObjectsBoolean

                                        proxyObjectsCheckBox.checked = proxyObjectsBoolean9
                                        proxyObjectsCheckBox.enabled = proxyObjectscheckBoxEnabled9

                                    -- facesNumberInteger

                                        facesNumberSpinner.value = facesNumberInteger9
                                        facesNumberSpinner.enabled = facesNumberSpinnerEnabled9

                                    -- coronaBoolean

                                        coronaCheckbox.checked = coronaBoolean9
                                        coronaCheckbox.enabled = coronaCheckboxEnabled9

                                -- Output Filters

                                    -- includeCamerasBoolean

                                        includeCamerasCheckBox.checked = includeCamerasBoolean9
                                        includeCamerasCheckBox.enabled = includeCamerascheckBoxEnabled9

                                    -- includeLightsBoolean

                                        includeLightsCheckBox.checked = includeLightsBoolean9
                                        includeLightsCheckBox.enabled = includeLightscheckBoxEnabled9

                                -- File naming

                                    -- replaceAllTextBoolean

                                        replaceAllTextCheckBox.checked = replaceAllTextBoolean9
                                        replaceAllTextCheckBox.enabled = replaceAllTextcheckBoxEnabled9

                                    -- retainSpecifiedTextFromFileNameBoolean

                                        retainSpecifiedTextFromFileNameCheckBox.checked = retainSpecifiedTextFromFileNameBoolean9
                                        retainSpecifiedTextFromFileNameCheckBox.enabled = retainSpecifiedTextFromFileNamecheckBoxEnabled9

                                    -- retainSpecifiedTextFromObjectNameBoolean

                                        retainSpecifiedTextFromFileNameCheckBox.checked = retainSpecifiedTextFromFileNameBoolean9
                                        retainSpecifiedTextFromFileNameCheckBox.enabled = retainSpecifiedTextFromFileNamecheckBoxEnabled9

                                    -- retainAllTextFromFileNameBoolean

                                        retainAllTextFromFileNameCheckBox.checked = retainAllTextFromFileNameBoolean9
                                        retainAllTextFromFileNameCheckBox.enabled = retainAllTextFromFileNamecheckBoxEnabled9

                                -- File naming continued

                                    -- phraseToSplitWithString

                                        phraseToSplitWithEditText.text = phraseToSplitWithString9
                                        phraseToSplitWithEditText.enabled = phraseToSplitWithEditTextEnabled9

                                    -- numberOfIndicesToRemoveFromStartInteger

                                        numberOfIndicesToRemoveFromStartSpinner.value = numberOfIndicesToRemoveFromStartInteger9
                                        numberOfIndicesToRemoveFromStartSpinner.enabled = numberOfIndicesToRemoveFromStartSpinnerEnabled9

                                    -- numberOfIndicesToRemoveFromEndInteger

                                        numberOfIndicesToRemoveFromEndSpinner.value = numberOfIndicesToRemoveFromEndInteger9
                                        numberOfIndicesToRemoveFromEndSpinner.enabled = numberOfIndicesToRemoveFromEndSpinnerEnabled9

                                -- Layering

                                    -- layerToMoveObjectsToString

                                        layerToMoveObjectsIntoEditText.text = layerToMoveObjectsToString9
                            )

                            if currentVolumeDropDownListSelectionInteger == 10 then(

                                -- Naming

                                    -- useOriginalVolumeNameAsSuffixBoolean

                                        useOriginalVolumeNameAsSuffixCheckBox.checked = useOriginalVolumeNameAsSuffixBoolean10
                                        useOriginalVolumeNameAsSuffixCheckBox.enabled = useOriginalVolumeNameAsSuffixcheckBoxEnabled10

                                        useOriginalVolumeNameAsSuffixCheckBox.checked = useOriginalVolumeNameAsSuffixBoolean10
                                        useOriginalVolumeNameAsSuffixCheckBox.enabled = useOriginalVolumeNameAsSuffixcheckBoxEnabled10

                                    -- volumeNameSuffixString

                                        volumeNameSuffixEditText.text = volumeNameSuffixString10
                                        volumeNameSuffixEditText.enabled = volumeNameSuffixEditTextEnabled10

                                    -- fileNameExtraTextString

                                        fileNameExtraTextEditText.text = fileNameExtraTextString10
                                        fileNameExtraTextEditText.enabled = fileNameExtraTextEditTextEnabled10

                                    -- keywordFilterString

                                        keywordFilterEditText.text = keywordFilterString10
                                        keywordFilterEditText.enabled = keywordFilterEditTextEnabled10

                                -- Convert scene to Vray

                                    convertSceneToVrayOrCoronaCheckBox.checked = convertSceneToVrayOrCoronaBoolean10
                                    convertSceneToVrayOrCoronaCheckBox.enabled = convertSceneToVrayOrCoronacheckBoxEnabled10

                                -- Object handling

                                    -- saveEachObjectSeparatelyBoolean

                                        saveEachObjectSeparatelyCheckBox.checked = saveEachObjectSeparatelyBoolean10
                                        saveEachObjectSeparatelyCheckBox.enabled = saveEachObjectSeparatelycheckBoxEnabled10

                                    -- attachObjectsBoolean

                                        attachObjectsCheckBox.checked = attachObjectsBoolean10
                                        attachObjectsCheckBox.enabled = attachObjectscheckBoxEnabled10

                                      -- proxyObjectsBoolean

                                          proxyObjectsCheckBox.checked = proxyObjectsBoolean10
                                          proxyObjectsCheckBox.enabled = proxyObjectscheckBoxEnabled10

                                    -- facesNumberInteger

                                        facesNumberSpinner.value = facesNumberInteger10
                                        facesNumberSpinner.enabled = facesNumberSpinnerEnabled10

                                    -- coronaBoolean

                                        coronaCheckbox.checked = coronaBoolean10
                                        coronaCheckbox.enabled = coronaCheckboxEnabled10

                                -- Output Filters

                                    -- includeCamerasBoolean

                                        includeCamerasCheckBox.checked = includeCamerasBoolean10
                                        includeCamerasCheckBox.enabled = includeCamerascheckBoxEnabled10

                                    -- includeLightsBoolean

                                        includeLightsCheckBox.checked = includeLightsBoolean10
                                        includeLightsCheckBox.enabled = includeLightscheckBoxEnabled10

                                -- File naming

                                    -- replaceAllTextBoolean

                                        replaceAllTextCheckBox.checked = replaceAllTextBoolean10
                                        replaceAllTextCheckBox.enabled = replaceAllTextcheckBoxEnabled10

                                    -- retainSpecifiedTextFromFileNameBoolean

                                        retainSpecifiedTextFromFileNameCheckBox.checked = retainSpecifiedTextFromFileNameBoolean10
                                        retainSpecifiedTextFromFileNameCheckBox.enabled = retainSpecifiedTextFromFileNamecheckBoxEnabled10

                                    -- retainSpecifiedTextFromObjectNameBoolean

                                        retainSpecifiedTextFromFileNameCheckBox.checked = retainSpecifiedTextFromFileNameBoolean10
                                        retainSpecifiedTextFromFileNameCheckBox.enabled = retainSpecifiedTextFromFileNamecheckBoxEnabled10

                                    -- retainAllTextFromFileNameBoolean

                                        retainAllTextFromFileNameCheckBox.checked = retainAllTextFromFileNameBoolean10
                                        retainAllTextFromFileNameCheckBox.enabled = retainAllTextFromFileNamecheckBoxEnabled10

                                -- File naming continued

                                    -- phraseToSplitWithString

                                        phraseToSplitWithEditText.text = phraseToSplitWithString10
                                        phraseToSplitWithEditText.enabled = phraseToSplitWithEditTextEnabled10

                                    -- numberOfIndicesToRemoveFromStartInteger

                                        numberOfIndicesToRemoveFromStartSpinner.value = numberOfIndicesToRemoveFromStartInteger10
                                        numberOfIndicesToRemoveFromStartSpinner.enabled = numberOfIndicesToRemoveFromStartSpinnerEnabled10

                                    -- numberOfIndicesToRemoveFromEndInteger

                                        numberOfIndicesToRemoveFromEndSpinner.value = numberOfIndicesToRemoveFromEndInteger10
                                        numberOfIndicesToRemoveFromEndSpinner.enabled = numberOfIndicesToRemoveFromEndSpinnerEnabled10

                                -- Layering

                                    -- layerToMoveObjectsToString

                                        layerToMoveObjectsIntoEditText.text = layerToMoveObjectsToString10
                            )

                            if currentVolumeDropDownListSelectionInteger == 11 then(

                                -- Naming

                                    -- useOriginalVolumeNameAsSuffixBoolean

                                        useOriginalVolumeNameAsSuffixCheckBox.checked = useOriginalVolumeNameAsSuffixBoolean11
                                        useOriginalVolumeNameAsSuffixCheckBox.enabled = useOriginalVolumeNameAsSuffixcheckBoxEnabled11

                                        useOriginalVolumeNameAsSuffixCheckBox.checked = useOriginalVolumeNameAsSuffixBoolean11
                                        useOriginalVolumeNameAsSuffixCheckBox.enabled = useOriginalVolumeNameAsSuffixcheckBoxEnabled11

                                    -- volumeNameSuffixString

                                        volumeNameSuffixEditText.text = volumeNameSuffixString11
                                        volumeNameSuffixEditText.enabled = volumeNameSuffixEditTextEnabled11

                                    -- fileNameExtraTextString

                                        fileNameExtraTextEditText.text = fileNameExtraTextString11
                                        fileNameExtraTextEditText.enabled = fileNameExtraTextEditTextEnabled11

                                    -- keywordFilterString

                                        keywordFilterEditText.text = keywordFilterString11
                                        keywordFilterEditText.enabled = keywordFilterEditTextEnabled11

                                -- Convert scene to Vray

                                    convertSceneToVrayOrCoronaCheckBox.checked = convertSceneToVrayOrCoronaBoolean11
                                    convertSceneToVrayOrCoronaCheckBox.enabled = convertSceneToVrayOrCoronacheckBoxEnabled11

                                -- Object handling

                                    -- saveEachObjectSeparatelyBoolean

                                        saveEachObjectSeparatelyCheckBox.checked = saveEachObjectSeparatelyBoolean11
                                        saveEachObjectSeparatelyCheckBox.enabled = saveEachObjectSeparatelycheckBoxEnabled11

                                    -- attachObjectsBoolean

                                        attachObjectsCheckBox.checked = attachObjectsBoolean11
                                        attachObjectsCheckBox.enabled = attachObjectscheckBoxEnabled11

                                    -- proxyObjectsBoolean

                                        proxyObjectsCheckBox.checked = proxyObjectsBoolean11
                                        proxyObjectsCheckBox.enabled = proxyObjectscheckBoxEnabled11

                                    -- facesNumberInteger

                                        facesNumberSpinner.value = facesNumberInteger11
                                        facesNumberSpinner.enabled = facesNumberSpinnerEnabled11

                                    -- coronaBoolean

                                        coronaCheckbox.checked = coronaBoolean11
                                        coronaCheckbox.enabled = coronaCheckboxEnabled11

                                -- Output Filters

                                    -- includeCamerasBoolean

                                        includeCamerasCheckBox.checked = includeCamerasBoolean11
                                        includeCamerasCheckBox.enabled = includeCamerascheckBoxEnabled11

                                    -- includeLightsBoolean

                                        includeLightsCheckBox.checked = includeLightsBoolean11
                                        includeLightsCheckBox.enabled = includeLightscheckBoxEnabled11

                                -- File naming

                                    -- replaceAllTextBoolean

                                        replaceAllTextCheckBox.checked = replaceAllTextBoolean11
                                        replaceAllTextCheckBox.enabled = replaceAllTextcheckBoxEnabled11

                                    -- retainSpecifiedTextFromFileNameBoolean

                                        retainSpecifiedTextFromFileNameCheckBox.checked = retainSpecifiedTextFromFileNameBoolean11
                                        retainSpecifiedTextFromFileNameCheckBox.enabled = retainSpecifiedTextFromFileNamecheckBoxEnabled11

                                    -- retainSpecifiedTextFromObjectNameBoolean

                                        retainSpecifiedTextFromFileNameCheckBox.checked = retainSpecifiedTextFromFileNameBoolean11
                                        retainSpecifiedTextFromFileNameCheckBox.enabled = retainSpecifiedTextFromFileNamecheckBoxEnabled11

                                    -- retainAllTextFromFileNameBoolean

                                        retainAllTextFromFileNameCheckBox.checked = retainAllTextFromFileNameBoolean11
                                        retainAllTextFromFileNameCheckBox.enabled = retainAllTextFromFileNamecheckBoxEnabled11

                                -- File naming continued

                                    -- phraseToSplitWithString

                                        phraseToSplitWithEditText.text = phraseToSplitWithString11
                                        phraseToSplitWithEditText.enabled = phraseToSplitWithEditTextEnabled11

                                    -- numberOfIndicesToRemoveFromStartInteger

                                        numberOfIndicesToRemoveFromStartSpinner.value = numberOfIndicesToRemoveFromStartInteger11
                                        numberOfIndicesToRemoveFromStartSpinner.enabled = numberOfIndicesToRemoveFromStartSpinnerEnabled11

                                    -- numberOfIndicesToRemoveFromEndInteger

                                        numberOfIndicesToRemoveFromEndSpinner.value = numberOfIndicesToRemoveFromEndInteger11
                                        numberOfIndicesToRemoveFromEndSpinner.enabled = numberOfIndicesToRemoveFromEndSpinnerEnabled11

                                -- Layering

                                    -- layerToMoveObjectsToString

                                        layerToMoveObjectsIntoEditText.text = layerToMoveObjectsToString11
                            )

                            if currentVolumeDropDownListSelectionInteger == 12 then(

                                -- Naming

                                    -- useOriginalVolumeNameAsSuffixBoolean

                                        useOriginalVolumeNameAsSuffixCheckBox.checked = useOriginalVolumeNameAsSuffixBoolean12
                                        useOriginalVolumeNameAsSuffixCheckBox.enabled = useOriginalVolumeNameAsSuffixcheckBoxEnabled12

                                        useOriginalVolumeNameAsSuffixCheckBox.checked = useOriginalVolumeNameAsSuffixBoolean12
                                        useOriginalVolumeNameAsSuffixCheckBox.enabled = useOriginalVolumeNameAsSuffixcheckBoxEnabled12

                                    -- volumeNameSuffixString

                                        volumeNameSuffixEditText.text = volumeNameSuffixString12
                                        volumeNameSuffixEditText.enabled = volumeNameSuffixEditTextEnabled12

                                    -- fileNameExtraTextString

                                        fileNameExtraTextEditText.text = fileNameExtraTextString12
                                        fileNameExtraTextEditText.enabled = fileNameExtraTextEditTextEnabled12

                                    -- keywordFilterString

                                        keywordFilterEditText.text = keywordFilterString12
                                        keywordFilterEditText.enabled = keywordFilterEditTextEnabled12

                                -- Convert scene to Vray

                                    convertSceneToVrayOrCoronaCheckBox.checked = convertSceneToVrayOrCoronaBoolean12
                                    convertSceneToVrayOrCoronaCheckBox.enabled = convertSceneToVrayOrCoronacheckBoxEnabled12

                                -- Object handling

                                    -- saveEachObjectSeparatelyBoolean

                                        saveEachObjectSeparatelyCheckBox.checked = saveEachObjectSeparatelyBoolean12
                                        saveEachObjectSeparatelyCheckBox.enabled = saveEachObjectSeparatelycheckBoxEnabled12

                                    -- attachObjectsBoolean

                                        attachObjectsCheckBox.checked = attachObjectsBoolean12
                                        attachObjectsCheckBox.enabled = attachObjectscheckBoxEnabled12

                                    -- proxyObjectsBoolean

                                        proxyObjectsCheckBox.checked = proxyObjectsBoolean12
                                        proxyObjectsCheckBox.enabled = proxyObjectscheckBoxEnabled12

                                    -- facesNumberInteger

                                        facesNumberSpinner.value = facesNumberInteger12
                                        facesNumberSpinner.enabled = facesNumberSpinnerEnabled12

                                    -- coronaBoolean

                                        coronaCheckbox.checked = coronaBoolean12
                                        coronaCheckbox.enabled = coronaCheckboxEnabled12

                                -- Output Filters

                                    -- includeCamerasBoolean

                                        includeCamerasCheckBox.checked = includeCamerasBoolean12
                                        includeCamerasCheckBox.enabled = includeCamerascheckBoxEnabled12

                                    -- includeLightsBoolean

                                        includeLightsCheckBox.checked = includeLightsBoolean12
                                        includeLightsCheckBox.enabled = includeLightscheckBoxEnabled12

                                -- File naming

                                    -- replaceAllTextBoolean

                                        replaceAllTextCheckBox.checked = replaceAllTextBoolean12
                                        replaceAllTextCheckBox.enabled = replaceAllTextcheckBoxEnabled12

                                    -- retainSpecifiedTextFromFileNameBoolean

                                        retainSpecifiedTextFromFileNameCheckBox.checked = retainSpecifiedTextFromFileNameBoolean12
                                        retainSpecifiedTextFromFileNameCheckBox.enabled = retainSpecifiedTextFromFileNamecheckBoxEnabled12

                                    -- retainSpecifiedTextFromObjectNameBoolean

                                        retainSpecifiedTextFromFileNameCheckBox.checked = retainSpecifiedTextFromFileNameBoolean12
                                        retainSpecifiedTextFromFileNameCheckBox.enabled = retainSpecifiedTextFromFileNamecheckBoxEnabled12

                                    -- retainAllTextFromFileNameBoolean

                                        retainAllTextFromFileNameCheckBox.checked = retainAllTextFromFileNameBoolean12
                                        retainAllTextFromFileNameCheckBox.enabled = retainAllTextFromFileNamecheckBoxEnabled12

                                -- File naming continued

                                    -- phraseToSplitWithString

                                        phraseToSplitWithEditText.text = phraseToSplitWithString12
                                        phraseToSplitWithEditText.enabled = phraseToSplitWithEditTextEnabled12

                                    -- numberOfIndicesToRemoveFromStartInteger

                                        numberOfIndicesToRemoveFromStartSpinner.value = numberOfIndicesToRemoveFromStartInteger12
                                        numberOfIndicesToRemoveFromStartSpinner.enabled = numberOfIndicesToRemoveFromStartSpinnerEnabled12

                                    -- numberOfIndicesToRemoveFromEndInteger

                                        numberOfIndicesToRemoveFromEndSpinner.value = numberOfIndicesToRemoveFromEndInteger12
                                        numberOfIndicesToRemoveFromEndSpinner.enabled = numberOfIndicesToRemoveFromEndSpinnerEnabled12

                                -- Layering

                                    -- layerToMoveObjectsToString

                                        layerToMoveObjectsIntoEditText.text = layerToMoveObjectsToString12
                            )

                            if currentVolumeDropDownListSelectionInteger == 13 then(

                                -- Naming

                                    -- useOriginalVolumeNameAsSuffixBoolean

                                        useOriginalVolumeNameAsSuffixCheckBox.checked = useOriginalVolumeNameAsSuffixBoolean13
                                        useOriginalVolumeNameAsSuffixCheckBox.enabled = useOriginalVolumeNameAsSuffixcheckBoxEnabled13

                                        useOriginalVolumeNameAsSuffixCheckBox.checked = useOriginalVolumeNameAsSuffixBoolean13
                                        useOriginalVolumeNameAsSuffixCheckBox.enabled = useOriginalVolumeNameAsSuffixcheckBoxEnabled13

                                    -- volumeNameSuffixString

                                        volumeNameSuffixEditText.text = volumeNameSuffixString13
                                        volumeNameSuffixEditText.enabled = volumeNameSuffixEditTextEnabled13

                                    -- fileNameExtraTextString

                                        fileNameExtraTextEditText.text = fileNameExtraTextString13
                                        fileNameExtraTextEditText.enabled = fileNameExtraTextEditTextEnabled13

                                    -- keywordFilterString

                                        keywordFilterEditText.text = keywordFilterString13
                                        keywordFilterEditText.enabled = keywordFilterEditTextEnabled13

                                -- Convert scene to Vray

                                    convertSceneToVrayOrCoronaCheckBox.checked = convertSceneToVrayOrCoronaBoolean13
                                    convertSceneToVrayOrCoronaCheckBox.enabled = convertSceneToVrayOrCoronacheckBoxEnabled13

                                -- Object handling

                                    -- saveEachObjectSeparatelyBoolean

                                        saveEachObjectSeparatelyCheckBox.checked = saveEachObjectSeparatelyBoolean13
                                        saveEachObjectSeparatelyCheckBox.enabled = saveEachObjectSeparatelycheckBoxEnabled13

                                    -- attachObjectsBoolean

                                        attachObjectsCheckBox.checked = attachObjectsBoolean13
                                        attachObjectsCheckBox.enabled = attachObjectscheckBoxEnabled13

                                    -- proxyObjectsBoolean

                                        proxyObjectsCheckBox.checked = proxyObjectsBoolean13
                                        proxyObjectsCheckBox.enabled = proxyObjectscheckBoxEnabled13

                                    -- facesNumberInteger

                                        facesNumberSpinner.value = facesNumberInteger13
                                        facesNumberSpinner.enabled = facesNumberSpinnerEnabled13

                                    -- coronaBoolean

                                        coronaCheckbox.checked = coronaBoolean13
                                        coronaCheckbox.enabled = coronaCheckboxEnabled13

                                -- Output Filters

                                    -- includeCamerasBoolean

                                        includeCamerasCheckBox.checked = includeCamerasBoolean13
                                        includeCamerasCheckBox.enabled = includeCamerascheckBoxEnabled13

                                    -- includeLightsBoolean

                                        includeLightsCheckBox.checked = includeLightsBoolean13
                                        includeLightsCheckBox.enabled = includeLightscheckBoxEnabled13

                                -- File naming

                                    -- replaceAllTextBoolean

                                        replaceAllTextCheckBox.checked = replaceAllTextBoolean13
                                        replaceAllTextCheckBox.enabled = replaceAllTextcheckBoxEnabled13

                                    -- retainSpecifiedTextFromFileNameBoolean

                                        retainSpecifiedTextFromFileNameCheckBox.checked = retainSpecifiedTextFromFileNameBoolean13
                                        retainSpecifiedTextFromFileNameCheckBox.enabled = retainSpecifiedTextFromFileNamecheckBoxEnabled13

                                    -- retainSpecifiedTextFromObjectNameBoolean

                                        retainSpecifiedTextFromFileNameCheckBox.checked = retainSpecifiedTextFromFileNameBoolean13
                                        retainSpecifiedTextFromFileNameCheckBox.enabled = retainSpecifiedTextFromFileNamecheckBoxEnabled13

                                    -- retainAllTextFromFileNameBoolean

                                        retainAllTextFromFileNameCheckBox.checked = retainAllTextFromFileNameBoolean13
                                        retainAllTextFromFileNameCheckBox.enabled = retainAllTextFromFileNamecheckBoxEnabled13

                                -- File naming continued

                                    -- phraseToSplitWithString

                                        phraseToSplitWithEditText.text = phraseToSplitWithString13
                                        phraseToSplitWithEditText.enabled = phraseToSplitWithEditTextEnabled13

                                    -- numberOfIndicesToRemoveFromStartInteger

                                        numberOfIndicesToRemoveFromStartSpinner.value = numberOfIndicesToRemoveFromStartInteger13
                                        numberOfIndicesToRemoveFromStartSpinner.enabled = numberOfIndicesToRemoveFromStartSpinnerEnabled13

                                    -- numberOfIndicesToRemoveFromEndInteger

                                        numberOfIndicesToRemoveFromEndSpinner.value = numberOfIndicesToRemoveFromEndInteger13
                                        numberOfIndicesToRemoveFromEndSpinner.enabled = numberOfIndicesToRemoveFromEndSpinnerEnabled13

                                -- Layering

                                    -- layerToMoveObjectsToString

                                        layerToMoveObjectsIntoEditText.text = layerToMoveObjectsToString13
                            )

                            if currentVolumeDropDownListSelectionInteger == 14 then(

                                -- Naming

                                    -- useOriginalVolumeNameAsSuffixBoolean

                                        useOriginalVolumeNameAsSuffixCheckBox.checked = useOriginalVolumeNameAsSuffixBoolean14
                                        useOriginalVolumeNameAsSuffixCheckBox.enabled = useOriginalVolumeNameAsSuffixcheckBoxEnabled14

                                        useOriginalVolumeNameAsSuffixCheckBox.checked = useOriginalVolumeNameAsSuffixBoolean14
                                        useOriginalVolumeNameAsSuffixCheckBox.enabled = useOriginalVolumeNameAsSuffixcheckBoxEnabled14

                                    -- volumeNameSuffixString

                                        volumeNameSuffixEditText.text = volumeNameSuffixString14
                                        volumeNameSuffixEditText.enabled = volumeNameSuffixEditTextEnabled14

                                    -- fileNameExtraTextString

                                        fileNameExtraTextEditText.text = fileNameExtraTextString14
                                        fileNameExtraTextEditText.enabled = fileNameExtraTextEditTextEnabled14

                                    -- keywordFilterString

                                        keywordFilterEditText.text = keywordFilterString14
                                        keywordFilterEditText.enabled = keywordFilterEditTextEnabled14

                                -- Convert scene to Vray

                                    convertSceneToVrayOrCoronaCheckBox.checked = convertSceneToVrayOrCoronaBoolean14
                                    convertSceneToVrayOrCoronaCheckBox.enabled = convertSceneToVrayOrCoronacheckBoxEnabled14

                                -- Object handling

                                    -- saveEachObjectSeparatelyBoolean

                                        saveEachObjectSeparatelyCheckBox.checked = saveEachObjectSeparatelyBoolean14
                                        saveEachObjectSeparatelyCheckBox.enabled = saveEachObjectSeparatelycheckBoxEnabled14

                                    -- attachObjectsBoolean

                                        attachObjectsCheckBox.checked = attachObjectsBoolean14
                                        attachObjectsCheckBox.enabled = attachObjectscheckBoxEnabled14

                                    -- proxyObjectsBoolean

                                        proxyObjectsCheckBox.checked = proxyObjectsBoolean14
                                        proxyObjectsCheckBox.enabled = proxyObjectscheckBoxEnabled14

                                    -- facesNumberInteger

                                        facesNumberSpinner.value = facesNumberInteger14
                                        facesNumberSpinner.enabled = facesNumberSpinnerEnabled14

                                    -- coronaBoolean

                                        coronaCheckbox.checked = coronaBoolean14
                                        coronaCheckbox.enabled = coronaCheckboxEnabled14

                                -- Output Filters

                                    -- includeCamerasBoolean

                                        includeCamerasCheckBox.checked = includeCamerasBoolean14
                                        includeCamerasCheckBox.enabled = includeCamerascheckBoxEnabled14

                                    -- includeLightsBoolean

                                        includeLightsCheckBox.checked = includeLightsBoolean14
                                        includeLightsCheckBox.enabled = includeLightscheckBoxEnabled14

                                -- File naming

                                    -- replaceAllTextBoolean

                                        replaceAllTextCheckBox.checked = replaceAllTextBoolean14
                                        replaceAllTextCheckBox.enabled = replaceAllTextcheckBoxEnabled14

                                    -- retainSpecifiedTextFromFileNameBoolean

                                        retainSpecifiedTextFromFileNameCheckBox.checked = retainSpecifiedTextFromFileNameBoolean14
                                        retainSpecifiedTextFromFileNameCheckBox.enabled = retainSpecifiedTextFromFileNamecheckBoxEnabled14

                                    -- retainSpecifiedTextFromObjectNameBoolean

                                        retainSpecifiedTextFromFileNameCheckBox.checked = retainSpecifiedTextFromFileNameBoolean14
                                        retainSpecifiedTextFromFileNameCheckBox.enabled = retainSpecifiedTextFromFileNamecheckBoxEnabled14

                                    -- retainAllTextFromFileNameBoolean

                                        retainAllTextFromFileNameCheckBox.checked = retainAllTextFromFileNameBoolean14
                                        retainAllTextFromFileNameCheckBox.enabled = retainAllTextFromFileNamecheckBoxEnabled14

                                -- File naming continued

                                    -- phraseToSplitWithString

                                        phraseToSplitWithEditText.text = phraseToSplitWithString14
                                        phraseToSplitWithEditText.enabled = phraseToSplitWithEditTextEnabled14

                                    -- numberOfIndicesToRemoveFromStartInteger

                                        numberOfIndicesToRemoveFromStartSpinner.value = numberOfIndicesToRemoveFromStartInteger14
                                        numberOfIndicesToRemoveFromStartSpinner.enabled = numberOfIndicesToRemoveFromStartSpinnerEnabled14

                                    -- numberOfIndicesToRemoveFromEndInteger

                                        numberOfIndicesToRemoveFromEndSpinner.value = numberOfIndicesToRemoveFromEndInteger14
                                        numberOfIndicesToRemoveFromEndSpinner.enabled = numberOfIndicesToRemoveFromEndSpinnerEnabled14

                                -- Layering

                                    -- layerToMoveObjectsToString

                                        layerToMoveObjectsIntoEditText.text = layerToMoveObjectsToString14
                            )

                            if currentVolumeDropDownListSelectionInteger == 15 then(

                                -- Naming

                                    -- useOriginalVolumeNameAsSuffixBoolean

                                        useOriginalVolumeNameAsSuffixCheckBox.checked = useOriginalVolumeNameAsSuffixBoolean15
                                        useOriginalVolumeNameAsSuffixCheckBox.enabled = useOriginalVolumeNameAsSuffixcheckBoxEnabled15

                                        useOriginalVolumeNameAsSuffixCheckBox.checked = useOriginalVolumeNameAsSuffixBoolean15
                                        useOriginalVolumeNameAsSuffixCheckBox.enabled = useOriginalVolumeNameAsSuffixcheckBoxEnabled15

                                    -- volumeNameSuffixString

                                        volumeNameSuffixEditText.text = volumeNameSuffixString15
                                        volumeNameSuffixEditText.enabled = volumeNameSuffixEditTextEnabled15

                                    -- fileNameExtraTextString

                                        fileNameExtraTextEditText.text = fileNameExtraTextString15
                                        fileNameExtraTextEditText.enabled = fileNameExtraTextEditTextEnabled15

                                    -- keywordFilterString

                                        keywordFilterEditText.text = keywordFilterString15
                                        keywordFilterEditText.enabled = keywordFilterEditTextEnabled15

                                -- Convert scene to Vray

                                    convertSceneToVrayOrCoronaCheckBox.checked = convertSceneToVrayOrCoronaBoolean15
                                    convertSceneToVrayOrCoronaCheckBox.enabled = convertSceneToVrayOrCoronacheckBoxEnabled15

                                -- Object handling

                                    -- saveEachObjectSeparatelyBoolean

                                        saveEachObjectSeparatelyCheckBox.checked = saveEachObjectSeparatelyBoolean15
                                        saveEachObjectSeparatelyCheckBox.enabled = saveEachObjectSeparatelycheckBoxEnabled15

                                    -- attachObjectsBoolean

                                        attachObjectsCheckBox.checked = attachObjectsBoolean15
                                        attachObjectsCheckBox.enabled = attachObjectscheckBoxEnabled15

                                    -- proxyObjectsBoolean

                                        proxyObjectsCheckBox.checked = proxyObjectsBoolean15
                                        proxyObjectsCheckBox.enabled = proxyObjectscheckBoxEnabled15

                                    -- facesNumberInteger

                                        facesNumberSpinner.value = facesNumberInteger15
                                        facesNumberSpinner.enabled = facesNumberSpinnerEnabled15

                                    -- coronaBoolean

                                        coronaCheckbox.checked = coronaBoolean15
                                        coronaCheckbox.enabled = coronaCheckboxEnabled15

                                -- Output Filters

                                    -- includeCamerasBoolean

                                        includeCamerasCheckBox.checked = includeCamerasBoolean15
                                        includeCamerasCheckBox.enabled = includeCamerascheckBoxEnabled15

                                    -- includeLightsBoolean

                                        includeLightsCheckBox.checked = includeLightsBoolean15
                                        includeLightsCheckBox.enabled = includeLightscheckBoxEnabled15

                                -- File naming

                                    -- replaceAllTextBoolean

                                        replaceAllTextCheckBox.checked = replaceAllTextBoolean15
                                        replaceAllTextCheckBox.enabled = replaceAllTextcheckBoxEnabled15

                                    -- retainSpecifiedTextFromFileNameBoolean

                                        retainSpecifiedTextFromFileNameCheckBox.checked = retainSpecifiedTextFromFileNameBoolean15
                                        retainSpecifiedTextFromFileNameCheckBox.enabled = retainSpecifiedTextFromFileNamecheckBoxEnabled15

                                    -- retainSpecifiedTextFromObjectNameBoolean

                                        retainSpecifiedTextFromFileNameCheckBox.checked = retainSpecifiedTextFromFileNameBoolean15
                                        retainSpecifiedTextFromFileNameCheckBox.enabled = retainSpecifiedTextFromFileNamecheckBoxEnabled15

                                    -- retainAllTextFromFileNameBoolean

                                        retainAllTextFromFileNameCheckBox.checked = retainAllTextFromFileNameBoolean15
                                        retainAllTextFromFileNameCheckBox.enabled = retainAllTextFromFileNamecheckBoxEnabled15

                                -- File naming continued

                                    -- phraseToSplitWithString

                                        phraseToSplitWithEditText.text = phraseToSplitWithString15
                                        phraseToSplitWithEditText.enabled = phraseToSplitWithEditTextEnabled15

                                    -- numberOfIndicesToRemoveFromStartInteger

                                        numberOfIndicesToRemoveFromStartSpinner.value = numberOfIndicesToRemoveFromStartInteger15
                                        numberOfIndicesToRemoveFromStartSpinner.enabled = numberOfIndicesToRemoveFromStartSpinnerEnabled15

                                    -- numberOfIndicesToRemoveFromEndInteger

                                        numberOfIndicesToRemoveFromEndSpinner.value = numberOfIndicesToRemoveFromEndInteger15
                                        numberOfIndicesToRemoveFromEndSpinner.enabled = numberOfIndicesToRemoveFromEndSpinnerEnabled15

                                -- Layering

                                    -- layerToMoveObjectsToString

                                        layerToMoveObjectsIntoEditText.text = layerToMoveObjectsToString15
                            )

                            if currentVolumeDropDownListSelectionInteger == 16 then(

                                -- Naming

                                    -- useOriginalVolumeNameAsSuffixBoolean

                                        useOriginalVolumeNameAsSuffixCheckBox.checked = useOriginalVolumeNameAsSuffixBoolean16
                                        useOriginalVolumeNameAsSuffixCheckBox.enabled = useOriginalVolumeNameAsSuffixcheckBoxEnabled16

                                        useOriginalVolumeNameAsSuffixCheckBox.checked = useOriginalVolumeNameAsSuffixBoolean16
                                        useOriginalVolumeNameAsSuffixCheckBox.enabled = useOriginalVolumeNameAsSuffixcheckBoxEnabled16

                                    -- volumeNameSuffixString

                                        volumeNameSuffixEditText.text = volumeNameSuffixString16
                                        volumeNameSuffixEditText.enabled = volumeNameSuffixEditTextEnabled16

                                    -- fileNameExtraTextString

                                        fileNameExtraTextEditText.text = fileNameExtraTextString16
                                        fileNameExtraTextEditText.enabled = fileNameExtraTextEditTextEnabled16

                                    -- keywordFilterString

                                        keywordFilterEditText.text = keywordFilterString16
                                        keywordFilterEditText.enabled = keywordFilterEditTextEnabled16

                                -- Convert scene to Vray

                                    convertSceneToVrayOrCoronaCheckBox.checked = convertSceneToVrayOrCoronaBoolean16
                                    convertSceneToVrayOrCoronaCheckBox.enabled = convertSceneToVrayOrCoronacheckBoxEnabled16

                                -- Object handling

                                    -- saveEachObjectSeparatelyBoolean

                                        saveEachObjectSeparatelyCheckBox.checked = saveEachObjectSeparatelyBoolean16
                                        saveEachObjectSeparatelyCheckBox.enabled = saveEachObjectSeparatelycheckBoxEnabled16

                                    -- attachObjectsBoolean

                                        attachObjectsCheckBox.checked = attachObjectsBoolean16
                                        attachObjectsCheckBox.enabled = attachObjectscheckBoxEnabled16

                                    -- proxyObjectsBoolean

                                        proxyObjectsCheckBox.checked = proxyObjectsBoolean16
                                        proxyObjectsCheckBox.enabled = proxyObjectscheckBoxEnabled16

                                    -- facesNumberInteger

                                        facesNumberSpinner.value = facesNumberInteger16
                                        facesNumberSpinner.enabled = facesNumberSpinnerEnabled16

                                    -- coronaBoolean

                                        coronaCheckbox.checked = coronaBoolean16
                                        coronaCheckbox.enabled = coronaCheckboxEnabled16

                                -- Output Filters

                                    -- includeCamerasBoolean

                                        includeCamerasCheckBox.checked = includeCamerasBoolean16
                                        includeCamerasCheckBox.enabled = includeCamerascheckBoxEnabled16

                                    -- includeLightsBoolean

                                        includeLightsCheckBox.checked = includeLightsBoolean16
                                        includeLightsCheckBox.enabled = includeLightscheckBoxEnabled16

                                -- File naming

                                    -- replaceAllTextBoolean

                                        replaceAllTextCheckBox.checked = replaceAllTextBoolean16
                                        replaceAllTextCheckBox.enabled = replaceAllTextcheckBoxEnabled16

                                    -- retainSpecifiedTextFromFileNameBoolean

                                        retainSpecifiedTextFromFileNameCheckBox.checked = retainSpecifiedTextFromFileNameBoolean16
                                        retainSpecifiedTextFromFileNameCheckBox.enabled = retainSpecifiedTextFromFileNamecheckBoxEnabled16

                                    -- retainSpecifiedTextFromObjectNameBoolean

                                        retainSpecifiedTextFromFileNameCheckBox.checked = retainSpecifiedTextFromFileNameBoolean16
                                        retainSpecifiedTextFromFileNameCheckBox.enabled = retainSpecifiedTextFromFileNamecheckBoxEnabled16

                                    -- retainAllTextFromFileNameBoolean

                                        retainAllTextFromFileNameCheckBox.checked = retainAllTextFromFileNameBoolean16
                                        retainAllTextFromFileNameCheckBox.enabled = retainAllTextFromFileNamecheckBoxEnabled16

                                -- File naming continued

                                    -- phraseToSplitWithString

                                        phraseToSplitWithEditText.text = phraseToSplitWithString16
                                        phraseToSplitWithEditText.enabled = phraseToSplitWithEditTextEnabled16

                                    -- numberOfIndicesToRemoveFromStartInteger

                                        numberOfIndicesToRemoveFromStartSpinner.value = numberOfIndicesToRemoveFromStartInteger16
                                        numberOfIndicesToRemoveFromStartSpinner.enabled = numberOfIndicesToRemoveFromStartSpinnerEnabled16

                                    -- numberOfIndicesToRemoveFromEndInteger

                                        numberOfIndicesToRemoveFromEndSpinner.value = numberOfIndicesToRemoveFromEndInteger16
                                        numberOfIndicesToRemoveFromEndSpinner.enabled = numberOfIndicesToRemoveFromEndSpinnerEnabled16

                                -- Layering

                                    -- layerToMoveObjectsToString

                                        layerToMoveObjectsIntoEditText.text = layerToMoveObjectsToString16
                            )

                            if currentVolumeDropDownListSelectionInteger == 17 then(
                                -- Naming

                                    -- useOriginalVolumeNameAsSuffixBoolean

                                        useOriginalVolumeNameAsSuffixCheckBox.checked = useOriginalVolumeNameAsSuffixBoolean17
                                        useOriginalVolumeNameAsSuffixCheckBox.enabled = useOriginalVolumeNameAsSuffixcheckBoxEnabled17

                                        useOriginalVolumeNameAsSuffixCheckBox.checked = useOriginalVolumeNameAsSuffixBoolean17
                                        useOriginalVolumeNameAsSuffixCheckBox.enabled = useOriginalVolumeNameAsSuffixcheckBoxEnabled17

                                    -- volumeNameSuffixString

                                        volumeNameSuffixEditText.text = volumeNameSuffixString17
                                        volumeNameSuffixEditText.enabled = volumeNameSuffixEditTextEnabled17

                                    -- fileNameExtraTextString

                                        fileNameExtraTextEditText.text = fileNameExtraTextString17
                                        fileNameExtraTextEditText.enabled = fileNameExtraTextEditTextEnabled17

                                    -- keywordFilterString

                                        keywordFilterEditText.text = keywordFilterString17
                                        keywordFilterEditText.enabled = keywordFilterEditTextEnabled17

                                -- Convert scene to Vray

                                    convertSceneToVrayOrCoronaCheckBox.checked = convertSceneToVrayOrCoronaBoolean17
                                    convertSceneToVrayOrCoronaCheckBox.enabled = convertSceneToVrayOrCoronacheckBoxEnabled17

                                -- Object handling

                                    -- saveEachObjectSeparatelyBoolean

                                        saveEachObjectSeparatelyCheckBox.checked = saveEachObjectSeparatelyBoolean17
                                        saveEachObjectSeparatelyCheckBox.enabled = saveEachObjectSeparatelycheckBoxEnabled17

                                    -- attachObjectsBoolean

                                        attachObjectsCheckBox.checked = attachObjectsBoolean17
                                        attachObjectsCheckBox.enabled = attachObjectscheckBoxEnabled17

                                    -- proxyObjectsBoolean

                                        proxyObjectsCheckBox.checked = proxyObjectsBoolean17
                                        proxyObjectsCheckBox.enabled = proxyObjectscheckBoxEnabled17

                                    -- facesNumberInteger

                                        facesNumberSpinner.value = facesNumberInteger17
                                        facesNumberSpinner.enabled = facesNumberSpinnerEnabled17

                                    -- coronaBoolean

                                        coronaCheckbox.checked = coronaBoolean17
                                        coronaCheckbox.enabled = coronaCheckboxEnabled17

                                -- Output Filters

                                    -- includeCamerasBoolean

                                        includeCamerasCheckBox.checked = includeCamerasBoolean17
                                        includeCamerasCheckBox.enabled = includeCamerascheckBoxEnabled17

                                    -- includeLightsBoolean

                                        includeLightsCheckBox.checked = includeLightsBoolean17
                                        includeLightsCheckBox.enabled = includeLightscheckBoxEnabled17

                                -- File naming

                                    -- replaceAllTextBoolean

                                        replaceAllTextCheckBox.checked = replaceAllTextBoolean17
                                        replaceAllTextCheckBox.enabled = replaceAllTextcheckBoxEnabled17

                                    -- retainSpecifiedTextFromFileNameBoolean

                                        retainSpecifiedTextFromFileNameCheckBox.checked = retainSpecifiedTextFromFileNameBoolean17
                                        retainSpecifiedTextFromFileNameCheckBox.enabled = retainSpecifiedTextFromFileNamecheckBoxEnabled17

                                    -- retainSpecifiedTextFromObjectNameBoolean

                                        retainSpecifiedTextFromFileNameCheckBox.checked = retainSpecifiedTextFromFileNameBoolean17
                                        retainSpecifiedTextFromFileNameCheckBox.enabled = retainSpecifiedTextFromFileNamecheckBoxEnabled17

                                    -- retainAllTextFromFileNameBoolean

                                        retainAllTextFromFileNameCheckBox.checked = retainAllTextFromFileNameBoolean17
                                        retainAllTextFromFileNameCheckBox.enabled = retainAllTextFromFileNamecheckBoxEnabled17

                                -- File naming continued

                                    -- phraseToSplitWithString

                                        phraseToSplitWithEditText.text = phraseToSplitWithString17
                                        phraseToSplitWithEditText.enabled = phraseToSplitWithEditTextEnabled17

                                    -- numberOfIndicesToRemoveFromStartInteger

                                        numberOfIndicesToRemoveFromStartSpinner.value = numberOfIndicesToRemoveFromStartInteger17
                                        numberOfIndicesToRemoveFromStartSpinner.enabled = numberOfIndicesToRemoveFromStartSpinnerEnabled17

                                    -- numberOfIndicesToRemoveFromEndInteger

                                        numberOfIndicesToRemoveFromEndSpinner.value = numberOfIndicesToRemoveFromEndInteger17
                                        numberOfIndicesToRemoveFromEndSpinner.enabled = numberOfIndicesToRemoveFromEndSpinnerEnabled17

                                -- Layering

                                    -- layerToMoveObjectsToString

                                        layerToMoveObjectsIntoEditText.text = layerToMoveObjectsToString17
                            )

                            if currentVolumeDropDownListSelectionInteger == 18 then(
                                -- Naming

                                    -- useOriginalVolumeNameAsSuffixBoolean

                                        useOriginalVolumeNameAsSuffixCheckBox.checked = useOriginalVolumeNameAsSuffixBoolean18
                                        useOriginalVolumeNameAsSuffixCheckBox.enabled = useOriginalVolumeNameAsSuffixcheckBoxEnabled18

                                        useOriginalVolumeNameAsSuffixCheckBox.checked = useOriginalVolumeNameAsSuffixBoolean18
                                        useOriginalVolumeNameAsSuffixCheckBox.enabled = useOriginalVolumeNameAsSuffixcheckBoxEnabled18

                                    -- volumeNameSuffixString

                                        volumeNameSuffixEditText.text = volumeNameSuffixString18
                                        volumeNameSuffixEditText.enabled = volumeNameSuffixEditTextEnabled18

                                    -- fileNameExtraTextString

                                        fileNameExtraTextEditText.text = fileNameExtraTextString18
                                        fileNameExtraTextEditText.enabled = fileNameExtraTextEditTextEnabled18

                                    -- keywordFilterString

                                        keywordFilterEditText.text = keywordFilterString18
                                        keywordFilterEditText.enabled = keywordFilterEditTextEnabled18

                                -- Convert scene to Vray

                                    convertSceneToVrayOrCoronaCheckBox.checked = convertSceneToVrayOrCoronaBoolean18
                                    convertSceneToVrayOrCoronaCheckBox.enabled = convertSceneToVrayOrCoronacheckBoxEnabled18

                                -- Object handling

                                    -- saveEachObjectSeparatelyBoolean

                                        saveEachObjectSeparatelyCheckBox.checked = saveEachObjectSeparatelyBoolean18
                                        saveEachObjectSeparatelyCheckBox.enabled = saveEachObjectSeparatelycheckBoxEnabled18

                                    -- attachObjectsBoolean

                                        attachObjectsCheckBox.checked = attachObjectsBoolean18
                                        attachObjectsCheckBox.enabled = attachObjectscheckBoxEnabled18

                                    -- proxyObjectsBoolean

                                        proxyObjectsCheckBox.checked = proxyObjectsBoolean18
                                        proxyObjectsCheckBox.enabled = proxyObjectscheckBoxEnabled18

                                    -- facesNumberInteger

                                        facesNumberSpinner.value = facesNumberInteger18
                                        facesNumberSpinner.enabled = facesNumberSpinnerEnabled18

                                    -- coronaBoolean

                                        coronaCheckbox.checked = coronaBoolean18
                                        coronaCheckbox.enabled = coronaCheckboxEnabled18

                                -- Output Filters

                                    -- includeCamerasBoolean

                                        includeCamerasCheckBox.checked = includeCamerasBoolean18
                                        includeCamerasCheckBox.enabled = includeCamerascheckBoxEnabled18

                                    -- includeLightsBoolean

                                        includeLightsCheckBox.checked = includeLightsBoolean18
                                        includeLightsCheckBox.enabled = includeLightscheckBoxEnabled18

                                -- File naming

                                    -- replaceAllTextBoolean

                                        replaceAllTextCheckBox.checked = replaceAllTextBoolean18
                                        replaceAllTextCheckBox.enabled = replaceAllTextcheckBoxEnabled18

                                    -- retainSpecifiedTextFromFileNameBoolean

                                        retainSpecifiedTextFromFileNameCheckBox.checked = retainSpecifiedTextFromFileNameBoolean18
                                        retainSpecifiedTextFromFileNameCheckBox.enabled = retainSpecifiedTextFromFileNamecheckBoxEnabled18

                                    -- retainSpecifiedTextFromObjectNameBoolean

                                        retainSpecifiedTextFromFileNameCheckBox.checked = retainSpecifiedTextFromFileNameBoolean18
                                        retainSpecifiedTextFromFileNameCheckBox.enabled = retainSpecifiedTextFromFileNamecheckBoxEnabled18

                                    -- retainAllTextFromFileNameBoolean

                                        retainAllTextFromFileNameCheckBox.checked = retainAllTextFromFileNameBoolean18
                                        retainAllTextFromFileNameCheckBox.enabled = retainAllTextFromFileNamecheckBoxEnabled18

                                -- File naming continued

                                    -- phraseToSplitWithString

                                        phraseToSplitWithEditText.text = phraseToSplitWithString18
                                        phraseToSplitWithEditText.enabled = phraseToSplitWithEditTextEnabled18

                                    -- numberOfIndicesToRemoveFromStartInteger

                                        numberOfIndicesToRemoveFromStartSpinner.value = numberOfIndicesToRemoveFromStartInteger18
                                        numberOfIndicesToRemoveFromStartSpinner.enabled = numberOfIndicesToRemoveFromStartSpinnerEnabled18

                                    -- numberOfIndicesToRemoveFromEndInteger

                                        numberOfIndicesToRemoveFromEndSpinner.value = numberOfIndicesToRemoveFromEndInteger18
                                        numberOfIndicesToRemoveFromEndSpinner.enabled = numberOfIndicesToRemoveFromEndSpinnerEnabled18

                                -- Layering

                                    -- layerToMoveObjectsToString

                                        layerToMoveObjectsIntoEditText.text = layerToMoveObjectsToString19
                            )

                            if currentVolumeDropDownListSelectionInteger == 19 then(
                                -- Naming

                                    -- useOriginalVolumeNameAsSuffixBoolean

                                        useOriginalVolumeNameAsSuffixCheckBox.checked = useOriginalVolumeNameAsSuffixBoolean19
                                        useOriginalVolumeNameAsSuffixCheckBox.enabled = useOriginalVolumeNameAsSuffixcheckBoxEnabled19

                                        useOriginalVolumeNameAsSuffixCheckBox.checked = useOriginalVolumeNameAsSuffixBoolean19
                                        useOriginalVolumeNameAsSuffixCheckBox.enabled = useOriginalVolumeNameAsSuffixcheckBoxEnabled19

                                    -- volumeNameSuffixString

                                        volumeNameSuffixEditText.text = volumeNameSuffixString19
                                        volumeNameSuffixEditText.enabled = volumeNameSuffixEditTextEnabled19

                                    -- fileNameExtraTextString

                                        fileNameExtraTextEditText.text = fileNameExtraTextString19
                                        fileNameExtraTextEditText.enabled = fileNameExtraTextEditTextEnabled19

                                    -- keywordFilterString

                                        keywordFilterEditText.text = keywordFilterString19
                                        keywordFilterEditText.enabled = keywordFilterEditTextEnabled19

                                -- Convert scene to Vray

                                    convertSceneToVrayOrCoronaCheckBox.checked = convertSceneToVrayOrCoronaBoolean19
                                    convertSceneToVrayOrCoronaCheckBox.enabled = convertSceneToVrayOrCoronacheckBoxEnabled19

                                -- Object handling

                                    -- saveEachObjectSeparatelyBoolean

                                        saveEachObjectSeparatelyCheckBox.checked = saveEachObjectSeparatelyBoolean19
                                        saveEachObjectSeparatelyCheckBox.enabled = saveEachObjectSeparatelycheckBoxEnabled19

                                    -- attachObjectsBoolean

                                        attachObjectsCheckBox.checked = attachObjectsBoolean19
                                        attachObjectsCheckBox.enabled = attachObjectscheckBoxEnabled19

                                    -- proxyObjectsBoolean

                                        proxyObjectsCheckBox.checked = proxyObjectsBoolean19
                                        proxyObjectsCheckBox.enabled = proxyObjectscheckBoxEnabled19

                                    -- facesNumberInteger

                                        facesNumberSpinner.value = facesNumberInteger19
                                        facesNumberSpinner.enabled = facesNumberSpinnerEnabled19

                                    -- coronaBoolean

                                        coronaCheckbox.checked = coronaBoolean19
                                        coronaCheckbox.enabled = coronaCheckboxEnabled19

                                -- Output Filters

                                    -- includeCamerasBoolean

                                        includeCamerasCheckBox.checked = includeCamerasBoolean19
                                        includeCamerasCheckBox.enabled = includeCamerascheckBoxEnabled19

                                    -- includeLightsBoolean

                                        includeLightsCheckBox.checked = includeLightsBoolean19
                                        includeLightsCheckBox.enabled = includeLightscheckBoxEnabled19

                                -- File naming

                                    -- replaceAllTextBoolean

                                        replaceAllTextCheckBox.checked = replaceAllTextBoolean19
                                        replaceAllTextCheckBox.enabled = replaceAllTextcheckBoxEnabled19

                                    -- retainSpecifiedTextFromFileNameBoolean

                                        retainSpecifiedTextFromFileNameCheckBox.checked = retainSpecifiedTextFromFileNameBoolean19
                                        retainSpecifiedTextFromFileNameCheckBox.enabled = retainSpecifiedTextFromFileNamecheckBoxEnabled19

                                    -- retainSpecifiedTextFromObjectNameBoolean

                                        retainSpecifiedTextFromFileNameCheckBox.checked = retainSpecifiedTextFromFileNameBoolean19
                                        retainSpecifiedTextFromFileNameCheckBox.enabled = retainSpecifiedTextFromFileNamecheckBoxEnabled19

                                    -- retainAllTextFromFileNameBoolean

                                        retainAllTextFromFileNameCheckBox.checked = retainAllTextFromFileNameBoolean19
                                        retainAllTextFromFileNameCheckBox.enabled = retainAllTextFromFileNamecheckBoxEnabled19

                                -- File naming continued

                                    -- phraseToSplitWithString

                                        phraseToSplitWithEditText.text = phraseToSplitWithString19
                                        phraseToSplitWithEditText.enabled = phraseToSplitWithEditTextEnabled19

                                    -- numberOfIndicesToRemoveFromStartInteger

                                        numberOfIndicesToRemoveFromStartSpinner.value = numberOfIndicesToRemoveFromStartInteger19
                                        numberOfIndicesToRemoveFromStartSpinner.enabled = numberOfIndicesToRemoveFromStartSpinnerEnabled19

                                    -- numberOfIndicesToRemoveFromEndInteger

                                        numberOfIndicesToRemoveFromEndSpinner.value = numberOfIndicesToRemoveFromEndInteger19
                                        numberOfIndicesToRemoveFromEndSpinner.enabled = numberOfIndicesToRemoveFromEndSpinnerEnabled19

                                -- Layering

                                    -- layerToMoveObjectsToString

                                        layerToMoveObjectsIntoEditText.text = layerToMoveObjectsToString19
                            )

                            if currentVolumeDropDownListSelectionInteger == 20 then(
                                -- Naming

                                    -- useOriginalVolumeNameAsSuffixBoolean

                                        useOriginalVolumeNameAsSuffixCheckBox.checked = useOriginalVolumeNameAsSuffixBoolean20
                                        useOriginalVolumeNameAsSuffixCheckBox.enabled = useOriginalVolumeNameAsSuffixcheckBoxEnabled20

                                        useOriginalVolumeNameAsSuffixCheckBox.checked = useOriginalVolumeNameAsSuffixBoolean20
                                        useOriginalVolumeNameAsSuffixCheckBox.enabled = useOriginalVolumeNameAsSuffixcheckBoxEnabled20

                                    -- volumeNameSuffixString

                                        volumeNameSuffixEditText.text = volumeNameSuffixString20
                                        volumeNameSuffixEditText.enabled = volumeNameSuffixEditTextEnabled20

                                    -- fileNameExtraTextString

                                        fileNameExtraTextEditText.text = fileNameExtraTextString20
                                        fileNameExtraTextEditText.enabled = fileNameExtraTextEditTextEnabled20

                                    -- keywordFilterString

                                        keywordFilterEditText.text = keywordFilterString20
                                        keywordFilterEditText.enabled = keywordFilterEditTextEnabled20

                                -- Convert scene to Vray

                                    convertSceneToVrayOrCoronaCheckBox.checked = convertSceneToVrayOrCoronaBoolean20
                                    convertSceneToVrayOrCoronaCheckBox.enabled = convertSceneToVrayOrCoronacheckBoxEnabled20

                                -- Object handling

                                    -- saveEachObjectSeparatelyBoolean

                                        saveEachObjectSeparatelyCheckBox.checked = saveEachObjectSeparatelyBoolean20
                                        saveEachObjectSeparatelyCheckBox.enabled = saveEachObjectSeparatelycheckBoxEnabled20

                                    -- attachObjectsBoolean

                                        attachObjectsCheckBox.checked = attachObjectsBoolean20
                                        attachObjectsCheckBox.enabled = attachObjectscheckBoxEnabled20

                                    -- proxyObjectsBoolean

                                        proxyObjectsCheckBox.checked = proxyObjectsBoolean20
                                        proxyObjectsCheckBox.enabled = proxyObjectscheckBoxEnabled20

                                    -- facesNumberInteger

                                        facesNumberSpinner.value = facesNumberInteger20
                                        facesNumberSpinner.enabled = facesNumberSpinnerEnabled20

                                    -- coronaBoolean

                                        coronaCheckbox.checked = coronaBoolean20
                                        coronaCheckbox.enabled = coronaCheckboxEnabled20

                                -- Output Filters

                                    -- includeCamerasBoolean

                                        includeCamerasCheckBox.checked = includeCamerasBoolean20
                                        includeCamerasCheckBox.enabled = includeCamerascheckBoxEnabled20

                                    -- includeLightsBoolean

                                        includeLightsCheckBox.checked = includeLightsBoolean20
                                        includeLightsCheckBox.enabled = includeLightscheckBoxEnabled20

                                -- File naming

                                    -- replaceAllTextBoolean

                                        replaceAllTextCheckBox.checked = replaceAllTextBoolean20
                                        replaceAllTextCheckBox.enabled = replaceAllTextcheckBoxEnabled20

                                    -- retainSpecifiedTextFromFileNameBoolean

                                        retainSpecifiedTextFromFileNameCheckBox.checked = retainSpecifiedTextFromFileNameBoolean20
                                        retainSpecifiedTextFromFileNameCheckBox.enabled = retainSpecifiedTextFromFileNamecheckBoxEnabled20

                                    -- retainSpecifiedTextFromObjectNameBoolean

                                        retainSpecifiedTextFromFileNameCheckBox.checked = retainSpecifiedTextFromFileNameBoolean20
                                        retainSpecifiedTextFromFileNameCheckBox.enabled = retainSpecifiedTextFromFileNamecheckBoxEnabled20

                                    -- retainAllTextFromFileNameBoolean

                                        retainAllTextFromFileNameCheckBox.checked = retainAllTextFromFileNameBoolean20
                                        retainAllTextFromFileNameCheckBox.enabled = retainAllTextFromFileNamecheckBoxEnabled20

                                -- File naming continued

                                    -- phraseToSplitWithString

                                        phraseToSplitWithEditText.text = phraseToSplitWithString20
                                        phraseToSplitWithEditText.enabled = phraseToSplitWithEditTextEnabled20

                                    -- numberOfIndicesToRemoveFromStartInteger

                                        numberOfIndicesToRemoveFromStartSpinner.value = numberOfIndicesToRemoveFromStartInteger20
                                        numberOfIndicesToRemoveFromStartSpinner.enabled = numberOfIndicesToRemoveFromStartSpinnerEnabled20

                                    -- numberOfIndicesToRemoveFromEndInteger

                                        numberOfIndicesToRemoveFromEndSpinner.value = numberOfIndicesToRemoveFromEndInteger20
                                        numberOfIndicesToRemoveFromEndSpinner.enabled = numberOfIndicesToRemoveFromEndSpinnerEnabled20

                                -- Layering

                                    -- layerToMoveObjectsToString

                                        layerToMoveObjectsIntoEditText.text = layerToMoveObjectsToString20
                            )
                    )

                -- Naming

                    -- Suffix

                        on useOriginalVolumeNameAsSuffixCheckBox changed state do(
                            if state then(
                                -- Change variable

                                    if currentVolumeDropDownListSelectionInteger == 1 then(
                                        useOriginalVolumeNameAsSuffixBoolean1 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 2 then(
                                        useOriginalVolumeNameAsSuffixBoolean2 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 3 then(
                                        useOriginalVolumeNameAsSuffixBoolean3 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 4 then(
                                        useOriginalVolumeNameAsSuffixBoolean4 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 5 then(
                                        useOriginalVolumeNameAsSuffixBoolean5 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 6 then(
                                        useOriginalVolumeNameAsSuffixBoolean6 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 7 then(
                                        useOriginalVolumeNameAsSuffixBoolean7 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 8 then(
                                        useOriginalVolumeNameAsSuffixBoolean8 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 9 then(
                                        useOriginalVolumeNameAsSuffixBoolean9 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 10 then(
                                        useOriginalVolumeNameAsSuffixBoolean10 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 11 then(
                                        useOriginalVolumeNameAsSuffixBoolean11 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 12 then(
                                        useOriginalVolumeNameAsSuffixBoolean12 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 13 then(
                                        useOriginalVolumeNameAsSuffixBoolean13 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 14 then(
                                        useOriginalVolumeNameAsSuffixBoolean14 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 15 then(
                                        useOriginalVolumeNameAsSuffixBoolean15 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 16 then(
                                        useOriginalVolumeNameAsSuffixBoolean16 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 17 then(
                                        useOriginalVolumeNameAsSuffixBoolean17 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 18 then(
                                        useOriginalVolumeNameAsSuffixBoolean18 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 19 then(
                                        useOriginalVolumeNameAsSuffixBoolean19 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 20 then(
                                        useOriginalVolumeNameAsSuffixBoolean20 = true
                                    )

                                -- Change variable

                                    if currentVolumeDropDownListSelectionInteger == 1 then(
                                        volumeNameSuffixEditTextEnabled1 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 2 then(
                                        volumeNameSuffixEditTextEnabled2 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 3 then(
                                        volumeNameSuffixEditTextEnabled3 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 4 then(
                                        volumeNameSuffixEditTextEnabled4 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 5 then(
                                        volumeNameSuffixEditTextEnabled5 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 6 then(
                                        volumeNameSuffixEditTextEnabled6 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 7 then(
                                        volumeNameSuffixEditTextEnabled7 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 8 then(
                                        volumeNameSuffixEditTextEnabled8 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 9 then(
                                        volumeNameSuffixEditTextEnabled9 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 10 then(
                                        volumeNameSuffixEditTextEnabled10 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 11 then(
                                        volumeNameSuffixEditTextEnabled11 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 12 then(
                                        volumeNameSuffixEditTextEnabled12 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 13 then(
                                        volumeNameSuffixEditTextEnabled13 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 14 then(
                                        volumeNameSuffixEditTextEnabled14 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 15 then(
                                        volumeNameSuffixEditTextEnabled15 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 16 then(
                                        volumeNameSuffixEditTextEnabled16 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 17 then(
                                        volumeNameSuffixEditTextEnabled17 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 18 then(
                                        volumeNameSuffixEditTextEnabled18 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 19 then(
                                        volumeNameSuffixEditTextEnabled19 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 20 then(
                                        volumeNameSuffixEditTextEnabled20 = false
                                    )

                                -- Other components

                                    volumeNameSuffixEditText.enabled = false
                            )else(
                                -- Change variable

                                    if currentVolumeDropDownListSelectionInteger == 1 then(
                                        useOriginalVolumeNameAsSuffixBoolean1 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 2 then(
                                        useOriginalVolumeNameAsSuffixBoolean2 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 3 then(
                                        useOriginalVolumeNameAsSuffixBoolean3 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 4 then(
                                        useOriginalVolumeNameAsSuffixBoolean4 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 5 then(
                                        useOriginalVolumeNameAsSuffixBoolean5 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 6 then(
                                        useOriginalVolumeNameAsSuffixBoolean6 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 7 then(
                                        useOriginalVolumeNameAsSuffixBoolean7 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 8 then(
                                        useOriginalVolumeNameAsSuffixBoolean8 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 9 then(
                                        useOriginalVolumeNameAsSuffixBoolean9 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 10 then(
                                        useOriginalVolumeNameAsSuffixBoolean10 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 11 then(
                                        useOriginalVolumeNameAsSuffixBoolean11 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 12 then(
                                        useOriginalVolumeNameAsSuffixBoolean12 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 13 then(
                                        useOriginalVolumeNameAsSuffixBoolean13 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 14 then(
                                        useOriginalVolumeNameAsSuffixBoolean14 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 15 then(
                                        useOriginalVolumeNameAsSuffixBoolean15 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 16 then(
                                        useOriginalVolumeNameAsSuffixBoolean16 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 17 then(
                                        useOriginalVolumeNameAsSuffixBoolean17 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 18 then(
                                        useOriginalVolumeNameAsSuffixBoolean18 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 19 then(
                                        useOriginalVolumeNameAsSuffixBoolean19 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 20 then(
                                        useOriginalVolumeNameAsSuffixBoolean20 = false
                                    )

                                -- Change variable

                                    if currentVolumeDropDownListSelectionInteger == 1 then(
                                        volumeNameSuffixEditTextEnabled1 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 2 then(
                                        volumeNameSuffixEditTextEnabled2 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 3 then(
                                        volumeNameSuffixEditTextEnabled3 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 4 then(
                                        volumeNameSuffixEditTextEnabled4 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 5 then(
                                        volumeNameSuffixEditTextEnabled5 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 6 then(
                                        volumeNameSuffixEditTextEnabled6 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 7 then(
                                        volumeNameSuffixEditTextEnabled7 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 8 then(
                                        volumeNameSuffixEditTextEnabled8 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 9 then(
                                        volumeNameSuffixEditTextEnabled9 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 10 then(
                                        volumeNameSuffixEditTextEnabled10 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 11 then(
                                        volumeNameSuffixEditTextEnabled11 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 12 then(
                                        volumeNameSuffixEditTextEnabled12 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 13 then(
                                        volumeNameSuffixEditTextEnabled13 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 14 then(
                                        volumeNameSuffixEditTextEnabled14 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 15 then(
                                        volumeNameSuffixEditTextEnabled15 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 16 then(
                                        volumeNameSuffixEditTextEnabled16 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 17 then(
                                        volumeNameSuffixEditTextEnabled17 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 18 then(
                                        volumeNameSuffixEditTextEnabled18 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 19 then(
                                        volumeNameSuffixEditTextEnabled19 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 20 then(
                                        volumeNameSuffixEditTextEnabled20 = true
                                    )

                                -- Other components

                                    volumeNameSuffixEditText.enabled = true
                            )
                        )

                        on volumeNameSuffixEditText entered txt do(
                            -- Change variable

                                if currentVolumeDropDownListSelectionInteger == 1 then(
                                    volumeNameSuffixString1 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 2 then(
                                    volumeNameSuffixString2 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 3 then(
                                    volumeNameSuffixString3 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 4 then(
                                    volumeNameSuffixString4 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 5 then(
                                    volumeNameSuffixString5 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 6 then(
                                    volumeNameSuffixString6 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 7 then(
                                    volumeNameSuffixString7 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 8 then(
                                    volumeNameSuffixString8 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 9 then(
                                    volumeNameSuffixString9 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 10 then(
                                    volumeNameSuffixString10 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 11 then(
                                    volumeNameSuffixString11 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 12 then(
                                    volumeNameSuffixString12 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 13 then(
                                    volumeNameSuffixString13 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 14 then(
                                    volumeNameSuffixString14 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 15 then(
                                    volumeNameSuffixString15 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 16 then(
                                    volumeNameSuffixString16 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 17 then(
                                    volumeNameSuffixString17 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 18 then(
                                    volumeNameSuffixString18 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 19 then(
                                    volumeNameSuffixString19 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 20 then(
                                    volumeNameSuffixString20 = txt
                                )
                        )

                        on fileNameExtraTextEditText entered txt do(
                            -- Change variable

                                if currentVolumeDropDownListSelectionInteger == 1 then(
                                    fileNameExtraTextString1 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 2 then(
                                    fileNameExtraTextString2 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 3 then(
                                    fileNameExtraTextString3 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 4 then(
                                    fileNameExtraTextString4 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 5 then(
                                    fileNameExtraTextString5 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 6 then(
                                    fileNameExtraTextString6 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 7 then(
                                    fileNameExtraTextString7 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 8 then(
                                    fileNameExtraTextString8 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 9 then(
                                    fileNameExtraTextString9 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 10 then(
                                    fileNameExtraTextString10 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 11 then(
                                    fileNameExtraTextString11 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 12 then(
                                    fileNameExtraTextString12 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 13 then(
                                    fileNameExtraTextString13 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 14 then(
                                    fileNameExtraTextString14 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 15 then(
                                    fileNameExtraTextString15 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 16 then(
                                    fileNameExtraTextString16 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 17 then(
                                    fileNameExtraTextString17 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 18 then(
                                    fileNameExtraTextString18 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 19 then(
                                    fileNameExtraTextString19 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 20 then(
                                    fileNameExtraTextString20 = txt
                                )
                        )

                    -- Keyword filter

                        on keywordFilterEditText entered txt do(
                            if txt != "" and txt != undefined then(
                                -- Change variable

                                    if currentVolumeDropDownListSelectionInteger == 1 then(
                                        keywordFilterString1 = "*" + txt + "*"
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 2 then(
                                        keywordFilterString2 = "*" + txt + "*"
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 3 then(
                                        keywordFilterString3 = "*" + txt + "*"
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 4 then(
                                        keywordFilterString4 = "*" + txt + "*"
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 5 then(
                                        keywordFilterString5 = "*" + txt + "*"
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 6 then(
                                        keywordFilterString6 = "*" + txt + "*"
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 7 then(
                                        keywordFilterString7 = "*" + txt + "*"
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 8 then(
                                        keywordFilterString8 = "*" + txt + "*"
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 9 then(
                                        keywordFilterString9 = "*" + txt + "*"
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 10 then(
                                        keywordFilterString10 = "*" + txt + "*"
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 11 then(
                                        keywordFilterString11 = "*" + txt + "*"
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 12 then(
                                        keywordFilterString12 = "*" + txt + "*"
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 13 then(
                                        keywordFilterString13 = "*" + txt + "*"
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 14 then(
                                        keywordFilterString14 = "*" + txt + "*"
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 15 then(
                                        keywordFilterString15 = "*" + txt + "*"
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 16 then(
                                        keywordFilterString16 = "*" + txt + "*"
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 17 then(
                                        keywordFilterString17 = "*" + txt + "*"
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 18 then(
                                        keywordFilterString18 = "*" + txt + "*"
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 19 then(
                                        keywordFilterString19 = "*" + txt + "*"
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 20 then(
                                        keywordFilterString20 = "*" + txt + "*"
                                    )
                            )else(
                                -- Change variable

                                    if currentVolumeDropDownListSelectionInteger == 1 then(
                                        keywordFilterString1 = ""
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 2 then(
                                        keywordFilterString2 = ""
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 3 then(
                                        keywordFilterString3 = ""
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 4 then(
                                        keywordFilterString4 = ""
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 5 then(
                                        keywordFilterString5 = ""
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 6 then(
                                        keywordFilterString6 = ""
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 7 then(
                                        keywordFilterString7 = ""
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 8 then(
                                        keywordFilterString8 = ""
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 9 then(
                                        keywordFilterString9 = ""
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 10 then(
                                        keywordFilterString10 = ""
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 11 then(
                                        keywordFilterString11 = ""
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 12 then(
                                        keywordFilterString12 = ""
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 13 then(
                                        keywordFilterString13 = ""
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 14 then(
                                        keywordFilterString14 = ""
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 15 then(
                                        keywordFilterString15 = ""
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 16 then(
                                        keywordFilterString16 = ""
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 17 then(
                                        keywordFilterString17 = ""
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 18 then(
                                        keywordFilterString18 = ""
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 19 then(
                                        keywordFilterString19 = ""
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 20 then(
                                        keywordFilterString20 = ""
                                    )
                            )
                        )

                -- Convert scene to Vray

                    on convertSceneToVrayOrCoronaCheckbox changed state do(
                        if state == true then(
                            -- Change variable

                                if currentVolumeDropDownListSelectionInteger == 1 then(
                                    convertSceneToVrayOrCoronaBoolean1 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 2 then(
                                    convertSceneToVrayOrCoronaBoolean2 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 3 then(
                                    convertSceneToVrayOrCoronaBoolean3 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 4 then(
                                    convertSceneToVrayOrCoronaBoolean4 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 5 then(
                                    convertSceneToVrayOrCoronaBoolean5 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 6 then(
                                    convertSceneToVrayOrCoronaBoolean6 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 7 then(
                                    convertSceneToVrayOrCoronaBoolean7 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 8 then(
                                    convertSceneToVrayOrCoronaBoolean8 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 9 then(
                                    convertSceneToVrayOrCoronaBoolean9 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 10 then(
                                    convertSceneToVrayOrCoronaBoolean10 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 11 then(
                                    convertSceneToVrayOrCoronaBoolean11 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 12 then(
                                    convertSceneToVrayOrCoronaBoolean12 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 13 then(
                                    convertSceneToVrayOrCoronaBoolean13 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 14 then(
                                    convertSceneToVrayOrCoronaBoolean14 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 15 then(
                                    convertSceneToVrayOrCoronaBoolean15 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 16 then(
                                    convertSceneToVrayOrCoronaBoolean16 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 17 then(
                                    convertSceneToVrayOrCoronaBoolean17 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 18 then(
                                    convertSceneToVrayOrCoronaBoolean18 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 19 then(
                                    convertSceneToVrayOrCoronaBoolean19 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 20 then(
                                    convertSceneToVrayOrCoronaBoolean20 = true
                                )
                        )else(
                            -- Change variable

                                if currentVolumeDropDownListSelectionInteger == 1 then(
                                    convertSceneToVrayOrCoronaBoolean1 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 2 then(
                                    convertSceneToVrayOrCoronaBoolean2 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 3 then(
                                    convertSceneToVrayOrCoronaBoolean3 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 4 then(
                                    convertSceneToVrayOrCoronaBoolean4 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 5 then(
                                    convertSceneToVrayOrCoronaBoolean5 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 6 then(
                                    convertSceneToVrayOrCoronaBoolean6 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 7 then(
                                    convertSceneToVrayOrCoronaBoolean7 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 8 then(
                                    convertSceneToVrayOrCoronaBoolean8 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 9 then(
                                    convertSceneToVrayOrCoronaBoolean9 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 10 then(
                                    convertSceneToVrayOrCoronaBoolean10 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 11 then(
                                    convertSceneToVrayOrCoronaBoolean11 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 12 then(
                                    convertSceneToVrayOrCoronaBoolean12 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 13 then(
                                    convertSceneToVrayOrCoronaBoolean13 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 14 then(
                                    convertSceneToVrayOrCoronaBoolean14 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 15 then(
                                    convertSceneToVrayOrCoronaBoolean15 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 16 then(
                                    convertSceneToVrayOrCoronaBoolean16 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 17 then(
                                    convertSceneToVrayOrCoronaBoolean17 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 18 then(
                                    convertSceneToVrayOrCoronaBoolean18 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 19 then(
                                    convertSceneToVrayOrCoronaBoolean19 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 20 then(
                                    convertSceneToVrayOrCoronaBoolean20 = false
                                )
                        )
                    )

                -- Object handling

                    on saveEachObjectSeparatelyCheckBox changed state do(
                        if state == true then(
                            -- Change variable

                                if currentVolumeDropDownListSelectionInteger == 1 then(
                                    saveEachObjectSeparatelyBoolean1 = true
                                    attachObjectsBoolean1 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 2 then(
                                    saveEachObjectSeparatelyBoolean2 = true
                                    attachObjectsBoolean2 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 3 then(
                                    saveEachObjectSeparatelyBoolean3 = true
                                    attachObjectsBoolean3 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 4 then(
                                    saveEachObjectSeparatelyBoolean4 = true
                                    attachObjectsBoolean4 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 5 then(
                                    saveEachObjectSeparatelyBoolean5 = true
                                    attachObjectsBoolean5 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 6 then(
                                    saveEachObjectSeparatelyBoolean6 = true
                                    attachObjectsBoolean6 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 7 then(
                                    saveEachObjectSeparatelyBoolean7 = true
                                    attachObjectsBoolean7 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 8 then(
                                    saveEachObjectSeparatelyBoolean8 = true
                                    attachObjectsBoolean8 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 9 then(
                                    saveEachObjectSeparatelyBoolean9 = true
                                    attachObjectsBoolean9 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 10 then(
                                    saveEachObjectSeparatelyBoolean10 = true
                                    attachObjectsBoolean10 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 11 then(
                                    saveEachObjectSeparatelyBoolean11 = true
                                    attachObjectsBoolean11 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 12 then(
                                    saveEachObjectSeparatelyBoolean12 = true
                                    attachObjectsBoolean12 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 13 then(
                                    saveEachObjectSeparatelyBoolean13 = true
                                    attachObjectsBoolean13 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 14 then(
                                    saveEachObjectSeparatelyBoolean14 = true
                                    attachObjectsBoolean14 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 15 then(
                                    saveEachObjectSeparatelyBoolean15 = true
                                    attachObjectsBoolean15 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 16 then(
                                    saveEachObjectSeparatelyBoolean16 = true
                                    attachObjectsBoolean16 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 17 then(
                                    saveEachObjectSeparatelyBoolean17 = true
                                    attachObjectsBoolean17 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 18 then(
                                    saveEachObjectSeparatelyBoolean18 = true
                                    attachObjectsBoolean18 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 19 then(
                                    saveEachObjectSeparatelyBoolean19 = true
                                    attachObjectsBoolean19 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 20 then(
                                    saveEachObjectSeparatelyBoolean20 = true
                                    attachObjectsBoolean20 = false
                                )

                            -- Change variable

                                if currentVolumeDropDownListSelectionInteger == 1 then(
                                    attachObjectsCheckBoxEnabled1 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 2 then(
                                    attachObjectsCheckBoxEnabled2 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 3 then(
                                    attachObjectsCheckBoxEnabled3 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 4 then(
                                    attachObjectsCheckBoxEnabled4 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 5 then(
                                    attachObjectsCheckBoxEnabled5 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 6 then(
                                    attachObjectsCheckBoxEnabled6 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 7 then(
                                    attachObjectsCheckBoxEnabled7 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 8 then(
                                    attachObjectsCheckBoxEnabled8 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 9 then(
                                    attachObjectsCheckBoxEnabled9 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 10 then(
                                    attachObjectsCheckBoxEnabled10 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 11 then(
                                    attachObjectsCheckBoxEnabled11 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 12 then(
                                    attachObjectsCheckBoxEnabled12 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 13 then(
                                    attachObjectsCheckBoxEnabled13 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 14 then(
                                    attachObjectsCheckBoxEnabled14 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 15 then(
                                    attachObjectsCheckBoxEnabled15 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 16 then(
                                    attachObjectsCheckBoxEnabled16 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 17 then(
                                    attachObjectsCheckBoxEnabled17 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 18 then(
                                    attachObjectsCheckBoxEnabled18 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 19 then(
                                    attachObjectsCheckBoxEnabled19 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 20 then(
                                    attachObjectsCheckBoxEnabled20 = false
                                )

                            -- Other Components

                                attachObjectsCheckBox.enabled = false

                                attachObjectsCheckBox.checked = false
                        )else(
                            -- Change variable

                                if currentVolumeDropDownListSelectionInteger == 1 then(
                                    saveEachObjectSeparatelyBoolean1 = false
                                    attachObjectsBoolean1 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 2 then(
                                    saveEachObjectSeparatelyBoolean2 = false
                                    attachObjectsBoolean2 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 3 then(
                                    saveEachObjectSeparatelyBoolean3 = false
                                    attachObjectsBoolean3 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 4 then(
                                    saveEachObjectSeparatelyBoolean4 = false
                                    attachObjectsBoolean4 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 5 then(
                                    saveEachObjectSeparatelyBoolean5 = false
                                    attachObjectsBoolean5 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 6 then(
                                    saveEachObjectSeparatelyBoolean6 = false
                                    attachObjectsBoolean6 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 7 then(
                                    saveEachObjectSeparatelyBoolean7 = false
                                    attachObjectsBoolean7 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 8 then(
                                    saveEachObjectSeparatelyBoolean8 = false
                                    attachObjectsBoolean8 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 9 then(
                                    saveEachObjectSeparatelyBoolean9 = false
                                    attachObjectsBoolean9 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 10 then(
                                    saveEachObjectSeparatelyBoolean10 = false
                                    attachObjectsBoolean10 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 11 then(
                                    saveEachObjectSeparatelyBoolean11 = false
                                    attachObjectsBoolean11 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 12 then(
                                    saveEachObjectSeparatelyBoolean12 = false
                                    attachObjectsBoolean12 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 13 then(
                                    saveEachObjectSeparatelyBoolean13 = false
                                    attachObjectsBoolean13 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 14 then(
                                    saveEachObjectSeparatelyBoolean14 = false
                                    attachObjectsBoolean14 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 15 then(
                                    saveEachObjectSeparatelyBoolean15 = false
                                    attachObjectsBoolean15 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 16 then(
                                    saveEachObjectSeparatelyBoolean16 = false
                                    attachObjectsBoolean16 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 17 then(
                                    saveEachObjectSeparatelyBoolean17 = false
                                    attachObjectsBoolean17 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 18 then(
                                    saveEachObjectSeparatelyBoolean18 = false
                                    attachObjectsBoolean18 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 19 then(
                                    saveEachObjectSeparatelyBoolean19 = false
                                    attachObjectsBoolean19 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 20 then(
                                    saveEachObjectSeparatelyBoolean20 = false
                                    attachObjectsBoolean20 = true
                                )

                            -- Change variable

                                if currentVolumeDropDownListSelectionInteger == 1 then(
                                    attachObjectsCheckBoxEnabled1 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 2 then(
                                    attachObjectsCheckBoxEnabled2 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 3 then(
                                    attachObjectsCheckBoxEnabled3 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 4 then(
                                    attachObjectsCheckBoxEnabled4 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 5 then(
                                    attachObjectsCheckBoxEnabled5 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 6 then(
                                    attachObjectsCheckBoxEnabled6 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 7 then(
                                    attachObjectsCheckBoxEnabled7 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 8 then(
                                    attachObjectsCheckBoxEnabled8 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 9 then(
                                    attachObjectsCheckBoxEnabled9 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 10 then(
                                    attachObjectsCheckBoxEnabled10 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 11 then(
                                    attachObjectsCheckBoxEnabled11 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 12 then(
                                    attachObjectsCheckBoxEnabled12 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 13 then(
                                    attachObjectsCheckBoxEnabled13 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 14 then(
                                    attachObjectsCheckBoxEnabled14 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 15 then(
                                    attachObjectsCheckBoxEnabled15 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 16 then(
                                    attachObjectsCheckBoxEnabled16 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 17 then(
                                    attachObjectsCheckBoxEnabled17 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 18 then(
                                    attachObjectsCheckBoxEnabled18 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 19 then(
                                    attachObjectsCheckBoxEnabled19 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 20 then(
                                    attachObjectsCheckBoxEnabled20 = true
                                )

                            -- Other Components

                                attachObjectsCheckBox.enabled = true
                        )
                    )

                    on attachObjectsCheckBox changed state do(
                        if state == true then(
                            -- Change variable

                                if currentVolumeDropDownListSelectionInteger == 1 then(
                                    attachObjectsBoolean1 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 2 then(
                                    attachObjectsBoolean2 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 3 then(
                                    attachObjectsBoolean3 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 4 then(
                                    attachObjectsBoolean4 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 5 then(
                                    attachObjectsBoolean5 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 6 then(
                                    attachObjectsBoolean6 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 7 then(
                                    attachObjectsBoolean7 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 8 then(
                                    attachObjectsBoolean8 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 9 then(
                                    attachObjectsBoolean9 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 10 then(
                                    attachObjectsBoolean10 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 11 then(
                                    attachObjectsBoolean11 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 12 then(
                                    attachObjectsBoolean12 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 13 then(
                                    attachObjectsBoolean13 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 14 then(
                                    attachObjectsBoolean14 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 15 then(
                                    attachObjectsBoolean15 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 16 then(
                                    attachObjectsBoolean16 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 17 then(
                                    attachObjectsBoolean17 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 18 then(
                                    attachObjectsBoolean18 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 19 then(
                                    attachObjectsBoolean19 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 20 then(
                                    attachObjectsBoolean20 = true
                                )
                        )else(
                            -- Change variable

                                if currentVolumeDropDownListSelectionInteger == 1 then(
                                    attachObjectsBoolean1 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 2 then(
                                    attachObjectsBoolean2 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 3 then(
                                    attachObjectsBoolean3 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 4 then(
                                    attachObjectsBoolean4 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 5 then(
                                    attachObjectsBoolean5 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 6 then(
                                    attachObjectsBoolean6 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 7 then(
                                    attachObjectsBoolean7 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 8 then(
                                    attachObjectsBoolean8 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 9 then(
                                    attachObjectsBoolean9 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 10 then(
                                    attachObjectsBoolean10 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 11 then(
                                    attachObjectsBoolean11 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 12 then(
                                    attachObjectsBoolean12 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 13 then(
                                    attachObjectsBoolean13 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 14 then(
                                    attachObjectsBoolean14 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 15 then(
                                    attachObjectsBoolean15 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 16 then(
                                    attachObjectsBoolean16 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 17 then(
                                    attachObjectsBoolean17 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 18 then(
                                    attachObjectsBoolean18 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 19 then(
                                    attachObjectsBoolean19 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 20 then(
                                    attachObjectsBoolean20 = false
                                )
                        )
                    )

                    on proxyObjectsCheckBox changed state do(
                        if state == true then(
                            -- Change variable

                                if currentVolumeDropDownListSelectionInteger == 1 then(
                                    proxyObjectsBoolean1 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 2 then(
                                    proxyObjectsBoolean2 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 3 then(
                                    proxyObjectsBoolean3 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 4 then(
                                    proxyObjectsBoolean4 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 5 then(
                                    proxyObjectsBoolean5 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 6 then(
                                    proxyObjectsBoolean6 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 7 then(
                                    proxyObjectsBoolean7 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 8 then(
                                    proxyObjectsBoolean8 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 9 then(
                                    proxyObjectsBoolean9 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 10 then(
                                    proxyObjectsBoolean10 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 11 then(
                                    proxyObjectsBoolean11 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 12 then(
                                    proxyObjectsBoolean12 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 13 then(
                                    proxyObjectsBoolean13 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 14 then(
                                    proxyObjectsBoolean14 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 15 then(
                                    proxyObjectsBoolean15 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 16 then(
                                    proxyObjectsBoolean16 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 17 then(
                                    proxyObjectsBoolean17 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 18 then(
                                    proxyObjectsBoolean18 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 19 then(
                                    proxyObjectsBoolean19 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 20 then(
                                    proxyObjectsBoolean20 = true
                                )

                            -- Change variable

                                if currentVolumeDropDownListSelectionInteger == 1 then(
                                    facesNumberSpinnerEnabled1 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 2 then(
                                    facesNumberSpinnerEnabled2 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 3 then(
                                    facesNumberSpinnerEnabled3 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 4 then(
                                    facesNumberSpinnerEnabled4 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 5 then(
                                    facesNumberSpinnerEnabled5 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 6 then(
                                    facesNumberSpinnerEnabled6 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 7 then(
                                    facesNumberSpinnerEnabled7 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 8 then(
                                    facesNumberSpinnerEnabled8 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 9 then(
                                    facesNumberSpinnerEnabled9 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 10 then(
                                    facesNumberSpinnerEnabled10 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 11 then(
                                    facesNumberSpinnerEnabled11 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 12 then(
                                    facesNumberSpinnerEnabled12 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 13 then(
                                    facesNumberSpinnerEnabled13 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 14 then(
                                    facesNumberSpinnerEnabled14 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 15 then(
                                    facesNumberSpinnerEnabled15 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 16 then(
                                    facesNumberSpinnerEnabled16 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 17 then(
                                    facesNumberSpinnerEnabled17 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 18 then(
                                    facesNumberSpinnerEnabled18 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 19 then(
                                    facesNumberSpinnerEnabled19 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 20 then(
                                    facesNumberSpinnerEnabled20 = true
                                )

                            -- Other Components

                                facesNumberSpinner.enabled = true
                        )else(
                            -- Change variable

                                if currentVolumeDropDownListSelectionInteger == 1 then(
                                    proxyObjectsBoolean1 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 2 then(
                                    proxyObjectsBoolean2 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 3 then(
                                    proxyObjectsBoolean3 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 4 then(
                                    proxyObjectsBoolean4 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 5 then(
                                    proxyObjectsBoolean5 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 6 then(
                                    proxyObjectsBoolean6 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 7 then(
                                    proxyObjectsBoolean7 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 8 then(
                                    proxyObjectsBoolean8 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 9 then(
                                    proxyObjectsBoolean9 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 10 then(
                                    proxyObjectsBoolean10 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 11 then(
                                    proxyObjectsBoolean11 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 12 then(
                                    proxyObjectsBoolean12 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 13 then(
                                    proxyObjectsBoolean13 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 14 then(
                                    proxyObjectsBoolean14 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 15 then(
                                    proxyObjectsBoolean15 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 16 then(
                                    proxyObjectsBoolean16 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 17 then(
                                    proxyObjectsBoolean17 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 18 then(
                                    proxyObjectsBoolean18 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 19 then(
                                    proxyObjectsBoolean19 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 20 then(
                                    proxyObjectsBoolean20 = false
                                )

                            -- Change variable

                                if currentVolumeDropDownListSelectionInteger == 1 then(
                                    facesNumberSpinnerEnabled1 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 2 then(
                                    facesNumberSpinnerEnabled2 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 3 then(
                                    facesNumberSpinnerEnabled3 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 4 then(
                                    facesNumberSpinnerEnabled4 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 5 then(
                                    facesNumberSpinnerEnabled5 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 6 then(
                                    facesNumberSpinnerEnabled6 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 7 then(
                                    facesNumberSpinnerEnabled7 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 8 then(
                                    facesNumberSpinnerEnabled8 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 9 then(
                                    facesNumberSpinnerEnabled9 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 10 then(
                                    facesNumberSpinnerEnabled10 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 11 then(
                                    facesNumberSpinnerEnabled11 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 12 then(
                                    facesNumberSpinnerEnabled12 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 13 then(
                                    facesNumberSpinnerEnabled13 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 14 then(
                                    facesNumberSpinnerEnabled14 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 15 then(
                                    facesNumberSpinnerEnabled15 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 16 then(
                                    facesNumberSpinnerEnabled16 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 17 then(
                                    facesNumberSpinnerEnabled17 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 18 then(
                                    facesNumberSpinnerEnabled18 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 19 then(
                                    facesNumberSpinnerEnabled19 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 20 then(
                                    facesNumberSpinnerEnabled20 = false
                                )

                            -- Other Components

                                facesNumberSpinner.enabled = false
                        )
                    )

                    on facesNumberSpinner changed num do(
                        -- Change variable

                            if currentVolumeDropDownListSelectionInteger == 1 then(
                                facesNumberInteger1 = num
                            )

                            if currentVolumeDropDownListSelectionInteger == 2 then(
                                facesNumberInteger2 = num
                            )

                            if currentVolumeDropDownListSelectionInteger == 3 then(
                                facesNumberInteger3 = num
                            )

                            if currentVolumeDropDownListSelectionInteger == 4 then(
                                facesNumberInteger4 = num
                            )

                            if currentVolumeDropDownListSelectionInteger == 5 then(
                                facesNumberInteger5 = num
                            )

                            if currentVolumeDropDownListSelectionInteger == 6 then(
                                facesNumberInteger6 = num
                            )

                            if currentVolumeDropDownListSelectionInteger == 7 then(
                                facesNumberInteger7 = num
                            )

                            if currentVolumeDropDownListSelectionInteger == 8 then(
                                facesNumberInteger8 = num
                            )

                            if currentVolumeDropDownListSelectionInteger == 9 then(
                                facesNumberInteger9 = num
                            )

                            if currentVolumeDropDownListSelectionInteger == 10 then(
                                facesNumberInteger10 = num
                            )

                            if currentVolumeDropDownListSelectionInteger == 11 then(
                                facesNumberInteger11 = num
                            )

                            if currentVolumeDropDownListSelectionInteger == 12 then(
                                facesNumberInteger12 = num
                            )

                            if currentVolumeDropDownListSelectionInteger == 13 then(
                                facesNumberInteger13 = num
                            )

                            if currentVolumeDropDownListSelectionInteger == 14 then(
                                facesNumberInteger14 = num
                            )

                            if currentVolumeDropDownListSelectionInteger == 15 then(
                                facesNumberInteger15 = num
                            )

                            if currentVolumeDropDownListSelectionInteger == 16 then(
                                facesNumberInteger16 = num
                            )

                            if currentVolumeDropDownListSelectionInteger == 17 then(
                                facesNumberInteger17 = num
                            )

                            if currentVolumeDropDownListSelectionInteger == 18 then(
                                facesNumberInteger18 = num
                            )

                            if currentVolumeDropDownListSelectionInteger == 19 then(
                                facesNumberInteger19 = num
                            )

                            if currentVolumeDropDownListSelectionInteger == 20 then(
                                facesNumberInteger20 = num
                            )
                    )

                    on coronaCheckbox changed state do(
                        if state == true then(
                            -- Change variable

                                if currentVolumeDropDownListSelectionInteger == 1 then(
                                    coronaBoolean1 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 2 then(
                                    coronaBoolean2 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 3 then(
                                    coronaBoolean3 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 4 then(
                                    coronaBoolean4 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 5 then(
                                    coronaBoolean5 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 6 then(
                                    coronaBoolean6 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 7 then(
                                    coronaBoolean7 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 8 then(
                                    coronaBoolean8 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 9 then(
                                    coronaBoolean9 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 10 then(
                                    coronaBoolean10 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 11 then(
                                    coronaBoolean11 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 12 then(
                                    coronaBoolean12 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 13 then(
                                    coronaBoolean13 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 14 then(
                                    coronaBoolean14 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 15 then(
                                    coronaBoolean15 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 16 then(
                                    coronaBoolean16 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 17 then(
                                    coronaBoolean17 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 18 then(
                                    coronaBoolean18 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 19 then(
                                    coronaBoolean19 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 20 then(
                                    coronaBoolean20 = true
                                )
                        )else(
                            -- Change variable

                                if currentVolumeDropDownListSelectionInteger == 1 then(
                                    coronaBoolean1 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 2 then(
                                    coronaBoolean2 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 3 then(
                                    coronaBoolean3 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 4 then(
                                    coronaBoolean4 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 5 then(
                                    coronaBoolean5 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 6 then(
                                    coronaBoolean6 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 7 then(
                                    coronaBoolean7 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 8 then(
                                    coronaBoolean8 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 9 then(
                                    coronaBoolean9 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 10 then(
                                    coronaBoolean10 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 11 then(
                                    coronaBoolean11 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 12 then(
                                    coronaBoolean12 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 13 then(
                                    coronaBoolean13 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 14 then(
                                    coronaBoolean14 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 15 then(
                                    coronaBoolean15 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 16 then(
                                    coronaBoolean16 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 17 then(
                                    coronaBoolean17 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 18 then(
                                    coronaBoolean18 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 19 then(
                                    coronaBoolean19 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 20 then(
                                    coronaBoolean20 = false
                                )
                        )
                    )

                -- Output filters

                    on includeCamerasCheckBox changed state do(
                        if state == true then(
                            -- Change variable

                                if currentVolumeDropDownListSelectionInteger == 1 then(
                                    includeCamerasBoolean1 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 2 then(
                                    includeCamerasBoolean2 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 3 then(
                                    includeCamerasBoolean3 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 4 then(
                                    includeCamerasBoolean4 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 5 then(
                                    includeCamerasBoolean5 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 6 then(
                                    includeCamerasBoolean6 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 7 then(
                                    includeCamerasBoolean7 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 8 then(
                                    includeCamerasBoolean8 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 9 then(
                                    includeCamerasBoolean9 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 10 then(
                                    includeCamerasBoolean10 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 11 then(
                                    includeCamerasBoolean11 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 12 then(
                                    includeCamerasBoolean12 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 13 then(
                                    includeCamerasBoolean13 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 14 then(
                                    includeCamerasBoolean14 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 15 then(
                                    includeCamerasBoolean15 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 16 then(
                                    includeCamerasBoolean16 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 17 then(
                                    includeCamerasBoolean17 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 18 then(
                                    includeCamerasBoolean18 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 19 then(
                                    includeCamerasBoolean19 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 20 then(
                                    includeCamerasBoolean20 = true
                                )
                        )else(
                            -- Change variable

                                if currentVolumeDropDownListSelectionInteger == 1 then(
                                    includeCamerasBoolean1 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 2 then(
                                    includeCamerasBoolean2 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 3 then(
                                    includeCamerasBoolean3 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 4 then(
                                    includeCamerasBoolean4 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 5 then(
                                    includeCamerasBoolean5 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 6 then(
                                    includeCamerasBoolean6 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 7 then(
                                    includeCamerasBoolean7 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 8 then(
                                    includeCamerasBoolean8 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 9 then(
                                    includeCamerasBoolean9 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 10 then(
                                    includeCamerasBoolean10 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 11 then(
                                    includeCamerasBoolean11 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 12 then(
                                    includeCamerasBoolean12 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 13 then(
                                    includeCamerasBoolean13 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 14 then(
                                    includeCamerasBoolean14 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 15 then(
                                    includeCamerasBoolean15 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 16 then(
                                    includeCamerasBoolean16 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 17 then(
                                    includeCamerasBoolean17 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 18 then(
                                    includeCamerasBoolean18 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 19 then(
                                    includeCamerasBoolean19 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 20 then(
                                    includeCamerasBoolean20 = false
                                )
                        )
                    )

                    on includeLightsCheckBox changed state do(
                        if state == true then(
                            -- Change variable

                                if currentVolumeDropDownListSelectionInteger == 1 then(
                                    includeLightsBoolean1 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 2 then(
                                    includeLightsBoolean2 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 3 then(
                                    includeLightsBoolean3 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 4 then(
                                    includeLightsBoolean4 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 5 then(
                                    includeLightsBoolean5 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 6 then(
                                    includeLightsBoolean6 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 7 then(
                                    includeLightsBoolean7 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 8 then(
                                    includeLightsBoolean8 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 9 then(
                                    includeLightsBoolean9 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 10 then(
                                    includeLightsBoolean10 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 11 then(
                                    includeLightsBoolean11 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 12 then(
                                    includeLightsBoolean12 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 13 then(
                                    includeLightsBoolean13 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 14 then(
                                    includeLightsBoolean14 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 15 then(
                                    includeLightsBoolean15 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 16 then(
                                    includeLightsBoolean16 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 17 then(
                                    includeLightsBoolean17 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 18 then(
                                    includeLightsBoolean18 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 19 then(
                                    includeLightsBoolean19 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 20 then(
                                    includeLightsBoolean20 = true
                                )
                        )else(
                            -- Change variable

                                if currentVolumeDropDownListSelectionInteger == 1 then(
                                    includeLightsBoolean1 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 2 then(
                                    includeLightsBoolean2 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 3 then(
                                    includeLightsBoolean3 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 4 then(
                                    includeLightsBoolean4 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 5 then(
                                    includeLightsBoolean5 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 6 then(
                                    includeLightsBoolean6 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 7 then(
                                    includeLightsBoolean7 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 8 then(
                                    includeLightsBoolean8 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 9 then(
                                    includeLightsBoolean9 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 10 then(
                                    includeLightsBoolean10 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 11 then(
                                    includeLightsBoolean11 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 12 then(
                                    includeLightsBoolean12 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 13 then(
                                    includeLightsBoolean13 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 14 then(
                                    includeLightsBoolean14 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 15 then(
                                    includeLightsBoolean15 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 16 then(
                                    includeLightsBoolean16 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 17 then(
                                    includeLightsBoolean17 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 18 then(
                                    includeLightsBoolean18 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 19 then(
                                    includeLightsBoolean19 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 20 then(
                                    includeLightsBoolean20 = false
                                )
                        )
                    )

                -- File naming

                    on replaceAllTextCheckBox changed state do(
                        if replaceAllTextCheckBox.checked == true then(
                            -- Variables

                                -- Change variable

                                    if currentVolumeDropDownListSelectionInteger == 1 then(
                                        replaceAllTextBoolean1 = true
                                        retainSpecifiedTextFromFileNameBoolean1 = false
                                        retainSpecifiedTextFromObjectNameBoolean1 = false
                                        retainAllTextFromFileNameBoolean1 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 2 then(
                                        replaceAllTextBoolean2 = true
                                        retainSpecifiedTextFromFileNameBoolean2 = false
                                        retainSpecifiedTextFromObjectNameBoolean2 = false
                                        retainAllTextFromFileNameBoolean2 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 3 then(
                                        replaceAllTextBoolean3 = true
                                        retainSpecifiedTextFromFileNameBoolean3 = false
                                        retainSpecifiedTextFromObjectNameBoolean3 = false
                                        retainAllTextFromFileNameBoolean3 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 4 then(
                                        replaceAllTextBoolean4 = true
                                        retainSpecifiedTextFromFileNameBoolean4 = false
                                        retainSpecifiedTextFromObjectNameBoolean4 = false
                                        replaceAllTextBoolean = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 5 then(
                                        replaceAllTextBoolean5 = true
                                        retainSpecifiedTextFromFileNameBoolean5 = false
                                        retainSpecifiedTextFromObjectNameBoolean5 = false
                                        retainAllTextFromFileNameBoolean5 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 6 then(
                                        replaceAllTextBoolean6 = true
                                        retainSpecifiedTextFromFileNameBoolean6 = false
                                        retainSpecifiedTextFromObjectNameBoolean6 = false
                                        retainAllTextFromFileNameBoolean6 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 7 then(
                                        replaceAllTextBoolean7 = true
                                        retainSpecifiedTextFromFileNameBoolean7 = false
                                        retainSpecifiedTextFromObjectNameBoolean7 = false
                                        retainAllTextFromFileNameBoolean7 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 8 then(
                                        replaceAllTextBoolean8 = true
                                        retainSpecifiedTextFromFileNameBoolean8 = false
                                        retainSpecifiedTextFromObjectNameBoolean8 = false
                                        retainAllTextFromFileNameBoolean8 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 9 then(
                                        replaceAllTextBoolean9 = true
                                        retainSpecifiedTextFromFileNameBoolean9 = false
                                        retainSpecifiedTextFromObjectNameBoolean9 = false
                                        retainAllTextFromFileNameBoolean9 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 10 then(
                                        replaceAllTextBoolean10 = true
                                        retainSpecifiedTextFromFileNameBoolean10 = false
                                        retainSpecifiedTextFromObjectNameBoolean10 = false
                                        retainAllTextFromFileNameBoolean10 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 11 then(
                                        replaceAllTextBoolean11 = true
                                        retainSpecifiedTextFromFileNameBoolean11 = false
                                        retainSpecifiedTextFromObjectNameBoolean11 = false
                                        retainAllTextFromFileNameBoolean11 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 12 then(
                                        replaceAllTextBoolean12 = true
                                        retainSpecifiedTextFromFileNameBoolean12 = false
                                        retainSpecifiedTextFromObjectNameBoolean12 = false
                                        retainAllTextFromFileNameBoolean12 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 13 then(
                                        replaceAllTextBoolean13 = true
                                        retainSpecifiedTextFromFileNameBoolean13 = false
                                        retainSpecifiedTextFromObjectNameBoolean13 = false
                                        retainAllTextFromFileNameBoolean13 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 14 then(
                                        replaceAllTextBoolean14 = true
                                        retainSpecifiedTextFromFileNameBoolean14 = false
                                        retainSpecifiedTextFromObjectNameBoolean14 = false
                                        retainAllTextFromFileNameBoolean14 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 15 then(
                                        replaceAllTextBoolean15 = true
                                        retainSpecifiedTextFromFileNameBoolean15 = false
                                        retainSpecifiedTextFromObjectNameBoolean15 = false
                                        retainAllTextFromFileNameBoolean15 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 16 then(
                                        replaceAllTextBoolean16 = true
                                        retainSpecifiedTextFromFileNameBoolean16 = false
                                        retainSpecifiedTextFromObjectNameBoolean16 = false
                                        retainAllTextFromFileNameBoolean16 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 17 then(
                                        replaceAllTextBoolean17 = true
                                        retainSpecifiedTextFromFileNameBoolean17 = false
                                        retainSpecifiedTextFromObjectNameBoolean17 = false
                                        retainAllTextFromFileNameBoolean17 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 18 then(
                                        replaceAllTextBoolean18 = true
                                        retainSpecifiedTextFromFileNameBoolean18 = false
                                        retainSpecifiedTextFromObjectNameBoolean18 = false
                                        retainAllTextFromFileNameBoolean18 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 19 then(
                                        replaceAllTextBoolean19 = true
                                        retainSpecifiedTextFromFileNameBoolean19 = false
                                        retainSpecifiedTextFromObjectNameBoolean19 = false
                                        retainAllTextFromFileNameBoolean19 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 20 then(
                                        replaceAllTextBoolean20 = true
                                        retainSpecifiedTextFromFileNameBoolean20 = false
                                        retainSpecifiedTextFromObjectNameBoolean20 = false
                                        retainAllTextFromFileNameBoolean20 = false
                                    )

                                -- Change variable

                                    if currentVolumeDropDownListSelectionInteger == 1 then(
                                        phraseToSplitWithEditTextEnabled1 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled1 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled1 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 2 then(
                                        phraseToSplitWithEditTextEnabled2 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled2 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled2 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 3 then(
                                        phraseToSplitWithEditTextEnabled3 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled3 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled3 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 4 then(
                                        phraseToSplitWithEditTextEnabled4 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled4 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled4 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 5 then(
                                        phraseToSplitWithEditTextEnabled5 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled5 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled5 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 6 then(
                                        phraseToSplitWithEditTextEnabled6 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled6 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled6 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 7 then(
                                        phraseToSplitWithEditTextEnabled7 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled7 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled7 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 8 then(
                                        phraseToSplitWithEditTextEnabled8 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled8 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled8 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 9 then(
                                        phraseToSplitWithEditTextEnabled9 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled9 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled9 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 10 then(
                                        phraseToSplitWithEditTextEnabled10 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled10 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled10 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 11 then(
                                        phraseToSplitWithEditTextEnabled11 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled11 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled11 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 12 then(
                                        phraseToSplitWithEditTextEnabled12 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled12 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled12 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 13 then(
                                        phraseToSplitWithEditTextEnabled13 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled13 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled13 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 14 then(
                                        phraseToSplitWithEditTextEnabled14 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled14 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled14 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 15 then(
                                        phraseToSplitWithEditTextEnabled15 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled15 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled15 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 16 then(
                                        phraseToSplitWithEditTextEnabled16 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled16 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled16 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 17 then(
                                        phraseToSplitWithEditTextEnabled17 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled17 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled17 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 18 then(
                                        phraseToSplitWithEditTextEnabled18 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled18 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled18 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 19 then(
                                        phraseToSplitWithEditTextEnabled19 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled19 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled19 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 20 then(
                                        phraseToSplitWithEditTextEnabled20 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled20 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled20 = false
                                    )

                            -- Other components

                                -- Checking

                                    retainSpecifiedTextFromFileNameCheckBox.checked = false

                                    retainSpecifiedTextFromObjectNameCheckBox.checked = false

                                    retainAllTextFromFileNameCheckBox.checked = false

                                -- Enabling/disabling

                                    phraseToSplitWithEditText.enabled = false

                                    numberOfIndicesToRemoveFromStartSpinner.enabled = false

                                    numberOfIndicesToRemoveFromEndSpinner.enabled = false
                        )else(
                            replaceAllTextCheckBox.checked = true
                        )
                    )

                    on retainSpecifiedTextFromFileNameCheckBox changed state do(
                        if retainSpecifiedTextFromFileNameCheckBox.checked == true then(
                            -- Variables

                                -- Change variable

                                    if currentVolumeDropDownListSelectionInteger == 1 then(
                                        retainSpecifiedTextFromFileNameBoolean1 = true
                                        retainSpecifiedTextFromObjectNameBoolean1 = false
                                        replaceAllTextBoolean1 = false
                                        retainAllTextFromFileNameBoolean1 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 2 then(
                                        retainSpecifiedTextFromFileNameBoolean2 = true
                                        retainSpecifiedTextFromObjectNameBoolean2 = false
                                        replaceAllTextBoolean2 = false
                                        retainAllTextFromFileNameBoolean2 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 3 then(
                                        retainSpecifiedTextFromFileNameBoolean3 = true
                                        retainSpecifiedTextFromObjectNameBoolean3 = false
                                        replaceAllTextBoolean3 = false
                                        retainAllTextFromFileNameBoolean3 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 4 then(
                                        retainSpecifiedTextFromFileNameBoolean4 = true
                                        retainSpecifiedTextFromObjectNameBoolean4 = false
                                        replaceAllTextBoolean4 = false
                                        retainAllTextFromFileNameBoolean4 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 5 then(
                                        retainSpecifiedTextFromFileNameBoolean5 = true
                                        retainSpecifiedTextFromObjectNameBoolean5 = false
                                        replaceAllTextBoolean5 = false
                                        retainAllTextFromFileNameBoolean5 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 6 then(
                                        retainSpecifiedTextFromFileNameBoolean6 = true
                                        retainSpecifiedTextFromObjectNameBoolean6 = false
                                        replaceAllTextBoolean6 = false
                                        retainAllTextFromFileNameBoolean6 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 7 then(
                                        retainSpecifiedTextFromFileNameBoolean7 = true
                                        retainSpecifiedTextFromObjectNameBoolean7 = false
                                        replaceAllTextBoolean7 = false
                                        retainAllTextFromFileNameBoolean7 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 8 then(
                                        retainSpecifiedTextFromFileNameBoolean8 = true
                                        retainSpecifiedTextFromObjectNameBoolean8 = false
                                        replaceAllTextBoolean8 = false
                                        retainAllTextFromFileNameBoolean8 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 9 then(
                                        retainSpecifiedTextFromFileNameBoolean9 = true
                                        retainSpecifiedTextFromObjectNameBoolean9 = false
                                        replaceAllTextBoolean9 = false
                                        retainAllTextFromFileNameBoolean9 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 10 then(
                                        retainSpecifiedTextFromFileNameBoolean10 = true
                                        retainSpecifiedTextFromObjectNameBoolean10 = false
                                        replaceAllTextBoolean10 = false
                                        retainAllTextFromFileNameBoolean10 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 11 then(
                                        retainSpecifiedTextFromFileNameBoolean11 = true
                                        retainSpecifiedTextFromObjectNameBoolean11 = false
                                        replaceAllTextBoolean11 = false
                                        retainAllTextFromFileNameBoolean11 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 12 then(
                                        retainSpecifiedTextFromFileNameBoolean12 = true
                                        retainSpecifiedTextFromObjectNameBoolean12 = false
                                        replaceAllTextBoolean12 = false
                                        retainAllTextFromFileNameBoolean12 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 13 then(
                                        retainSpecifiedTextFromFileNameBoolean13 = true
                                        retainSpecifiedTextFromObjectNameBoolean13 = false
                                        replaceAllTextBoolean13 = false
                                        retainAllTextFromFileNameBoolean13 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 14 then(
                                        retainSpecifiedTextFromFileNameBoolean14 = true
                                        retainSpecifiedTextFromObjectNameBoolean14 = false
                                        replaceAllTextBoolean14 = false
                                        retainAllTextFromFileNameBoolean14 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 15 then(
                                        retainSpecifiedTextFromFileNameBoolean15 = true
                                        retainSpecifiedTextFromObjectNameBoolean15 = false
                                        replaceAllTextBoolean15 = false
                                        retainAllTextFromFileNameBoolean15 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 16 then(
                                        retainSpecifiedTextFromFileNameBoolean16 = true
                                        retainSpecifiedTextFromObjectNameBoolean16 = false
                                        replaceAllTextBoolean16 = false
                                        retainAllTextFromFileNameBoolean16 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 17 then(
                                        retainSpecifiedTextFromFileNameBoolean17 = true
                                        retainSpecifiedTextFromObjectNameBoolean17 = false
                                        replaceAllTextBoolean17 = false
                                        retainAllTextFromFileNameBoolean17 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 18 then(
                                        retainSpecifiedTextFromFileNameBoolean18 = true
                                        retainSpecifiedTextFromObjectNameBoolean18 = false
                                        replaceAllTextBoolean18 = false
                                        retainAllTextFromFileNameBoolean18 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 19 then(
                                        retainSpecifiedTextFromFileNameBoolean19 = true
                                        retainSpecifiedTextFromObjectNameBoolean19 = false
                                        replaceAllTextBoolean19 = false
                                        retainAllTextFromFileNameBoolean19 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 20 then(
                                        retainSpecifiedTextFromFileNameBoolean20 = true
                                        retainSpecifiedTextFromObjectNameBoolean20 = false
                                        replaceAllTextBoolean20 = false
                                        retainAllTextFromFileNameBoolean20 = false
                                    )

                                -- Change variable

                                    if currentVolumeDropDownListSelectionInteger == 1 then(
                                        phraseToSplitWithEditTextEnabled1 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled1 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled1 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 2 then(
                                        phraseToSplitWithEditTextEnabled2 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled2 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled2 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 3 then(
                                        phraseToSplitWithEditTextEnabled3 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled3 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled3 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 4 then(
                                        phraseToSplitWithEditTextEnabled4 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled4 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled4 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 5 then(
                                        phraseToSplitWithEditTextEnabled5 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled5 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled5 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 6 then(
                                        phraseToSplitWithEditTextEnabled6 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled6 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled6 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 7 then(
                                        phraseToSplitWithEditTextEnabled7 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled7 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled7 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 8 then(
                                        phraseToSplitWithEditTextEnabled8 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled8 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled8 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 9 then(
                                        phraseToSplitWithEditTextEnabled9 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled9 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled9 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 10 then(
                                        phraseToSplitWithEditTextEnabled10 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled10 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled10 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 11 then(
                                        phraseToSplitWithEditTextEnabled11 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled11 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled11 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 12 then(
                                        phraseToSplitWithEditTextEnabled12 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled12 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled12 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 13 then(
                                        phraseToSplitWithEditTextEnabled13 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled13 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled13 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 14 then(
                                        phraseToSplitWithEditTextEnabled14 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled14 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled14 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 15 then(
                                        phraseToSplitWithEditTextEnabled15 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled15 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled15 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 16 then(
                                        phraseToSplitWithEditTextEnabled16 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled16 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled16 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 17 then(
                                        phraseToSplitWithEditTextEnabled17 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled17 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled17 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 18 then(
                                        phraseToSplitWithEditTextEnabled18 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled18 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled18 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 19 then(
                                        phraseToSplitWithEditTextEnabled19 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled19 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled19 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 20 then(
                                        phraseToSplitWithEditTextEnabled20 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled20 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled20 = true
                                    )

                            -- Other components

                                -- Checking

                                    retainSpecifiedTextFromObjectNameCheckBox.checked = false

                                    replaceAllTextCheckBox.checked = false

                                    retainAllTextFromFileNameCheckBox.checked = false

                                -- Enabling/disabling

                                    phraseToSplitWithEditText.enabled = true

                                    numberOfIndicesToRemoveFromStartSpinner.enabled = true

                                    numberOfIndicesToRemoveFromEndSpinner.enabled = true
                        )else(
                            retainSpecifiedTextFromFileNameCheckBox.checked = true
                        )
                    )

                    on retainSpecifiedTextFromObjectNameCheckBox changed state do(
                        if retainSpecifiedTextFromObjectNameCheckBox.checked == true then(
                            -- Variables

                                -- Change variable

                                    if currentVolumeDropDownListSelectionInteger == 1 then(
                                        retainSpecifiedTextFromObjectNameBoolean1 = true
                                        retainSpecifiedTextFromFileNameBoolean1 = false
                                        replaceAllTextBoolean1 = false
                                        retainAllTextFromFileNameBoolean1 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 2 then(
                                        retainSpecifiedTextFromObjectNameBoolean2 = true
                                        retainSpecifiedTextFromFileNameBoolean2 = false
                                        replaceAllTextBoolean2 = false
                                        retainAllTextFromFileNameBoolean2 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 3 then(
                                        retainSpecifiedTextFromObjectNameBoolean3 = true
                                        retainSpecifiedTextFromFileNameBoolean3 = false
                                        replaceAllTextBoolean3 = false
                                        retainAllTextFromFileNameBoolean3 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 4 then(
                                        retainSpecifiedTextFromObjectNameBoolean4 = true
                                        retainSpecifiedTextFromFileNameBoolean4 = false
                                        replaceAllTextBoolean4 = false
                                        retainAllTextFromFileNameBoolean4 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 5 then(
                                        retainSpecifiedTextFromObjectNameBoolean5 = true
                                        retainSpecifiedTextFromFileNameBoolean5 = false
                                        replaceAllTextBoolean5 = false
                                        retainAllTextFromFileNameBoolean5 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 6 then(
                                        retainSpecifiedTextFromObjectNameBoolean6 = true
                                        retainSpecifiedTextFromFileNameBoolean6 = false
                                        replaceAllTextBoolean6 = false
                                        retainAllTextFromFileNameBoolean6 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 7 then(
                                        retainSpecifiedTextFromObjectNameBoolean7 = true
                                        retainSpecifiedTextFromFileNameBoolean7 = false
                                        replaceAllTextBoolean7 = false
                                        retainAllTextFromFileNameBoolean7 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 8 then(
                                        retainSpecifiedTextFromObjectNameBoolean8 = true
                                        retainSpecifiedTextFromFileNameBoolean8 = false
                                        replaceAllTextBoolean8 = false
                                        retainAllTextFromFileNameBoolean8 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 9 then(
                                        retainSpecifiedTextFromObjectNameBoolean9 = true
                                        retainSpecifiedTextFromFileNameBoolean9 = false
                                        replaceAllTextBoolean9 = false
                                        retainAllTextFromFileNameBoolean9 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 10 then(
                                        retainSpecifiedTextFromObjectNameBoolean10 = true
                                        retainSpecifiedTextFromFileNameBoolean10 = false
                                        replaceAllTextBoolean10 = false
                                        retainAllTextFromFileNameBoolean10 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 11 then(
                                        retainSpecifiedTextFromObjectNameBoolean11 = true
                                        retainSpecifiedTextFromFileNameBoolean11 = false
                                        replaceAllTextBoolean11 = false
                                        retainAllTextFromFileNameBoolean11 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 12 then(
                                        retainSpecifiedTextFromObjectNameBoolean12 = true
                                        retainSpecifiedTextFromFileNameBoolean12 = false
                                        replaceAllTextBoolean12 = false
                                        retainAllTextFromFileNameBoolean12 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 13 then(
                                        retainSpecifiedTextFromObjectNameBoolean13 = true
                                        retainSpecifiedTextFromFileNameBoolean13 = false
                                        replaceAllTextBoolean13 = false
                                        retainAllTextFromFileNameBoolean13 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 14 then(
                                        retainSpecifiedTextFromObjectNameBoolean14 = true
                                        retainSpecifiedTextFromFileNameBoolean14 = false
                                        replaceAllTextBoolean14 = false
                                        retainAllTextFromFileNameBoolean14 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 15 then(
                                        retainSpecifiedTextFromObjectNameBoolean15 = true
                                        retainSpecifiedTextFromFileNameBoolean15 = false
                                        replaceAllTextBoolean15 = false
                                        retainAllTextFromFileNameBoolean15 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 16 then(
                                        retainSpecifiedTextFromObjectNameBoolean16 = true
                                        retainSpecifiedTextFromFileNameBoolean16 = false
                                        replaceAllTextBoolean16 = false
                                        retainAllTextFromFileNameBoolean16 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 17 then(
                                        retainSpecifiedTextFromObjectNameBoolean17 = true
                                        retainSpecifiedTextFromFileNameBoolean17 = false
                                        replaceAllTextBoolean17 = false
                                        retainAllTextFromFileNameBoolean17 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 18 then(
                                        retainSpecifiedTextFromObjectNameBoolean18 = true
                                        retainSpecifiedTextFromFileNameBoolean18 = false
                                        replaceAllTextBoolean18 = false
                                        retainAllTextFromFileNameBoolean18 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 19 then(
                                        retainSpecifiedTextFromObjectNameBoolean19 = true
                                        retainSpecifiedTextFromFileNameBoolean19 = false
                                        replaceAllTextBoolean19 = false
                                        retainAllTextFromFileNameBoolean19 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 20 then(
                                        retainSpecifiedTextFromObjectNameBoolean = true
                                        retainSpecifiedTextFromFileNameBoolean20 = false
                                        replaceAllTextBoolean20 = false
                                        retainAllTextFromFileNameBoolean20 = false
                                    )

                                -- Change variable

                                    if currentVolumeDropDownListSelectionInteger == 1 then(
                                        phraseToSplitWithEditTextEnabled1 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled1 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled1 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 2 then(
                                        phraseToSplitWithEditTextEnabled2 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled2 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled2 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 3 then(
                                        phraseToSplitWithEditTextEnabled3 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled3 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled3 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 4 then(
                                        phraseToSplitWithEditTextEnabled4 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled4 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled4 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 5 then(
                                        phraseToSplitWithEditTextEnabled5 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled5 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled5 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 6 then(
                                        phraseToSplitWithEditTextEnabled6 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled6 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled6 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 7 then(
                                        phraseToSplitWithEditTextEnabled7 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled7 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled7 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 8 then(
                                        phraseToSplitWithEditTextEnabled8 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled8 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled8 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 9 then(
                                        phraseToSplitWithEditTextEnabled9 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled9 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled9 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 10 then(
                                        phraseToSplitWithEditTextEnabled10 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled10 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled10 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 11 then(
                                        phraseToSplitWithEditTextEnabled11 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled11 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled11 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 12 then(
                                        phraseToSplitWithEditTextEnabled12 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled12 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled12 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 13 then(
                                        phraseToSplitWithEditTextEnabled13 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled13 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled13 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 14 then(
                                        phraseToSplitWithEditTextEnabled14 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled14 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled14 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 15 then(
                                        phraseToSplitWithEditTextEnabled15 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled15 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled15 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 16 then(
                                        phraseToSplitWithEditTextEnabled16 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled16 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled16 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 17 then(
                                        phraseToSplitWithEditTextEnabled17 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled17 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled17 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 18 then(
                                        phraseToSplitWithEditTextEnabled18 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled18 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled18 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 19 then(
                                        phraseToSplitWithEditTextEnabled19 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled19 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled19 = true
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 20 then(
                                        phraseToSplitWithEditTextEnabled20 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled20 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled20 = true
                                    )

                            -- Other components

                                -- Checking

                                    retainSpecifiedTextFromFileNameCheckBox.checked = false

                                    replaceAllTextCheckBox.checked = false

                                    retainAllTextFromFileNameCheckBox.checked = false

                                -- Enabling/disabling

                                    phraseToSplitWithEditText.enabled = true

                                    numberOfIndicesToRemoveFromStartSpinner.enabled = true

                                    numberOfIndicesToRemoveFromEndSpinner.enabled = true
                        )else(
                            retainSpecifiedTextFromObjectNameCheckBox.checked = true
                        )
                    )

                    on retainAllTextFromFileNameCheckBox changed state do(
                        if retainAllTextFromFileNameCheckBox.checked == true then(
                            -- Variables

                                -- Change variable

                                    if currentVolumeDropDownListSelectionInteger == 1 then(
                                        retainAllTextFromFileNameBoolean1 = true
                                        ReplaceAllTextBoolean1 = false
                                        retainSpecifiedTextFromFileNameBoolean1 = false
                                        retainSpecifiedTextFromObjectNameBoolean1 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 2 then(
                                        retainAllTextFromFileNameBoolean2 = true
                                        ReplaceAllTextBoolean2 = false
                                        retainSpecifiedTextFromFileNameBoolean2 = false
                                        retainSpecifiedTextFromObjectNameBoolean2 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 3 then(
                                        retainAllTextFromFileNameBoolean3 = true
                                        ReplaceAllTextBoolean3 = false
                                        retainSpecifiedTextFromFileNameBoolean3 = false
                                        retainSpecifiedTextFromObjectNameBoolean3 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 4 then(
                                        retainAllTextFromFileNameBoolean4 = true
                                        ReplaceAllTextBoolean4 = false
                                        retainSpecifiedTextFromFileNameBoolean4 = false
                                        retainSpecifiedTextFromObjectNameBoolean4 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 5 then(
                                        retainAllTextFromFileNameBoolean5 = true
                                        ReplaceAllTextBoolean5 = false
                                        retainSpecifiedTextFromFileNameBoolean5 = false
                                        retainSpecifiedTextFromObjectNameBoolean5 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 6 then(
                                        retainAllTextFromFileNameBoolean6 = true
                                        ReplaceAllTextBoolean6 = false
                                        retainSpecifiedTextFromFileNameBoolean6 = false
                                        retainSpecifiedTextFromObjectNameBoolean6 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 7 then(
                                        retainAllTextFromFileNameBoolean7 = true
                                        ReplaceAllTextBoolean7 = false
                                        retainSpecifiedTextFromFileNameBoolean7 = false
                                        retainSpecifiedTextFromObjectNameBoolean7 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 8 then(
                                        retainAllTextFromFileNameBoolean8 = true
                                        ReplaceAllTextBoolean8 = false
                                        retainSpecifiedTextFromFileNameBoolean8 = false
                                        retainSpecifiedTextFromObjectNameBoolean8 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 9 then(
                                        retainAllTextFromFileNameBoolean9 = true
                                        ReplaceAllTextBoolean9 = false
                                        retainSpecifiedTextFromFileNameBoolean9 = false
                                        retainSpecifiedTextFromObjectNameBoolean9 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 10 then(
                                        retainAllTextFromFileNameBoolean10 = true
                                        ReplaceAllTextBoolean10 = false
                                        retainSpecifiedTextFromFileNameBoolean10 = false
                                        retainSpecifiedTextFromObjectNameBoolean10 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 11 then(
                                        retainAllTextFromFileNameBoolean11 = true
                                        ReplaceAllTextBoolean11 = false
                                        retainSpecifiedTextFromFileNameBoolean11 = false
                                        retainSpecifiedTextFromObjectNameBoolean11 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 12 then(
                                        retainAllTextFromFileNameBoolean12 = true
                                        ReplaceAllTextBoolean12 = false
                                        retainSpecifiedTextFromFileNameBoolean12 = false
                                        retainSpecifiedTextFromObjectNameBoolean12 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 13 then(
                                        retainAllTextFromFileNameBoolean13 = true
                                        ReplaceAllTextBoolean13 = false
                                        retainSpecifiedTextFromFileNameBoolean13 = false
                                        retainSpecifiedTextFromObjectNameBoolean13 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 14 then(
                                        retainAllTextFromFileNameBoolean14 = true
                                        ReplaceAllTextBoolean14 = false
                                        retainSpecifiedTextFromFileNameBoolean14 = false
                                        retainSpecifiedTextFromObjectNameBoolean14 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 15 then(
                                        retainAllTextFromFileNameBoolean15 = true
                                        ReplaceAllTextBoolean15 = false
                                        retainSpecifiedTextFromFileNameBoolean15 = false
                                        retainSpecifiedTextFromObjectNameBoolean15 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 16 then(
                                        retainAllTextFromFileNameBoolean16 = true
                                        ReplaceAllTextBoolean16 = false
                                        retainSpecifiedTextFromFileNameBoolean16 = false
                                        retainSpecifiedTextFromObjectNameBoolean16 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 17 then(
                                        retainAllTextFromFileNameBoolean17 = true
                                        ReplaceAllTextBoolean17 = false
                                        retainSpecifiedTextFromFileNameBoolean17 = false
                                        retainSpecifiedTextFromObjectNameBoolean17 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 18 then(
                                        retainAllTextFromFileNameBoolean18 = true
                                        ReplaceAllTextBoolean18 = false
                                        retainSpecifiedTextFromFileNameBoolean18 = false
                                        retainSpecifiedTextFromObjectNameBoolean18 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 19 then(
                                        retainAllTextFromFileNameBoolean19 = true
                                        ReplaceAllTextBoolean19 = false
                                        retainSpecifiedTextFromFileNameBoolean19 = false
                                        retainSpecifiedTextFromObjectNameBoolean19 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 20 then(
                                        retainAllTextFromFileNameBoolean20 = true
                                        ReplaceAllTextBoolean20 = false
                                        retainSpecifiedTextFromFileNameBoolean20 = false
                                        retainSpecifiedTextFromObjectNameBoolean20 = false
                                    )

                                -- Change variable

                                    if currentVolumeDropDownListSelectionInteger == 1 then(
                                        phraseToSplitWithEditTextEnabled1 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled1 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled1 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 2 then(
                                        phraseToSplitWithEditTextEnabled2 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled2 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled2 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 3 then(
                                        phraseToSplitWithEditTextEnabled3 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled3 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled3 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 4 then(
                                        phraseToSplitWithEditTextEnabled4 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled4 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled4 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 5 then(
                                        phraseToSplitWithEditTextEnabled5 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled5 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled5 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 6 then(
                                        phraseToSplitWithEditTextEnabled6 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled6 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled6 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 7 then(
                                        phraseToSplitWithEditTextEnabled7 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled7 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled7 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 8 then(
                                        phraseToSplitWithEditTextEnabled8 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled8 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled8 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 9 then(
                                        phraseToSplitWithEditTextEnabled9 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled9 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled9 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 10 then(
                                        phraseToSplitWithEditTextEnabled10 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled10 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled10 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 11 then(
                                        phraseToSplitWithEditTextEnabled11 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled11 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled11 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 12 then(
                                        phraseToSplitWithEditTextEnabled12 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled12 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled12 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 13 then(
                                        phraseToSplitWithEditTextEnabled13 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled13 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled13 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 14 then(
                                        phraseToSplitWithEditTextEnabled14 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled14 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled14 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 15 then(
                                        phraseToSplitWithEditTextEnabled15 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled15 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled15 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 16 then(
                                        phraseToSplitWithEditTextEnabled16 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled16 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled16 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 17 then(
                                        phraseToSplitWithEditTextEnabled17 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled17 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled17 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 18 then(
                                        phraseToSplitWithEditTextEnabled18 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled18 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled18 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 19 then(
                                        phraseToSplitWithEditTextEnabled19 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled19 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled19 = false
                                    )

                                    if currentVolumeDropDownListSelectionInteger == 20 then(
                                        phraseToSplitWithEditTextEnabled20 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled20 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled20 = false
                                    )

                            -- Other components

                                -- Checking

                                    replaceAllTextCheckBox.checked = false

                                    retainSpecifiedTextFromFileNameCheckBox.checked = false

                                    retainSpecifiedTextFromObjectNameCheckBox.checked = false

                                -- Enabling/disabling

                                    phraseToSplitWithEditText.enabled = false

                                    numberOfIndicesToRemoveFromStartSpinner.enabled = false

                                    numberOfIndicesToRemoveFromEndSpinner.enabled = false
                        )else(
                            retainAllTextFromFileNameCheckBox.checked = true
                        )
                    )

                -- File naming continued

                    on phraseToSplitWithEditText entered txt do(
                        if txt != "" then(
                            -- Change variable

                                if currentVolumeDropDownListSelectionInteger == 1 then(
                                    phraseToSplitWithString1 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 2 then(
                                    phraseToSplitWithString2 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 3 then(
                                    phraseToSplitWithString3 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 4 then(
                                    phraseToSplitWithString4 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 5 then(
                                    phraseToSplitWithString5 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 6 then(
                                    phraseToSplitWithString6 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 7 then(
                                    phraseToSplitWithString7 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 8 then(
                                    phraseToSplitWithString8 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 9 then(
                                    phraseToSplitWithString9 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 10 then(
                                    phraseToSplitWithString10 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 11 then(
                                    phraseToSplitWithString11 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 12 then(
                                    phraseToSplitWithString12 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 13 then(
                                    phraseToSplitWithString13 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 14 then(
                                    phraseToSplitWithString14 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 15 then(
                                    phraseToSplitWithString15 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 16 then(
                                    phraseToSplitWithString16 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 17 then(
                                    phraseToSplitWithString17 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 18 then(
                                    phraseToSplitWithString18 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 19 then(
                                    phraseToSplitWithString19 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 20 then(
                                    phraseToSplitWithString20 = txt
                                )
                        )else(
                            -- Change variable

                                if currentVolumeDropDownListSelectionInteger == 1 then(
                                    phraseToSplitWithString1 = ""
                                )

                                if currentVolumeDropDownListSelectionInteger == 2 then(
                                    phraseToSplitWithString2 = ""
                                )

                                if currentVolumeDropDownListSelectionInteger == 3 then(
                                    phraseToSplitWithString3 = ""
                                )

                                if currentVolumeDropDownListSelectionInteger == 4 then(
                                    phraseToSplitWithString4 = ""
                                )

                                if currentVolumeDropDownListSelectionInteger == 5 then(
                                    phraseToSplitWithString5 = ""
                                )

                                if currentVolumeDropDownListSelectionInteger == 6 then(
                                    phraseToSplitWithString6 = ""
                                )

                                if currentVolumeDropDownListSelectionInteger == 7 then(
                                    phraseToSplitWithString7 = ""
                                )

                                if currentVolumeDropDownListSelectionInteger == 8 then(
                                    phraseToSplitWithString8 = ""
                                )

                                if currentVolumeDropDownListSelectionInteger == 9 then(
                                    phraseToSplitWithString9 = ""
                                )

                                if currentVolumeDropDownListSelectionInteger == 10 then(
                                    phraseToSplitWithString10 = ""
                                )

                                if currentVolumeDropDownListSelectionInteger == 11 then(
                                    phraseToSplitWithString11 = ""
                                )

                                if currentVolumeDropDownListSelectionInteger == 12 then(
                                    phraseToSplitWithString12 = ""
                                )

                                if currentVolumeDropDownListSelectionInteger == 13 then(
                                    phraseToSplitWithString13 = ""
                                )

                                if currentVolumeDropDownListSelectionInteger == 14 then(
                                    phraseToSplitWithString14 = ""
                                )

                                if currentVolumeDropDownListSelectionInteger == 15 then(
                                    phraseToSplitWithString15 = ""
                                )

                                if currentVolumeDropDownListSelectionInteger == 16 then(
                                    phraseToSplitWithString16 = ""
                                )

                                if currentVolumeDropDownListSelectionInteger == 17 then(
                                    phraseToSplitWithString17 = ""
                                )

                                if currentVolumeDropDownListSelectionInteger == 18 then(
                                    phraseToSplitWithString18 = ""
                                )

                                if currentVolumeDropDownListSelectionInteger == 19 then(
                                    phraseToSplitWithString19 = ""
                                )

                                if currentVolumeDropDownListSelectionInteger == 20 then(
                                    phraseToSplitWithString20 = ""
                                )
                        )
                    )

                    on numberOfIndicesToRemoveFromStartSpinner changed int do(
                        -- Change variable

                            if currentVolumeDropDownListSelectionInteger == 1 then(
                                numberOfIndicesToRemoveFromStartInteger1 = int
                            )

                            if currentVolumeDropDownListSelectionInteger == 2 then(
                                numberOfIndicesToRemoveFromStartInteger2 = int
                            )

                            if currentVolumeDropDownListSelectionInteger == 3 then(
                                numberOfIndicesToRemoveFromStartInteger3 = int
                            )

                            if currentVolumeDropDownListSelectionInteger == 4 then(
                                numberOfIndicesToRemoveFromStartInteger4 = int
                            )

                            if currentVolumeDropDownListSelectionInteger == 5 then(
                                numberOfIndicesToRemoveFromStartInteger5 = int
                            )

                            if currentVolumeDropDownListSelectionInteger == 6 then(
                                numberOfIndicesToRemoveFromStartInteger6 = int
                            )

                            if currentVolumeDropDownListSelectionInteger == 7 then(
                                numberOfIndicesToRemoveFromStartInteger7 = int
                            )

                            if currentVolumeDropDownListSelectionInteger == 8 then(
                                numberOfIndicesToRemoveFromStartInteger8 = int
                            )

                            if currentVolumeDropDownListSelectionInteger == 9 then(
                                numberOfIndicesToRemoveFromStartInteger9 = int
                            )

                            if currentVolumeDropDownListSelectionInteger == 10 then(
                                numberOfIndicesToRemoveFromStartInteger10 = int
                            )

                            if currentVolumeDropDownListSelectionInteger == 11 then(
                                numberOfIndicesToRemoveFromStartInteger11 = int
                            )

                            if currentVolumeDropDownListSelectionInteger == 12 then(
                                numberOfIndicesToRemoveFromStartInteger12 = int
                            )

                            if currentVolumeDropDownListSelectionInteger == 13 then(
                                numberOfIndicesToRemoveFromStartInteger13 = int
                            )

                            if currentVolumeDropDownListSelectionInteger == 14 then(
                                numberOfIndicesToRemoveFromStartInteger14 = int
                            )

                            if currentVolumeDropDownListSelectionInteger == 15 then(
                                numberOfIndicesToRemoveFromStartInteger15 = int
                            )

                            if currentVolumeDropDownListSelectionInteger == 16 then(
                                numberOfIndicesToRemoveFromStartInteger16 = int
                            )

                            if currentVolumeDropDownListSelectionInteger == 17 then(
                                numberOfIndicesToRemoveFromStartInteger17 = int
                            )

                            if currentVolumeDropDownListSelectionInteger == 18 then(
                                numberOfIndicesToRemoveFromStartInteger18 = int
                            )

                            if currentVolumeDropDownListSelectionInteger == 19 then(
                                numberOfIndicesToRemoveFromStartInteger19 = int
                            )

                            if currentVolumeDropDownListSelectionInteger == 20 then(
                                numberOfIndicesToRemoveFromStartInteger20 = int
                            )
                    )

                    on numberOfIndicesToRemoveFromEndSpinner changed int do(
                        -- Change variable

                            if currentVolumeDropDownListSelectionInteger == 1 then(
                                numberOfIndicesToRemoveFromEndInteger1 = int
                            )

                            if currentVolumeDropDownListSelectionInteger == 2 then(
                                numberOfIndicesToRemoveFromEndInteger2 = int
                            )

                            if currentVolumeDropDownListSelectionInteger == 3 then(
                                numberOfIndicesToRemoveFromEndInteger3 = int
                            )

                            if currentVolumeDropDownListSelectionInteger == 4 then(
                                numberOfIndicesToRemoveFromEndInteger4 = int
                            )

                            if currentVolumeDropDownListSelectionInteger == 5 then(
                                numberOfIndicesToRemoveFromEndInteger5 = int
                            )

                            if currentVolumeDropDownListSelectionInteger == 6 then(
                                numberOfIndicesToRemoveFromEndInteger6 = int
                            )

                            if currentVolumeDropDownListSelectionInteger == 7 then(
                                numberOfIndicesToRemoveFromEndInteger7 = int
                            )

                            if currentVolumeDropDownListSelectionInteger == 8 then(
                                numberOfIndicesToRemoveFromEndInteger8 = int
                            )

                            if currentVolumeDropDownListSelectionInteger == 9 then(
                                numberOfIndicesToRemoveFromEndInteger9 = int
                            )

                            if currentVolumeDropDownListSelectionInteger == 10 then(
                                numberOfIndicesToRemoveFromEndInteger10 = int
                            )

                            if currentVolumeDropDownListSelectionInteger == 11 then(
                                numberOfIndicesToRemoveFromEndInteger11 = int
                            )

                            if currentVolumeDropDownListSelectionInteger == 12 then(
                                numberOfIndicesToRemoveFromEndInteger12 = int
                            )

                            if currentVolumeDropDownListSelectionInteger == 13 then(
                                numberOfIndicesToRemoveFromEndInteger13 = int
                            )

                            if currentVolumeDropDownListSelectionInteger == 14 then(
                                numberOfIndicesToRemoveFromEndInteger14 = int
                            )

                            if currentVolumeDropDownListSelectionInteger == 15 then(
                                numberOfIndicesToRemoveFromEndInteger15 = int
                            )

                            if currentVolumeDropDownListSelectionInteger == 16 then(
                                numberOfIndicesToRemoveFromEndInteger16 = int
                            )

                            if currentVolumeDropDownListSelectionInteger == 17 then(
                                numberOfIndicesToRemoveFromEndInteger17 = int
                            )

                            if currentVolumeDropDownListSelectionInteger == 18 then(
                                numberOfIndicesToRemoveFromEndInteger18 = int
                            )

                            if currentVolumeDropDownListSelectionInteger == 19 then(
                                numberOfIndicesToRemoveFromEndInteger19 = int
                            )

                            if currentVolumeDropDownListSelectionInteger == 20 then(
                                numberOfIndicesToRemoveFromEndInteger20 = int
                            )
                    )

                -- Layering

                    on layerToMoveObjectsIntoEditText entered txt do(
                        if txt != "" then(
                            -- Change variable

                                if currentVolumeDropDownListSelectionInteger == 1 then(
                                    layerToMoveObjectsToString1 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 2 then(
                                    layerToMoveObjectsToString2 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 3 then(
                                    layerToMoveObjectsToString3 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 4 then(
                                    layerToMoveObjectsToString4 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 5 then(
                                    layerToMoveObjectsToString5 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 6 then(
                                    layerToMoveObjectsToString6 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 7 then(
                                    layerToMoveObjectsToString7 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 8 then(
                                    layerToMoveObjectsToString8 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 9 then(
                                    layerToMoveObjectsToString9 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 10 then(
                                    layerToMoveObjectsToString10 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 11 then(
                                    layerToMoveObjectsToString11 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 12 then(
                                    layerToMoveObjectsToString12 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 13 then(
                                    layerToMoveObjectsToString13 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 14 then(
                                    layerToMoveObjectsToString14 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 15 then(
                                    layerToMoveObjectsToString15 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 16 then(
                                    layerToMoveObjectsToString16 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 17 then(
                                    layerToMoveObjectsToString17 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 18 then(
                                    layerToMoveObjectsToString18 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 19 then(
                                    layerToMoveObjectsToString19 = txt
                                )

                                if currentVolumeDropDownListSelectionInteger == 20 then(
                                    layerToMoveObjectsToString20 = txt
                                )
                        )else(
                            -- Change variable

                                if currentVolumeDropDownListSelectionInteger == 1 then(
                                    layerToMoveObjectsToString1 = ""
                                )

                                if currentVolumeDropDownListSelectionInteger == 2 then(
                                    layerToMoveObjectsToString2 = ""
                                )

                                if currentVolumeDropDownListSelectionInteger == 3 then(
                                    layerToMoveObjectsToString3 = ""
                                )

                                if currentVolumeDropDownListSelectionInteger == 4 then(
                                    layerToMoveObjectsToString4 = ""
                                )

                                if currentVolumeDropDownListSelectionInteger == 5 then(
                                    layerToMoveObjectsToString5 = ""
                                )

                                if currentVolumeDropDownListSelectionInteger == 6 then(
                                    layerToMoveObjectsToString6 = ""
                                )

                                if currentVolumeDropDownListSelectionInteger == 7 then(
                                    layerToMoveObjectsToString7 = ""
                                )

                                if currentVolumeDropDownListSelectionInteger == 8 then(
                                    layerToMoveObjectsToString8 = ""
                                )

                                if currentVolumeDropDownListSelectionInteger == 9 then(
                                    layerToMoveObjectsToString9 = ""
                                )

                                if currentVolumeDropDownListSelectionInteger == 10 then(
                                    layerToMoveObjectsToString10 = ""
                                )

                                if currentVolumeDropDownListSelectionInteger == 11 then(
                                    layerToMoveObjectsToString11 = ""
                                )

                                if currentVolumeDropDownListSelectionInteger == 12 then(
                                    layerToMoveObjectsToString12 = ""
                                )

                                if currentVolumeDropDownListSelectionInteger == 13 then(
                                    layerToMoveObjectsToString13 = ""
                                )

                                if currentVolumeDropDownListSelectionInteger == 14 then(
                                    layerToMoveObjectsToString14 = ""
                                )

                                if currentVolumeDropDownListSelectionInteger == 15 then(
                                    layerToMoveObjectsToString15 = ""
                                )

                                if currentVolumeDropDownListSelectionInteger == 16 then(
                                    layerToMoveObjectsToString16 = ""
                                )

                                if currentVolumeDropDownListSelectionInteger == 17 then(
                                    layerToMoveObjectsToString17 = ""
                                )

                                if currentVolumeDropDownListSelectionInteger == 18 then(
                                    layerToMoveObjectsToString18 = ""
                                )

                                if currentVolumeDropDownListSelectionInteger == 19 then(
                                    layerToMoveObjectsToString19 = ""
                                )

                                if currentVolumeDropDownListSelectionInteger == 20 then(
                                    layerToMoveObjectsToString20 = ""
                                )
                        )
                    )

                -- Maps

                    on relinkMapsCheckBox changed state do(
                        if state == true then(
                            -- Change variable

                                if currentVolumeDropDownListSelectionInteger == 1 then(
                                    relinkMapsBoolean1 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 2 then(
                                    relinkMapsBoolean2 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 3 then(
                                    relinkMapsBoolean3 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 4 then(
                                    relinkMapsBoolean4 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 5 then(
                                    relinkMapsBoolean5 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 6 then(
                                    relinkMapsBoolean6 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 7 then(
                                    relinkMapsBoolean7 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 8 then(
                                    relinkMapsBoolean8 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 9 then(
                                    relinkMapsBoolean9 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 10 then(
                                    relinkMapsBoolean10 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 11 then(
                                    relinkMapsBoolean11 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 12 then(
                                    relinkMapsBoolean12 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 13 then(
                                    relinkMapsBoolean13 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 14 then(
                                    relinkMapsBoolean14 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 15 then(
                                    relinkMapsBoolean15 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 16 then(
                                    relinkMapsBoolean16 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 17 then(
                                    relinkMapsBoolean17 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 18 then(
                                    relinkMapsBoolean18 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 19 then(
                                    relinkMapsBoolean19 = true
                                )

                                if currentVolumeDropDownListSelectionInteger == 20 then(
                                    relinkMapsBoolean20 = true
                                )
                        )else(
                            -- Change variable

                                if currentVolumeDropDownListSelectionInteger == 1 then(
                                    relinkMapsBoolean1 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 2 then(
                                    relinkMapsBoolean2 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 3 then(
                                    relinkMapsBoolean3 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 4 then(
                                    relinkMapsBoolean4 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 5 then(
                                    relinkMapsBoolean5 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 6 then(
                                    relinkMapsBoolean6 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 7 then(
                                    relinkMapsBoolean7 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 8 then(
                                    relinkMapsBoolean8 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 9 then(
                                    relinkMapsBoolean9 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 10 then(
                                    relinkMapsBoolean10 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 11 then(
                                    relinkMapsBoolean11 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 12 then(
                                    relinkMapsBoolean12 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 13 then(
                                    relinkMapsBoolean13 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 14 then(
                                    relinkMapsBoolean14 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 15 then(
                                    relinkMapsBoolean15 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 16 then(
                                    relinkMapsBoolean16 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 17 then(
                                    relinkMapsBoolean17 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 18 then(
                                    relinkMapsBoolean18 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 19 then(
                                    relinkMapsBoolean19 = false
                                )

                                if currentVolumeDropDownListSelectionInteger == 20 then(
                                    relinkMapsBoolean20 = false
                                )
                        )
                    )

            -- Execution

                on processButton pressed do(
                    if originalFolderPathText != undefined and destinationFolderText != undefined then(
                        --if (retainSpecifiedTextFromFileNameBoolean == false and retainSpecifiedTextFromObjectNameBoolean == false) or phraseToSplitWithString.count == 1 then(
                            --if not matchpattern volumeNameSuffixString Pattern:"*,*" and not matchpattern fileNameExtraTextString Pattern:"*,*" and not matchpattern keywordFilterString Pattern:"*,*" then(
                                -- Create arrays

                                    useOriginalVolumeNameAsSuffixBooleanArray = #(useOriginalVolumeNameAsSuffixBoolean1, useOriginalVolumeNameAsSuffixBoolean2, useOriginalVolumeNameAsSuffixBoolean3, useOriginalVolumeNameAsSuffixBoolean4, useOriginalVolumeNameAsSuffixBoolean5, useOriginalVolumeNameAsSuffixBoolean6, useOriginalVolumeNameAsSuffixBoolean7, useOriginalVolumeNameAsSuffixBoolean8, useOriginalVolumeNameAsSuffixBoolean9, useOriginalVolumeNameAsSuffixBoolean10, useOriginalVolumeNameAsSuffixBoolean11, useOriginalVolumeNameAsSuffixBoolean12, useOriginalVolumeNameAsSuffixBoolean13, useOriginalVolumeNameAsSuffixBoolean14, useOriginalVolumeNameAsSuffixBoolean15, useOriginalVolumeNameAsSuffixBoolean16, useOriginalVolumeNameAsSuffixBoolean17, useOriginalVolumeNameAsSuffixBoolean18, useOriginalVolumeNameAsSuffixBoolean19, useOriginalVolumeNameAsSuffixBoolean20)

                                    volumeNameSuffixStringArray = #(volumeNameSuffixString1, volumeNameSuffixString2, volumeNameSuffixString3, volumeNameSuffixString4, volumeNameSuffixString5, volumeNameSuffixString6, volumeNameSuffixString7, volumeNameSuffixString8, volumeNameSuffixString9, volumeNameSuffixString10, volumeNameSuffixString11, volumeNameSuffixString12, volumeNameSuffixString13, volumeNameSuffixString14, volumeNameSuffixString15, volumeNameSuffixString16, volumeNameSuffixString17, volumeNameSuffixString18, volumeNameSuffixString19, volumeNameSuffixString20)

                                    fileNameExtraTextStringArray = #(fileNameExtraTextString1, fileNameExtraTextString2, fileNameExtraTextString3, fileNameExtraTextString4, fileNameExtraTextString5, fileNameExtraTextString6, fileNameExtraTextString7, fileNameExtraTextString8, fileNameExtraTextString9, fileNameExtraTextString10, fileNameExtraTextString11, fileNameExtraTextString12, fileNameExtraTextString13, fileNameExtraTextString14, fileNameExtraTextString15, fileNameExtraTextString16, fileNameExtraTextString17, fileNameExtraTextString18, fileNameExtraTextString19, fileNameExtraTextString20)

                                    keywordFilterStringArray = #(keywordFilterString1, keywordFilterString2, keywordFilterString3, keywordFilterString4, keywordFilterString5, keywordFilterString6, keywordFilterString7, keywordFilterString8, keywordFilterString9, keywordFilterString10, keywordFilterString11, keywordFilterString12, keywordFilterString13, keywordFilterString14, keywordFilterString15, keywordFilterString16, keywordFilterString17, keywordFilterString18, keywordFilterString19, keywordFilterString20)

                                    convertSceneToVrayOrCoronaBooleanArray = #(convertSceneToVrayOrCoronaBoolean1, convertSceneToVrayOrCoronaBoolean2, convertSceneToVrayOrCoronaBoolean3, convertSceneToVrayOrCoronaBoolean4, convertSceneToVrayOrCoronaBoolean5, convertSceneToVrayOrCoronaBoolean6, convertSceneToVrayOrCoronaBoolean7, convertSceneToVrayOrCoronaBoolean8, convertSceneToVrayOrCoronaBoolean9, convertSceneToVrayOrCoronaBoolean10, convertSceneToVrayOrCoronaBoolean11, convertSceneToVrayOrCoronaBoolean12, convertSceneToVrayOrCoronaBoolean13, convertSceneToVrayOrCoronaBoolean14, convertSceneToVrayOrCoronaBoolean15, convertSceneToVrayOrCoronaBoolean16, convertSceneToVrayOrCoronaBoolean17, convertSceneToVrayOrCoronaBoolean18, convertSceneToVrayOrCoronaBoolean19, convertSceneToVrayOrCoronaBoolean20)

                                    saveEachObjectSeparatelyBooleanArray = #(saveEachObjectSeparatelyBoolean1, saveEachObjectSeparatelyBoolean2, saveEachObjectSeparatelyBoolean3, saveEachObjectSeparatelyBoolean4, saveEachObjectSeparatelyBoolean5, saveEachObjectSeparatelyBoolean6, saveEachObjectSeparatelyBoolean7, saveEachObjectSeparatelyBoolean8, saveEachObjectSeparatelyBoolean9, saveEachObjectSeparatelyBoolean10, saveEachObjectSeparatelyBoolean11, saveEachObjectSeparatelyBoolean12, saveEachObjectSeparatelyBoolean13, saveEachObjectSeparatelyBoolean14, saveEachObjectSeparatelyBoolean15, saveEachObjectSeparatelyBoolean16, saveEachObjectSeparatelyBoolean17, saveEachObjectSeparatelyBoolean18, saveEachObjectSeparatelyBoolean19, saveEachObjectSeparatelyBoolean20)

                                    attachObjectsBooleanArray = #(attachObjectsBoolean1, attachObjectsBoolean2, attachObjectsBoolean3, attachObjectsBoolean4, attachObjectsBoolean5, attachObjectsBoolean6, attachObjectsBoolean7, attachObjectsBoolean8, attachObjectsBoolean9, attachObjectsBoolean10, attachObjectsBoolean11, attachObjectsBoolean12, attachObjectsBoolean13, attachObjectsBoolean14, attachObjectsBoolean15, attachObjectsBoolean16, attachObjectsBoolean17, attachObjectsBoolean18, attachObjectsBoolean19, attachObjectsBoolean20)

                                    proxyObjectsBooleanArray = #(proxyObjectsBoolean1, proxyObjectsBoolean2, proxyObjectsBoolean3, proxyObjectsBoolean4, proxyObjectsBoolean5, proxyObjectsBoolean6, proxyObjectsBoolean7, proxyObjectsBoolean8, proxyObjectsBoolean9, proxyObjectsBoolean10, proxyObjectsBoolean11, proxyObjectsBoolean12, proxyObjectsBoolean13, proxyObjectsBoolean14, proxyObjectsBoolean15, proxyObjectsBoolean16, proxyObjectsBoolean17, proxyObjectsBoolean18, proxyObjectsBoolean19, proxyObjectsBoolean20)

                                    facesNumberIntegerArray = #(facesNumberInteger1, facesNumberInteger2, facesNumberInteger3, facesNumberInteger4, facesNumberInteger5, facesNumberInteger6, facesNumberInteger7, facesNumberInteger8, facesNumberInteger9, facesNumberInteger10, facesNumberInteger11, facesNumberInteger12, facesNumberInteger13, facesNumberInteger14, facesNumberInteger15, facesNumberInteger16, facesNumberInteger17, facesNumberInteger18, facesNumberInteger19, facesNumberInteger20)

                                    coronaBooleanArray = #(coronaBoolean1, coronaBoolean2, coronaBoolean3, coronaBoolean4, coronaBoolean5, coronaBoolean6, coronaBoolean7, coronaBoolean8, coronaBoolean9, coronaBoolean10, coronaBoolean11, coronaBoolean12, coronaBoolean13, coronaBoolean14, coronaBoolean15, coronaBoolean16, coronaBoolean17, coronaBoolean18, coronaBoolean19, coronaBoolean20)

                                    includeCamerasBooleanArray = #(includeCamerasBoolean1, includeCamerasBoolean2, includeCamerasBoolean3, includeCamerasBoolean4, includeCamerasBoolean5, includeCamerasBoolean6, includeCamerasBoolean7, includeCamerasBoolean8, includeCamerasBoolean9, includeCamerasBoolean10, includeCamerasBoolean11, includeCamerasBoolean12, includeCamerasBoolean13, includeCamerasBoolean14, includeCamerasBoolean15, includeCamerasBoolean16, includeCamerasBoolean17, includeCamerasBoolean18, includeCamerasBoolean19, includeCamerasBoolean20)

                                    includeLightsBooleanArray = #(includeLightsBoolean1, includeLightsBoolean2, includeLightsBoolean3, includeLightsBoolean4, includeLightsBoolean5, includeLightsBoolean6, includeLightsBoolean7, includeLightsBoolean8, includeLightsBoolean9, includeLightsBoolean10, includeLightsBoolean11, includeLightsBoolean12, includeLightsBoolean13, includeLightsBoolean14, includeLightsBoolean15, includeLightsBoolean16, includeLightsBoolean17, includeLightsBoolean18, includeLightsBoolean19, includeLightsBoolean20)

                                    replaceAllTextBooleanArray = #(replaceAllTextBoolean1, replaceAllTextBoolean2, replaceAllTextBoolean3, replaceAllTextBoolean4, replaceAllTextBoolean5, replaceAllTextBoolean6, replaceAllTextBoolean7, replaceAllTextBoolean8, replaceAllTextBoolean9, replaceAllTextBoolean10, replaceAllTextBoolean11, replaceAllTextBoolean12, replaceAllTextBoolean13, replaceAllTextBoolean14, replaceAllTextBoolean15, replaceAllTextBoolean16, replaceAllTextBoolean17, replaceAllTextBoolean18, replaceAllTextBoolean19, replaceAllTextBoolean20)

                                    retainSpecifiedTextFromFileNameBooleanArray = #(retainSpecifiedTextFromFileNameBoolean1, retainSpecifiedTextFromFileNameBoolean2, retainSpecifiedTextFromFileNameBoolean3, retainSpecifiedTextFromFileNameBoolean4, retainSpecifiedTextFromFileNameBoolean5, retainSpecifiedTextFromFileNameBoolean6, retainSpecifiedTextFromFileNameBoolean7, retainSpecifiedTextFromFileNameBoolean8, retainSpecifiedTextFromFileNameBoolean9, retainSpecifiedTextFromFileNameBoolean10, retainSpecifiedTextFromFileNameBoolean11, retainSpecifiedTextFromFileNameBoolean12, retainSpecifiedTextFromFileNameBoolean13, retainSpecifiedTextFromFileNameBoolean14, retainSpecifiedTextFromFileNameBoolean15, retainSpecifiedTextFromFileNameBoolean16, retainSpecifiedTextFromFileNameBoolean17, retainSpecifiedTextFromFileNameBoolean18, retainSpecifiedTextFromFileNameBoolean19, retainSpecifiedTextFromFileNameBoolean20)

                                    retainSpecifiedTextFromObjectNameBooleanArray = #(retainSpecifiedTextFromObjectNameBoolean1, retainSpecifiedTextFromObjectNameBoolean2, retainSpecifiedTextFromObjectNameBoolean3, retainSpecifiedTextFromObjectNameBoolean4, retainSpecifiedTextFromObjectNameBoolean5, retainSpecifiedTextFromObjectNameBoolean6, retainSpecifiedTextFromObjectNameBoolean7, retainSpecifiedTextFromObjectNameBoolean8, retainSpecifiedTextFromObjectNameBoolean9, retainSpecifiedTextFromObjectNameBoolean10, retainSpecifiedTextFromObjectNameBoolean11, retainSpecifiedTextFromObjectNameBoolean12, retainSpecifiedTextFromObjectNameBoolean13, retainSpecifiedTextFromObjectNameBoolean14, retainSpecifiedTextFromObjectNameBoolean15, retainSpecifiedTextFromObjectNameBoolean16, retainSpecifiedTextFromObjectNameBoolean17, retainSpecifiedTextFromObjectNameBoolean18, retainSpecifiedTextFromObjectNameBoolean19, retainSpecifiedTextFromObjectNameBoolean20)

                                    retainAllTextFromFileNameBooleanArray = #(retainAllTextFromFileNameBoolean1, retainAllTextFromFileNameBoolean2, retainAllTextFromFileNameBoolean3, retainAllTextFromFileNameBoolean4, retainAllTextFromFileNameBoolean5, retainAllTextFromFileNameBoolean6, retainAllTextFromFileNameBoolean7, retainAllTextFromFileNameBoolean8, retainAllTextFromFileNameBoolean9, retainAllTextFromFileNameBoolean10, retainAllTextFromFileNameBoolean11, retainAllTextFromFileNameBoolean12, retainAllTextFromFileNameBoolean13, retainAllTextFromFileNameBoolean14, retainAllTextFromFileNameBoolean15, retainAllTextFromFileNameBoolean16, retainAllTextFromFileNameBoolean17, retainAllTextFromFileNameBoolean18, retainAllTextFromFileNameBoolean19, retainAllTextFromFileNameBoolean20)

                                    phraseToSplitWithStringArray = #(phraseToSplitWithString1, phraseToSplitWithString2, phraseToSplitWithString3, phraseToSplitWithString4, phraseToSplitWithString5, phraseToSplitWithString6, phraseToSplitWithString7, phraseToSplitWithString8, phraseToSplitWithString9, phraseToSplitWithString10, phraseToSplitWithString11, phraseToSplitWithString12, phraseToSplitWithString13, phraseToSplitWithString14, phraseToSplitWithString15, phraseToSplitWithString16, phraseToSplitWithString17, phraseToSplitWithString18, phraseToSplitWithString19, phraseToSplitWithString20)

                                    numberOfIndicesToRemoveFromStartIntegerArray = #(numberOfIndicesToRemoveFromStartInteger1, numberOfIndicesToRemoveFromStartInteger2, numberOfIndicesToRemoveFromStartInteger3, numberOfIndicesToRemoveFromStartInteger4, numberOfIndicesToRemoveFromStartInteger5, numberOfIndicesToRemoveFromStartInteger6, numberOfIndicesToRemoveFromStartInteger7, numberOfIndicesToRemoveFromStartInteger8, numberOfIndicesToRemoveFromStartInteger9, numberOfIndicesToRemoveFromStartInteger10, numberOfIndicesToRemoveFromStartInteger11, numberOfIndicesToRemoveFromStartInteger12, numberOfIndicesToRemoveFromStartInteger13, numberOfIndicesToRemoveFromStartInteger14, numberOfIndicesToRemoveFromStartInteger15, numberOfIndicesToRemoveFromStartInteger16, numberOfIndicesToRemoveFromStartInteger17, numberOfIndicesToRemoveFromStartInteger18, numberOfIndicesToRemoveFromStartInteger19, numberOfIndicesToRemoveFromStartInteger20)

                                    numberOfIndicesToRemoveFromEndIntegerArray = #(numberOfIndicesToRemoveFromEndInteger1, numberOfIndicesToRemoveFromEndInteger2, numberOfIndicesToRemoveFromEndInteger3, numberOfIndicesToRemoveFromEndInteger4, numberOfIndicesToRemoveFromEndInteger5, numberOfIndicesToRemoveFromEndInteger6, numberOfIndicesToRemoveFromEndInteger7, numberOfIndicesToRemoveFromEndInteger8, numberOfIndicesToRemoveFromEndInteger9, numberOfIndicesToRemoveFromEndInteger10, numberOfIndicesToRemoveFromEndInteger11, numberOfIndicesToRemoveFromEndInteger12, numberOfIndicesToRemoveFromEndInteger13, numberOfIndicesToRemoveFromEndInteger14, numberOfIndicesToRemoveFromEndInteger15, numberOfIndicesToRemoveFromEndInteger16, numberOfIndicesToRemoveFromEndInteger17, numberOfIndicesToRemoveFromEndInteger18, numberOfIndicesToRemoveFromEndInteger19, numberOfIndicesToRemoveFromEndInteger20)

                                    layerToMoveObjectsToStringArray = #(layerToMoveObjectsToString1, layerToMoveObjectsToString2, layerToMoveObjectsToString3, layerToMoveObjectsToString4, layerToMoveObjectsToString5, layerToMoveObjectsToString6, layerToMoveObjectsToString7, layerToMoveObjectsToString8, layerToMoveObjectsToString9, layerToMoveObjectsToString10, layerToMoveObjectsToString11, layerToMoveObjectsToString12, layerToMoveObjectsToString13, layerToMoveObjectsToString14, layerToMoveObjectsToString15, layerToMoveObjectsToString16, layerToMoveObjectsToString17, layerToMoveObjectsToString18, layerToMoveObjectsToString19, layerToMoveObjectsToString20)

                                    relinkMapsBooleanArray = #(relinkMapsBoolean1, relinkMapsBoolean2, relinkMapsBoolean3, relinkMapsBoolean4, relinkMapsBoolean5, relinkMapsBoolean6, relinkMapsBoolean7, relinkMapsBoolean8, relinkMapsBoolean9, relinkMapsBoolean10, relinkMapsBoolean11, relinkMapsBoolean12, relinkMapsBoolean13, relinkMapsBoolean14, relinkMapsBoolean15, relinkMapsBoolean16, relinkMapsBoolean17, relinkMapsBoolean18, relinkMapsBoolean19, relinkMapsBoolean20)

                                -- Run the script

                                    destroyDialog callisScriptsProcessAssetsForConnecterRollout

                                    callisScriptsProcessAssetsForConnecterFunction originalFolderPathText destinationFolderText useOriginalVolumeNameAsSuffixBooleanArray volumeNameSuffixStringArray fileNameExtraTextStringArray keywordFilterStringArray convertSceneToVrayOrCoronaBooleanArray saveEachObjectSeparatelyBooleanArray attachObjectsBooleanArray proxyObjectsBooleanArray facesNumberIntegerArray coronaBooleanArray includeCamerasBooleanArray includeLightsBooleanArray replaceAllTextBooleanArray retainSpecifiedTextFromFileNameBooleanArray retainSpecifiedTextFromObjectNameBooleanArray retainAllTextFromFileNameBooleanArray phraseToSplitWithStringArray numberOfIndicesToRemoveFromStartIntegerArray numberOfIndicesToRemoveFromEndIntegerArray layerToMoveObjectsToStringArray relinkMapsBooleanArray
                            --)else(
                                --messageBox "Sorry - non-path text fields cannot contain commas. Please remove commas and try again"
                            --)
                        --)else(
                            --messageBox "Please type a single character into the 'Phrase to split with' field, or check a different file naming box"
                        --)
                    )
                )
    )

    createDialog callisScriptsProcessAssetsForConnecterRollout 550 980

-- Reenabling callbacks

    disableRelevantEventHandlersForCertainOperationsVariable.enableOnNodeAddedEventHandlers()
