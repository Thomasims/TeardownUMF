
if UMF_VERSION then return end
UMF_VERSION = "0.6.0"

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

local knownroots = {}
local function fixpath(path)
	local max, maxs = 0, path
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
	return maxs
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

include("extension/meta/vector.lua")
include("extension/meta/quat.lua")
include("extension/meta/transform.lua")

include("extension/meta/entity.lua")
include("extension/meta/body.lua")
include("extension/meta/shape.lua")
include("extension/meta/location.lua")
include("extension/meta/joint.lua")
include("extension/meta/light.lua")
include("extension/meta/trigger.lua")
include("extension/meta/screen.lua")
include("extension/meta/vehicle.lua")
include("extension/meta/player.lua")

include("extension/render.lua")
include("extension/timer.lua")
include("extension/tdui.lua")

include("extension/added_hooks.lua")

include("extension/tool_loader.lua")

for i, modname in ipairs(ListKeys("mods.available")) do
	local modkey = string.format("mods.available.%s", modname)
	local path = GetString(modkey .. ".path")
	knownroots[#knownroots + 1] = path
end

hook.saferun("api.postinit")
