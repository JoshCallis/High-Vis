-- Function to move objects to a new layer
fn moveObjectsToLayer objects newLayerName =
(
    for obj in objects do
    (
        if isvalidnode obj do
        (
            layerName = getLayerName obj
            newLayer = getLayerFromName newLayerName

            if newLayer != undefined do
            (
                if layerName != undefined do
                (
                    obj.layer = newLayer
                )
            )
        )
    )
)

-- Function to delete helper objects from a layer
fn deleteHelpersInLayer layerName =
(
    local layer = getLayerFromName layerName

    if layer != undefined do
    (
        for obj in layer do
        (
            if isKindOf obj Helper do
            (
                delete obj
            )
        )
    )
)

-- Get all objects in the specified layers
allOthersLayer = "All Others"
wallsLayer = "Walls"
ceilingsLayer = "Ceilings"
floorsLayer = "Floors"
caseworkLayer = "Casework"
furnitureLayer = "Furniture"

allOthersObjects = for obj in objects where obj.layer.name == allOthersLayer collect obj
wallsObjects = for obj in objects where obj.layer.name == wallsLayer collect obj
ceilingsObjects = for obj in objects where obj.layer.name == ceilingsLayer collect obj
floorsObjects = for obj in objects where obj.layer.name == floorsLayer collect obj
caseworkObjects = for obj in objects where obj.layer.name == caseworkLayer collect obj
furnitureObjects = for obj in objects where obj.layer.name == furnitureLayer collect obj

-- Delete helper objects from the specified layers
deleteHelpersInLayer allOthersLayer
deleteHelpersInLayer wallsLayer
deleteHelpersInLayer ceilingsLayer
deleteHelpersInLayer floorsLayer
deleteHelpersInLayer caseworkLayer
deleteHelpersInLayer furnitureLayer

-- Move objects with specific names to the 'Glass (Non-Separate) (L)' layer
glassLayer = "Glass (Non-Separate) (L)"
glassObjects = for obj in allOthersObjects where matchPattern (obj.name as string) pattern:"*glass*" or matchPattern (obj.name as string) pattern:"*glazing*" or matchPattern (obj.name as string) pattern:"*window*" collect obj

moveObjectsToLayer glassObjects glassLayer

-- Move objects from 'All Others' layer to 'Miscellaneous (Building) (L)' layer
miscLayer = "Miscellaneous (Building) (L)"
moveObjectsToLayer allOthersObjects miscLayer

-- Move objects from 'Ceilings' layer to 'Ceilings (B)' layer
ceilingsBLayer = "Ceilings (B)"
moveObjectsToLayer ceilingsObjects ceilingsBLayer

-- Move objects from 'Floors' layer to 'Floors (B)' layer
floorsBLayer = "Floors (B)"
moveObjectsToLayer floorsObjects floorsBLayer

-- Move objects from 'Walls' layer to 'External Walls (B)' layer
externalWallsLayer = "External Walls (B)"
moveObjectsToLayer wallsObjects externalWallsLayer

-- Move objects from 'Casework' layer to 'Joinery (B)' layer
joineryLayer = "Joinery (B)"
moveObjectsToLayer caseworkObjects joineryLayer

-- Move objects from 'Furniture' layer to 'Furniture (B)' layer
furnitureBLayer = "Furniture (B)"
moveObjectsToLayer furnitureObjects furnitureBLayer
