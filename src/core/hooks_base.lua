----------------
-- Default hooks
-- @script core.hooks_base
UMF_REQUIRE "/"
UMF_REQUIRE "util/detouring.lua"
UMF_RUNLATER "UpdateQuickloadPatch()"

local hook = hook

local function checkoriginal( b, ... )
	if not b then
		printerror( ... )
		return
	end
	return ...
end

local function simple_detour( name )
	local event = "base." .. name
	DETOUR( name, function( original )
		return function( ... )
			hook.saferun( event, ... )
			return checkoriginal( pcall( original, ... ) )
		end

	end )
end

local detours = {
	"init", -- "base.init" (runs before init())
	"tick", -- "base.tick" (runs before tick())
	"update", -- "base.update" (runs before update())
}
for i = 1, #detours do
	simple_detour( detours[i] )
end

--- Tests if a UI element should be drawn.
---
---@param kind string
---@return boolean
function shoulddraw( kind )
	return hook.saferun( "api.shoulddraw", kind ) ~= false
end

DETOUR( "draw", function( original )
	return function( dt )
		if shoulddraw( "all" ) then
			hook.saferun( "base.predraw", dt )
			if shoulddraw( "original" ) then
				checkoriginal( pcall( original, dt ) )
			end
			hook.saferun( "base.draw", dt )
		end
	end

end )

DETOUR( "Command", function( original )
	return function( cmd, ... )
		hook.saferun( "base.precmd", cmd, { ... } )
		local a, b, c, d, e, f = original( cmd, ... )
		hook.saferun( "base.postcmd", cmd, { ... }, { a, b, c, d, e, f } )
	end

end )

------ QUICKSAVE WORKAROUND -----
-- Quicksaving stores a copy of the global table without functions, so libraries get corrupted on quickload
-- This code prevents this by overriding them back

local savedtypes = { ["function"] = true, ["userdata"] = true, ["thread"] = true }
local saved

local function searchtable(t, bck)
	if bck[t] then return end
	bck[t] = true
	local rt, dosave = {}, false
	for k, v in pairs(t) do
		local vt = type(v)
		if vt == "table" then
			local st = searchtable(v, bck)
			if st then
				dosave = true
				rt[k] = st
			end
		elseif savedtypes[vt] then
			dosave = true
			rt[k] = v
		end
	end
	bck[t] = false
	if dosave then
		return rt
	end
end

local function restoretable(t, dst)
	if not t then return end
	for k, v in pairs(t) do
		if type(v) == "table" then
			dst[k] = dst[k] or {}
			restoretable(v, dst[k])
		else
			dst[k] = v
		end
	end
end

--- Updates the list of libraries known by the Quickload Patch.
function UpdateQuickloadPatch()
	saved = searchtable(_G, {})
end

DETOUR( "handleCommand", function( original )
	return function( command, ... )
		if command == "quickload" then
			restoretable(saved, _G)
		end
		hook.saferun( "base.command." .. command, ... )
		return original( command, ... )
	end
end )

--------------------------------

hook.add( "base.tick", "api.firsttick", function()
	hook.remove( "base.tick", "api.firsttick" )
	hook.saferun( "api.firsttick" )
	if type( firsttick ) == "function" then
		firsttick()
	end
end )
