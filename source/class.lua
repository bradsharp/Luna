--[[

	luna class library
	https://github.com/BradSharp/luna

	MIT License
	Copyright (c) 2016 Brad Sharp

]]

local createWrapper, getWrapper do
	local indexObj = function (object, index)
		return object[index]
	end
	local newIndexObj = function (object, index, value)
		object[index] = value
	end
	local metatable = {
		__call = function (this) return rawget(this, 1) end,

		__index = function (this, index)
			local value = rawget(this, 2)[index]
			if value then
				return value
			else
				local success, result = pcall(indexObj,
					rawget(this, 1), index)
				if success then
					if type(result) == "function" then
						-- Probably a better way to do this?
						return function (...)
							return result(this, ...)
						end
					else
						return result
					end
				else
					return nil
				end
			end
		end,

		__newindex = function (this, index, value)
			local private = rawget(this, 2)
			local currentValue = private[index]
			if currentValue then -- Change an existing value
				private[index] = value
			else -- Attempt to set an existing value from definition
				local success, result = pcall(
					newIndexObj, rawget(this, 1), index, value)
				if not success then
					if result == "Incompatible type" then
						error(result)
					else -- Create a new value
						private[index] = value
					end
				end
			end
		end,

		__add = function (this, other) return rawget(this, 1) + other end,
		__sub = function (this, other) return rawget(this, 1) - other end,
		__mul = function (this, other) return rawget(this, 1) * other end,
		__div = function (this, other) return rawget(this, 1) / other end,
		__mod = function (this, other) return rawget(this, 1) % other end,
		__pow = function (this, other) return rawget(this, 1) ^ other end,
		__unm = function (this) return -rawget(this, 1) end,

		__eq = function (this, other) return rawget(this, 1) == other end,
		__lt = function (this, other) return rawget(this, 1) < other end,
		__le = function (this, other) return rawget(this, 1) <= other end,

		__concat = function (this, ...) return rawget(this, 1) .. ... end,
		__tostring = function (this) return tostring(rawget(this, 1)) end,
		__len = function (this) return #rawget(this, 1) end,
	}
	local wrappers = setmetatable({}, {__mode="k"})
	function createWrapper(object)
		local wrapper = {object, {}}
		wrappers[object] = wrapper
		return setmetatable(wrapper, metatable)
	end
	function getWrapper(object)
		return wrappers[object]
	end
end

function createObject(definition, ...)
	local object = {__properties = {}}
	local wrapper = createWrapper(object)
	setmetatable(object, definition.__metatable)
	local constructor = definition.__construct
	if constructor then
		constructor(wrapper, ...)
	end
	return object
end

function getIndex(definition, index)
	local value = definition[index]
	if value then
		return value
	else
		for _, v in ipairs(definition.__inherits) do
			value = getIndex(v, index)
			if value then
				return value
			end
		end
	end
end

function getMetamethods(definition)
	local methods = {}
	local function recurse(def)
		for i, v in pairs(def) do
			if string.sub(i, 1, 2) == "__" then
				if not methods[i] then
					methods[i] = v
				end
			end
		end
		for _, v in ipairs(def.__inherits) do
			recurse(v)
		end
	end
	recurse(definition)
	return methods
end

local constructClass do
	local definitionMetatable = {
		__call = createObject,
	}
	function constructClass(definition, inherits)
		for i, v in pairs(definition) do
			assert(type(i) == "string",
				"Invalid property name " .. tostring(i))
			local vType = type(v)
			if vType == "table" then
				assert(v.set or v.get,
					"Tables must be defined using accessors and mutators")
			end
		end
		definition.__inherits = inherits or {}
		definition.__sharp = true
		local metamethods = getMetamethods(definition)
		local metatable = {
			__index = function (this, index)
				assert(string.sub(index, 1, 2) ~= "__",
					"Metaindexing is forbidden")
				local public = rawget(this, "__properties")
				local value = public[index]
				if value then
					return value
				else -- It doesn't exist, it's a function or, an accessor
					value = getIndex(definition, index)
					if value then
						local valueType = type(value)
						if valueType == "function" then
							local wrapper = getWrapper(this)
							return function (this, ...)
								return value(wrapper, ...)
							end
						elseif valueType == "table" and value.get then
							return value.get(getWrapper(this))
						else
							-- Assign it to the object
							public[index] = value
							return value
						end
					elseif metamethods.__index then
						return metamethods.__index(getWrapper(this), index)
					else
						error("'" .. index .. "' is not a valid member of "
							.. tostring(this))
					end
				end
			end,
			__newindex = function (this, index, value)
				assert(string.sub(index, 1, 2) ~= "__",
					"Metaindexing is forbidden")
				if metamethods.__newindex then
					metamethods.__newindex(getWrapper(this), index, value)
				end
				local public = rawget(this, "__properties")
				local currentValue = public[index]
				if currentValue then
					if type(value) == type(currentValue) then
						public[index] = value
					else
						error("Incompatible type")
					end
				else
					currentValue = getIndex(definition, index)
					if currentValue then
						local currentValueType = type(currentValue)
						local valueType = type(value)
						if currentValueType == "table" and currentValue.set then
							currentValue.set(getWrapper(this), value)
						elseif valueType == "function" then
							error("Can not set " .. index)
						elseif valueType == currentValueType then
							public[index] = value
						else
							error("Incompatible type")
						end
					else
						error("'" .. index .. "' is not a valid member of "
							.. tostring(this))
					end
				end
			end
		}
		-- Wrap the metamethods
		for i, v in pairs(metamethods) do
			local method = string.sub(i, 3)
			if not (method == "index" or method == "newindex") then
				metatable[i] = function (this, ...)
					return v(getWrapper(this), ...)
				end
			end
		end
		definition.__construct = metamethods.__construct
		definition.__metatable = metatable
		return setmetatable(definition, definitionMetatable)
	end
end

function class(...)
	local parameters = {...}
	if type(parameters[1] == "table") and
		rawget(parameters[1], "__sharp") then -- Inheritance
		return function (definition)
			return constructClass(definition, parameters)
		end
	else -- Definition
		return constructClass(parameters[1], {})
	end
end

return class
