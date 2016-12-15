local class = require'luna'

local stack = class {

    Size = {
        get = function (this)
            return #this.stack
        end
    };

    __construct = function (this, ...)
        this.stack = {...}
    end;

    Push = function (this, value)
        table.insert(this.stack, value)
    end;

    Pop = function (this)
        local value = this.stack[this.Size]
        table.remove(this.stack, this.Size)
        return value
    end;

    Peak = function (this)
        local value = this.stack[this.Size]
        return value
    end;

}
