# Photoshop scripts

ExtendScript (`.jsx`) tools that turn V-Ray render passes into a graded image. The pipeline scripts are normally started by 3ds Max; the rest are single-key grading and export shortcuts.

← [Back to overview](../README.md)

---

## Install

1. Copy the contents of `Scripts/` to `<Photoshop>\Presets\Scripts\CallisScripts\`.
2. Load `Actions/Callis Scripts.atn` in the **Actions** panel. 3ds Max starts the pipeline by playing these actions.
3. Restart Photoshop. The scripts appear under **File ▸ Scripts** and can be bound to keys in **Edit ▸ Keyboard Shortcuts**.

---

## Render pipeline

### `Organisation Scripts....jsx`

Builds and maintains the layered `.psb` for each rendered shot. It has four modes, chosen either by 3ds Max's render dialog or by a prompt when run by hand.

**Initial Organisation** builds the file from a folder of passes:

1. Sets up a 32-bit RGB `.psb` at the diffuse pass's size.
2. Places every render pass as a **linked smart object**, so re-renders update in place, and names it cleanly.
3. Converts **multimatte** passes into per-channel selection masks, and adds world normals and alpha.
4. Groups and blends the passes into a working stack:
   - Background
   - Reflection and Refraction (Linear Dodge, with their filter passes as Multiply)
   - Specular
   - Total Lighting, Raw Lighting, Raw GI and Sun
   - Diffuse
   - AO, Self-Illumination, Atmosphere and Z-Depth overlays
   - A separate **Glass** group when glass was rendered on its own
5. Adds an **Overall Adjustments** group, a **Border** group, multimatte adjustment groups, and an **Entourage** structure with shadow sub-layers.
6. Collapses the groups, zooms to fit, and saves.

**Rerender Organisation** (same location or new location) swaps a new set of passes into an existing `.psb` and keeps every mask, adjustment and painted layer.

**High Resify** takes a graded low-res file, scales it 400%, relinks it to the high-res passes, and rescales the smart objects. The grading done at preview resolution carries straight over to the final.

**Shift to 16b Mode** creates a `… 16b.psb` working file next to the 32-bit master and links the master into it as a smart object. Adjustments that only work in 16-bit can then be used while the master stays live underneath.

### `Adjustments Scripts....jsx`

Prompts for a single letter, then adds a masked adjustment layer to the right pass group, using the current selection or a multimatte as the mask:

```
A  Overall Adjustments     B  Background      D  Diffuse         G  GI
L  Raw Lighting            W  Raw Reflection  R  Raw Refraction
E  Reflection Filter       T  Refraction Filter                  X  Specular   S  Sun
```

A second prompt picks a normal or an **inverse** adjustment, which applies to everything outside the selection.

### `Scripts For Actions/`

Small helpers that the action set plays when 3ds Max triggers the pipeline. 3ds Max writes the shot settings (root folder, frame number, resolution, bit depth, overwrite) as a metadata file. These scripts read those settings back into the running Photoshop session and choose the pipeline mode (`Initial`, `Rerender`, `High Resify`). `Create 3DS Max Metadata File.jsx` creates that hand-off file the first time.

---

## Grading shortcuts: `Extras/`

Each one is meant to be bound to a key.

| Script | What it does |
|---|---|
| **Create Group from Selection** | Creates an empty group masked by the current selection, ready for adjustment layers. |
| **Create Lighter Colour Group / Create Darker Colour Group** | The same, with the group set to *Lighter Color* or *Darker Color*, for painting light or shadow into a region. |
| **Create Group Set To Normal** | Groups the selected layers with the group's blend mode set to *Normal* (not *Pass Through*). |
| **Add Mask From Selection To Active Layer** | Replaces the active layer's mask with the current selection. |
| **Convert Layer Mask To Group Mask** (Normal / Pass Through) | Moves a layer's mask onto a new group around it, so more layers can share it. |
| **Create Vignette Group** | Adds an inverted, masked Exposure vignette and switches to a black/white brush to shape it. |
| **Toggle Multimatte Layer Visibility** | Shows or hides the multimatte group. |
| **Add Entourage Member** | Picks an image file (a person, tree, car…), places it as a smart object, and files it into the entourage group under a clean name. |
| **Save As JPG** | Saves a JPG with the file name prefilled from the shot name, minus the `16b` / `High Res` suffixes. The output folder defaults to the document's own folder. |

## Export: `Asset Organisation/`

| Script | What it does |
|---|---|
| **Save Current Screen Selection as JPG** | Crops to the current selection, saves it as a numbered JPG to the folder named in a `path:` layer, then restores the document. Built for cutting a contact sheet into individual thumbnails. |
| **Save Each Layer As A Numbered JPG** (bottom-up / top-to-bottom) | Exports every layer as its own numbered JPG. |
| **Arrange All Layers Alphabetically** | Sorts the layer stack by name. |
