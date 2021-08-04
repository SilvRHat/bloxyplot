-- Require Library
local bplt = require(script.Parent.bloxyplot)

-- Define points for line
local char = workspace.Character
local pts_lookvec = {
    char.HumanoidRootPart,
    function ()
        return char.HumanoidRootPart.CFrame * Vector3.new(0,0,-4)
    end
}
local pts_fromorig = {
    char.HumanoidRootPart,
    Vector3.new()
}

-- Create a subplot and plot lines
local char_plt = bplt:subplot('Character')
local lookVec_line = char_plt:plot{pts_lookvec, 'Look Vector', '-', c=Color3.fromRGB(200,120,32), lw=.2}
local fromOrigin_line = char_plt:plot(pts_fromorig, 'From Origin', '--')
