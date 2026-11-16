-- Render specified frames to corresponding folders

    MacroScript callisScriptsRender category:"Callis Scripts" tooltip:"Render" Icon:#("Render",1)

    (
        include "$scripts/CallisScripts/scripts/All Scripts.ms"

        on execute do callisScriptsRender()
    )

-- Start interactive render

    MacroScript callisScriptsStartInteractiveRender category:"Callis Scripts" tooltip:"Start interactive render" Icon:#("Start interactive render",1)

    (
        include "$scripts/CallisScripts/scripts/All Scripts.ms"

        callisScriptsStartInteractiveRender()
    )

-- Stop interactive render

    MacroScript callisScriptsStopInteractiveRender category:"Callis Scripts" tooltip:"Stop interactive render" Icon:#("Stop interactive render",1)

    (
        vrayStopIPR()
    )

-- Toggle autokey and camera lock

    MacroScript toggleAutokeyAndCameraLock category:"Callis Scripts" tooltip:"Toggle autokey and camera lock" Icon:#("Toggle autokey and camera lock",1)

    (
        include "$scripts/CallisScripts/scripts/All Scripts.ms"

        on execute do toggleAutokeyAndCameraLock()
    )

-- Consolidate Cameras

    MacroScript consolidateCameras category:"Callis Scripts" tooltip:"Consolidate Cameras" Icon:#("Consolidate Cameras",1)

    (
        include "$scripts/CallisScripts/scripts/All Scripts.ms"

        on execute do consolidateCameras()
    )

-- Change Frame

    -- Frame 1

        MacroScript frame1 category:"Callis Scripts" tooltip:"Frame 1" Icon:#("Frame 1",1)

        (
            include "$scripts/CallisScripts/scripts/All Scripts.ms"

            on execute do(
                changeFrameNumber 1
            )
        )

    -- Frame 2

        MacroScript frame2 category:"Callis Scripts" tooltip:"Frame 2" Icon:#("Frame 2",2)

        (
            include "$scripts/CallisScripts/scripts/All Scripts.ms"

            on execute do(
                changeFrameNumber 2
            )
        )

    -- Frame 3

        MacroScript frame3 category:"Callis Scripts" tooltip:"Frame 3" Icon:#("Frame 3",3)

        (
            include "$scripts/CallisScripts/scripts/All Scripts.ms"

            on execute do(
                changeFrameNumber 3
            )
        )

    -- Frame 4

        MacroScript frame4 category:"Callis Scripts" tooltip:"Frame 4" Icon:#("Frame 4",4)

        (
            include "$scripts/CallisScripts/scripts/All Scripts.ms"

            on execute do(
                changeFrameNumber 4
            )
        )

    -- Frame 5

        MacroScript frame5 category:"Callis Scripts" tooltip:"Frame 5" Icon:#("Frame 5",5)

        (
            include "$scripts/CallisScripts/scripts/All Scripts.ms"

            on execute do(
                changeFrameNumber 5
            )
        )

    -- Frame 6

        MacroScript frame6 category:"Callis Scripts" tooltip:"Frame 6" Icon:#("Frame 6",6)

        (
            include "$scripts/CallisScripts/scripts/All Scripts.ms"

            on execute do(
                changeFrameNumber 6
            )
        )

    -- Frame 7

        MacroScript frame7 category:"Callis Scripts" tooltip:"Frame 7" Icon:#("Frame 7",7)

        (
            include "$scripts/CallisScripts/scripts/All Scripts.ms"

            on execute do(
                changeFrameNumber 7
            )
        )

    -- Frame 8

        MacroScript frame8 category:"Callis Scripts" tooltip:"Frame 8" Icon:#("Frame 8",8)

        (
            include "$scripts/CallisScripts/scripts/All Scripts.ms"

            on execute do(
                changeFrameNumber 8
            )
        )

    -- Frame 9

        MacroScript frame9 category:"Callis Scripts" tooltip:"Frame 9" Icon:#("Frame 9",9)

        (
            include "$scripts/CallisScripts/scripts/All Scripts.ms"

            on execute do(
                changeFrameNumber 9
            )
        )

-- Create layer structure

    MacroScript createLayerStructure category:"Callis Scripts" tooltip:"Create Layer Structure" Icon:#("Create Layer Structure",1)

    (
        include "$scripts/CallisScripts/scripts/All Scripts.ms"

        on execute do createLayerStructure()
    )

/*
-- Material Guesser

    -- UI

        MacroScript materialGuesserUI category:"Callis Scripts" tooltip:"Material Guesser UI" Icon:#("Material Guesser UI",1)

        (
            include "$scripts/CallisScripts/scripts/All Scripts.ms"

            on execute do materialGuesserUI()
        )

    -- Guess materials

        MacroScript guessMaterials category:"Callis Scripts" tooltip:"Guess Materials" Icon:#("guess Materials",1)

        (
            include "$scripts/CallisScripts/scripts/All Scripts.ms"

            on execute do guessMaterials()
        )
*/
