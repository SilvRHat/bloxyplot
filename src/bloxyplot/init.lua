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


-- STATE //
local instance_luaobj_mapping = {}


local function newColor(i)
    local x = (i%3 + 1) * ((i^2) % 3 + 1)
    local h, s, v
    h = ((i * 323 + 200) % 255) / 255
    s = (((x * 45) % 100) / 100)*.1 + .9;
    v = (((x * 924) % 100) / 100)*.5 + .5;
    return Color3.fromHSV(h,s,v)
end

local function newColorVariant(i)
    local x = (i%3 + 1) * ((i^2) % 3 + 1)
    local h, s, v
    h = ((i * 500 + 200) % 255) / 255
    s = (((x * 45) % 100) / 100)*.2 + .8;
    v = (((x * 924) % 100) / 100)*.6 + .4;
    return Color3.fromHSV(h,s,v)
end



--  LINE CLASS //
local nsubplots = -1

local lineClass = {}
lineClass.__index = lineClass

local line_attrs = {'Color', 'Emission', 'Transparency', 'LineWidth', 'StyleFormat', 'MarkerSize', 'Label', 'Visible'}
local line_attr_defaults = {
    Color = Color3.new(1,1,1);
    Emission = .1;
    Transparency = 0;
    LineWidth = .5;
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
        for _, beam : Beam in ipairs(line.Beams:GetChildren()) do
            beam.Color = ColorSequence.new(line.Color) end
    end;
    Emission = function(line) 
        for _, beam : Beam in ipairs(line.Beams:GetChildren()) do
            beam.LightEmission = line.Emission end
    end;
    Transparency = function(line) 
        for _, beam : Beam in ipairs(line.Beams:GetChildren()) do
            beam.Transparency = NumberSequence.new(line.Transparency) end
    end;
    LineWidth = function(line) 
        for _, beam : Beam in ipairs(line.Beams:GetChildren()) do
            beam.Width0 = line.LineWidth
            beam.Width1 = line.LineWidth
        end
    end;
    MarkerSize = function(line)
        for _, marker in ipairs(line.Markers:GetChildren()) do
            marker.Size = Vector3.new(1,1,1) * line.MarkerSize end
    end;
    StyleFormat = function (line)
        line:formatStyle()
        for _, marker in ipairs(line.Markers:GetChildren()) do
            marker:GetFirstChildOfClass('SpecialMesh').MeshType = line._marker_mesh
        end
        for _, beam : Beam in ipairs(line.Beams:GetChildren()) do
            beam.Color = ColorSequence.new(line.Color)
            beam.Texture = line._line_texture
        end
    end;
}

local pt_class_get_funcs; pt_class_get_funcs = {
    Vector3 = function(x) 
        return x, Vector3.new()
    end;
    CFrame = function(x)
        local rx,ry,rz = x:ToEulerAnglesYXZ()
        return x.Position, Vector3.new(math.deg(rx), math.deg(ry), math.deg(rz))
    end;
    Instance = function(x)
        if x:IsA('BasePart') then
            return x.Position, x.Orientation
        elseif x:IsA('CFrameValue') then
            local rx,ry,rz = x.Value:ToEulerAnglesYXZ()
            return x.Value.Position, Vector3.new(math.deg(rx), math.deg(ry), math.deg(rz))
        elseif x:IsA('Attachment') then
            return x.WorldPosition, x.WorldOrientation
        elseif x:IsA('Vector3Value') then
            return x.Value, Vector3.new()
        end
    end;
    ['function'] = function(x)
        local ret = x()
        if typeof(ret)=='function' then
            error('function cannot return type function') end
        return pt_class_get_funcs[typeof(ret)](ret)
    end;
}


-- Format line
local marker_style = {
    o = Enum.MeshType.Sphere;
    x = Enum.MeshType.Brick;
}
local line_style = {
    ['-'] = '';     -- Solid line
    ['--'] = '';    -- Dashed line
    [':'] = '';     -- Dotted line
    ['-.'] = '';    -- Dash dotted line
    [''] = ''; -- Empty
}
local color_shorthand = {
    r = Color3.fromRGB(255, 0, 0);
    o = Color3.fromRGB(255, 150, 0);
    y = Color3.new(255, 255, 0);
    g = Color3.fromRGB(50, 255, 95);
    b = Color3.fromRGB(0, 0, 255);
    p = Color3.fromRGB(150,0,255);
}
function lineClass:formatStyle()
    local marker, line, color = string.match(
        self.StyleFormat,
        '([ox]?)([-.:]*)(%l*)'
    )
    if marker_style[marker] then
        self._use_markers = true
        self._marker_mesh = marker_style[marker] 
    else
        self._use_markers = false
    end

    if line_style[line] then
        self._line_texture = line_style[line] end
    
    if color_shorthand[color] then
        self._color_set = true
        self.Color = color_shorthand[color] end
end


-- lineClass.new // Constructor for a new line object
    -- @return - Returns a line class object which references both a table of methods 
              -- and an instance with attributes describing line material and rendering options
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

        -- To parent beam objects under
        local beams = Instance.new('Folder')
        beams.Name = 'Beams'
        beams.Parent = instance
        
        -- To parent marker objects under
        local markers = Instance.new('Folder')
        markers.Name = 'Markers'
        markers.Parent = instance
    end


    -- Init class object
    self.Class = LINE_CLASSNAME
    self.Instance = instance
    self._points = {}
    self._attInstances = {}

    self._render = true         -- Internal variable for determining visibility based on heirarchy of objects with set Visible property
    self._use_markers = false   -- Internal for if markers are used
    self._line_texture = ''     -- Internal for texture on beam objects
    self._marker_mesh = Enum.MeshType.Sphere
    self._color_set = false

    self._update_conn_maid = maid.new() -- Maid for cleaning up RBXScriptConnections which update line


    -- Connections
    local astry_conn, attr_conn, chldRem_conn: RBXScriptConnection
    astry_conn = instance.AncestryChanged:Connect(function (child, parent) 
        if child==instance and parent==nil and #instance:GetChildren()==0 then  -- Instance has been destroyed
            self:Destroy() end  -- Cleans up extra data held in lua-table component of object
    end)
    attr_conn = instance.AttributeChanged:Connect(function (attr) 
        if line_attr_update_func[attr] then         -- Propety changed (Color, Width, etc)
            line_attr_update_func[attr](line) end   -- Update based on function
    end)
    chldRem_conn = instance.DescendantRemoving:Connect(function(desc) 
        local isAttrIndex = table.find(self._attInstances, desc)
        if isAttrIndex then
            table.remove(self._points, isAttrIndex)
            task.defer(function ()  -- Defer to next frame when instance is fully removed
                line:SetPoints(self._points)
            end)
        end
    end)
    self._maid:Mark(astry_conn)
    self._maid:Mark(attr_conn)
    self._maid:Mark(chldRem_conn)
    

    -- Init and return public table
        -- Allow correct indexing to map to appropriate table (Class Methods) or instance (Attributes)
    setmetatable(line, {
        __newindex = function(tab, key, val)
            if self[key]~=nil then
                self[key] = val
            elseif instance:GetAttribute(key)~=nil then
                if not (type(val)==type(instance:GetAttribute(key))) then
                    error(  string.format('Expected type %s, got %s', type(val), type(instance:GetAttribute(key)))  )
                end
                instance:SetAttribute(key, val)
            else
                instance[key]=val
            end
        end;
        __index = function(tab, key)
            if self[key]~=nil then
                return self[key]
            elseif instance:GetAttribute(key)~=nil then
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
    for i, pt in ipairs(points) do
        table.insert(newpoints, pt) end
    self._points = newpoints

    -- Verify existing attachments are valid
    do local i = 1; while (i<=#self._attInstances) 
        do
            local att : Instance = self._attInstances[i]
            if not att:IsDescendantOf(self.Instance) then
                table.remove(self._attInstances, i)
            else
                i+=1
            end
        end
    end

    -- Ensure appropriate amount of attachments
    while (#self._points ~= #self._attInstances) do
        if #self._points > #self._attInstances then    -- Instance new attachment
            local newAtt = Instance.new('Attachment')
            newAtt.Name = 'Pt Attachment'
            newAtt.Parent = self.Attachments
            table.insert(self._attInstances, newAtt)

        elseif #newpoints < #self._attInstances then    -- Remove attachment
            local att = self._attInstances[#self._attInstances]
            table.remove(self._attInstances, table.find(self._attInstances, att))
            att:Destroy()

        end
    end

    -- Ensure appropriate amount of beams
    while  #(self.Beams:GetChildren()) ~= math.max(0, #newpoints - 1) do
        if #(self.Beams:GetChildren()) < #newpoints - 1 then
            local beam : Beam = Instance.new('Beam')
            beam.Color = ColorSequence.new(self.Color)
            beam.LightEmission = self.Emission
            beam.Width0 = self.LineWidth
            beam.Width1 = self.LineWidth
            beam.FaceCamera = true
            beam.Transparency = NumberSequence.new(self.Transparency)
            beam.LightInfluence = 1
            beam.Texture = self._line_texture
            beam.TextureSpeed = 0
            beam.Segments = 0
            beam.Parent = self.Beams

        elseif #self.Beams:GetChildren() > math.max(0, #newpoints - 1) then
            self.Beams:FindFirstChildOfClass('Beam'):Destroy()

        end
    end

    -- Ensure appropriate amount of markers
    local markersNeeded = self._use_markers and #self._points or 0
    
    if markersNeeded==0 then
        self.Markers:ClearAllChildren() end
    while #(self.Markers:GetChildren()) ~= markersNeeded do
        if #(self.Markers:GetChildren()) < markersNeeded then
            local marker: Part = Instance.new('Part')
            marker.Anchored = true
            marker.CanCollide = false
            marker.Material = Enum.Material.Neon
            marker.Size = Vector3.new(1,1,1) * self.MarkerSize
            marker.Color = self.Color
            marker.Transparency = self.Transparency
            marker.Parent = self.Markers

            local mesh: SpecialMesh = Instance.new('SpecialMesh')
            mesh.MeshType = self._marker_mesh
            mesh.Parent = marker
            
        elseif #(self.Markers:GetChildren()) > markersNeeded then
            self.Beams:FindFirstChildOfClass('BasePart'):Destroy()

        end
    end


    -- Reset connections
    self._update_conn_maid:Clean()

    local function updateWorldPt(input, att, marker)
        local pos, rot = pt_class_get_funcs[typeof(input)](input)
        att.WorldPosition = pos
        if marker then
            marker.Position, marker.Orientation = pos, rot end
    end

    -- loop through points; set new connections
    local markers = self.Markers:GetChildren()
    for i, pt in ipairs(self._points) do
        local att = self._attInstances[i]
        local marker = markers[i]

        if typeof(pt)=='function' then
            -- Connect function to heartbeat signal / update per frame
            local conn = runservice.Heartbeat:Connect(function () 
                local ret = pt()
                if typeof(ret)=='function' then
                    error() end
                updateWorldPt(ret, att, marker)
            end)
            self._update_conn_maid:Mark(conn)

        elseif typeof(pt)=='Instance' then
            local conn = pt.Changed:Connect(function () 
                updateWorldPt(pt, att, marker) end)
            self._update_conn_maid:Mark(conn)

        end
        updateWorldPt(pt, att, marker)
    end

    -- Correct beam attachments
    for i, beam:Beam in ipairs(self.Beams:GetChildren()) do
       beam.Attachment0 = self._attInstances[i]
       beam.Attachment1 = self._attInstances[i + 1]
    end
end



function lineClass:Destroy()
    self._update_conn_maid:Clean()  -- Clear any update functions
    self._maid:Clean()              -- Clear self
end













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

    nsubplots+=1
    self._plotid = nsubplots

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
    label = label or string.format('Subplot %d', self._plotid+2)
    color = color or newColor(
        (self._plotid*50) + #self:GetLines()
    )

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

    -- Default label
    attrs['Label'] = attrs['Label'] or string.format('Line %d', #self:GetLines())

    -- Create line; Edit attributes; Return object
    local line = lineClass.new()
    for attr, val in pairs(attrs) do
        line[attr] = val end

    -- Check if color not set
    if not attrs['Color'] and not line._color_set then
        line.Color = newColor(self._plotid*50 + #self:GetLines())
    end
    
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