
local function simple_detour(name)
	local event = "base." .. name
	DETOUR(name, function(original)
		return function(...)
			softassert(pcall(hook.run, event, ...))
			return original(...)
		end
	end)
end
local detours = {
	"init",
	"tick",
	"update",
	"handleCommand"
}
for i = 1, #detours do
	simple_detour(detours[i])
end

DETOUR("draw", function(original)
	return function()
		softassert(pcall(hook.run, "base.predraw"))
		original()
		softassert(pcall(hook.run, "base.draw"))
	end
end)