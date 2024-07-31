# GBC_Color_Viz
Aseprite script to visualize GBC screen during asset creation.
# Installation
**1. Just move the following two files to your Aseprite script directory:**
 - gbcScreenVisualization.lua
 - gbc_sRGB_scaled.csv
**2. That's it!**

# Usage
**1. Open the sprite you want to visualize**
**2. Run script from the Aseprite menu**
   
![image](https://github.com/user-attachments/assets/fd89f3bf-2fe1-4c78-8afd-3e8575941bf7)

*On the first usage, Aseprite will ask for permission to read the gbc_sRGB_scaled.csv file. Check the "Don't show this specific alert" box to suppress this popup. Then click Allow Access*

![image](https://github.com/user-attachments/assets/b68619be-8e42-4711-bdcd-72cbb918be39)

**3. Visualization window will appear**
- The visualization preview transforms each color from the active sprite into the corresponding color measurement from the colorspace data file.
- The color palette of the active sprite is assumed to be "raw" values. As if these are the values loaded into the actual GBC palette. So if your build procedure does any kind of modification, (as in `RGBGFX -c` flag), this visualization will not be accurate. Recommendation is to not use other color modifications in your pipeline, and simply make final color palette choices at this stage.

![image](https://github.com/user-attachments/assets/9cc685c6-b9fa-44c4-94ff-044eed262609)

**4. Workflow**
- The preview window will continuously update as you work. So you can leave it open to the side and reference as you go.
- NOTE: Because of a known bug in Aseprite, the "change" event and "undo" action conflict and will cause Aseprite to crash. As a workaround, I do not update the preview window on "undo" actions. Otherwise, the preview window will update as you work

![image](https://github.com/user-attachments/assets/b50b5084-45e3-41e2-938a-f332a5f49d79)
