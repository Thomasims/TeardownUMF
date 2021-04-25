
local tool_meta = {
	__index = {
		DrawInWorld = function(self, transform)
			SetToolTransform(TransformToLocalTransform(GetCameraTransform(), transform))
		end
	}
}

local extra_tools = {}
function RegisterToolUMF(id, data)
	setmetatable(data, tool_meta)
	data.id = id
	data.base = data.base or "none"
	extra_tools[id] = data
	RegisterTool(id, data.printname or id, data.model or "")
	SetBool("game.tool." .. id .. ".enabled", true)
end

local function istoolactive()
	return GetBool("game.player.canusetool")
end

local prev
hook.add("api.mouse.wheel", "api.tool_loader", function(ds)
	if not istoolactive() then return end
	local tool = prev and extra_tools[prev]
	if tool and tool.MouseWheel then tool:MouseWheel(ds) end
end)

hook.add("base.tick", "api.tool_loader", function(dt)
	local cur = GetString("game.player.tool")
	local tool = extra_tools[cur]
	
	local prevtool = prev and extra_tools[prev]
	if prevtool and prevtool.ShouldLockMouseWheel then
		local s, b = softassert(pcall(prevtool.ShouldLockMouseWheel, prevtool))
		if b then
			SetString("game.player.tool", prev)
			cur = prev
			tool = prevtool
		end
	end
	prev = cur

	if tool then
		if tool.Animate then
			local body = GetToolBody()
			if not tool._BODY or tool._BODY.handle ~= body then
				tool._BODY = Body(body)
				tool._SHAPES = tool._BODY and tool._BODY:GetShapes()
			end
			if tool._BODY then
				softassert(pcall(tool.Animate, tool, tool._BODY, tool._SHAPES))
			end
		end
		if tool.Tick then softassert(pcall(tool.Tick, tool, dt)) end
	end
end)

hook.add("api.firsttick", "api.tool_loader", function()
	for id, tool in pairs(extra_tools) do
		if tool.Initialize then softassert(pcall(tool.Initialize, tool)) end
	end
end)

hook.add("base.draw", "api.tool_loader", function()
	local tool = extra_tools[GetString("game.player.tool")]
	if tool and tool.Draw then softassert(pcall(tool.Draw, tool)) end
end)

hook.add("api.mouse.pressed", "api.tool_loader", function(button)
	local tool = extra_tools[GetString("game.player.tool")]
	local event = button == "lmb" and "LeftClick" or "RightClick"
	if tool and tool[event] and istoolactive() then
		softassert(pcall(tool[event], tool))
	end
end)

hook.add("api.mouse.released", "api.tool_loader", function(button)
	local tool = extra_tools[GetString("game.player.tool")]
	local event = button == "lmb" and "LeftClickReleased" or "RightClickReleased"
	if tool and tool[event] and istoolactive() then
		softassert(pcall(tool[event], tool))
	end
end)