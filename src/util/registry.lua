----------------
-- Registry Utilities
-- @script util.registry
local coreloaded = UMF_SOFTREQUIRE "core"

util = util or {}

do
	local serialize_any, serialize_table

	serialize_table = function( val, bck )
		if bck[val] then
			return "nil"
		end
		bck[val] = true
		local entries = {}
		for k, v in pairs( val ) do
			entries[#entries + 1] = string.format( "[%s] = %s", serialize_any( k, bck ), serialize_any( v, bck ) )
		end
		return string.format( "{%s}", table.concat( entries, "," ) )
	end

	serialize_any = function( val, bck )
		local vtype = type( val )
		if vtype == "table" then
			return serialize_table( val, bck )
		elseif vtype == "string" then
			return string.format( "%q", val )
		elseif vtype == "function" or vtype == "userdata" then
			return string.format( "nil --[[%s]]", tostring( val ) )
		else
			return tostring( val )
		end
	end

	--- Serializes something to a lua-like string.
	---
	---@vararg any
	---@return string
	function util.serialize( ... )
		local result = {}
		for i = 1, select( "#", ... ) do
			result[i] = serialize_any( select( i, ... ), {} )
		end
		return table.concat( result, "," )
	end
end

--- Unserializes something from a lua-like string.
---
---@param dt string
---@return ...
function util.unserialize( dt )
	local fn = loadstring( "return " .. dt )
	if fn then
		setfenv( fn, {} )
		return fn()
	end
end

do
	local function serialize_any( val, bck )
		local vtype = type( val )
		if vtype == "table" then
			if bck[val] then
				return "{}"
			end
			bck[val] = true
			local len = 0
			for k, v in pairs( val ) do
				len = len + 1
			end
			local rt = {}
			if len == #val then
				for i = 1, #val do
					rt[i] = serialize_any( val[i], bck )
				end
				return string.format( "[%s]", table.concat( rt, "," ) )
			else
				for k, v in pairs( val ) do
					if type( k ) == "string" or type( k ) == "number" then
						rt[#rt + 1] = string.format( "%s: %s", serialize_any( k, bck ), serialize_any( v, bck ) )
					end
				end
				return string.format( "{%s}", table.concat( rt, "," ) )
			end
		elseif vtype == "string" then
			return string.format( "%q", val )
		elseif vtype == "function" or vtype == "userdata" or vtype == "nil" then
			return "null"
		else
			return tostring( val )
		end
	end

	--- Serializes something to a JSON string.
	---
	---@param val any
	---@return string
	function util.serializeJSON( val )
		return serialize_any( val, {} )
	end
end

--- Creates a buffer shared via the registry.
---
---@param name string
---@param max? number
---@return table
function util.shared_buffer( name, max )
	max = max or 64
	return {
		_pos_name = name .. ".position",
		_list_name = name .. ".list.",
		push = function( self, text )
			local cpos = GetInt( self._pos_name )
			SetString( self._list_name .. (cpos % max), text )
			SetInt( self._pos_name, cpos + 1 )
		end,
		len = function( self )
			return math.min( GetInt( self._pos_name ), max )
		end,
		pos = function( self )
			return GetInt( self._pos_name )
		end,
		get = function( self, index )
			local pos = GetInt( self._pos_name )
			local len = math.min( pos, max )
			if index >= len then
				return
			end
			return GetString( self._list_name .. (pos + index - len) % max )
		end,
		iterator = function( self )
			local pos = GetInt( self._pos_name )
			local len = math.min( pos, max )
			return function( _, i )
				i = (i or 0) + 1
				if i >= len then
					return
				end
				return i, GetString( self._list_name .. (pos + i - len) % max )
			end
		end,
		get_g = function( self, index )
			return GetString( self._list_name .. (index % max) )
		end,
		clear = function( self )
			SetInt( self._pos_name, 0 )
			ClearKey( self._list_name:sub( 1, -2 ) )
		end,
	}
end

if coreloaded then
	--- Creates a channel shared via the registry.
	---
	---@param name string Name of the channel.
	---@param max? number Maximum amount of unread messages in the channel.
	---@param local_realm? string Name to use to identify the local recipient.
	---@return table
	function util.shared_channel( name, max, local_realm )
		max = max or 64
		local channel = {
			_buffer = util.shared_buffer( name, max ),
			_offset = 0,
			_hooks = {},
			_ready_count = 0,
			_ready = {},
			broadcast = function( self, ... )
				return self:send( "", ... )
			end,
			send = function( self, realm, ... )
				self._buffer:push( string.format( ",%s,;%s",
				                                  (type( realm ) == "table" and table.concat( realm, "," ) or tostring( realm )),
				                                  util.serialize( ... ) ) )
			end,
			listen = function( self, callback )
				if self._ready[callback] ~= nil then
					return
				end
				self._hooks[#self._hooks + 1] = callback
				self:ready( callback )
				return callback
			end,
			unlisten = function( self, callback )
				self:unready( callback )
				self._ready[callback] = nil
				for i = 1, #self._hooks do
					if self._hooks[i] == callback then
						table.remove( self._hooks, i )
						return true
					end
				end
			end,
			ready = function( self, callback )
				if not self._ready[callback] then
					self._ready_count = self._ready_count + 1
					self._ready[callback] = true
				end
			end,
			unready = function( self, callback )
				if self._ready[callback] then
					self._ready_count = self._ready_count - 1
					self._ready[callback] = false
				end
			end,
		}
		local_realm = "," .. (local_realm or "unknown") .. ","
		local function receive( ... )
			for i = 1, #channel._hooks do
				local f = channel._hooks[i]
				if channel._ready[f] then
					f( channel, ... )
				end
			end
		end
		hook.add( "base.tick", name, function( dt )
			if channel._ready_count > 0 then
				local last_pos = channel._buffer:pos()
				if last_pos > channel._offset then
					for i = math.max( channel._offset, last_pos - max ), last_pos - 1 do
						local message = channel._buffer:get_g( i )
						local start = message:find( ";", 1, true )
						local realms = message:sub( 1, start - 1 )
						if realms == ",," or realms:find( local_realm, 1, true ) then
							receive( util.unserialize( message:sub( start + 1 ) ) )
							if channel._ready_count <= 0 then
								channel._offset = i + 1
								return
							end
						end
					end
					channel._offset = last_pos
				end
			end
		end )
		return channel
	end

	--- Creates an async reader on a channel for coroutines.
	---
	---@param channel table Name of the channel.
	---@return table
	function util.async_channel( channel )
		local listener = {
			_channel = channel,
			_waiter = nil,
			read = function( self )
				self._waiter = coroutine.running()
				if not self._waiter then
					error( "async_channel:read() can only be used in a coroutine" )
				end
				self._channel:ready( self._handler )
				return coroutine.yield()
			end,
			close = function( self )
				if self._handler then
					self._channel:unlisten( self._handler )
				end
			end,
		}
		listener._handler = listener._channel:listen( function( _, ... )
			if listener._waiter then
				local co = listener._waiter
				listener._waiter = nil
				listener._channel:unready( listener._handler )
				return coroutine.resume( co, ... )
			end
		end )
		listener._channel:unready( listener._handler )
		return listener
	end
end

do

	local gets, sets = {}, {}

	--- Registers a type unserializer.
	---
	---@param type string
	---@param callback fun(data: string): any
	function util.register_unserializer( type, callback )
		gets[type] = function( key )
			return callback( GetString( key ) )
		end
	end

	if coreloaded then
		hook.add( "api.newmeta", "api.createunserializer", function( name, meta )
			gets[name] = function( key )
				return setmetatable( {}, meta ):__unserialize( GetString( key ) )
			end
			sets[name] = function( key, value )
				return SetString( key, meta.__serialize( value ) )
			end
		end )
	end

	--- Creates a table shared via the registry.
	---
	---@param name string
	---@param base? table
	---@return table
	function util.shared_table( name, base )
		return setmetatable( base or {}, {
			__index = function( self, k )
				local key = tostring( k )
				local vtype = GetString( string.format( "%s.%s.type", name, key ) )
				if vtype == "" then
					return
				end
				return gets[vtype]( string.format( "%s.%s.val", name, key ) )
			end,
			__newindex = function( self, k, v )
				local vtype = type( v )
				local handler = sets[vtype]
				if not handler then
					return
				end
				local key = tostring( k )
				if vtype == "table" then
					local meta = getmetatable( v )
					if meta and meta.__serialize and meta.__type then
						vtype = meta.__type
						v = meta.__serialize( v )
						handler = sets.string
					end
				end
				SetString( string.format( "%s.%s.type", name, key ), vtype )
				handler( string.format( "%s.%s.val", name, key ), v )
			end,
		} )
	end

	--- Creates a table shared via the registry with a structure.
	---
	---@param name string
	---@param base table
	---@return table
	---@overload fun(name: string): fun(base: table): table
	function util.structured_table( name, base )
		local function generate( base )
			local root = {}
			local keys = {}
			for k, v in pairs( base ) do
				local key = name .. "." .. tostring( k )
				if type( v ) == "table" then
					if #v == 0 then
						root[k] = util.structured_table( key, v )
					else
						keys[k] = { type = v[1], key = key, default = v[2] }
					end
				elseif type( v ) == "string" then
					keys[k] = { type = v, key = key }
				else
					root[k] = v
				end
			end
			return setmetatable( root, {
				__index = function( self, k )
					local entry = keys[k]
					if entry and gets[entry.type] then
						if HasKey( entry.key ) then
							return gets[entry.type]( entry.key )
						else
							return entry.default
						end
					end
				end,
				__newindex = function( self, k, v )
					local entry = keys[k]
					if entry and sets[entry.type] then
						return sets[entry.type]( entry.key, v )
					end
				end,
			} )
		end
		if type( base ) == "table" then
			return generate( base )
		end
		return generate
	end

	gets.number = GetFloat
	gets.integer = GetInt
	gets.boolean = GetBool
	gets.string = GetString
	gets.table = util.shared_table

	sets.number = SetFloat
	sets.integer = SetInt
	sets.boolean = SetBool
	sets.string = SetString
	sets.table = function( key, val )
		local tab = util.shared_table( key )
		for k, v in pairs( val ) do
			tab[k] = v
		end
	end

end
