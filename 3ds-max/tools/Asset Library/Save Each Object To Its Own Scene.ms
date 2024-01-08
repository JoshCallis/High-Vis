-- Variables

    try(
        include "$scripts/Startup/Callis Scripts/General Event Handling.ms"
    )catch()

    global callisScriptsAssetOrganisationFailedObjects = #()

    global callisScriptsAssetOrganisationObjectsToDelete = #()

-- Disabling callbacks

    try(
        disableRelevantEventHandlersForCertainOperationsVariable.disableOnNodeAddedEventHandlers()
    )catch()

-- Functions

    -- Subfunctions

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

            -- Include scripts

                include "$scripts\CallisScripts\scripts\Libraries\Callis Scripts Library.ms"

            -- Functions

                fn pivotPlacer pPPlace pPType pPGroups pPAlignTo = (
                  undo "pivotPlacer" on
                    (
                        for obj in selection do(
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

    -- Functions

        -- Save each object to its own scene

            fn saveEachObjectToItsOwnSceneFunction folder explodeGroupsBoolean considerExistingFilesBoolean useObjectNamesBoolean = (
                -- Variables

                    local myNumber
                    local saveFilesAgain
                    local myFiles = getFiles (folder + "/*")

                    if considerExistingFilesBoolean == true then(
                        local numberToAdd = myFiles.count
                    )else(
                        local numberToAdd = 0
                    )

                deselect selection

                -- Place pivots at bottom

                    max select all

                    pivotPlacer 15 1 true 1

                -- Move everything to centre

                    max select all

                    for i in selection do(
                        if not isGroupMember i or explodeGroupsBoolean == true then(
                            i.pos = [0,0,0]
                        )
                    )

                deselect selection

                -- Loop

                    if explodeGroupsBoolean == true then(
                        local objectsArray = #()

                        for a in objects do(
                            if superClassOf a != helper then(
                                append objectsArray a
                            )
                        )

                        for a = 1 to objectsArray.count do(
                            select objectsArray[a]

                            -- Define myNumber variable

                                if (a + numberToAdd) < 1000 then(
                                    myNumber = ((a + numberToAdd) as string)
                                )

                                if (a + numberToAdd) < 100 then(
                                    myNumber = "0" + ((a + numberToAdd) as string)
                                )

                                if (a + numberToAdd) < 10 then(
                                    myNumber = "00" + ((a + numberToAdd) as string)
                                )

                                if useObjectNamesBoolean == true then(
                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true
                                )else(
                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true
                                )

                            deselect selection
                        )
                    )else(
                        local nonGroupMembersArray = #()

                        for a in objects do(
                            if not isGroupMember a and (superClassOf a != helper or isgrouphead a) then(
                                append nonGroupMembersArray a
                            )
                        )

                        for a = 1 to nonGroupMembersArray.count do(
                            select nonGroupMembersArray[a]

                            max group close

                            -- Define myNumber variable

                                if (a + numberToAdd) < 1000 then(
                                    myNumber = ((a + numberToAdd) as string)
                                )

                                if (a + numberToAdd) < 100 then(
                                    myNumber = "0" + ((a + numberToAdd) as string)
                                )

                                if (a + numberToAdd) < 10 then(
                                    myNumber = "00" + ((a + numberToAdd) as string)
                                )

                            -- Save each object

                                if useObjectNamesBoolean == true then(
                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                        if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                            saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                            if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                        if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                            saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                            if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                        if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                            saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                            if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                        if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                            saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                            if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                        if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                            saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                            if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                        if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                            saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                            if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                        if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                            saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                            if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                        if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                            saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                            if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                                        if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                            saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                                            if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                                                        if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                                            saveNodes selection (folder + "\\" + $.name + ".max") quiet:true
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
                                                                )
                                                            )
                                                        )
                                                    )
                                                )
                                            )
                                        )
                                    )
                                )else(
                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true
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

                            deselect selection
                        )
                    )

                -- If any files didn't finish saving, save each object again

                    -- Variables

                        myFiles = getFiles (folder + "/*")

                    -- Round 1

                        saveFilesAgain = false

                        for j in myFiles do(
                            if matchPattern j Pattern:"*max.sv*" then(
                                saveFilesAgain = true
                            )
                        )

                        if saveFilesAgain == true then(
                            -- Loop

                                if explodeGroupsBoolean == true then(
                                    local objectsArray = #()

                                    for a in objects do(
                                        if superClassOf a != helper then(
                                            append objectsArray a
                                        )
                                    )

                                    for a = 1 to objectsArray.count do(
                                        select objectsArray[a]

                                        -- Define myNumber variable

                                            if (a + numberToAdd) < 1000 then(
                                                myNumber = ((a + numberToAdd) as string)
                                            )

                                            if (a + numberToAdd) < 100 then(
                                                myNumber = "0" + ((a + numberToAdd) as string)
                                            )

                                            if (a + numberToAdd) < 10 then(
                                                myNumber = "00" + ((a + numberToAdd) as string)
                                            )

                                            if useObjectNamesBoolean == true then(
                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true
                                            )else(
                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true
                                            )

                                        deselect selection
                                    )
                                )else(
                                    local nonGroupMembersArray = #()

                                    for a in objects do(
                                        if not isGroupMember a and (superClassOf a != helper or isgrouphead a) then(
                                            append nonGroupMembersArray a
                                        )
                                    )

                                    for a = 1 to nonGroupMembersArray.count do(
                                        select nonGroupMembersArray[a]

                                        max group close

                                        -- Define myNumber variable

                                            if (a + numberToAdd) < 1000 then(
                                                myNumber = ((a + numberToAdd) as string)
                                            )

                                            if (a + numberToAdd) < 100 then(
                                                myNumber = "0" + ((a + numberToAdd) as string)
                                            )

                                            if (a + numberToAdd) < 10 then(
                                                myNumber = "00" + ((a + numberToAdd) as string)
                                            )

                                        -- Save each object

                                            if useObjectNamesBoolean == true then(
                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                        if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                            saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                            if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                        if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                            saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                            if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                        if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                            saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                            if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                        if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                            saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                            if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                        if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                            saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                            if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                        if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                            saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                            if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                        if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                            saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                            if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                                        if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                            saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                                            if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                                                        if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                                            saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                                                            if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true
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
                                                                            )
                                                                        )
                                                                    )
                                                                )
                                                            )
                                                        )
                                                    )
                                                )
                                            )else(
                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true
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

                                        deselect selection
                                    )
                                )
                        )

                    -- Round 2

                        saveFilesAgain = false

                        for j in myFiles do(
                            if matchPattern j Pattern:"*max.sv*" then(
                                saveFilesAgain = true
                            )
                        )

                        if saveFilesAgain == true then(
                            -- Loop

                                if explodeGroupsBoolean == true then(
                                    local objectsArray = #()

                                    for a in objects do(
                                        if superClassOf a != helper then(
                                            append objectsArray a
                                        )
                                    )

                                    for a = 1 to objectsArray.count do(
                                        select objectsArray[a]

                                        -- Define myNumber variable

                                            if (a + numberToAdd) < 1000 then(
                                                myNumber = ((a + numberToAdd) as string)
                                            )

                                            if (a + numberToAdd) < 100 then(
                                                myNumber = "0" + ((a + numberToAdd) as string)
                                            )

                                            if (a + numberToAdd) < 10 then(
                                                myNumber = "00" + ((a + numberToAdd) as string)
                                            )

                                            if useObjectNamesBoolean == true then(
                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true
                                            )else(
                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true
                                            )

                                        deselect selection
                                    )
                                )else(
                                    local nonGroupMembersArray = #()

                                    for a in objects do(
                                        if not isGroupMember a and (superClassOf a != helper or isgrouphead a) then(
                                            append nonGroupMembersArray a
                                        )
                                    )

                                    for a = 1 to nonGroupMembersArray.count do(
                                        select nonGroupMembersArray[a]

                                        max group close

                                        -- Define myNumber variable

                                            if (a + numberToAdd) < 1000 then(
                                                myNumber = ((a + numberToAdd) as string)
                                            )

                                            if (a + numberToAdd) < 100 then(
                                                myNumber = "0" + ((a + numberToAdd) as string)
                                            )

                                            if (a + numberToAdd) < 10 then(
                                                myNumber = "00" + ((a + numberToAdd) as string)
                                            )

                                        -- Save each object

                                            if useObjectNamesBoolean == true then(
                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                        if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                            saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                            if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                        if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                            saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                            if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                        if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                            saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                            if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                        if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                            saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                            if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                        if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                            saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                            if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                        if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                            saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                            if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                        if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                            saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                            if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                                        if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                            saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                                            if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                                                        if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                                            saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                                                            if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true
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
                                                                            )
                                                                        )
                                                                    )
                                                                )
                                                            )
                                                        )
                                                    )
                                                )
                                            )else(
                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true
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

                                        deselect selection
                                    )
                                )
                        )

                    -- Round 3

                        saveFilesAgain = false

                        for j in myFiles do(
                            if matchPattern j Pattern:"*max.sv*" then(
                                saveFilesAgain = true
                            )
                        )

                        if saveFilesAgain == true then(
                            -- Loop

                                if explodeGroupsBoolean == true then(
                                    local objectsArray = #()

                                    for a in objects do(
                                        if superClassOf a != helper then(
                                            append objectsArray a
                                        )
                                    )

                                    for a = 1 to objectsArray.count do(
                                        select objectsArray[a]

                                        -- Define myNumber variable

                                            if (a + numberToAdd) < 1000 then(
                                                myNumber = ((a + numberToAdd) as string)
                                            )

                                            if (a + numberToAdd) < 100 then(
                                                myNumber = "0" + ((a + numberToAdd) as string)
                                            )

                                            if (a + numberToAdd) < 10 then(
                                                myNumber = "00" + ((a + numberToAdd) as string)
                                            )

                                            if useObjectNamesBoolean == true then(
                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true
                                            )else(
                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true
                                            )

                                        deselect selection
                                    )
                                )else(
                                    local nonGroupMembersArray = #()

                                    for a in objects do(
                                        if not isGroupMember a and (superClassOf a != helper or isgrouphead a) then(
                                            append nonGroupMembersArray a
                                        )
                                    )

                                    for a = 1 to nonGroupMembersArray.count do(
                                        select nonGroupMembersArray[a]

                                        max group close

                                        -- Define myNumber variable

                                            if (a + numberToAdd) < 1000 then(
                                                myNumber = ((a + numberToAdd) as string)
                                            )

                                            if (a + numberToAdd) < 100 then(
                                                myNumber = "0" + ((a + numberToAdd) as string)
                                            )

                                            if (a + numberToAdd) < 10 then(
                                                myNumber = "00" + ((a + numberToAdd) as string)
                                            )

                                        -- Save each object

                                            if useObjectNamesBoolean == true then(
                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                        if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                            saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                            if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                        if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                            saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                            if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                        if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                            saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                            if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                        if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                            saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                            if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                        if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                            saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                            if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                        if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                            saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                            if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                        if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                            saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                            if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                                        if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                            saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                                            if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                                                        if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                                            saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                                                            if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true
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
                                                                            )
                                                                        )
                                                                    )
                                                                )
                                                            )
                                                        )
                                                    )
                                                )
                                            )else(
                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true
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

                                        deselect selection
                                    )
                                )
                        )

                    -- Round 4

                        saveFilesAgain = false

                        for j in myFiles do(
                            if matchPattern j Pattern:"*max.sv*" then(
                                saveFilesAgain = true
                            )
                        )

                        if saveFilesAgain == true then(
                            -- Loop

                                if explodeGroupsBoolean == true then(
                                    local objectsArray = #()

                                    for a in objects do(
                                        if superClassOf a != helper then(
                                            append objectsArray a
                                        )
                                    )

                                    for a = 1 to objectsArray.count do(
                                        select objectsArray[a]

                                        -- Define myNumber variable

                                            if (a + numberToAdd) < 1000 then(
                                                myNumber = ((a + numberToAdd) as string)
                                            )

                                            if (a + numberToAdd) < 100 then(
                                                myNumber = "0" + ((a + numberToAdd) as string)
                                            )

                                            if (a + numberToAdd) < 10 then(
                                                myNumber = "00" + ((a + numberToAdd) as string)
                                            )

                                            if useObjectNamesBoolean == true then(
                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true
                                            )else(
                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true
                                            )

                                        deselect selection
                                    )
                                )else(
                                    local nonGroupMembersArray = #()

                                    for a in objects do(
                                        if not isGroupMember a and (superClassOf a != helper or isgrouphead a) then(
                                            append nonGroupMembersArray a
                                        )
                                    )

                                    for a = 1 to nonGroupMembersArray.count do(
                                        select nonGroupMembersArray[a]

                                        max group close

                                        -- Define myNumber variable

                                            if (a + numberToAdd) < 1000 then(
                                                myNumber = ((a + numberToAdd) as string)
                                            )

                                            if (a + numberToAdd) < 100 then(
                                                myNumber = "0" + ((a + numberToAdd) as string)
                                            )

                                            if (a + numberToAdd) < 10 then(
                                                myNumber = "00" + ((a + numberToAdd) as string)
                                            )

                                        -- Save each object

                                            if useObjectNamesBoolean == true then(
                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                        if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                            saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                            if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                        if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                            saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                            if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                        if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                            saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                            if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                        if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                            saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                            if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                        if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                            saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                            if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                        if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                            saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                            if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                        if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                            saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                            if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                                        if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                            saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                                            if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                                                        if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                                            saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                                                            if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                                                saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                                                                if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                                                    saveNodes selection (folder + "\\" + $.name + ".max") quiet:true

                                                                                                                                                                                                    if not doesFileExist(folder + "\\" + $.name + ".max") then(
                                                                                                                                                                                                        saveNodes selection (folder + "\\" + $.name + ".max") quiet:true
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
                                                                            )
                                                                        )
                                                                    )
                                                                )
                                                            )
                                                        )
                                                    )
                                                )
                                            )else(
                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                                                if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                                                    saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                                                    if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                                                        saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                                                        if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                                                            saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true

                                                                                                                                                                                                            if not doesFileExist(folder + "\\" + myNumber + ".max") then(
                                                                                                                                                                                                                saveNodes selection (folder + "\\" + myNumber + ".max") quiet:true
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

                                        deselect selection
                                    )
                                )
                        )

            )

-- Rollout

    rollout saveEachObjectToItsOwnSceneRollout "Save Each Obect To Its Own Scene"(
        -- Variables

            local folderString = ""
            local explodeGroupsBoolean = true
            local considerExistingFilesBoolean = true
            local useObjectNamesBoolean = true

        -- Components

            editText warningOne "" text:"If saving by group, ensure all groups are closed before running" readOnly:true

            editText warningTwo "" text:"Consider existing files assumes only numbered files are in the folder, starting from 001, and no numbers are missing between any two files" readOnly:true

            editText folderEditText "Folder: " text:""

            checkbox exploderetainGroupsCheckbox "Explode groups" checked:true toolTip:"If checked, objects in groups will be saved to separate scenes"

            checkbox retainGroupsCheckbox "Retain groups" checked:false toolTip:"If checked, grouped objects will stay grouped when saving"

            checkbox useObjectNamesCheckbox "Use object names" checked:true toolTip:"If checked, files will be names after object names. If unchecked, files will be named a 3-digit number starting from 001."

            checkbox considerExistingFilesCheckbox "Consider existing files" checked:true

            button runButton "Run"

        -- Actions

            on folderEditText entered txt do(
                if txt != undefined and txt != "" then(
                    folderString = txt
                )
            )

            on exploderetainGroupsCheckbox changed state do(
                if state then(
                    explodeGroupsBoolean = true

                    retainGroupsCheckbox.checked = false
                )else(
                    explodeGroupsBoolean = false

                    retainGroupsCheckbox.checked = true
                )
            )

            on retainGroupsCheckbox changed state do(
                if state then(
                    explodeGroupsBoolean = false

                    exploderetainGroupsCheckbox.checked = false
                )else(
                    explodeGroupsBoolean = true

                    exploderetainGroupsCheckbox.checked = true
                )
            )

            on useObjectNamesCheckbox changed state do(
                if state then(
                    useObjectNamesBoolean = true
                )else(
                    useObjectNamesBoolean = false
                )
            )

            on considerExistingFilesCheckbox changed state do(
                if state then(
                    considerExistingFilesBoolean = true
                )else(
                    considerExistingFilesBoolean = false
                )
            )

            on runButton pressed do(
                if folderString != undefined and folderString != "" then(
                    saveEachObjectToItsOwnSceneFunction folderString explodeGroupsBoolean considerExistingFilesBoolean useObjectNamesBoolean

                    destroyDialog saveEachObjectToItsOwnSceneRollout
                )else(
                    messageBox "Please enter a folder path and try again"
                )
            )
    )

-- Create dialog

    createDialog saveEachObjectToItsOwnSceneRollout 750 180

-- Reenabling callbacks

    try(
        disableRelevantEventHandlersForCertainOperationsVariable.enableOnNodeAddedEventHandlers()
    )catch()
