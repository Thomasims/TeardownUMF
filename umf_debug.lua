--------------------------------------------------------------------------------
-- This file is NOT to be used in released mods, use build.lua for that purpose.
-- Only use this if you are testing UMF changes locally.
--
-- Note: This file MUST be loaded using #include
--------------------------------------------------------------------------------
local function SplitPath( filepath )
	return filepath:match( "^(.-/?)([^/]+)$" )
end

local function GetCurrentDirectory()
	local _, errpath = pcall( error, "-", 2 )
	local curpath = errpath:match( "^%[string \"...([^\"]*)/umf_debug.lua\"%]:%d+: %-$" )

	local matches = {}
	while curpath and #curpath > 0 do
		matches[#matches + 1] = curpath
		curpath = curpath:match( "^(.-)/[^/]*$" )
	end

	for i, key in ipairs( ListKeys( "mods.available" ) ) do
		local path = GetString( "mods.available." .. key .. ".path" )
		for j, subpath in ipairs( matches ) do
			if path:sub( -#subpath ) == subpath then
				return path:sub( 1, -#subpath - 1 ) .. matches[1]
			end
		end
	end
end

local loaded = {}
local includestack = { GetCurrentDirectory() .. "/" }

function UMF_REQUIRE( filepath )
	local root = includestack[#includestack]
	local realpath
	local f
	while true do
		realpath = root .. filepath
		f = loadfile( realpath )
		if not f then
			realpath = realpath:match( "(.-)/*$" ) .. "/_index.lua"
			f = loadfile( realpath )
		end
		if f or root == "" then
			break
		end
		root = root:match( "(.-)[^/]*/+$" ) or ""
	end
	if not f or loaded[realpath] then
		return loaded[realpath]
	end
	local res = { path = realpath, dump = string.dump( f ) }
	loaded[realpath] = res
	local subroot = SplitPath( realpath )
	includestack[#includestack + 1] = subroot
	local s, e = pcall( f )
	if not s then
		DebugPrint( tostring( e ) )
	end
	includestack[#includestack] = nil
	res.result = e
	return e
end

local __RUNLATER = {}
function UMF_RUNLATER( code )
	__RUNLATER[#__RUNLATER + 1] = code
end

UMF_REQUIRE "src"

for i = 1, #__RUNLATER do
	local f = loadstring( __RUNLATER[i] )
	if f then
		pcall( f )
	end
end

-- IDEA: use loaded to auto refresh
