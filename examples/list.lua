local class = require'lib/class'

local list = class {

    Length = {
        get = function (this)
            return #this.List
        end
    };

    __construct = function (this, ...)
        this.List = {...}
    end;

    __index = function (this, index)
        return this.List[index]
    end;

    Add = function (this, item)
        table.insert(this.List, item)
    end;

    Remove = function (this, index)
        table.remove(this.List, index)
    end;

    Iterator = {
        get = function (this)
            local i = 0
            local function iter ()
                i = i + 1
                local v = this.List[i]
                if v then
                    return i, v
                end
            end
            return iter
        end
    };

}
