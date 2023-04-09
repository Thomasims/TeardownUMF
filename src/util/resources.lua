----------------
-- Resources Utilities
-- @script util.resources
UMF_REQUIRE "debug.lua"

util = util or {}

local mod
do
	local stack = util.stacktrace()
	local function findmods( file )
		local matches = {}
		while file and #file > 0 do
			matches[#matches + 1] = file
			file = file:match( "^(.-)/[^/]*$" )
		end

		local found
		for _, key in ipairs( ListKeys( "mods.available" ) ) do
			local path = GetString( "mods.available." .. key .. ".path" )
			for _, subpath in ipairs( matches ) do
				if path:sub( -#subpath ) == subpath then
					if found then
						return
					end
					found = key
					break
				end
			end
		end
		return found
	end
	for i = 1, #stack do
		if stack[i] ~= "[C]:?" then
			local t = stack[i]:match( "%[string \"%.%.%.(.*)\"%]:%d+" ) or stack[i]:match( "%.%.%.(.*):%d+" )
			if t then
				local found = findmods( t )
				if found then
					mod = found
					MOD = found
					break
				end
			end
		end
	end
end

--- Resolves a given mod path to an absolute path.
---
---@param path string
---@return string path Absolute path
function util.resolve_path( path )
	-- TODO: support relative paths (relative to the current file)
	-- TODO: return multiple matches if applicable
	local replaced, n = path:gsub( "^MOD/", GetString( "mods.available." .. mod .. ".path" ) .. "/" )
	if n == 0 then
		replaced, n = path:gsub( "^LEVEL/", GetString( "game.levelpath" ):sub( 1, -5 ) .. "/" )
	end
	if n == 0 then
		replaced, n = path:gsub( "^MODS/([^/]+)", function( mod )
			return GetString( "mods.available." .. mod .. ".path" )
		end )
	end
	if n == 0 then
		return path
	end
	return replaced
end

--- Load a lua file from its mod path.
---
---@param path string
---@return function?
---@return string? error_message
function util.load_lua_resource( path )
	return loadfile( util.resolve_path( path ) )
end
