local class = require'new/luna'

local stack = class {

    Size = {
        get = function (this)
            return #this.stack
        end
    };

    __construct = function (this, ...)
        this.stack = {...}
    end;

    Push = function (this, ...)
        local values = {...}
        for i = 1, #values do
            table.insert(this.stack, values[i])
        end
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

local tasks = stack()

tasks:Push("Test", "Hi")
print(tasks:Pop())
print(tasks:Pop())
