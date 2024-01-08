try(
    for a in selection do(
        if classOf a == VRayProxy then(
            a.display = 4
        )
    )
)catch()
