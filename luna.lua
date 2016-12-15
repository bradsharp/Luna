--[[

	luna class library https://github.com/BradSharp/luna
	MIT License Copyright (c) 2016 Brad Sharp

]]

if not (setfenv or getfenv) then
	local envs = setmetatable({}, {__mode = "k"}) -- Annoying work around
	local getinfo = debug.getinfo
	local getupvalue = debug.getupvalue
	local upvaluejoin = debug.upvaluejoin
	setfenv = function (fn, env)
	    fn = type(fn) == "function" and fn or
			getinfo(fn and fn + 1 or 1, "f").func
		envs[fn] = env
	    local i = 1 repeat
            local name = getupvalue(fn, i)
            if name == "_ENV" then
                upvaluejoin(fn, i, (function()
	                return env
	            end), 1)
                break
            elseif name == nil then
                break
            end
            i = i + 1
        until false
	end
	getfenv = function (fn)
		fn = type(fn) == "function" and fn or
			getinfo(fn and fn + 1 or 1, "f").func
		if envs[fn] then
			return envs[fn]
		end
        local i = 1 repeat
            local name, value = getupvalue(fn, i)
            if name == "_ENV" then
                return value
            elseif name == nil then
                break
            end
            i = i + 1
        until false
	end
end

function createObject(definitionWrap, ...)
	local definition = definitionWrap.__definition
	local object = {__properties = {}, __private = {}}
	setmetatable(object, definition.__metatable)
	local constructor = definition.__construct
	if constructor then
		constructor(object, ...)
	end
	return object
end

function getIndex(definition, index)
	local value = rawget(definition, index)
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

	local definitionBase = {
		GetProperties = function (wrapper)
			local definition = wrapper.__definition
			local properties = {}
			for i, v in pairs(definition) do
				if string.sub(i, 1, 2) ~= "__" then
					local valueType = type(v)
					if valueType == "table" then
						if not (v.set or v.get) then
							properties[i] = v
						end
					elseif valueType ~= "function" then
						properties[i] = v
					end
				end
			end
			return properties
		end,

		GetMetamethods = function (wrapper)
			local definition = wrapper.__definition
			local methods = {}
			for i, v in pairs(definition) do
				if string.sub(i, 1, 2) == "__" then
					local valueType = type(v)
					if valueType == "function" then
						methods[i] = v
					end
				end
			end
			return methods
		end,

		GetMethods = function (wrapper)
			local definition = wrapper.__definition
			local methods = {}
			for i, v in pairs(definition) do
				if string.sub(i, 1, 2) ~= "__" then
					local valueType = type(v)
					if valueType == "function" then
						methods[i] = v
					end
				end
			end
			return methods
		end,

		GetAccessors = function (wrapper)
			local definition = wrapper.__definition
			local accessors = {}
			for i, v in pairs(definition) do
				local valueType = type(v)
				if valueType == "table" then
					if v.get then
						accessors[i] = v.get
					end
				end
			end
			return accessors
		end,

		GetMutators = function (wrapper)
			local definition = wrapper.__definition
			local mutators = {}
			for i, v in pairs(definition) do
				local valueType = type(v)
				if valueType == "table" then
					if v.set then
						mutators[i] = v.set
					end
				end
			end
			return mutators
		end
	}

	local function definitionIndex(wrapper, index)
		if definitionBase[index] then
			return definitionBase[index]
		else
			return getIndex(wrapper.__definition, index)
		end
	end
	local function throwIndexError()
		error("Definition is locked from editing", 2)
	end
	local definitionMetatable = {
		__call = createObject,
		__index = definitionIndex,
		__newindex = throwIndexError
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
	local function privenv(fn, priv)
		local env = getfenv(fn)
		setfenv(fn, setmetatable(priv, {
			__index = env,
			__newindex = env
		}))
	end
	function constructClass(definition, inherits)
		local wrapper = {__definition = definition}
		do local priv = {
				base = wrapper,
				__priv = true
			}
			for i, v in pairs(definition) do
				if type(i) ~= "string" then
					error("Invalid index " .. tostring(i) ..
						" for " .. tostring(v), 2)
				else
					local valueType = type(v)
					if valueType == "userdata" then
						error("Attempt to create property " .. i ..
							" of type userdata use an accessor instead", 2)
					elseif valueType == "function" then
						privenv(v, duplicateTable(priv))
					elseif type(v) == "table" then
						if v.get then privenv(v.get, duplicateTable(priv)) end
						if v.set then privenv(v.set, duplicateTable(priv)) end
					end
				end
			end
		end
		definition.__inherits = {}
		for _, v in ipairs(inherits or {}) do
			table.insert(definition.__inherits, v.__definition)
		end
		local metamethods = getMetamethods(definition)
		local metatable = {
			__index = function (this, index)
				if string.sub(index, 1, 2) == "__" then
					error("Metaindexing is forbidden", 2)
				end
				local public = rawget(this, "__properties")
				local value = public[index]
				if value then
					return value
				else -- It doesn't exist, it's a function or, an accessor
					value = getIndex(definition, index)
					if value then
						local valueType = type(value)
						if valueType == "function" then
							return value
						elseif valueType == "table" then
							if value.get then
								return value.get(this)
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
					else
						do
							local env = getfenv(2)
							if env and env.__priv then
								return rawget(this, "__private")[index]
							end
						end
						print(metamethods.__index)
						if metamethods.__index then
							return metamethods.__index(this, index)
                    	else
							error("'" .. index .. "' is not a valid member of "
								.. tostring(this), 2)
						end
					end
				end
			end,
			__newindex = function (this, index, value)
				if string.sub(index, 1, 2) == "__" then
					error("Metaindexing is forbidden", 2)
				end
				if metamethods.__newindex then
					if metamethods.__newindex(this, index, value) then
						return
					end
				end
				local public = rawget(this, "__properties")
				local currentValue = public[index]
				if currentValue then
					local newValue = convertType(value, type(currentValue))
					if newValue then
						public[index] = newValue
					else
						error("Incompatible type", 1)
					end
				else
					currentValue = getIndex(definition, index)
					if currentValue then
						local currentValueType = type(currentValue)
						local newValue = convertType(value, currentValueType)
						local valueType = type(value)
						if currentValueType == "table" and currentValue.set then
							currentValue.set(this, value)
						elseif valueType == "function" then
							error(index .. " is not a valid member of "
								.. tostring(this), 1)
						elseif newValue then
							public[index] = newValue
						else
							error("Incompatible type", 1)
						end
					else
						local internal do
							local env = getfenv(2)
							internal = env and env.__priv or false
						end
						if internal then
							local private = rawget(this, "__private")
							private[index] = value
						else
							error("'" .. index .. "' is not a valid member of "
								.. tostring(this), 1)
						end
					end
				end
			end,
			__call = function ()
				return definition
			end
		}
		for i, v in pairs(metamethods) do
			local method = string.sub(i, 3)
			if not (method == "index" or method == "newindex"
				or method == "call") then
				metatable[i] = v
			end
		end
		definition.__construct = metamethods.__construct
		definition.__metatable = metatable
		return setmetatable(wrapper, definitionMetatable)
	end
end

function class(...)
	local parameters = {...}
	if rawget(parameters[1], "__definition") then
		return function (definition)
			return constructClass(definition, parameters)
		end
	else
		return constructClass(parameters[1])
	end
end

return class
