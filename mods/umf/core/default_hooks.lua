
local hook = hook

local function simple_detour(name)
	local event = "base." .. name
	DETOUR(name, function(original)
		return function(...)
			hook.saferun(event, ...)
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

function shoulddraw(kind)
	return hook.saferun("api.shouddraw", kind) ~= false
end

DETOUR("draw", function(original)
	return function()
		if shoulddraw("all") then
			hook.saferun("base.predraw")
			if shoulddraw("original") then
				original()
			end
			hook.saferun("base.draw")
		end
	end
end)


------ QUICKSAVE WORKAROUND -----
-- Quicksaving stores a copy of the global table without functions, so libraries get corrupted on quickload
-- This code prevents this by overriding them back

local saved = {}

local function hasfunction(t, bck)
	if bck[t] then return end
	bck[t] = true
	for k, v in pairs(t) do
		if type(v) == "function" then return true end
		if type(v) == "table" and hasfunction(v, bck) then return true end
	end
end

hook.add("api.postinit", "quicksave_workaround", function()
	for k, v in pairs(_G) do
		if k ~= "_G" and type(v) == "table" and hasfunction(v, {}) then
			saved[k] = v
		end
	end
end)

local quickloadfix = function()
	for k, v in pairs(saved) do
		_G[k] = v
	end
end

DETOUR("handleCommand", function(original)
	return function(command, ...)
		if command == "quickload" then quickloadfix() end
		hook.saferun("base.command." .. command, ...)
		return original(command, ...)
	end
end)

--------------------------------

if REALM_HUD then
	hook.add("base.command.quicksave", "api.broadcast_quicksave", function()
		GLOBAL_CHANNEL:broadcast("quicksave")
	end)
else
	GLOBAL_CHANNEL:listen(function(channel, type)
		if type == "quicksave" then
			hook.saferun("base.command.quicksave")
		end
	end)
end

if REALM_SANDBOX then
	SetBool("game.sandbox", true)
	SetBool("game.unlimitedammo", pUnlimited)

	function tick(dt)
		--Fade to black and respawn when dead
		if GetFloat("game.player.health") == 0 then
			if dieFade == 0 then
				SetValue("dieFade", 1, "linear", 4)
			end
			if dieFade == 1 then
				RespawnPlayer()
				SetValue("dieFade", 0, "linear", 1)
			end	
		end
	end
end