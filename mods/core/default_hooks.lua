
local hook = hook

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
	"init", -- "base.init" (runs before init())
	"tick", -- "base.tick" (runs before tick())
	"update", -- "base.update" (runs before update())
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

------ QUICKSAVE WORKAROUND -----
-- Quicksaving stores a copy of the global table without functions, so libraries get corrupted on quickload
-- This code prevents this by overriding them back

local handleCommandDetour = function(original)
	return function(...)
		softassert(pcall(hook.run, "base.handleCommand", ...))
		return original(...)
	end
end

if REALM_WORLD then
	local saved = {}

	local function hasfunction(t, bck)
		if bck[t] then return end
		bck[t] = true
		for k, v in pairs(t) do
			if type(v) == "function" then return true end
			if type(v) == "table" and hasfunction(v, bck) then return true end
		end
	end

	for k, v in pairs(_G) do
		if type(v) == "table" and hasfunction(v, {}) then
			saved[k] = v
		end
	end

	handleCommandDetour = function(original)
		return function(command, ...)
			if command == "quickload" then
				for k, v in pairs(saved) do
					_G[k] = v
				end
			end
			softassert(pcall(hook.run, "base.handleCommand", command, ...))
			return original(command, ...)
		end
	end
end

DETOUR("handleCommand", handleCommandDetour)