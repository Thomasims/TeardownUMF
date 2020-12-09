
function IsPlayerInVehicle()
	return GetBool("game.player.usevehicle")
end

local tool = GetString("game.player.tool")
local invehicle = IsPlayerInVehicle()

hook.add("base.tick", "api.default_hooks", function()
	if InputPressed then
		if InputPressed("lmb") then hook.saferun("api.mouse.pressed", "lmb") end
		if InputPressed("rmb") then hook.saferun("api.mouse.pressed", "rmb") end
		if InputReleased("lmb") then hook.saferun("api.mouse.released", "lmb") end
		if InputReleased("rmb") then hook.saferun("api.mouse.released", "rmb") end
		local wheel = InputValue("mousewheel")
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