if not REALM_MENU then
	function RegisterMap(name)
		warning(string.format("[%s] Called RegisterMap() for level %q from realm %q. This function only works from REALM_MENU!", current_mod(1), name, REALM))
	end
	return
end

local custom_maps = {
	{name = "basic", printname = "Basic level", path = "../../create/basic.xml"},
	{name = "island", printname = "Island level", path = "../../create/island.xml"},
	{name = "castle", printname = "Castle level", path = "../../create/castle.xml"},
	{name = "vehicle", printname = "Vehicle level", path = "../../create/vehicle.xml"},
	{name = "custom", printname = "Custom level", path = "../../create/custom.xml"},
}

function RegisterMap(name, printname, curmod)
	curmod = curmod or current_mod(1)
	for i = 1, #custom_maps do
		local map = custom_maps[i]
		if map.name == name and map.curmod == curmod then
			if printname then
				map.printname = printname
			end
			return
		end
	end
	table.insert(custom_maps, {
		name = name,
		curmod = curmod,
		printname = printname or name,
		path = string.format("../../mods/%s/levels/%s.xml", curmod, name)
	})
end

hook.add("api.postload", "framework.levelloader", function(name, mod, data)
	local levels = file.find(string.format("mods/%s/levels/(*).xml", name))
	for i = 1, #levels do
		RegisterMap(levels[i], nil, name)
	end
end)

DETOUR("drawCreate", function(original)
	return function(scale)
		local open = true
		UiPush()
			local w = 800
			local h = 530
			UiTranslate(UiCenter(), UiMiddle())
			UiScale(scale)
			UiColorFilter(1, 1, 1, scale)
			UiColor(0,0,0, 0.5)
			UiAlign("center middle")
			UiImageBox("common/box-solid-shadow-50.png", w, h, -50, -50)
			UiWindow(w, h)
			UiAlign("left top")
			UiColor(1,1,1)
			if UiIsKeyPressed("esc") or (not UiIsMouseInRect(UiWidth(), UiHeight()) and UiIsMousePressed()) then
				open = false
			end
	
			UiPush()
				UiFont("font/bold.ttf", 48)
				UiColor(1,1,1)
				UiAlign("center")
				UiTranslate(UiCenter(), 60)
				UiText("CREATE")
			UiPop()
			
			UiPush()
				UiFont("font/regular.ttf", 22)
				UiTranslate(UiCenter(), 100)
				UiAlign("center")
				UiWordWrap(600)
				UiColor(0.8, 0.8, 0.8)
				UiText("Create your own sandbox level using the free voxel modeling program MagicaVoxel. We have provided example levels that you can modify or replace with your own creation. Find out more on our web page:", true)
				UiTranslate(0, 2)
				UiFont("font/bold.ttf", 22)
				UiColor(1, .8, .5)
				if UiTextButton("www.teardowngame.com/create") then
					Command("game.openurl", "http://www.teardowngame.com/create")
				end
	
				local columns = math.ceil(#custom_maps/5)
				UiTranslate(123 - 123 * columns, 70)
				UiPush()
					UiColor(1,1,1)
					UiFont("font/regular.ttf", 26)
					UiButtonImageBox("common/box-outline-6.png", 6, 6, 1, 1, 1)
					for i = 1, #custom_maps do
						local map = custom_maps[i]
						if UiTextButton(map.printname, 240, 40) then
							Command("game.startlevel", map.path)
						end
						UiTranslate(0, 45)
						if i % 5 == 0 then
							UiTranslate(246, -225)
						end
					end
				UiPop()
				UiTranslate(0, 250)
				UiFont("font/regular.ttf", 20)
				UiColor(.6, .6, .6)
				UiText("Using custom loader. Files located at: " .. GetString("game.path") .. "/mods")
			UiPop()
		UiPop()
		return open
	end
end)