--------------------------------------------------------------------------------
-- This file is NOT to be used in released mods, use build.lua for that purpose.
-- Only use this if you are testing UMF changes locally.
--
-- Note: This file MUST be loaded using #include
--------------------------------------------------------------------------------
local function SplitPath( filepath )
	return filepath:match( "^(.-/?)([^/]+)$" )
end

local function GetCurrentDirectory( level )
	local _, errpath = pcall( error, "-", 2 + (level or 0) )
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

local function NotFound( f, err )
	return not f and err and err:sub( 1, 11 ) == "cannot open"
end

local loaded = {}
local currentdir
function UMF_REQUIRE( filepath, isAbsolute )
	local f, err, realpath
	if isAbsolute then
		realpath = filepath
		f, err = loadfile( realpath )
	else
		local root = currentdir or (GetCurrentDirectory( 1 ) .. "/")
		while true do
			realpath = root .. filepath
			f, err = loadfile( realpath )
			if NotFound( f, err ) then
				realpath = realpath:match( "(.-)/*$" ) .. "/_index.lua"
				f, err = loadfile( realpath )
			end
			if not NotFound( f, err ) or root == "" then
				break
			end
			root = root:match( "(.-)[^/]*/+$" ) or ""
		end
	end
	if not f then
		print( err )
		DebugPrint( err )
		return loaded[realpath] and loaded[realpath].result or err
	end
	local dump = string.dump( f )
	if loaded[realpath] and loaded[realpath].dump == dump then
		return loaded[realpath].result
	end
	local res = { path = realpath, dump = dump }
	loaded[realpath] = res
	local prevdir = currentdir
	currentdir = SplitPath( realpath )
	local s, e = pcall( f )
	if not s then
		print( e )
		DebugPrint( e )
	end
	currentdir = prevdir
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

if hook then
	function UMF_AUTOREFRESH( enabled )
		if enabled then
			local last = GetTime()
			hook.add( "base.tick", "api.autorefresh", function()
				local now = GetTime()
				if now - last >= 1 then
					last = now
					for k, v in pairs( loaded ) do
						UMF_REQUIRE( v.path, true )
					end
				end
			end )
		else
			hook.remove( "base.tick", "api.autorefresh" )
		end
	end
end
