-- Bloxy Plot
-- A 3D Plotting tool for Roblox Development

-- Dev // SilvRHat
-- Documentation // 
-- GitHub // https://github.com/SilvRHat/bloxyplot


-- DEPENDENCIES //
local collectionservice = game:GetService('CollectionService')
local runservice = game:GetService('RunService')

local maid = require(script.maid)


-- CONST //
local PLOT_COLLECTION_TAG = 'bloxyplot_plot_object'
local PLOTCLASS = 'bloxyplot_plot_class'
local LINE_COLLECTION_TAG = 'bloxyplot_line_object'
local LINECLASS = 'bloxyplot_line_class'


-- SOURCE //
local bplt = {}

local instance_luaobj_mapping = {}


--  LINE CLASS //
local lineClass = {}
lineClass.__index = lineClass

local line_attrs = {'Color', 'Emission', 'Transparency', 'LineWidth', 'StyleFormat', 'MarkerSize', 'Label', 'Visible'}
local line_attr_defaults = {
    Color = Color3.new(1,1,1);
    Emission = 1;
    Transparency = 0;
    LineWidth = .2;
    StyleFormat = '-';
    MarkerSize = 1;
    Label = 'Line';
    Visible = true;
}
local line_attr_aliases = {     -- Short/ lowercase names of line attributes (only used in plot function)
    [2]='StyleFormat';
    [3]='Label';
    color = 'Color';
    c = 'Color';
    emission = 'Emission';
    e = 'Emission';
    a = 'Transparency';
    alpha = 'Transparency';
    lw = 'LineWidth';
    linewidth='LineWidth';
    ms = 'MarkerSize';
    markersize='MarkerSize';
    label='Label';
    visible='Visible';
}


--  SUBPLOT CLASS //
local plotClass = {}
plotClass.__index = plotClass

local plot_attrs = {'Label', 'Color', 'Visible'}
local plot_attr_defaults = {
    Label = 'New';
    Color = Color3.new(1,1,1);
    Visible = true;
}

-- plotClass.new // 
-- A Constructor for plotClass; A folder-type object which organizes a group of nested subplot and line objects
    -- @return - A new plotClass object with default properties
        -- A plotClass object is an empty table whose metamethods interact with both:
        -- an `inner table` with the plotClass methods and private state variables
        -- and a Roblox Instance used for rendering line objects
function plotClass.new()
    local plot = {}
    local instance = Instance.new()
    local self = setmetatable({}, plotClass)


    -- Init instance
    instance_luaobj_mapping[instance] = plot
    collectionservice:AddTag(instance, PLOT_COLLECTION_TAG)
    for _, attr in ipairs(plot_attrs) do
        instance:SetAttribute(attr, plot_attr_defaults[attr]) end


    -- Init class object
    self.Class = PLOTCLASS
    self.Instance = instance
    self._children = {}
    self._maid = maid.new()

    local astry_conn, chldAdd_conn, chldRem_conn : RBXScriptConnection
    astry_conn = instance.AncestryChanged:Connect(function (child, parent) 
        if child==instance and parent==nil and #instance:GetChildren()==0 then  -- Instance has been destroyed
            self:Destroy() end
    end)
    chldAdd_conn = instance.ChildAdded:Connect(function (child)
        table.insert(self._children, instance_luaobj_mapping[child])
    end)
    chldRem_conn = instance.ChildRemoved:Connect(function (child)
        table.remove(self._children, instance_luaobj_mapping[child])
    end)


    -- Mark deconstructor tasks
    self._maid:Mark(astry_conn)
    self._maid:Mark(chldAdd_conn)
    self._maid:Mark(chldRem_conn)
    self._maid:Mark(function ()
        local err_index_out = function() error('Subplot no longer exists') end
        setmetatable(plot, {
            __index = err_index_out;
            __newindex = err_index_out;
        }) 
    end)


    -- Init and return public table
        -- Allow correct indexing to map to appropriate table (Class Methods) or instance (Attributes)
    plot.__newindex = function(tab, key, val)
        local childIndex=nil
        for i, table in ipairs(self._children) do
            if table.Label==key then childIndex = i break end
        end

        if self[key] or childIndex then
            error(string.format('%s is read-only; cannot be set', key))
        elseif instance:GetAttribute(key) then
            if not (type(val)==type(instance:GetAttribute(key))) then
                error(  string.format('Expected type %s, got %s', type(val), type(instance:GetAttribute(key)))  )
            end
            instance:SetAttribute(key, val)
        else
            instance[key]=val
        end
    end
    plot.__index = function(tab, key)
        local childIndex=nil
        for i, table in ipairs(self._children) do
            if table.Label==key then childIndex = i break end
        end

        if self[key] and (not string.match(key, '^_')) then
            return self[key]
        elseif childIndex then
            return self._children[childIndex]
        elseif instance:GetAttribute(key) then
            return instance:GetAttribute(key)
        else
            return instance[key]
        end
    end
    return plot
end


-- plotClass:Subplots // Creates a subplot parented under the plot method called on
    -- @param label (optional) - Specifies a label for the given subplot
    -- @param color (optional) - Specifies an initial color for the given subplot
    -- @return - Returns a new plotClass parented under the one this method was called on
function plotClass:Subplots(label, color)
    label = label or ''
    color = color or Color3.new()   -- TODO: Choose new color

    local subplot = plotClass.new()
    subplot.Label = label
    subplot.Name = string.fromat('Subplot %s', label)
    subplot.Color = color
    subplot.Parent = self.Instance
    return subplot
end

-- plotClass:Plot // Main plot function
    -- @param arg1 - Array of points
        -- Allowed Classes:
            -- Static [Vector3, CFrame]
            -- Updating [Instance, function] (Special rules are outlined in documentation)
    -- @param arg2 (optional) - Line Format
    -- @param arg3 (optional) - Label

    -- Additional parameters may be specified calling the function with a table 
        -- Example: bplt:Plot{{}, label='example', a=.5, lw=.2}
        -- Full list of line properties can be found on the documentation page noted at the top
    -- @return - Returns a lineClass object parented under the subplot this was called on
function plotClass:Plot(...)
    -- Parse and format arguments
    local args = {...}
    if (type(args[1])=='table' and type(args[1][1])=='table') then
        args = args[1] end
    
    local points = args[1]
    args[1] = nil
    if not (points and type(points)=='table') then
        error(string.format('Argument 1 expected type table, got %s', type(points))) end
    
    local attrs = {}
    for arg, val in pairs(args) do
        local attr = table.find(line_attrs, arg) and arg or line_attr_aliases[arg]
        if not attr then
            error(string.format('%s is not a member of %s', LINECLASS, arg)) end
        attrs[attr] = val
    end


    -- Set default properties // TODO: Set attributes in line.new() func
    for property, default in pairs(line_attr_defaults) do
        if not attrs[property] then
            attrs[property] = default end
    end

    -- TODO: Choose color and default label

    
    -- Create line; Edit attributes; Return object
    local line = lineClass.new()
    for attr, val in pairs(attrs) do
        line:SetAttribute(attr, val) end
    line:SetPoints(points)
    return line
end


function plotClass:PlotCFrame()
    
end
function plotClass:PlotLookVector()

end
function plotClass:PlotRightVector()

end
function plotClass:PlotUpVector()

end


-- plotClass:GetLines // Returns a table of the lines under this subplot
function plotClass:GetLines()
    local lines = {}
    for _, obj in ipairs(self._children) do
        if obj.Class==LINECLASS then
            table.insert(lines, obj)
        elseif obj.Class==PLOTCLASS then
            for _, recobj in ipairs(obj:GetLines()) do
                table.insert(lines, recobj)
            end
        end
    end
    return lines
end


function plotClass:Destroy()
    -- Destroy Children
    for name, child in pairs(self._children) do 
        child:Destroy()
        self._children[name] = nil
    end

    -- Cleanup & remove references
    self._maid:Clean()
    instance_luaobj_mapping[self.Instance] = nil
    self.Instance:Destroy()
    for key, _ in ipairs(self) do
        self[key]=nil end
end





-- Bloxy Plot Library
function bplt:FromInstance(obj)
    return instance_luaobj_mapping[obj]
end

return bplt