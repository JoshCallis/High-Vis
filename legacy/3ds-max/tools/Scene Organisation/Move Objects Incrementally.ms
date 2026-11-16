    -- Move

        fn callisScriptsMoveIncrementally distanceToMOve = (
            -- Variables

                mySelection = getCurrentSelection()

            for myNum = 1 to mySelection.count do(
                (selection[myNum]).pos = [-(distanceToMOve),0,0]

                move selection[myNum] [(myNum*distanceToMOve),0,0]
            )
        )

        rollout callisScriptsMoveObjectsIncrementally("Move Objects Incrementally")(
            -- Variables

                local distanceText

            editText distance "Desired distance between objects (in scene units):"

            button moveButton "Move"

            on distance entered txt do(
                if txt != "" then(
                    distanceText = txt as integer
                )
            )

            on moveButton pressed do(
                if distanceText != undefined then(
                    try(
                        callisScriptsMoveIncrementally distanceText
                    )catch(
                        messageBox ("Error")
                    )
                )
            )
        )

        createDialog callisScriptsMoveObjectsIncrementally 320 100
