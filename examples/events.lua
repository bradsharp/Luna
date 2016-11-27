local class = require'lib/class'

local event do
    event = class {
        Connect = function (this, func)
            this.signals[func] = coroutine.wrap(func)
            return function () -- Return a disconnect function incase func was anonymous 
                this.signals[func] = nil
            end
        end;
        Disconnect = function (this, func)
            this.signals[func] = nil
        end;
        Raise = function (this, ...)
            for func, thread in ipairs(this.signals) do
                thread(...)
            end
        end;
        __construct = function (this)
            this.signals = {}
        end,
    }
end
