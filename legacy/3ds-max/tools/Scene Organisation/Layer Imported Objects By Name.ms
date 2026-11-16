for i in selection do(
    -- Building

        -- Balustrades

            if matchPattern i.name pattern: "*balust*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Balustrades (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*handrail*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Balustrades (Import) —").addnode i
            )

        -- Ceilings

            if matchPattern i.name pattern: "*ceiling*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Ceilings (Import) —").addnode i
            )

        -- Cladding

            if matchPattern i.name pattern: "*cladding*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Cladding (Import) —").addnode i
            )

        -- Floors

            if matchPattern i.name pattern: "*floor*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Floors (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*stair*" and not matchPattern i.name pattern: "*glass*" and not matchPattern i.name pattern: "*balust*" and not matchPattern i.name pattern: "*rail*" then(
                (layerManager.getLayerFromName "Floors (Import) —").addnode i
            )

        -- Glass

            if matchPattern i.name pattern: "*glas*" then(
                (layerManager.getLayerFromName "Glass (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*glaz*" then(
                (layerManager.getLayerFromName "Glass (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*windo*" then(
                (layerManager.getLayerFromName "Glass (Import) —").addnode i
            )

        -- Joinery

            if matchPattern i.name pattern: "*joinery*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Joinery (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*cabinet*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Joinery (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*credenza*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Joinery (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*island*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Joinery (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*shelv*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Joinery (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*shelf*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Joinery (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*cupboard*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Joinery (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*drawer*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Joinery (Import) —").addnode i
            )

        -- Mechanics

            if matchPattern i.name pattern: "*duct*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Mechanics (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*hvac*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Mechanics (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*exhaust*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Mechanics (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*sprinkler*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Mechanics (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*lift*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Mechanics (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*elevator*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Mechanics (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*escalator*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Mechanics (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*sensor*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Mechanics (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*piping*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Mechanics (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*pipe*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Mechanics (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*plumb*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Mechanics (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*a/c*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Mechanics (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*wc*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Mechanics (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*w/c*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Mechanics (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*toilet*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Mechanics (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*sink*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Mechanics (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*gutter*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Mechanics (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*shower*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Mechanics (Import) —").addnode i
            )

        -- Mullions

            if matchPattern i.name pattern: "*mullion*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Mullions (Import) —").addnode i
            )

        -- Rooves

            if matchPattern i.name pattern: "*roof*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Rooves (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*roov*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Rooves (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*parapet*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Rooves (Import) —").addnode i
            )

        -- Structure

            if matchPattern i.name pattern: "*struc*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Structure (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*beam*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Structure (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*column*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Structure (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*clmn*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Structure (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*rafter*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Structure (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*purlin*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Structure (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*bearer*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Structure (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*joist*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Structure (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*truss*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Structure (Import) —").addnode i
            )

        -- Walls

            if matchPattern i.name pattern: "*wall*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "External Walls (Import) —").addnode i
            )

            if matchPattern i.name pattern: "core*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Internal Walls (Import) —").addnode i
            )

            if matchPattern i.name pattern: "cavity*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Internal Walls (Import) —").addnode i
            )

    -- Context

        -- Roads

            if matchPattern i.name pattern: "*road*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Roads (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*asphalt*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Roads (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*tarseal*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Roads (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*tarmac*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Roads (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*highway*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Roads (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*freeway*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Roads (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*motorway*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Roads (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*underpass*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Roads (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*overpass*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Roads (Import) —").addnode i
            )

        -- Surrounding Buildings

            if matchPattern i.name pattern: "*context*" and not matchPattern i.name pattern: "*road*" and not matchPattern i.name pattern: "*terrain*" then(
                (layerManager.getLayerFromName "Surrounding Buildings (Import) —").addnode i
            )

        -- Terrain

            if matchPattern i.name pattern: "*terrain*" and not matchPattern i.name pattern: "*road*" and not matchPattern i.name pattern: "*buil*" then(
                (layerManager.getLayerFromName "Terrain (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*land*" and not matchPattern i.name pattern: "*road*" and not matchPattern i.name pattern: "*buil*" then(
                (layerManager.getLayerFromName "Terrain (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*topog*" and not matchPattern i.name pattern: "*road*" and not matchPattern i.name pattern: "*buil*" then(
                (layerManager.getLayerFromName "Terrain (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*topol*" and not matchPattern i.name pattern: "*road*" and not matchPattern i.name pattern: "*buil*" then(
                (layerManager.getLayerFromName "Terrain (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*survey*" and not matchPattern i.name pattern: "*road*" and not matchPattern i.name pattern: "*buil*" then(
                (layerManager.getLayerFromName "Terrain (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*grass*" and matchPattern i.name pattern: "*context*" then(
                (layerManager.getLayerFromName "Terrain (Import) —").addnode i
            )

    -- Landscaping

        -- Miscellaneous

            if matchPattern i.name pattern: "*bench*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Miscellaneous (Import, Landscaping) —").addnode i
            )

            if matchPattern i.name pattern: "*landsc*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Miscellaneous (Import, Landscaping) —").addnode i
            )

            if matchPattern i.name pattern: "*rock*" and not matchPattern i.name pattern: "*glass*" then(
                (layerManager.getLayerFromName "Miscellaneous (Import, Landscaping) —").addnode i
            )

        -- Terrain

            if matchPattern i.name pattern: "*grass*" then(
                (layerManager.getLayerFromName "Terrain (Import, Landscaping) —").addnode i
            )

            if matchPattern i.name pattern: "*soil*" then(
                (layerManager.getLayerFromName "Terrain (Import, Landscaping) —").addnode i
            )

            if matchPattern i.name pattern: "*grass*" then(
                (layerManager.getLayerFromName "Terrain (Import, Landscaping) —").addnode i
            )

            if matchPattern i.name pattern: "*grass*" then(
                (layerManager.getLayerFromName "Terrain (Import, Landscaping) —").addnode i
            )

            if matchPattern i.name pattern: "*grass*" then(
                (layerManager.getLayerFromName "Terrain (Import, Landscaping) —").addnode i
            )

            if matchPattern i.name pattern: "*grass*" then(
                (layerManager.getLayerFromName "Terrain (Import, Landscaping) —").addnode i
            )

            if matchPattern i.name pattern: "*planter*" then(
                (layerManager.getLayerFromName "Terrain (Import, Landscaping) —").addnode i
            )

            if matchPattern i.name pattern: "*planting*" then(
                (layerManager.getLayerFromName "Terrain (Import, Landscaping) —").addnode i
            )

            if matchPattern i.name pattern: "*flo;\wer*" then(
                (layerManager.getLayerFromName "Terrain (Import, Landscaping) —").addnode i
            )

    -- Population

        -- Electronics

            if matchPattern i.name pattern: "*phone*" then(
                (layerManager.getLayerFromName "Electronics (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*intercom*" then(
                (layerManager.getLayerFromName "Electronics (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*computer*" then(
                (layerManager.getLayerFromName "Electronics (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*laptop*" then(
                (layerManager.getLayerFromName "Electronics (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*monitor*" then(
                (layerManager.getLayerFromName "Electronics (Import) —").addnode i
            )

        -- Furniture

            if matchPattern i.name pattern: "*chair*" then(
                (layerManager.getLayerFromName "Furniture (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*couch*" then(
                (layerManager.getLayerFromName "Furniture (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*sofa*" then(
                (layerManager.getLayerFromName "Furniture (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*stool*" then(
                (layerManager.getLayerFromName "Furniture (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*table*" then(
                (layerManager.getLayerFromName "Furniture (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*ottoman*" then(
                (layerManager.getLayerFromName "Furniture (Import) —").addnode i
            )

            if matchPattern i.name pattern: "bed*" then(
                (layerManager.getLayerFromName "Furniture (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*seat*" then(
                (layerManager.getLayerFromName "Furniture (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*desk*" then(
                (layerManager.getLayerFromName "Furniture (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*rug*" then(
                (layerManager.getLayerFromName "Furniture (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*lamp*" then(
                (layerManager.getLayerFromName "Furniture (Import) —").addnode i
            )

        -- Light Fittings

            if matchPattern i.name pattern: "*light*" then(
                (layerManager.getLayerFromName "Light Fittings (Import) —").addnode i
            )

        -- Miscellaneous

            if matchPattern i.name pattern: "*magazine*" then(
                (layerManager.getLayerFromName "Miscellaneous (Import, Population) —").addnode i
            )

        -- Vegitation

            if matchPattern i.name pattern: "*tree*" then(
                (layerManager.getLayerFromName "Vegetation (Import) —").addnode i
            )

            if matchPattern i.name pattern: "*plants*" then(
                (layerManager.getLayerFromName "Vegetation (Import) —").addnode i
            )
)
