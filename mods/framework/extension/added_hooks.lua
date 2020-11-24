
function IsPlayerInVehicle()
	return GetBool("game.player.usevehicle")
end

local tool = GetString("game.player.tool")
local invehicle = IsPlayerInVehicle()

hook.add("base.tick", "api.default_hooks", function()
	if UiIsMousePressed then
		if UiIsMousePressed() then softassert(pcall(hook.run, "api.mouse.pressed")) end
		if UiIsMouseReleased() then softassert(pcall(hook.run, "api.mouse.released")) end
		local wheel = UiGetMouseWheel()
		if wheel and wheel ~= 0 then softassert(pcall(hook.run, "api.mouse.wheel", wheel)) end
	end

	local n_invehicle = IsPlayerInVehicle()
	if invehicle ~= n_invehicle then
		softassert(pcall(hook.run, n_invehicle and "api.player.enter_vehicle" or "api.player.exit_vehicle", n_invehicle and GetPlayerVehicle()))
		invehicle = n_invehicle
	end

	local n_tool = GetString("game.player.tool")
	if tool ~= n_tool then
		softassert(pcall(hook.run, "api.player.switch_tool", n_tool, tool))
		tool = n_tool
	end
end)