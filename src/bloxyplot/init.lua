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
local PLOT_CLASSNAME = 'bloxyplot_plot_class'
local LINE_COLLECTION_TAG = 'bloxyplot_line_object'
local LINE_CLASSNAME = 'bloxyplot_line_class'


-- SOURCE //
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
    [2] = 'StyleFormat'; -- 2nd arg
    [3] = 'Label';       -- 3rd arg

    color = 'Color';
    emission = 'Emission';
    alpha = 'Transparency';
    linewidth='LineWidth';
    markersize='MarkerSize';
    label='Label';
    visible='Visible';

    c = 'Color';
    e = 'Emission';
    a = 'Transparency';
    lw = 'LineWidth';
    ms = 'MarkerSize';
}
local line_attr_update_func = {
    Color = function(line) 
        print('update color') -- TODO
    end;
    Emission = function(line) 
        print('update emission') -- TODO
    end;
    Transparency = function(line) 
        print('update transparency') -- TODO
    end;
    LineWidth = function(line) 
        print('update linewidth') -- TODO
    end;
    MarkerSize = function(line)
        print('update markersize') -- TODO
    end;
}
local pt_class_get_funcs
pt_class_get_funcs = {
    Vector3 = function(x) 
        return x
    end;
    CFrame = function(x)
        return x.Position
    end;
    Instance = function(x)
        if x:IsA('BasePart') then
            return x.Position
        elseif x:IsA('CFrameValue') then
            return x.Value.Position
        elseif x:IsA('Attachment') then
            return x.WorldPosition
        elseif x:IsA('Vector3Value') then
            return x.Value
        end
    end;
    ['function'] = function(x)
        local ret = x()
        if typeof(x)=='function' then
            error('function cannot return type function') end
        return pt_class_get_funcs[typeof(ret)](ret)
    end;
}





function lineClass.new() 
    local line = {}
    local instance = Instance.new('Folder')
    local self = setmetatable({}, lineClass)
    self._maid = maid.new()

    -- Init instance
    do
        instance_luaobj_mapping[instance] = line
        collectionservice:AddTag(instance, LINE_COLLECTION_TAG)
        for _, attr in ipairs(line_attrs) do
            instance:SetAttribute(attr, line_attr_defaults[attr]) end
        
        -- To parent attachment objects under
        local attpart = Instance.new('Part')
        attpart.Name = 'Attachments'
        attpart.CanCollide = false
        attpart.Anchored = true
        attpart.Transparency = 1
        attpart.Position = Vector3.new(0, -500, 0)
        attpart.Locked = true
        attpart.Size = Vector3.new(.05, .05, .05)
        attpart.Parent = instance
        self._maid:Mark(attpart)

        -- To parent beam objects under
        local beams = Instance.new('Folder')
        beams.Name = 'Beams'
        beams.Parent = instance
        self._maid:Mark(beams)
        
        -- To parent marker objects under
        local markers = Instance.new('Folder')
        markers.Name = 'Markers'
        markers.Parent = instance
        self._maid:Mark(markers)
    end


    -- Init class object
    self.Class = LINE_CLASSNAME
    self.Instance = instance
    self._points = {}
    self._attInstances = {}
    self._markerInstances = {}

    self._update_conn_maid = maid.new()
    self._update_funcs = {}
    
    -- Connections
    local astry_conn, attr_conn, chldRem_conn: RBXScriptConnection
    astry_conn = instance.AncestryChanged:Connect(function (child, parent) 
        if child==instance and parent==nil and #instance:GetChildren()==0 then  -- Instance has been destroyed
            self:Destroy() end
    end)
    attr_conn = instance.AttributeChanged:Connect(function (attr) 
        if line_attr_update_func[attr] then
            line_attr_update_func[attr](line) end
    end)
    chldRem_conn = instance.DescendantRemoving:Connect(function(desc) 
        -- Check if descendent is related to a point (and if related pieces should be removed)
        local idx = table.find(self._attInstances, desc) or table.find(self._markerInstances, desc)
        if idx then
            local att, marker = self._attInstances[idx], self._markerInstances[idx]
            table.remove(self._points, idx)
            if att then
                table.remove(self._attInstances, idx)
                if att~=desc then att:Destroy() end
            end
            if marker then
                table.remove(self._markerInstances, idx)
                if marker~=desc then marker:Destroy() end
            end
        end
    end)
    self._maid:Mark(astry_conn)
    self._maid:Mark(attr_conn)
    self._maid:Mark(chldRem_conn)
    

    -- Init and return public table
        -- Allow correct indexing to map to appropriate table (Class Methods) or instance (Attributes)
    setmetatable(line, {
        __newindex = function(tab, key, val)
            if self[key] then
                self[key] = val
            elseif instance:GetAttribute(key) then
                if not (type(val)==type(instance:GetAttribute(key))) then
                    error(  string.format('Expected type %s, got %s', type(val), type(instance:GetAttribute(key)))  )
                end
                instance:SetAttribute(key, val)
            else
                instance[key]=val
            end
        end;
        __index = function(tab, key)
            if self[key] then
                return self[key]
            elseif instance:GetAttribute(key) then
                return instance:GetAttribute(key)
            else
                return instance[key]
            end
        end;
    })
    return line
end

function lineClass:GetPoints()
    local positions = {}
    for _, pt in ipairs(self._points) do
        if not(pt_class_get_funcs[typeof(pt)]) then
            error('Unsupported point type %s', typeof(pt)=='Instance' and pt.ClassName or typeof(pt)) end
        table.insert(positions, pt_class_get_funcs[typeof(pt)](pt))
    end
    return positions
end

function lineClass:SetPoints(points)
    local newpoints = {}

    -- Fix points / marker
    
    -- Reset connections
    self._update_conn_maid:Clean()
    self._update_funcs = {}
    
    -- loop through points; set new connections
    for i, pt in ipairs(points) do
        local att = self._attInstances[i]

        if typeof(pt)=='function' then
            if #self._update_funcs==0 then
                local conn = runservice.Heartbeat:Connect(function () 
                    for j, func in ipairs(self._update_funcs) do
                        func()
                    end
                end)
                self._update_conn_maid:Mark(conn)
            end

            table.insert(self._update_funcs, function() 
                local ret = pt()
                if typeof(ret)=='function' then
                    error() end
                att.WorldPosition = pt_class_get_funcs[typeof(ret)](ret)
            end)

        elseif typeof(pt)=='Instance' then
            local conn = pt.Changed:Connect(function ()
                att.WorldPosition = pt_class_get_funcs[typeof(pt)](pt)
            end)
            self._update_conn_maid:Mark(conn)
        end
        att.WorldPosition = pt_class_get_funcs[typeof(pt)](pt)
    end
end



function lineClass:Destroy()
    self._update_conn_maid:Clean()
    self._maid:Clean()
end

-- parts of line
--[[
    Attachments
    Markers
    Beams

]]

-- Times to set up parts (when building)
-- Set up connections to update certain points as long as they exist
-- Set up a watch for removed children needed for connections - remove point 

















--  SUBPLOT CLASS //
local plotClass = {}
plotClass.__index = plotClass

local plot_attrs = {'Label', 'Color', 'Visible'}
local plot_attr_defaults = {
    Label = 'Subplot';
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
    local instance = Instance.new('Folder')
    local self = setmetatable({}, plotClass)


    -- Init instance
    instance_luaobj_mapping[instance] = plot
    collectionservice:AddTag(instance, PLOT_COLLECTION_TAG)
    for _, attr in ipairs(plot_attrs) do
        instance:SetAttribute(attr, plot_attr_defaults[attr]) end


    -- Init class object
    self.Class = PLOT_CLASSNAME
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
        table.remove(self._children, table.find(self._children, instance_luaobj_mapping[child]))
    end)


    -- Mark deconstructor tasks
    self._maid:Mark(astry_conn)
    self._maid:Mark(chldAdd_conn)
    self._maid:Mark(chldRem_conn)


    -- Init and return public table
        -- Allow correct indexing to map to appropriate table (Class Methods) or instance (Attributes)
    setmetatable(plot, {
        __newindex = function(tab, key, val)
            local childIndex=nil
            for i, table in ipairs(self._children) do
                if table.Label==key then childIndex = i break end
            end

            if self[key] then
                self[key] = val
            elseif childIndex then
                error(string.format('%s is read-only; cannot be set', key))
            elseif instance:GetAttribute(key) then
                if not (type(val)==type(instance:GetAttribute(key))) then
                    error(  string.format('Expected type %s, got %s', type(val), type(instance:GetAttribute(key)))  )
                end
                instance:SetAttribute(key, val)
            else
                instance[key]=val
            end
        end;
        __index = function(tab, key)
            local childIndex=nil
            for i, table in ipairs(self._children) do
                if table.Label==key then childIndex = i break end
            end

            if self[key] then
                return self[key]
            elseif childIndex then
                return self._children[childIndex]
            elseif instance:GetAttribute(key) then
                return instance:GetAttribute(key)
            else
                return instance[key]
            end
        end;
    })
    return plot
end


-- plotClass:Subplot // Creates a subplot parented under the plot method called on
    -- @param label (optional) - Specifies a label for the given subplot
    -- @param color (optional) - Specifies an initial color for the given subplot
    -- @return - Returns a new plotClass parented under the one this method was called on
function plotClass:Subplot(label, color)
    label = label or ''
    color = color or Color3.new()   -- TODO: Choose new color

    local subplot = plotClass.new()
    subplot.Label = label
    subplot.Name = string.format('Subplot %s', label)
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
            error(string.format('%s is not a member of %s', LINE_CLASSNAME, arg)) end
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
        line[attr] = val end
    line:SetPoints(points)
    line.Name = string.format('Line %s', line.Label)
    line.Parent = self.Instance
    return line
end


function plotClass:PlotCFrame(CF, length, format, name)
    
end
function plotClass:PlotLookVector(CF, length, format, name)

end
function plotClass:PlotRightVector(CF, length, format, name)

end
function plotClass:PlotUpVector(CF, length, format, name)

end


-- plotClass:GetLines // Returns a table of the lines under this subplot
function plotClass:GetLines()
    local lines = {}
    for _, obj in ipairs(self._children) do
        if obj.Class == LINE_CLASSNAME then
            table.insert(lines, obj)
        elseif obj.Class == PLOT_CLASSNAME then
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
    for k, val in pairs(self) do
        self[k] = nil end

    local err_index_out = function() error('Subplot no longer exists') end
    setmetatable(self, {
        __index = err_index_out;
        __newindex = err_index_out;
    }) 
end












-- BLOXY PLOT LIBRARY //
local bplt = {}

function bplt:FromInstance(obj)
    return instance_luaobj_mapping[obj]
end

local test = plotClass.new()
test.Name='Test BloxyPlot'
test.Parent=workspace
return test