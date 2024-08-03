function sRGBfromRGB(rgb_in, colorspace)
    -- Divide rgb_in by 8 to get 0, 31
    local R = app.pixelColor.rgbaR
    local G = app.pixelColor.rgbaG
    local B = app.pixelColor.rgbaB
    r_in = math.floor(R(rgb_in) / 8)
    g_in = math.floor(G(rgb_in) / 8)
    b_in = math.floor(B(rgb_in) / 8)
    local i = (r_in * 32 * 32) + (g_in * 32) + b_in -- Get row index for data file
    return colorspace[i].sRGB
end

function getPalette()
    local preview = Image(app.sprite)
    local act_pal = {}
    for it in preview:pixels() do
        local val = it() -- Get value of current pixel
        local foundColor = false
        for _k = 1, #act_pal do
            if val == act_pal[_k] then
                foundColor = true
                break -- Should also skip the rest of the inner loop
            end
        end
        if foundColor == false then
            -- Add new color to the palette
            table.insert(act_pal, val)
        end
    end
    sRGB_gbc = {}
    lookup_pal = {}
    for _i = 1, #act_pal do
        local rgbaA = app.pixelColor.rgbaA
        local pc = act_pal[_i]

        table.insert(lookup_pal, pc)
        -- Get colorspace conversion for GBC
        local gbc_color = sRGBfromRGB(pc, gbc_colorspace)
        table.insert(sRGB_gbc, sRGBfromRGB(pc, gbc_colorspace))
    end
end

function enumeratePalettes()
    -- Need to get tileset
    local lay = app.activeLayer
	if not lay.isTilemap then return app.alert "No active tilemap layer" end

	local tileset = lay.tileset
    print(tileset)
    -- Then loop over each tile and look at the colors
end

-- Script Entry Point
gbc_colorspace = {}
local gbc_fname = app.fs.joinPath(app.fs.userConfigPath, "scripts/gbc_sRGB_scaled.csv");

if app.fs.isFile(gbc_fname) == false then
    return app.alert(string.format("ERROR: Couldn't find GBC colorspace file at %s", gbc_fname))
end
if app.apiVersion < 1 then
    return app.alert("This script requires Aseprite v1.2.10-beta3")
end

-- Load colorspace from file
local file = io.open(gbc_fname)
local n = 0
for line in io.lines(gbc_fname) do
    local R, G, B, sR, sG, sB
    R = file:read('*n'); file:read(1) --<-- added
    G = file:read('*n'); file:read(1) --<-- added
    B = file:read('*n'); file:read(1) --<-- added
    sR = file:read('*n'); file:read(1) --<-- added
    sG = file:read('*n'); file:read(1) --<-- added
    sB = file:read('*n'); file:read(1) --<-- added
    local rgb_in, srgb_out
    local rgba = app.pixelColor.rgba

    rgb_in = rgba(R, G, B, 255)
    srgb_out = rgba(sR, sG, sB, 255)
    gbc_colorspace[n] = {['RGB'] = rgb_in, ['sRGB'] = srgb_out};
    n = n+1
end
file:close()

spr = app.activeSprite

lookup_pal = {}

-- Create Dialog, draw image on it, and get palette of colors in the current sprite

getPalette()

dlg = Dialog("GBC Screen Visualization")
dlg:label{
    id="",
    label="",
    text="GBC"
}
dlg:newrow()
dlg:canvas {
    width = app.sprite.width+10,
    height = app.sprite.height+10,
    autoscaling=true,
    onpaint = function(ev)
        local gc = ev.context
        gc.opacity = 255
        gc.blendMode = BlendMode.NORMAL

        local preview = Image(app.sprite)

        local rgba = app.pixelColor.rgba
        local R = app.pixelColor.rgbaR
        local G = app.pixelColor.rgbaG
        local B = app.pixelColor.rgbaB

        -- Replace colors from active sprite with visualization colorspace
        if preview.colorMode == ColorMode.RGB then
            for it in preview:pixels() do
                local val = it() -- Get value of current pixel

                -- Find matching color in the palette and replace with sRGB of target colorspace
                for _k = 1, #lookup_pal do
                    local p_check = lookup_pal[_k]
                    if val == p_check then
                        -- swap in sRGB for target system
                        local sRGB_k = sRGB_gbc[_k]
                        it(rgba(R(sRGB_k), G(sRGB_k), B(sRGB_k), 255))
                    end
                end
            end
        end
        gc: drawImage(preview, 0, 0)
    end -- end function onpaint()
}
dlg:newrow()
dlg:button{ id="enum_button",
            label="",
            text="Enumerate Palettes",
            onclick=enumeratePalettes}
dlg:show{wait=false}

spr.events:on("change", function(ev)
    getPalette()
    dlg:repaint()
end)

