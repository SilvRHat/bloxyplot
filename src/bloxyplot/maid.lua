-- Maid Class
-- Manages a group of class objects for well-managed deconstruction


-- Class
local maidClass = {}
maidClass.__index = maidClass

-- Destructors
local DESTRUCTORS = {
    ['function'] = function(mark)
        mark()
    end;
    ['RBXScriptConnection'] = function(mark)
        mark:Disconnect()
    end;
    ['Instance'] = function(mark)
        mark:Destroy()
    end;
    ['table'] = function(mark)
        if mark.Destroy then
            mark:Destroy() end
    end;
}

-- Constructors
function maidClass.new(...)
    local self = setmetatable({}, maidClass)

    self._marked = {}
    for _, mark in pairs({...}) do
        if not DESTRUCTORS[typeof(mark)] then 
            continue end
        self._marked[mark] = 1 
    end
    return self
end

-- Methods
function maidClass:Mark(mark)
    if not DESTRUCTORS[typeof(mark)] then 
        return end
    self._marked[mark] = (self._marked[mark] or 0) + 1
end

function maidClass:Unmark(mark)
    self._marked[mark] = nil end


function maidClass:Clean()
    for mark, _ in pairs(self._marked) do
        DESTRUCTORS[typeof(mark)](mark)
        self._marked[mark] = nil
    end
end

function maidClass:Destroy()
    self:Clean()
end



return maidClass