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
    local spr = app.activeSprite
    local act_pal = spr.palettes[1]
    app.command.ColorQuantization { -- Calling this inside an event callback is crashing Aseprite. So let's build our own palette
        ui = false,
        withAlpha = true,
        maxColors = 256,
        useRange = false,
        algorithm = 0
    }
    sRGB_gbc = {}
    lookup_pal = {}     -- NOT a palette object, so indexes from 1, len
    -- For some godforsaken reason, palettes index from 0, len-1, unlike everything else
    for _i = 0, #act_pal-1 do
        local c = act_pal:getColor(_i)
        if c.alpha ~= 0 then -- ignore non-opaque pixels
            local pc = c.rgbaPixel
            table.insert(lookup_pal, pc)

            -- Get colorspace conversion for GBC
            table.insert(sRGB_gbc, sRGBfromRGB(pc, gbc_colorspace))
        end
    end
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
dlg:show{wait=false}

spr = app.activeSprite
spr.events:on("change", function(ev)
    if ev and not ev.fromUndo then
        getPalette()
        dlg:repaint()
    end
end)

