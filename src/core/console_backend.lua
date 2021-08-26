UMF_REQUIRE "util/registry.lua"
UMF_REQUIRE "util/debug.lua"

local console_buffer = util.shared_buffer( "game.console", 128 )

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
--- Prints its arguments in the specified color to the console.
--- Also prints to the screen if global `PRINTTOSCREEN` is set to true.
---
---@param r number
---@param g number
---@param b number
function printcolor( r, g, b, ... )
	local text = maketext( ... )
	console_buffer:push( string.format( "%f;%f;%f;%s", r, g, b, text ) )
	-- TODO: Use color
	if PRINTTOSCREEN then
		DebugPrint( text )
	end
	return _OLDPRINT( ... )
end

--- Prints its arguments to the console.
--- Also prints to the screen if global `PRINTTOSCREEN` is set to true.
function print( ... )
	printcolor( 1, 1, 1, ... )
end

--- Prints its arguments to the console.
--- Also prints to the screen if global `PRINTTOSCREEN` is set to true.
function printinfo( ... )
	printcolor( 0, .6, 1, ... )
end

--- Prints a warning and the current stacktrace to the console.
--- Also prints to the screen if global `PRINTTOSCREEN` is set to true.
---
---@param msg any
function warning( msg )
	printcolor( 1, .7, 0, "[WARNING] " .. tostring( msg ) .. "\n  " .. table.concat( util.stacktrace( 1 ), "\n  " ) )
end

printwarning = warning

--- Prints its arguments to the console.
--- Also prints to the screen if global `PRINTTOSCREEN` is set to true.
function printerror( ... )
	printcolor( 1, .2, 0, ... )
end

--- Clears the UMF console buffer.
function clearconsole()
	console_buffer:clear()
end

--- To be used with `pcall`, checks success value and prints the error if necessary.
---
---@param b boolean
---@return any
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

