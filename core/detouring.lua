local original = {}
local function call_original( name, ... )
	local fn = original[name]
	if fn then
		return fn( ... )
	end
end

local detoured = {}
function DETOUR( name, generator )
	original[name] = _G[name]
	detoured[name] = generator( function( ... )
		return call_original( name, ... )
	end )
	rawset( _G, name, nil )
end

setmetatable( _G, {
	__index = detoured,
	__newindex = function( self, k, v )
		if detoured[k] then
			original[k] = v
		else
			rawset( self, k, v )
		end
	end,
} )
