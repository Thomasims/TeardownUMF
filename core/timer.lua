----------------------------------------
--              WARNING               --
--   Timers are reset on quickload!   --
-- Keep this in mind if you use them. --
----------------------------------------
timer = {}
timer._backlog = {}

local backlog = timer._backlog

local function sortedinsert( tab, val )
	for i = #tab, 1, -1 do
		if val.time < tab[i].time then
			tab[i + 1] = val
			return
		end
		tab[i + 1] = tab[i]
	end
	tab[1] = val
end

local diff = GetTime() -- In certain realms, GetTime() is not 0 right away

function timer.simple( time, callback )
	sortedinsert( backlog, { time = GetTime() + time - diff, callback = callback } )
end

function timer.create( id, interval, iterations, callback )
	sortedinsert( backlog, {
		id = id,
		time = GetTime() + interval - diff,
		interval = interval,
		callback = callback,
		runsleft = iterations - 1,
	} )
end

function timer.wait( time )
	local co = coroutine.running()
	if not co then
		error( "timer.wait() can only be used in a coroutine" )
	end
	timer.simple( time, function()
		coroutine.resume( co )
	end )
	return coroutine.yield()
end

local function find( id )
	for i = 1, #backlog do
		if backlog[i].id == id then
			return i, backlog[i]
		end
	end
end

function timer.time_left( id )
	local index, entry = find( id )
	if entry then
		return entry.time - GetTime()
	end
end

function timer.iterations_left( id )
	local index, entry = find( id )
	if entry then
		return entry.runsleft + 1
	end
end

function timer.remove( id )
	local index, entry = find( id )
	if index then
		table.remove( backlog, index )
	end
end

hook.add( "base.tick", "framework.timer", function( dt )
	diff = 0
	local now = GetTime()
	while #backlog > 0 do
		local first = backlog[#backlog]
		if first.time > now then
			break
		end
		backlog[#backlog] = nil
		first.callback()
		if first.runsleft and first.runsleft > 0 then
			first.runsleft = first.runsleft - 1
			first.time = first.time + first.interval
			sortedinsert( backlog, first )
		end
	end
end )
