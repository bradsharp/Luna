local class = require'lib/luna'

local event do
	local signal = class {
		__construct = function (this, callback)
			this.callback = callback
		end;
		Disconnect = function (this)
			this.Connected = false
			this.callback = nil
		end;
		Raise = function (this, ...)
			if this.Connected and this.callback then
				coroutine.wrap(this.callback)(...)
			else
				error("Signal has been disconnected")	
			end
		end;
		Connected = true
	}
    event = class {
        Connect = function (this, func)
			local newSignal = signal(func)
			table.insert(this.signals, newSignal)
            return newSignal
        end;
        Raise = function (this, ...)
            for i, signal in ipairs(this.signals) do
                if signal.Connected then
					signal:Raise(...)
				else
					this.signals[i] = nil
				end
            end
        end;
        __construct = function (this)
            this.signals = {}
        end,
    }
end
