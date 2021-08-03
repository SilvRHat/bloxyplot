local bplt = require(script.Parent.bloxyplot)
local character = workspace.Character
local char_plt = bplt:sector('Character')
local fromOrigin_line = char_plt:plot{
    {character.HumanoidRootPart, Vector3.new()},
    '-',
    c = Color3.fromRGB(200, 120, 32),
    a = (function () 
            return 1 - (math.clamp(character.HumanoidRootPart.Position.Magnitude, 0, 100) / 100)
        end),
    width = 1,
    stretch = true,
}