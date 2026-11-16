
-- Issues

    -- General

        -- Need code to ensure "get resolution from max" is turned off, or to change max output size while vray is the current renderer
        -- Need code to multiply render time by 16 on high res render, if a render time exists
        -- Make sure vray lock image aspect is turned off when changing output size, unless it turns out that it doesn't matter
        -- Need code to ensure ", " is between frame numbers when processed

    -- Material guesser

        -- Need to remove materials from the library when replaced.
        -- Need to ensure users can't input illegal characters into text fields.
        -- Need to put each slot's tags under its image.
        -- Each time a material is applied, it creates a new version. Each version gets its own multimatte. Need to fix.

-- Extras

    -- Material Guesser .ini text, in case it gets deleted

        /*
            [Material Guesser]
            Material Names=Timber|Concrete|materialGuesserDummyMaterialName|Glass, Grey, Glossy|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName|materialGuesserDummyMaterialName
            Bitmap Paths=B:\Timber.jpg|B:\Concrete.jpg.jpg|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath|materialGuesserDummyBitmapPath
            Last Edited Slot=4
            Tags=Wood|Walls|materialGuesserDummyTag|Glaz|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag|materialGuesserDummyTag
        */

    /*
    -- Split bracketed letter out of layer name if applicable

        layerNameMinusMultimatteSuffixPreliminary3 = substituteString (layersToMultimatteByLayer (((LayerManager.getLayer i).getParent()).getParent()).name) "(B)" ""
        layerNameMinusMultimatteSuffixPreliminary2 = substituteString layerNameMinusMultimatteSuffixPreliminary3 "(B)" ""
        layerNameMinusMultimatteSuffixPreliminary1 = substituteString layerNameMinusMultimatteSuffixPreliminary2 "(B)" ""
        layerNameMinusMultimatteSufix = substituteString layerNameMinusMultimatteSuffixPreliminary1 "(B)" ""
    */

-- Progression

    -- Isolate glass functionality

        -- Need to alter the photoshop scripts to accomodate.

-- Set heap size

    try(
        heapSize=52428800L
    )catch()

-- Global variables

    global highResDecisionVar = "false"
    global frameNumbers = ""
    global frameNumbersString = ""
    global frameNumber = "null"
    global myDirectory = ""
    global dialogInitialPromptLayer = ""
    global dialogInitialPromptGroup = ""
    global dialogFrameNumbers = ""
    global dialogOutputFolder = ""
    global dialogDoForHighRes = ""
    global dialogDoFor16b = ""
    global photoshopFrameNumbers = ""
    global photoshopFrameNumbersString = ""
    global photoshopSpecifiedFramesText = ""
    global photoshopOriginalFrameNumber = ""
    global callisScriptsMainLayer = ""
    layersToHideAfterRendering = #()
    global callisScriptsIsInteractiveRenderCurrentlyOn
    global callisScriptsHasLockRenderToViewButtonBeenPressed

    -- Create outputPath variable

        try(
            global outputFolderPreliminary = $'Output Path Dummy'.layer.name
            global outputFolder = substituteString outputFolderPreliminary "Output Path: " ""
            global outputPath = outputFolder + "\\Metadata\\3DS Max Metadata.psb"
        )catch()

    -- Material guesser

        global materialGuesserSlotNumber = undefined

-- Functions

    -- Subfunctions

        -- Not currently in use

            /*
            -- Move Pivot To Bottom/Detach

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
            */

        -- Get active frame's camera

            fn getActiveFramesCamera = (
                local activeFramesCamera

                try(
                    -- Get frame number

                        currentFrameNumberPreliminary = sliderTime as string

                        currentFrameNumberAsStringPreliminary = filterString currentFrameNumberPreliminary "f" splitEmptyTokens:false

                        currentFrameNumberAsString = currentFrameNumberAsStringPreliminary[1]

                        frameNumber = currentFrameNumberAsString as integer

                    camerasLayer = (layermanager.getLayerFromName "Cameras")

                    camerasLayer.nodes &camerasLayerNodes

                    for i = 1 to camerasLayerNodes.count do(
                        cameraNumber = filterString camerasLayerNodes[i].name " "

                        for b = 1 to cameraNumber.count do(
                            if (substituteString cameraNumber[b] "," "") == (frameNumber as string) and superClassOf camerasLayerNodes[i] == camera then(
                                activeFramesCamera = camerasLayerNodes[i]
                            )

                            if (classOf ((substituteString cameraNumber[b] "," "") as integer)) != integer then( -- This stops numbers that are part of the object's actual name from being interpreted as frame numbers
                                exit
                            )
                        )
                    )

                    activeFramesCamera
                )catch()
            )

        -- Change frame

            fn changeFrameNumber frameNumber = (
                -- Variables

                    local originalActiveViewport
                    local sunOn = false
                    local skyOn = false
                    local currentFrameNumberAsInteger
                    local previousFrameNumber

                    -- Get previous frame number

                        currentFrameNumberPreliminary = sliderTime as string

                        currentFrameNumberAsStringPreliminary = filterString currentFrameNumberPreliminary "f" splitEmptyTokens:false

                        currentFrameNumberAsString = currentFrameNumberAsStringPreliminary[1]

                        previousframeNumber = currentFrameNumberAsString as integer

                try(
                    sliderTime = frameNumber

                    currentFrameNumberAsInteger = frameNumber

                    -- Set frame size

                        -- Create variables

                            -- Create frameSizePreliminary3 variable

                                frameSizePreliminary32 = $'Frame Sizes Dummy'.layer.name

                                frameSizePreliminary3 = substituteString frameSizePreliminary32 "Frame Sizes: " ","

                            -- Create frameSizePreliminary2 variable

                                frameSizePreliminary22 = substituteString frameSizePreliminary3 ", " ","

                                frameSizePreliminary2 = filterString frameSizePreliminary22 ","

                            -- Create frameSizePreliminary1 variable

                                frameSizePreliminary1 = frameSizePreliminary2[currentFrameNumberAsInteger]

                            -- Create frameSizePreliminary0 variable

                                frameSizePreliminary0 = filterString frameSizePreliminary1 "."

                            -- Create frameSizePreliminary variable

                                frameSizePreliminary = frameSizePreliminary0[2]

                            -- Create frameSize variable

                                frameSize = substituteString frameSizePreliminary " " ""

                            -- Create frameSizeSingleAxis variable

                                frameSizeSingleAxis = filterString frameSize "x"

                            -- Create frameWidth variable

                                frameWidth = frameSizeSingleAxis[1]

                            -- Create frameHeight variable

                                frameHeight = frameSizeSingleAxis[2]

                            -- Convert to integers

                                -- Create frameWidthAsInteger variable

                                    frameWidthAsInteger = frameWidth as integer

                                -- Create frameHeightAsInteger variable

                                    frameHeightAsInteger = frameHeight as integer

                        -- Set frame size

                            renderers.current.output_width = frameWidthAsInteger

                            try(
                                renderWidth = frameWidthAsInteger
                            )catch()

                            renderers.current.output_height = frameHeightAsInteger

                            try(
                                renderHeight = frameHeightAsInteger
                            )catch()

                    originalActiveViewport = viewport.activeViewport

                    camerasLayer = (layermanager.getLayerFromName "Cameras")
                    camerasLayer.nodes &camerasLayerNodes

                    sunLayer = (layermanager.getLayerFromName "Sun")
                    sunLayer.nodes &sunLayerNodes

                    skyLayer = (layermanager.getLayerFromName "Sky")
                    skyLayer.nodes &skyLayerNodes

                    -- Cameras

                        try(
                            for i = 1 to camerasLayerNodes.count do(
                                cameraNumber = filterString camerasLayerNodes[i].name " "

                                for b = 1 to cameraNumber.count do(
                                    if ((substituteString cameraNumber[b] "," "") == (frameNumber as string) or (substituteString cameraNumber[b] "," "") == ("All Frames")) and superClassOf camerasLayerNodes[i] == camera then(
                                        for a = 1 to viewport.numViews do(
                                            viewport.activeViewport = a

                                            if viewport.getType() == #view_camera then(
                                                viewport.setCamera camerasLayerNodes[i]
                                            )
                                        )
                                    )

                                    if (classOf ((substituteString cameraNumber[b] "," "") as integer)) != integer then( -- This stops numbers that are part of the object's actual name from being interpreted as frame numbers
                                        exit
                                    )
                                )
                            )
                        )catch()

                    -- Sun

                        try(
                            for i = 1 to sunLayerNodes.count do(
                                sunNumber = filterString sunLayerNodes[i].name " "

                                for b = 1 to sunNumber.count do(
                                    if ((substituteString sunNumber[b] "," "") == (frameNumber as string) or (substituteString sunNumber[b] "," "") == ("All Frames")) and superClassOf sunLayerNodes[i] == light then(
                                        sunOn = true
                                    )

                                    if (classOf ((substituteString sunNumber[b] "," "") as integer)) != integer then( -- This stops numbers that are part of the object's actual name from being interpreted as frame numbers
                                        exit
                                    )
                                )

                                if sunOn == true then(
                                    try(
                                        sunLayerNodes[i].on = on
                                    )catch()

                                    try(
                                        sunLayerNodes[i].enabled = on
                                    )catch()
                                )else(
                                    if matchPattern (sunLayerNodes[i].name) pattern:"All *" == false then(
                                        try(
                                            sunLayerNodes[i].on = off
                                        )catch()

                                        try(
                                            sunLayerNodes[i].enabled = off
                                        )catch()
                                    )
                                )

                                sunOn = false
                            )
                        )catch()

                    -- Sky

                        try(
                            for i = 1 to skyLayerNodes.count do(
                                skyNumber = filterString skyLayerNodes[i].name " "

                                for b = 1 to skyNumber.count do(
                                    if ((substituteString skyNumber[b] "," "") == (frameNumber as string) or (substituteString skyNumber[b] "," "") == ("All Frames")) and superClassOf skyLayerNodes[i] == light then(
                                        skyOn = true
                                    )

                                    if (classOf ((substituteString skyNumber[b] "," "") as integer)) != integer then( -- This stops numbers that are part of the object's actual name from being interpreted as frame numbers
                                        exit
                                    )
                                )

                                if skyOn == true then(
                                    try(
                                        skyLayerNodes[i].on = on
                                    )catch()

                                    try(
                                        skyLayerNodes[i].enabled = on
                                    )catch()
                                )else(
                                    if matchPattern (skyLayerNodes[i].name) pattern:"All *" == false then(
                                        try(
                                            skyLayerNodes[i].on = off
                                        )catch()

                                        try(
                                            skyLayerNodes[i].enabled = off
                                        )catch()
                                    )
                                )

                                skyOn = false
                            )
                        )catch()

                    -- Geometry

                        --try(
                            for obj in objects do(
                                -- If any objects in the previous frame were hidden by the user, note this in their names if it wasn't already

                                    if ((matchpattern obj.name pattern:(previousFrameNumber as string + " *")) or (matchpattern obj.name pattern:(previousFrameNumber as string))) and classof obj != Targetobject then(
                                        if obj.isHidden == true then(
                                            if not matchpattern obj.name pattern:("* (Keep Hidden)") then(
                                                obj.name = obj.name + " (Keep Hidden)"
                                            )
                                        )else(
                                            if matchpattern obj.name pattern:("* (Keep Hidden)") then(
                                                local newname = substituteString obj.name " (Keep Hidden)" ""
                                                obj.name = newname
                                            )
                                        )
                                    )

                                -- Check if the object's name starts with an integer between 1 and 10 followed by a space

                                    if ((matchpattern obj.name pattern:(frameNumber as string + " *")) or (matchpattern obj.name pattern:(frameNumber as string)) or (matchpattern obj.name pattern:(frameNumber as string + ".Target"))) and not matchpattern obj.name pattern:("* (Keep Hidden)") and not matchpattern obj.name pattern:("* (Keep Hidden).Target") then(
                                        -- Unhide the object

                                            obj.isHidden = false
                                    )else(
                                        -- Check if the object's name starts with an integer between 1 and 10, but not the integer provided by the user

                                            for a = 1 to 9 do(
                                                if ((matchpattern obj.name pattern:(a as string + " *")) or (matchpattern obj.name pattern:(a as string)) or (matchpattern obj.name pattern:(a as string + ".Target"))) and not ((matchpattern obj.name pattern:(frameNumber as string + " *")) or (matchpattern obj.name pattern:(frameNumber as string)) or (matchpattern obj.name pattern:(frameNumber as string + ".Target"))) then(
                                                    print 3

                                                    -- Hide the object

                                                        obj.isHidden = true
                                                )
                                            )
                                    )
                            )
                        --)catch()

                    viewport.activeViewport = originalActiveViewport

                    redrawViews()
                )catch()
            )

        -- Multimatte

            -- Clear multimatte elements

                fn clearMultiMatteElements = (
                    _elementsArray = #()

                    re = maxOps.GetCurRenderElementMgr()

                    for n = 1 to re.numrenderelements() do(
                        element = re.getRenderElement(n-1)
                        if classOf element == MultiMatteElement do(
                            append _elementsArray element
                        )
                    )

                    for e in _elementsArray do
                        re.RemoveRenderElement(e)

                    tmpString = "Removed " + _elementsArray.count as string + " MultiMatte Render Elements..."
                )

            -- Automultimatte script

                -- Define automultimatte script

                    struct AutoMultiMatte_HelperFunctions(
                        fn saveVarToIniFile section_name var_name var_value = (
                          INIFileDir = ((getdir #plugcfg) + "\\AutoMultiMatte\\")
                          if (getDirectories INIFileDir).count == 0 then makeDir INIFileDir
                          INIFilename = INIFileDir + "AutoMultiMatte.ini"
                          setINISetting INIFilename section_name var_name (var_value as string)
                        ),

                        fn loadVarFromIniFile section_name var_name = (
                          INIFileDir = ((getdir #plugcfg) + "\\AutoMultiMatte\\")
                          INIFilename = INIFileDir + "AutoMultiMatte.ini"
                          temp_value = getINISetting INIFilename section_name var_name
                          if temp_value == "" then undefined else temp_value
                        ),

                        fn leadingZero num digitCount = (
                          str = num as string
                          while str.count < digitCount do
                            str = "0" + str
                          str
                        ),

                        fn deleteRenderElements prefix_String elementManager = (
                          elementsNum = elementManager.NumRenderElements()
                          selectedElements = #()

                          --iterate over all render elements
                          for i=0 to (elementsNum-1) do
                          (
                            element = elementManager.GetRenderElement i
                            --select elements whose names starts with given prefix
                            if (substring element.elementName 1 prefix_String.count == prefix_String) then
                              append selectedElements element
                          )

                          for element in selectedElements do
                            elementManager.RemoveRenderElement element	--delete them one by one
                        ),

                        fn collectExistingMatteIds elementManager useObjectId: = (
                          matIdsArray = #()
                          elementsNum = elementManager.NumRenderElements()

                          fn xor b1 b2 = (not (b1 and b2)) and (b1 or b2)

                          for i=0 to (elementsNum-1) do
                          (
                            element = elementManager.GetRenderElement i
                            elementNameParts = filterString (element as string) ":"
                            elementType = elementNameParts[2] as string

                            if (elementType == "MultiMatteElement") then(
                              if ( element.enabled and ( xor element.MatID (useObjectId != unsupplied and useObjectId) ) ) then
                              (
                                if (element.R_gbufIDOn) then
                                  append matIdsArray element.R_gbufID
                                if (element.G_gbufIDOn) then
                                  append matIdsArray element.G_gbufID
                                if (element.B_gbufIDOn) then
                                  append matIdsArray element.B_gbufID
                              )
                            )
                          )
                          matIdsArray
                        ),

                        fn getNextFreeMatId elementStartingNumber existingIds = (
                          elementNumber = elementStartingNumber
                          while ((findItem existingIds elementNumber) != 0) do
                            elementNumber += 1
                          elementNumber
                        )
                    )

                    struct AutoMultiMatte_MaterialCollector(
                      fn isUniqueMat mat matArray = (
                        hasInstance = false
                        for matInArr in matArray while (not hasInstance) do
                          if matInArr == mat then hasInstance = true

                        (not hasInstance)
                      ),

                      fn joinIfUnique matArr matArrIn = (
                        for mat in matArr do
                          if (AutoMultiMatte_MaterialCollector.isUniqueMat mat matArrIn) then (append matArrIn mat)
                      ),

                      fn collectSubMaterials materials = (
                        matArray = #()
                        for mat in materials do
                        (
                          case (classof mat) of
                          (
                            VRayMtl:
                            (
                              if (AutoMultiMatte_MaterialCollector.isUniqueMat mat matArray) then (append matArray mat)
                            )
                            --check all other materials if they contain vray materials
                            Multimaterial:
                            (
                              returnedArray = AutoMultiMatte_MaterialCollector.collectSubMaterials mat.materialList
                              AutoMultiMatte_MaterialCollector.joinIfUnique returnedArray matArray
                            )
                            Blend:
                            (
                              returnedArray = AutoMultiMatte_MaterialCollector.collectSubMaterials #(mat.map1, mat.map2)
                              AutoMultiMatte_MaterialCollector.joinIfUnique returnedArray matArray
                            )
                            VRayBlendMtl:
                            (
                              returnedArray = AutoMultiMatte_MaterialCollector.collectSubMaterials (append (mat.coatMtl as array) mat.baseMtl)
                              AutoMultiMatte_MaterialCollector.joinIfUnique returnedArray matArray
                            )
                            VRay2SidedMtl:
                            (
                              returnedArray = AutoMultiMatte_MaterialCollector.collectSubMaterials #(mat.frontMtl, mat.backMtl)
                              AutoMultiMatte_MaterialCollector.joinIfUnique returnedArray matArray
                            )
                            VRayOverrideMtl:
                            (
                              returnedArray = AutoMultiMatte_MaterialCollector.collectSubMaterials #(mat.baseMtl, mat.giMtl, mat.reflectMtl, mat.refractMtl, mat.shadowMtl)
                              AutoMultiMatte_MaterialCollector.joinIfUnique returnedArray matArray
                            )
                            Shellac:
                            (
                              returnedArray = AutoMultiMatte_MaterialCollector.collectSubMaterials #(mat.shellacMtl1, mat.shellacMtl2)
                              AutoMultiMatte_MaterialCollector.joinIfUnique returnedArray matArray
                            )
                            TopBottom:
                            (
                              returnedArray = AutoMultiMatte_MaterialCollector.collectSubMaterials #(mat.topMaterial, mat.bottomMaterial)
                              AutoMultiMatte_MaterialCollector.joinIfUnique returnedArray matArray
                            )
                            Shell_Material:
                            (
                              returnedArray = AutoMultiMatte_MaterialCollector.collectSubMaterials #(mat.originalMaterial, mat.bakedMaterial)
                              AutoMultiMatte_MaterialCollector.joinIfUnique returnedArray matArray
                            )
                            default:
                            (
                              --all other materials go here
                            )
                          )
                        )
                        matArray
                      )
                    )

                    elementNamePrefix = "Multimatte_"
                    elementStartingNumber; elementStartingNumber = 16
                    considerMattes = false
                    matSelection = AutoMultiMatte_HelperFunctions.loadVarFromIniFile "AutoMultiMatte_Paramaters" "materialSelection"

                    rollout AutoMultiMatte_Rollout("Create Multimatte Elements")(

                        on AutoMultiMatte_Rollout open do(
                            elementManager = MaxOps.GetCurRenderElementMgr()

                            local existingIds = #()
                            local existingMaterials = #()

                            for mat in scenematerials do(
                                try(
                                    mat.override_effect_id = false
                                )catch()
                            )

                            AutoMultiMatte_HelperFunctions.deleteRenderElements elementNamePrefix elementManager

                            allMaterials = #()

                            for obj in objects where (obj.material != undefined) do append allMaterials obj.material

                            allVrayMaterials = #()

                            allVrayMaterials = AutoMultiMatte_MaterialCollector.collectSubMaterials allMaterials

                            for vrayMat in allVrayMaterials do(
                                try(
                                    vrayMat.override_effect_id = false
                                    vrayMat.effect_id = 0
                                )catch()
                            )

                            setOfObjects = selection

                            selectionMaterials = #()

                            for obj in setOfObjects where (obj.material != undefined and not obj.isHiddenInVpt) do
                              append selectionMaterials obj.material

                            vrayMaterialArray = #()

                            vrayMaterialArray = AutoMultiMatte_MaterialCollector.collectSubMaterials selectionMaterials

                            -- Count vray materials and divide by 3 to get multimatte render elements quantity

                                matCount = vrayMaterialArray.count
                                channelSelected = 1
                                numOfElements = (ceil (matCount / (channelSelected as float))) as integer
                                matIndex = 0

                            -- Loop over materials

                                for i = 1 to numOfElements do(
                                    rendElementNameString = elementNamePrefix
                                    rendElement = MultiMatteElement()
                                    rendElement.enabled = true
                                    rendElement.MatID = true

                                    if (matIndex < matCount) then
                                    (
                                      vrayMaterialArray[matIndex+1].override_effect_id = true
                                      matId = 0

                                        vrayMaterialArray[matIndex+1].effect_id = elementStartingNumber + matIndex
                                      rendElementNameString += vrayMaterialArray[matIndex+1].name
                                      rendElement.R_gbufIDOn = true

                                        rendElement.R_gbufID = elementStartingNumber + matIndex
                                      matIndex += 1
                                    )

                                    rendElement.G_gbufIDOn = false

                                    rendElement.B_gbufIDOn = false

                                    rendElement.elementName = rendElementNameString

                                    elementManager.AddRenderElement rendElement
                                )
                        )
                    )

                -- Run automultimatte script

                    fn runAutoMultimatteScript = (
                        createDialog AutoMultiMatte_Rollout width:0 height:0 modal:false escapeEnable:false

                        destroyDialog AutoMultiMatte_Rollout
                    )

            -- Add multimattes by layer

                fn AddMultiMattes elementSuffix gBufferNumber = (
                    currentSel = getCurrentSelection()

                    _idArray = #()

                    for obj in currentSel do
                        obj.gBufferChannel = gBufferNumber

                    for obj in currentSel do
                        appendifunique _idArray gBufferNumber

                    sort _idArray

                    re = maxOps.GetCurRenderElementMgr()

                    _Ids = _idArray.count / 3.0
                    _elementsNeeded = ceil _Ids as integer

                    elementCounter = 0

                    for count = 1 to _elementsNeeded do(
                      nameString = "Multimatte_" + ((filterString elementSuffix " —" splitEmptyTokens:false) [1]) --Upon starting at RMA in 2022 and beginning using Max 2023, the dash causes problems with render output (weird double-ups). So we just get rid of it.
                      print "Mad"
                      re.AddRenderElement (MultiMatteElement elementname:nameString  R_gbufID:gBufferNumber R_gbufIDOn:(on) G_gbufID:gBufferNumber G_gbufIDOn:(off) B_gbufID:gBufferNumber B_gbufIDOn:(off))

                      elementCounter += 3
                    )
                )

        -- Layers

            -- Layer-based object seletion

                -- Select all objects in layer

                    fn GetObjectsInLayer layer: =(
                        local objsArr

                        layer.nodes &objsArr

                        objsArr
                    )

                    function selectAllObjectsInSpecifiedLayer obj = (
                        try(
                            if classOf obj == MixinInterface do(
                                objsInnLayerArr = GetObjectsInLayer layer:obj

                                for o in objsInnLayerArr do(
                                    selectMore o
                                )
                            )

                            numChilds = obj.getNumChildren()
                            for layer = 1 to numChilds do selectAllObjectsInSpecifiedLayer (obj.getChild layer)
                        )catch()
                    )

                -- Deselect all objects in layer

                    function deselectAllObjectsInSpecifiedLayer obj = (
                        try(
                            if classOf obj == MixinInterface do(
                                objsInnLayerArr = GetObjectsInLayer layer:obj

                                for o in objsInnLayerArr do(
                                    deselect o
                                )
                            )

                            numChilds = obj.getNumChildren()
                            for layer = 1 to numChilds do deselectAllObjectsInSpecifiedLayer (obj.getChild layer)
                        )catch()
                    )

            -- Add multimatte layers to bottom layers

                fn addMultimatteLayersToSpecifiedLayer layerName = (
                    -- Variables

                        local myLayer = LayerManager.getLayerFromName layerName
                        local numChildLayers = myLayer.getNumChildren()
                        local childA

                        if matchPattern layerName pattern:"* —" then(
                            local layerNameWithoutDash = substring layerName 1 (layerName.count - 2)
                        )else(
                            local layerNameWithoutDash = layerName
                        )

                        local multimatteLayerOne = layerNameWithoutDash + " (L)"
                        local multimatteLayerTwo = layerNameWithoutDash + " (M)"
                        local multimatteLayerThree = layerNameWithoutDash + " (B)"
                        local multimatteLayerFour = layerNameWithoutDash + " (N)"

                    -- Create sublayers if relevant

                        if not matchPattern layerName pattern:"* (L)" and not matchPattern layerName pattern:"* (M)" and not matchPattern layerName pattern:"* (B)" and not matchPattern layerName pattern:"* (N)" then(
                          try(
                              LayerManager.newLayerFromName (multimatteLayerOne)
                          )catch()

                          try(
                              LayerManager.newLayerFromName (multimatteLayerTwo)
                          )catch()

                          try(
                              LayerManager.newLayerFromName (multimatteLayerThree)
                          )catch()

                          try(
                              LayerManager.newLayerFromName (multimatteLayerFour)
                          )catch()


                          try(
                              (LayerManager.getLayerFromName multimatteLayerOne).setParent myLayer
                          )catch()

                          try(
                              (LayerManager.getLayerFromName multimatteLayerTwo).setParent myLayer
                          )catch()

                          try(
                              (LayerManager.getLayerFromName multimatteLayerThree).setParent myLayer
                          )catch()

                          try(
                              (LayerManager.getLayerFromName multimatteLayerFour).setParent myLayer
                          )catch()

                        )
                )

                fn addMultimatteLayersToAllRelevantLayers mainLayerName = (
                    -- Variables etc.

                        local haveReachedBottomOfLayerStack = false

                    try(
                        layersToProcess = #()

                        callisScriptsMainLayer = LayerManager.getLayerFromName mainLayerName

                        numChildLayers = callisScriptsMainLayer.getNumChildren()

                        -- Assume we have reached the bottom of the stack, and then determine otherwise if any non-multimatte layers are found

                            haveReachedBottomOfLayerStack = true

                            if numChildLayers != undefined and numChildLayers != 0 then(
                                for childA = 1 to numChildLayers do(
                                    if not matchPattern (((callisScriptsMainLayer.getChild childA).name) as string) Pattern:"* (B)" and not matchPattern (((callisScriptsMainLayer.getChild childA).name) as string) Pattern:"* (L)" and not matchPattern (((callisScriptsMainLayer.getChild childA).name) as string) Pattern:"* (N)" and not matchPattern (((callisScriptsMainLayer.getChild childA).name) as string) Pattern:"* (N)" then(
                                        haveReachedBottomOfLayerStack = false
                                    )
                                )
                            )

                        if haveReachedBottomOfLayerStack == false then(
                            for a = 1 to numChildLayers do(
                                currentChildLayer = callisScriptsMainLayer.getChild a
                                mainLayer2 = currentChildLayer
                                numChildLayers2 = mainLayer2.getNumChildren()

                                aa = numChildLayers2

                                -- Assume we have reached the bottom of the stack, and then determine otherwise if any non-multimatte layers are found

                                    haveReachedBottomOfLayerStack = true

                                    if aa != undefined and aa != 0 then(
                                        for childB = 1 to numChildLayers2 do(
                                            if not matchPattern (((mainLayer2.getChild childB).name) as string) Pattern:"* (B)" and not matchPattern (((mainLayer2.getChild childB).name) as string) Pattern:"* (L)" and not matchPattern (((mainLayer2.getChild childB).name) as string) Pattern:"* (N)" and not matchPattern (((mainLayer2.getChild childB).name) as string) Pattern:"* (N)" then(
                                                haveReachedBottomOfLayerStack = false
                                            )
                                        )
                                    )

                                if haveReachedBottomOfLayerStack == false then(
                                    for b = 1 to numChildLayers2 do(
                                        currentChildLayer = mainLayer2.getChild b
                                        mainLayer3 = currentChildLayer
                                        numChildLayers3 = mainLayer3.getNumChildren()

                                        bb = numChildLayers3

                                        -- Assume we have reached the bottom of the stack, and then determine otherwise if any non-multimatte layers are found

                                            haveReachedBottomOfLayerStack = true

                                            if bb != undefined and bb != 0 then(
                                                for childC = 1 to numChildLayers3 do(
                                                    if not matchPattern (((mainLayer3.getChild childC).name) as string) Pattern:"* (B)" and not matchPattern (((mainLayer3.getChild childC).name) as string) Pattern:"* (L)" and not matchPattern (((mainLayer3.getChild childC).name) as string) Pattern:"* (N)" and not matchPattern (((mainLayer3.getChild childC).name) as string) Pattern:"* (N)" then(
                                                        haveReachedBottomOfLayerStack = false
                                                    )
                                                )
                                            )

                                        if haveReachedBottomOfLayerStack == false then(
                                            for c = 1 to numChildLayers3 do(
                                                currentChildLayer = mainLayer3.getChild c
                                                mainLayer4 = currentChildLayer
                                                numChildLayers4 = mainLayer4.getNumChildren()

                                                cc = numChildLayers4

                                                -- Assume we have reached the bottom of the stack, and then determine otherwise if any non-multimatte layers are found

                                                    haveReachedBottomOfLayerStack = true

                                                    if cc != undefined and cc != 0 then(
                                                        for childD = 1 to numChildLayers4 do(
                                                            if not matchPattern (((mainLayer4.getChild childD).name) as string) Pattern:"* (B)" and not matchPattern (((mainLayer4.getChild childD).name) as string) Pattern:"* (L)" and not matchPattern (((mainLayer4.getChild childD).name) as string) Pattern:"* (N)" and not matchPattern (((mainLayer4.getChild childD).name) as string) Pattern:"* (N)" then(
                                                                haveReachedBottomOfLayerStack = false
                                                            )
                                                        )
                                                    )

                                                if haveReachedBottomOfLayerStack == false then(
                                                    for d = 1 to numChildLayers4 do(
                                                        currentChildLayer = mainLayer4.getChild d
                                                        mainLayer5 = currentChildLayer
                                                        numChildLayers5 = mainLayer5.getNumChildren()

                                                        dd = numChildLayers5

                                                        -- Assume we have reached the bottom of the stack, and then determine otherwise if any non-multimatte layers are found

                                                            haveReachedBottomOfLayerStack = true

                                                            if dd != undefined and dd != 0 then(
                                                                for childE = 1 to numChildLayers5 do(
                                                                    if not matchPattern (((mainLayer5.getChild childE).name) as string) Pattern:"* (B)" and not matchPattern (((mainLayer5.getChild childE).name) as string) Pattern:"* (L)" and not matchPattern (((mainLayer5.getChild childE).name) as string) Pattern:"* (N)" and not matchPattern (((mainLayer5.getChild childE).name) as string) Pattern:"* (N)" then(
                                                                        haveReachedBottomOfLayerStack = false
                                                                    )
                                                                )
                                                            )

                                                        if haveReachedBottomOfLayerStack == false then(
                                                            for e = 1 to numChildLayers5 do(
                                                                currentChildLayer = mainLayer5.getChild e
                                                                mainLayer6 = currentChildLayer
                                                                numChildLayers6 = mainLayer6.getNumChildren()

                                                                ee = numChildLayers6

                                                                -- Assume we have reached the bottom of the stack, and then determine otherwise if any non-multimatte layers are found

                                                                    haveReachedBottomOfLayerStack = true

                                                                    if ee != undefined and ee != 0 then(
                                                                        for childF = 1 to numChildLayers6 do(
                                                                            if not matchPattern (((mainLayer6.getChild childF).name) as string) Pattern:"* (B)" and not matchPattern (((mainLayer6.getChild childF).name) as string) Pattern:"* (L)" and not matchPattern (((mainLayer6.getChild childF).name) as string) Pattern:"* (N)" and not matchPattern (((mainLayer6.getChild childF).name) as string) Pattern:"* (N)" then(
                                                                                haveReachedBottomOfLayerStack = false
                                                                            )
                                                                        )
                                                                    )

                                                                if haveReachedBottomOfLayerStack == false then(
                                                                    for f = 1 to numChildLayers6 do(
                                                                        currentChildLayer = mainLayer6.getChild f
                                                                        mainLayer7 = currentChildLayer
                                                                        numChildLayers7 = mainLayer7.getNumChildren()

                                                                        ff = numChildLayers7

                                                                        -- Assume we have reached the bottom of the stack, and then determine otherwise if any non-multimatte layers are found

                                                                            haveReachedBottomOfLayerStack = true

                                                                            if ff != undefined and ff != 0 then(
                                                                                for childG = 1 to numChildLayers7 do(
                                                                                    if not matchPattern (((mainLayer7.getChild childG).name) as string) Pattern:"* (B)" and not matchPattern (((mainLayer7.getChild childG).name) as string) Pattern:"* (L)" and not matchPattern (((mainLayer7.getChild childG).name) as string) Pattern:"* (N)" and not matchPattern (((mainLayer7.getChild childG).name) as string) Pattern:"* (N)" then(
                                                                                        haveReachedBottomOfLayerStack = false
                                                                                    )
                                                                                )
                                                                            )

                                                                        if haveReachedBottomOfLayerStack == false then(
                                                                            for g = 1 to numChildLayers7 do(
                                                                                currentChildLayer = mainLayer7.getChild g
                                                                                mainLayer8 = currentChildLayer
                                                                                numChildLayers8 = mainLayer8.getNumChildren()

                                                                                gg = numChildLayers8

                                                                                -- Assume we have reached the bottom of the stack, and then determine otherwise if any non-multimatte layers are found

                                                                                    haveReachedBottomOfLayerStack = true

                                                                                    if gg != undefined and gg != 0 then(
                                                                                        for childH = 1 to numChildLayers8 do(
                                                                                            if not matchPattern (((mainLayer8.getChild childH).name) as string) Pattern:"* (B)" and not matchPattern (((mainLayer8.getChild childH).name) as string) Pattern:"* (L)" and not matchPattern (((mainLayer8.getChild childH).name) as string) Pattern:"* (N)" and not matchPattern (((mainLayer8.getChild childH).name) as string) Pattern:"* (N)" then(
                                                                                                haveReachedBottomOfLayerStack = false
                                                                                            )
                                                                                        )
                                                                                    )

                                                                                if haveReachedBottomOfLayerStack = false then(
                                                                                )else(
                                                                                    append layersToProcess mainLayer8.name
                                                                                )
                                                                            )
                                                                        )else(
                                                                            append layersToProcess mainLayer7.name
                                                                        )
                                                                    )
                                                                )else(
                                                                    append layersToProcess mainLayer6.name
                                                                )
                                                            )
                                                        )else(
                                                            append layersToProcess mainLayer5.name
                                                        )
                                                    )
                                                )else(
                                                    append layersToProcess mainLayer4.name
                                                )
                                            )
                                        )else(
                                            append layersToProcess mainLayer3.name
                                        )
                                    )
                                )else(
                                    append layersToProcess mainLayer2.name
                                )
                            )
                        )else(
                            append layersToProcess callisScriptsMainLayer.name
                        )

                        for layerNameToProcess in layersToProcess do(
                            addMultimatteLayersToSpecifiedLayer layerNameToProcess
                        )
                    )catch()
                )

        -- Multimatte

            -- Remove ID override on all scene materials

                fn removeIDOverrideOnAllSceneMaterials =
                    for mat in scenematerials do(
                        try(
                            mat.override_effect_id = false
                        )catch()
                    )

            -- Set G buffer channel on all objects to 0

                fn setGBufferOnAllObjectsToZero = (
                    _tmpArray = geometry
                    _idArray = #()

                    for obj in _tmpArray do
                        obj.gBufferChannel = 0
                )

            -- Create multimatte elements by layer

                fn createByLayerMultimatteElement elementName gBufNumber = (
                    -- Select all objects in relevant layer

                        callisScriptsMainLayer = LayerManager.getLayerFromName elementName
                        selectAllObjectsInSpecifiedLayer callisScriptsMainLayer

                    -- Deselect any objects in multimatte by material layers

                        for o in selection do(
                            if matchPattern o.layer.name pattern:"* (M)" or matchPattern o.layer.name pattern:"* (N)" then(
                                deselect o
                            )
                        )

                    -- Create multimatte element from selection

                        if selection.count != undefined and selection.count > 0 then(
                            local _selectionArray = #()
                            local _collectionArray = #()
                            local _allSceneIDs = #()

                            -- Add multimatte elements

                                AddMultiMattes elementName gBufNumber
                        )

                    -- Select none

                        deselect selection
                )

            -- Update multimatte elements

                fn updateMultimatteElements = (
                    -- Consolidate default materials

                        local matLib = getDir #scripts + "\\CallisScripts\\Material Libraries\\Default Material.mat"
                        loadMaterialLibrary matLib

                        for o in objects do(
                            try(
                                if o.material.name == "Default Material" then(
                                    o.material = currentMaterialLibrary[1]
                                )
                            )catch()
                        )

                    -- Create arrays of layers to multimatte by layer and by material

                        layersToMultimatteByLayer = #()
                        layersToMultimatteByMaterial = #()

                        for i = 0 to LayerManager.count - 1 do (
                            -- Layers to multimatte by layer. Note: this gives the main (parent) layers containing all the multimatte specifying layers. Layers ending in "* (N)" will be removed from selection in the "createByLayerMultimatteElement" function.

                                if matchPattern (LayerManager.getLayer i).name pattern:"* (L)" then(
                                    if ((LayerManager.getLayer i).getParent()).name == "Glass (Non-Separate)" or ((LayerManager.getLayer i).getParent()).name == "Glass (Separate)" then(
                                        append layersToMultimatteByLayer (((LayerManager.getLayer i).getParent()).getParent()).name
                                    )else(
                                        append layersToMultimatteByLayer ((LayerManager.getLayer i).getParent()).name
                                    )
                                )

                            -- Layers to multimatte by material

                                if matchPattern (LayerManager.getLayer i).name pattern:"* (M)" or matchPattern (LayerManager.getLayer i).name pattern:"* (B)" then(
                                    append layersToMultimatteByMaterial (LayerManager.getLayer i).name
                                )
                        )

                    -- Remove ID override on all scene materials

                        removeIDOverrideOnAllSceneMaterials()

                    -- Set G buffer channel on all objects to 0

                        setGBufferOnAllObjectsToZero()

                    -- Run automultimatte script on relevant objects

                        -- Select objects in specified layers

                            -- Layers to omit from multimatte

                                for i = 1 to layersToMultimatteByMaterial.count do(
                                    try(
                                        callisScriptsMainLayer = LayerManager.getLayerFromName layersToMultimatteByMaterial[i]
                                        selectAllObjectsInSpecifiedLayer callisScriptsMainLayer
                                    )catch()
                                )

                        -- Run automultimatte script

                            runAutoMultimatteScript()

                        -- Select none

                            deselect selection

                    -- Create the by-layer multimatte elements

                        -- Run the script

                            for i = 1 to layersToMultimatteByLayer.count do(
                                try(
                                    gbufNum = i + 49

                                    createByLayerMultimatteElement layersToMultimatteByLayer[i] gbufNum
                                )catch()
                            )
                )

        -- Rendering

            -- Change Vray output path

                fn changeVrayOutputPath outputPath rawOutputPath = (
                    -- Settings

                        renderers.current.output_splitgbuffer = true
                        renderers.current.output_splitRGB = true
                        renderers.current.output_splitAlpha = true
                        renderers.current.output_saveRawFile = true

                    -- Declare output path

                        renderers.current.output_splitfilename = outputPath

                        renderers.current.output_rawFileName = rawOutputPath
                )

            -- Set frame size

                fn callisScriptsSetFrameSize highResDecision = (
                    -- Variables

                        local viewContainingCamera
                        local originalActiveViewport = viewport.activeViewport
                        local re
                        local outputPathPreliminary1
                        local outputPathPreliminary
                        local outputFolder
                        local outputPath
                        local rawOutputPath
                        local callisScriptsMainLayer
                        local vrayvfbIni
                        local vfbHistoryPath
                        local dateAndTimePartOne
                        local dateAndTimePartTwo
                        local dateAndTimePartThree
                        local dateAndTimePartFour
                        local dateAndTimeAllParts
                        local dateAndTimePreliminary3
                        local dateAndTimePreliminary2
                        local dateAndTimePreliminary1
                        local dateAndTimePreliminary
                        local dateAndTime

                    -- Get frame number

                        currentFrameNumberPreliminary = sliderTime as string

                        currentFrameNumberAsStringPreliminary = filterString currentFrameNumberPreliminary "f" splitEmptyTokens:false

                        currentFrameNumberAsString = currentFrameNumberAsStringPreliminary[1]

                        currentFrameNumberAsInteger = currentFrameNumberAsString as integer

                    -- Create variables

                        -- Create frameSizePreliminary3 variable

                            frameSizePreliminary32 = $'Frame Sizes Dummy'.layer.name

                            frameSizePreliminary3 = substituteString frameSizePreliminary32 "Frame Sizes: " ","

                        -- Create frameSizePreliminary2 variable

                            frameSizePreliminary22 = substituteString frameSizePreliminary3 ", " ","

                            frameSizePreliminary2 = filterString frameSizePreliminary22 ","

                        -- Create frameSizePreliminary1 variable

                            frameSizePreliminary1 = frameSizePreliminary2[currentFrameNumberAsInteger]

                        -- Create frameSizePreliminary0 variable

                            frameSizePreliminary0 = filterString frameSizePreliminary1 "."

                        -- Create frameSizePreliminary variable

                            frameSizePreliminary = frameSizePreliminary0[2]

                        -- Create frameSize variable

                            frameSize = substituteString frameSizePreliminary " " ""

                        -- Create frameSizeSingleAxis variable

                            frameSizeSingleAxis = filterString frameSize "x"

                        -- Create frameWidth variable

                            frameWidth = frameSizeSingleAxis[1]

                        -- Create frameHeight variable

                            frameHeight = frameSizeSingleAxis[2]

                        -- Convert to integers

                            if highResDecision == "true" then(
                                -- Create frameWidthAsInteger variable

                                    frameWidthAsIntegerPreliminary = frameWidth as integer

                                    frameWidthAsInteger = frameWidthAsIntegerPreliminary * 4

                                -- Create frameHeightAsInteger variable

                                    frameHeightAsIntegerPreliminary = frameHeight as integer

                                    frameHeightAsInteger = frameHeightAsIntegerPreliminary * 4
                            )

                            if highResDecision == "false" then(
                                -- Create frameWidthAsInteger variable

                                    frameWidthAsInteger = frameWidth as integer

                                -- Create frameHeightAsInteger variable

                                    frameHeightAsInteger = frameHeight as integer
                            )

                            if highResDecision == "test" then(
                                -- Create frameWidthAsInteger variable

                                    frameWidthAsIntegerPreliminary = frameWidth as integer

                                    frameWidthAsInteger = frameWidthAsIntegerPreliminary/2

                                -- Create frameHeightAsInteger variable

                                    frameHeightAsIntegerPreliminary = frameHeight as integer

                                    frameHeightAsInteger = frameHeightAsIntegerPreliminary/2
                            )

                            if highResDecision == "thumbnail" then(
                                -- Create frameWidthAsInteger variable

                                    frameWidthAsIntegerPreliminary = frameWidth as integer

                                    frameWidthAsInteger = frameWidthAsIntegerPreliminary/4

                                -- Create frameHeightAsInteger variable

                                    frameHeightAsIntegerPreliminary = frameHeight as integer

                                    frameHeightAsInteger = frameHeightAsIntegerPreliminary/4
                            )

                    -- Set frame size

                        renderers.current.output_width = frameWidthAsInteger

                        try(
                            renderWidth = frameWidthAsInteger
                        )catch()

                        renderers.current.output_height = frameHeightAsInteger

                        try(
                            renderHeight = frameHeightAsInteger
                        )catch()
                )

            -- Render current frame to corresponding folder Preliminary

                fn renderCurrentFrameToCorrespondingFolderPreliminary separateGlassDecision forceActiveViewDecision highResDecision saveDecision regionDecision = (
                    -- Variables

                        local viewContainingCamera
                        local originalActiveViewport = viewport.activeViewport
                        local re
                        local outputPathPreliminary1
                        local outputPathPreliminary
                        local outputFolder
                        local outputPath
                        local rawOutputPath
                        local callisScriptsMainLayer
                        local vrayvfbIni
                        local vfbHistoryPath
                        local dateAndTimePartOne
                        local dateAndTimePartTwo
                        local dateAndTimePartThree
                        local dateAndTimePartFour
                        local dateAndTimeAllParts
                        local dateAndTimePreliminary3
                        local dateAndTimePreliminary2
                        local dateAndTimePreliminary1
                        local dateAndTimePreliminary
                        local dateAndTime
                        local currentFileToBackup

                    -- Unlock view to render if it was locked

                        rendUseActiveView = true

                    -- Set view to Camera

                        if forceActiveViewDecision == "false" then(
                            try(
                                for a = 1 to viewport.numViews do(
                                    viewport.activeViewport = a

                                    if viewport.getType() == #view_camera then(
                                        viewContainingCamera = a
                                    )
                                )

                                if viewContainingCamera != undefined then(
                                    viewport.activeViewport = viewContainingCamera
                                )else(
                                    -- Variables

                                        oldLayer = LayerManager.current
                                        layer = layerManager.getLayerFromName "Temporary Script Objects"

                                    deselect cameras

                                    if viewport.getType() == #view_persp_user then(
                                        try(
                                            try(
                                                delete $CallisScriptsTemporaryPerspectiveCamera
                                            )catch()

                                            layer.current = true

                                            macros.run "Lights and Cameras" "PhysicalCamera_CreateFromView"

                                            activeCamera = getactivecamera()

                                            viewport.setCamera (getActiveFramesCamera())

                                            activeCamera.name = "CallisScriptsTemporaryPerspectiveCamera"

                                            hide activeCamera

                                            hide $CallisScriptsTemporaryPerspectiveCamera.Target

                                            oldLayer.current = true

                                            displaySafeFrames = true

                                            viewport.EnableSolidBackgroundColorMode false
                                        )catch()
                                    )else(
                                    )

                                    redrawViews()
                                )

                                viewport.setCamera (getActiveFramesCamera())
                            )catch()
                        )

                    -- Get frame number

                        currentFrameNumberPreliminary = sliderTime as string

                        currentFrameNumberAsStringPreliminary = filterString currentFrameNumberPreliminary "f" splitEmptyTokens:false

                        currentFrameNumberAsString = currentFrameNumberAsStringPreliminary[1]

                        currentFrameNumberAsInteger = currentFrameNumberAsString as integer

                    -- Run Change frame code to ensure sun, sky etc are set correctly

                        changeFrameNumber currentFrameNumberAsInteger

                    -- Get frame name

                        -- Create frameNamePreliminary2 variable

                            frameNamePreliminary22 = $'Frame Names Dummy'.layer.name

                            frameNamePreliminary2 = substituteString frameNamePreliminary22 "Frame Names: " ","

                        -- Create frameNamePreliminary1 variable

                            frameNamePreliminary12 = substituteString frameNamePreliminary2 ", " ","

                            frameNamePreliminary1 = filterString frameNamePreliminary12 ","

                        -- Create frameName variable

                            frameName = frameNamePreliminary1[currentFrameNumberAsInteger]

                    -- Hide glass to separate layers if relevant

                        if separateGlassDecision == "true" then(
                            try(
                                layerToHide = LayerManager.getLayerFromName "Glass (Separate)"
                                layerToHide.on = false
                            )catch()
                        )

                    -- Set region on or off

                        if regionDecision == "region" then(
                            vrayVFBSetRegionEnabled true
                        )

                        if regionDecision == "noRegion" then(
                            vrayVFBSetRegionEnabled false
                        )

                    -- Set output path

                        if saveDecision == "save" then(
                            -- Create outputPath variable

                                outputPathPreliminary1 = $'Output Path Dummy'.layer.name

                                outputPathPreliminary = substituteString outputPathPreliminary1 "Output Path: " ""

                                if highResDecision == "true" then(
                                    outputFolder = outputPathPreliminary + "\\" + frameName + "\\" + "High Res"

                                    outputPath = outputPathPreliminary + "\\" + frameName + "\\" + "High Res" + "\\" + ".exr"

                                    rawOutputPath = outputPathPreliminary + "\\" + frameName + "\\" + "High Res" + "\\" + ".vrimg"
                                )else(
                                    outputFolder = outputPathPreliminary + "\\" + frameName + "\\" + "Low Res"

                                    outputPath = outputPathPreliminary + "\\" + frameName + "\\" + "Low Res" + "\\" + ".exr"

                                    rawOutputPath = outputPathPreliminary + "\\" + frameName + "\\" + "Low Res" + "\\" + ".vrimg"
                                )

                            -- Create relevant folder is it doesn't exist

                                if doesFileExist outputFolder == false do(
                                    makeDir outputFolder
                                )
                        )else(
                            -- Create outputPath variable

                                outputPath = ""

                                rawOutputPath = ""
                        )

                        -- Set output path

                            changeVrayOutputPath outputPath rawOutputPath

                    -- Set frame size

                        callisScriptsSetFrameSize highResDecision

                    -- Delete all relevant files in the folder

                        if saveDecision == "save" then(
                            makeDir (outputFolder + "\\Backup")

                            for a in getFiles (outputFolder + "\\*.exr") do(
                                -- Variables

                                    currentFileToBackup = (getFilenameFile a + getFilenameType a)

                                renameFile a (outputFolder + "\\Backup\\" + currentFileToBackup)
                            )

                            for a in getFiles (outputFolder + "\\*DisregardMe*") do(
                                -- Variables

                                    currentFileToBackup = (getFilenameFile a + getFilenameType a)

                                renameFile a (outputFolder + "\\Backup\\" + currentFileToBackup)
                            )

                            for a in getFiles (outputFolder + "\\*.vrimg") do(
                                -- Variables

                                    currentFileToBackup = (getFilenameFile a + getFilenameType a)

                                renameFile a (outputFolder + "\\Backup\\" + currentFileToBackup)
                            )
                        )

                    -- Quick render

                        max quick render

                    -- Recover backup files if render was cancelled, otherwise delete them

                        if saveDecision == "save" then(
                            if (getFiles (outputFolder + "\\*.exr")).count != 0 and (getFiles (outputFolder + "\\*.exr")).count != undefined then(
                                fileClass = dotNetClass "System.IO.Directory"
                                backupFolderToDelete = (outputFolder + "\\Backup")
                                fileClass.Delete backupFolderToDelete true
                            )else(
                                for a in getFiles (outputFolder + "\\Backup\\" + "\\*.exr") do(
                                    -- Variables

                                        currentFileToBackup = getFilenameFile a + getFilenameType a

                                    renameFile a (outputFolder + "\\" + currentFileToBackup)
                                )

                                for a in getFiles (outputFolder + "\\Backup\\" + "\\*DisregardMe*") do(
                                    -- Variables

                                        currentFileToBackup = getFilenameFile a + getFilenameType a

                                    renameFile a (outputFolder + "\\" + currentFileToBackup)
                                )

                                for a in getFiles (outputFolder + "\\Backup\\" + "\\*.vrimg") do(
                                    -- Variables

                                        currentFileToBackup = getFilenameFile a + getFilenameType a

                                    renameFile a (outputFolder + "\\" + currentFileToBackup)
                                )

                                fileClass = dotNetClass "System.IO.Directory"
                                backupFolderToDelete = (outputFolder + "\\Backup")
                                fileClass.Delete backupFolderToDelete true
                            )
                        )

                    -- Create currentFrameNumberAsStringFull variable

                        if currentFrameNumberAsInteger < 10 then(
                            currentFrameNumberAsStringFull = "000" + currentFrameNumberAsString
                        )

                        if currentFrameNumberAsInteger > 9 and currentFrameNumberAsInteger < 100 then(
                            currentFrameNumberAsStringFull = "00" + currentFrameNumberAsString
                        )

                        if currentFrameNumberAsInteger > 99 and currentFrameNumberAsInteger < 1000 then(
                            currentFrameNumberAsStringFull = "0" + currentFrameNumberAsString
                        )

                        if currentFrameNumberAsInteger > 999 then(
                            currentFrameNumberAsStringFull = currentFrameNumberAsString
                        )

                    -- Copy vrimg to the VFB history folder

                        --try(
                            if saveDecision == "save" then(
                                -- Variables etc.

                                    vrayvfbIni = (getdir #plugcfg) + "/vrayvfb.ini"
                                    vfbHistoryPath = getINISetting vrayvfbIni "History" "Path"

                                    dateAndTimePartOne = subString localTime 7 5
                                    dateAndTimePartTwo = substring localtime 4 2
                                    dateAndTimePartThree = subString localTime 1 2
                                    dateAndTimePartFour = subString localTime 12 100
                                    dateAndTimeAllParts = ("vfbHistory_" + dateAndTimePartOne + dateAndTimePartTwo + " " + dateAndTimePartThree + " " + dateAndTimePartFour)
                                    dateAndTimePreliminary3 = substituteString dateAndTimeAllParts "AM" "000"
                                    dateAndTimePreliminary2 = substituteString dateAndTimePreliminary3 "PM" "000"
                                    dateAndTimePreliminary1 = substituteString dateAndTimePreliminary2 " " "_"
                                    dateAndTimePreliminary = substituteString dateAndTimePreliminary1 "/" "_"
                                    dateAndTime = substituteString dateAndTimePreliminary ":" "_"

                                copyFile (outputFolder + "\\." + currentFrameNumberAsStringFull + ".vrimg") (vfbHistoryPath + "\\" + dateAndTime + ".vrimg")
                            )
                        --)catch()

                    -- Run glass to separate code if relevant

                        if separateGlassDecision == "true" then(
                            -- Show glass to separate layers

                                try(
                                    layerToHide = LayerManager.getLayerFromName "Glass (Separate)"
                                    layerToHide.on = true
                                )catch()

                            -- Create reflection pass for isolated glass

                                re = maxOps.GetCurRenderElementMgr()

                                re.addrenderelement (VrayReflection elementname:("All Isolated Glass To Rename"))

                            -- Clear all multimatte layers

                                clearMultiMatteElements()

                            -- Create multimatte element from glass to separate layers

                                -- Select relevant objects

                                    callisScriptsMainLayer = LayerManager.getLayerFromName "Glass (Separate)"
                                    selectAllObjectsInSpecifiedLayer callisScriptsMainLayer

                                -- Create multimatte element from selection
                                    if selection.count != undefined and selection.count > 0 then(
                                        (
                                          local _selectionArray = #()
                                          local _collectionArray = #()
                                          local _allSceneIDs = #()

                                          -- Add multimatte elements

                                              AddMultiMattes "All Isolated Glass" 1
                                        )
                                    )

                                -- Select none

                                    deselect selection

                            -- Delete all relevant files in the folder

                                try(
                                    hiddenDOSCommand "del *Glass*Isolated*" startpath:(outputFolder)
                                )catch()

                            -- Change output name to "Glass_Isolated_.exr"

                                -- Create outputPath variable

                                    outputPathPreliminary1 = $'Output Path Dummy'.layer.name

                                    outputPathPreliminary = substituteString outputPathPreliminary1 "Output Path: " ""

                                    if highResDecision == "true" then(
                                        outputFolder = outputPathPreliminary + "\\" + frameName + "\\" + "High Res"

                                        outputPath = outputPathPreliminary + "\\" + frameName + "\\" + "High Res" + "\\" + "Glass_Isolated_.exr"
                                    )else(
                                        outputFolder = outputPathPreliminary + "\\" + frameName + "\\" + "Low Res"

                                        outputPath = outputPathPreliminary + "\\" + frameName + "\\" + "Low Res" + "\\" + "Glass_Isolated_.exr"
                                    )

                                    rawOutputPath = ""

                                -- Set output path

                                    changeVrayOutputPath outputPath rawOutputPath

                            -- Quick render

                                max quick render

                            -- Rename isolated glass passes

                                renameFile (outputFolder + "\\" + "Glass_Isolated_." + "All_Isolated_Glass_To_Rename." + currentFrameNumberAsStringFull + ".exr") (outputFolder + "\\" + ".Isolated_Glass." + currentFrameNumberAsStringFull + ".exr")

                                renameFile (outputFolder + "\\" + "Glass_Isolated_." + "MultimatteAll_Isolated_Glass." + currentFrameNumberAsStringFull + ".exr") (outputFolder + "\\" + ".MultimatteIsolated_Glass." + currentFrameNumberAsStringFull + ".exr")

                                -- World Normals

                                    renameFile (outputFolder + "\\" + "Glass_Isolated_." + "World_Normals_-_x." + currentFrameNumberAsStringFull + ".exr") (outputFolder + "\\" + ".World_Normals_-_x_(Glass)." + currentFrameNumberAsStringFull + ".exr")

                                    renameFile (outputFolder + "\\" + "Glass_Isolated_." + "World_Normals_+_x." + currentFrameNumberAsStringFull + ".exr") (outputFolder + "\\" + ".World_Normals_+_x_(Glass)." + currentFrameNumberAsStringFull + ".exr")

                                    renameFile (outputFolder + "\\" + "Glass_Isolated_." + "World_Normals_-_y." + currentFrameNumberAsStringFull + ".exr") (outputFolder + "\\" + ".World_Normals_-_y_(Glass)." + currentFrameNumberAsStringFull + ".exr")

                                    renameFile (outputFolder + "\\" + "Glass_Isolated_." + "World_Normals_+_y." + currentFrameNumberAsStringFull + ".exr") (outputFolder + "\\" + ".World_Normals_+_y_(Glass)." + currentFrameNumberAsStringFull + ".exr")

                                    renameFile (outputFolder + "\\" + "Glass_Isolated_." + "World_Normals_-_z." + currentFrameNumberAsStringFull + ".exr") (outputFolder + "\\" + ".World_Normals_-_z_(Glass)." + currentFrameNumberAsStringFull + ".exr")

                                    renameFile (outputFolder + "\\" + "Glass_Isolated_." + "World_Normals_+_z." + currentFrameNumberAsStringFull + ".exr") (outputFolder + "\\" + ".World_Normals_+_z_(Glass)." + currentFrameNumberAsStringFull + ".exr")

                                    renameFile (outputFolder + "\\" + "Glass_Isolated_." + "Fresnel." + currentFrameNumberAsStringFull + ".exr") (outputFolder + "\\" + ".Fresnel_(Glass)." + currentFrameNumberAsStringFull + ".exr")

                            -- Delete all relevant files in the folder

                                if saveDecision == "save" then(
                                    try(
                                        hiddenDOSCommand "del *Glass*Isolated*" startpath:(outputFolder)
                                    )catch()
                                )

                            -- Delete the render passes added

                                -- Clear all multimatte layers

                                    clearMultiMatteElements()

                                -- Delete the reflection pass (bottom pass in the list of passes)

                                    re = maxOps.GetCurRenderElementMgr()

                                    element = re.getRenderElement((re.numrenderelements()) - 1)
                                    re.RemoveRenderElement(element)

                            -- Recreate multimatte layers

                                updateMultimatteElements()
                        )

                    -- Delete new dummy files in output path

                        hiddenDOSCommand "del *DisregardMe*" startpath:(getFilenamePath rendOutputFilename)

                    -- Remove frame number from the names of the exr files, if they are present

                        if saveDecision == "save" then(
                            if (getFiles (outputFolder + "\\*.exr")).count != 0 and (getFiles (outputFolder + "\\*.exr")).count != undefined then(
                                -- Define the directory path where you want to search for .exr files
                                local RezasDirectoryPath = outputFolder

                                -- Get a list of .exr files in the directory
                                local exrFiles = getFiles (RezasDirectoryPath + "\\*.exr")

                                -- Loop through each .exr file
                                for exrFile in exrFiles do(
                                    print "Hi"

                                    -- Get the filename without the extension
                                    local fileNameWithoutExtension = getFilenameFile exrFile

                                    -- Check if the last 5 characters of the filename begin with ".00"
                                    if matchPattern fileNameWithoutExtension pattern:"*.00??" then(
                                        -- Remove the last 5 characters from the filename
                                        local newFileName = substring fileNameWithoutExtension 1 (fileNameWithoutExtension.count - 5)

                                        -- Construct the new full path with the updated filename and extension
                                        local newFilePath = RezasDirectoryPath + "\\" + newFileName + ".exr"

                                        print newFilePath

                                        -- Rename the file
                                        renameFile exrFile newFilePath
                                    )
                                )
                            )
                        )

                    -- If view was perspective before rendering, set it back to perspective

                        if forceActiveViewDecision == "false" then(
                            if viewContainingCamera == undefined then(
                                try(
                                    viewport.setCamera $CallisScriptsTemporaryPerspectiveCamera

                                    redrawViews()

                                    displaySafeFrames = false

                                    viewport.EnableSolidBackgroundColorMode false

                                    actionMan.executeAction 0 "40182"  -- Views: Perspective User View
                                )catch()
                            )
                        )

                    -- Ensure active viewport is what it was before rendering

                        viewport.activeViewport = originalActiveViewport
                )

        -- Set layers' visibility back to what it was before running the render script

            -- Show relevant hidden layers

                fn showRelevantHiddenLayers = (
                    local myLayer

                    for o = 0 to LayerManager.count-1 do(
                        myLayer = LayerManager.getLayer o

                        if matchPattern myLayer.name pattern:"*—*" == true and myLayer.on == false then(
                            myLayer.on = true

                            append layersToHideAfterRendering myLayer
                        )
                    )
                )

            -- Hide relevant shown layers

                fn hideRelevantShownLayers = (
                    for i = 1 to layersToHideAfterRendering.count do(
                        layersToHideAfterRendering[i].on = false
                    )

                    layersToHideAfterRendering = #()
                )

        -- Update light-select render elements

            fn updateLightSelectElements = (
                -- Variables

                		local insLights = #()
                		local artificialLights = #()
                		local re = maxOps.GetCurRenderElementMgr()

                -- Script

                		-- Remove existing light select elements

                				lightSelectElementsArray = #()

                				re = maxOps.GetCurRenderElementMgr() -- get the current render element manager

                				for n = 1 to re.numrenderelements() do(
                						element = re.getRenderElement(n-1)
                						if classOf element == VRayLightSelect do(
                								append lightSelectElementsArray element
                						)
                				)

                				for e in lightSelectElementsArray do
                						re.RemoveRenderElement(e)

                				tmpString = "Removed " + lightSelectElementsArray.count as string + " MultiMatte Render Elements..."

                		-- Add the elements

                				numr = re.numrenderelements()
                				numr2 = numr - 1
                				vls = VRayLightSelect()
                				vls.elementName = "Sun"
                				vls.mode = 1

                				artificialLightsElement = VRayLightSelect()
                				artificialLightsElement.elementName = "Raw Lighting"
                				artificialLightsElement.mode = 1



                				sunLayer = (layermanager.getLayerFromName "Sun")
                				skyLayer = (layermanager.getLayerFromName "Sky")

                				sunLayer.nodes &sunLayerNodes
                				skyLayer.nodes &skyLayerNodes

                				for i = 1 to sunLayerNodes.count do(
                						if superClassOf sunLayerNodes[i] == light then(
                								append insLights sunLayerNodes[i]
                						)
                				)

                				for i = 1 to skyLayerNodes.count do(
                						if superClassOf skyLayerNodes[i] == light then(
                								append insLights skyLayerNodes[i]
                						)
                				)

                				for l in lights do(
                						if superClassOf l == light and l.layer.name != "Sun" and l.layer.name != "Sky" then(
                								append artificialLights l
                						)
                				)

                				if insLights.count > 0 then(
                				vls.lights = insLights
                				)

                				if artificialLights.count > 0 then(
                				artificialLightsElement.lights = artificialLights
                				)

                				re.AddRenderElement vls
                				re.AddRenderElement artificialLightsElement
            )

        /*
        -- Material guesser

            -- Variables

                materialGuesserIni = (getdir #plugcfg_ln) + "/Callis Scripts/Material Guesser.ini"
                materialGuesserLibraryPreliminary = getDir #scripts + "\\CallisScripts\\Material Libraries\\Material Guesser.mat"
                materialGuesserLibrary = materialGuesserLibraryPreliminary

            -- Functions

                -- Get selected material

                    function getSelectedMaterial = (
                        viewNode = sme.GetView (sme.activeView)
                        selectedMaterials = #()

                        for n = 1 to trackViewNodes[#sme][(sme.activeView)].numSubs do(
                          m = trackViewNodes[#sme][(sme.activeView)][n].reference
                          b = viewNode.GetNodeByRef m
                          if b.selected do append selectedMaterials m
                        )

                        if selectedMaterials.count > 0 then(
                           return selectedMaterials[1]
                        )
                    )

                -- Overwrite to .ini file

                    fn overwriteToIniFile path section key text = (
                        -- Close the .ini file if open

                            try(
                                close path
                            )catch()

                        -- Write to .ini file

                            try(
                                delIniSetting path section key
                            )catch()

                            setINISetting path section key text
                    )

                -- Get arrays from .ini file

                    fn materialGuesserGetTagsArray = (
                        local tagsString = getINISetting materialGuesserIni "Material Guesser" "Tags"

                        filterString tagsString "|"
                    )

                    fn materialGuesserGetMaterialNamesArray = (
                        local materialNamesString = getINISetting materialGuesserIni "Material Guesser" "Material Names"

                        filterString materialNamesString "|"
                    )

                -- Convert array back to string for .ini file

                    fn materialGuesserConvertArrayBacktoString stringsArray = (
                        -- Variables

                            local newItemsString = ""

                        for i = 1 to stringsArray.count do(
                            currentStringsArrayItem = stringsArray[i]

                            currentItemsString = newItemsString + currentStringsArrayItem

                            if i != stringsArray.count then(
                                newItemsString = currentItemsString + "|"
                            )else(
                                newItemsString = currentItemsString
                            )
                        )

                        newItemsString
                    )

                -- Add new material to .ini file

                    fn materialGuesserAddNewMaterialToIniFile newmaterialName materialGuesserSlotNumber = (
                        -- Variables

                            local currentMaterialNamesString
                            local currentTagsString
                            local materialNamesArray
                            local tagsArray
                            local currentMaterialNamesArrayItem
                            local currentTagsArrayItem

                            local oldMaterialNamesString = getINISetting materialGuesserIni "Material Guesser" "Material Names"
                            local oldTagsString = getINISetting materialGuesserIni "Material Guesser" "Tags"

                            materialNamesArray = filterString oldMaterialNamesString "|"
                            tagsArray = filterString oldTagsString "|"

                        insertItem newmaterialName materialNamesArray materialGuesserSlotNumber
                        insertItem "materialGuesserDummyTag" tagsArray materialGuesserSlotNumber

                        newMaterialNamesString = materialGuesserConvertArrayBacktoString materialNamesArray
                        newTagsString = materialGuesserConvertArrayBacktoString tagsArray

                        overwriteToIniFile materialGuesserIni "Material Guesser" "Material Names" newMaterialNamesString

                        overwriteToIniFile materialGuesserIni "Material Guesser" "Tags" newTagsString
                    )

                -- Insert new material slot

                    fn materialGuesserInsertNewMaterialSlot materialGuesserSlotNumber = (
                        -- Variables

                            local oldMaterialNamesString = getINISetting materialGuesserIni "Material Guesser" "Material Names"
                            local materialNamesArray = filterString oldMaterialNamesString "|"
                            local materialNameIsTaken = false

                            local selectedMaterial = getSelectedMaterial()

                        -- Load the material library

                            loadMaterialLibrary materialGuesserLibrary

                        -- Ensure active material name isn't already in the .ini file

                            for a in materialNamesArray do(
                                if matchPattern a pattern:(selectedMaterial.name) then(
                                    materialNameIsTaken = true
                                )
                            )

                        -- Add the material to library and .ini file

                            if materialNameIsTaken == false then(
                                if (materialGuesserSlotNumber - 1) > materialNamesArray.count then( -- The - 1 is to counteract the + 1 in the rollout's actions section.
                                    messageBox ("The specified slot number is higher than the number of slots. Please change the slot number and try again.")
                                )else(
                                    append currentMaterialLibrary selectedMaterial

                                    saveTempMaterialLibrary currentMaterialLibrary materialGuesserLibrary

                                    materialGuesserAddNewMaterialToIniFile selectedMaterial.name materialGuesserSlotNumber
                                )
                            )else(
                                messageBox ("A material named " + "'" + selectedMaterial.name + "'" + " already exists in another slot. Please change the name or choose another material.")
                            )
                    )

                -- Add tags to material

                    fn materialGuesserAddTagsToMaterial = (
                        -- Define tags dialog

                            rollout materialGuesserTagsDialogue "Material Guesser Tags"(
                                -- Variables

                                    -- Converting from .ini to editText

                                        local materialGuesserIni = (getdir #plugcfg_ln) + "/Callis Scripts/Material Guesser.ini"
                                        local oldTagsString = getINISetting materialGuesserIni "Material Guesser" "Tags"
                                        local tagsArray = filterString oldTagsString "|"
                                        local slotNumberAsString = getINISetting materialGuesserIni "Material Guesser" "Last Edited Slot"
                                        local slotNumber = slotNumberAsString as integer
                                        local currentSlotsTagsPreliminary1 = substituteString tagsArray[slotNumber] "materialGuesserDummyTag" "" -- If the tag is a dummy, this turns it into an empty string. Need to do it this way, as an if-else statement can't go in the top level of a rollout.
                                        local currentSlotsTagsPreliminary = substituteString currentSlotsTagsPreliminary1 "/" "\n"
                                        local currentSlotsTags = substituteString currentSlotsTagsPreliminary "," ", "
                                        local newText

                                -- Components

                                    group ""(
                                        edittext tagsEditText "" text:currentSlotsTags fieldWidth:190 height:300 labelOnTop:true

                                        button materialGuesserUpdateTagsButton "Update Tags"
                                    )

                                -- Actions

                                    on tagsEditText changed text do(
                                        newText = text
                                    )

                                    on materialGuesserUpdateTagsButton pressed do(
                                        -- Variables

                                            -- Converting from editText to .ini

                                                local newTagsStringToInsertPreliminary = substituteString newText ", " ","
                                                local newTagsStringToInsert = substituteString newTagsStringToInsertPreliminary "\n" "/"
                                                local newTagsStringToInsertWithoutSlashes = substituteString newTagsStringToInsert "/" ""

                                                if newTagsStringToInsertWithoutSlashes == "" or newTagsStringToInsertWithoutSlashes == undefined then(
                                                    newTagsStringToInsert = "materialGuesserDummyTag"
                                                )

                                                local newTagsArray = deleteItem tagsArray slotNumber
                                                insertItem newTagsStringToInsert newTagsArray slotNumber
                                                local newTagsString = materialGuesserConvertArrayBacktoString newTagsArray

                                        destroyDialog materialGuesserTagsDialogue

                                        overwriteToIniFile materialGuesserIni "Material Guesser" "Tags" newTagsString
                                    )
                            )

                        -- Create tags dialog

                            createDialog materialGuesserTagsDialogue 220 505
                    )

                -- Add material to slot

                    fn materialGuesserAddMaterialToSlot = (
                        -- Variables

                            local materialGuesserIni = (getdir #plugcfg_ln) + "/Callis Scripts/Material Guesser.ini"
                            local slotNumberAsString = getINISetting materialGuesserIni "Material Guesser" "Last Edited Slot"
                            local slotNumber = slotNumberAsString as integer
                            local selectedMaterial = getSelectedMaterial()

                            -- Material names

                                -- Converting from .ini to editText

                                    local oldMaterialNamesString = getINISetting materialGuesserIni "Material Guesser" "Material Names"
                                    local materialNamesArray = filterString oldMaterialNamesString "|"

                                -- Converting from editText to .ini

                                    local newMaterialNamesArray = deleteItem materialNamesArray slotNumber
                                    insertItem selectedMaterial.name newMaterialNamesArray slotNumber
                                    local newMaterialNamesString = materialGuesserConvertArrayBacktoString newMaterialNamesArray

                            -- Bitmap paths

                                -- Converting from .ini to editText

                                    local oldBitmapPathsString = getINISetting materialGuesserIni "Material Guesser" "Bitmap Paths"
                                    local BitmapPathsArray = filterString oldBitmapPathsString "|"

                                -- Converting from editText to .ini

                                    local materialGuesserBitMapPathPreliminary = (getSubTexMap selectedMaterial 1)
                                    local materialGuesserBitMapPath

                                    if materialGuesserBitMapPathPreliminary != undefined then(
                                        materialGuesserBitMapPath = (usedMaps materialGuesserBitMapPathPreliminary)[1]
                                    )

                                    if materialGuesserBitMapPathPreliminary == "Ok" or (ClassOf materialGuesserBitMapPath) != String then(
                                        materialGuesserBitMapPath = "materialGuesserDummyBitmapPath"
                                    )

                                    local newBitmapPathsArray = deleteItem BitmapPathsArray slotNumber
                                    insertItem materialGuesserBitMapPath newBitmapPathsArray slotNumber
                                    local newBitmapPathsString = materialGuesserConvertArrayBacktoString newBitmapPathsArray

                            local oldMaterialNamesString = getINISetting materialGuesserIni "Material Guesser" "Material Names"
                            local materialNamesArray = filterString oldMaterialNamesString "|"
                            local materialNameIsTaken = false

                        -- Load the material library

                            loadMaterialLibrary materialGuesserLibrary

                        -- Ensure active material name isn't already in the .ini file

                            for a in materialNamesArray do(
                                if matchPattern a pattern:(selectedMaterial.name) then(
                                    materialNameIsTaken = true
                                )
                            )

                        -- Add the material to library and .ini file

                            if materialNameIsTaken == false then(
                                append currentMaterialLibrary selectedMaterial

                                saveTempMaterialLibrary currentMaterialLibrary materialGuesserLibrary

                                overwriteToIniFile materialGuesserIni "Material Guesser" "Material Names" newMaterialNamesString

                                overwriteToIniFile materialGuesserIni "Material Guesser" "Bitmap Paths" newBitmapPathsString
                            )else(
                                messageBox ("A material named " + "'" + selectedMaterial.name + "'" + " already exists in another slot. Please change the name or choose another material.")
                            )
                    )
        */

    -- Main functions

        -- Render

            fn callisScriptsRender = (
                -- Define renderSpecifiedFrames dialog

                    rollout renderSpecifiedFrames "Render"(
                        -- Components

                            -- Render Components

                                group ""(
                                    edittext prefix_txt "Frames (separated by comma + space)" fieldWidth:190 labelOnTop:true

                                    checkbox lowResCheckBox "Low res" checked:true tooltip:"Renders specified resolution to low res folder" pos:[10,65]

                                    checkbox highResCheckBox "High res" checked:false tooltip:"Renders 4x specified resolution to high res folder" pos:[75,65]

                                    checkbox lowAndHighResCheckBox "Both" checked:false tooltip:"Renders both low and high res (respectively) to their respective folders" pos:[140,65]

                                    checkbox saveOutputCheckBox "Save output" checked:true tooltip:"" pos:[10,95]

                                    checkbox saveSceneCheckBox "Save scene" checked:true tooltip:"" pos:[113,95]

                                    checkbox renderRegionCheckBox "Render region" checked:false tooltip:"" pos:[10,115]

                                    checkbox forceActiveViewCheckBox "Active View" checked:false tooltip:"If checked, this box will force Max to render from the currently active view. If unchecked, Max will render from the active frame's camera if available" pos:[113,115]

                                    checkbox separateGlassCheckbox "Separate Glass" checked:false tooltip:"" pos:[10,135]

                                    checkbox updatePassesCheckbox "Update Passes" checked:false tooltip:"" pos:[113,135]
                                )

                            -- Photoshop components

                                group ""(
                                    -- Choose whether to run Photoshop scripts

                                        checkbox runPhotoshopScriptsUponCompletion "Run Photoshop scripts" checked:false tooltip:"Run photoshop scripts upon completion" pos:[10,175]

                                    -- Choose script to run

                                        checkbox initialOrganisation "Initial Org" checked:true tooltip:"" pos:[10,205] enabled:false

                                        checkbox rerenderOrganisationSameLocation "Rerender Same" checked:false tooltip:"" pos:[113,205] enabled:false

                                        checkbox rerenderOrganisationNewLocation "Rerender New" checked:false tooltip:"" pos:[10,225] enabled:false

                                        checkbox highResify "High Resify" checked:false tooltip:"" pos:[113,225] enabled:false

                                    -- Resolution components

                                        checkbox photoshopDoForLowRes "Low Res" checked:true tooltip:"" pos:[10,255] enabled:false

                                        checkbox photoshopDoForHighRes "High Res" checked:false tooltip:"" pos:[75,255] enabled:false

                                    -- Bit depth components

                                        checkbox photoshopDoFor32b "32b" checked:true tooltip:"" pos:[10,285] enabled:false

                                        checkbox photoshopDoFor16b "16b" checked:false tooltip:"" pos:[75,285] enabled:false

                                        checkbox photoshopDoFor16bAnd32b "Both" checked:false tooltip:"" pos:[140,285] enabled:false

                                    -- Overwrite components

                                        checkbox overwriteExistingFiles "Overwrite existing files" checked:false tooltip:"If unchecked, any existing Photoshop files found for the specified frame numbers will be opened without modification" pos:[10,315] enabled:false

                                    -- Frames components

                                        checkbox photoshopCurrentFrames "All frames about to be rendered" checked:true tooltip:"" pos:[10,345] enabled:false

                                        checkbox photoshopAllFrames "All Frames in output folder" checked:false tooltip:"" pos:[10,365] enabled:false

                                        checkbox photoshopSpecifiedFrames "Specify frames:" checked:false tooltip:"" pos:[10,385] enabled:false

                                        edittext photoshopSpecifiedFramesText "" pos:[10,405] fieldWidth:190 labelOnTop:false enabled:false

                                        edittext photoshopOriginalFrameText "Source frame number:" pos:[14,427] fieldWidth:190 labelOnTop:true enabled:false
                                )

                            -- Render button

                                button renderButton "Final" offset:[0,0] pos:[168,475]

                                button previewButton "Preview" offset:[0,0] pos:[109,475]

                                button testButton "Test" offset:[0,0] pos:[67,475]

                                button thumbnailButton "Thumb" offset:[0,0] pos:[14,475]

                        -- Actions

                            -- Open dialog actions

                                on renderSpecifiedFrames open do(
                                    highResDecisionVar = "false"
                                )

                            -- Render actions

                                -- Ensure no doubleups on 3ds max resolution checkboxes

                                    on lowResCheckBox changed lowResState do(
                                        if lowResState then(
                                            highResCheckBox.checked = false

                                            lowAndHighResCheckBox.checked = false

                                            photoshopDoForLowRes.checked = true

                                            photoshopDoForHighRes.checked = false
                                        )else(
                                            lowResCheckBox.checked = true

                                            photoshopDoForLowRes.checked = false

                                            photoshopDoForHighRes.checked = true
                                        )
                                    )

                                    on highResCheckBox changed highResState do(
                                        if highResState then(
                                            lowResCheckBox.checked = false

                                            lowAndHighResCheckBox.checked = false

                                            photoshopDoForLowRes.checked = false

                                            photoshopDoForHighRes.checked = true
                                        )else(
                                            highResCheckBox.checked = true

                                            photoshopDoForLowRes.checked = true

                                            photoshopDoForHighRes.checked = false
                                        )
                                    )

                                    on lowAndHighResCheckBox changed lowAndHighResState do(
                                        if lowAndHighResState then(
                                            lowResCheckBox.checked = false

                                            highResCheckBox.checked = false
                                        )else(
                                            lowAndHighResCheckBox.checked = true
                                        )
                                    )

                                -- Create frameNumber and frameNumberString variables

                                    on prefix_txt entered txt do(
                                        if txt != "" do(
                                            -- Create frameNumbers variable

                                                if txt == "C" or txt == "c" then(
                                                    -- Get frame number

                                                        currentFrameNumberPreliminary = sliderTime as string

                                                        currentFrameNumberAsStringPreliminary = filterString currentFrameNumberPreliminary "f" splitEmptyTokens:false

                                                        currentFrameNumberAsString = currentFrameNumberAsStringPreliminary[1]

                                                        frameNumbers = currentFrameNumberAsString
                                                        frameNumbersString = currentFrameNumberAsString
                                                )else(
                                                    frameNumbers = filterString txt ", "
                                                    frameNumbersString = txt
                                                )
                                        )
                                    )

                                -- Ensure Photoshop scripts don't run and separate glass can't be checked if output isn't saved

                                    on saveOutputCheckBox changed saveOutputCheckBoxState do(
                                        if saveOutputCheckBoxState then(
                                            -- Run Photoshop scripts upon completion

                                                runPhotoshopScriptsUponCompletion.enabled = true

                                            -- Separate glass

                                                separateGlassCheckbox.enabled = true
                                        )else(
                                            -- Run Photoshop scripts upon completion

                                                runPhotoshopScriptsUponCompletion.checked = false

                                                runPhotoshopScriptsUponCompletion.enabled = false

                                            -- Separate glass

                                                separateGlassCheckbox.enabled = false

                                                separateGlassCheckbox.checked = false

                                            -- Initial prompt

                                                initialOrganisation.enabled = false

                                                rerenderOrganisationSameLocation.enabled = false

                                                rerenderOrganisationNewLocation.enabled = false

                                                highResify.enabled = false

                                            -- Resolution

                                                photoshopDoForLowRes.enabled = false

                                                photoshopDoForHighRes.enabled = false

                                            -- Bit depth

                                                photoshopDoFor32b.enabled = false

                                                photoshopDoFor16b.enabled = false

                                                photoshopDoFor16bAnd32b.enabled = false

                                            -- Overwrite existing files

                                                overwriteExistingFiles.enabled = false

                                            -- Frames

                                                photoshopCurrentFrames.enabled = false

                                                photoshopAllFrames.enabled = false

                                                photoshopSpecifiedFrames.enabled = false

                                                photoshopSpecifiedFramesText.enabled = false

                                                photoshopOriginalFrameText.enabled = false
                                        )
                                    )

                            -- Photoshop actions

                                -- Create photoshopFrameNumber and photoshopFrameNumbersString variables

                                    on photoshopSpecifiedFramesText entered photoshopSpecifiedFramesTextText do(
                                        -- Create photoshopFrameNumbers variable

                                            photoshopFrameNumbers = filterString photoshopSpecifiedFramesTextText ", "
                                            photoshopFrameNumbersString = photoshopSpecifiedFramesTextText
                                    )

                                -- Create photoshopOriginalFrameNumber variable

                                    on photoshopOriginalFrameText entered photoshopOriginalFrameTextText do(
                                        -- Create photoshopOriginalFrameNumber variable

                                            photoshopOriginalFrameNumber = photoshopOriginalFrameTextText
                                    )

                                -- Disabling/enabling

                                    -- Run photoshop scripts upon completion

                                        on runPhotoshopScriptsUponCompletion changed runPhotoshopScriptsUponCompletionState do(
                                            if runPhotoshopScriptsUponCompletionState then(
                                                -- Initial prompt

                                                    initialOrganisation.enabled = true

                                                    rerenderOrganisationSameLocation.enabled = true

                                                    rerenderOrganisationNewLocation.enabled = true

                                                    highResify.enabled = true

                                                if initialOrganisation.checked == true then(
                                                    -- Resolution

                                                        photoshopDoForLowRes.enabled = true

                                                        photoshopDoForHighRes.enabled = true

                                                    -- Bit depth

                                                        photoshopDoFor32b.enabled = true

                                                        photoshopDoFor16b.enabled = false

                                                        photoshopDoFor16bAnd32b.enabled = true

                                                    -- Overwrite existing files

                                                        overwriteExistingFiles.enabled = false

                                                    -- Frames

                                                        photoshopCurrentFrames.enabled = true

                                                        photoshopAllFrames.enabled = true

                                                        photoshopSpecifiedFrames.enabled = true

                                                        photoshopSpecifiedFramesText.enabled = false

                                                        photoshopOriginalFrameText.enabled = false
                                                )

                                                if rerenderOrganisationSameLocation.checked == true then(
                                                    -- Resolution

                                                        photoshopDoForLowRes.enabled = true

                                                        photoshopDoForHighRes.enabled = true

                                                    -- Bit depth

                                                        photoshopDoFor32b.enabled = true

                                                        photoshopDoFor16b.enabled = true

                                                        photoshopDoFor16bAnd32b.enabled = true

                                                    -- Overwrite existing files

                                                        overwriteExistingFiles.enabled = false

                                                    -- Frames

                                                        photoshopCurrentFrames.enabled = true

                                                        photoshopAllFrames.enabled = true

                                                        photoshopSpecifiedFrames.enabled = true

                                                        photoshopSpecifiedFramesText.enabled = false

                                                        photoshopOriginalFrameText.enabled = false
                                                )

                                                if rerenderOrganisationNewLocation.checked == true then(
                                                    -- Resolution

                                                        photoshopDoForLowRes.enabled = true

                                                        photoshopDoForHighRes.enabled = true

                                                    -- Bit depth

                                                        photoshopDoFor32b.enabled = true

                                                        photoshopDoFor16b.enabled = true

                                                        photoshopDoFor16bAnd32b.enabled = true

                                                    -- Overwrite existing files

                                                        overwriteExistingFiles.enabled = false

                                                    -- Frames

                                                        photoshopCurrentFrames.enabled = true

                                                        photoshopAllFrames.enabled = true

                                                        photoshopSpecifiedFrames.enabled = true

                                                        photoshopSpecifiedFramesText.enabled = false

                                                        photoshopOriginalFrameText.enabled = true
                                                )

                                                if highResify.checked == true then(
                                                    -- Resolution

                                                        photoshopDoForLowRes.enabled = false

                                                        photoshopDoForHighRes.enabled = false

                                                    -- Bit depth

                                                        photoshopDoFor32b.enabled = false

                                                        photoshopDoFor16b.enabled = false

                                                        photoshopDoFor16bAnd32b.enabled = false

                                                    -- Overwrite existing files

                                                        overwriteExistingFiles.enabled = true

                                                    -- Frames

                                                        photoshopCurrentFrames.enabled = true

                                                        photoshopAllFrames.enabled = true

                                                        photoshopSpecifiedFrames.enabled = true

                                                        photoshopSpecifiedFramesText.enabled = false

                                                        photoshopOriginalFrameText.enabled = false
                                                )
                                            )else(
                                                -- Initial prompt

                                                    initialOrganisation.enabled = false

                                                    rerenderOrganisationSameLocation.enabled = false

                                                    rerenderOrganisationNewLocation.enabled = false

                                                    highResify.enabled = false

                                                -- Resolution

                                                    photoshopDoForLowRes.enabled = false

                                                    photoshopDoForHighRes.enabled = false

                                                -- Bit depth

                                                    photoshopDoFor32b.enabled = false

                                                    photoshopDoFor16b.enabled = false

                                                    photoshopDoFor16bAnd32b.enabled = false

                                                -- Overwrite existing files

                                                    overwriteExistingFiles.enabled = false

                                                -- Frames

                                                    photoshopCurrentFrames.enabled = false

                                                    photoshopAllFrames.enabled = false

                                                    photoshopSpecifiedFrames.enabled = false

                                                    photoshopSpecifiedFramesText.enabled = false

                                                    photoshopOriginalFrameText.enabled = false
                                            )
                                        )

                                    -- Initial organisation

                                        on initialOrganisation changed initialOrganisationState do(
                                            if initialOrganisation.checked == true then(
                                                -- Resolution

                                                    photoshopDoForLowRes.enabled = true

                                                    photoshopDoForLowRes.checked = true

                                                    photoshopDoForHighRes.enabled = true

                                                    photoshopDoForHighRes.checked = false

                                                -- Bit depth

                                                    photoshopDoFor32b.enabled = true

                                                    photoshopDoFor32b.checked = true

                                                    photoshopDoFor16b.enabled = false

                                                    photoshopDoFor16b.checked = false

                                                    photoshopDoFor16bAnd32b.enabled = true

                                                    photoshopDoFor16bAnd32b.checked = false

                                                -- Overwrite existing files

                                                    overwriteExistingFiles.enabled = false

                                                    overwriteExistingFiles.checked = false

                                                -- Frames

                                                    photoshopCurrentFrames.enabled = true

                                                    photoshopCurrentFrames.checked = true

                                                    photoshopAllFrames.enabled = true

                                                    photoshopAllFrames.checked = false

                                                    photoshopSpecifiedFrames.enabled = true

                                                    photoshopSpecifiedFrames.checked = false

                                                    photoshopSpecifiedFramesText.enabled = false

                                                    photoshopOriginalFrameText.enabled = false

                                                -- Ensuring no doubleups

                                                    rerenderOrganisationSameLocation.checked = false

                                                    rerenderOrganisationNewLocation.checked = false

                                                    highResify.checked = false
                                            )else(
                                                initialOrganisation.checked = true
                                            )
                                        )

                                    -- Rerender organisation same location

                                        on rerenderOrganisationSameLocation changed rerenderOrganisationSameLocationState do(
                                            if rerenderOrganisationSameLocation.checked == true then(
                                                -- Resolution

                                                    photoshopDoForLowRes.enabled = true

                                                    photoshopDoForLowRes.checked = true

                                                    photoshopDoForHighRes.enabled = true

                                                    photoshopDoForHighRes.checked = false

                                                -- Bit depth

                                                    photoshopDoFor32b.enabled = true

                                                    photoshopDoFor32b.checked = false

                                                    photoshopDoFor16b.enabled = true

                                                    photoshopDoFor16b.checked = false

                                                    photoshopDoFor16bAnd32b.enabled = true

                                                    photoshopDoFor16bAnd32b.checked = true

                                                -- Overwrite existing files

                                                    overwriteExistingFiles.enabled = false

                                                    overwriteExistingFiles.checked = false

                                                -- Frames

                                                    photoshopCurrentFrames.enabled = true

                                                    photoshopCurrentFrames.checked = true

                                                    photoshopAllFrames.enabled = true

                                                    photoshopAllFrames.checked = false

                                                    photoshopSpecifiedFrames.enabled = true

                                                    photoshopSpecifiedFrames.checked = false

                                                    photoshopSpecifiedFramesText.enabled = false

                                                    photoshopOriginalFrameText.enabled = false

                                                -- Ensure no doubleups

                                                    initialOrganisation.checked = false

                                                    rerenderOrganisationNewLocation.checked = false

                                                    highResify.checked = false
                                            )else(
                                                rerenderOrganisationSameLocation.checked = true
                                            )
                                        )

                                    -- Rerender organisation new location

                                        on rerenderOrganisationNewLocation changed rerenderOrganisationNewLocationState do(
                                            if rerenderOrganisationNewLocation.checked == true then(
                                                -- Resolution

                                                    photoshopDoForLowRes.enabled = true

                                                    photoshopDoForLowRes.checked = true

                                                    photoshopDoForHighRes.enabled = true

                                                    photoshopDoForHighRes.checked = false

                                                -- Bit depth

                                                    photoshopDoFor32b.enabled = true

                                                    photoshopDoFor32b.checked = false

                                                    photoshopDoFor16b.enabled = true

                                                    photoshopDoFor16b.checked = false

                                                    photoshopDoFor16bAnd32b.enabled = true

                                                    photoshopDoFor16bAnd32b.checked = true

                                                -- Overwrite existing files

                                                    overwriteExistingFiles.enabled = false

                                                    overwriteExistingFiles.checked = false

                                                -- Frames

                                                    photoshopCurrentFrames.enabled = true

                                                    photoshopCurrentFrames.checked = true

                                                    photoshopAllFrames.enabled = true

                                                    photoshopAllFrames.checked = false

                                                    photoshopSpecifiedFrames.enabled = true

                                                    photoshopSpecifiedFrames.checked = false

                                                    photoshopSpecifiedFramesText.enabled = false

                                                    photoshopOriginalFrameText.enabled = true

                                                -- Ensure no doubleups

                                                    rerenderOrganisationSameLocation.checked = false

                                                    initialOrganisation.checked = false

                                                    highResify.checked = false
                                            )else(
                                                rerenderOrganisationNewLocation.checked = true
                                            )
                                        )

                                    -- High resify

                                        on highResify changed highResifyState do(
                                            if highResify.checked == true then(
                                                -- Resolution

                                                    photoshopDoForLowRes.enabled = false

                                                    photoshopDoForLowRes.checked = true

                                                    photoshopDoForHighRes.enabled = false

                                                    photoshopDoForHighRes.checked = false

                                                -- Bit depth

                                                    photoshopDoFor32b.enabled = false

                                                    photoshopDoFor32b.checked = false

                                                    photoshopDoFor16b.enabled = false

                                                    photoshopDoFor16b.checked = false

                                                    photoshopDoFor16bAnd32b.enabled = false

                                                    photoshopDoFor16bAnd32b.checked = true

                                                -- Overwrite existing files

                                                    overwriteExistingFiles.enabled = true

                                                    overwriteExistingFiles.checked = false

                                                -- Frames

                                                    photoshopCurrentFrames.enabled = true

                                                    photoshopCurrentFrames.checked = true

                                                    photoshopAllFrames.enabled = true

                                                    photoshopAllFrames.checked = false

                                                    photoshopSpecifiedFrames.enabled = true

                                                    photoshopSpecifiedFrames.checked = false

                                                    photoshopSpecifiedFramesText.enabled = false

                                                    photoshopOriginalFrameText.enabled = false

                                                -- Ensure no doubleups

                                                    rerenderOrganisationSameLocation.checked = false

                                                    rerenderOrganisationNewLocation.checked = false

                                                    initialOrganisation.checked = false
                                            )else(
                                                highResify.checked = true
                                            )
                                        )

                                -- Ensure no doubleups

                                    -- Ensure no doubleups on photoshop resolution checkboxes

                                        on photoshopDoForLowRes changed photoshopDoForLowResState do(
                                            if photoshopDoForLowResState then(
                                                photoshopDoForHighRes.checked = false
                                            )else(
                                                photoshopDoForLowRes.checked = true
                                            )
                                        )

                                        on photoshopDoForHighRes changed photoshopDoForHighResState do(
                                            if photoshopDoForHighResState then(
                                                photoshopDoForLowRes.checked = false
                                            )else(
                                                photoshopDoForHighRes.checked = true
                                            )
                                        )

                                    -- Ensure no doubleups on bit depth checkboxes

                                        on photoshopDoFor32b changed photoshopDoFor32bState do(
                                            if photoshopDoFor32bState then(
                                                photoshopDoFor16b.checked = false

                                                photoshopDoFor16bAnd32b.checked = false
                                            )else(
                                                photoshopDoFor32b.checked = true
                                            )
                                        )

                                        on photoshopDoFor16b changed photoshopDoFor16bState do(
                                            if photoshopDoFor16bState then(
                                                photoshopDoFor32b.checked = false

                                                photoshopDoFor16bAnd32b.checked = false
                                            )else(
                                                photoshopDoFor16b.checked = true
                                            )
                                        )

                                        on photoshopDoFor16bAnd32b changed photoshopDoFor16bAnd32bState do(
                                            if photoshopDoFor16bAnd32bState then(
                                                photoshopDoFor32b.checked = false

                                                photoshopDoFor16b.checked = false
                                            )else(
                                                photoshopDoFor16bAnd32b.checked = true
                                            )
                                        )

                                    -- Ensure no doubleups on frame number checkboxes

                                        on photoshopCurrentFrames changed photoshopCurrentFramesState do(
                                            if photoshopCurrentFramesState then(
                                                photoshopAllFrames.checked = false

                                                photoshopSpecifiedFrames.checked = false

                                                photoshopSpecifiedFramesText.enabled = false
                                            )else(
                                                photoshopCurrentFrames.checked = true
                                            )
                                        )

                                        on photoshopAllFrames changed photoshopAllFramesState do(
                                            if photoshopAllFramesState then(
                                                photoshopCurrentFrames.checked = false

                                                photoshopSpecifiedFrames.checked = false

                                                photoshopSpecifiedFramesText.enabled = false
                                            )else(
                                                photoshopAllFrames.checked = true
                                            )
                                        )

                                        on photoshopSpecifiedFrames changed photoshopSpecifiedFramesState do(
                                            if photoshopSpecifiedFramesState then(
                                                photoshopCurrentFrames.checked = false

                                                photoshopAllFrames.checked = false

                                                photoshopSpecifiedFramesText.enabled = true
                                            )else(
                                                photoshopSpecifiedFrames.checked = true
                                            )
                                        )

                            -- Run the script

                                on renderButton pressed do(
                                    if frameNumbers != "" do(
                                        if photoshopSpecifiedFrames.checked == true and photoshopFrameNumbersString == "" then(
                                        )else(
                                            if rerenderOrganisationNewLocation.checked == true and photoshopOriginalFrameNumber == "" then(
                                            )else(
                                                -- Load render preset (disabled as it is too costly e.g. frame buffer gets reloaded, all render settings get reset etc.)

                                                    /*
                                                        try(
                                                            renderpresets.Load 0 ("$scripts/CallisScripts/Render Presets/Final.rps") #{32}
                                                        )catch()
                                                    */

                                                -- Save scene if relevant

                                                    if saveSceneCheckBox.checked == true then(
                                                        saveMaxFile (maxFilePath + maxFileName)
                                                    )

                                                -- Show relevant hidden layers

                                                    showRelevantHiddenLayers()

                                                if updatePassesCheckBox.checked == true then(
                                                    -- Update light select elements

                                                        updateLightSelectElements()

                                                    -- Update multimatte elements

                                                        updateMultimatteElements()
                                                )

                                                if lowResCheckBox.checked == true then(
                                                    -- Close the dialog

                                                        DestroyDialog renderSpecifiedFrames

                                                    -- Loop through frame numbers, setting relevant frame to current and running the script on each

                                                        for a = 1 to frameNumbers.count do(
                                                            frameNumber = frameNumbers[a] as integer

                                                            changeFrameNumber frameNumber

                                                            if separateGlassCheckbox.checked == false then(
                                                                if forceActiveViewCheckBox.checked == true then(
                                                                    if saveOutputCheckBox.checked == true then(
                                                                        if renderRegionCheckBox.checked == true then(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "false" "true" "false" "save" "region"
                                                                        )else(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "false" "true" "false" "save" "noRegion"
                                                                        )
                                                                    )else(
                                                                        if renderRegionCheckBox.checked == true then(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "false" "true" "false" "dontSave" "region"
                                                                        )else(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "false" "true" "false" "dontSave" "noRegion"
                                                                        )
                                                                    )
                                                                )else(
                                                                    if saveOutputCheckBox.checked == true then(
                                                                        if renderRegionCheckBox.checked == true then(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "false" "false" "false" "save" "region"
                                                                        )else(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "false" "false" "false" "save" "noRegion"
                                                                        )
                                                                    )else(
                                                                        if renderRegionCheckBox.checked == true then(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "false" "false" "false" "dontSave" "region"
                                                                        )else(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "false" "false" "false" "dontSave" "noRegion"
                                                                        )
                                                                    )
                                                                )
                                                            )else(
                                                                if forceActiveViewCheckBox.checked == true then(
                                                                    if saveOutputCheckBox.checked == true then(
                                                                        if renderRegionCheckBox.checked == true then(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "true" "true" "false" "save" "region"
                                                                        )else(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "true" "true" "false" "save" "noRegion"
                                                                        )
                                                                    )else(
                                                                        if renderRegionCheckBox.checked == true then(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "true" "true" "false" "dontSave" "region"
                                                                        )else(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "true" "true" "false" "dontSave" "noRegion"
                                                                        )
                                                                    )
                                                                )else(
                                                                    if saveOutputCheckBox.checked == true then(
                                                                        if renderRegionCheckBox.checked == true then(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "true" "false" "false" "save" "region"
                                                                        )else(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "true" "false" "false" "save" "noRegion"
                                                                        )
                                                                    )else(
                                                                        if renderRegionCheckBox.checked == true then(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "true" "false" "false" "dontSave" "region"
                                                                        )else(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "true" "false" "false" "dontSave" "noRegion"
                                                                        )
                                                                    )
                                                                )
                                                            )
                                                        )
                                                )

                                                if highResCheckBox.checked == true then(
                                                    -- Close the dialog

                                                        DestroyDialog renderSpecifiedFrames

                                                    -- Loop through frame numbers, setting relevant frame to current and running the script on each

                                                        for a = 1 to frameNumbers.count do(
                                                            frameNumber = frameNumbers[a] as integer

                                                            changeFrameNumber frameNumber

                                                            if separateGlassCheckbox.checked == false then(
                                                                if forceActiveViewCheckBox.checked == true then(
                                                                    if saveOutputCheckBox.checked == true then(
                                                                        if renderRegionCheckBox.checked == true then(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "false" "true" "true" "save" "region"
                                                                        )else(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "false" "true" "true" "save" "noRegion"
                                                                        )
                                                                    )else(
                                                                        if renderRegionCheckBox.checked == true then(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "false" "true" "true" "dontSave" "region"
                                                                        )else(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "false" "true" "true" "dontSave" "noRegion"
                                                                        )
                                                                    )
                                                                )else(
                                                                    if saveOutputCheckBox.checked == true then(
                                                                        if renderRegionCheckBox.checked == true then(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "false" "false" "true" "save" "region"
                                                                        )else(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "false" "false" "true" "save" "noRegion"
                                                                        )
                                                                    )else(
                                                                        if renderRegionCheckBox.checked == true then(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "false" "false" "true" "dontSave" "region"
                                                                        )else(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "false" "false" "true" "dontSave" "noRegion"
                                                                        )
                                                                    )
                                                                )
                                                            )else(
                                                                if forceActiveViewCheckBox.checked == true then(
                                                                    if saveOutputCheckBox.checked == true then(
                                                                        if renderRegionCheckBox.checked == true then(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "true" "true" "true" "save" "region"
                                                                        )else(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "true" "true" "true" "save" "noRegion"
                                                                        )
                                                                    )else(
                                                                        if renderRegionCheckBox.checked == true then(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "true" "true" "true" "dontSave" "region"
                                                                        )else(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "true" "true" "true" "dontSave" "noRegion"
                                                                        )
                                                                    )
                                                                )else(
                                                                    if saveOutputCheckBox.checked == true then(
                                                                        if renderRegionCheckBox.checked == true then(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "true" "false" "true" "save" "region"
                                                                        )else(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "true" "false" "true" "save" "noRegion"
                                                                        )
                                                                    )else(
                                                                        if renderRegionCheckBox.checked == true then(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "true" "false" "true" "dontSave" "region"
                                                                        )else(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "true" "false" "true" "dontSave" "noRegion"
                                                                        )
                                                                    )
                                                                )
                                                            )
                                                        )
                                                )

                                                if lowAndHighResCheckBox.checked == true then(
                                                    -- Close the dialog

                                                        DestroyDialog renderSpecifiedFrames

                                                    -- Loop through frame numbers, setting relevant frame to current and running the script on each

                                                        for a = 1 to frameNumbers.count do(
                                                            frameNumber = frameNumbers[a] as integer

                                                            changeFrameNumber frameNumber

                                                            if separateGlassCheckbox.checked == false then(
                                                                if forceActiveViewCheckBox.checked == true then(
                                                                    if saveOutputCheckBox.checked == true then(
                                                                        if renderRegionCheckBox.checked == true then(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "false" "true" "false" "save" "region"
                                                                        )else(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "false" "true" "false" "save" "noRegion"
                                                                        )
                                                                    )else(
                                                                        if renderRegionCheckBox.checked == true then(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "false" "true" "false" "dontSave" "region"
                                                                        )else(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "false" "true" "false" "dontSave" "noRegion"
                                                                        )
                                                                    )
                                                                )else(
                                                                    if saveOutputCheckBox.checked == true then(
                                                                        if renderRegionCheckBox.checked == true then(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "false" "false" "false" "save" "region"
                                                                        )else(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "false" "false" "false" "save" "noRegion"
                                                                        )
                                                                    )else(
                                                                        if renderRegionCheckBox.checked == true then(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "false" "false" "false" "dontSave" "region"
                                                                        )else(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "false" "false" "false" "dontSave" "noRegion"
                                                                        )
                                                                    )
                                                                )
                                                            )else(
                                                                if forceActiveViewCheckBox.checked == true then(
                                                                    if saveOutputCheckBox.checked == true then(
                                                                        if renderRegionCheckBox.checked == true then(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "true" "true" "false" "save" "region"
                                                                        )else(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "true" "true" "false" "save" "noRegion"
                                                                        )
                                                                    )else(
                                                                        if renderRegionCheckBox.checked == true then(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "true" "true" "false" "dontSave" "region"
                                                                        )else(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "true" "true" "false" "dontSave" "noRegion"
                                                                        )
                                                                    )
                                                                )else(
                                                                    if saveOutputCheckBox.checked == true then(
                                                                        if renderRegionCheckBox.checked == true then(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "true" "false" "false" "save" "region"
                                                                        )else(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "true" "false" "false" "save" "noRegion"
                                                                        )
                                                                    )else(
                                                                        if renderRegionCheckBox.checked == true then(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "true" "false" "false" "dontSave" "region"
                                                                        )else(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "true" "false" "false" "dontSave" "noRegion"
                                                                        )
                                                                    )
                                                                )
                                                            )
                                                        )

                                                    -- Loop through frame numbers, setting relevant frame to current and running the script on each

                                                        for a = 1 to frameNumbers.count do(
                                                            frameNumber = frameNumbers[a] as integer

                                                            changeFrameNumber frameNumber

                                                            if separateGlassCheckbox.checked == false then(
                                                                if forceActiveViewCheckBox.checked == true then(
                                                                    if saveOutputCheckBox.checked == true then(
                                                                        if renderRegionCheckBox.checked == true then(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "false" "true" "true" "save" "region"
                                                                        )else(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "false" "true" "true" "save" "noRegion"
                                                                        )
                                                                    )else(
                                                                        if renderRegionCheckBox.checked == true then(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "false" "true" "true" "dontSave" "region"
                                                                        )else(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "false" "true" "true" "dontSave" "noRegion"
                                                                        )
                                                                    )
                                                                )else(
                                                                    if saveOutputCheckBox.checked == true then(
                                                                        if renderRegionCheckBox.checked == true then(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "false" "false" "true" "save" "region"
                                                                        )else(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "false" "false" "true" "save" "noRegion"
                                                                        )
                                                                    )else(
                                                                        if renderRegionCheckBox.checked == true then(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "false" "false" "true" "dontSave" "region"
                                                                        )else(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "false" "false" "true" "dontSave" "noRegion"
                                                                        )
                                                                    )
                                                                )
                                                            )else(
                                                                if forceActiveViewCheckBox.checked == true then(
                                                                    if saveOutputCheckBox.checked == true then(
                                                                        if renderRegionCheckBox.checked == true then(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "true" "true" "true" "save" "region"
                                                                        )else(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "true" "true" "true" "save" "noRegion"
                                                                        )
                                                                    )else(
                                                                        if renderRegionCheckBox.checked == true then(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "true" "true" "true" "dontSave" "region"
                                                                        )else(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "true" "true" "true" "dontSave" "noRegion"
                                                                        )
                                                                    )
                                                                )else(
                                                                    if saveOutputCheckBox.checked == true then(
                                                                        if renderRegionCheckBox.checked == true then(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "true" "false" "true" "save" "region"
                                                                        )else(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "true" "false" "true" "save" "noRegion"
                                                                        )
                                                                    )else(
                                                                        if renderRegionCheckBox.checked == true then(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "true" "false" "true" "dontSave" "region"
                                                                        )else(
                                                                            renderCurrentFrameToCorrespondingFolderPreliminary "true" "false" "true" "dontSave" "noRegion"
                                                                        )
                                                                    )
                                                                )
                                                            )
                                                        )
                                                )

                                                -- Hide relevant shown layers

                                                    hideRelevantShownLayers()

                                                if runPhotoshopScriptsUponCompletion.checked == true then(
                                                    -- Delete directory if it exists

                                                        try(
                                                            fileClass = dotNetClass "System.IO.Directory"
                                                            fileClass.Delete @"C:\\Callis Scripts" true
                                                        )catch()

                                                    -- Create Metadata PSB

                                                        -- Create directory

                                                            myDirectory = "C:\\Callis Scripts"
                                                            makedir myDirectory

                                                        PsApp = CreateOLEObject"Photoshop.Application"
                                                        PsApp.Visible = true
                                                        PsApp.bringToFront()
                                                        PsApp.doaction "Create 3DS Max Metadata File" "Callis Scripts"

                                                    if initialOrganisation.checked == true then(
                                                        -- Replace initial prompt

                                                            -- Delete directory if it exists

                                                                try(
                                                                    fileClass = dotNetClass "System.IO.Directory"
                                                                    fileClass.Delete @"C:\\Callis Scripts\\Metadata" true
                                                                )catch()

                                                            -- Create directory

                                                                -- Layer name

                                                                    -- Create dialogInitialPromptLayer variable

                                                                        dialogInitialPromptLayer = "I"

                                                                    myDirectory = "C:\\Callis Scripts\\Metadata\\" + "initialPromptLayer" + dialogInitialPromptLayer
                                                                    makedir myDirectory

                                                                -- Group name

                                                                    -- Create dialogInitialPromptGroup variable

                                                                        dialogInitialPromptGroup = "initialPrompt"

                                                                    myDirectory = "C:\\Callis Scripts\\Metadata\\" + "initialPromptGroup" + dialogInitialPromptGroup
                                                                    makedir myDirectory

                                                            -- Run Photoshop action

                                                                PsApp.bringToFront()
                                                                PsApp.doaction "Initial Prompt" "Callis Scripts"

                                                            -- Delete directory

                                                                fileClass = dotNetClass "System.IO.Directory"
                                                                fileClass.Delete @"C:\\Callis Scripts\\Metadata" true

                                                        -- Replace root folder path prompt

                                                            -- Delete directory if it exists

                                                                try(
                                                                    fileClass = dotNetClass "System.IO.Directory"
                                                                    fileClass.Delete @"C:\\Callis Scripts\\Metadata" true
                                                                )catch()

                                                            -- Create directory

                                                                -- Layer name

                                                                    -- Create dialogInitialPromptLayer variable

                                                                        dialogOutputFolderPreliminary2 = $'Output Path Dummy'.layer.name

                                                                        dialogOutputFolderPreliminary = substituteString dialogOutputFolderPreliminary2 "Output Path: " ""

                                                                        dialogOutputFolder9 = substituteString dialogOutputFolderPreliminary "/" "\\"

                                                                        dialogOutputFolder8 = substituteString dialogOutputFolder9 "\\" "\\\\"

                                                                        dialogOutputFolder7 = substituteString dialogOutputFolder8 "\\\\" "xxslashxx"

                                                                        dialogOutputFolder6 = substituteString dialogOutputFolder7 ":" "xxcolonxx"

                                                                        dialogInitialPromptLayer = "dialogOutputFolderSpacer" + dialogOutputFolder6

                                                                    myDirectory = "C:\\Callis Scripts\\Metadata\\" + "initialPromptLayer" + dialogInitialPromptLayer
                                                                    makedir myDirectory

                                                                -- Group name

                                                                    -- Create dialogInitialPromptGroup variable

                                                                        dialogInitialPromptGroup = "rootFolderPath"

                                                                    myDirectory = "C:\\Callis Scripts\\Metadata\\" + "initialPromptGroup" + dialogInitialPromptGroup
                                                                    makedir myDirectory

                                                            -- Run Photoshop action

                                                                PsApp.bringToFront()
                                                                PsApp.doaction "Initial Prompt" "Callis Scripts"

                                                            -- Delete directory

                                                                fileClass = dotNetClass "System.IO.Directory"
                                                                fileClass.Delete @"C:\\Callis Scripts\\Metadata" true

                                                        -- Replace frame number prompt

                                                            -- Delete directory if it exists

                                                                try(
                                                                    fileClass = dotNetClass "System.IO.Directory"
                                                                    fileClass.Delete @"C:\\Callis Scripts\\Metadata" true
                                                                )catch()

                                                            -- Create directory

                                                                -- Layer name

                                                                    -- Create dialogInitialPromptLayer variable

                                                                        if photoshopCurrentFrames.checked == true then(
                                                                            dialogInitialPromptLayer = frameNumbersString
                                                                        )

                                                                        if photoshopAllFrames.checked == true then(
                                                                            dialogInitialPromptLayer = "All"
                                                                        )

                                                                        if photoshopSpecifiedFrames.checked == true then(
                                                                            dialogInitialPromptLayer = photoshopFrameNumbersString
                                                                        )

                                                                    myDirectory = "C:\\Callis Scripts\\Metadata\\" + "initialPromptLayer" + dialogInitialPromptLayer
                                                                    makedir myDirectory

                                                                -- Group name

                                                                    -- Create dialogInitialPromptGroup variable

                                                                        dialogInitialPromptGroup = "promptForFrameNumber"

                                                                    myDirectory = "C:\\Callis Scripts\\Metadata\\" + "initialPromptGroup" + dialogInitialPromptGroup
                                                                    makedir myDirectory

                                                            -- Run Photoshop action

                                                                PsApp.bringToFront()
                                                                PsApp.doaction "Initial Prompt" "Callis Scripts"

                                                            -- Delete directory

                                                                fileClass = dotNetClass "System.IO.Directory"
                                                                fileClass.Delete @"C:\\Callis Scripts\\Metadata" true

                                                        -- Replace high res prompt

                                                            -- Delete directory if it exists

                                                                try(
                                                                    fileClass = dotNetClass "System.IO.Directory"
                                                                    fileClass.Delete @"C:\\Callis Scripts\\Metadata" true
                                                                )catch()

                                                            -- Create directory

                                                                -- Layer name

                                                                    -- Create dialogInitialPromptLayer variable

                                                                        if photoshopDoForHighRes.checked == true then(
                                                                            dialogInitialPromptLayer = "Y"
                                                                        )else(
                                                                            dialogInitialPromptLayer = "N"
                                                                        )

                                                                    myDirectory = "C:\\Callis Scripts\\Metadata\\" + "initialPromptLayer" + dialogInitialPromptLayer
                                                                    makedir myDirectory

                                                                -- Group name

                                                                    -- Create dialogInitialPromptGroup variable

                                                                        dialogInitialPromptGroup = "promptForHighRes"

                                                                    myDirectory = "C:\\Callis Scripts\\Metadata\\" + "initialPromptGroup" + dialogInitialPromptGroup
                                                                    makedir myDirectory

                                                            -- Run Photoshop action

                                                                PsApp.bringToFront()
                                                                PsApp.doaction "Initial Prompt" "Callis Scripts"

                                                            -- Delete directory

                                                                fileClass = dotNetClass "System.IO.Directory"
                                                                fileClass.Delete @"C:\\Callis Scripts\\Metadata" true

                                                        -- Replace 16b prompt

                                                            -- Delete directory if it exists

                                                                try(
                                                                    fileClass = dotNetClass "System.IO.Directory"
                                                                    fileClass.Delete @"C:\\Callis Scripts\\Metadata" true
                                                                )catch()

                                                            -- Create directory

                                                                -- Layer name

                                                                    -- Create dialogInitialPromptLayer variable

                                                                        if photoshopDoFor32b.checked == true then(
                                                                            dialogInitialPromptLayer = "N"
                                                                        )

                                                                        if photoshopDoFor16b.checked == true then(
                                                                            dialogInitialPromptLayer = "O"
                                                                        )

                                                                        if photoshopDoFor16bAnd32b.checked == true then(
                                                                            dialogInitialPromptLayer = "Y"
                                                                        )

                                                                    myDirectory = "C:\\Callis Scripts\\Metadata\\" + "initialPromptLayer" + dialogInitialPromptLayer
                                                                    makedir myDirectory

                                                                -- Group name

                                                                    -- Create dialogInitialPromptGroup variable

                                                                        dialogInitialPromptGroup = "promptFor16b"

                                                                    myDirectory = "C:\\Callis Scripts\\Metadata\\" + "initialPromptGroup" + dialogInitialPromptGroup
                                                                    makedir myDirectory

                                                            -- Run Photoshop action

                                                                PsApp.bringToFront()
                                                                PsApp.doaction "Initial Prompt" "Callis Scripts"

                                                            -- Delete directory

                                                                fileClass = dotNetClass "System.IO.Directory"
                                                                fileClass.Delete @"C:\\Callis Scripts\\Metadata" true

                                                        -- Run the script

                                                            PsApp.bringToFront()
                                                            PsApp.doaction "Organisation Scripts..." "Callis Scripts"
                                                    )

                                                    if rerenderOrganisationSameLocation.checked == true then(
                                                        -- Replace initial prompt

                                                            -- Delete directory if it exists

                                                                try(
                                                                    fileClass = dotNetClass "System.IO.Directory"
                                                                    fileClass.Delete @"C:\\Callis Scripts\\Metadata" true
                                                                )catch()

                                                            -- Create directory

                                                                -- Layer name

                                                                    -- Create dialogInitialPromptLayer variable

                                                                        dialogInitialPromptLayer = "R"

                                                                    myDirectory = "C:\\Callis Scripts\\Metadata\\" + "initialPromptLayer" + dialogInitialPromptLayer
                                                                    makedir myDirectory

                                                                -- Group name

                                                                    -- Create dialogInitialPromptGroup variable

                                                                        dialogInitialPromptGroup = "initialPrompt"

                                                                    myDirectory = "C:\\Callis Scripts\\Metadata\\" + "initialPromptGroup" + dialogInitialPromptGroup
                                                                    makedir myDirectory

                                                            -- Run Photoshop action

                                                                PsApp.bringToFront()
                                                                PsApp.doaction "Initial Prompt" "Callis Scripts"

                                                            -- Delete directory

                                                                fileClass = dotNetClass "System.IO.Directory"
                                                                fileClass.Delete @"C:\\Callis Scripts\\Metadata" true

                                                        -- Replace root folder path prompt

                                                            -- Delete directory if it exists

                                                                try(
                                                                    fileClass = dotNetClass "System.IO.Directory"
                                                                    fileClass.Delete @"C:\\Callis Scripts\\Metadata" true
                                                                )catch()

                                                            -- Create directory

                                                                -- Layer name

                                                                    -- Create dialogInitialPromptLayer variable

                                                                        dialogOutputFolderPreliminary2 = $'Output Path Dummy'.layer.name

                                                                        dialogOutputFolderPreliminary = substituteString dialogOutputFolderPreliminary2 "Output Path: " ""

                                                                        dialogOutputFolder9 = substituteString dialogOutputFolderPreliminary "/" "\\"

                                                                        dialogOutputFolder8 = substituteString dialogOutputFolder9 "\\" "\\\\"

                                                                        dialogOutputFolder7 = substituteString dialogOutputFolder8 "\\\\" "xxslashxx"

                                                                        dialogOutputFolder6 = substituteString dialogOutputFolder7 ":" "xxcolonxx"

                                                                        dialogInitialPromptLayer = "dialogOutputFolderSpacer" + dialogOutputFolder6

                                                                    myDirectory = "C:\\Callis Scripts\\Metadata\\" + "initialPromptLayer" + dialogInitialPromptLayer
                                                                    makedir myDirectory

                                                                -- Group name

                                                                    -- Create dialogInitialPromptGroup variable

                                                                        dialogInitialPromptGroup = "rootFolderPath"

                                                                    myDirectory = "C:\\Callis Scripts\\Metadata\\" + "initialPromptGroup" + dialogInitialPromptGroup
                                                                    makedir myDirectory

                                                            -- Run Photoshop action

                                                                PsApp.bringToFront()
                                                                PsApp.doaction "Initial Prompt" "Callis Scripts"

                                                            -- Delete directory

                                                                fileClass = dotNetClass "System.IO.Directory"
                                                                fileClass.Delete @"C:\\Callis Scripts\\Metadata" true

                                                        -- Replace frame number prompt

                                                            -- Delete directory if it exists

                                                                try(
                                                                    fileClass = dotNetClass "System.IO.Directory"
                                                                    fileClass.Delete @"C:\\Callis Scripts\\Metadata" true
                                                                )catch()

                                                            -- Create directory

                                                                -- Layer name

                                                                    -- Create dialogInitialPromptLayer variable

                                                                        if photoshopCurrentFrames.checked == true then(
                                                                            dialogInitialPromptLayer = frameNumbersString
                                                                        )

                                                                        if photoshopAllFrames.checked == true then(
                                                                            dialogInitialPromptLayer = "All"
                                                                        )

                                                                        if photoshopSpecifiedFrames.checked == true then(
                                                                            dialogInitialPromptLayer = photoshopFrameNumbersString
                                                                        )

                                                                    myDirectory = "C:\\Callis Scripts\\Metadata\\" + "initialPromptLayer" + dialogInitialPromptLayer
                                                                    makedir myDirectory

                                                                -- Group name

                                                                    -- Create dialogInitialPromptGroup variable

                                                                        dialogInitialPromptGroup = "promptForFrameNumber"

                                                                    myDirectory = "C:\\Callis Scripts\\Metadata\\" + "initialPromptGroup" + dialogInitialPromptGroup
                                                                    makedir myDirectory

                                                            -- Run Photoshop action

                                                                PsApp.bringToFront()
                                                                PsApp.doaction "Initial Prompt" "Callis Scripts"

                                                            -- Delete directory

                                                                fileClass = dotNetClass "System.IO.Directory"
                                                                fileClass.Delete @"C:\\Callis Scripts\\Metadata" true

                                                        -- Replace high res prompt

                                                            -- Delete directory if it exists

                                                                try(
                                                                    fileClass = dotNetClass "System.IO.Directory"
                                                                    fileClass.Delete @"C:\\Callis Scripts\\Metadata" true
                                                                )catch()

                                                            -- Create directory

                                                                -- Layer name

                                                                    -- Create dialogInitialPromptLayer variable

                                                                        if photoshopDoForHighRes.checked == true then(
                                                                            dialogInitialPromptLayer = "Y"
                                                                        )else(
                                                                            dialogInitialPromptLayer = "N"
                                                                        )

                                                                    myDirectory = "C:\\Callis Scripts\\Metadata\\" + "initialPromptLayer" + dialogInitialPromptLayer
                                                                    makedir myDirectory

                                                                -- Group name

                                                                    -- Create dialogInitialPromptGroup variable

                                                                        dialogInitialPromptGroup = "promptForHighRes"

                                                                    myDirectory = "C:\\Callis Scripts\\Metadata\\" + "initialPromptGroup" + dialogInitialPromptGroup
                                                                    makedir myDirectory

                                                            -- Run Photoshop action

                                                                PsApp.bringToFront()
                                                                PsApp.doaction "Initial Prompt" "Callis Scripts"

                                                            -- Delete directory

                                                                fileClass = dotNetClass "System.IO.Directory"
                                                                fileClass.Delete @"C:\\Callis Scripts\\Metadata" true

                                                        -- Replace 16b prompt

                                                            -- Delete directory if it exists

                                                                try(
                                                                    fileClass = dotNetClass "System.IO.Directory"
                                                                    fileClass.Delete @"C:\\Callis Scripts\\Metadata" true
                                                                )catch()

                                                            -- Create directory

                                                                -- Layer name

                                                                    -- Create dialogInitialPromptLayer variable

                                                                        if photoshopDoFor32b.checked == true then(
                                                                            dialogInitialPromptLayer = "N"
                                                                        )

                                                                        if photoshopDoFor16b.checked == true then(
                                                                            dialogInitialPromptLayer = "O"
                                                                        )

                                                                        if photoshopDoFor16bAnd32b.checked == true then(
                                                                            dialogInitialPromptLayer = "Y"
                                                                        )

                                                                    myDirectory = "C:\\Callis Scripts\\Metadata\\" + "initialPromptLayer" + dialogInitialPromptLayer
                                                                    makedir myDirectory

                                                                -- Group name

                                                                    -- Create dialogInitialPromptGroup variable

                                                                        dialogInitialPromptGroup = "promptFor16b"

                                                                    myDirectory = "C:\\Callis Scripts\\Metadata\\" + "initialPromptGroup" + dialogInitialPromptGroup
                                                                    makedir myDirectory

                                                            -- Run Photoshop action

                                                                PsApp.bringToFront()
                                                                PsApp.doaction "Initial Prompt" "Callis Scripts"

                                                            -- Delete directory

                                                                fileClass = dotNetClass "System.IO.Directory"
                                                                fileClass.Delete @"C:\\Callis Scripts\\Metadata" true

                                                        -- Run the script

                                                            PsApp.bringToFront()
                                                            PsApp.doaction "Organisation Scripts..." "Callis Scripts"
                                                    )

                                                    if rerenderOrganisationNewLocation.checked == true then(
                                                        -- Replace initial prompt

                                                            -- Delete directory if it exists

                                                                try(
                                                                    fileClass = dotNetClass "System.IO.Directory"
                                                                    fileClass.Delete @"C:\\Callis Scripts\\Metadata" true
                                                                )catch()

                                                            -- Create directory

                                                                -- Layer name

                                                                    -- Create dialogInitialPromptLayer variable

                                                                        dialogInitialPromptLayer = "T"

                                                                    myDirectory = "C:\\Callis Scripts\\Metadata\\" + "initialPromptLayer" + dialogInitialPromptLayer
                                                                    makedir myDirectory

                                                                -- Group name

                                                                    -- Create dialogInitialPromptGroup variable

                                                                        dialogInitialPromptGroup = "initialPrompt"

                                                                    myDirectory = "C:\\Callis Scripts\\Metadata\\" + "initialPromptGroup" + dialogInitialPromptGroup
                                                                    makedir myDirectory

                                                            -- Run Photoshop action

                                                                PsApp.bringToFront()
                                                                PsApp.doaction "Initial Prompt" "Callis Scripts"

                                                            -- Delete directory

                                                                fileClass = dotNetClass "System.IO.Directory"
                                                                fileClass.Delete @"C:\\Callis Scripts\\Metadata" true

                                                        -- Replace root folder path prompt

                                                            -- Delete directory if it exists

                                                                try(
                                                                    fileClass = dotNetClass "System.IO.Directory"
                                                                    fileClass.Delete @"C:\\Callis Scripts\\Metadata" true
                                                                )catch()

                                                            -- Create directory

                                                                -- Layer name

                                                                    -- Create dialogInitialPromptLayer variable

                                                                        dialogOutputFolderPreliminary2 = $'Output Path Dummy'.layer.name

                                                                        dialogOutputFolderPreliminary = substituteString dialogOutputFolderPreliminary2 "Output Path: " ""

                                                                        dialogOutputFolder9 = substituteString dialogOutputFolderPreliminary "/" "\\"

                                                                        dialogOutputFolder8 = substituteString dialogOutputFolder9 "\\" "\\\\"

                                                                        dialogOutputFolder7 = substituteString dialogOutputFolder8 "\\\\" "xxslashxx"

                                                                        dialogOutputFolder6 = substituteString dialogOutputFolder7 ":" "xxcolonxx"

                                                                        dialogInitialPromptLayer = "dialogOutputFolderSpacer" + dialogOutputFolder6

                                                                    myDirectory = "C:\\Callis Scripts\\Metadata\\" + "initialPromptLayer" + dialogInitialPromptLayer
                                                                    makedir myDirectory

                                                                -- Group name

                                                                    -- Create dialogInitialPromptGroup variable

                                                                        dialogInitialPromptGroup = "rootFolderPath"

                                                                    myDirectory = "C:\\Callis Scripts\\Metadata\\" + "initialPromptGroup" + dialogInitialPromptGroup
                                                                    makedir myDirectory

                                                            -- Run Photoshop action

                                                                PsApp.bringToFront()
                                                                PsApp.doaction "Initial Prompt" "Callis Scripts"

                                                            -- Delete directory

                                                                fileClass = dotNetClass "System.IO.Directory"
                                                                fileClass.Delete @"C:\\Callis Scripts\\Metadata" true

                                                        -- Replace frame number prompt

                                                            -- Delete directory if it exists

                                                                try(
                                                                    fileClass = dotNetClass "System.IO.Directory"
                                                                    fileClass.Delete @"C:\\Callis Scripts\\Metadata" true
                                                                )catch()

                                                            -- Create directory

                                                            -- Layer name

                                                                -- Create dialogInitialPromptLayer variable

                                                                    dialogInitialPromptLayer = photoshopOriginalFrameNumber

                                                                myDirectory = "C:\\Callis Scripts\\Metadata\\" + "initialPromptLayer" + dialogInitialPromptLayer
                                                                makedir myDirectory

                                                                -- Group name

                                                                    -- Create dialogInitialPromptGroup variable

                                                                        dialogInitialPromptGroup = "promptForFrameNumber"

                                                                    myDirectory = "C:\\Callis Scripts\\Metadata\\" + "initialPromptGroup" + dialogInitialPromptGroup
                                                                    makedir myDirectory

                                                            -- Run Photoshop action

                                                                PsApp.bringToFront()
                                                                PsApp.doaction "Initial Prompt" "Callis Scripts"

                                                            -- Delete directory

                                                                fileClass = dotNetClass "System.IO.Directory"
                                                                fileClass.Delete @"C:\\Callis Scripts\\Metadata" true

                                                        -- Replace new frame number prompt

                                                            -- Delete directory if it exists

                                                                try(
                                                                    fileClass = dotNetClass "System.IO.Directory"
                                                                    fileClass.Delete @"C:\\Callis Scripts\\Metadata" true
                                                                )catch()

                                                            -- Create directory

                                                                -- Layer name

                                                                    -- Create dialogInitialPromptLayer variable

                                                                        if photoshopCurrentFrames.checked == true then(
                                                                            dialogInitialPromptLayer = frameNumbersString
                                                                        )

                                                                        if photoshopAllFrames.checked == true then(
                                                                            dialogInitialPromptLayer = "All"
                                                                        )

                                                                        if photoshopSpecifiedFrames.checked == true then(
                                                                            dialogInitialPromptLayer = photoshopFrameNumbersString
                                                                        )

                                                                    myDirectory = "C:\\Callis Scripts\\Metadata\\" + "initialPromptLayer" + dialogInitialPromptLayer
                                                                    makedir myDirectory

                                                                -- Group name

                                                                    -- Create dialogInitialPromptGroup variable

                                                                        dialogInitialPromptGroup = "promptForNewFrameNumber"

                                                                    myDirectory = "C:\\Callis Scripts\\Metadata\\" + "initialPromptGroup" + dialogInitialPromptGroup
                                                                    makedir myDirectory

                                                            -- Run Photoshop action

                                                                PsApp.bringToFront()
                                                                PsApp.doaction "Initial Prompt" "Callis Scripts"

                                                            -- Delete directory

                                                                fileClass = dotNetClass "System.IO.Directory"
                                                                fileClass.Delete @"C:\\Callis Scripts\\Metadata" true

                                                        -- Replace high res prompt

                                                            -- Delete directory if it exists

                                                                try(
                                                                    fileClass = dotNetClass "System.IO.Directory"
                                                                    fileClass.Delete @"C:\\Callis Scripts\\Metadata" true
                                                                )catch()

                                                            -- Create directory

                                                                -- Layer name

                                                                    -- Create dialogInitialPromptLayer variable

                                                                        if photoshopDoForHighRes.checked == true then(
                                                                            dialogInitialPromptLayer = "Y"
                                                                        )else(
                                                                            dialogInitialPromptLayer = "N"
                                                                        )

                                                                    myDirectory = "C:\\Callis Scripts\\Metadata\\" + "initialPromptLayer" + dialogInitialPromptLayer
                                                                    makedir myDirectory

                                                                -- Group name

                                                                    -- Create dialogInitialPromptGroup variable

                                                                        dialogInitialPromptGroup = "promptForHighRes"

                                                                    myDirectory = "C:\\Callis Scripts\\Metadata\\" + "initialPromptGroup" + dialogInitialPromptGroup
                                                                    makedir myDirectory

                                                            -- Run Photoshop action

                                                                PsApp.bringToFront()
                                                                PsApp.doaction "Initial Prompt" "Callis Scripts"

                                                            -- Delete directory

                                                                fileClass = dotNetClass "System.IO.Directory"
                                                                fileClass.Delete @"C:\\Callis Scripts\\Metadata" true

                                                        -- Replace 16b prompt

                                                            -- Delete directory if it exists

                                                                try(
                                                                    fileClass = dotNetClass "System.IO.Directory"
                                                                    fileClass.Delete @"C:\\Callis Scripts\\Metadata" true
                                                                )catch()

                                                            -- Create directory

                                                                -- Layer name

                                                                    -- Create dialogInitialPromptLayer variable

                                                                        if photoshopDoFor32b.checked == true then(
                                                                            dialogInitialPromptLayer = "N"
                                                                        )

                                                                        if photoshopDoFor16b.checked == true then(
                                                                            dialogInitialPromptLayer = "O"
                                                                        )

                                                                        if photoshopDoFor16bAnd32b.checked == true then(
                                                                            dialogInitialPromptLayer = "Y"
                                                                        )

                                                                    myDirectory = "C:\\Callis Scripts\\Metadata\\" + "initialPromptLayer" + dialogInitialPromptLayer
                                                                    makedir myDirectory

                                                                -- Group name

                                                                    -- Create dialogInitialPromptGroup variable

                                                                        dialogInitialPromptGroup = "promptFor16b"

                                                                    myDirectory = "C:\\Callis Scripts\\Metadata\\" + "initialPromptGroup" + dialogInitialPromptGroup
                                                                    makedir myDirectory

                                                            -- Run Photoshop action

                                                                PsApp.bringToFront()
                                                                PsApp.doaction "Initial Prompt" "Callis Scripts"

                                                            -- Delete directory

                                                                fileClass = dotNetClass "System.IO.Directory"
                                                                fileClass.Delete @"C:\\Callis Scripts\\Metadata" true

                                                        -- Run the script

                                                            PsApp.bringToFront()
                                                            PsApp.doaction "Organisation Scripts..." "Callis Scripts"
                                                    )

                                                    if highResify.checked == true then(
                                                        -- Replace initial prompt

                                                            -- Delete directory if it exists

                                                                try(
                                                                    fileClass = dotNetClass "System.IO.Directory"
                                                                    fileClass.Delete @"C:\\Callis Scripts\\Metadata" true
                                                                )catch()

                                                            -- Create directory

                                                                -- Layer name

                                                                    -- Create dialogInitialPromptLayer variable

                                                                        dialogInitialPromptLayer = "H"

                                                                    myDirectory = "C:\\Callis Scripts\\Metadata\\" + "initialPromptLayer" + dialogInitialPromptLayer
                                                                    makedir myDirectory

                                                                -- Group name

                                                                    -- Create dialogInitialPromptGroup variable

                                                                        dialogInitialPromptGroup = "initialPrompt"

                                                                    myDirectory = "C:\\Callis Scripts\\Metadata\\" + "initialPromptGroup" + dialogInitialPromptGroup
                                                                    makedir myDirectory

                                                            -- Run Photoshop action

                                                                PsApp.bringToFront()
                                                                PsApp.doaction "Initial Prompt" "Callis Scripts"

                                                            -- Delete directory

                                                                fileClass = dotNetClass "System.IO.Directory"
                                                                fileClass.Delete @"C:\\Callis Scripts\\Metadata" true

                                                        -- Replace root folder path prompt

                                                            -- Delete directory if it exists

                                                                try(
                                                                    fileClass = dotNetClass "System.IO.Directory"
                                                                    fileClass.Delete @"C:\\Callis Scripts\\Metadata" true
                                                                )catch()

                                                            -- Create directory

                                                                -- Layer name

                                                                    -- Create dialogInitialPromptLayer variable

                                                                        dialogOutputFolderPreliminary2 = $'Output Path Dummy'.layer.name

                                                                        dialogOutputFolderPreliminary = substituteString dialogOutputFolderPreliminary2 "Output Path: " ""

                                                                        dialogOutputFolder9 = substituteString dialogOutputFolderPreliminary "/" "\\"

                                                                        dialogOutputFolder8 = substituteString dialogOutputFolder9 "\\" "\\\\"

                                                                        dialogOutputFolder7 = substituteString dialogOutputFolder8 "\\\\" "xxslashxx"

                                                                        dialogOutputFolder6 = substituteString dialogOutputFolder7 ":" "xxcolonxx"

                                                                        dialogInitialPromptLayer = "dialogOutputFolderSpacer" + dialogOutputFolder6

                                                                    myDirectory = "C:\\Callis Scripts\\Metadata\\" + "initialPromptLayer" + dialogInitialPromptLayer
                                                                    makedir myDirectory

                                                                -- Group name

                                                                    -- Create dialogInitialPromptGroup variable

                                                                        dialogInitialPromptGroup = "rootFolderPath"

                                                                    myDirectory = "C:\\Callis Scripts\\Metadata\\" + "initialPromptGroup" + dialogInitialPromptGroup
                                                                    makedir myDirectory

                                                            -- Run Photoshop action

                                                                PsApp.bringToFront()
                                                                PsApp.doaction "Initial Prompt" "Callis Scripts"

                                                            -- Delete directory

                                                                fileClass = dotNetClass "System.IO.Directory"
                                                                fileClass.Delete @"C:\\Callis Scripts\\Metadata" true

                                                        -- Replace frame number prompt

                                                            -- Delete directory if it exists

                                                                try(
                                                                    fileClass = dotNetClass "System.IO.Directory"
                                                                    fileClass.Delete @"C:\\Callis Scripts\\Metadata" true
                                                                )catch()

                                                            -- Create directory

                                                                -- Layer name

                                                                    -- Create dialogInitialPromptLayer variable

                                                                        if photoshopCurrentFrames.checked == true then(
                                                                            dialogInitialPromptLayer = frameNumbersString
                                                                        )

                                                                        if photoshopAllFrames.checked == true then(
                                                                            dialogInitialPromptLayer = "All"
                                                                        )

                                                                        if photoshopSpecifiedFrames.checked == true then(
                                                                            dialogInitialPromptLayer = photoshopFrameNumbersString
                                                                        )

                                                                    myDirectory = "C:\\Callis Scripts\\Metadata\\" + "initialPromptLayer" + dialogInitialPromptLayer
                                                                    makedir myDirectory

                                                                -- Group name

                                                                    -- Create dialogInitialPromptGroup variable

                                                                        dialogInitialPromptGroup = "promptForFrameNumber"

                                                                    myDirectory = "C:\\Callis Scripts\\Metadata\\" + "initialPromptGroup" + dialogInitialPromptGroup
                                                                    makedir myDirectory

                                                            -- Run Photoshop action

                                                                PsApp.bringToFront()
                                                                PsApp.doaction "Initial Prompt" "Callis Scripts"

                                                            -- Delete directory

                                                                fileClass = dotNetClass "System.IO.Directory"
                                                                fileClass.Delete @"C:\\Callis Scripts\\Metadata" true

                                                        -- Replace overwrite original files prompt

                                                            -- Delete directory if it exists

                                                                try(
                                                                    fileClass = dotNetClass "System.IO.Directory"
                                                                    fileClass.Delete @"C:\\Callis Scripts\\Metadata" true
                                                                )catch()

                                                            -- Create directory

                                                                -- Layer name

                                                                    -- Create dialogInitialPromptLayer variable

                                                                        if overwriteExistingFiles.checked == true then(
                                                                            dialogInitialPromptLayer = "Y"
                                                                        )else(
                                                                            dialogInitialPromptLayer = "N"
                                                                        )

                                                                    myDirectory = "C:\\Callis Scripts\\Metadata\\" + "initialPromptLayer" + dialogInitialPromptLayer
                                                                    makedir myDirectory

                                                                -- Group name

                                                                    -- Create dialogInitialPromptGroup variable

                                                                        dialogInitialPromptGroup = "promptForOverWriteDecision"

                                                                    myDirectory = "C:\\Callis Scripts\\Metadata\\" + "initialPromptGroup" + dialogInitialPromptGroup
                                                                    makedir myDirectory

                                                            -- Run Photoshop action

                                                                PsApp.bringToFront()
                                                                PsApp.doaction "Initial Prompt" "Callis Scripts"

                                                            -- Delete directory

                                                                fileClass = dotNetClass "System.IO.Directory"
                                                                fileClass.Delete @"C:\\Callis Scripts\\Metadata" true

                                                        -- Run the script

                                                            PsApp.bringToFront()
                                                            PsApp.doaction "Organisation Scripts..." "Callis Scripts"
                                                    )

                                                    -- Delete directory

                                                        fileClass = dotNetClass "System.IO.Directory"
                                                        fileClass.Delete @"C:\\Callis Scripts" true
                                                )
                                            )
                                        )
                                    )
                                )

                                on previewButton pressed do(
                                    -- Close the dialog

                                        DestroyDialog renderSpecifiedFrames

                                    -- Load render preset

                                        try(
                                            renderpresets.Load 0 ("$scripts/CallisScripts/Render Presets/Preview.rps") #{32}
                                        )catch()

                                    if renderRegionCheckBox.checked == true then(

                                        showRelevantHiddenLayers()

                                        if forceActiveViewCheckBox.checked == true then(
                                            renderCurrentFrameToCorrespondingFolderPreliminary "false" "true" "false" "dontSave" "NA"
                                        )else(
                                            renderCurrentFrameToCorrespondingFolderPreliminary "false" "false" "false" "dontSave" "NA"
                                        )

                                        hideRelevantShownLayers()
                                    )else(
                                        showRelevantHiddenLayers()

                                        if forceActiveViewCheckBox.checked == true then(
                                            renderCurrentFrameToCorrespondingFolderPreliminary "false" "true" "false" "dontSave" "NA"
                                        )else(
                                            renderCurrentFrameToCorrespondingFolderPreliminary "false" "false" "false" "dontSave" "NA"
                                        )

                                        hideRelevantShownLayers()
                                    )
                                )

                                on testButton pressed do(
                                    -- Close the dialog

                                        DestroyDialog renderSpecifiedFrames

                                    -- Load render preset

                                        try(
                                            renderpresets.Load 0 ("$scripts/CallisScripts/Render Presets/Preview.rps") #{32}
                                        )catch()

                                    if renderRegionCheckBox.checked == true then(

                                        showRelevantHiddenLayers()

                                        if forceActiveViewCheckBox.checked == true then(
                                            renderCurrentFrameToCorrespondingFolderPreliminary "false" "true" "test" "dontSave" "NA"
                                        )else(
                                            renderCurrentFrameToCorrespondingFolderPreliminary "false" "false" "test" "dontSave" "NA"
                                        )

                                        hideRelevantShownLayers()
                                    )else(
                                        showRelevantHiddenLayers()

                                        if forceActiveViewCheckBox.checked == true then(
                                            renderCurrentFrameToCorrespondingFolderPreliminary "false" "true" "test" "dontSave" "NA"
                                        )else(
                                            renderCurrentFrameToCorrespondingFolderPreliminary "false" "false" "test" "dontSave" "NA"
                                        )

                                        hideRelevantShownLayers()
                                    )
                                )

                                on thumbnailButton pressed do(
                                    -- Close the dialog

                                        DestroyDialog renderSpecifiedFrames

                                    -- Load render preset

                                        try(
                                            renderpresets.Load 0 ("$scripts/CallisScripts/Render Presets/Preview.rps") #{32}
                                        )catch()

                                    if renderRegionCheckBox.checked == true then(
                                        showRelevantHiddenLayers()

                                        if forceActiveViewCheckBox.checked == true then(
                                            renderCurrentFrameToCorrespondingFolderPreliminary "false" "true" "thumbnail" "dontSave" "NA"
                                        )else(
                                            renderCurrentFrameToCorrespondingFolderPreliminary "false" "false" "thumbnail" "dontSave" "NA"
                                        )

                                        hideRelevantShownLayers()
                                    )else(
                                        showRelevantHiddenLayers()

                                        if forceActiveViewCheckBox.checked == true then(
                                            renderCurrentFrameToCorrespondingFolderPreliminary "false" "true" "thumbnail" "dontSave" "NA"
                                        )else(
                                            renderCurrentFrameToCorrespondingFolderPreliminary "false" "false" "thumbnail" "dontSave" "NA"
                                        )

                                        hideRelevantShownLayers()
                                    )
                                )
                    )

                -- Create renderSpecifiedFrames dialog

                    createDialog renderSpecifiedFrames 220 505
            )

        -- Set project folder

            fn setProjectFolderFunction = (
                rollout callisScriptsSetProjectFolderRollout "Set Project Folder"(
                    -- Variables

                        local currentFolderNameVariable = ""
                        local userNameVariable = "Josh"
                        local createCurrentFolderVariable = true

                        local hi = "C:\\Test"
                        local pathVariable = substituteString hi "Project Folder Path: " ""

                    -- Components

                        editText pathEditText "Path:" text:pathVariable width:300 enabled:true

                        editText folderNameEditText "Current Folder Name:" text:"" width:300 enabled:true

                        editText userNameEditText "User Name:" text:"Josh" width:300 enabled:true

                        checkBox createCurrentFolderCheckBox "Create Current Folder" checked:true

                        button setButton "Set"

                    -- Actions

                        on pathEditText entered txt do(
                            if txt != "" and txt != undefined then(
                                pathVariable = txt
                            )
                        )

                        on folderNameEditText entered txt do(
                            if txt != "" and txt != undefined then(
                                currentFolderNameVariable = txt
                            )
                        )

                        on usernameEditText entered txt do(
                            if txt != "" and txt != undefined then(
                                userNameVariable = txt
                            )
                        )

                        on createCurrentFolderCheckBox changed state do(
                            if state then(
                                createCurrentFolderVariable = true

                                folderNameEditText.enabled = true

                                userNameEditText.enabled = true
                            )else(
                                createCurrentFolderVariable = false

                                folderNameEditText.enabled = false

                                userNameEditText.enabled = false
                            )
                        )

                        on setButton pressed do(
                            if pathVariable != "" and pathVariable != undefined and (((currentFolderNameVariable != "" and currentFolderNameVariable != undefined) and (userNameVariable != "" and userNameVariable != undefined)) or createCurrentFolderVariable == false) then(
                                try(
                                    SetQuietMode true

                                    pathConfig.doProjectSetupStepsUsingDirectory pathVariable

                                    makeDir (pathVariable + "\\" + "Renders")

                                    makeDir (pathVariable + "\\" + "Photoshop")

                                    makeDir (pathVariable + "\\" + "Uploads")

                                    makeDir (pathVariable + "\\" + "Reference")

                                    if createCurrentFolderVariable == true then(
                                        makeDir (pathVariable + "\\" + "downloads" + "\\" + currentFolderNameVariable)

                                        makeDir (pathVariable + "\\" + "export" + "\\" + currentFolderNameVariable)

                                        makeDir (pathVariable + "\\" + "import" + "\\" + currentFolderNameVariable)

                                        makeDir (pathVariable + "\\" + "Photoshop" + "\\" + currentFolderNameVariable)

                                        makeDir (pathVariable + "\\" + "Reference" + "\\" + currentFolderNameVariable)

                                        makeDir (pathVariable + "\\" + "renderoutput" + "\\" + currentFolderNameVariable)

                                        makeDir (pathVariable + "\\" + "renderoutput" + "\\" + currentFolderNameVariable + "\\" + userNameVariable)

                                        makeDir (pathVariable + "\\" + "Renders" + "\\" + currentFolderNameVariable)

                                        makeDir (pathVariable + "\\" + "scenes" + "\\" + currentFolderNameVariable)

                                        -- Master

                                            makeDir (pathVariable + "\\" + "scenes" + "\\" + currentFolderNameVariable + "\\" + "Master")

                                            makeDir (pathVariable + "\\" + "scenes" + "\\" + currentFolderNameVariable + "\\" + "Master" + "\\" + "Superseded")

                                        -- Xref

                                            makeDir (pathVariable + "\\" + "scenes" + "\\" + currentFolderNameVariable + "\\" + "Xref")

                                            makeDir (pathVariable + "\\" + "scenes" + "\\" + currentFolderNameVariable + "\\" + "Xref" + "\\" + "Superseded")

                                        -- Miscellaneous

                                            makeDir (pathVariable + "\\" + "scenes" + "\\" + currentFolderNameVariable + "\\" + "Miscellaneous")

                                            makeDir (pathVariable + "\\" + "scenes" + "\\" + currentFolderNameVariable + "\\" + "Miscellaneous" + "\\" + "Superseded")

                                        -- Working

                                            makeDir (pathVariable + "\\" + "scenes" + "\\" + currentFolderNameVariable + "\\" + "Working")

                                            makeDir (pathVariable + "\\" + "scenes" + "\\" + currentFolderNameVariable + "\\" + "Working" + "\\" + "Superseded")

                                        makeDir (pathVariable + "\\" + "Uploads" + "\\" + currentFolderNameVariable)
                                    )

                                    destroyDialog callisScriptsSetProjectFolderRollout

                                    SetQuietMode false
                                )catch()
                            )
                        )
                )

                createDialog callisScriptsSetProjectFolderRollout 350 140
            )

        -- Interactive render

            fn callisScriptsStartInteractiveRender = (
                -- Define rollout for if lock render to view button hasn't been pressed in the current session yet

                    rollout callisScriptsReminderToPressLockRenderToViewRollout ""(
                        -- Components

                            editText reminderText "" text:"Please lock and then unlock the view to render\nwhile the camera is the active viewport, and try again" readOnly:true height:36

                            checkBox doneCheckBox "Done" checked:false

                            button closeButton "Close"

                        -- Actions

                            on doneCheckBox changed state do(
                                if state then(
                                    callisScriptsHasLockRenderToViewButtonBeenPressed = true
                                )else(
                                    callisScriptsHasLockRenderToViewButtonBeenPressed = undefined
                                )
                            )

                            on closeButton pressed do(
                                destroyDialog callisScriptsReminderToPressLockRenderToViewRollout
                            )
                    )

                if callisScriptsIsInteractiveRenderCurrentlyOn == undefined or callisScriptsIsInteractiveRenderCurrentlyOn == false then(
                    if callisScriptsHasLockRenderToViewButtonBeenPressed != true then(
                        createDialog callisScriptsReminderToPressLockRenderToViewRollout 350 100
                    )else(
                        -- Rollout

                            rollout callisScriptsStartInteractiveRenderRollout "Enter resolution index"(
                                editText instructionsEditText "" text:"Input resolution. 1 = Thumbnail, 2 = Test,\n3 = Low Res, 4 = High Res" readOnly:true height:36

                                editText resolutionEditText ""

                                on callisScriptsStartInteractiveRenderRollout open do(
                                    setFocus resolutionEditText
                                )

                                on resolutionEditText entered txt do(
                                    destroyDialog callisScriptsStartInteractiveRenderRollout

                                    -- Load render preset

                                        try(
                                            renderpresets.Load 0 ("$scripts/CallisScripts/Render Presets/Preview.rps") #{32}
                                        )catch()

                                    -- Get frame number

                                        local currentFrameNumberPreliminary = sliderTime as string

                                        local currentFrameNumberAsStringPreliminary = filterString currentFrameNumberPreliminary "f" splitEmptyTokens:false

                                        local currentFrameNumberAsString = currentFrameNumberAsStringPreliminary[1]

                                        local frameNumber = currentFrameNumberAsString as integer

                                    -- Set frame number

                                        changeFrameNumber frameNumber

                                    -- Set resolution

                                        if txt == "1" then(
                                            callisScriptsSetFrameSize "thumbnail"
                                        )

                                        if txt == "2" then(
                                            callisScriptsSetFrameSize "test"
                                        )

                                        if txt == "3" then(
                                            callisScriptsSetFrameSize "false"
                                        )

                                        if txt == "4" then(
                                            callisScriptsSetFrameSize "true"
                                        )

                                    vrayStartIPR()

                                    -- Lock view to render to current frame's camera

                                        try(
                                            for a = 1 to viewport.numViews do(
                                                viewport.activeViewport = a

                                                if viewport.getType() == #view_camera then(
                                                    viewContainingCamera = a
                                                )
                                            )

                                            if viewContainingCamera != undefined then(
                                                viewport.activeViewport = viewContainingCamera
                                            )else(
                                                -- Variables

                                                    oldLayer = LayerManager.current
                                                    layer = layerManager.getLayerFromName "Temporary Script Objects"

                                                deselect cameras

                                                if viewport.getType() == #view_persp_user then(
                                                    try(
                                                        try(
                                                            delete $CallisScriptsTemporaryPerspectiveCamera
                                                        )catch()

                                                        layer.current = true

                                                        macros.run "Lights and Cameras" "PhysicalCamera_CreateFromView"

                                                        activeCamera = getactivecamera()

                                                        viewport.setCamera (getActiveFramesCamera())

                                                        activeCamera.name = "CallisScriptsTemporaryPerspectiveCamera"

                                                        hide activeCamera

                                                        hide $CallisScriptsTemporaryPerspectiveCamera.Target

                                                        oldLayer.current = true

                                                        displaySafeFrames = true

                                                        viewport.EnableSolidBackgroundColorMode false
                                                    )catch()
                                                )else(
                                                )

                                                redrawViews()
                                            )

                                            viewport.setCamera (getActiveFramesCamera())
                                        )catch()

                                        rendUseActiveView = false

                                    callisScriptsIsInteractiveRenderCurrentlyOn = true
                                )
                            )

                            createDialog callisScriptsStartInteractiveRenderRollout 250 70
                    )
                )else(
                    vrayStopIPR()

                    -- Unlock view to render

                        rendUseActiveView = true

                    callisScriptsIsInteractiveRenderCurrentlyOn = false
                )
            )

        -- Toggle autokey and camera lock

            fn toggleAutokeyAndCameraLock = (
                if callisScriptsCamerasLocked == true then(
                    setTransformLockFlags cameras #none

                    callisScriptsCamerasLocked = false
                )else(
                    setTransformLockFlags cameras #all

                    callisScriptsCamerasLocked = true
                )
            )

        -- Create layer structure

            fn createLayerStructure = (
                -- Remove empty layers

                    try(
                        macros.run "Scene Explorer" "SERemoveEmptyLayers"
                    )catch()

                -- Create Layers

                    -- Create scripting metadata sublayers if there wasn't an existing 'Scripting Metadata' layer before running the script

                        if LayerManager.getLayerFromName "Scripting Metadata" == undefined then(
                            try(
                                LayerManager.newLayerFromName "Frame Names: 1 Name, 2 Name, 3 Name, 4 Name, 5 Name, 6 Name, 7 Name, 8 Name, 9 Name, 10 Name"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Frame Sizes: 1. 750x500, 2. 750x500, 3. 750x500, 4. 750x500, 5. 750x500, 6. 750x500, 7. 750x500, 8. 750x500, 9. 750x500, 10. 750x500"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Output Path: C:\Test"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Project Folder Path: C:\Test"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Separate Glass: No"
                            )catch()
                        )

                    -- Environment

                        try(
                            LayerManager.newLayerFromName "Cameras"
                        )catch()

                        try(
                            LayerManager.newLayerFromName "Environment"
                        )catch()

                        try(
                            LayerManager.newLayerFromName "Sky"
                        )catch()

                        try(
                            LayerManager.newLayerFromName "Sun"
                        )catch()

                    -- Geometry

                        -- Building

                            try(
                                LayerManager.newLayerFromName "Geometry —"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Building —"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Balustrades —"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Ceilings —"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Cladding —"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Floors —"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Glass —"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Glass (Non-Separate)"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Glass (Separate)"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Joinery —"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Mechanics —"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Miscellaneous (Building) —"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Mullions —"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Rooves —"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Signage —"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Spandrels —"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Structure —"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Walls —"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "External Walls —"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Internal Walls"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Window Frames —"
                            )catch()

                        -- Context

                            try(
                                LayerManager.newLayerFromName "Context —"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Background —"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Miscellaneous (Context) —"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Paving —"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Roads —"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Surrounding Buildings —"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Terrain —"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Landscaping —"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Curbs —"
                            )catch()

                        -- Landscaping

                            try(
                                LayerManager.newLayerFromName "Miscellaneous (Landscaping) —"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Paving (Landscaping) —"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Planters —"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Roads (Landscaping) —"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Terrain (Landscaping) —"
                            )catch()

                        -- Population

                            try(
                                LayerManager.newLayerFromName "Population —"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Electronics —"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Entourage —"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "People —"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Vehicles —"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Furniture —"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Lighting —"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Light Fittings"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Lights"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Miscellaneous (Population) —"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Vegitation —"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Grass —"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Plants —"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Substrate —"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Trees —"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Water —"
                            )catch()

                    -- Miscellaneous

                        try(
                            LayerManager.newLayerFromName "Miscellaneous"
                        )catch()

                        try(
                            LayerManager.newLayerFromName "Drafting"
                        )catch()

                        try(
                            LayerManager.newLayerFromName "Bitmaps"
                        )catch()

                        try(
                            LayerManager.newLayerFromName "Linework (Drafting)"
                        )catch()

                        try(
                            LayerManager.newLayerFromName "Dummy Objects"
                        )catch()

                        try(
                            LayerManager.newLayerFromName "Linework"
                        )catch()

                        -- Scatter Objects

                            try(
                                LayerManager.newLayerFromName "Scatter Objects"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Scatter Objects, People"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Scatter Objects, People, Standing"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Scatter Objects, People, Walking"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Scatter Objects, People, Sitting"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Scatter Objects, Vegetation"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Scatter Objects, Trees"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Scatter Objects, Plants"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Scatter Objects, Grass"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Scatter Objects, Substrate"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Scatter Objects, Vehicles"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Scatter Objects, Miscellaneous"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Scatter Objects, Curbs"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Scatter Objects, Lighting"
                            )catch()

                        -- Scatter Surfaces

                            try(
                                LayerManager.newLayerFromName "Scatter Surfaces"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Scatter Surfaces, People"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Scatter Surfaces, People, Standing"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Scatter Surfaces, People, Walking"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Scatter Surfaces, People, Sitting"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Scatter Surfaces, Vegetation"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Scatter Surfaces, Trees"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Scatter Surfaces, Plants"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Scatter Surfaces, Grass"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Scatter Surfaces, Substrate"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Scatter Surfaces, Vehicles"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Scatter Surfaces, Miscellaneous"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Scatter Surfaces, Curbs"
                            )catch()

                            try(
                                LayerManager.newLayerFromName "Scatter Surfaces, Lighting"
                            )catch()

                        try(
                            LayerManager.newLayerFromName "Scripting Metadata"
                        )catch()

                        try(
                            LayerManager.newLayerFromName "Temporary Script Objects"
                        )catch()

                -- Organise Layers

                    -- Environment

                        (LayerManager.getLayerFromName "Sky").setParent (LayerManager.getLayerFromName "Environment")

                        (LayerManager.getLayerFromName "Sun").setParent (LayerManager.getLayerFromName "Environment")

                    -- Geometry —

                        (LayerManager.getLayerFromName "Building —").setParent (LayerManager.getLayerFromName "Geometry —")

                        (LayerManager.getLayerFromName "Context —").setParent (LayerManager.getLayerFromName "Geometry —")

                        (LayerManager.getLayerFromName "Landscaping —").setParent (LayerManager.getLayerFromName "Geometry —")

                        (LayerManager.getLayerFromName "Population —").setParent (LayerManager.getLayerFromName "Geometry —")

                        -- Building —

                            (LayerManager.getLayerFromName "Balustrades —").setParent (LayerManager.getLayerFromName "Building —")

                            (LayerManager.getLayerFromName "Ceilings —").setParent (LayerManager.getLayerFromName "Building —")

                            (LayerManager.getLayerFromName "Cladding —").setParent (LayerManager.getLayerFromName "Building —")

                            (LayerManager.getLayerFromName "Floors —").setParent (LayerManager.getLayerFromName "Building —")

                            (LayerManager.getLayerFromName "Glass —").setParent (LayerManager.getLayerFromName "Building —")

                            (LayerManager.getLayerFromName "Joinery —").setParent (LayerManager.getLayerFromName "Building —")

                            (LayerManager.getLayerFromName "Mechanics —").setParent (LayerManager.getLayerFromName "Building —")

                            (LayerManager.getLayerFromName "Miscellaneous (Building) —").setParent (LayerManager.getLayerFromName "Building —")

                            (LayerManager.getLayerFromName "Mullions —").setParent (LayerManager.getLayerFromName "Building —")

                            (LayerManager.getLayerFromName "Rooves —").setParent (LayerManager.getLayerFromName "Building —")

                            (LayerManager.getLayerFromName "signage —").setParent (LayerManager.getLayerFromName "Building —")

                            (LayerManager.getLayerFromName "Spandrels —").setParent (LayerManager.getLayerFromName "Building —")

                            (LayerManager.getLayerFromName "Structure —").setParent (LayerManager.getLayerFromName "Building —")

                            (LayerManager.getLayerFromName "Walls —").setParent (LayerManager.getLayerFromName "Building —")

                            (LayerManager.getLayerFromName "External Walls —").setParent (LayerManager.getLayerFromName "Walls —")

                            (LayerManager.getLayerFromName "Internal Walls").setParent (LayerManager.getLayerFromName "Walls —")

                            (LayerManager.getLayerFromName "Window Frames —").setParent (LayerManager.getLayerFromName "Building —")

                            -- Glass —

                                (LayerManager.getLayerFromName "Glass (Non-Separate)").setParent (LayerManager.getLayerFromName "Glass —")

                                (LayerManager.getLayerFromName "Glass (Separate)").setParent (LayerManager.getLayerFromName "Glass —")

                        -- Context —

                            (LayerManager.getLayerFromName "Background —").setParent (LayerManager.getLayerFromName "Context —")

                            (LayerManager.getLayerFromName "Miscellaneous (Context) —").setParent (LayerManager.getLayerFromName "Context —")

                            (LayerManager.getLayerFromName "Paving —").setParent (LayerManager.getLayerFromName "Context —")

                            (LayerManager.getLayerFromName "Roads —").setParent (LayerManager.getLayerFromName "Context —")

                            (LayerManager.getLayerFromName "Surrounding Buildings —").setParent (LayerManager.getLayerFromName "Context —")

                            (LayerManager.getLayerFromName "Terrain —").setParent (LayerManager.getLayerFromName "Context —")

                        -- Landscaping —

                            (LayerManager.getLayerFromName "Curbs —").setParent (LayerManager.getLayerFromName "Landscaping —")

                            (LayerManager.getLayerFromName "Miscellaneous (Landscaping) —").setParent (LayerManager.getLayerFromName "Landscaping —")

                            (LayerManager.getLayerFromName "Paving (Landscaping) —").setParent (LayerManager.getLayerFromName "Landscaping —")

                            (LayerManager.getLayerFromName "Planters —").setParent (LayerManager.getLayerFromName "Landscaping —")

                            (LayerManager.getLayerFromName "Roads (Landscaping) —").setParent (LayerManager.getLayerFromName "Landscaping —")

                            (LayerManager.getLayerFromName "Terrain (Landscaping) —").setParent (LayerManager.getLayerFromName "Landscaping —")

                        -- Population —

                            (LayerManager.getLayerFromName "Electronics —").setParent (LayerManager.getLayerFromName "Population —")

                            (LayerManager.getLayerFromName "Entourage —").setParent (LayerManager.getLayerFromName "Population —")

                            (LayerManager.getLayerFromName "Furniture —").setParent (LayerManager.getLayerFromName "Population —")

                            (LayerManager.getLayerFromName "Lighting —").setParent (LayerManager.getLayerFromName "Population —")

                            (LayerManager.getLayerFromName "Miscellaneous (Population) —").setParent (LayerManager.getLayerFromName "Population —")

                            (LayerManager.getLayerFromName "Vegitation —").setParent (LayerManager.getLayerFromName "Population —")

                            (LayerManager.getLayerFromName "Water —").setParent (LayerManager.getLayerFromName "Population —")

                            -- Entourage —

                                (LayerManager.getLayerFromName "People —").setParent (LayerManager.getLayerFromName "Entourage —")

                                (LayerManager.getLayerFromName "Vehicles —").setParent (LayerManager.getLayerFromName "Entourage —")

                            -- Lighting —

                                (LayerManager.getLayerFromName "Light Fittings").setParent (LayerManager.getLayerFromName "Lighting —")

                                (LayerManager.getLayerFromName "Lights").setParent (LayerManager.getLayerFromName "Lighting —")

                            -- Vegitation —

                                (LayerManager.getLayerFromName "Grass —").setParent (LayerManager.getLayerFromName "Vegitation —")

                                (LayerManager.getLayerFromName "Plants —").setParent (LayerManager.getLayerFromName "Vegitation —")

                                (LayerManager.getLayerFromName "Substrate —").setParent (LayerManager.getLayerFromName "Vegitation —")

                                (LayerManager.getLayerFromName "Trees —").setParent (LayerManager.getLayerFromName "Vegitation —")

                    -- Miscellaneous

                        (LayerManager.getLayerFromName "Drafting").setParent (LayerManager.getLayerFromName "Miscellaneous")

                        (LayerManager.getLayerFromName "Dummy Objects").setParent (LayerManager.getLayerFromName "Miscellaneous")

                        (LayerManager.getLayerFromName "Linework").setParent (LayerManager.getLayerFromName "Miscellaneous")

                        (LayerManager.getLayerFromName "Scatter Objects").setParent (LayerManager.getLayerFromName "Miscellaneous")

                        -- Scatter Objects

                            (LayerManager.getLayerFromName "Scatter Objects, People").setParent (LayerManager.getLayerFromName "Scatter Objects")

                            -- Scatter Objects, People

                                (LayerManager.getLayerFromName "Scatter Objects, People, Standing").setParent (LayerManager.getLayerFromName "Scatter Objects, People")

                                (LayerManager.getLayerFromName "Scatter Objects, People, Walking").setParent (LayerManager.getLayerFromName "Scatter Objects, People")

                                (LayerManager.getLayerFromName "Scatter Objects, People, Sitting").setParent (LayerManager.getLayerFromName "Scatter Objects, People")

                            (LayerManager.getLayerFromName "Scatter Objects, Vegetation").setParent (LayerManager.getLayerFromName "Scatter Objects")

                            -- Scatter Objects, Vegetation

                                (LayerManager.getLayerFromName "Scatter Objects, Trees").setParent (LayerManager.getLayerFromName "Scatter Objects, Vegetation")

                                (LayerManager.getLayerFromName "Scatter Objects, Plants").setParent (LayerManager.getLayerFromName "Scatter Objects, Vegetation")

                                (LayerManager.getLayerFromName "Scatter Objects, Grass").setParent (LayerManager.getLayerFromName "Scatter Objects, Vegetation")

                                (LayerManager.getLayerFromName "Scatter Objects, Substrate").setParent (LayerManager.getLayerFromName "Scatter Objects, Vegetation")

                            (LayerManager.getLayerFromName "Scatter Objects, Vehicles").setParent (LayerManager.getLayerFromName "Scatter Objects")

                            (LayerManager.getLayerFromName "Scatter Objects, Miscellaneous").setParent (LayerManager.getLayerFromName "Scatter Objects")

                            (LayerManager.getLayerFromName "Scatter Objects, Curbs").setParent (LayerManager.getLayerFromName "Scatter Objects")

                            (LayerManager.getLayerFromName "Scatter Objects, Lighting").setParent (LayerManager.getLayerFromName "Scatter Objects")

                        (LayerManager.getLayerFromName "Scatter Surfaces").setParent (LayerManager.getLayerFromName "Miscellaneous")

                        -- Scatter Surfaces

                            (LayerManager.getLayerFromName "Scatter Surfaces, People").setParent (LayerManager.getLayerFromName "Scatter Surfaces")

                            -- Scatter Surfaces, People

                                (LayerManager.getLayerFromName "Scatter Surfaces, People, Standing").setParent (LayerManager.getLayerFromName "Scatter Surfaces, People")

                                (LayerManager.getLayerFromName "Scatter Surfaces, People, Walking").setParent (LayerManager.getLayerFromName "Scatter Surfaces, People")

                                (LayerManager.getLayerFromName "Scatter Surfaces, People, Sitting").setParent (LayerManager.getLayerFromName "Scatter Surfaces, People")

                            (LayerManager.getLayerFromName "Scatter Surfaces, Vegetation").setParent (LayerManager.getLayerFromName "Scatter Surfaces")

                            -- Scatter Surfaces, Vegetation

                                (LayerManager.getLayerFromName "Scatter Surfaces, Trees").setParent (LayerManager.getLayerFromName "Scatter Surfaces, Vegetation")

                                (LayerManager.getLayerFromName "Scatter Surfaces, Plants").setParent (LayerManager.getLayerFromName "Scatter Surfaces, Vegetation")

                                (LayerManager.getLayerFromName "Scatter Surfaces, Grass").setParent (LayerManager.getLayerFromName "Scatter Surfaces, Vegetation")

                                (LayerManager.getLayerFromName "Scatter Surfaces, Substrate").setParent (LayerManager.getLayerFromName "Scatter Surfaces, Vegetation")

                            (LayerManager.getLayerFromName "Scatter Surfaces, Vehicles").setParent (LayerManager.getLayerFromName "Scatter Surfaces")

                            (LayerManager.getLayerFromName "Scatter Surfaces, Miscellaneous").setParent (LayerManager.getLayerFromName "Scatter Surfaces")

                            (LayerManager.getLayerFromName "Scatter Surfaces, Curbs").setParent (LayerManager.getLayerFromName "Scatter Surfaces")

                            (LayerManager.getLayerFromName "Scatter Surfaces, Lighting").setParent (LayerManager.getLayerFromName "Scatter Surfaces")

                        (LayerManager.getLayerFromName "Scripting Metadata").setParent (LayerManager.getLayerFromName "Miscellaneous")

                        -- Drafting

                            (LayerManager.getLayerFromName "Bitmaps").setParent (LayerManager.getLayerFromName "Drafting")

                            (LayerManager.getLayerFromName "Linework (Drafting)").setParent (LayerManager.getLayerFromName "Drafting")

                        -- Scripting Metadata

                            try(
                                (LayerManager.getLayerFromName "Frame Names: 1 Name, 2 Name, 3 Name, 4 Name, 5 Name, 6 Name, 7 Name, 8 Name, 9 Name, 10 Name").setParent (LayerManager.getLayerFromName "Scripting Metadata")
                            )catch()

                            try(
                                (LayerManager.getLayerFromName "Frame Sizes: 1. 750x500, 2. 750x500, 3. 750x500, 4. 750x500, 5. 750x500, 6. 750x500, 7. 750x500, 8. 750x500, 9. 750x500, 10. 750x500").setParent (LayerManager.getLayerFromName "Scripting Metadata")
                            )catch()

                            try(
                                (LayerManager.getLayerFromName "Output Path: C:\\Test").setParent (LayerManager.getLayerFromName "Scripting Metadata")
                            )catch()

                            try(
                                (LayerManager.getLayerFromName "Separate Glass: No").setParent (LayerManager.getLayerFromName "Scripting Metadata")
                            )catch()

                            try(
                                (LayerManager.getLayerFromName "Temporary Script Objects").setParent (LayerManager.getLayerFromName "Scripting Metadata")
                            )catch()

                            try(
                                (LayerManager.getLayerFromName "Project Folder Path: C:\\Test").setParent (LayerManager.getLayerFromName "Scripting Metadata")
                            )catch()

                -- Create dummy objects

                    -- Frame Names

                        if $FrameNamesDummy == undefined then(
                            Dummy effect:0 pos:[0,0,0] isSelected:on
                            $.name = "Frame Names Dummy"
                            (LayerManager.getLayerFromName "Frame Names: 1 Name, 2 Name, 3 Name, 4 Name, 5 Name, 6 Name, 7 Name, 8 Name, 9 Name, 10 Name").addnode $
                            deselect selection
                            hide $FrameNamesDummy
                        )

                    -- Frame Sizes

                        if $FrameSizesDummy == undefined then(
                            Dummy effect:0 pos:[0,0,0] isSelected:on
                            $.name = "Frame Sizes Dummy"
                            (LayerManager.getLayerFromName "Frame Sizes: 1. 750x500, 2. 750x500, 3. 750x500, 4. 750x500, 5. 750x500, 6. 750x500, 7. 750x500, 8. 750x500, 9. 750x500, 10. 750x500").addnode $
                            deselect selection
                            hide $FrameSizesDummy
                        )

                    -- Output path

                        if $OutputPathDummy == undefined then(
                            Dummy effect:0 pos:[0,0,0] isSelected:on
                            $.name = "Output Path Dummy"
                            (LayerManager.getLayerFromName "Output Path: C:\Test").addnode $
                            deselect selection
                            hide $OutputPathDummy
                        )

                    -- Project folder path

                        if $OutputPathDummy == undefined then(
                            Dummy effect:0 pos:[0,0,0] isSelected:on
                            $.name = "Project Folder Dummy"
                            (LayerManager.getLayerFromName "Project Folder Path: C:\Test").addnode $
                            deselect selection
                            hide $ProjectFolderPathDummy
                        )

                    -- Separate Glass

                        if $OutputPathDummy == undefined then(
                            Dummy effect:0 pos:[0,0,0] isSelected:on
                            $.name = "Separate Glass Dummy"
                            (LayerManager.getLayerFromName "Separate Glass: No").addnode $
                            deselect selection
                            hide $SeparateGlassDummy
                        )

                    -- Objects

                        if $TemporaryScriptObjectsDummy == undefined then(
                            Dummy effect:0 pos:[0,0,0] isSelected:on
                            $.name = "Temporary Script Objects Dummy"
                            (LayerManager.getLayerFromName "Temporary Script Objects").addnode $
                            deselect selection
                            hide $TemporaryScriptObjectsDummy
                        )

                -- Hide/freeze layers

                    (LayerManager.getLayerFromName "Scripting Metadata").isFrozen = on

                -- Add multimatte layers

                    addMultimatteLayersToAllRelevantLayers "Geometry —"
            )

        /*
        -- Material Guesser

            -- UI

                fn materialGuesserUI = (
                    -- Define the dialogs

                        -- All slots

                            rollout allSlotsRollout "All Materials"(
                                -- Variables

                                    local materialGuesserIni = (getdir #plugcfg_ln) + "/Callis Scripts/Material Guesser.ini"
                                    local defaultImage = openBitMap("$scripts/CallisScripts/Images/1.bmp")

                                    -- Material names

                                        local materialNamesStringPreliminary = getINISetting materialGuesserIni "Material Guesser" "Material Names"
                                        local materialNamesString = substituteString materialNamesStringPreliminary "materialGuesserDummyMaterialName" " Empty"
                                        local materialNamesArray = filterString materialNamesString "|"

                                        local materialNamesString1 = materialNamesArray[1]
                                        local materialNamesString2 = materialNamesArray[2]
                                        local materialNamesString3 = materialNamesArray[3]
                                        local materialNamesString4 = materialNamesArray[4]
                                        local materialNamesString5 = materialNamesArray[5]
                                        local materialNamesString6 = materialNamesArray[6]
                                        local materialNamesString7 = materialNamesArray[7]
                                        local materialNamesString8 = materialNamesArray[8]
                                        local materialNamesString9 = materialNamesArray[9]
                                        local materialNamesString10 = materialNamesArray[10]

                                    -- Bitmap paths

                                        local BitmapsPathsStringPrelimminary = getINISetting materialGuesserIni "Material Guesser" "Bitmap Paths"
                                        local BitmapsPathsString = substituteString BitmapsPathsStringPrelimminary "materialGuesserDummyBitmapPath" "$scripts/CallisScripts/Images/1.bmp"
                                        local BitmapsPathsArray = filterString BitmapsPathsString "|"

                                        local BitmapPathString1 = openBitMap(BitmapsPathsArray[1])
                                        local BitmapPathString2 = openBitMap(BitmapsPathsArray[2])
                                        local BitmapPathString3 = openBitMap(BitmapsPathsArray[3])
                                        local BitmapPathString4 = openBitMap(BitmapsPathsArray[4])
                                        local BitmapPathString5 = openBitMap(BitmapsPathsArray[5])
                                        local BitmapPathString6 = openBitMap(BitmapsPathsArray[6])
                                        local BitmapPathString7 = openBitMap(BitmapsPathsArray[7])
                                        local BitmapPathString8 = openBitMap(BitmapsPathsArray[8])
                                        local BitmapPathString9 = openBitMap(BitmapsPathsArray[9])
                                        local BitmapPathString10 = openBitMap(BitmapsPathsArray[10])

                                -- Components

                                    -- Slot 1

                                        imgTag image1 style:#bmp_center bitmap:BitmapPathString1 height:120 width:120 pos:[10,10]
                                        editText title1 text:("1: " + materialNamesString1) fieldWidth:120 readOnly:true pos:[6,140]

                                    -- Slot 2

                                        imgTag image2 style:#bmp_center bitmap:BitmapPathString2 height:120 width:120 pos:[160,10]
                                        editText title2 text:("2: " + materialNamesString2) fieldWidth:120 readOnly:true pos:[156,140]

                                    -- Slot 3

                                        imgTag image3 style:#bmp_center bitmap:BitmapPathString3 height:120 width:120 pos:[310,10]
                                        editText title3 text:("3: " + materialNamesString3) fieldWidth:120 readOnly:true pos:[306,140]

                                    -- Slot 4

                                        imgTag image4 style:#bmp_center bitmap:BitmapPathString4 height:120 width:120 pos:[460,10]
                                        editText title4 text:("4: " + materialNamesString4) fieldWidth:120 readOnly:true pos:[456,140]

                                    -- Slot 5

                                        imgTag image5 style:#bmp_center bitmap:BitmapPathString5 height:120 width:120 pos:[610,10]
                                        editText title5 text:("5: " + materialNamesString5) fieldWidth:120 readOnly:true pos:[606,140]

                                    -- Slot 6

                                        imgTag image6 style:#bmp_center bitmap:BitmapPathString6 height:120 width:120 pos:[10,310]
                                        editText title6 text:("6: " + materialNamesString6) fieldWidth:120 readOnly:true pos:[6,440]

                                    -- Slot 7

                                        imgTag image7 style:#bmp_center bitmap:BitmapPathString7 height:120 width:120 pos:[160,310]
                                        editText title7 text:("7: " + materialNamesString7) fieldWidth:120 readOnly:true pos:[156,440]

                                    -- Slot 8

                                        imgTag image8 style:#bmp_center bitmap:BitmapPathString8 height:120 width:120 pos:[310,310]
                                        editText title8 text:("8: " + materialNamesString8) fieldWidth:120 readOnly:true pos:[306,440]

                                    -- Slot 9

                                        imgTag image9 style:#bmp_center bitmap:BitmapPathString9 height:120 width:120 pos:[460,310]
                                        editText title9 text:("9: " + materialNamesString9) fieldWidth:120 readOnly:true pos:[456,440]

                                    -- Slot 10

                                        imgTag image10 style:#bmp_center bitmap:BitmapPathString10 height:120 width:120 pos:[610,310]
                                        editText title10 text:("10: " + materialNamesString10) fieldWidth:120 readOnly:true pos:[606,440]
                            )

                        -- Main

                            rollout materialGuesserUIRollout "Material Guesser"(
                                subrollout allSlotsSubRollout "All Materials"

                                -- Variables

                                    local materialGuesserIni = (getdir #plugcfg_ln) + "/Callis Scripts/Material Guesser.ini"
                                    local slotNumberFromSpinnerAsString = "1"

                                -- Components

                                    spinner title1 type:#integer width:120 range:[1,10,1] pos:[6,540]
                                    button editMaterialButton1 "Apply Current Material" width:120 pos:[10,566]
                                    button editTagsButton1 "Edit Tags" width:120 pos:[10,596]

                                -- Actions

                                    on title1 changed num do(
                                        slotNumberFromSpinnerAsString = (num as string)
                                    )

                                    on editMaterialButton1 pressed do(
                                        overwriteToIniFile materialGuesserIni "Material Guesser" "Last Edited Slot" slotNumberFromSpinnerAsString

                                        materialGuesserAddMaterialToSlot()
                                    )

                                    on editTagsButton1 pressed do(
                                        overwriteToIniFile materialGuesserIni "Material Guesser" "Last Edited Slot" slotNumberFromSpinnerAsString

                                        materialGuesserAddTagsToMaterial()
                                    )
                            )

                    -- Create the dialogs

                        createdialog materialGuesserUIRollout 800 800

                        AddSubRollout materialGuesserUIRollout.allSlotsSubRollout allSlotsRollout
                        materialGuesserUIRollout.allSlotsSubRollout.height = 450
                )

            -- Guess materials
                 fn guessMaterials = (
                    -- Variables

                        local tagsArray = materialGuesserGetTagsArray()
                        local materialNamesArray = materialGuesserGetMaterialNamesArray()

                        local materialGuesserLibraryPreliminary = getDir #scripts + "\\CallisScripts\\Material Libraries\\Material Guesser.mat"
                        local materialGuesserLibrary = materialGuesserLibraryPreliminary

                        local tagsArrayArraySplit
                        local tagsArrayArrayArraySplit

                        local plusArray
                        local minusArray

                        local materialApplied = false

                        local matchesValues

                        local currentMaterial

                    loadMaterialLibrary materialGuesserLibrary

                    -- Loop

                        for currentObject in selection do(
                            -- Variables

                                materialApplied = false

                            for o = 1 to tagsArray.count do(
                                -- Variables

                                    tagsArraysArray = tagsArray[o]

                                    for myMaterial in currentMaterialLibrary do(
                                        if myMaterial.name == materialNamesArray[o] then(
                                            currentMaterial = myMaterial
                                        )
                                    )

                                    if materialApplied == false and currentMaterial != undefined then(
                                        -- Variables

                                            tagsArraysArraySplit = filterString tagsArraysArray "/"

                                        for tagsArrayArrayArray in tagsArraysArraySplit do(
                                            if materialApplied == false then(
                                                -- Variables

                                                    tagsArrayArrayArraySplitPreliminary = substituteString tagsArrayArrayArray ", " ","
                                                    tagsArrayArrayArraySplit = filterString tagsArrayArrayArraySplitPreliminary ","

                                                    plusArray = #()
                                                    minusArray = #()

                                                    materialApplied = false

                                                -- Define plus and minus array variables

                                                    for a in tagsArrayArrayArraySplit do(
                                                        if matchPattern a pattern:"-*" == true then(
                                                            append minusArray a
                                                        )else(
                                                            append plusArray a
                                                        )
                                                    )

                                                -- Determine if the material should be applied

                                                    -- Variables

                                                        matchesValues = true

                                                    -- Compare the plus and minus array values with the object name

                                                        if plusArray.count > 0 then(
                                                            for a in plusArray do(
                                                                if not matchPattern currentObject.name pattern:("*" + a + "*") then(
                                                                    matchesValues = false
                                                                )
                                                            )
                                                        )

                                                        if matchesValues == true and minusArray.count > 0 then(
                                                            for aPreliminary2 in minusArray do(
                                                                -- Variables

                                                                    aPreliminary = filterString aPreliminary2 "-"
                                                                    a = aPreliminary[1]

                                                                if matchPattern currentObject.name pattern:("*" + a + "*") then(
                                                                    matchesValues = false
                                                                )
                                                            )
                                                        )

                                                -- Apply the material if relevant

                                                    if matchesValues == true then(
                                                        if currentMaterial != undefined then(
                                                            currentObject.material = currentMaterial

                                                            materialApplied = true
                                                        )
                                                    )
                                            )
                                        )
                                    )
                            )
                        )

                    -- Update viewport

                        redrawViews()
                )
        */

        -- Move cameras, lights etc. into correct locations

            fn moveCamerasLightsEtcIntoCorrectLocations = (
                -- Variables etc.

                    local camerasLayer = layermanager.getLayerFromName "Cameras"
                    local sunLayer = layermanager.getLayerFromName "Sun"
                    local skyLayer = layermanager.getLayerFromName "Sky"
                    local lightsLayer = layermanager.getLayerFromName "Lights"
                    local selectedCamerasTarget
                    local selectedSunsTarget

                for obj in objects do(
                    if superclassof obj == camera then(
                        try(
                            camerasLayer.addNode obj

                            lastTargetedObjectCreated = obj.name
                        )catch()
                    )

                    if classof obj == VRaySun then(
                        try(
                            sunLayer.addNode obj

                            lastTargetedObjectCreated = obj.name
                        )catch()
                    )

                    if classof obj == Targetobject then(
                        try(
                            if matchPattern (lastTargetedObjectCreated) pattern:"*amera*" == true then(
                                camerasLayer.addNode obj
                            )

                            if matchPattern (lastTargetedObjectCreated) pattern:"*Sun*" == true then(
                                sunLayer.addNode obj
                            )
                        )catch()

                        lastTargetedObjectCreated = "undefined"
                    )

                    if classof obj == VRayLight and obj.type == 1 then(
                        try(
                            skyLayer.addNode obj
                        )catch()
                    )

                    if classof obj == VRayLight and obj.type == 0 then(
                        try(
                            lightsLayer.addNode obj
                        )catch()
                    )
                )
            )

        /*
        -- Set metadata

            fn callisScriptsSetMetadataFunction = (
                rollout setMetadataRollout "Set Metadata"(
                    -- Variables

                        -- Frame names

                            local frameNamesStringPreliminary = $'Frame Names Dummy'.layer.name
                            local frameNamesString = substituteString frameNamesStringPreliminary "Frame Names:" ","
                            local frameNamesSplitArray = filterString frameNamesString ","

                            local frameNamesLayer = layerManager.getLayerFromName frameNamesStringPreliminary

                            local frame1NameString = substituteString frameNamesSplitArray[1] " 1 " ""
                            local frame2NameString = substituteString frameNamesSplitArray[2] " 2 " ""
                            local frame3NameString = substituteString frameNamesSplitArray[3] " 3 " ""
                            local frame4NameString = substituteString frameNamesSplitArray[4] " 4 " ""
                            local frame5NameString = substituteString frameNamesSplitArray[5] " 5 " ""
                            local frame6NameString = substituteString frameNamesSplitArray[6] " 6 " ""
                            local frame7NameString = substituteString frameNamesSplitArray[7] " 7 " ""
                            local frame8NameString = substituteString frameNamesSplitArray[8] " 8 " ""
                            local frame9NameString = substituteString frameNamesSplitArray[9] " 9 " ""
                            local frame10NameString = substituteString frameNamesSplitArray[10] " 10 " ""

                        -- Frame sizes

                            local frameSizesStringPreliminary = $'Frame Sizes Dummy'.layer.name
                            local frameSizesString = substituteString frameSizesStringPreliminary "Frame Sizes:" ","
                            local frameSizesSplitArray = filterString frameSizesString ","

                            local frameSizesLayer = layerManager.getLayerFromName frameSizesStringPreliminary

                            local frame1Sizestring = substituteString frameSizesSplitArray[1] " 1. " ""
                            local frame2Sizestring = substituteString frameSizesSplitArray[2] " 2. " ""
                            local frame3Sizestring = substituteString frameSizesSplitArray[3] " 3. " ""
                            local frame4Sizestring = substituteString frameSizesSplitArray[4] " 4. " ""
                            local frame5Sizestring = substituteString frameSizesSplitArray[5] " 5. " ""
                            local frame6Sizestring = substituteString frameSizesSplitArray[6] " 6. " ""
                            local frame7Sizestring = substituteString frameSizesSplitArray[7] " 7. " ""
                            local frame8Sizestring = substituteString frameSizesSplitArray[8] " 8. " ""
                            local frame9Sizestring = substituteString frameSizesSplitArray[9] " 9. " ""
                            local frame10Sizestring = substituteString frameSizesSplitArray[10] " 10. " ""

                        -- Output Path

                            local outputPathStringPreliminary = $'Output Path Dummy'.layer.name
                            local outputPathString = substituteString outputPathStringPreliminary "Output Path: " ""

                            local outputPathLayer = layerManager.getLayerFromName outputPathStringPreliminary

                        -- Project Folder

                            local projectFolderPathStringPreliminary = $'Project Folder Path Dummy'.layer.name
                            local projectFolderPathString = substituteString projectFolderPathStringPreliminary "Project Folder Path: " ""

                            local projectFolderPathLayer = layerManager.getLayerFromName projectFolderPathStringPreliminary

                        -- Separate Glass

                            local separateGlassStringPreliminary = $'Separate Glass Dummy'.layer.name
                            local separateGlassString = substituteString separateGlassStringPreliminary "Separate Glass: " ""

                            local separateGlassLayer = layerManager.getLayerFromName separateGlassStringPreliminary

                    -- Components

                        -- Frame names

                            group "Frame Names"(
                                editText frameNames1EditText "Frame 1 Name:" text:frame1NameString

                                editText frameNames2EditText "Frame 2 Name:" text:frame2NameString

                                editText frameNames3EditText "Frame 3 Name:" text:frame3NameString

                                editText frameNames4EditText "Frame 4 Name:" text:frame4NameString

                                editText frameNames5EditText "Frame 5 Name:" text:frame5NameString

                                editText frameNames6EditText "Frame 6 Name:" text:frame6NameString

                                editText frameNames7EditText "Frame 7 Name:" text:frame7NameString

                                editText frameNames8EditText "Frame 8 Name:" text:frame8NameString

                                editText frameNames9EditText "Frame 9 Name:" text:frame9NameString

                                editText frameNames10EditText "Frame 10 Name:" text:frame10NameString
                            )

                        -- Frame sizes

                            group "Frame Sizes"(
                                editText frameSizes1EditText "Frame 1 Size:" text:frame1SizeString

                                editText frameSizes2EditText "Frame 2 Size:" text:frame2SizeString

                                editText frameSizes3EditText "Frame 3 Size:" text:frame3SizeString

                                editText frameSizes4EditText "Frame 4 Size:" text:frame4SizeString

                                editText frameSizes5EditText "Frame 5 Size:" text:frame5SizeString

                                editText frameSizes6EditText "Frame 6 Size:" text:frame6SizeString

                                editText frameSizes7EditText "Frame 7 Size:" text:frame7SizeString

                                editText frameSizes8EditText "Frame 8 Size:" text:frame8SizeString

                                editText frameSizes9EditText "Frame 9 Size:" text:frame9SizeString

                                editText frameSizes10EditText "Frame 10 Size:" text:frame10SizeString
                            )

                        editText outputPathEditText "Output Path:" text:outputPathString

                        editText projectFolderPathEditText "Project Folder Path:" text:projectFolderPathString

                        editText separateGlasseditText "Separate Glass" text:separateGlassString

                    -- Actions

                        -- Frame names

                            on frameNames1EditText entered txt do(
                                frameNamesLayer.setName (substituteString frameNamesStringPreliminary ("1 " + frame1NameString + ", 2 ") ("1 " + txt + ", 2 "))

                                frameNamesStringPreliminary = $'Frame Names Dummy'.layer.name
                                frameNamesString = substituteString frameNamesStringPreliminary "Frame Names:" ","
                                frameNamesSplitArray = filterString frameNamesString ","

                                frameNamesLayer = layerManager.getLayerFromName frameNamesStringPreliminary

                                frame1NameString = substituteString frameNamesSplitArray[1] "1 " ""
                            )

                            on frameNames2EditText entered txt do(
                                frameNamesLayer.setName (substituteString frameNamesStringPreliminary ("2 " + frame2NameString + ", 3 ") ("2 " + txt + ", 3 "))
                            )

                            on frameNames3EditText entered txt do(
                                frameNamesLayer.setName (substituteString frameNamesStringPreliminary ("3 " + frame3NameString + ", 4 ") ("3 " + txt + ", 4 "))
                            )

                            on frameNames4EditText entered txt do(
                                frameNamesLayer.setName (substituteString frameNamesStringPreliminary ("4 " + frame4NameString + ", 5 ") ("4 " + txt + ", 5 "))
                            )

                            on frameNames5EditText entered txt do(
                                frameNamesLayer.setName (substituteString frameNamesStringPreliminary ("5 " + frame5NameString + ", 6 ") ("5 " + txt + ", 6 "))
                            )

                            on frameNames6EditText entered txt do(
                                frameNamesLayer.setName (substituteString frameNamesStringPreliminary ("6 " + frame6NameString + ", 7 ") ("6 " + txt + ", 7 "))
                            )

                            on frameNames7EditText entered txt do(
                                frameNamesLayer.setName (substituteString frameNamesStringPreliminary ("7 " + frame7NameString + ", 8 ") ("7 " + txt + ", 8 "))
                            )

                            on frameNames8EditText entered txt do(
                                frameNamesLayer.setName (substituteString frameNamesStringPreliminary ("8 " + frame8NameString + ", 9 ") ("8 " + txt + ", 9 "))
                            )

                            on frameNames9EditText entered txt do(
                                frameNamesLayer.setName (substituteString frameNamesStringPreliminary ("9 " + frame9NameString + ", 10 ") ("9 " + txt + ", 10 "))
                            )

                            on frameNames10EditText entered txt do(
                                frameNamesLayer.setName (substituteString frameNamesStringPreliminary ("10 " + frame10NameString) ("10 " + txt))
                            )

                        -- Frame sizes

                            on frameSizes1EditText entered txt do(
                                frameSizesLayer.setName (substituteString frameSizesStringPreliminary ("1. " + frame1Sizestring + ", 2. ") ("1. " + txt + ", 2. "))

                                frameSizesStringPreliminary = $'Frame Sizes Dummy'.layer.name
                                frameSizesString = substituteString frameSizesStringPreliminary "Frame Sizes:" ","
                                frameSizesSplitArray = filterString frameSizesString ","

                                frameSizesLayer = layerManager.getLayerFromName frameSizesStringPreliminary

                                frame1Sizestring = substituteString frameSizesSplitArray[1] "1 " ""
                            )

                            on frameSizes2EditText entered txt do(
                                frameSizesLayer.setName (substituteString frameSizesStringPreliminary ("2. " + frame2Sizestring + ", 3. ") ("2. " + txt + ", 3. "))
                            )

                            on frameSizes3EditText entered txt do(
                                frameSizesLayer.setName (substituteString frameSizesStringPreliminary ("3. " + frame3Sizestring + ", 4. ") ("3. " + txt + ", 4. "))
                            )

                            on frameSizes4EditText entered txt do(
                                frameSizesLayer.setName (substituteString frameSizesStringPreliminary ("4. " + frame4Sizestring + ", 5. ") ("4. " + txt + ", 5. "))
                            )

                            on frameSizes5EditText entered txt do(
                                frameSizesLayer.setName (substituteString frameSizesStringPreliminary ("5. " + frame5Sizestring + ", 6. ") ("5. " + txt + ", 6. "))
                            )

                            on frameSizes6EditText entered txt do(
                                frameSizesLayer.setName (substituteString frameSizesStringPreliminary ("6. " + frame6Sizestring + ", 7. ") ("6. " + txt + ", 7. "))
                            )

                            on frameSizes7EditText entered txt do(
                                frameSizesLayer.setName (substituteString frameSizesStringPreliminary ("7. " + frame7Sizestring + ", 8. ") ("7. " + txt + ", 8. "))
                            )

                            on frameSizes8EditText entered txt do(
                                frameSizesLayer.setName (substituteString frameSizesStringPreliminary ("8. " + frame8Sizestring + ", 9. ") ("8. " + txt + ", 9. "))
                            )

                            on frameSizes9EditText entered txt do(
                                frameSizesLayer.setName (substituteString frameSizesStringPreliminary ("9. " + frame9Sizestring + ", 10. ") ("9. " + txt + ", 10. "))
                            )

                            on frameSizes10EditText entered txt do(
                                frameSizesLayer.setName (substituteString frameSizesStringPreliminary ("10. " + frame10Sizestring) ("10. " + txt))
                            )

                        -- Output Path

                            on outputPathEditText entered txt do(
                                outputPathLayer.setName ("Output Path: " + txt)

                                outputPathStringPreliminary = $'Frame Sizes Dummy'.layer.name
                                outputPathString = substituteString outputPathStringPreliminary "Frame Sizes:" ","

                                outputPathLayer = layerManager.getLayerFromName outputPathStringPreliminary
                            )

                            on projectFolderPathEditText entered txt do(
                                projectFolderPathLayer.setName ("Project Folder Path: " + txt)

                                projectFolderPathStringPreliminary = $'Frame Sizes Dummy'.layer.name
                                projectFolderPathString = substituteString projectFolderPathStringPreliminary "Frame Sizes:" ","

                                projectFolderPathLayer = layerManager.getLayerFromName projectFolderPathStringPreliminary
                            )

                            on separateGlassEditText entered txt do(
                                separateGlassLayer.setName ("Separate Glass: " + txt)

                                separateGlassStringPreliminary = $'Frame Sizes Dummy'.layer.name
                                separateGlassString = substituteString separateGlassStringPreliminary "Frame Sizes:" ","

                                separateGlassLayer = layerManager.getLayerFromName separateGlassStringPreliminary
                            )
                )

                createDialog setMetadataRollout 1000 1000
            )
        */

-- Run the script
