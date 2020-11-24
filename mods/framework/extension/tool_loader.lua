
if not REALM_HUD then return end

local extra_tools = {}
local toolslist = {}

local function sortedinsert(tab, val)
	for i = #tab, 1, -1 do
		if val.order > tab[i].order then
			tab[i + 1] = val
			return
		end
		tab[i + 1] = tab[i]
	end
	tab[1] = val
end

function RegisterTool(id, data)
	data.id = id
	extra_tools[id] = data
	sortedinsert(toolslist, data)
end

local function ammodisplay(tool)
	local str = "game.tool."..tool..".ammo"
	return function() return GetInt(str) end
end

local function isenabled(tool)
	local str = "game.tool."..tool..".enabled"
	return function() return GetBool(str) end
end

RegisterTool("sledge", {
	base = "sledge",
	printname = "Sledge",
	order = 0.5,
	IsEnabled = isenabled("sledge"),
})

RegisterTool("spraycan", {
	base = "spraycan",
	printname = "Spraycan",
	order = 1.5,
	IsEnabled = isenabled("spraycan"),
})

RegisterTool("extinguisher", {
	base = "extinguisher",
	printname = "Extinguisher",
	order = 2.5,
	IsEnabled = isenabled("extinguisher"),
})

RegisterTool("blowtorch", {
	base = "blowtorch",
	printname = "Blowtorch",
	order = 3.5,
	GetAmmoString = function() return math.floor(GetFloat("game.tool.blowtorch.ammo")*10)/10 end,
	IsEnabled = isenabled("blowtorch"),
})

RegisterTool("shotgun", {
	base = "shotgun",
	printname = "Shotgun",
	order = 4.5,
	GetAmmoString = ammodisplay("shotgun"),
	IsEnabled = isenabled("shotgun"),
})

RegisterTool("plank", {
	base = "plank",
	printname = "Plank",
	order = 5.5,
	GetAmmoString = ammodisplay("plank"),
	IsEnabled = isenabled("plank"),
})

RegisterTool("pipebomb", {
	base = "pipebomb",
	printname = "Pipe bomb",
	order = 6.5,
	GetAmmoString = ammodisplay("pipebomb"),
	IsEnabled = isenabled("pipebomb"),
})

RegisterTool("gun", {
	base = "gun",
	printname = "Gun",
	order = 7.5,
	GetAmmoString = ammodisplay("gun"),
	IsEnabled = isenabled("gun"),
})

RegisterTool("bomb", {
	base = "bomb",
	printname = "Bomb",
	order = 8.5,
	GetAmmoString = ammodisplay("bomb"),
	IsEnabled = isenabled("bomb"),
})

RegisterTool("rocket", {
	base = "rocket",
	printname = "Rocket",
	order = 9.5,
	GetAmmoString = ammodisplay("rocket"),
	IsEnabled = isenabled("rocket"),
})

function GetActiveTools()
	local enabledTools = {}
	for i=1, #toolslist do
		local t = toolslist[i]
		if not t.IsEnabled or t:IsEnabled() then
			enabledTools[#enabledTools+1] = t
		end
	end
	return enabledTools
end

CurrentTool = GetString("game.player.tool")
local actual_tool = CurrentTool

local scrolling
hook.add("api.mouse.wheel", "api.tool_loader", function(ds)
	scrolling = GetTime()
	local enabledTools = GetActiveTools()
	for i = 1, #enabledTools do
		if enabledTools[i].id == CurrentTool then
			scrolling = GetTime()
			local newtool = enabledTools[math.min(math.max(i - ds, 1), #enabledTools)]
			local tool = extra_tools[CurrentTool]
			CurrentTool = newtool.id
			actual_tool = newtool.base
			SetString("game.player.tool", actual_tool)
			if tool.id ~= newtool.id then
				if tool.Holster then tool:Holster() end
				if newtool.Deploy then newtool:Deploy() end
			end
			break
		end
	end
end)

hook.add("api.player.switch_tool", "api.tool_loader", function(new_tool, old_tool)
	if CurrentTool ~= new_tool then
		if scrolling == GetTime() then
			SetString("game.player.tool", actual_tool)
		else
			local tool = extra_tools[CurrentTool]
			if tool.Holster then tool:Holster() end
			CurrentTool = new_tool
			actual_tool = new_tool
		end
	end
end)

function drawTool()
	UiPush()
		UiTranslate(0, UiHeight()-60)
		UiAlign("top left")

		local enabledTools = GetActiveTools()
	
		local currentTool = CurrentTool
		if not oldTool then 
			toolX = UiCenter()
			toolAlpha = 0
			oldTool = currentTool
			previousTool = oldTool
		end

		if currentTool ~= oldTool then
			oldTool = currentTool
			for i=1, #enabledTools do
				if enabledTools[i].id == currentTool then
					SetValue("toolX", UiCenter()-150*(i-1), "cosine", 0.2)
				end
			end
		end
		
		UiTranslate(toolX, 45)
		
		for i=1, #enabledTools do
			local t = enabledTools[i]
			UiPush()
				local alpha = math.min(1.0, toolAlpha)
				UiFont("font/bold.ttf", 26)
				UiAlign("center")
				local w = currentTool
				if previousTool ~= w then
					toolAlpha = 4
					SetValue("toolAlpha", 0, "linear", 2)	
					previousTool = w
				end
				if w == t.id then
					UiScale(1)
					UiTextOutline(0,0,0,1, 0.1)
					UiColor(1, 1, 1, 1.0)
				else
					UiScale(0.6)
					UiTextOutline(0,0,0,1*alpha, 0.1)
					UiColor(0.7, 0.7, 0.7, alpha)
				end
				UiText(string.upper(t.printname))

				UiTranslate(0, -24)
				if w == t.id then UiScale(1.6) end
				if not gUnlimited and t.GetAmmoString then
					UiText(t:GetAmmoString())
				end
			UiPop()
			UiTranslate(150, 0)
		end
	UiPop()

	local tooldata = extra_tools[CurrentTool]
	if tooldata.hide_default then
		SetCameraTransform(GetPlayerTransform(), GetInt("options.gfx.fov"))
	end
	if tooldata.Draw then
		pcall(tooldata.Draw, tooldata)
	end
end

hook.add("base.init", "api.tool_loader", function()
	for i = 1, #toolslist do
		local tool = toolslist[i]
		if tool.Initialize then pcall(tool.Initialize, tool) end
	end
end)

hook.add("base.tick", "api.tool_loader", function()
	local tool = extra_tools[CurrentTool]
	if tool and tool.Tick then pcall(tool.Tick, tool) end
end)

hook.add("api.mouse.pressed", "api.tool_loader", function()
	local tool = extra_tools[CurrentTool]
	if tool and tool.LeftClick then pcall(tool.LeftClick, tool) end
end)