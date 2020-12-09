
if REALM then return end
local REALM = ...

local s, e = pcall(function()

local realms = {
	hud = "REALM_HUD",
	loading = "REALM_LOADING",
	menu = "REALM_MENU",
	splash = "REALM_SPLASH",
	tv = "REALM_TV",
	world = "REALM_WORLD",
	heist = "REALM_HEIST",
	sandbox = "REALM_SANDBOX",
}

if realms[REALM] then
	_G[realms[REALM]] = true
else
	REALM_OTHER = true
end


-- Detouring stuff --

local original = {}
local function call_original(name, ...)
	local fn = original[name]
	if fn then
		return fn(...)
	end
end

local detoured = {}
function DETOUR(name, generator)
	original[name] = _G[name]
	detoured[name] = generator(function(...) return call_original(name, ...) end)
	rawset(_G, name, nil)
end

setmetatable(_G, {
	__index = detoured,
	__newindex = function(self, k, v)
		if detoured[k] then
			original[k] = v
		else
			rawset(self, k, v)
		end
	end
})

-- Load helper --

function FileExists(path)
	local func, err = loadfile(path)
	return func or err:match("[^ ]+ No such file or directory")
end
file = {exists = FileExists}

function current_line(level)
	level = (level or 0) + 3
	local _, line = pcall(error, "-", level)
	if line == "-" then
		_, line = pcall(error, "-", level + 1)
		if line == "-" then return end
		line = "[C]:?"
	else
		line = line:sub(1, -4)
	end
	return line
end

function current_mod(level)
	level = (level or 0) + 1
	local location = current_line(level)
	if location == "[C]:?" then
		location = current_line(level + 1)
	end
	local mod = location:match("/?mods/([^/]+)/")
	return mod
end

function current_dir(level)
	level = (level or 0) + 1
	local location = current_line(level)
	if location == "[C]:?" then
		location = current_line(level + 1)
	end
	local file = location:match("^([^:]+)")
	local p = file and file:find("([^/]+)$")
	if p then file = file:sub(1, p - 1) end
	return file
end

function include(file, ...)
	local path = current_dir(1) .. file
	local func, err = loadfile(path)
	if not func and err:match("[^ ]+ No such file or directory") then
		path = string.format("mods/%s/%s", current_mod(1), file)
		func, err = loadfile(path)
		if not func and err:match("[^ ]+ No such file or directory") then
			path = file
			func, err = loadfile(path)
			if not func and err:match("[^ ]+ No such file or directory") then
				error("File not found: " .. file)
			end
		end
	end
	if err then
		error(err)
	end

	return func(...)
end

include("core/hook.lua")
include("core/util.lua")
GLOBAL_CHANNEL = util.shared_channel("game.umf_global_channel", 128)
include("core/console_backend.lua")
include("core/meta.lua")
include("core/default_hooks.lua")
include("init.lua")


if REALM_MENU then
	-- The menu realm is the first to initialize so we can do 
	clearconsole()
	printinfo("-- GAME STARTED --")
	printinfo(_VERSION)
end

print("Initializing modding base for REALM: " .. REALM)

hook.saferun("api.postinit")

end)

if not s then
	SetString("savegame.errors."..(math.floor(math.random()*5000)), e)
end