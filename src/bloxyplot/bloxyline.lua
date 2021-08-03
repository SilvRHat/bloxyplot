-- Bloxy Plot // Line Class Script
-- A 3D Plotting tool for Roblox Development

-- Dev // SilvRHat
-- Documentation //
-- GitHub //


-- DEPENDENCIES //
local runservice = game:GetService('RunService')
local collectionservice = game:GetService('CollectionService')

local maid = require(script.Parent.maid)


-- CONSTANTS //
local LINE_COLLECTION_TAG = 'bloxyplot_line_object'


-- CLASS SOURCE //
local line = {}
line.__index = line

-- Private functions
function renderLine(self)
    local n = #self._points
    

end

function connectUpdateFunc(self, func)

end

-- Constructors
function line.new(points, properties)
    local self = setmetatable({}, {
        __index = line; -- Used to get property and line class functions
        __newindex = nil; -- Used to set a property and match changes
    })

    self._maid = maid.new()
    self._update_funcs = {}
    self._update_conn = nil

    self._points = points
    self._pt_objs = 0

    local instance = Instance.new('Folder')
    collectionservice:AddTag(instance, LINE_COLLECTION_TAG)
    self._Instance = instance

    renderLine(self)
    
    return self
end

-- Public Functions
function line:SetPoints(points)

end

function line:Destory()
    line._maid:Clean()
end


return line