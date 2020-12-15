
if REALM then return end
REALM = ... or "other"

local s, e = pcall(function()

SetBool("game.umf." .. REALM, true)

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

local knownroots = {}
local function fixpath(path)
	local max, maxs = 0
	for i = 1, #knownroots do
		local root = knownroots[i]
		local s = root:find("/", 1, true)
		while s do
			local sub = root:sub(s+1)
			local st, se = path:find(sub, 1, true)
			if st then
				if se - st > max then
					max = st - se
					maxs = root:sub(1, s) .. path:sub(st)
				end
				break
			end
			s = root:find("/", s + 1, true)
		end
	end
	return maxs or path
end

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
	if line:sub(1,3) == "..." then
		line = fixpath(line:sub(4))
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
	local file = location:match("^(..[^:]+)")
	local p = file and file:find("([^/]+)$")
	if p then file = file:sub(1, p - 1) end
	return file
end

local function unknownfile(err)
	return err:match("[^ ]+ No such file or directory") or err:match("[^ ]+ Invalid argument")
end

function include(file, ...)
	local path = current_dir(1) .. file
	local func, err = loadfile(path)
	if not func and unknownfile(err) then
		path = string.format("mods/%s/%s", current_mod(1), file)
		func, err = loadfile(path)
		if not func and unknownfile(err) then
			path = file
			func, err = loadfile(path)
			if not func and unknownfile(err) then
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

if REALM_MENU then
	-- The menu realm is the first to initialize so we can do
	clearconsole()
	printinfo("-- GAME STARTED --")
	printinfo(_VERSION)

	hook.add("base.postcmd", "api.markumf", function(cmd)
		if cmd ~= "mods.refresh" then return end
		for i, modname in ipairs(ListKeys("mods.available")) do
			local modkey = string.format("mods.available.%s", modname)
			local path = GetString(modkey .. ".path")
			local success, manifest = pcall(dofile, path .. "/manifest.lua")
			if success then 
				SetBool(modkey .. ".override", true)
			end
		end
	end)
	Command("mods.refresh")
end

print("Initializing modding base for REALM: " .. REALM)

include("init.lua")

local function canload(manifest)
	if manifest.disabled then return end
	for i = 1, #manifest.realms do
		if manifest.realms[i] == "*" or manifest.realms[i] == REALM then
			return true
		end
	end
end

local function loadmod(modname, path, manifest)
	if not canload(manifest) then return end
	local init, err = loadfile(path .. "/init.lua")
	if not init then
		if not unknownfile(err) then printerror(err) end
		return
	end
	-- TODO: dependencies support
	init()
	printinfo("Loaded mod: " .. modname)
end

local runningMod = GetString("game.levelpath"):match("mods/([^/]+)/main.xml$")
for i, modname in ipairs(ListKeys("mods.available")) do
	local modkey = string.format("mods.available.%s", modname)
	local path = GetString(modkey .. ".path")
	knownroots[#knownroots + 1] = path
	if not UMF_NOMODS then
		local success, manifest = pcall(dofile, path .. "/manifest.lua")
		if success and (GetBool(modkey .. ".active") or not runningMod or runningMod == path:match("mods/([^/]+)/?$")) then
			softassert(pcall(loadmod, modname, path, manifest))
		end
	end
end

hook.saferun("api.postinit")

end)

if not s then
	SetString("savegame.errors."..(math.floor(math.random()*5000)), e)
end