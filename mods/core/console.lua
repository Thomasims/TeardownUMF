
local console_buffer = util.shared_buffer("savegame.console", 128)

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

if REALM_HUD or REALM_MENU then

	local bottom = not not REALM_MENU
	hook.add("base.draw", "console.draw", function()
		local w, h = UiWidth(), UiHeight()
		local cw, ch = w / 2 - 220, math.floor(h * 0.75)
		local visible = bottom and 1 or pauseMenuAlpha
		if not visible or visible == 0 then return end
		UiPush()
			if bottom then
				UiTranslate(w - 20, h - 20)
				UiAlign("right bottom")
			else
				UiTranslate(w - 20, 20)
				UiAlign("right top")
			end
			UiWordWrap(cw)
			UiColor(.0, .0, .0, 0.7 * visible)
			UiImageBox("common/box-solid-shadow-50.png", cw, ch, -50, -50)
			UiWindow(cw, ch, true)
			UiColor(1,0,0,1)
			UiFont("../../mods/core/font/consolas.ttf", 24)
			UiAlign("left bottom")
			UiTranslate(0,ch)
			local len = console_buffer:len() - 1
			for i = len, 0, -1 do
				local data = console_buffer:get(i)
				local r, g, b, text = data:match("([^;]+);([^;]+);([^;]+);(.*)")
				if text then -- if this is nil, something went horribly wrong!
					UiColor(tonumber(r), tonumber(g), tonumber(b), 1 * visible)
					local w, h = UiText(#text == 0 and " " or text, false)
					UiTranslate(0,-math.max(h, 24))
				end
			end
		UiPop()
	end)

end
