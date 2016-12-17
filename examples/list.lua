local class = require'luna'

local list = class {
	
	__construct = function (this, ...)
		this.items = {}
	end,
	
	__index = function (this, index)
		return this.items[index]
	end,
	
	__newindex = function (this, index, value)
		this.items[index] = value
	end,
	
	Count = {get = function (this) return #this.items end},
	
	IndexOf = function (this, item, n)
		for i = n or 1, #this.items do
			if this.items[i] == item then
				return i
			end
		end
	end,
	
	Add = function (this, item)
		table.insert(this.items, item)
	end,
	
	Remove = function (this, item)
		table.remove(this.items, this.IndexOf(item))
	end,
	
	RemoveAt = function (this, index)
		table.remove(this.items, index)
	end,
	
	ToArray = function (this)
		return this.items
	end
}

