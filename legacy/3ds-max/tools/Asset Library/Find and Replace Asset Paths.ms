
fn getFilesRecursive root pattern = (
		dir_array = GetDirectories (root+"/*")

		for d in dir_array do(
            join dir_array (GetDirectories (d+"/*"))
        )

        append dir_array (root + "/")

		theFileList = #()

		for f in dir_array do(
        join theFileList (getFiles (f + pattern))
    )

		theFileList
)

rollout rol_AssetRepather "Asset Repather"(
    -- Components

        button btn_RootFolder "Root Folder..." offset:[-15,-3] across:2 align:#left
        editText edt_RootFolder "" width:1100 align:#left offset:[-510,-3]
        button btn_Collect "Collect/Refresh Asset Paths" width:150 height:20 offset:[-15,-3]  Align:#left
        multilistbox mlb_AssetList "Unique Asset Paths:" height:50

        editText edt_Find "Find in path: "
        editText edt_Replace "Replace with:"

        button btn_Go "RePath!" width:50 height:50

    -- Actions

        on btn_RootFolder pressed do(
            local rootFolder = getSavePath caption:"Select Root Folder to process:"
            if rootFolder != undefined do edt_RootFolder.text = rootFolder
        )

        on btn_Collect pressed do(
            clearListener()
            actionMan.executeAction 0 "40472"  -- MAX Script: MAXScript Listener

            local startTime = timeStamp()

            local theReport = createfile ((getDir #temp) + "\\MaxMetaDataReport.dat")

            local theRootPath = edt_RootFolder.text

            global theRepathFileList = getFilesRecursive theRootPath "*.max"

            local theAssetCount = 0

            local theFileCount = 0

            print theRepathFileList

            global theUniquePathArray = #()

            for f in theRepathFileList do
            (
                theFileCount += 1
                metaArray = getMAXFileAssetMetadata f
                if metaArray != undefined do
                (
                    for x = 1 to metaArray.count do
                    (
                        theAssetCount += 1
                        theFilename = metaArray[x].filename
                        thePath = getFilenamePath theFileName
                        appendIfUnique theUniquePathArray thePath
                    )
                )
            )

            sort theUniquePathArray
            print theUniquePathArray

            for p in theUniquePathArray do
            (
                format "%\n" p to:theReport
            )

            endTime = timeStamp()

           mlb_AssetList.items = theUniquePathArray

            format "\n\nProcessed % Assets in % files in % seconds\n" (theAssetCount as string) (theFileCount as string) (((endTime - startTime) / 1000.0)as string) to:theReport

            close theReport

            format "\n\nProcessed % Assets in % files in % seconds\n" (theAssetCount as string) (theFileCount as string) (((endTime - startTime) / 1000.0)as string)
        )

        on mlb_AssetList doubleClicked arg do(
            if arg != undefined do edt_Find.text = mlb_AssetList.items[arg]
        )

        on btn_Go pressed do(
            actionMan.executeAction 0 "40472"
            local theAssetCount = 0
            local theFileCount = 0
                edt_Find.text = toLower edt_Find.text
                edt_Replace.text = toLower edt_Replace.text

                format "Looking for String: %\n" edt_Find.text
                format "Replacing with: %\n" edt_Replace.text

            for theMaxFile in theRepathFileList do(
                theFileCount  += 1

                metaArray = getMAXFileAssetMetadata theMaxFile

                if metaArray != undefined then(
                    for x = 1 to metaArray.count do(
                        fName = toLower (metaArray[x].filename)
                        theAssetCount += 1

                        if matchpattern fName pattern:(edt_Find.text +"*") then(
                            newFName = substituteString fName edt_Find.text edt_Replace.text
                            metaArray[x].filename = newFName
                        )
                    )

                    setMAXFileAssetMetadata theMaxFile metaArray
                )
            )
        )
)

CreateDialog rol_AssetRepather 1200 833
