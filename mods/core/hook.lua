

local hook_table = {}
local hook_compiled = {}

local function recompile(event)
	local hooks = {}
	for k, v in pairs(hook_table[event]) do
		hooks[#hooks + 1] = v
	end
	hook_compiled[event] = hooks
end

hook = {
	table = hook_table,
}

function hook.add(event, identifier, func)
	hook_table[event] = hook_table[event] or {}
	hook_table[event][identifier] = func
	recompile(event)
end

function hook.remove(event, identifier)
	if hook_table[event] then
		hook_table[event][identifier] = nil
		recompile(event)
	end
end

function hook.run(event, ...)
	local hooks = hook_compiled[event]
	if not hooks then return end
	for i = 1, #hooks do
		local a, b, c, d, e = hooks[i](...)
		if a then return a, b, c, d, e end
	end
end