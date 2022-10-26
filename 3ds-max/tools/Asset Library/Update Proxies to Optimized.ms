-- Variables

    global callisScriptsAssetOrganisationFailedObjects = #()

    global callisScriptsAssetOrganisationObjectsToDelete = #()

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
                objectAttacherDefaults()
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

            fn mergeAllFiles oldScenesPath volumeNumber proxiesPath volumeName catergoryName volumeNameSuffixString fileNameExtraTextString keywordFilterString includeCamerasBoolean includeLightsBoolean saveEachObjectSeparatelyBoolean attachObjectsBoolean proxyObjectsBoolean replaceAllTextBoolean retainSpecifiedTextFromFileNameBoolean retainSpecifiedTextFromObjectNameBoolean retainAllTextFromFileNameBoolean phraseToSplitWithString numberOfIndicesToRemoveFromStartInteger numberOfIndicesToRemoveFromEndInteger = (
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

                        -- Move objects into default layer

                                DefaultLayer = layermanager.getLayerFromName "0"

                                try(
                                    for a in selection do(
                                        DefaultLayer.addnode a
                                    )
                                )catch()

                        -- Open all groups

                            for g in helpers where isGroupHead g do(
                                select g

                                max group ungroup
                            )

                        DefaultLayer = layermanager.getLayerFromName "0"
                        DefaultLayerNodes = #()
                        DefaultLayer.nodes &DefaultLayerNodes

                        deselect selection

                        for a in DefaultLayerNodes do(
                            selectMore a
                        )

                        -- Move objects into temporary layer

                            try(
                                for a in selection do(
                                    (LayerManager.getLayerFromName "Callis Scripts Temporary Proxy Layer").addnode a
                                )
                            )catch()

                        -- Select everything in the temporary group

                            deselect selection

                            temporaryProxyLayer = layermanager.getLayerFromName "Callis Scripts Temporary Proxy Layer"
                            temporaryProxyLayerNodes = #()
                            temporaryProxyLayer.nodes &temporaryProxyLayerNodes

                            for a in temporaryProxyLayerNodes do(
                                selectmore a
                            )

                        -- Create groups to deal with

                            -- Activate temporary proxy layer

                                temporaryProxyLayer.current = true

                            group selection name:"Callis Scripts Subgroup 001"

                            -- Activate default layer

                                defaultLayer = layermanager.getLayerFromName "0"
                                defaultLayer.current = true

                        -- Select none

                            deselect selection

                        temporaryProxyLayer = layermanager.getLayerFromName "Callis Scripts Temporary Proxy Layer"
                        temporaryProxyLayerNodes = #()
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

                            -- Update all existing proxies

                                temporaryProxySublayer = layermanager.getLayerFromName "Callis Scripts Temporary Proxy Sublayer"
                                temporaryProxySublayer.nodes &temporaryProxySublayerNodes

                                for a in temporaryProxySublayerNodes where iskindof a vrayProxy do(
                                    a.display = 4

                                    myPath = a.fileName
                                    myPath2 = filterString myPath "."
                                    myPath3 = myPath2[1]

                                    select a

                                    importedMesh = vrayMeshImport a

                                    importedMesh.pos = a.pos

                                    importedMesh.mat = a.mat

                                    exportedProxy = vrayMeshExport meshFile:(myPath3 + ".vrmesh") autoCreateProxies:true exportMultiple:false maxPreviewFaces:30000 animation:off nodes:importedMesh oneVoxelPerMesh:true

                                    delete $

                                    select exportedProxy

                                    temporaryProxySublayer.addNode $

                                    $.display = 4
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

                            -- Delete everything

                                deselect selection

                                temporaryProxySublayerNodes = undefined
                                temporaryProxySublayer.nodes &temporaryProxySublayerNodes

                                for a in temporaryProxySublayerNodes do(
                                    selectmore a
                                )

                                delete selection

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

        fn callisScriptsProcessAssetsForConnecterFunction folderPathContainingOriginalFiles destinationFolderRoot useOriginalVolumeNameAsSuffixBooleanArray volumeNameSuffixStringArray fileNameExtraTextStringArray keywordFilterStringArray saveEachObjectSeparatelyBooleanArray attachObjectsBooleanArray proxyObjectsBooleanArray previewFacesNumberArray includeCamerasBooleanArray includeLightsBooleanArray replaceAllTextBooleanArray retainSpecifiedTextFromFileNameBooleanArray retainSpecifiedTextFromObjectNameBooleanArray retainAllTextFromFileNameBooleanArray phraseToSplitWithStringArray numberOfIndicesToRemoveFromStartIntegerArray numberOfIndicesToRemoveFromEndIntegerArray = (
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

                    --File

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

                    -- Variables

                        -- Isolating relevant array items

                          local useOriginalVolumeNameAsSuffixBoolean = useOriginalVolumeNameAsSuffixBooleanArray[currentInteger]
                          local volumeNameSuffixString = volumeNameSuffixStringArray[currentInteger]
                          local fileNameExtraTextString = fileNameExtraTextStringArray[currentInteger]
                          local keywordFilterString = keywordFilterStringArray[currentInteger]
                          local saveEachObjectSeparatelyBoolean = saveEachObjectSeparatelyBooleanArray[currentInteger]
                          local attachObjectsBoolean = attachObjectsBooleanArray[currentInteger]
                          local proxyObjectsBoolean = proxyObjectsBooleanArray[currentInteger]
                          local previewFacesNumber = previewFacesNumberArray[currentInteger]
                          local includeCamerasBoolean = includeCamerasBooleanArray[currentInteger]
                          local includeLightsBoolean = includeLightsBooleanArray[currentInteger]
                          local replaceAllTextBoolean = replaceAllTextBooleanArray[currentInteger]
                          local retainSpecifiedTextFromFileNameBoolean = retainSpecifiedTextFromFileNameBooleanArray[currentInteger]
                          local retainSpecifiedTextFromObjectNameBoolean = retainSpecifiedTextFromObjectNameBooleanArray[currentInteger]
                          local retainAllTextFromFileNameBoolean = retainAllTextFromFileNameBooleanArray[currentInteger]
                          local phraseToSplitWithString = phraseToSplitWithStringArray[currentInteger]
                          local numberOfIndicesToRemoveFromStartInteger = numberOfIndicesToRemoveFromStartIntegerArray[currentInteger]
                          local numberOfIndicesToRemoveFromEndInteger = numberOfIndicesToRemoveFromEndIntegerArray[currentInteger]

                        -- Everything else

                            local newScenesPath = destinationFolder + "\\Scenes"
                            local proxiesPath = destinationFolder + "\\Proxies"
                            local volumeName = (filterString destinationFolder "\\")[(filterString destinationFolder "\\").count]
                            local catergoryName = (filterString destinationFolder "\\")[(filterString destinationFolder "\\").count - 1]
                            local oldScenesPath = undefined
                            local oldIESPath = undefined
                            local oldProxiesPath = undefined
                            local previewFacesNumberAsInteger = (previewFacesNumber as integer)
                            local lastThreeCharOfObjNamePreliminary = undefined
                            local lastThreeCharOfObjName = undefined
                            local myPreviewFilePreliminary = undefined
                            local myPreviewFile = undefined
                            local myIESFiles = undefined
                            local myProxyFiles = undefined
                            local mySelection = undefined
                            local myMapFiles = undefined
                            local currentMapName = undefined
                            local currentMapType = undefined

                        -- Define old paths variables

                            for i in getDirectories (currentOriginalFolder + "/*") do(
                                endOfDirPreliminary = filterString (i as string) "\\"
                                endOfDir = endOfDirPreliminary[endOfDirPreliminary.count]

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

                        mergeAllFiles oldScenesPath volumeNumber proxiesPath volumeName catergoryName volumeNameSuffixString fileNameExtraTextString keywordFilterString includeCamerasBoolean includeLightsBoolean saveEachObjectSeparatelyBoolean attachObjectsBoolean proxyObjectsBoolean replaceAllTextBoolean retainSpecifiedTextFromFileNameBoolean retainSpecifiedTextFromObjectNameBoolean retainAllTextFromFileNameBoolean phraseToSplitWithString numberOfIndicesToRemoveFromStartInteger numberOfIndicesToRemoveFromEndInteger

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
                    local saveEachObjectSeparatelyBooleanArray = #()
                    local attachObjectsBooleanArray = #()
                    local proxyObjectsBooleanArray = #()
                    local facesNumberIntegerArray = #()
                    local includeCamerasBooleanArray = #()
                    local includeLightsBooleanArray = #()
                    local replaceAllTextBooleanArray = #()
                    local retainSpecifiedTextFromFileNameBooleanArray = #()
                    local retainSpecifiedTextFromObjectNameBooleanArray = #()
                    local retainAllTextFromFileNameBooleanArray = #()
                    local phraseToSplitWithStringArray = #()
                    local numberOfIndicesToRemoveFromStartIntegerArray = #()
                    local numberOfIndicesToRemoveFromEndIntegerArray = #()

                -- File Locations

                    local originalFolderPathText
                    local destinationFolderText

                -- Volume to configure

                    local listOfOriginalVolumeNames
                    local currentDropDownListSelectionInteger = 1
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

        -- Components

            -- Main

                group "File Locations"(
                    editText originalFolderEditText "Original Folder:" text:"" toolTip:"This is the parent folder containing all original volume folders"

                    editText destinationFolderEditText "Destination Folder (Doesn't Matter Anymore):" text:"C:\Test" toolTip:"This is the parent where all new volume folders will be saved"
                )

            -- Execution

                button processButton "Process"

        -- Actions

            -- Main

                -- Folders

                    on originalFolderEditText entered txt do(
                        if txt != "" then(
                            originalFolderPathText = txt
                        )else(
                            listOfOriginalVolumeNames = #()
                        )
                    )

                    on destinationFolderEditText entered txt do(
                        if txt != "" then(
                            destinationFolderText = txt
                        )
                    )

                -- Volume to configure

                    on volumeToConfigureDropDownList selected arg do(
                        -- Define currentDropDownListSelectionInteger variable

                            currentDropDownListSelectionInteger = volumeToConfigureDropDownList.selection

                        -- Other Components

                            if currentDropDownListSelectionInteger == 1 then(

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
                            )
                    )

                -- Naming

                    -- Suffix

                        on useOriginalVolumeNameAsSuffixCheckBox changed state do(
                            if state then(
                                -- Change variable

                                    if currentDropDownListSelectionInteger == 1 then(
                                        useOriginalVolumeNameAsSuffixBoolean1 = true
                                    )

                                    if currentDropDownListSelectionInteger == 2 then(
                                        useOriginalVolumeNameAsSuffixBoolean2 = true
                                    )

                                    if currentDropDownListSelectionInteger == 3 then(
                                        useOriginalVolumeNameAsSuffixBoolean3 = true
                                    )

                                    if currentDropDownListSelectionInteger == 4 then(
                                        useOriginalVolumeNameAsSuffixBoolean4 = true
                                    )

                                    if currentDropDownListSelectionInteger == 5 then(
                                        useOriginalVolumeNameAsSuffixBoolean5 = true
                                    )

                                    if currentDropDownListSelectionInteger == 6 then(
                                        useOriginalVolumeNameAsSuffixBoolean6 = true
                                    )

                                    if currentDropDownListSelectionInteger == 7 then(
                                        useOriginalVolumeNameAsSuffixBoolean7 = true
                                    )

                                    if currentDropDownListSelectionInteger == 8 then(
                                        useOriginalVolumeNameAsSuffixBoolean8 = true
                                    )

                                    if currentDropDownListSelectionInteger == 9 then(
                                        useOriginalVolumeNameAsSuffixBoolean9 = true
                                    )

                                    if currentDropDownListSelectionInteger == 10 then(
                                        useOriginalVolumeNameAsSuffixBoolean10 = true
                                    )

                                    if currentDropDownListSelectionInteger == 11 then(
                                        useOriginalVolumeNameAsSuffixBoolean11 = true
                                    )

                                    if currentDropDownListSelectionInteger == 12 then(
                                        useOriginalVolumeNameAsSuffixBoolean12 = true
                                    )

                                    if currentDropDownListSelectionInteger == 13 then(
                                        useOriginalVolumeNameAsSuffixBoolean13 = true
                                    )

                                    if currentDropDownListSelectionInteger == 14 then(
                                        useOriginalVolumeNameAsSuffixBoolean14 = true
                                    )

                                    if currentDropDownListSelectionInteger == 15 then(
                                        useOriginalVolumeNameAsSuffixBoolean15 = true
                                    )

                                    if currentDropDownListSelectionInteger == 16 then(
                                        useOriginalVolumeNameAsSuffixBoolean16 = true
                                    )

                                    if currentDropDownListSelectionInteger == 17 then(
                                        useOriginalVolumeNameAsSuffixBoolean17 = true
                                    )

                                    if currentDropDownListSelectionInteger == 18 then(
                                        useOriginalVolumeNameAsSuffixBoolean18 = true
                                    )

                                    if currentDropDownListSelectionInteger == 19 then(
                                        useOriginalVolumeNameAsSuffixBoolean19 = true
                                    )

                                    if currentDropDownListSelectionInteger == 20 then(
                                        useOriginalVolumeNameAsSuffixBoolean20 = true
                                    )

                                -- Change variable

                                    if currentDropDownListSelectionInteger == 1 then(
                                        volumeNameSuffixEditTextEnabled1 = false
                                    )

                                    if currentDropDownListSelectionInteger == 2 then(
                                        volumeNameSuffixEditTextEnabled2 = false
                                    )

                                    if currentDropDownListSelectionInteger == 3 then(
                                        volumeNameSuffixEditTextEnabled3 = false
                                    )

                                    if currentDropDownListSelectionInteger == 4 then(
                                        volumeNameSuffixEditTextEnabled4 = false
                                    )

                                    if currentDropDownListSelectionInteger == 5 then(
                                        volumeNameSuffixEditTextEnabled5 = false
                                    )

                                    if currentDropDownListSelectionInteger == 6 then(
                                        volumeNameSuffixEditTextEnabled6 = false
                                    )

                                    if currentDropDownListSelectionInteger == 7 then(
                                        volumeNameSuffixEditTextEnabled7 = false
                                    )

                                    if currentDropDownListSelectionInteger == 8 then(
                                        volumeNameSuffixEditTextEnabled8 = false
                                    )

                                    if currentDropDownListSelectionInteger == 9 then(
                                        volumeNameSuffixEditTextEnabled9 = false
                                    )

                                    if currentDropDownListSelectionInteger == 10 then(
                                        volumeNameSuffixEditTextEnabled10 = false
                                    )

                                    if currentDropDownListSelectionInteger == 11 then(
                                        volumeNameSuffixEditTextEnabled11 = false
                                    )

                                    if currentDropDownListSelectionInteger == 12 then(
                                        volumeNameSuffixEditTextEnabled12 = false
                                    )

                                    if currentDropDownListSelectionInteger == 13 then(
                                        volumeNameSuffixEditTextEnabled13 = false
                                    )

                                    if currentDropDownListSelectionInteger == 14 then(
                                        volumeNameSuffixEditTextEnabled14 = false
                                    )

                                    if currentDropDownListSelectionInteger == 15 then(
                                        volumeNameSuffixEditTextEnabled15 = false
                                    )

                                    if currentDropDownListSelectionInteger == 16 then(
                                        volumeNameSuffixEditTextEnabled16 = false
                                    )

                                    if currentDropDownListSelectionInteger == 17 then(
                                        volumeNameSuffixEditTextEnabled17 = false
                                    )

                                    if currentDropDownListSelectionInteger == 18 then(
                                        volumeNameSuffixEditTextEnabled18 = false
                                    )

                                    if currentDropDownListSelectionInteger == 19 then(
                                        volumeNameSuffixEditTextEnabled19 = false
                                    )

                                    if currentDropDownListSelectionInteger == 20 then(
                                        volumeNameSuffixEditTextEnabled20 = false
                                    )

                                -- Other components

                                    volumeNameSuffixEditText.enabled = false
                            )else(
                                -- Change variable

                                    if currentDropDownListSelectionInteger == 1 then(
                                        useOriginalVolumeNameAsSuffixBoolean1 = false
                                    )

                                    if currentDropDownListSelectionInteger == 2 then(
                                        useOriginalVolumeNameAsSuffixBoolean2 = false
                                    )

                                    if currentDropDownListSelectionInteger == 3 then(
                                        useOriginalVolumeNameAsSuffixBoolean3 = false
                                    )

                                    if currentDropDownListSelectionInteger == 4 then(
                                        useOriginalVolumeNameAsSuffixBoolean4 = false
                                    )

                                    if currentDropDownListSelectionInteger == 5 then(
                                        useOriginalVolumeNameAsSuffixBoolean5 = false
                                    )

                                    if currentDropDownListSelectionInteger == 6 then(
                                        useOriginalVolumeNameAsSuffixBoolean6 = false
                                    )

                                    if currentDropDownListSelectionInteger == 7 then(
                                        useOriginalVolumeNameAsSuffixBoolean7 = false
                                    )

                                    if currentDropDownListSelectionInteger == 8 then(
                                        useOriginalVolumeNameAsSuffixBoolean8 = false
                                    )

                                    if currentDropDownListSelectionInteger == 9 then(
                                        useOriginalVolumeNameAsSuffixBoolean9 = false
                                    )

                                    if currentDropDownListSelectionInteger == 10 then(
                                        useOriginalVolumeNameAsSuffixBoolean10 = false
                                    )

                                    if currentDropDownListSelectionInteger == 11 then(
                                        useOriginalVolumeNameAsSuffixBoolean11 = false
                                    )

                                    if currentDropDownListSelectionInteger == 12 then(
                                        useOriginalVolumeNameAsSuffixBoolean12 = false
                                    )

                                    if currentDropDownListSelectionInteger == 13 then(
                                        useOriginalVolumeNameAsSuffixBoolean13 = false
                                    )

                                    if currentDropDownListSelectionInteger == 14 then(
                                        useOriginalVolumeNameAsSuffixBoolean14 = false
                                    )

                                    if currentDropDownListSelectionInteger == 15 then(
                                        useOriginalVolumeNameAsSuffixBoolean15 = false
                                    )

                                    if currentDropDownListSelectionInteger == 16 then(
                                        useOriginalVolumeNameAsSuffixBoolean16 = false
                                    )

                                    if currentDropDownListSelectionInteger == 17 then(
                                        useOriginalVolumeNameAsSuffixBoolean17 = false
                                    )

                                    if currentDropDownListSelectionInteger == 18 then(
                                        useOriginalVolumeNameAsSuffixBoolean18 = false
                                    )

                                    if currentDropDownListSelectionInteger == 19 then(
                                        useOriginalVolumeNameAsSuffixBoolean19 = false
                                    )

                                    if currentDropDownListSelectionInteger == 20 then(
                                        useOriginalVolumeNameAsSuffixBoolean20 = false
                                    )

                                -- Change variable

                                    if currentDropDownListSelectionInteger == 1 then(
                                        volumeNameSuffixEditTextEnabled1 = true
                                    )

                                    if currentDropDownListSelectionInteger == 2 then(
                                        volumeNameSuffixEditTextEnabled2 = true
                                    )

                                    if currentDropDownListSelectionInteger == 3 then(
                                        volumeNameSuffixEditTextEnabled3 = true
                                    )

                                    if currentDropDownListSelectionInteger == 4 then(
                                        volumeNameSuffixEditTextEnabled4 = true
                                    )

                                    if currentDropDownListSelectionInteger == 5 then(
                                        volumeNameSuffixEditTextEnabled5 = true
                                    )

                                    if currentDropDownListSelectionInteger == 6 then(
                                        volumeNameSuffixEditTextEnabled6 = true
                                    )

                                    if currentDropDownListSelectionInteger == 7 then(
                                        volumeNameSuffixEditTextEnabled7 = true
                                    )

                                    if currentDropDownListSelectionInteger == 8 then(
                                        volumeNameSuffixEditTextEnabled8 = true
                                    )

                                    if currentDropDownListSelectionInteger == 9 then(
                                        volumeNameSuffixEditTextEnabled9 = true
                                    )

                                    if currentDropDownListSelectionInteger == 10 then(
                                        volumeNameSuffixEditTextEnabled10 = true
                                    )

                                    if currentDropDownListSelectionInteger == 11 then(
                                        volumeNameSuffixEditTextEnabled11 = true
                                    )

                                    if currentDropDownListSelectionInteger == 12 then(
                                        volumeNameSuffixEditTextEnabled12 = true
                                    )

                                    if currentDropDownListSelectionInteger == 13 then(
                                        volumeNameSuffixEditTextEnabled13 = true
                                    )

                                    if currentDropDownListSelectionInteger == 14 then(
                                        volumeNameSuffixEditTextEnabled14 = true
                                    )

                                    if currentDropDownListSelectionInteger == 15 then(
                                        volumeNameSuffixEditTextEnabled15 = true
                                    )

                                    if currentDropDownListSelectionInteger == 16 then(
                                        volumeNameSuffixEditTextEnabled16 = true
                                    )

                                    if currentDropDownListSelectionInteger == 17 then(
                                        volumeNameSuffixEditTextEnabled17 = true
                                    )

                                    if currentDropDownListSelectionInteger == 18 then(
                                        volumeNameSuffixEditTextEnabled18 = true
                                    )

                                    if currentDropDownListSelectionInteger == 19 then(
                                        volumeNameSuffixEditTextEnabled19 = true
                                    )

                                    if currentDropDownListSelectionInteger == 20 then(
                                        volumeNameSuffixEditTextEnabled20 = true
                                    )

                                -- Other components

                                    volumeNameSuffixEditText.enabled = true
                            )
                        )

                        on volumeNameSuffixEditText entered txt do(
                            -- Change variable

                                if currentDropDownListSelectionInteger == 1 then(
                                    volumeNameSuffixString1 = txt
                                )

                                if currentDropDownListSelectionInteger == 2 then(
                                    volumeNameSuffixString2 = txt
                                )

                                if currentDropDownListSelectionInteger == 3 then(
                                    volumeNameSuffixString3 = txt
                                )

                                if currentDropDownListSelectionInteger == 4 then(
                                    volumeNameSuffixString4 = txt
                                )

                                if currentDropDownListSelectionInteger == 5 then(
                                    volumeNameSuffixString5 = txt
                                )

                                if currentDropDownListSelectionInteger == 6 then(
                                    volumeNameSuffixString6 = txt
                                )

                                if currentDropDownListSelectionInteger == 7 then(
                                    volumeNameSuffixString7 = txt
                                )

                                if currentDropDownListSelectionInteger == 8 then(
                                    volumeNameSuffixString8 = txt
                                )

                                if currentDropDownListSelectionInteger == 9 then(
                                    volumeNameSuffixString9 = txt
                                )

                                if currentDropDownListSelectionInteger == 10 then(
                                    volumeNameSuffixString10 = txt
                                )

                                if currentDropDownListSelectionInteger == 11 then(
                                    volumeNameSuffixString11 = txt
                                )

                                if currentDropDownListSelectionInteger == 12 then(
                                    volumeNameSuffixString12 = txt
                                )

                                if currentDropDownListSelectionInteger == 13 then(
                                    volumeNameSuffixString13 = txt
                                )

                                if currentDropDownListSelectionInteger == 14 then(
                                    volumeNameSuffixString14 = txt
                                )

                                if currentDropDownListSelectionInteger == 15 then(
                                    volumeNameSuffixString15 = txt
                                )

                                if currentDropDownListSelectionInteger == 16 then(
                                    volumeNameSuffixString16 = txt
                                )

                                if currentDropDownListSelectionInteger == 17 then(
                                    volumeNameSuffixString17 = txt
                                )

                                if currentDropDownListSelectionInteger == 18 then(
                                    volumeNameSuffixString18 = txt
                                )

                                if currentDropDownListSelectionInteger == 19 then(
                                    volumeNameSuffixString19 = txt
                                )

                                if currentDropDownListSelectionInteger == 20 then(
                                    volumeNameSuffixString20 = txt
                                )
                        )

                        on fileNameExtraTextEditText entered txt do(
                            -- Change variable

                                if currentDropDownListSelectionInteger == 1 then(
                                    fileNameExtraTextString1 = txt
                                )

                                if currentDropDownListSelectionInteger == 2 then(
                                    fileNameExtraTextString2 = txt
                                )

                                if currentDropDownListSelectionInteger == 3 then(
                                    fileNameExtraTextString3 = txt
                                )

                                if currentDropDownListSelectionInteger == 4 then(
                                    fileNameExtraTextString4 = txt
                                )

                                if currentDropDownListSelectionInteger == 5 then(
                                    fileNameExtraTextString5 = txt
                                )

                                if currentDropDownListSelectionInteger == 6 then(
                                    fileNameExtraTextString6 = txt
                                )

                                if currentDropDownListSelectionInteger == 7 then(
                                    fileNameExtraTextString7 = txt
                                )

                                if currentDropDownListSelectionInteger == 8 then(
                                    fileNameExtraTextString8 = txt
                                )

                                if currentDropDownListSelectionInteger == 9 then(
                                    fileNameExtraTextString9 = txt
                                )

                                if currentDropDownListSelectionInteger == 10 then(
                                    fileNameExtraTextString10 = txt
                                )

                                if currentDropDownListSelectionInteger == 11 then(
                                    fileNameExtraTextString11 = txt
                                )

                                if currentDropDownListSelectionInteger == 12 then(
                                    fileNameExtraTextString12 = txt
                                )

                                if currentDropDownListSelectionInteger == 13 then(
                                    fileNameExtraTextString13 = txt
                                )

                                if currentDropDownListSelectionInteger == 14 then(
                                    fileNameExtraTextString14 = txt
                                )

                                if currentDropDownListSelectionInteger == 15 then(
                                    fileNameExtraTextString15 = txt
                                )

                                if currentDropDownListSelectionInteger == 16 then(
                                    fileNameExtraTextString16 = txt
                                )

                                if currentDropDownListSelectionInteger == 17 then(
                                    fileNameExtraTextString17 = txt
                                )

                                if currentDropDownListSelectionInteger == 18 then(
                                    fileNameExtraTextString18 = txt
                                )

                                if currentDropDownListSelectionInteger == 19 then(
                                    fileNameExtraTextString19 = txt
                                )

                                if currentDropDownListSelectionInteger == 20 then(
                                    fileNameExtraTextString20 = txt
                                )
                        )

                    -- Keyword filter

                        on keywordFilterEditText entered txt do(
                            if txt != "" and txt != undefined then(
                                -- Change variable

                                    if currentDropDownListSelectionInteger == 1 then(
                                        keywordFilterString1 = "*" + txt + "*"
                                    )

                                    if currentDropDownListSelectionInteger == 2 then(
                                        keywordFilterString2 = "*" + txt + "*"
                                    )

                                    if currentDropDownListSelectionInteger == 3 then(
                                        keywordFilterString3 = "*" + txt + "*"
                                    )

                                    if currentDropDownListSelectionInteger == 4 then(
                                        keywordFilterString4 = "*" + txt + "*"
                                    )

                                    if currentDropDownListSelectionInteger == 5 then(
                                        keywordFilterString5 = "*" + txt + "*"
                                    )

                                    if currentDropDownListSelectionInteger == 6 then(
                                        keywordFilterString6 = "*" + txt + "*"
                                    )

                                    if currentDropDownListSelectionInteger == 7 then(
                                        keywordFilterString7 = "*" + txt + "*"
                                    )

                                    if currentDropDownListSelectionInteger == 8 then(
                                        keywordFilterString8 = "*" + txt + "*"
                                    )

                                    if currentDropDownListSelectionInteger == 9 then(
                                        keywordFilterString9 = "*" + txt + "*"
                                    )

                                    if currentDropDownListSelectionInteger == 10 then(
                                        keywordFilterString10 = "*" + txt + "*"
                                    )

                                    if currentDropDownListSelectionInteger == 11 then(
                                        keywordFilterString11 = "*" + txt + "*"
                                    )

                                    if currentDropDownListSelectionInteger == 12 then(
                                        keywordFilterString12 = "*" + txt + "*"
                                    )

                                    if currentDropDownListSelectionInteger == 13 then(
                                        keywordFilterString13 = "*" + txt + "*"
                                    )

                                    if currentDropDownListSelectionInteger == 14 then(
                                        keywordFilterString14 = "*" + txt + "*"
                                    )

                                    if currentDropDownListSelectionInteger == 15 then(
                                        keywordFilterString15 = "*" + txt + "*"
                                    )

                                    if currentDropDownListSelectionInteger == 16 then(
                                        keywordFilterString16 = "*" + txt + "*"
                                    )

                                    if currentDropDownListSelectionInteger == 17 then(
                                        keywordFilterString17 = "*" + txt + "*"
                                    )

                                    if currentDropDownListSelectionInteger == 18 then(
                                        keywordFilterString18 = "*" + txt + "*"
                                    )

                                    if currentDropDownListSelectionInteger == 19 then(
                                        keywordFilterString19 = "*" + txt + "*"
                                    )

                                    if currentDropDownListSelectionInteger == 20 then(
                                        keywordFilterString20 = "*" + txt + "*"
                                    )
                            )else(
                                -- Change variable

                                    if currentDropDownListSelectionInteger == 1 then(
                                        keywordFilterString1 = ""
                                    )

                                    if currentDropDownListSelectionInteger == 2 then(
                                        keywordFilterString2 = ""
                                    )

                                    if currentDropDownListSelectionInteger == 3 then(
                                        keywordFilterString3 = ""
                                    )

                                    if currentDropDownListSelectionInteger == 4 then(
                                        keywordFilterString4 = ""
                                    )

                                    if currentDropDownListSelectionInteger == 5 then(
                                        keywordFilterString5 = ""
                                    )

                                    if currentDropDownListSelectionInteger == 6 then(
                                        keywordFilterString6 = ""
                                    )

                                    if currentDropDownListSelectionInteger == 7 then(
                                        keywordFilterString7 = ""
                                    )

                                    if currentDropDownListSelectionInteger == 8 then(
                                        keywordFilterString8 = ""
                                    )

                                    if currentDropDownListSelectionInteger == 9 then(
                                        keywordFilterString9 = ""
                                    )

                                    if currentDropDownListSelectionInteger == 10 then(
                                        keywordFilterString10 = ""
                                    )

                                    if currentDropDownListSelectionInteger == 11 then(
                                        keywordFilterString11 = ""
                                    )

                                    if currentDropDownListSelectionInteger == 12 then(
                                        keywordFilterString12 = ""
                                    )

                                    if currentDropDownListSelectionInteger == 13 then(
                                        keywordFilterString13 = ""
                                    )

                                    if currentDropDownListSelectionInteger == 14 then(
                                        keywordFilterString14 = ""
                                    )

                                    if currentDropDownListSelectionInteger == 15 then(
                                        keywordFilterString15 = ""
                                    )

                                    if currentDropDownListSelectionInteger == 16 then(
                                        keywordFilterString16 = ""
                                    )

                                    if currentDropDownListSelectionInteger == 17 then(
                                        keywordFilterString17 = ""
                                    )

                                    if currentDropDownListSelectionInteger == 18 then(
                                        keywordFilterString18 = ""
                                    )

                                    if currentDropDownListSelectionInteger == 19 then(
                                        keywordFilterString19 = ""
                                    )

                                    if currentDropDownListSelectionInteger == 20 then(
                                        keywordFilterString20 = ""
                                    )
                            )
                        )

                -- Object handling

                    on saveEachObjectSeparatelyCheckBox changed state do(
                        if state == true then(
                            -- Change variable

                                if currentDropDownListSelectionInteger == 1 then(
                                    saveEachObjectSeparatelyBoolean1 = true
                                    attachObjectsBoolean1 = false
                                )

                                if currentDropDownListSelectionInteger == 2 then(
                                    saveEachObjectSeparatelyBoolean2 = true
                                    attachObjectsBoolean2 = false
                                )

                                if currentDropDownListSelectionInteger == 3 then(
                                    saveEachObjectSeparatelyBoolean3 = true
                                    attachObjectsBoolean3 = false
                                )

                                if currentDropDownListSelectionInteger == 4 then(
                                    saveEachObjectSeparatelyBoolean4 = true
                                    attachObjectsBoolean4 = false
                                )

                                if currentDropDownListSelectionInteger == 5 then(
                                    saveEachObjectSeparatelyBoolean5 = true
                                    attachObjectsBoolean5 = false
                                )

                                if currentDropDownListSelectionInteger == 6 then(
                                    saveEachObjectSeparatelyBoolean6 = true
                                    attachObjectsBoolean6 = false
                                )

                                if currentDropDownListSelectionInteger == 7 then(
                                    saveEachObjectSeparatelyBoolean7 = true
                                    attachObjectsBoolean7 = false
                                )

                                if currentDropDownListSelectionInteger == 8 then(
                                    saveEachObjectSeparatelyBoolean8 = true
                                    attachObjectsBoolean8 = false
                                )

                                if currentDropDownListSelectionInteger == 9 then(
                                    saveEachObjectSeparatelyBoolean9 = true
                                    attachObjectsBoolean9 = false
                                )

                                if currentDropDownListSelectionInteger == 10 then(
                                    saveEachObjectSeparatelyBoolean10 = true
                                    attachObjectsBoolean10 = false
                                )

                                if currentDropDownListSelectionInteger == 11 then(
                                    saveEachObjectSeparatelyBoolean11 = true
                                    attachObjectsBoolean11 = false
                                )

                                if currentDropDownListSelectionInteger == 12 then(
                                    saveEachObjectSeparatelyBoolean12 = true
                                    attachObjectsBoolean12 = false
                                )

                                if currentDropDownListSelectionInteger == 13 then(
                                    saveEachObjectSeparatelyBoolean13 = true
                                    attachObjectsBoolean13 = false
                                )

                                if currentDropDownListSelectionInteger == 14 then(
                                    saveEachObjectSeparatelyBoolean14 = true
                                    attachObjectsBoolean14 = false
                                )

                                if currentDropDownListSelectionInteger == 15 then(
                                    saveEachObjectSeparatelyBoolean15 = true
                                    attachObjectsBoolean15 = false
                                )

                                if currentDropDownListSelectionInteger == 16 then(
                                    saveEachObjectSeparatelyBoolean16 = true
                                    attachObjectsBoolean16 = false
                                )

                                if currentDropDownListSelectionInteger == 17 then(
                                    saveEachObjectSeparatelyBoolean17 = true
                                    attachObjectsBoolean17 = false
                                )

                                if currentDropDownListSelectionInteger == 18 then(
                                    saveEachObjectSeparatelyBoolean18 = true
                                    attachObjectsBoolean18 = false
                                )

                                if currentDropDownListSelectionInteger == 19 then(
                                    saveEachObjectSeparatelyBoolean19 = true
                                    attachObjectsBoolean19 = false
                                )

                                if currentDropDownListSelectionInteger == 20 then(
                                    saveEachObjectSeparatelyBoolean20 = true
                                    attachObjectsBoolean20 = false
                                )

                            -- Change variable

                                if currentDropDownListSelectionInteger == 1 then(
                                    attachObjectsCheckBoxEnabled1 = false
                                )

                                if currentDropDownListSelectionInteger == 2 then(
                                    attachObjectsCheckBoxEnabled2 = false
                                )

                                if currentDropDownListSelectionInteger == 3 then(
                                    attachObjectsCheckBoxEnabled3 = false
                                )

                                if currentDropDownListSelectionInteger == 4 then(
                                    attachObjectsCheckBoxEnabled4 = false
                                )

                                if currentDropDownListSelectionInteger == 5 then(
                                    attachObjectsCheckBoxEnabled5 = false
                                )

                                if currentDropDownListSelectionInteger == 6 then(
                                    attachObjectsCheckBoxEnabled6 = false
                                )

                                if currentDropDownListSelectionInteger == 7 then(
                                    attachObjectsCheckBoxEnabled7 = false
                                )

                                if currentDropDownListSelectionInteger == 8 then(
                                    attachObjectsCheckBoxEnabled8 = false
                                )

                                if currentDropDownListSelectionInteger == 9 then(
                                    attachObjectsCheckBoxEnabled9 = false
                                )

                                if currentDropDownListSelectionInteger == 10 then(
                                    attachObjectsCheckBoxEnabled10 = false
                                )

                                if currentDropDownListSelectionInteger == 11 then(
                                    attachObjectsCheckBoxEnabled11 = false
                                )

                                if currentDropDownListSelectionInteger == 12 then(
                                    attachObjectsCheckBoxEnabled12 = false
                                )

                                if currentDropDownListSelectionInteger == 13 then(
                                    attachObjectsCheckBoxEnabled13 = false
                                )

                                if currentDropDownListSelectionInteger == 14 then(
                                    attachObjectsCheckBoxEnabled14 = false
                                )

                                if currentDropDownListSelectionInteger == 15 then(
                                    attachObjectsCheckBoxEnabled15 = false
                                )

                                if currentDropDownListSelectionInteger == 16 then(
                                    attachObjectsCheckBoxEnabled16 = false
                                )

                                if currentDropDownListSelectionInteger == 17 then(
                                    attachObjectsCheckBoxEnabled17 = false
                                )

                                if currentDropDownListSelectionInteger == 18 then(
                                    attachObjectsCheckBoxEnabled18 = false
                                )

                                if currentDropDownListSelectionInteger == 19 then(
                                    attachObjectsCheckBoxEnabled19 = false
                                )

                                if currentDropDownListSelectionInteger == 20 then(
                                    attachObjectsCheckBoxEnabled20 = false
                                )

                            -- Other Components

                                attachObjectsCheckBox.enabled = false

                                attachObjectsCheckBox.checked = false
                        )else(
                            -- Change variable

                                if currentDropDownListSelectionInteger == 1 then(
                                    saveEachObjectSeparatelyBoolean1 = false
                                    attachObjectsBoolean1 = true
                                )

                                if currentDropDownListSelectionInteger == 2 then(
                                    saveEachObjectSeparatelyBoolean2 = false
                                    attachObjectsBoolean2 = true
                                )

                                if currentDropDownListSelectionInteger == 3 then(
                                    saveEachObjectSeparatelyBoolean3 = false
                                    attachObjectsBoolean3 = true
                                )

                                if currentDropDownListSelectionInteger == 4 then(
                                    saveEachObjectSeparatelyBoolean4 = false
                                    attachObjectsBoolean4 = true
                                )

                                if currentDropDownListSelectionInteger == 5 then(
                                    saveEachObjectSeparatelyBoolean5 = false
                                    attachObjectsBoolean5 = true
                                )

                                if currentDropDownListSelectionInteger == 6 then(
                                    saveEachObjectSeparatelyBoolean6 = false
                                    attachObjectsBoolean6 = true
                                )

                                if currentDropDownListSelectionInteger == 7 then(
                                    saveEachObjectSeparatelyBoolean7 = false
                                    attachObjectsBoolean7 = true
                                )

                                if currentDropDownListSelectionInteger == 8 then(
                                    saveEachObjectSeparatelyBoolean8 = false
                                    attachObjectsBoolean8 = true
                                )

                                if currentDropDownListSelectionInteger == 9 then(
                                    saveEachObjectSeparatelyBoolean9 = false
                                    attachObjectsBoolean9 = true
                                )

                                if currentDropDownListSelectionInteger == 10 then(
                                    saveEachObjectSeparatelyBoolean10 = false
                                    attachObjectsBoolean10 = true
                                )

                                if currentDropDownListSelectionInteger == 11 then(
                                    saveEachObjectSeparatelyBoolean11 = false
                                    attachObjectsBoolean11 = true
                                )

                                if currentDropDownListSelectionInteger == 12 then(
                                    saveEachObjectSeparatelyBoolean12 = false
                                    attachObjectsBoolean12 = true
                                )

                                if currentDropDownListSelectionInteger == 13 then(
                                    saveEachObjectSeparatelyBoolean13 = false
                                    attachObjectsBoolean13 = true
                                )

                                if currentDropDownListSelectionInteger == 14 then(
                                    saveEachObjectSeparatelyBoolean14 = false
                                    attachObjectsBoolean14 = true
                                )

                                if currentDropDownListSelectionInteger == 15 then(
                                    saveEachObjectSeparatelyBoolean15 = false
                                    attachObjectsBoolean15 = true
                                )

                                if currentDropDownListSelectionInteger == 16 then(
                                    saveEachObjectSeparatelyBoolean16 = false
                                    attachObjectsBoolean16 = true
                                )

                                if currentDropDownListSelectionInteger == 17 then(
                                    saveEachObjectSeparatelyBoolean17 = false
                                    attachObjectsBoolean17 = true
                                )

                                if currentDropDownListSelectionInteger == 18 then(
                                    saveEachObjectSeparatelyBoolean18 = false
                                    attachObjectsBoolean18 = true
                                )

                                if currentDropDownListSelectionInteger == 19 then(
                                    saveEachObjectSeparatelyBoolean19 = false
                                    attachObjectsBoolean19 = true
                                )

                                if currentDropDownListSelectionInteger == 20 then(
                                    saveEachObjectSeparatelyBoolean20 = false
                                    attachObjectsBoolean20 = true
                                )

                            -- Change variable

                                if currentDropDownListSelectionInteger == 1 then(
                                    attachObjectsCheckBoxEnabled1 = true
                                )

                                if currentDropDownListSelectionInteger == 2 then(
                                    attachObjectsCheckBoxEnabled2 = true
                                )

                                if currentDropDownListSelectionInteger == 3 then(
                                    attachObjectsCheckBoxEnabled3 = true
                                )

                                if currentDropDownListSelectionInteger == 4 then(
                                    attachObjectsCheckBoxEnabled4 = true
                                )

                                if currentDropDownListSelectionInteger == 5 then(
                                    attachObjectsCheckBoxEnabled5 = true
                                )

                                if currentDropDownListSelectionInteger == 6 then(
                                    attachObjectsCheckBoxEnabled6 = true
                                )

                                if currentDropDownListSelectionInteger == 7 then(
                                    attachObjectsCheckBoxEnabled7 = true
                                )

                                if currentDropDownListSelectionInteger == 8 then(
                                    attachObjectsCheckBoxEnabled8 = true
                                )

                                if currentDropDownListSelectionInteger == 9 then(
                                    attachObjectsCheckBoxEnabled9 = true
                                )

                                if currentDropDownListSelectionInteger == 10 then(
                                    attachObjectsCheckBoxEnabled10 = true
                                )

                                if currentDropDownListSelectionInteger == 11 then(
                                    attachObjectsCheckBoxEnabled11 = true
                                )

                                if currentDropDownListSelectionInteger == 12 then(
                                    attachObjectsCheckBoxEnabled12 = true
                                )

                                if currentDropDownListSelectionInteger == 13 then(
                                    attachObjectsCheckBoxEnabled13 = true
                                )

                                if currentDropDownListSelectionInteger == 14 then(
                                    attachObjectsCheckBoxEnabled14 = true
                                )

                                if currentDropDownListSelectionInteger == 15 then(
                                    attachObjectsCheckBoxEnabled15 = true
                                )

                                if currentDropDownListSelectionInteger == 16 then(
                                    attachObjectsCheckBoxEnabled16 = true
                                )

                                if currentDropDownListSelectionInteger == 17 then(
                                    attachObjectsCheckBoxEnabled17 = true
                                )

                                if currentDropDownListSelectionInteger == 18 then(
                                    attachObjectsCheckBoxEnabled18 = true
                                )

                                if currentDropDownListSelectionInteger == 19 then(
                                    attachObjectsCheckBoxEnabled19 = true
                                )

                                if currentDropDownListSelectionInteger == 20 then(
                                    attachObjectsCheckBoxEnabled20 = true
                                )

                            -- Other Components

                                attachObjectsCheckBox.enabled = true
                        )
                    )

                    on attachObjectsCheckBox changed state do(
                        if state == true then(
                            -- Change variable

                                if currentDropDownListSelectionInteger == 1 then(
                                    attachObjectsBoolean1 = true
                                )

                                if currentDropDownListSelectionInteger == 2 then(
                                    attachObjectsBoolean2 = true
                                )

                                if currentDropDownListSelectionInteger == 3 then(
                                    attachObjectsBoolean3 = true
                                )

                                if currentDropDownListSelectionInteger == 4 then(
                                    attachObjectsBoolean4 = true
                                )

                                if currentDropDownListSelectionInteger == 5 then(
                                    attachObjectsBoolean5 = true
                                )

                                if currentDropDownListSelectionInteger == 6 then(
                                    attachObjectsBoolean6 = true
                                )

                                if currentDropDownListSelectionInteger == 7 then(
                                    attachObjectsBoolean7 = true
                                )

                                if currentDropDownListSelectionInteger == 8 then(
                                    attachObjectsBoolean8 = true
                                )

                                if currentDropDownListSelectionInteger == 9 then(
                                    attachObjectsBoolean9 = true
                                )

                                if currentDropDownListSelectionInteger == 10 then(
                                    attachObjectsBoolean10 = true
                                )

                                if currentDropDownListSelectionInteger == 11 then(
                                    attachObjectsBoolean11 = true
                                )

                                if currentDropDownListSelectionInteger == 12 then(
                                    attachObjectsBoolean12 = true
                                )

                                if currentDropDownListSelectionInteger == 13 then(
                                    attachObjectsBoolean13 = true
                                )

                                if currentDropDownListSelectionInteger == 14 then(
                                    attachObjectsBoolean14 = true
                                )

                                if currentDropDownListSelectionInteger == 15 then(
                                    attachObjectsBoolean15 = true
                                )

                                if currentDropDownListSelectionInteger == 16 then(
                                    attachObjectsBoolean16 = true
                                )

                                if currentDropDownListSelectionInteger == 17 then(
                                    attachObjectsBoolean17 = true
                                )

                                if currentDropDownListSelectionInteger == 18 then(
                                    attachObjectsBoolean18 = true
                                )

                                if currentDropDownListSelectionInteger == 19 then(
                                    attachObjectsBoolean19 = true
                                )

                                if currentDropDownListSelectionInteger == 20 then(
                                    attachObjectsBoolean20 = true
                                )
                        )else(
                            -- Change variable

                                if currentDropDownListSelectionInteger == 1 then(
                                    attachObjectsBoolean1 = false
                                )

                                if currentDropDownListSelectionInteger == 2 then(
                                    attachObjectsBoolean2 = false
                                )

                                if currentDropDownListSelectionInteger == 3 then(
                                    attachObjectsBoolean3 = false
                                )

                                if currentDropDownListSelectionInteger == 4 then(
                                    attachObjectsBoolean4 = false
                                )

                                if currentDropDownListSelectionInteger == 5 then(
                                    attachObjectsBoolean5 = false
                                )

                                if currentDropDownListSelectionInteger == 6 then(
                                    attachObjectsBoolean6 = false
                                )

                                if currentDropDownListSelectionInteger == 7 then(
                                    attachObjectsBoolean7 = false
                                )

                                if currentDropDownListSelectionInteger == 8 then(
                                    attachObjectsBoolean8 = false
                                )

                                if currentDropDownListSelectionInteger == 9 then(
                                    attachObjectsBoolean9 = false
                                )

                                if currentDropDownListSelectionInteger == 10 then(
                                    attachObjectsBoolean10 = false
                                )

                                if currentDropDownListSelectionInteger == 11 then(
                                    attachObjectsBoolean11 = false
                                )

                                if currentDropDownListSelectionInteger == 12 then(
                                    attachObjectsBoolean12 = false
                                )

                                if currentDropDownListSelectionInteger == 13 then(
                                    attachObjectsBoolean13 = false
                                )

                                if currentDropDownListSelectionInteger == 14 then(
                                    attachObjectsBoolean14 = false
                                )

                                if currentDropDownListSelectionInteger == 15 then(
                                    attachObjectsBoolean15 = false
                                )

                                if currentDropDownListSelectionInteger == 16 then(
                                    attachObjectsBoolean16 = false
                                )

                                if currentDropDownListSelectionInteger == 17 then(
                                    attachObjectsBoolean17 = false
                                )

                                if currentDropDownListSelectionInteger == 18 then(
                                    attachObjectsBoolean18 = false
                                )

                                if currentDropDownListSelectionInteger == 19 then(
                                    attachObjectsBoolean19 = false
                                )

                                if currentDropDownListSelectionInteger == 20 then(
                                    attachObjectsBoolean20 = false
                                )
                        )
                    )

                    on proxyObjectsCheckBox changed state do(
                        if state == true then(
                            -- Change variable

                                if currentDropDownListSelectionInteger == 1 then(
                                    proxyObjectsBoolean1 = true
                                )

                                if currentDropDownListSelectionInteger == 2 then(
                                    proxyObjectsBoolean2 = true
                                )

                                if currentDropDownListSelectionInteger == 3 then(
                                    proxyObjectsBoolean3 = true
                                )

                                if currentDropDownListSelectionInteger == 4 then(
                                    proxyObjectsBoolean4 = true
                                )

                                if currentDropDownListSelectionInteger == 5 then(
                                    proxyObjectsBoolean5 = true
                                )

                                if currentDropDownListSelectionInteger == 6 then(
                                    proxyObjectsBoolean6 = true
                                )

                                if currentDropDownListSelectionInteger == 7 then(
                                    proxyObjectsBoolean7 = true
                                )

                                if currentDropDownListSelectionInteger == 8 then(
                                    proxyObjectsBoolean8 = true
                                )

                                if currentDropDownListSelectionInteger == 9 then(
                                    proxyObjectsBoolean9 = true
                                )

                                if currentDropDownListSelectionInteger == 10 then(
                                    proxyObjectsBoolean10 = true
                                )

                                if currentDropDownListSelectionInteger == 11 then(
                                    proxyObjectsBoolean11 = true
                                )

                                if currentDropDownListSelectionInteger == 12 then(
                                    proxyObjectsBoolean12 = true
                                )

                                if currentDropDownListSelectionInteger == 13 then(
                                    proxyObjectsBoolean13 = true
                                )

                                if currentDropDownListSelectionInteger == 14 then(
                                    proxyObjectsBoolean14 = true
                                )

                                if currentDropDownListSelectionInteger == 15 then(
                                    proxyObjectsBoolean15 = true
                                )

                                if currentDropDownListSelectionInteger == 16 then(
                                    proxyObjectsBoolean16 = true
                                )

                                if currentDropDownListSelectionInteger == 17 then(
                                    proxyObjectsBoolean17 = true
                                )

                                if currentDropDownListSelectionInteger == 18 then(
                                    proxyObjectsBoolean18 = true
                                )

                                if currentDropDownListSelectionInteger == 19 then(
                                    proxyObjectsBoolean19 = true
                                )

                                if currentDropDownListSelectionInteger == 20 then(
                                    proxyObjectsBoolean20 = true
                                )

                            -- Change variable

                                if currentDropDownListSelectionInteger == 1 then(
                                    facesNumberSpinnerEnabled1 = true
                                )

                                if currentDropDownListSelectionInteger == 2 then(
                                    facesNumberSpinnerEnabled2 = true
                                )

                                if currentDropDownListSelectionInteger == 3 then(
                                    facesNumberSpinnerEnabled3 = true
                                )

                                if currentDropDownListSelectionInteger == 4 then(
                                    facesNumberSpinnerEnabled4 = true
                                )

                                if currentDropDownListSelectionInteger == 5 then(
                                    facesNumberSpinnerEnabled5 = true
                                )

                                if currentDropDownListSelectionInteger == 6 then(
                                    facesNumberSpinnerEnabled6 = true
                                )

                                if currentDropDownListSelectionInteger == 7 then(
                                    facesNumberSpinnerEnabled7 = true
                                )

                                if currentDropDownListSelectionInteger == 8 then(
                                    facesNumberSpinnerEnabled8 = true
                                )

                                if currentDropDownListSelectionInteger == 9 then(
                                    facesNumberSpinnerEnabled9 = true
                                )

                                if currentDropDownListSelectionInteger == 10 then(
                                    facesNumberSpinnerEnabled10 = true
                                )

                                if currentDropDownListSelectionInteger == 11 then(
                                    facesNumberSpinnerEnabled11 = true
                                )

                                if currentDropDownListSelectionInteger == 12 then(
                                    facesNumberSpinnerEnabled12 = true
                                )

                                if currentDropDownListSelectionInteger == 13 then(
                                    facesNumberSpinnerEnabled13 = true
                                )

                                if currentDropDownListSelectionInteger == 14 then(
                                    facesNumberSpinnerEnabled14 = true
                                )

                                if currentDropDownListSelectionInteger == 15 then(
                                    facesNumberSpinnerEnabled15 = true
                                )

                                if currentDropDownListSelectionInteger == 16 then(
                                    facesNumberSpinnerEnabled16 = true
                                )

                                if currentDropDownListSelectionInteger == 17 then(
                                    facesNumberSpinnerEnabled17 = true
                                )

                                if currentDropDownListSelectionInteger == 18 then(
                                    facesNumberSpinnerEnabled18 = true
                                )

                                if currentDropDownListSelectionInteger == 19 then(
                                    facesNumberSpinnerEnabled19 = true
                                )

                                if currentDropDownListSelectionInteger == 20 then(
                                    facesNumberSpinnerEnabled20 = true
                                )

                            -- Other Components

                                facesNumberSpinner.enabled = true
                        )else(
                            -- Change variable

                                if currentDropDownListSelectionInteger == 1 then(
                                    proxyObjectsBoolean1 = false
                                )

                                if currentDropDownListSelectionInteger == 2 then(
                                    proxyObjectsBoolean2 = false
                                )

                                if currentDropDownListSelectionInteger == 3 then(
                                    proxyObjectsBoolean3 = false
                                )

                                if currentDropDownListSelectionInteger == 4 then(
                                    proxyObjectsBoolean4 = false
                                )

                                if currentDropDownListSelectionInteger == 5 then(
                                    proxyObjectsBoolean5 = false
                                )

                                if currentDropDownListSelectionInteger == 6 then(
                                    proxyObjectsBoolean6 = false
                                )

                                if currentDropDownListSelectionInteger == 7 then(
                                    proxyObjectsBoolean7 = false
                                )

                                if currentDropDownListSelectionInteger == 8 then(
                                    proxyObjectsBoolean8 = false
                                )

                                if currentDropDownListSelectionInteger == 9 then(
                                    proxyObjectsBoolean9 = false
                                )

                                if currentDropDownListSelectionInteger == 10 then(
                                    proxyObjectsBoolean10 = false
                                )

                                if currentDropDownListSelectionInteger == 11 then(
                                    proxyObjectsBoolean11 = false
                                )

                                if currentDropDownListSelectionInteger == 12 then(
                                    proxyObjectsBoolean12 = false
                                )

                                if currentDropDownListSelectionInteger == 13 then(
                                    proxyObjectsBoolean13 = false
                                )

                                if currentDropDownListSelectionInteger == 14 then(
                                    proxyObjectsBoolean14 = false
                                )

                                if currentDropDownListSelectionInteger == 15 then(
                                    proxyObjectsBoolean15 = false
                                )

                                if currentDropDownListSelectionInteger == 16 then(
                                    proxyObjectsBoolean16 = false
                                )

                                if currentDropDownListSelectionInteger == 17 then(
                                    proxyObjectsBoolean17 = false
                                )

                                if currentDropDownListSelectionInteger == 18 then(
                                    proxyObjectsBoolean18 = false
                                )

                                if currentDropDownListSelectionInteger == 19 then(
                                    proxyObjectsBoolean19 = false
                                )

                                if currentDropDownListSelectionInteger == 20 then(
                                    proxyObjectsBoolean20 = false
                                )

                            -- Change variable

                                if currentDropDownListSelectionInteger == 1 then(
                                    facesNumberSpinnerEnabled1 = false
                                )

                                if currentDropDownListSelectionInteger == 2 then(
                                    facesNumberSpinnerEnabled2 = false
                                )

                                if currentDropDownListSelectionInteger == 3 then(
                                    facesNumberSpinnerEnabled3 = false
                                )

                                if currentDropDownListSelectionInteger == 4 then(
                                    facesNumberSpinnerEnabled4 = false
                                )

                                if currentDropDownListSelectionInteger == 5 then(
                                    facesNumberSpinnerEnabled5 = false
                                )

                                if currentDropDownListSelectionInteger == 6 then(
                                    facesNumberSpinnerEnabled6 = false
                                )

                                if currentDropDownListSelectionInteger == 7 then(
                                    facesNumberSpinnerEnabled7 = false
                                )

                                if currentDropDownListSelectionInteger == 8 then(
                                    facesNumberSpinnerEnabled8 = false
                                )

                                if currentDropDownListSelectionInteger == 9 then(
                                    facesNumberSpinnerEnabled9 = false
                                )

                                if currentDropDownListSelectionInteger == 10 then(
                                    facesNumberSpinnerEnabled10 = false
                                )

                                if currentDropDownListSelectionInteger == 11 then(
                                    facesNumberSpinnerEnabled11 = false
                                )

                                if currentDropDownListSelectionInteger == 12 then(
                                    facesNumberSpinnerEnabled12 = false
                                )

                                if currentDropDownListSelectionInteger == 13 then(
                                    facesNumberSpinnerEnabled13 = false
                                )

                                if currentDropDownListSelectionInteger == 14 then(
                                    facesNumberSpinnerEnabled14 = false
                                )

                                if currentDropDownListSelectionInteger == 15 then(
                                    facesNumberSpinnerEnabled15 = false
                                )

                                if currentDropDownListSelectionInteger == 16 then(
                                    facesNumberSpinnerEnabled16 = false
                                )

                                if currentDropDownListSelectionInteger == 17 then(
                                    facesNumberSpinnerEnabled17 = false
                                )

                                if currentDropDownListSelectionInteger == 18 then(
                                    facesNumberSpinnerEnabled18 = false
                                )

                                if currentDropDownListSelectionInteger == 19 then(
                                    facesNumberSpinnerEnabled19 = false
                                )

                                if currentDropDownListSelectionInteger == 20 then(
                                    facesNumberSpinnerEnabled20 = false
                                )

                            -- Other Components

                                facesNumberSpinner.enabled = false
                        )
                    )

                    on facesNumberSpinner changed num do(
                        -- Change variable

                            if currentDropDownListSelectionInteger == 1 then(
                                facesNumberInteger1 = num
                            )

                            if currentDropDownListSelectionInteger == 2 then(
                                facesNumberInteger2 = num
                            )

                            if currentDropDownListSelectionInteger == 3 then(
                                facesNumberInteger3 = num
                            )

                            if currentDropDownListSelectionInteger == 4 then(
                                facesNumberInteger4 = num
                            )

                            if currentDropDownListSelectionInteger == 5 then(
                                facesNumberInteger5 = num
                            )

                            if currentDropDownListSelectionInteger == 6 then(
                                facesNumberInteger6 = num
                            )

                            if currentDropDownListSelectionInteger == 7 then(
                                facesNumberInteger7 = num
                            )

                            if currentDropDownListSelectionInteger == 8 then(
                                facesNumberInteger8 = num
                            )

                            if currentDropDownListSelectionInteger == 9 then(
                                facesNumberInteger9 = num
                            )

                            if currentDropDownListSelectionInteger == 10 then(
                                facesNumberInteger10 = num
                            )

                            if currentDropDownListSelectionInteger == 11 then(
                                facesNumberInteger11 = num
                            )

                            if currentDropDownListSelectionInteger == 12 then(
                                facesNumberInteger12 = num
                            )

                            if currentDropDownListSelectionInteger == 13 then(
                                facesNumberInteger13 = num
                            )

                            if currentDropDownListSelectionInteger == 14 then(
                                facesNumberInteger14 = num
                            )

                            if currentDropDownListSelectionInteger == 15 then(
                                facesNumberInteger15 = num
                            )

                            if currentDropDownListSelectionInteger == 16 then(
                                facesNumberInteger16 = num
                            )

                            if currentDropDownListSelectionInteger == 17 then(
                                facesNumberInteger17 = num
                            )

                            if currentDropDownListSelectionInteger == 18 then(
                                facesNumberInteger18 = num
                            )

                            if currentDropDownListSelectionInteger == 19 then(
                                facesNumberInteger19 = num
                            )

                            if currentDropDownListSelectionInteger == 20 then(
                                facesNumberInteger20 = num
                            )
                    )

                -- Output filters

                    on includeCamerasCheckBox changed state do(
                        if state == true then(
                            -- Change variable

                                if currentDropDownListSelectionInteger == 1 then(
                                    includeCamerasBoolean1 = true
                                )

                                if currentDropDownListSelectionInteger == 2 then(
                                    includeCamerasBoolean2 = true
                                )

                                if currentDropDownListSelectionInteger == 3 then(
                                    includeCamerasBoolean3 = true
                                )

                                if currentDropDownListSelectionInteger == 4 then(
                                    includeCamerasBoolean4 = true
                                )

                                if currentDropDownListSelectionInteger == 5 then(
                                    includeCamerasBoolean5 = true
                                )

                                if currentDropDownListSelectionInteger == 6 then(
                                    includeCamerasBoolean6 = true
                                )

                                if currentDropDownListSelectionInteger == 7 then(
                                    includeCamerasBoolean7 = true
                                )

                                if currentDropDownListSelectionInteger == 8 then(
                                    includeCamerasBoolean8 = true
                                )

                                if currentDropDownListSelectionInteger == 9 then(
                                    includeCamerasBoolean9 = true
                                )

                                if currentDropDownListSelectionInteger == 10 then(
                                    includeCamerasBoolean10 = true
                                )

                                if currentDropDownListSelectionInteger == 11 then(
                                    includeCamerasBoolean11 = true
                                )

                                if currentDropDownListSelectionInteger == 12 then(
                                    includeCamerasBoolean12 = true
                                )

                                if currentDropDownListSelectionInteger == 13 then(
                                    includeCamerasBoolean13 = true
                                )

                                if currentDropDownListSelectionInteger == 14 then(
                                    includeCamerasBoolean14 = true
                                )

                                if currentDropDownListSelectionInteger == 15 then(
                                    includeCamerasBoolean15 = true
                                )

                                if currentDropDownListSelectionInteger == 16 then(
                                    includeCamerasBoolean16 = true
                                )

                                if currentDropDownListSelectionInteger == 17 then(
                                    includeCamerasBoolean17 = true
                                )

                                if currentDropDownListSelectionInteger == 18 then(
                                    includeCamerasBoolean18 = true
                                )

                                if currentDropDownListSelectionInteger == 19 then(
                                    includeCamerasBoolean19 = true
                                )

                                if currentDropDownListSelectionInteger == 20 then(
                                    includeCamerasBoolean20 = true
                                )
                        )else(
                            -- Change variable

                                if currentDropDownListSelectionInteger == 1 then(
                                    includeCamerasBoolean1 = false
                                )

                                if currentDropDownListSelectionInteger == 2 then(
                                    includeCamerasBoolean2 = false
                                )

                                if currentDropDownListSelectionInteger == 3 then(
                                    includeCamerasBoolean3 = false
                                )

                                if currentDropDownListSelectionInteger == 4 then(
                                    includeCamerasBoolean4 = false
                                )

                                if currentDropDownListSelectionInteger == 5 then(
                                    includeCamerasBoolean5 = false
                                )

                                if currentDropDownListSelectionInteger == 6 then(
                                    includeCamerasBoolean6 = false
                                )

                                if currentDropDownListSelectionInteger == 7 then(
                                    includeCamerasBoolean7 = false
                                )

                                if currentDropDownListSelectionInteger == 8 then(
                                    includeCamerasBoolean8 = false
                                )

                                if currentDropDownListSelectionInteger == 9 then(
                                    includeCamerasBoolean9 = false
                                )

                                if currentDropDownListSelectionInteger == 10 then(
                                    includeCamerasBoolean10 = false
                                )

                                if currentDropDownListSelectionInteger == 11 then(
                                    includeCamerasBoolean11 = false
                                )

                                if currentDropDownListSelectionInteger == 12 then(
                                    includeCamerasBoolean12 = false
                                )

                                if currentDropDownListSelectionInteger == 13 then(
                                    includeCamerasBoolean13 = false
                                )

                                if currentDropDownListSelectionInteger == 14 then(
                                    includeCamerasBoolean14 = false
                                )

                                if currentDropDownListSelectionInteger == 15 then(
                                    includeCamerasBoolean15 = false
                                )

                                if currentDropDownListSelectionInteger == 16 then(
                                    includeCamerasBoolean16 = false
                                )

                                if currentDropDownListSelectionInteger == 17 then(
                                    includeCamerasBoolean17 = false
                                )

                                if currentDropDownListSelectionInteger == 18 then(
                                    includeCamerasBoolean18 = false
                                )

                                if currentDropDownListSelectionInteger == 19 then(
                                    includeCamerasBoolean19 = false
                                )

                                if currentDropDownListSelectionInteger == 20 then(
                                    includeCamerasBoolean20 = false
                                )
                        )
                    )

                    on includeLightsCheckBox changed state do(
                        if state == true then(
                            -- Change variable

                                if currentDropDownListSelectionInteger == 1 then(
                                    includeLightsBoolean1 = true
                                )

                                if currentDropDownListSelectionInteger == 2 then(
                                    includeLightsBoolean2 = true
                                )

                                if currentDropDownListSelectionInteger == 3 then(
                                    includeLightsBoolean3 = true
                                )

                                if currentDropDownListSelectionInteger == 4 then(
                                    includeLightsBoolean4 = true
                                )

                                if currentDropDownListSelectionInteger == 5 then(
                                    includeLightsBoolean5 = true
                                )

                                if currentDropDownListSelectionInteger == 6 then(
                                    includeLightsBoolean6 = true
                                )

                                if currentDropDownListSelectionInteger == 7 then(
                                    includeLightsBoolean7 = true
                                )

                                if currentDropDownListSelectionInteger == 8 then(
                                    includeLightsBoolean8 = true
                                )

                                if currentDropDownListSelectionInteger == 9 then(
                                    includeLightsBoolean9 = true
                                )

                                if currentDropDownListSelectionInteger == 10 then(
                                    includeLightsBoolean10 = true
                                )

                                if currentDropDownListSelectionInteger == 11 then(
                                    includeLightsBoolean11 = true
                                )

                                if currentDropDownListSelectionInteger == 12 then(
                                    includeLightsBoolean12 = true
                                )

                                if currentDropDownListSelectionInteger == 13 then(
                                    includeLightsBoolean13 = true
                                )

                                if currentDropDownListSelectionInteger == 14 then(
                                    includeLightsBoolean14 = true
                                )

                                if currentDropDownListSelectionInteger == 15 then(
                                    includeLightsBoolean15 = true
                                )

                                if currentDropDownListSelectionInteger == 16 then(
                                    includeLightsBoolean16 = true
                                )

                                if currentDropDownListSelectionInteger == 17 then(
                                    includeLightsBoolean17 = true
                                )

                                if currentDropDownListSelectionInteger == 18 then(
                                    includeLightsBoolean18 = true
                                )

                                if currentDropDownListSelectionInteger == 19 then(
                                    includeLightsBoolean19 = true
                                )

                                if currentDropDownListSelectionInteger == 20 then(
                                    includeLightsBoolean20 = true
                                )
                        )else(
                            -- Change variable

                                if currentDropDownListSelectionInteger == 1 then(
                                    includeLightsBoolean1 = false
                                )

                                if currentDropDownListSelectionInteger == 2 then(
                                    includeLightsBoolean2 = false
                                )

                                if currentDropDownListSelectionInteger == 3 then(
                                    includeLightsBoolean3 = false
                                )

                                if currentDropDownListSelectionInteger == 4 then(
                                    includeLightsBoolean4 = false
                                )

                                if currentDropDownListSelectionInteger == 5 then(
                                    includeLightsBoolean5 = false
                                )

                                if currentDropDownListSelectionInteger == 6 then(
                                    includeLightsBoolean6 = false
                                )

                                if currentDropDownListSelectionInteger == 7 then(
                                    includeLightsBoolean7 = false
                                )

                                if currentDropDownListSelectionInteger == 8 then(
                                    includeLightsBoolean8 = false
                                )

                                if currentDropDownListSelectionInteger == 9 then(
                                    includeLightsBoolean9 = false
                                )

                                if currentDropDownListSelectionInteger == 10 then(
                                    includeLightsBoolean10 = false
                                )

                                if currentDropDownListSelectionInteger == 11 then(
                                    includeLightsBoolean11 = false
                                )

                                if currentDropDownListSelectionInteger == 12 then(
                                    includeLightsBoolean12 = false
                                )

                                if currentDropDownListSelectionInteger == 13 then(
                                    includeLightsBoolean13 = false
                                )

                                if currentDropDownListSelectionInteger == 14 then(
                                    includeLightsBoolean14 = false
                                )

                                if currentDropDownListSelectionInteger == 15 then(
                                    includeLightsBoolean15 = false
                                )

                                if currentDropDownListSelectionInteger == 16 then(
                                    includeLightsBoolean16 = false
                                )

                                if currentDropDownListSelectionInteger == 17 then(
                                    includeLightsBoolean17 = false
                                )

                                if currentDropDownListSelectionInteger == 18 then(
                                    includeLightsBoolean18 = false
                                )

                                if currentDropDownListSelectionInteger == 19 then(
                                    includeLightsBoolean19 = false
                                )

                                if currentDropDownListSelectionInteger == 20 then(
                                    includeLightsBoolean20 = false
                                )
                        )
                    )

                -- File naming

                    on replaceAllTextCheckBox changed state do(
                        if replaceAllTextCheckBox.checked == true then(
                            -- Variables

                                -- Change variable

                                    if currentDropDownListSelectionInteger == 1 then(
                                        replaceAllTextBoolean1 = true
                                        retainSpecifiedTextFromFileNameBoolean1 = false
                                        retainSpecifiedTextFromObjectNameBoolean1 = false
                                        retainAllTextFromFileNameBoolean1 = false
                                    )

                                    if currentDropDownListSelectionInteger == 2 then(
                                        replaceAllTextBoolean2 = true
                                        retainSpecifiedTextFromFileNameBoolean2 = false
                                        retainSpecifiedTextFromObjectNameBoolean2 = false
                                        retainAllTextFromFileNameBoolean2 = false
                                    )

                                    if currentDropDownListSelectionInteger == 3 then(
                                        replaceAllTextBoolean3 = true
                                        retainSpecifiedTextFromFileNameBoolean3 = false
                                        retainSpecifiedTextFromObjectNameBoolean3 = false
                                        retainAllTextFromFileNameBoolean3 = false
                                    )

                                    if currentDropDownListSelectionInteger == 4 then(
                                        replaceAllTextBoolean4 = true
                                        retainSpecifiedTextFromFileNameBoolean4 = false
                                        retainSpecifiedTextFromObjectNameBoolean4 = false
                                        replaceAllTextBoolean = false
                                    )

                                    if currentDropDownListSelectionInteger == 5 then(
                                        replaceAllTextBoolean5 = true
                                        retainSpecifiedTextFromFileNameBoolean5 = false
                                        retainSpecifiedTextFromObjectNameBoolean5 = false
                                        retainAllTextFromFileNameBoolean5 = false
                                    )

                                    if currentDropDownListSelectionInteger == 6 then(
                                        replaceAllTextBoolean6 = true
                                        retainSpecifiedTextFromFileNameBoolean6 = false
                                        retainSpecifiedTextFromObjectNameBoolean6 = false
                                        retainAllTextFromFileNameBoolean6 = false
                                    )

                                    if currentDropDownListSelectionInteger == 7 then(
                                        replaceAllTextBoolean7 = true
                                        retainSpecifiedTextFromFileNameBoolean7 = false
                                        retainSpecifiedTextFromObjectNameBoolean7 = false
                                        retainAllTextFromFileNameBoolean7 = false
                                    )

                                    if currentDropDownListSelectionInteger == 8 then(
                                        replaceAllTextBoolean8 = true
                                        retainSpecifiedTextFromFileNameBoolean8 = false
                                        retainSpecifiedTextFromObjectNameBoolean8 = false
                                        retainAllTextFromFileNameBoolean8 = false
                                    )

                                    if currentDropDownListSelectionInteger == 9 then(
                                        replaceAllTextBoolean9 = true
                                        retainSpecifiedTextFromFileNameBoolean9 = false
                                        retainSpecifiedTextFromObjectNameBoolean9 = false
                                        retainAllTextFromFileNameBoolean9 = false
                                    )

                                    if currentDropDownListSelectionInteger == 10 then(
                                        replaceAllTextBoolean10 = true
                                        retainSpecifiedTextFromFileNameBoolean10 = false
                                        retainSpecifiedTextFromObjectNameBoolean10 = false
                                        retainAllTextFromFileNameBoolean10 = false
                                    )

                                    if currentDropDownListSelectionInteger == 11 then(
                                        replaceAllTextBoolean11 = true
                                        retainSpecifiedTextFromFileNameBoolean11 = false
                                        retainSpecifiedTextFromObjectNameBoolean11 = false
                                        retainAllTextFromFileNameBoolean11 = false
                                    )

                                    if currentDropDownListSelectionInteger == 12 then(
                                        replaceAllTextBoolean12 = true
                                        retainSpecifiedTextFromFileNameBoolean12 = false
                                        retainSpecifiedTextFromObjectNameBoolean12 = false
                                        retainAllTextFromFileNameBoolean12 = false
                                    )

                                    if currentDropDownListSelectionInteger == 13 then(
                                        replaceAllTextBoolean13 = true
                                        retainSpecifiedTextFromFileNameBoolean13 = false
                                        retainSpecifiedTextFromObjectNameBoolean13 = false
                                        retainAllTextFromFileNameBoolean13 = false
                                    )

                                    if currentDropDownListSelectionInteger == 14 then(
                                        replaceAllTextBoolean14 = true
                                        retainSpecifiedTextFromFileNameBoolean14 = false
                                        retainSpecifiedTextFromObjectNameBoolean14 = false
                                        retainAllTextFromFileNameBoolean14 = false
                                    )

                                    if currentDropDownListSelectionInteger == 15 then(
                                        replaceAllTextBoolean15 = true
                                        retainSpecifiedTextFromFileNameBoolean15 = false
                                        retainSpecifiedTextFromObjectNameBoolean15 = false
                                        retainAllTextFromFileNameBoolean15 = false
                                    )

                                    if currentDropDownListSelectionInteger == 16 then(
                                        replaceAllTextBoolean16 = true
                                        retainSpecifiedTextFromFileNameBoolean16 = false
                                        retainSpecifiedTextFromObjectNameBoolean16 = false
                                        retainAllTextFromFileNameBoolean16 = false
                                    )

                                    if currentDropDownListSelectionInteger == 17 then(
                                        replaceAllTextBoolean17 = true
                                        retainSpecifiedTextFromFileNameBoolean17 = false
                                        retainSpecifiedTextFromObjectNameBoolean17 = false
                                        retainAllTextFromFileNameBoolean17 = false
                                    )

                                    if currentDropDownListSelectionInteger == 18 then(
                                        replaceAllTextBoolean18 = true
                                        retainSpecifiedTextFromFileNameBoolean18 = false
                                        retainSpecifiedTextFromObjectNameBoolean18 = false
                                        retainAllTextFromFileNameBoolean18 = false
                                    )

                                    if currentDropDownListSelectionInteger == 19 then(
                                        replaceAllTextBoolean19 = true
                                        retainSpecifiedTextFromFileNameBoolean19 = false
                                        retainSpecifiedTextFromObjectNameBoolean19 = false
                                        retainAllTextFromFileNameBoolean19 = false
                                    )

                                    if currentDropDownListSelectionInteger == 20 then(
                                        replaceAllTextBoolean20 = true
                                        retainSpecifiedTextFromFileNameBoolean20 = false
                                        retainSpecifiedTextFromObjectNameBoolean20 = false
                                        retainAllTextFromFileNameBoolean20 = false
                                    )

                                -- Change variable

                                    if currentDropDownListSelectionInteger == 1 then(
                                        phraseToSplitWithEditTextEnabled1 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled1 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled1 = false
                                    )

                                    if currentDropDownListSelectionInteger == 2 then(
                                        phraseToSplitWithEditTextEnabled2 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled2 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled2 = false
                                    )

                                    if currentDropDownListSelectionInteger == 3 then(
                                        phraseToSplitWithEditTextEnabled3 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled3 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled3 = false
                                    )

                                    if currentDropDownListSelectionInteger == 4 then(
                                        phraseToSplitWithEditTextEnabled4 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled4 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled4 = false
                                    )

                                    if currentDropDownListSelectionInteger == 5 then(
                                        phraseToSplitWithEditTextEnabled5 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled5 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled5 = false
                                    )

                                    if currentDropDownListSelectionInteger == 6 then(
                                        phraseToSplitWithEditTextEnabled6 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled6 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled6 = false
                                    )

                                    if currentDropDownListSelectionInteger == 7 then(
                                        phraseToSplitWithEditTextEnabled7 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled7 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled7 = false
                                    )

                                    if currentDropDownListSelectionInteger == 8 then(
                                        phraseToSplitWithEditTextEnabled8 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled8 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled8 = false
                                    )

                                    if currentDropDownListSelectionInteger == 9 then(
                                        phraseToSplitWithEditTextEnabled9 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled9 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled9 = false
                                    )

                                    if currentDropDownListSelectionInteger == 10 then(
                                        phraseToSplitWithEditTextEnabled10 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled10 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled10 = false
                                    )

                                    if currentDropDownListSelectionInteger == 11 then(
                                        phraseToSplitWithEditTextEnabled11 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled11 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled11 = false
                                    )

                                    if currentDropDownListSelectionInteger == 12 then(
                                        phraseToSplitWithEditTextEnabled12 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled12 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled12 = false
                                    )

                                    if currentDropDownListSelectionInteger == 13 then(
                                        phraseToSplitWithEditTextEnabled13 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled13 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled13 = false
                                    )

                                    if currentDropDownListSelectionInteger == 14 then(
                                        phraseToSplitWithEditTextEnabled14 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled14 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled14 = false
                                    )

                                    if currentDropDownListSelectionInteger == 15 then(
                                        phraseToSplitWithEditTextEnabled15 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled15 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled15 = false
                                    )

                                    if currentDropDownListSelectionInteger == 16 then(
                                        phraseToSplitWithEditTextEnabled16 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled16 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled16 = false
                                    )

                                    if currentDropDownListSelectionInteger == 17 then(
                                        phraseToSplitWithEditTextEnabled17 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled17 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled17 = false
                                    )

                                    if currentDropDownListSelectionInteger == 18 then(
                                        phraseToSplitWithEditTextEnabled18 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled18 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled18 = false
                                    )

                                    if currentDropDownListSelectionInteger == 19 then(
                                        phraseToSplitWithEditTextEnabled19 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled19 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled19 = false
                                    )

                                    if currentDropDownListSelectionInteger == 20 then(
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

                                    if currentDropDownListSelectionInteger == 1 then(
                                        retainSpecifiedTextFromFileNameBoolean1 = true
                                        retainSpecifiedTextFromObjectNameBoolean1 = false
                                        replaceAllTextBoolean1 = false
                                        retainAllTextFromFileNameBoolean1 = false
                                    )

                                    if currentDropDownListSelectionInteger == 2 then(
                                        retainSpecifiedTextFromFileNameBoolean2 = true
                                        retainSpecifiedTextFromObjectNameBoolean2 = false
                                        replaceAllTextBoolean2 = false
                                        retainAllTextFromFileNameBoolean2 = false
                                    )

                                    if currentDropDownListSelectionInteger == 3 then(
                                        retainSpecifiedTextFromFileNameBoolean3 = true
                                        retainSpecifiedTextFromObjectNameBoolean3 = false
                                        replaceAllTextBoolean3 = false
                                        retainAllTextFromFileNameBoolean3 = false
                                    )

                                    if currentDropDownListSelectionInteger == 4 then(
                                        retainSpecifiedTextFromFileNameBoolean4 = true
                                        retainSpecifiedTextFromObjectNameBoolean4 = false
                                        replaceAllTextBoolean4 = false
                                        retainAllTextFromFileNameBoolean4 = false
                                    )

                                    if currentDropDownListSelectionInteger == 5 then(
                                        retainSpecifiedTextFromFileNameBoolean5 = true
                                        retainSpecifiedTextFromObjectNameBoolean5 = false
                                        replaceAllTextBoolean5 = false
                                        retainAllTextFromFileNameBoolean5 = false
                                    )

                                    if currentDropDownListSelectionInteger == 6 then(
                                        retainSpecifiedTextFromFileNameBoolean6 = true
                                        retainSpecifiedTextFromObjectNameBoolean6 = false
                                        replaceAllTextBoolean6 = false
                                        retainAllTextFromFileNameBoolean6 = false
                                    )

                                    if currentDropDownListSelectionInteger == 7 then(
                                        retainSpecifiedTextFromFileNameBoolean7 = true
                                        retainSpecifiedTextFromObjectNameBoolean7 = false
                                        replaceAllTextBoolean7 = false
                                        retainAllTextFromFileNameBoolean7 = false
                                    )

                                    if currentDropDownListSelectionInteger == 8 then(
                                        retainSpecifiedTextFromFileNameBoolean8 = true
                                        retainSpecifiedTextFromObjectNameBoolean8 = false
                                        replaceAllTextBoolean8 = false
                                        retainAllTextFromFileNameBoolean8 = false
                                    )

                                    if currentDropDownListSelectionInteger == 9 then(
                                        retainSpecifiedTextFromFileNameBoolean9 = true
                                        retainSpecifiedTextFromObjectNameBoolean9 = false
                                        replaceAllTextBoolean9 = false
                                        retainAllTextFromFileNameBoolean9 = false
                                    )

                                    if currentDropDownListSelectionInteger == 10 then(
                                        retainSpecifiedTextFromFileNameBoolean10 = true
                                        retainSpecifiedTextFromObjectNameBoolean10 = false
                                        replaceAllTextBoolean10 = false
                                        retainAllTextFromFileNameBoolean10 = false
                                    )

                                    if currentDropDownListSelectionInteger == 11 then(
                                        retainSpecifiedTextFromFileNameBoolean11 = true
                                        retainSpecifiedTextFromObjectNameBoolean11 = false
                                        replaceAllTextBoolean11 = false
                                        retainAllTextFromFileNameBoolean11 = false
                                    )

                                    if currentDropDownListSelectionInteger == 12 then(
                                        retainSpecifiedTextFromFileNameBoolean12 = true
                                        retainSpecifiedTextFromObjectNameBoolean12 = false
                                        replaceAllTextBoolean12 = false
                                        retainAllTextFromFileNameBoolean12 = false
                                    )

                                    if currentDropDownListSelectionInteger == 13 then(
                                        retainSpecifiedTextFromFileNameBoolean13 = true
                                        retainSpecifiedTextFromObjectNameBoolean13 = false
                                        replaceAllTextBoolean13 = false
                                        retainAllTextFromFileNameBoolean13 = false
                                    )

                                    if currentDropDownListSelectionInteger == 14 then(
                                        retainSpecifiedTextFromFileNameBoolean14 = true
                                        retainSpecifiedTextFromObjectNameBoolean14 = false
                                        replaceAllTextBoolean14 = false
                                        retainAllTextFromFileNameBoolean14 = false
                                    )

                                    if currentDropDownListSelectionInteger == 15 then(
                                        retainSpecifiedTextFromFileNameBoolean15 = true
                                        retainSpecifiedTextFromObjectNameBoolean15 = false
                                        replaceAllTextBoolean15 = false
                                        retainAllTextFromFileNameBoolean15 = false
                                    )

                                    if currentDropDownListSelectionInteger == 16 then(
                                        retainSpecifiedTextFromFileNameBoolean16 = true
                                        retainSpecifiedTextFromObjectNameBoolean16 = false
                                        replaceAllTextBoolean16 = false
                                        retainAllTextFromFileNameBoolean16 = false
                                    )

                                    if currentDropDownListSelectionInteger == 17 then(
                                        retainSpecifiedTextFromFileNameBoolean17 = true
                                        retainSpecifiedTextFromObjectNameBoolean17 = false
                                        replaceAllTextBoolean17 = false
                                        retainAllTextFromFileNameBoolean17 = false
                                    )

                                    if currentDropDownListSelectionInteger == 18 then(
                                        retainSpecifiedTextFromFileNameBoolean18 = true
                                        retainSpecifiedTextFromObjectNameBoolean18 = false
                                        replaceAllTextBoolean18 = false
                                        retainAllTextFromFileNameBoolean18 = false
                                    )

                                    if currentDropDownListSelectionInteger == 19 then(
                                        retainSpecifiedTextFromFileNameBoolean19 = true
                                        retainSpecifiedTextFromObjectNameBoolean19 = false
                                        replaceAllTextBoolean19 = false
                                        retainAllTextFromFileNameBoolean19 = false
                                    )

                                    if currentDropDownListSelectionInteger == 20 then(
                                        retainSpecifiedTextFromFileNameBoolean20 = true
                                        retainSpecifiedTextFromObjectNameBoolean20 = false
                                        replaceAllTextBoolean20 = false
                                        retainAllTextFromFileNameBoolean20 = false
                                    )

                                -- Change variable

                                    if currentDropDownListSelectionInteger == 1 then(
                                        phraseToSplitWithEditTextEnabled1 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled1 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled1 = true
                                    )

                                    if currentDropDownListSelectionInteger == 2 then(
                                        phraseToSplitWithEditTextEnabled2 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled2 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled2 = true
                                    )

                                    if currentDropDownListSelectionInteger == 3 then(
                                        phraseToSplitWithEditTextEnabled3 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled3 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled3 = true
                                    )

                                    if currentDropDownListSelectionInteger == 4 then(
                                        phraseToSplitWithEditTextEnabled4 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled4 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled4 = true
                                    )

                                    if currentDropDownListSelectionInteger == 5 then(
                                        phraseToSplitWithEditTextEnabled5 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled5 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled5 = true
                                    )

                                    if currentDropDownListSelectionInteger == 6 then(
                                        phraseToSplitWithEditTextEnabled6 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled6 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled6 = true
                                    )

                                    if currentDropDownListSelectionInteger == 7 then(
                                        phraseToSplitWithEditTextEnabled7 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled7 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled7 = true
                                    )

                                    if currentDropDownListSelectionInteger == 8 then(
                                        phraseToSplitWithEditTextEnabled8 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled8 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled8 = true
                                    )

                                    if currentDropDownListSelectionInteger == 9 then(
                                        phraseToSplitWithEditTextEnabled9 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled9 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled9 = true
                                    )

                                    if currentDropDownListSelectionInteger == 10 then(
                                        phraseToSplitWithEditTextEnabled10 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled10 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled10 = true
                                    )

                                    if currentDropDownListSelectionInteger == 11 then(
                                        phraseToSplitWithEditTextEnabled11 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled11 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled11 = true
                                    )

                                    if currentDropDownListSelectionInteger == 12 then(
                                        phraseToSplitWithEditTextEnabled12 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled12 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled12 = true
                                    )

                                    if currentDropDownListSelectionInteger == 13 then(
                                        phraseToSplitWithEditTextEnabled13 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled13 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled13 = true
                                    )

                                    if currentDropDownListSelectionInteger == 14 then(
                                        phraseToSplitWithEditTextEnabled14 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled14 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled14 = true
                                    )

                                    if currentDropDownListSelectionInteger == 15 then(
                                        phraseToSplitWithEditTextEnabled15 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled15 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled15 = true
                                    )

                                    if currentDropDownListSelectionInteger == 16 then(
                                        phraseToSplitWithEditTextEnabled16 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled16 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled16 = true
                                    )

                                    if currentDropDownListSelectionInteger == 17 then(
                                        phraseToSplitWithEditTextEnabled17 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled17 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled17 = true
                                    )

                                    if currentDropDownListSelectionInteger == 18 then(
                                        phraseToSplitWithEditTextEnabled18 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled18 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled18 = true
                                    )

                                    if currentDropDownListSelectionInteger == 19 then(
                                        phraseToSplitWithEditTextEnabled19 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled19 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled19 = true
                                    )

                                    if currentDropDownListSelectionInteger == 20 then(
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

                                    if currentDropDownListSelectionInteger == 1 then(
                                        retainSpecifiedTextFromObjectNameBoolean1 = true
                                        retainSpecifiedTextFromFileNameBoolean1 = false
                                        replaceAllTextBoolean1 = false
                                        retainAllTextFromFileNameBoolean1 = false
                                    )

                                    if currentDropDownListSelectionInteger == 2 then(
                                        retainSpecifiedTextFromObjectNameBoolean2 = true
                                        retainSpecifiedTextFromFileNameBoolean2 = false
                                        replaceAllTextBoolean2 = false
                                        retainAllTextFromFileNameBoolean2 = false
                                    )

                                    if currentDropDownListSelectionInteger == 3 then(
                                        retainSpecifiedTextFromObjectNameBoolean3 = true
                                        retainSpecifiedTextFromFileNameBoolean3 = false
                                        replaceAllTextBoolean3 = false
                                        retainAllTextFromFileNameBoolean3 = false
                                    )

                                    if currentDropDownListSelectionInteger == 4 then(
                                        retainSpecifiedTextFromObjectNameBoolean4 = true
                                        retainSpecifiedTextFromFileNameBoolean4 = false
                                        replaceAllTextBoolean4 = false
                                        retainAllTextFromFileNameBoolean4 = false
                                    )

                                    if currentDropDownListSelectionInteger == 5 then(
                                        retainSpecifiedTextFromObjectNameBoolean5 = true
                                        retainSpecifiedTextFromFileNameBoolean5 = false
                                        replaceAllTextBoolean5 = false
                                        retainAllTextFromFileNameBoolean5 = false
                                    )

                                    if currentDropDownListSelectionInteger == 6 then(
                                        retainSpecifiedTextFromObjectNameBoolean6 = true
                                        retainSpecifiedTextFromFileNameBoolean6 = false
                                        replaceAllTextBoolean6 = false
                                        retainAllTextFromFileNameBoolean6 = false
                                    )

                                    if currentDropDownListSelectionInteger == 7 then(
                                        retainSpecifiedTextFromObjectNameBoolean7 = true
                                        retainSpecifiedTextFromFileNameBoolean7 = false
                                        replaceAllTextBoolean7 = false
                                        retainAllTextFromFileNameBoolean7 = false
                                    )

                                    if currentDropDownListSelectionInteger == 8 then(
                                        retainSpecifiedTextFromObjectNameBoolean8 = true
                                        retainSpecifiedTextFromFileNameBoolean8 = false
                                        replaceAllTextBoolean8 = false
                                        retainAllTextFromFileNameBoolean8 = false
                                    )

                                    if currentDropDownListSelectionInteger == 9 then(
                                        retainSpecifiedTextFromObjectNameBoolean9 = true
                                        retainSpecifiedTextFromFileNameBoolean9 = false
                                        replaceAllTextBoolean9 = false
                                        retainAllTextFromFileNameBoolean9 = false
                                    )

                                    if currentDropDownListSelectionInteger == 10 then(
                                        retainSpecifiedTextFromObjectNameBoolean10 = true
                                        retainSpecifiedTextFromFileNameBoolean10 = false
                                        replaceAllTextBoolean10 = false
                                        retainAllTextFromFileNameBoolean10 = false
                                    )

                                    if currentDropDownListSelectionInteger == 11 then(
                                        retainSpecifiedTextFromObjectNameBoolean11 = true
                                        retainSpecifiedTextFromFileNameBoolean11 = false
                                        replaceAllTextBoolean11 = false
                                        retainAllTextFromFileNameBoolean11 = false
                                    )

                                    if currentDropDownListSelectionInteger == 12 then(
                                        retainSpecifiedTextFromObjectNameBoolean12 = true
                                        retainSpecifiedTextFromFileNameBoolean12 = false
                                        replaceAllTextBoolean12 = false
                                        retainAllTextFromFileNameBoolean12 = false
                                    )

                                    if currentDropDownListSelectionInteger == 13 then(
                                        retainSpecifiedTextFromObjectNameBoolean13 = true
                                        retainSpecifiedTextFromFileNameBoolean13 = false
                                        replaceAllTextBoolean13 = false
                                        retainAllTextFromFileNameBoolean13 = false
                                    )

                                    if currentDropDownListSelectionInteger == 14 then(
                                        retainSpecifiedTextFromObjectNameBoolean14 = true
                                        retainSpecifiedTextFromFileNameBoolean14 = false
                                        replaceAllTextBoolean14 = false
                                        retainAllTextFromFileNameBoolean14 = false
                                    )

                                    if currentDropDownListSelectionInteger == 15 then(
                                        retainSpecifiedTextFromObjectNameBoolean15 = true
                                        retainSpecifiedTextFromFileNameBoolean15 = false
                                        replaceAllTextBoolean15 = false
                                        retainAllTextFromFileNameBoolean15 = false
                                    )

                                    if currentDropDownListSelectionInteger == 16 then(
                                        retainSpecifiedTextFromObjectNameBoolean16 = true
                                        retainSpecifiedTextFromFileNameBoolean16 = false
                                        replaceAllTextBoolean16 = false
                                        retainAllTextFromFileNameBoolean16 = false
                                    )

                                    if currentDropDownListSelectionInteger == 17 then(
                                        retainSpecifiedTextFromObjectNameBoolean17 = true
                                        retainSpecifiedTextFromFileNameBoolean17 = false
                                        replaceAllTextBoolean17 = false
                                        retainAllTextFromFileNameBoolean17 = false
                                    )

                                    if currentDropDownListSelectionInteger == 18 then(
                                        retainSpecifiedTextFromObjectNameBoolean18 = true
                                        retainSpecifiedTextFromFileNameBoolean18 = false
                                        replaceAllTextBoolean18 = false
                                        retainAllTextFromFileNameBoolean18 = false
                                    )

                                    if currentDropDownListSelectionInteger == 19 then(
                                        retainSpecifiedTextFromObjectNameBoolean19 = true
                                        retainSpecifiedTextFromFileNameBoolean19 = false
                                        replaceAllTextBoolean19 = false
                                        retainAllTextFromFileNameBoolean19 = false
                                    )

                                    if currentDropDownListSelectionInteger == 20 then(
                                        retainSpecifiedTextFromObjectNameBoolean = true
                                        retainSpecifiedTextFromFileNameBoolean20 = false
                                        replaceAllTextBoolean20 = false
                                        retainAllTextFromFileNameBoolean20 = false
                                    )

                                -- Change variable

                                    if currentDropDownListSelectionInteger == 1 then(
                                        phraseToSplitWithEditTextEnabled1 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled1 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled1 = true
                                    )

                                    if currentDropDownListSelectionInteger == 2 then(
                                        phraseToSplitWithEditTextEnabled2 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled2 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled2 = true
                                    )

                                    if currentDropDownListSelectionInteger == 3 then(
                                        phraseToSplitWithEditTextEnabled3 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled3 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled3 = true
                                    )

                                    if currentDropDownListSelectionInteger == 4 then(
                                        phraseToSplitWithEditTextEnabled4 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled4 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled4 = true
                                    )

                                    if currentDropDownListSelectionInteger == 5 then(
                                        phraseToSplitWithEditTextEnabled5 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled5 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled5 = true
                                    )

                                    if currentDropDownListSelectionInteger == 6 then(
                                        phraseToSplitWithEditTextEnabled6 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled6 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled6 = true
                                    )

                                    if currentDropDownListSelectionInteger == 7 then(
                                        phraseToSplitWithEditTextEnabled7 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled7 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled7 = true
                                    )

                                    if currentDropDownListSelectionInteger == 8 then(
                                        phraseToSplitWithEditTextEnabled8 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled8 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled8 = true
                                    )

                                    if currentDropDownListSelectionInteger == 9 then(
                                        phraseToSplitWithEditTextEnabled9 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled9 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled9 = true
                                    )

                                    if currentDropDownListSelectionInteger == 10 then(
                                        phraseToSplitWithEditTextEnabled10 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled10 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled10 = true
                                    )

                                    if currentDropDownListSelectionInteger == 11 then(
                                        phraseToSplitWithEditTextEnabled11 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled11 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled11 = true
                                    )

                                    if currentDropDownListSelectionInteger == 12 then(
                                        phraseToSplitWithEditTextEnabled12 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled12 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled12 = true
                                    )

                                    if currentDropDownListSelectionInteger == 13 then(
                                        phraseToSplitWithEditTextEnabled13 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled13 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled13 = true
                                    )

                                    if currentDropDownListSelectionInteger == 14 then(
                                        phraseToSplitWithEditTextEnabled14 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled14 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled14 = true
                                    )

                                    if currentDropDownListSelectionInteger == 15 then(
                                        phraseToSplitWithEditTextEnabled15 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled15 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled15 = true
                                    )

                                    if currentDropDownListSelectionInteger == 16 then(
                                        phraseToSplitWithEditTextEnabled16 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled16 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled16 = true
                                    )

                                    if currentDropDownListSelectionInteger == 17 then(
                                        phraseToSplitWithEditTextEnabled17 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled17 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled17 = true
                                    )

                                    if currentDropDownListSelectionInteger == 18 then(
                                        phraseToSplitWithEditTextEnabled18 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled18 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled18 = true
                                    )

                                    if currentDropDownListSelectionInteger == 19 then(
                                        phraseToSplitWithEditTextEnabled19 = true
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled19 = true
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled19 = true
                                    )

                                    if currentDropDownListSelectionInteger == 20 then(
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

                                    if currentDropDownListSelectionInteger == 1 then(
                                        retainAllTextFromFileNameBoolean1 = true
                                        ReplaceAllTextBoolean1 = false
                                        retainSpecifiedTextFromFileNameBoolean1 = false
                                        retainSpecifiedTextFromObjectNameBoolean1 = false
                                    )

                                    if currentDropDownListSelectionInteger == 2 then(
                                        retainAllTextFromFileNameBoolean2 = true
                                        ReplaceAllTextBoolean2 = false
                                        retainSpecifiedTextFromFileNameBoolean2 = false
                                        retainSpecifiedTextFromObjectNameBoolean2 = false
                                    )

                                    if currentDropDownListSelectionInteger == 3 then(
                                        retainAllTextFromFileNameBoolean3 = true
                                        ReplaceAllTextBoolean3 = false
                                        retainSpecifiedTextFromFileNameBoolean3 = false
                                        retainSpecifiedTextFromObjectNameBoolean3 = false
                                    )

                                    if currentDropDownListSelectionInteger == 4 then(
                                        retainAllTextFromFileNameBoolean4 = true
                                        ReplaceAllTextBoolean4 = false
                                        retainSpecifiedTextFromFileNameBoolean4 = false
                                        retainSpecifiedTextFromObjectNameBoolean4 = false
                                    )

                                    if currentDropDownListSelectionInteger == 5 then(
                                        retainAllTextFromFileNameBoolean5 = true
                                        ReplaceAllTextBoolean5 = false
                                        retainSpecifiedTextFromFileNameBoolean5 = false
                                        retainSpecifiedTextFromObjectNameBoolean5 = false
                                    )

                                    if currentDropDownListSelectionInteger == 6 then(
                                        retainAllTextFromFileNameBoolean6 = true
                                        ReplaceAllTextBoolean6 = false
                                        retainSpecifiedTextFromFileNameBoolean6 = false
                                        retainSpecifiedTextFromObjectNameBoolean6 = false
                                    )

                                    if currentDropDownListSelectionInteger == 7 then(
                                        retainAllTextFromFileNameBoolean7 = true
                                        ReplaceAllTextBoolean7 = false
                                        retainSpecifiedTextFromFileNameBoolean7 = false
                                        retainSpecifiedTextFromObjectNameBoolean7 = false
                                    )

                                    if currentDropDownListSelectionInteger == 8 then(
                                        retainAllTextFromFileNameBoolean8 = true
                                        ReplaceAllTextBoolean8 = false
                                        retainSpecifiedTextFromFileNameBoolean8 = false
                                        retainSpecifiedTextFromObjectNameBoolean8 = false
                                    )

                                    if currentDropDownListSelectionInteger == 9 then(
                                        retainAllTextFromFileNameBoolean9 = true
                                        ReplaceAllTextBoolean9 = false
                                        retainSpecifiedTextFromFileNameBoolean9 = false
                                        retainSpecifiedTextFromObjectNameBoolean9 = false
                                    )

                                    if currentDropDownListSelectionInteger == 10 then(
                                        retainAllTextFromFileNameBoolean10 = true
                                        ReplaceAllTextBoolean10 = false
                                        retainSpecifiedTextFromFileNameBoolean10 = false
                                        retainSpecifiedTextFromObjectNameBoolean10 = false
                                    )

                                    if currentDropDownListSelectionInteger == 11 then(
                                        retainAllTextFromFileNameBoolean11 = true
                                        ReplaceAllTextBoolean11 = false
                                        retainSpecifiedTextFromFileNameBoolean11 = false
                                        retainSpecifiedTextFromObjectNameBoolean11 = false
                                    )

                                    if currentDropDownListSelectionInteger == 12 then(
                                        retainAllTextFromFileNameBoolean12 = true
                                        ReplaceAllTextBoolean12 = false
                                        retainSpecifiedTextFromFileNameBoolean12 = false
                                        retainSpecifiedTextFromObjectNameBoolean12 = false
                                    )

                                    if currentDropDownListSelectionInteger == 13 then(
                                        retainAllTextFromFileNameBoolean13 = true
                                        ReplaceAllTextBoolean13 = false
                                        retainSpecifiedTextFromFileNameBoolean13 = false
                                        retainSpecifiedTextFromObjectNameBoolean13 = false
                                    )

                                    if currentDropDownListSelectionInteger == 14 then(
                                        retainAllTextFromFileNameBoolean14 = true
                                        ReplaceAllTextBoolean14 = false
                                        retainSpecifiedTextFromFileNameBoolean14 = false
                                        retainSpecifiedTextFromObjectNameBoolean14 = false
                                    )

                                    if currentDropDownListSelectionInteger == 15 then(
                                        retainAllTextFromFileNameBoolean15 = true
                                        ReplaceAllTextBoolean15 = false
                                        retainSpecifiedTextFromFileNameBoolean15 = false
                                        retainSpecifiedTextFromObjectNameBoolean15 = false
                                    )

                                    if currentDropDownListSelectionInteger == 16 then(
                                        retainAllTextFromFileNameBoolean16 = true
                                        ReplaceAllTextBoolean16 = false
                                        retainSpecifiedTextFromFileNameBoolean16 = false
                                        retainSpecifiedTextFromObjectNameBoolean16 = false
                                    )

                                    if currentDropDownListSelectionInteger == 17 then(
                                        retainAllTextFromFileNameBoolean17 = true
                                        ReplaceAllTextBoolean17 = false
                                        retainSpecifiedTextFromFileNameBoolean17 = false
                                        retainSpecifiedTextFromObjectNameBoolean17 = false
                                    )

                                    if currentDropDownListSelectionInteger == 18 then(
                                        retainAllTextFromFileNameBoolean18 = true
                                        ReplaceAllTextBoolean18 = false
                                        retainSpecifiedTextFromFileNameBoolean18 = false
                                        retainSpecifiedTextFromObjectNameBoolean18 = false
                                    )

                                    if currentDropDownListSelectionInteger == 19 then(
                                        retainAllTextFromFileNameBoolean19 = true
                                        ReplaceAllTextBoolean19 = false
                                        retainSpecifiedTextFromFileNameBoolean19 = false
                                        retainSpecifiedTextFromObjectNameBoolean19 = false
                                    )

                                    if currentDropDownListSelectionInteger == 20 then(
                                        retainAllTextFromFileNameBoolean20 = true
                                        ReplaceAllTextBoolean20 = false
                                        retainSpecifiedTextFromFileNameBoolean20 = false
                                        retainSpecifiedTextFromObjectNameBoolean20 = false
                                    )

                                -- Change variable

                                    if currentDropDownListSelectionInteger == 1 then(
                                        phraseToSplitWithEditTextEnabled1 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled1 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled1 = false
                                    )

                                    if currentDropDownListSelectionInteger == 2 then(
                                        phraseToSplitWithEditTextEnabled2 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled2 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled2 = false
                                    )

                                    if currentDropDownListSelectionInteger == 3 then(
                                        phraseToSplitWithEditTextEnabled3 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled3 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled3 = false
                                    )

                                    if currentDropDownListSelectionInteger == 4 then(
                                        phraseToSplitWithEditTextEnabled4 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled4 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled4 = false
                                    )

                                    if currentDropDownListSelectionInteger == 5 then(
                                        phraseToSplitWithEditTextEnabled5 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled5 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled5 = false
                                    )

                                    if currentDropDownListSelectionInteger == 6 then(
                                        phraseToSplitWithEditTextEnabled6 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled6 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled6 = false
                                    )

                                    if currentDropDownListSelectionInteger == 7 then(
                                        phraseToSplitWithEditTextEnabled7 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled7 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled7 = false
                                    )

                                    if currentDropDownListSelectionInteger == 8 then(
                                        phraseToSplitWithEditTextEnabled8 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled8 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled8 = false
                                    )

                                    if currentDropDownListSelectionInteger == 9 then(
                                        phraseToSplitWithEditTextEnabled9 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled9 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled9 = false
                                    )

                                    if currentDropDownListSelectionInteger == 10 then(
                                        phraseToSplitWithEditTextEnabled10 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled10 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled10 = false
                                    )

                                    if currentDropDownListSelectionInteger == 11 then(
                                        phraseToSplitWithEditTextEnabled11 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled11 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled11 = false
                                    )

                                    if currentDropDownListSelectionInteger == 12 then(
                                        phraseToSplitWithEditTextEnabled12 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled12 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled12 = false
                                    )

                                    if currentDropDownListSelectionInteger == 13 then(
                                        phraseToSplitWithEditTextEnabled13 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled13 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled13 = false
                                    )

                                    if currentDropDownListSelectionInteger == 14 then(
                                        phraseToSplitWithEditTextEnabled14 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled14 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled14 = false
                                    )

                                    if currentDropDownListSelectionInteger == 15 then(
                                        phraseToSplitWithEditTextEnabled15 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled15 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled15 = false
                                    )

                                    if currentDropDownListSelectionInteger == 16 then(
                                        phraseToSplitWithEditTextEnabled16 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled16 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled16 = false
                                    )

                                    if currentDropDownListSelectionInteger == 17 then(
                                        phraseToSplitWithEditTextEnabled17 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled17 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled17 = false
                                    )

                                    if currentDropDownListSelectionInteger == 18 then(
                                        phraseToSplitWithEditTextEnabled18 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled18 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled18 = false
                                    )

                                    if currentDropDownListSelectionInteger == 19 then(
                                        phraseToSplitWithEditTextEnabled19 = false
                                        numberOfIndicesToRemoveFromStartSpinnerEnabled19 = false
                                        numberOfIndicesToRemoveFromEndSpinnerEnabled19 = false
                                    )

                                    if currentDropDownListSelectionInteger == 20 then(
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

                                if currentDropDownListSelectionInteger == 1 then(
                                    phraseToSplitWithString1 = txt
                                )

                                if currentDropDownListSelectionInteger == 2 then(
                                    phraseToSplitWithString2 = txt
                                )

                                if currentDropDownListSelectionInteger == 3 then(
                                    phraseToSplitWithString3 = txt
                                )

                                if currentDropDownListSelectionInteger == 4 then(
                                    phraseToSplitWithString4 = txt
                                )

                                if currentDropDownListSelectionInteger == 5 then(
                                    phraseToSplitWithString5 = txt
                                )

                                if currentDropDownListSelectionInteger == 6 then(
                                    phraseToSplitWithString6 = txt
                                )

                                if currentDropDownListSelectionInteger == 7 then(
                                    phraseToSplitWithString7 = txt
                                )

                                if currentDropDownListSelectionInteger == 8 then(
                                    phraseToSplitWithString8 = txt
                                )

                                if currentDropDownListSelectionInteger == 9 then(
                                    phraseToSplitWithString9 = txt
                                )

                                if currentDropDownListSelectionInteger == 10 then(
                                    phraseToSplitWithString10 = txt
                                )

                                if currentDropDownListSelectionInteger == 11 then(
                                    phraseToSplitWithString11 = txt
                                )

                                if currentDropDownListSelectionInteger == 12 then(
                                    phraseToSplitWithString12 = txt
                                )

                                if currentDropDownListSelectionInteger == 13 then(
                                    phraseToSplitWithString13 = txt
                                )

                                if currentDropDownListSelectionInteger == 14 then(
                                    phraseToSplitWithString14 = txt
                                )

                                if currentDropDownListSelectionInteger == 15 then(
                                    phraseToSplitWithString15 = txt
                                )

                                if currentDropDownListSelectionInteger == 16 then(
                                    phraseToSplitWithString16 = txt
                                )

                                if currentDropDownListSelectionInteger == 17 then(
                                    phraseToSplitWithString17 = txt
                                )

                                if currentDropDownListSelectionInteger == 18 then(
                                    phraseToSplitWithString18 = txt
                                )

                                if currentDropDownListSelectionInteger == 19 then(
                                    phraseToSplitWithString19 = txt
                                )

                                if currentDropDownListSelectionInteger == 20 then(
                                    phraseToSplitWithString20 = txt
                                )
                        )else(
                            -- Change variable

                                if currentDropDownListSelectionInteger == 1 then(
                                    phraseToSplitWithString1 = ""
                                )

                                if currentDropDownListSelectionInteger == 2 then(
                                    phraseToSplitWithString2 = ""
                                )

                                if currentDropDownListSelectionInteger == 3 then(
                                    phraseToSplitWithString3 = ""
                                )

                                if currentDropDownListSelectionInteger == 4 then(
                                    phraseToSplitWithString4 = ""
                                )

                                if currentDropDownListSelectionInteger == 5 then(
                                    phraseToSplitWithString5 = ""
                                )

                                if currentDropDownListSelectionInteger == 6 then(
                                    phraseToSplitWithString6 = ""
                                )

                                if currentDropDownListSelectionInteger == 7 then(
                                    phraseToSplitWithString7 = ""
                                )

                                if currentDropDownListSelectionInteger == 8 then(
                                    phraseToSplitWithString8 = ""
                                )

                                if currentDropDownListSelectionInteger == 9 then(
                                    phraseToSplitWithString9 = ""
                                )

                                if currentDropDownListSelectionInteger == 10 then(
                                    phraseToSplitWithString10 = ""
                                )

                                if currentDropDownListSelectionInteger == 11 then(
                                    phraseToSplitWithString11 = ""
                                )

                                if currentDropDownListSelectionInteger == 12 then(
                                    phraseToSplitWithString12 = ""
                                )

                                if currentDropDownListSelectionInteger == 13 then(
                                    phraseToSplitWithString13 = ""
                                )

                                if currentDropDownListSelectionInteger == 14 then(
                                    phraseToSplitWithString14 = ""
                                )

                                if currentDropDownListSelectionInteger == 15 then(
                                    phraseToSplitWithString15 = ""
                                )

                                if currentDropDownListSelectionInteger == 16 then(
                                    phraseToSplitWithString16 = ""
                                )

                                if currentDropDownListSelectionInteger == 17 then(
                                    phraseToSplitWithString17 = ""
                                )

                                if currentDropDownListSelectionInteger == 18 then(
                                    phraseToSplitWithString18 = ""
                                )

                                if currentDropDownListSelectionInteger == 19 then(
                                    phraseToSplitWithString19 = ""
                                )

                                if currentDropDownListSelectionInteger == 20 then(
                                    phraseToSplitWithString20 = ""
                                )
                        )
                    )

                    on numberOfIndicesToRemoveFromStartSpinner changed int do(
                        -- Change variable

                            if currentDropDownListSelectionInteger == 1 then(
                                numberOfIndicesToRemoveFromStartInteger1 = int
                            )

                            if currentDropDownListSelectionInteger == 2 then(
                                numberOfIndicesToRemoveFromStartInteger2 = int
                            )

                            if currentDropDownListSelectionInteger == 3 then(
                                numberOfIndicesToRemoveFromStartInteger3 = int
                            )

                            if currentDropDownListSelectionInteger == 4 then(
                                numberOfIndicesToRemoveFromStartInteger4 = int
                            )

                            if currentDropDownListSelectionInteger == 5 then(
                                numberOfIndicesToRemoveFromStartInteger5 = int
                            )

                            if currentDropDownListSelectionInteger == 6 then(
                                numberOfIndicesToRemoveFromStartInteger6 = int
                            )

                            if currentDropDownListSelectionInteger == 7 then(
                                numberOfIndicesToRemoveFromStartInteger7 = int
                            )

                            if currentDropDownListSelectionInteger == 8 then(
                                numberOfIndicesToRemoveFromStartInteger8 = int
                            )

                            if currentDropDownListSelectionInteger == 9 then(
                                numberOfIndicesToRemoveFromStartInteger9 = int
                            )

                            if currentDropDownListSelectionInteger == 10 then(
                                numberOfIndicesToRemoveFromStartInteger10 = int
                            )

                            if currentDropDownListSelectionInteger == 11 then(
                                numberOfIndicesToRemoveFromStartInteger11 = int
                            )

                            if currentDropDownListSelectionInteger == 12 then(
                                numberOfIndicesToRemoveFromStartInteger12 = int
                            )

                            if currentDropDownListSelectionInteger == 13 then(
                                numberOfIndicesToRemoveFromStartInteger13 = int
                            )

                            if currentDropDownListSelectionInteger == 14 then(
                                numberOfIndicesToRemoveFromStartInteger14 = int
                            )

                            if currentDropDownListSelectionInteger == 15 then(
                                numberOfIndicesToRemoveFromStartInteger15 = int
                            )

                            if currentDropDownListSelectionInteger == 16 then(
                                numberOfIndicesToRemoveFromStartInteger16 = int
                            )

                            if currentDropDownListSelectionInteger == 17 then(
                                numberOfIndicesToRemoveFromStartInteger17 = int
                            )

                            if currentDropDownListSelectionInteger == 18 then(
                                numberOfIndicesToRemoveFromStartInteger18 = int
                            )

                            if currentDropDownListSelectionInteger == 19 then(
                                numberOfIndicesToRemoveFromStartInteger19 = int
                            )

                            if currentDropDownListSelectionInteger == 20 then(
                                numberOfIndicesToRemoveFromStartInteger20 = int
                            )
                    )

                    on numberOfIndicesToRemoveFromEndSpinner changed int do(
                        -- Change variable

                            if currentDropDownListSelectionInteger == 1 then(
                                numberOfIndicesToRemoveFromEndInteger1 = int
                            )

                            if currentDropDownListSelectionInteger == 2 then(
                                numberOfIndicesToRemoveFromEndInteger2 = int
                            )

                            if currentDropDownListSelectionInteger == 3 then(
                                numberOfIndicesToRemoveFromEndInteger3 = int
                            )

                            if currentDropDownListSelectionInteger == 4 then(
                                numberOfIndicesToRemoveFromEndInteger4 = int
                            )

                            if currentDropDownListSelectionInteger == 5 then(
                                numberOfIndicesToRemoveFromEndInteger5 = int
                            )

                            if currentDropDownListSelectionInteger == 6 then(
                                numberOfIndicesToRemoveFromEndInteger6 = int
                            )

                            if currentDropDownListSelectionInteger == 7 then(
                                numberOfIndicesToRemoveFromEndInteger7 = int
                            )

                            if currentDropDownListSelectionInteger == 8 then(
                                numberOfIndicesToRemoveFromEndInteger8 = int
                            )

                            if currentDropDownListSelectionInteger == 9 then(
                                numberOfIndicesToRemoveFromEndInteger9 = int
                            )

                            if currentDropDownListSelectionInteger == 10 then(
                                numberOfIndicesToRemoveFromEndInteger10 = int
                            )

                            if currentDropDownListSelectionInteger == 11 then(
                                numberOfIndicesToRemoveFromEndInteger11 = int
                            )

                            if currentDropDownListSelectionInteger == 12 then(
                                numberOfIndicesToRemoveFromEndInteger12 = int
                            )

                            if currentDropDownListSelectionInteger == 13 then(
                                numberOfIndicesToRemoveFromEndInteger13 = int
                            )

                            if currentDropDownListSelectionInteger == 14 then(
                                numberOfIndicesToRemoveFromEndInteger14 = int
                            )

                            if currentDropDownListSelectionInteger == 15 then(
                                numberOfIndicesToRemoveFromEndInteger15 = int
                            )

                            if currentDropDownListSelectionInteger == 16 then(
                                numberOfIndicesToRemoveFromEndInteger16 = int
                            )

                            if currentDropDownListSelectionInteger == 17 then(
                                numberOfIndicesToRemoveFromEndInteger17 = int
                            )

                            if currentDropDownListSelectionInteger == 18 then(
                                numberOfIndicesToRemoveFromEndInteger18 = int
                            )

                            if currentDropDownListSelectionInteger == 19 then(
                                numberOfIndicesToRemoveFromEndInteger19 = int
                            )

                            if currentDropDownListSelectionInteger == 20 then(
                                numberOfIndicesToRemoveFromEndInteger20 = int
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

                                    saveEachObjectSeparatelyBooleanArray = #(saveEachObjectSeparatelyBoolean1, saveEachObjectSeparatelyBoolean2, saveEachObjectSeparatelyBoolean3, saveEachObjectSeparatelyBoolean4, saveEachObjectSeparatelyBoolean5, saveEachObjectSeparatelyBoolean6, saveEachObjectSeparatelyBoolean7, saveEachObjectSeparatelyBoolean8, saveEachObjectSeparatelyBoolean9, saveEachObjectSeparatelyBoolean10, saveEachObjectSeparatelyBoolean11, saveEachObjectSeparatelyBoolean12, saveEachObjectSeparatelyBoolean13, saveEachObjectSeparatelyBoolean14, saveEachObjectSeparatelyBoolean15, saveEachObjectSeparatelyBoolean16, saveEachObjectSeparatelyBoolean17, saveEachObjectSeparatelyBoolean18, saveEachObjectSeparatelyBoolean19, saveEachObjectSeparatelyBoolean20)

                                    attachObjectsBooleanArray = #(attachObjectsBoolean1, attachObjectsBoolean2, attachObjectsBoolean3, attachObjectsBoolean4, attachObjectsBoolean5, attachObjectsBoolean6, attachObjectsBoolean7, attachObjectsBoolean8, attachObjectsBoolean9, attachObjectsBoolean10, attachObjectsBoolean11, attachObjectsBoolean12, attachObjectsBoolean13, attachObjectsBoolean14, attachObjectsBoolean15, attachObjectsBoolean16, attachObjectsBoolean17, attachObjectsBoolean18, attachObjectsBoolean19, attachObjectsBoolean20)

                                    proxyObjectsBooleanArray = #(proxyObjectsBoolean1, proxyObjectsBoolean2, proxyObjectsBoolean3, proxyObjectsBoolean4, proxyObjectsBoolean5, proxyObjectsBoolean6, proxyObjectsBoolean7, proxyObjectsBoolean8, proxyObjectsBoolean9, proxyObjectsBoolean10, proxyObjectsBoolean11, proxyObjectsBoolean12, proxyObjectsBoolean13, proxyObjectsBoolean14, proxyObjectsBoolean15, proxyObjectsBoolean16, proxyObjectsBoolean17, proxyObjectsBoolean18, proxyObjectsBoolean19, proxyObjectsBoolean20)

                                    facesNumberIntegerArray = #(facesNumberInteger1, facesNumberInteger2, facesNumberInteger3, facesNumberInteger4, facesNumberInteger5, facesNumberInteger6, facesNumberInteger7, facesNumberInteger8, facesNumberInteger9, facesNumberInteger10, facesNumberInteger11, facesNumberInteger12, facesNumberInteger13, facesNumberInteger14, facesNumberInteger15, facesNumberInteger16, facesNumberInteger17, facesNumberInteger18, facesNumberInteger19, facesNumberInteger20)

                                    includeCamerasBooleanArray = #(includeCamerasBoolean1, includeCamerasBoolean2, includeCamerasBoolean3, includeCamerasBoolean4, includeCamerasBoolean5, includeCamerasBoolean6, includeCamerasBoolean7, includeCamerasBoolean8, includeCamerasBoolean9, includeCamerasBoolean10, includeCamerasBoolean11, includeCamerasBoolean12, includeCamerasBoolean13, includeCamerasBoolean14, includeCamerasBoolean15, includeCamerasBoolean16, includeCamerasBoolean17, includeCamerasBoolean18, includeCamerasBoolean19, includeCamerasBoolean20)

                                    includeLightsBooleanArray = #(includeLightsBoolean1, includeLightsBoolean2, includeLightsBoolean3, includeLightsBoolean4, includeLightsBoolean5, includeLightsBoolean6, includeLightsBoolean7, includeLightsBoolean8, includeLightsBoolean9, includeLightsBoolean10, includeLightsBoolean11, includeLightsBoolean12, includeLightsBoolean13, includeLightsBoolean14, includeLightsBoolean15, includeLightsBoolean16, includeLightsBoolean17, includeLightsBoolean18, includeLightsBoolean19, includeLightsBoolean20)

                                    replaceAllTextBooleanArray = #(replaceAllTextBoolean1, replaceAllTextBoolean2, replaceAllTextBoolean3, replaceAllTextBoolean4, replaceAllTextBoolean5, replaceAllTextBoolean6, replaceAllTextBoolean7, replaceAllTextBoolean8, replaceAllTextBoolean9, replaceAllTextBoolean10, replaceAllTextBoolean11, replaceAllTextBoolean12, replaceAllTextBoolean13, replaceAllTextBoolean14, replaceAllTextBoolean15, replaceAllTextBoolean16, replaceAllTextBoolean17, replaceAllTextBoolean18, replaceAllTextBoolean19, replaceAllTextBoolean20)

                                    retainSpecifiedTextFromFileNameBooleanArray = #(retainSpecifiedTextFromFileNameBoolean1, retainSpecifiedTextFromFileNameBoolean2, retainSpecifiedTextFromFileNameBoolean3, retainSpecifiedTextFromFileNameBoolean4, retainSpecifiedTextFromFileNameBoolean5, retainSpecifiedTextFromFileNameBoolean6, retainSpecifiedTextFromFileNameBoolean7, retainSpecifiedTextFromFileNameBoolean8, retainSpecifiedTextFromFileNameBoolean9, retainSpecifiedTextFromFileNameBoolean10, retainSpecifiedTextFromFileNameBoolean11, retainSpecifiedTextFromFileNameBoolean12, retainSpecifiedTextFromFileNameBoolean13, retainSpecifiedTextFromFileNameBoolean14, retainSpecifiedTextFromFileNameBoolean15, retainSpecifiedTextFromFileNameBoolean16, retainSpecifiedTextFromFileNameBoolean17, retainSpecifiedTextFromFileNameBoolean18, retainSpecifiedTextFromFileNameBoolean19, retainSpecifiedTextFromFileNameBoolean20)

                                    retainSpecifiedTextFromObjectNameBooleanArray = #(retainSpecifiedTextFromObjectNameBoolean1, retainSpecifiedTextFromObjectNameBoolean2, retainSpecifiedTextFromObjectNameBoolean3, retainSpecifiedTextFromObjectNameBoolean4, retainSpecifiedTextFromObjectNameBoolean5, retainSpecifiedTextFromObjectNameBoolean6, retainSpecifiedTextFromObjectNameBoolean7, retainSpecifiedTextFromObjectNameBoolean8, retainSpecifiedTextFromObjectNameBoolean9, retainSpecifiedTextFromObjectNameBoolean10, retainSpecifiedTextFromObjectNameBoolean11, retainSpecifiedTextFromObjectNameBoolean12, retainSpecifiedTextFromObjectNameBoolean13, retainSpecifiedTextFromObjectNameBoolean14, retainSpecifiedTextFromObjectNameBoolean15, retainSpecifiedTextFromObjectNameBoolean16, retainSpecifiedTextFromObjectNameBoolean17, retainSpecifiedTextFromObjectNameBoolean18, retainSpecifiedTextFromObjectNameBoolean19, retainSpecifiedTextFromObjectNameBoolean20)

                                    retainAllTextFromFileNameBooleanArray = #(retainAllTextFromFileNameBoolean1, retainAllTextFromFileNameBoolean2, retainAllTextFromFileNameBoolean3, retainAllTextFromFileNameBoolean4, retainAllTextFromFileNameBoolean5, retainAllTextFromFileNameBoolean6, retainAllTextFromFileNameBoolean7, retainAllTextFromFileNameBoolean8, retainAllTextFromFileNameBoolean9, retainAllTextFromFileNameBoolean10, retainAllTextFromFileNameBoolean11, retainAllTextFromFileNameBoolean12, retainAllTextFromFileNameBoolean13, retainAllTextFromFileNameBoolean14, retainAllTextFromFileNameBoolean15, retainAllTextFromFileNameBoolean16, retainAllTextFromFileNameBoolean17, retainAllTextFromFileNameBoolean18, retainAllTextFromFileNameBoolean19, retainAllTextFromFileNameBoolean20)

                                    phraseToSplitWithStringArray = #(phraseToSplitWithString1, phraseToSplitWithString2, phraseToSplitWithString3, phraseToSplitWithString4, phraseToSplitWithString5, phraseToSplitWithString6, phraseToSplitWithString7, phraseToSplitWithString8, phraseToSplitWithString9, phraseToSplitWithString10, phraseToSplitWithString11, phraseToSplitWithString12, phraseToSplitWithString13, phraseToSplitWithString14, phraseToSplitWithString15, phraseToSplitWithString16, phraseToSplitWithString17, phraseToSplitWithString18, phraseToSplitWithString19, phraseToSplitWithString20)

                                    numberOfIndicesToRemoveFromStartIntegerArray = #(numberOfIndicesToRemoveFromStartInteger1, numberOfIndicesToRemoveFromStartInteger2, numberOfIndicesToRemoveFromStartInteger3, numberOfIndicesToRemoveFromStartInteger4, numberOfIndicesToRemoveFromStartInteger5, numberOfIndicesToRemoveFromStartInteger6, numberOfIndicesToRemoveFromStartInteger7, numberOfIndicesToRemoveFromStartInteger8, numberOfIndicesToRemoveFromStartInteger9, numberOfIndicesToRemoveFromStartInteger10, numberOfIndicesToRemoveFromStartInteger11, numberOfIndicesToRemoveFromStartInteger12, numberOfIndicesToRemoveFromStartInteger13, numberOfIndicesToRemoveFromStartInteger14, numberOfIndicesToRemoveFromStartInteger15, numberOfIndicesToRemoveFromStartInteger16, numberOfIndicesToRemoveFromStartInteger17, numberOfIndicesToRemoveFromStartInteger18, numberOfIndicesToRemoveFromStartInteger19, numberOfIndicesToRemoveFromStartInteger20)

                                    numberOfIndicesToRemoveFromEndIntegerArray = #(numberOfIndicesToRemoveFromEndInteger1, numberOfIndicesToRemoveFromEndInteger2, numberOfIndicesToRemoveFromEndInteger3, numberOfIndicesToRemoveFromEndInteger4, numberOfIndicesToRemoveFromEndInteger5, numberOfIndicesToRemoveFromEndInteger6, numberOfIndicesToRemoveFromEndInteger7, numberOfIndicesToRemoveFromEndInteger8, numberOfIndicesToRemoveFromEndInteger9, numberOfIndicesToRemoveFromEndInteger10, numberOfIndicesToRemoveFromEndInteger11, numberOfIndicesToRemoveFromEndInteger12, numberOfIndicesToRemoveFromEndInteger13, numberOfIndicesToRemoveFromEndInteger14, numberOfIndicesToRemoveFromEndInteger15, numberOfIndicesToRemoveFromEndInteger16, numberOfIndicesToRemoveFromEndInteger17, numberOfIndicesToRemoveFromEndInteger18, numberOfIndicesToRemoveFromEndInteger19, numberOfIndicesToRemoveFromEndInteger20)

                                -- Run the script

                                    destroyDialog callisScriptsProcessAssetsForConnecterRollout

                                    callisScriptsProcessAssetsForConnecterFunction originalFolderPathText destinationFolderText useOriginalVolumeNameAsSuffixBooleanArray volumeNameSuffixStringArray fileNameExtraTextStringArray keywordFilterStringArray saveEachObjectSeparatelyBooleanArray attachObjectsBooleanArray proxyObjectsBooleanArray facesNumberIntegerArray includeCamerasBooleanArray includeLightsBooleanArray replaceAllTextBooleanArray retainSpecifiedTextFromFileNameBooleanArray retainSpecifiedTextFromObjectNameBooleanArray retainAllTextFromFileNameBooleanArray phraseToSplitWithStringArray numberOfIndicesToRemoveFromStartIntegerArray numberOfIndicesToRemoveFromEndIntegerArray
                            --)else(
                                --messageBox "Sorry - non-path text fields cannot contain commas. Please remove commas and try again"
                            --)
                        --)else(
                            --messageBox "Please type a single character into the 'Phrase to split with' field, or check a different file naming box"
                        --)
                    )
                )
    )

    createDialog callisScriptsProcessAssetsForConnecterRollout 550 880
