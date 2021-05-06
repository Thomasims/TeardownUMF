local console_buffer = util.shared_buffer( "savegame.mod.console", 128 )

-- Console backend --

local function maketext( ... )
	local text = ""
	local len = select( "#", ... )
	for i = 1, len do
		local s = tostring( select( i, ... ) )
		if i < len then
			s = s .. string.rep( " ", 8 - #s % 8 )
		end
		text = text .. s
	end
	return text
end

_OLDPRINT = _OLDPRINT or print
function printcolor( r, g, b, ... )
	local text = string.format( "%f;%f;%f;%s", r, g, b, maketext( ... ) )
	console_buffer:push( text )
	return _OLDPRINT( ... )
end

function print( ... )
	printcolor( 1, 1, 1, ... )
end

function printinfo( ... )
	printcolor( 0, .6, 1, ... )
end

function warning( msg )
	printcolor( 1, .7, 0, "[WARNING] " .. tostring( msg ) .. "\n  " .. table.concat( util.stacktrace( 1 ), "\n  " ) )
end

printwarning = warning

function printerror( ... )
	printcolor( 1, .2, 0, ... )
end

function clearconsole()
	console_buffer:clear()
end

function softassert( b, ... )
	if not b then
		printerror( ... )
	end
	return b, ...
end

function assert( b, msg, ... )
	if not b then
		local m = msg or "Assertion failed"
		warning( m )
		return error( m, ... )
	end
	return b, msg, ...
end

