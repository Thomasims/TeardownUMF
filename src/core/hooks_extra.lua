----------------
-- @submodule core.hooks_base
UMF_REQUIRE "/"

--- Checks if the player is in a vehicle.
---
---@return boolean
function IsPlayerInVehicle()
	return GetBool( "game.player.usevehicle" )
end

local tool = GetString( "game.player.tool" )
local invehicle = IsPlayerInVehicle()

local keyboardkeys = { "esc", "up", "down", "left", "right", "space", "interact", "return" }
for i = 97, 97 + 25 do
	keyboardkeys[#keyboardkeys + 1] = string.char( i )
end
local function checkkeys( func, mousehook, keyhook )
	if hook.used( keyhook ) and func( "any" ) then
		for i = 1, #keyboardkeys do
			if func( keyboardkeys[i] ) then
				hook.saferun( keyhook, keyboardkeys[i] )
			end
		end
	end
	if hook.used( mousehook ) then
		if func( "lmb" ) then
			hook.saferun( mousehook, "lmb" )
		end
		if func( "rmb" ) then
			hook.saferun( mousehook, "rmb" )
		end
	end
end

local mousekeys = { "lmb", "rmb", "mmb" }
local logicalinputs = {
	"up",
	"down",
	"left",
	"right",
	"interact",
	"flashlight",
	"jump",
	"crouch",
	"usetool",
	"grab",
	"handbrake",
	"map",
	"pause",
	"vehicleraise",
	"vehiclelower",
	"vehicleaction",
	"camerax",
	"cameray",
}
local heldkeys = {}

hook.add( "base.tick", "api.default_hooks", function()
	if InputLastPressedKey then
		if hook.used( "api.mouse.pressed" ) or hook.used( "api.mouse.released" ) then
			for i = 1, #mousekeys do
				local k = mousekeys[i]
				if InputPressed( k ) then
					hook.saferun( "api.mouse.pressed", k )
				elseif InputReleased( k ) then
					hook.saferun( "api.mouse.released", k )
				end
			end
		end
		if hook.used( "api.input.pressed" ) or hook.used( "api.input.released" ) then
			for i = 1, #logicalinputs do
				local k = logicalinputs[i]
				if InputPressed( k ) then
					hook.saferun( "api.input.pressed", k )
				elseif InputReleased( k ) then
					hook.saferun( "api.input.released", k )
				end
			end
		end
		if hook.used( "api.key.pressed" ) or hook.used( "api.key.released" ) then
			local lastkey = InputLastPressedKey()
			if lastkey ~= "" then
				heldkeys[lastkey] = true
				hook.saferun( "api.key.pressed", lastkey )
			end
			for key in pairs( heldkeys ) do
				if not InputDown( key ) then
					heldkeys[key] = nil
					hook.saferun( "api.key.released", key )
					break
				end
			end
		end
		if hook.used( "api.mouse.wheel" ) then
			local wheel = InputValue( "mousewheel" )
			if wheel ~= 0 then
				hook.saferun( "api.mouse.wheel", wheel )
			end
		end
		if hook.used( "api.mouse.move" ) then
			local mousedx = InputValue( "mousedx" )
			local mousedy = InputValue( "mousedy" )
			if mousedx ~= 0 or mousedy ~= 0 then
				hook.saferun( "api.mouse.move", mousedx, mousedy )
			end
		end
		if hook.used( "api.input.camera" ) then
			local camerax = InputValue( "camerax" )
			local cameray = InputValue( "cameray" )
			if camerax ~= 0 or cameray ~= 0 then
				hook.saferun( "api.input.camera", camerax, cameray )
			end
		end
	elseif InputPressed then
		checkkeys( InputPressed, "api.mouse.pressed", "api.key.pressed" )
		checkkeys( InputReleased, "api.mouse.released", "api.key.released" )
		local wheel = InputValue( "mousewheel" )
		if wheel ~= 0 then
			hook.saferun( "api.mouse.wheel", wheel )
		end
		local mousedx = InputValue( "mousedx" )
		local mousedy = InputValue( "mousedy" )
		if mousedx ~= 0 or mousedy ~= 0 then
			hook.saferun( "api.mouse.move", mousedx, mousedy )
		end
	end

	local n_invehicle = IsPlayerInVehicle()
	if invehicle ~= n_invehicle then
		hook.saferun( n_invehicle and "api.player.enter_vehicle" or "api.player.exit_vehicle",
		              n_invehicle and GetPlayerVehicle() )
		invehicle = n_invehicle
	end

	local n_tool = GetString( "game.player.tool" )
	if tool ~= n_tool then
		hook.saferun( "api.player.switch_tool", n_tool, tool )
		tool = n_tool
	end
end )
