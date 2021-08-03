-- Bloxy Plot
-- 3D Graphing tool for Roblox Development

-- DEPENDENCIES //
local collectionservice = game:GetService('CollectionService')
local runservice = game:GetService('RunService')


-- CONSTANTS //
local SECTOR_TAG = 'bloxyplot_sector_tag'
local LINE_TAG = 'bloxyplot_line_tag'


-- CLASSES //
local line = {}
line.__index = line

function line.new(points)
    local self = setmetatable({}, line)

    self.points = {}
    for i, pt in ipairs(points) do
        table.insert(self.points, pt) end

    self._instance = Instance.new('Folder')


    return self
end

function line:setPoints()

end

function renderLine(line)

end


-- SOURCE //
local bplt = {}
bplt.__index = bplt


function bplt:sector(name)
    local sector = setmetatable({}, bplt)

    sector.Name = name
    sector.Visible = true

    local folder = Instance.new('Folder')
    collectionservice:AddTag(folder, SECTOR_TAG)

    folder:SetAttribute('Visible', true)

    return sector
end



return bplt