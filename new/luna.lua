--[[

	luna class library https://github.com/BradSharp/luna
	MIT License Copyright (c) 2016 Brad Sharp

]]

if not setfenv then -- Lua 5.2
	local function findenv(f)
	local level = 1
	repeat
		local name, value = debug.getupvalue(f, level)
		if name == '_ENV' then return level, value end
		level = level + 1
	until name == nil
	return nil end
	getfenv = function (f) return(select(2, findenv(f)) or _G) end
	setfenv = function (f, t)
		local level = findenv(f)
		if level then debug.setupvalue(f, level, t) end
		return f
	end
end

function createObject(definition, ...)
	local object = {__properties = {}, __private = {}}
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
	local function duplicateTable(t)
		local t2 = {}
		for i, v in pairs(t) do
			t2[i] = v
		end
		return t2
	end
	local function convertType(value, _type)
		local valueType = type(value)
		if _type == valueType then
			return value
		elseif _type == "string" then
			if valueType == "number" then
				return tostring(value)
			end
		elseif _type == "number" then
			if valueType == "string" then
				return tonumber(value)
			end
		end
	end
	function constructClass(definition, inherits, base)
		for i, v in pairs(definition) do
			assert(type(i) == "string",
				"Invalid index " .. tostring(i) .. " for " .. tostring(v))
			assert(type(v) ~= "userdata", "Attempt to create property "
				.. i .. " of type userdata use an accessor instead")
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
						elseif valueType == "table" then
							if value.get then
								return value.get(getWrapper(this))
							else
								local value = duplicateTable(value)
								public[index] = value
								return value
							end
						else
							-- Assign it to the object
							public[index] = value
							return value
						end
					elseif metamethods.__index then
						return metamethods.__index(getWrapper(this), index)
					elseif private then

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
					local newValue = convertType(value, type(currentValue))
					if newValue then
						public[index] = newValue
					else
						error("Incompatible type")
					end
				else
					currentValue = getIndex(definition, index)
					if currentValue then
						local currentValueType = type(currentValue)
						local newValue = convertType(value, currentValueType)
						local valueType = type(value)
						if currentValueType == "table" and currentValue.set then
							currentValue.set(getWrapper(this), value)
						elseif valueType == "function" then
							error(index .. " is not a valid member of "
								.. tostring(this))
						elseif newValue then
							public[index] = newValue
						else
							error("Incompatible type")
						end
					else
						error("'" .. index .. "' is not a valid member of "
							.. tostring(this))
					end
				end
			end,
			__call = function ()
				return definition
			end
		}
		-- Wrap the metamethods
		for i, v in pairs(metamethods) do
			local method = string.sub(i, 3)
			if not (method == "index" or method == "newindex"
				or method == "call") then
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
