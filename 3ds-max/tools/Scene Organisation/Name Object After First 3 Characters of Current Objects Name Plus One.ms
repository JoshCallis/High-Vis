tool nameObjectCurrentObjectsNamePlusOneTool(
    -- Variables

        local initialObject
        local objectsUnderCursor

    on start do(
        if selection.count != 1 then(
            messageBox "Please select one base object"

            #stop
        )

        initialObject = $
    )

    on mousePoint clickno do(
        -- Variables

            try(
                local var1 = (((subString $.name 1 3) as integer) + 1)

                -- var2

                    if var1 < 1000 then(
                        local var2 = (var1 as string)
                    )

                    if var1 < 100 then(
                        local var2 = ("0" + (var1 as string))
                    )

                    if var1 < 10 then(
                        local var2 = ("00" + (var1 as string))
                    )
            )catch(
                messageBox "Sorry, object's name must begin with a 3-digit number. Please correct and try again."
            )

        try(
            objectsUnderCursor = (boxPickNode (box2 (mouse.pos - [2,2]) (mouse.pos + [2,2])) crossing:true)

            if objectsUnderCursor[1] != initialObject then(
                select objectsUnderCursor[1]

                print var2

                objectsUnderCursor[1].name = (var2 + " " + objectsUnderCursor[1].name)

                -- Resetting variables

                    initialObject = $

                    try(
                        var1 = (((subString $.name 1 3) as integer) + 1)

                        -- var2

                            if var1 < 1000 then(
                                var2 = (var1 as string)
                            )

                            if var1 < 100 then(
                                var2 = ("0" + (var1 as string))
                            )

                            if var1 < 10 then(
                                var2 = ("00" + (var1 as string))
                            )
                    )catch(
                        messageBox "Sorry, object's name must begin with a 3-digit number. Please correct and try again."
                    )
            )
        )catch(
            select initialObject
        )
    )

    on mouseAbort clickno do(
    )
)

messageBox ("Note: Initial object's name must begin with a 3-digit number (e.g. 007)")

startTool nameObjectCurrentObjectsNamePlusOneTool
