# 3ds Max scripts

MAXScript tools for scene setup, modelling, rendering and asset-library prep. They were written against 3ds Max 2018–2024 with V-Ray.

← [Back to overview](../README.md)

---

## Install

| Repo folder | Copy to |
|---|---|
| `usermacros/*.mcr` | `%LOCALAPPDATA%\Autodesk\3dsMax\<version>\ENU\usermacros\` |
| `scripts/Startup/Callis Scripts/` | `<3ds Max>\scripts\Startup\Callis Scripts\` |
| `scripts/CallisScripts/` | `<3ds Max>\scripts\CallisScripts\` |
| `tools/` | anywhere; run with **Scripting ▸ Run Script** |

Restart 3ds Max. The macros then appear under **Customize ▸ Hotkey Editor** in the categories *Callis Scripts*, *Callis Scripts Extras* and *BetterTools*, ready to bind to keys or toolbar buttons.

---

## Render pipeline and shots: `Callis Scripts.mcr` + `All Scripts.ms`

A scene is organised around **shots**. Each frame of the timeline (1–9) is one shot with its own camera, sun and sky. Shot names and output sizes are stored on the scene itself, so they travel with the `.max` file.

| Macro | What it does |
|---|---|
| **Render** | Opens the render dialog. Pick which shots to render, the resolution (low / high), bit depth (8 / 16), and whether to overwrite. Each shot is rendered with V-Ray into its own folder, with its render elements and multimattes. Optionally, Photoshop then runs automatically: initial organisation, re-render into the same or a new location, or High Resify (see [Photoshop](../photoshop/README.md)). Glass can be rendered as a separate pass. |
| **Start / Stop interactive render** | Starts V-Ray IPR on the active shot's camera, or stops it. |
| **Frame 1 … Frame 9** | Jumps to that shot: sets the time slider, the camera and the output size together. |
| **Update Frame Sizes** | Small dialog for editing each shot's output width and height. |
| **Toggle autokey and camera lock** | Locks or unlocks every camera's transforms, so a shot can't be nudged by accident. |
| **Create Layer Structure** | Removes empty layers and builds the standard layer tree: Building (walls, floors, ceilings, cladding, glazing, joinery…), Landscaping, Context, Entourage, Lighting, Cameras, Sun/Sky, plus *Glass (Separate)* for the glass pass and metadata layers for shot names and sizes. |
| **Material Guesser UI / Guess Materials** | A material library with tags. **Guess Materials** assigns materials to imported geometry by matching object names against the tags, e.g. anything named `*glaz*` gets the glass material. |

## Everyday macros: `Callis Scripts Extras.mcr`

| Macro | What it does |
|---|---|
| **Select active frame's camera / sun / sky** | Selects the current shot's camera, sun or sky. |
| **Cycle Viewport Layouts** | Cycles between a single shot-camera view with safe frames, a two-up view, and the modelling view. |
| **Toggle Camera/Perspective View** | Switches the viewport between the shot camera and a free perspective. |
| **Move cameras, lights etc. into correct locations** | Files cameras, suns, skies and lights (and their targets) onto their layers. |
| **Set Project Folder** | Creates the job's folder structure (scenes, renders, Photoshop, reference, uploads…) and sets it as the 3ds Max project. |
| **Set Metadata** | Edits shot names, which are stored on the scene. |
| **Collect Assets To Project Folder** | Gathers every bitmap, proxy and IES file the scene uses into the project folder and repaths them there. |
| **Attach Objects / Target Weld** | One key that attaches the selected objects at object level and target-welds at vertex level. |
| **Move Pivot To Bottom / Detach** | Puts the pivot at the bottom at object level, or detaches the selected sub-objects. |
| **Add Material To Selection / Pick Material From Selection** | Applies the material selected in the Slate editor to the selected objects, or picks the material from the selected object. |
| **Add UVW Map To Selection** | Adds a real-world-sized UVW Map to every selected object. |
| **Boolean difference** | Subtracts the second selection from the first. |
| **Enter Subobject Level 0–5** | Direct sub-object level keys that work across Edit Poly, Editable Poly and Editable Mesh. |
| **Copy / Paste / Paste in Place / Import** | Copies objects between open 3ds Max sessions. **Paste** drops the objects under the cursor and lets you place them with a click; **Paste in Place** keeps their original position. |
| **Rename Selected Object, Collapse Stack, Deselect, Hide Selected, Zoom Selected, Toggle Group Open, Undo** | One-key versions of common commands that behave the same in every mode. |
| **Swift Loop, Select Similar, Toggle Show End Result** | Wrap built-in modelling commands so they can be bound to keys (Select Similar works at both object and sub-object level). |
| **Toggle On Node Added Event Handlers** | Turns the start-up automation below on or off, e.g. while merging large files. |

## BetterMove: `BetterMove.mcr`

A precise, SketchUp-style move tool for 3ds Max, which only has drag-to-move built in.

- **Two clicks:** pick a base point, then the destination. No dragging.
- Snaps to vertices, edges and faces, and **infers** along the X/Y/Z axes and from earlier reference points, with guide lines drawn in the viewport.
- **Shift** locks to the nearest axis. Type a value to move an exact distance.
- Works on objects and on **sub-objects** in Editable Poly, Edit Poly and Editable Mesh, using the sub-selection's own pivot.

## Start-up automation: `scripts/Startup/Callis Scripts/`

These run on every launch. `General Event Handling.ms` holds the functions and `General Event Handling Execution.ms` registers them:

- **Default material:** new objects get a neutral default material, shown in the viewport.
- **Default wire colour:** new objects get a consistent wire colour.
- **Auto-layering:** new objects go onto the right layer for their type (cameras, lights, geometry…).
- **Add modifiers on creation** for chosen object types.
- Handlers switch themselves off during bulk operations (merges, batch scripts) so those stay fast.
- `Lock All Cameras.ms` and `Turn on snapping.ms` set those defaults at launch.

---

## Tools

Standalone scripts. Most open a small dialog.

### Asset Library

Tools for turning purchased model collections into a clean, searchable library.

| Script | What it does |
|---|---|
| **Process Assets for Connecter** | Main batch processor for model collections (e.g. Evermotion volumes). For each source file it merges everything, attaches the geometry, converts it to a **V-Ray proxy** (with a face-count limit for the preview mesh), groups it with any lights/cameras, names it from the volume and model number, and saves it to the destination library. It handles alternate versions (e.g. lights on/off) and can filter objects by keyword. Made for the *Connecter* asset browser. |
| **Update Proxies to Optimized** | Re-processes a folder of asset scenes: merges, attaches, sets pivots at the bottom, and rebuilds the V-Ray proxies with optimised settings. |
| **Set All Selected Proxies To Whole Mesh** | Sets every selected V-Ray proxy to display as a whole mesh. |
| **Save Each Object To Its Own Scene** | Saves every object (or group) in the scene as its own `.max` file, named after the object. It can explode or keep groups, and can skip files that already exist. |
| **Merge Files Into Scene And Move Each Incrementally** | Merges every `.max` file in a folder into one scene and spaces them out along a row, for a quick visual catalogue. |
| **Merge By Name / Attach By Name** | Attaches all scene geometry that shares a name prefix into single objects. |
| **Export Max Scenes As DWGs** | Batch-exports every `.max` file in a folder to `.dwg`. |
| **Find and Replace Asset Paths** | Scans a folder of `.max` files and repaths their assets in bulk, e.g. after the library moves to a new drive. |

### File Renaming

Batch renamers for texture and asset folders.

| Script | What it does |
|---|---|
| **Append Or Prepend Text To File Names** | Adds text to the start or end of every file name, optionally for a range of files only. |
| **Change File Names To File Numbers In Alphabetical Order** | Renumbers files (`001`, `002`…) in alphabetical order. Can keep chosen parts of the original name. |
| **Replace Text In File Names** | Find and replace across file names. |
| **Truncate File Names** | Cuts file names to a set length from the start or end. |
| **Replace File Contents** | Replaces files in one folder with same-position files from another, keeping the original names. |
| **Rename Files For Process Assets For Connecter Script** | Prepares a downloaded collection's file names for the asset processor above. |

### Scene Organisation

| Script | What it does |
|---|---|
| **Layer Imported Objects By Name** | Sorts imported CAD/BIM geometry onto the standard layers by matching names (balustrades, handrails, glazing, slabs, walls…). |
| **Organise Imported Revit Geometry** | Moves Revit-imported objects onto layers by category. |
| **Name And Number Each Selected Object Based On Current Alphabetical Order** | Renames the selection to `Prefix 001`, `Prefix 002`… in alphabetical order. |
| **Name Object Current Object Name Plus One** | Click-to-name tool. Each object you click gets the base object's name with the number incremented. |
| **Name Object After First 3 Characters of Current Objects Name Plus One** | As above, but keeps only a 3-character prefix. |
| **Capitalise Selected Object Names** | Capitalises the first letter of each selected object's name. |
| **Move Objects Incrementally** | Spaces the selected objects out at a fixed distance along X. |

### Modelling

| Script | What it does |
|---|---|
| **Scale Tool** | A click-based one-axis scale tool. Click and move to stretch an object along a single axis, with axis locking (including non-orthogonal axes) and a wireframe ghost of the original for reference. |
