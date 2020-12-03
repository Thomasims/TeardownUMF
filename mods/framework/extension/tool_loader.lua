
if not REALM_HUD then return end

--[[ Warning, not all tools are good as bases, if you supress default behaviour or if the player runs out of ammo for them, some start behaving weirdly.

- <invalid>     : Good       note: No view model
- sledge        : OK         note: Will always swing when clicking
- spraycan      : OK         note: Will always spray when clicking
- extinguisher  : OK         note: Will always spray when clicking
- blowtorch     : Glitched   note: Viewmodel jitters when its ammo is 0
- shotgun       : Good
- plank         : OK         note: Viewmodel is offset when its ammo is 0
- pipebomb      : Poor       note: Viewmodel is off-screen when its ammo is 0
- gun           : Good
- bomb          : Poor       note: Viewmodel is off-screen when its ammo is 0
- rocket        : Good

]]

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
	data.base = data.base or "none"
	extra_tools[id] = data
	sortedinsert(toolslist, data)
end

function GetToolList()
	return extra_tools
end

function UpdateToolsOrder()
	toolslist = {}
	for id, tool in pairs(extra_tools) do
		sortedinsert(toolslist, tool)
	end
end

local function ammodisplay(tool)
	local key = "game.tool."..tool..".ammo"
	local realkey = "game.tool."..tool..".savedammo"
	return function()
		if gUnlimited then return "" end
		return math.floor(GetFloat(HasKey(realkey) and realkey or key)*10)/10
	end
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
	GetAmmoString = ammodisplay("blowtorch"),
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

CurrentTool = HasKey("game.player.customtool") and GetString("game.player.customtool") or GetString("game.player.tool")
CurrentToolBase = GetString("game.player.tool")

local function updateammo()
	local key = "game.tool."..CurrentToolBase..".ammo"
	local realkey = "game.tool."..CurrentToolBase..".savedammo"
	if CurrentTool == CurrentToolBase then
		if HasKey(realkey) then
			SetFloat(key, GetFloat(realkey))
			ClearKey(realkey)
		end
	else
		local tool = extra_tools[CurrentTool]
		if tool.suppress_default and not HasKey(realkey) then
			SetFloat(realkey, GetFloat(key))
			SetFloat(key, 0)
		end
	end
end

local function istoolactive()
	return not GetBool("game.player.grabbing") and not GetBool("game.player.usescreen") and not GetBool("game.player.usevehicle") and not GetBool("game.map.enabled") and not GetBool("game.paused") and GetString("level.state") == ""
end

local scrolling
hook.add("api.mouse.wheel", "api.tool_loader", function(ds)
	if not istoolactive() then return end
	scrolling = GetTime()
	local enabledTools = GetActiveTools()
	for i = 1, #enabledTools do
		if enabledTools[i].id == CurrentTool then
			scrolling = GetTime()
			local newtool = enabledTools[math.min(math.max(i - ds, 1), #enabledTools)]
			local tool = extra_tools[CurrentTool]
			CurrentTool = newtool.id
			CurrentToolBase = newtool.base
			SetString("game.player.customtool", CurrentTool)
			SetString("game.player.tool", CurrentToolBase)
			if tool.id ~= newtool.id then
				if tool.Holster then tool:Holster() end
				if newtool.Deploy then newtool:Deploy() end
			end
			updateammo()
			break
		end
	end
end)

hook.add("api.player.switch_tool", "api.tool_loader", function(new_tool, old_tool)
	if CurrentTool ~= new_tool then
		if scrolling == GetTime() then
			SetString("game.player.tool", CurrentToolBase)
		else
			local tool = extra_tools[CurrentTool]
			if tool.Holster then tool:Holster() end
			CurrentTool = new_tool
			CurrentToolBase = new_tool
			SetString("game.player.customtool", CurrentTool)
			updateammo()
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
				if t.GetAmmoString then
					UiText(t:GetAmmoString())
				end
			UiPop()
			UiTranslate(150, 0)
		end
	UiPop()

	local tooldata = extra_tools[CurrentTool]
	if tooldata.Draw and istoolactive() then
		softassert(pcall(tooldata.Draw, tooldata))
	end
end

-- Override default tick() to replace the unlimited ammo feature
function tick()
	--Start recording when alarm goes off
	if not gAlarm and GetBool("level.alarm") then
		gAlarm = true
		startRecording()
	end

	--Stop recording if play state changes
	if gAlarm and GetString("level.state")~="" then
		stopRecording()
	end

	if gUnlimited then
		SetInt("game.tool."..CurrentTool..".ammo", 99)
	end
	local tool = extra_tools[CurrentTool]
	if tool and tool.Tick then softassert(pcall(tool.Tick, tool)) end
end

hook.add("base.init", "api.tool_loader", function()
	for i = 1, #toolslist do
		local tool = toolslist[i]
		if tool.Initialize then softassert(pcall(tool.Initialize, tool)) end
	end
end)

hook.add("api.mouse.pressed", "api.tool_loader", function()
	local tool = extra_tools[CurrentTool]
	if tool and tool.LeftClick and istoolactive() then
		softassert(pcall(tool.LeftClick, tool))
	end
end)

hook.add("api.mouse.released", "api.tool_loader", function()
	local tool = extra_tools[CurrentTool]
	if tool and tool.LeftClickReleased and istoolactive() then
		softassert(pcall(tool.LeftClickReleased, tool))
	end
end)