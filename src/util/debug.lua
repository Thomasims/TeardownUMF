----------------
-- Debug Utilities
-- @script util.debug
util = util or {}

--- Gets the current line of code.
---
---@param level number stack depth
---@return string
function util.current_line( level )
	level = (level or 0) + 3
	local _, line = pcall( error, "-", level )
	if line == "-" then
		_, line = pcall( error, "-", level + 1 )
		if line == "-" then
			return
		end
		line = "[C]:?"
	else
		line = line:sub( 1, -4 )
	end
	return line
end

--- Gets the current stacktrack.
---
---@param start number starting stack depth
---@return string
function util.stacktrace( start )
	start = (start or 0) + 3
	local stack, last = {}, nil
	for i = start, 32 do
		local _, line = pcall( error, "-", i )
		if line == "-" then
			if last == "-" then
				break
			end
		else
			if last == "-" then
				stack[#stack + 1] = "[C]:?"
			end
			stack[#stack + 1] = line:sub( 1, -4 )
		end
		last = line
	end
	return stack
end
