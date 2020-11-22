if REALM then return end
REALM = ...

local realms = {
	hud = "REALM_HUD",
	loading = "REALM_LOADING",
	menu = "REALM_MENU",
	splash = "REALM_SPLASH",
	tv = "REALM_TV",
	world = "REALM_WORLD",
	heist = "REALM_HEIST"
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

local curmod = "core"
local curdir = {"mods/core/"}

function current_mod(level)
	if not curmod or (level and util) then
		level = (level or 0) + 1
		local location = util.current_line(level)
		if location == "[C]:?" then
			location = util.current_line(level + 1)
		end
		local mod = location:match("^mods/([^/]+)/")
		return mod
	end
	return curmod
end

function current_dir(level)
	if #curdir == 0 or (level and util) then
		level = (level or 0) + 1
		local location = util.current_line(level)
		if location == "[C]:?" then
			location = util.current_line(level + 1)
		end
		local file = location:match("^([^:]+)")
		local p = file and file:find("([^/]+)$")
		if p then file = file:sub(1, p - 1) end
		return file
	end
	return curdir[#curdir]
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

	curdir[#curdir + 1] = path:match("^(.-/)[^/]+$")
	local s, a, b, c, d, e = pcall(func, ...)
	curdir[#curdir] = nil
	if not s then error(a) end
	return a, b, c, d, e
end

include("extension/hook.lua")
include("extension/util.lua")
include("extension/console_backend.lua")
include("extension/file.lua")

file.loadinfo()

if REALM_MENU then
	-- The menu realm is the first to initialize so we can do 
	clearconsole()
	printinfo("-- GAME STARTED --")
	printinfo(_VERSION)
end

print("Initializing modding base for REALM: " .. REALM)

include("default_hooks.lua")

local modnames, mods = file.find("mods/(*)"), {}
for i = 1, #modnames do
	local name = modnames[i]
	if name ~= "core" then
		local func, e = loadfile(string.format("mods/%s/manifest.lua", name))
		if func then
			setfenv(func, {})
			local success, manifest = pcall(func)
			if success and manifest then
				local mod = mods[name] or {children = {}}
				mod.parents = {}
				mod.name = name
				mod.manifest = manifest
				for i = 1, #manifest.dependencies do
					local parent = manifest.dependencies[i]
					mod.parents[parent] = true
					mods[parent] = mods[parent] or {children = {}}
					table.insert(mods[parent].children, mod)
				end
				mods[name] = mod
			end
		end
	end
end

local function canload(manifest)
	for i = 1, #manifest.realms do
		if manifest.realms[i] == "*" or manifest.realms[i] == REALM then
			return true
		end
	end
end

hook.add("api.postload", "api.modloader", function(name, mod, data)
	printinfo("Loaded mod: " .. mod.manifest.printname)
end)

hook.add("api.failload", "api.modloader", function(name, mod, error)
	printerror("Failed to load mod: " .. mod.manifest.printname)
	printerror(error)
end)

local function loadmod(mod)
	if not mod.parents or next(mod.parents) or mod.loaded then return end
	mod.loaded = true
	if canload(mod.manifest) then
		curmod = mod.name
		hook.run("api.preload", mod.name, mod)
		local success, ret = pcall(include, string.format("mods/%s/init.lua", mod.name))
		hook.run(success and "api.postload" or "api.failload", mod.name, mod, ret)
	end
	for i = 1, #mod.children do
		local child = mod.children[i]
		child.parents[mod.name] = nil
		loadmod(child)
	end
end

for name, mod in pairs(mods) do
	loadmod(mod)
end

for name, mod in pairs(mods) do
	if mod.parents and not mod.loaded and canload(mod.manifest) then
		printerror("Missing dependencies for mod: " .. mod.name)
	end
end

curmod = nil
curdir = {}

hook.run("api.postinit")