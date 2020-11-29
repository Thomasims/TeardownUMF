
function IsPlayerInVehicle()
	return GetBool("game.player.usevehicle")
end

local tool = GetString("game.player.tool")
local invehicle = IsPlayerInVehicle()

hook.add("base.tick", "api.default_hooks", function()
	if UiIsMousePressed then
		if UiIsMousePressed() then hook.saferun("api.mouse.pressed") end
		if UiIsMouseReleased() then hook.saferun("api.mouse.released") end
		local wheel = UiGetMouseWheel()
		if wheel and wheel ~= 0 then hook.saferun("api.mouse.wheel", wheel) end
	end

	local n_invehicle = IsPlayerInVehicle()
	if invehicle ~= n_invehicle then
		hook.saferun(n_invehicle and "api.player.enter_vehicle" or "api.player.exit_vehicle", n_invehicle and GetPlayerVehicle())
		invehicle = n_invehicle
	end

	local n_tool = GetString("game.player.tool")
	if tool ~= n_tool then
		hook.saferun("api.player.switch_tool", n_tool, tool)
		tool = n_tool
	end
end)