local class = require'luna'

local queue = class {

    Size = {get = function (this) return #this.stack end};

    __construct = function (this, ...)
        this.stack = {...}
    end;

    Push = function (this, value)
        table.insert(this.stack, value)
    end;

    Pop = function (this)
        local value = this.stack[1]
        table.remove(this.stack, 1)
        return value
    end;

    Peak = function (this)
        local value = this.stack[1]
        return value
    end;

	ToArray = function (this)
		return this.stack
	end

}
