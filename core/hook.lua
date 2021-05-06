if hook then
	return
end

local hook_table = {}
local hook_compiled = {}

local function recompile( event )
	local hooks = {}
	for k, v in pairs( hook_table[event] ) do
		hooks[#hooks + 1] = v
	end
	hook_compiled[event] = hooks
end

hook = { table = hook_table }

function hook.add( event, identifier, func )
	assert( type( event ) == "string", "Event must be a string" )
	if func then
		assert( identifier ~= nil, "Identifier must not be nil" )
		assert( type( func ) == "function", "Callback must be a function" )
	else
		assert( type( identifier ) == "function", "Callback must be a function" )
	end
	hook_table[event] = hook_table[event] or {}
	hook_table[event][identifier] = func or identifier
	recompile( event )
	return identifier
end

function hook.remove( event, identifier )
	assert( type( event ) == "string", "Event must be a string" )
	assert( identifier ~= nil, "Identifier must not be nil" )
	if hook_table[event] then
		hook_table[event][identifier] = nil
		if next( hook_table[event] ) == nil then
			hook_table[event] = nil
			hook_compiled[event] = nil
		else
			recompile( event )
		end
	end
end

function hook.run( event, ... )
	local hooks = hook_compiled[event]
	if not hooks then
		return
	end
	for i = 1, #hooks do
		local a, b, c, d, e = hooks[i]( ... )
		if a ~= nil then
			return a, b, c, d, e
		end
	end
end

function hook.saferun( event, ... )
	local hooks = hook_compiled[event]
	if not hooks then
		return
	end
	for i = 1, #hooks do
		local s, a, b, c, d, e = softassert( pcall( hooks[i], ... ) )
		if s and a ~= nil then
			return a, b, c, d, e
		end
	end
end

function hook.used( event )
	return hook_table[event]
end

