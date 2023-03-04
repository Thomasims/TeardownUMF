----------------
-- Metatable Utilities
-- @script util.meta
local coreloaded = UMF_SOFTREQUIRE "core"

local registered_meta = {}
local reverse_meta = {}

--- Defines a new metatable type.
---
---@param name string
---@param parent? string
---@return table
function global_metatable( name, parent, usecomputed )
	local meta = registered_meta[name]
	if meta then
		if not parent and not usecomputed then
			return meta
		end
	else
		meta = {}
		meta.__index = meta
		meta.__type = name
		registered_meta[name] = meta
		reverse_meta[meta] = name
		if coreloaded then
			hook.saferun( "api.newmeta", name, meta )
		end
	end
	local newindex = rawset
	if usecomputed then
		local computed = {}
		meta._C = computed
		meta.__index = function( self, k )
			local c = computed[k]
			if c then
				return c( self )
			end
			return meta[k]
		end
		meta.__newindex = function( self, k, v )
			local c = computed[k]
			if c then
				return c( self, true, v )
			end
			return newindex( self, k, v )
		end
	end
	if parent then
		local parent_meta = global_metatable( parent )
		if parent_meta.__newindex then
			newindex = parent_meta.__newindex
			if not meta.__newindex then
				meta.__newindex = newindex
			end
		end
		setmetatable( meta, { __index = parent_meta.__index } )
	end
	return meta
end

--- Gets an existing metatable.
---
---@param name string
---@return table?
function find_global_metatable( name )
	if not name then
		return
	end
	if type( name ) == "table" then
		return reverse_meta[name]
	end
	return registered_meta[name]
end

local function findmeta( src, found )
	if found[src] then
		return
	end
	found[src] = true
	local res
	for k, v in pairs( src ) do
		if type( v ) == "table" then
			local dt
			local m = getmetatable( v )
			if m then
				local name = reverse_meta[m]
				if name then
					dt = {}
					dt[1] = name
				end
			end
			local sub = findmeta( v, found )
			if sub then
				dt = dt or {}
				dt[2] = sub
			end
			if dt then
				res = res or {}
				res[k] = dt
			end
		end
	end
	return res
end

function instantiate_global_metatable( name, base )
	local t = base or {}
	t.__UMF_GLOBAL_METATYPE = name
	setmetatable( t, find_global_metatable( name ) )
	return t
end

if coreloaded then
	local function restoremeta( t, explored )
		if explored[t] then return end
		explored[t] = true
		for _, v in pairs( t ) do
			if type( v ) == "table" then
				local meta_type = rawget( v, "__UMF_GLOBAL_METATYPE" )
				if meta_type then
					setmetatable( v, global_metatable( meta_type ) )
				end
				restoremeta( v, explored )
			end
		end
	end

	hook.add( "base.command.quickload", "api.metatables.restore", function()
		restoremeta( _G, {} )
	end )
end