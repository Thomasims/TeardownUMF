
console_buffer = util.shared_buffer("savegame.console", 128)

-- Console backend --

local function maketext(...)
	local text = ""
	local len = select("#", ...)
	for i = 1, len do
		local s = tostring(select(i, ...))
		if i < len then
			s = s .. string.rep(" ", 8 - #s % 8)
		end
		text = text .. s
	end
	return text
end

function printcolor(r, g, b, ...)
	local text = string.format("%f;%f;%f;%s", r, g, b, maketext(...))
	console_buffer:push(text)
	--Command("console.update")
end

function print(...)
	printcolor(1, 1, 1, ...)
end

function printinfo(...)
	printcolor(0, .6, 1, ...)
end

function printwarning(...)
	printcolor(1, .7, 0, ...)
end

function printerror(...)
	printcolor(1, .2, 0, ...)
end

function clearconsole()
	console_buffer:clear()
end

function softassert(b, ...)
	if not b then printerror(...) end
	return b, ...
end
