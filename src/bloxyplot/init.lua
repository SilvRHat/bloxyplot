-- Bloxy Plot
-- A 3D Plotting tool for Roblox Development

-- Dev // SilvRHat
-- Documentation //
-- GitHub //


-- DEPENDENCIES //
local collectionservice = game:GetService('CollectionService')
local runservice = game:GetService('RunService')

local maid = require(script.maid)
local line = require(script.bloxyline)

-- CONST //
local PARAM_ALIASES = {
    [1] = '_points';
    [2] = 'label';
    [3] = 'style';
    
    c = 'color';
    a = 'alpha';
    ms = 'markersize';
}

local PARAM_DEFAULTS = {
    color = nil; -- Dynamic; depends on total created lines
    volume = nil; -- Set by width
    emission = 1;
    alpha = 0;
    width = .2;
    stretch = false;
    style = '-';
    markersize = 1;
    label = 'Line';
    visible = true;
}


-- SOURCE //
local bplt = {}
bplt.__index = bplt

local function initLineProperties(args)
    local properties = {}
    for k, v in pairs(args) do
        local property = PARAM_ALIASES[k] and PARAM_ALIASES[k] or k
        if (property~=k) and (args[k] and args[property]) then
            error(string.format('Cannot specify both arguments %s and %s', k, property)) end
        properties[property] = v
    end

    -- Set defaults
    for property, default in pairs(PARAM_DEFAULTS) do
        if not properties[property] then
            properties[property] = default end
    end

    return properties
end

function bplt:plot(...)
    -- Parse arguments
    local args = {...}
    if (type(args[1])=='table' and type(args[1][1])=='table') then
        args = args[1] end
    
    local points = args[1]
    if not (points and type(points)=='table') then
        error('plot function requires a type of table for the 1st argument') end
    
    local properties = initLineProperties(args)
    local ax = line.new(points, properties)
    ax._Instance.Parent = workspace
    return ax
end



return bplt