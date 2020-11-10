
util = {}

do
	local serialize_any, serialize_table

	serialize_table = function(val, bck)
		if bck[val] then return "nil" end
		bck[val] = true
		local entries = {}
		for k, v in pairs(val) do
			entries[#entries+1] = string.format("[%s] = %s", serialize_any(k, bck), serialize_any(v, bck))
		end
		return string.format("{%s}", table.concat(entries, ","))
	end

	serialize_any = function(val, bck)
		if type(val) == "table" then
			return serialize_table(val, bck)
		elseif type(val) == "string" then
			return string.format("%q", val)
		else
			return tostring(val)
		end
	end

	function util.serialize(...)
		local result = {}
		for i = 1, select("#", ...) do
			result[i] = serialize_any(select(i, ...), {})
		end
		return table.concat(result, ",")
	end
end

function util.unserialize(dt)
	local fn = loadstring("return " .. dt)
	if fn then
		setfenv(fn, {})
		return fn()
	end
end

function util.shared_buffer(name, max)
	return {
		_pos_name = name .. ".position",
		_list_name = name .. ".list.",
		push = function(self, text)
			local cpos = GetInt(self._pos_name)
			SetString(self._list_name .. (cpos % max), text)
			SetInt(self._pos_name, cpos + 1)
		end,
		len = function(self)
			return math.min(GetInt(self._pos_name), max)
		end,
		pos = function(self)
			return GetInt(self._pos_name)
		end,
		get = function(self, index)
			local pos = GetInt(self._pos_name)
			local len = math.min(pos, max)
			if index >= len then return end
			return GetString(self._list_name .. (pos + index - len) % max)
		end,
		get_g = function(self, index)
			return GetString(self._list_name .. (index % max))
		end,
		clear = function(self)
			SetInt(self._pos_name, 0)
			ClearKey(self._list_name:sub(1, -2))
		end
	}
end

do

	local gets, sets = {}, {}

	function util.shared_table(name)
		return setmetatable({}, {
			__index = function(self, k)
				local key = tostring(k)
				local vtype = GetString(string.format("%s.%s.type", name, key))
				if vtype == "" then return end
				return gets[vtype](string.format("%s.%s.val", name, key))
			end,
			__newindex = function(self, k, v)
				local vtype = type(v)
				local handler = sets[vtype]
				if not handler then return end
				local key = tostring(k)
				SetString(string.format("%s.%s.type", name, key), vtype)
				handler(string.format("%s.%s.val", name, key), v)
			end,
		})
	end

	gets.number = GetFloat
	gets.boolean = GetBool
	gets.string = GetString
	gets.table = util.shared_table

	sets.number = SetFloat
	sets.boolean = SetBool
	sets.string = SetString
	sets.table = function(key, val)
		local tab = util.shared_table(key)
		for k, v in pairs(val) do
			tab[k] = v
		end
	end

end