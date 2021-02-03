#include "MODS/umf/injector.lua"

function init()
	config = util.structured_table "savegame.mod"
	devmode = config.devmode
end

function draw()
	UiTranslate(UiCenter(), 250)
	UiAlign("center middle")

	UiFont("bold.ttf", 48)
	UiText("Unofficial Modding Framework")

	UiTranslate(0, 100)
	UiFont("regular.ttf", 26)
	UiButtonImageBox("ui/common/box-outline-6.png", 6, 6)

	UiPush()
		if UiTextButton("Developer Mode", 240, 40) then
			devmode = not devmode
			config.devmode = devmode
		end
		if devmode then
			UiColor(0.5, 1, 0.5)
			UiTranslate(-90, 0)
			UiImage("ui/menu/mod-active.png")
		else
			UiTranslate(-90, 0)
			UiImage("ui/menu/mod-inactive.png")
		end
	UiPop()

	UiTranslate(0, 100)
	if UiTextButton("Close", 80, 40) then
		Menu()
	end
end