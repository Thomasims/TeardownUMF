
if not REALM_HUD and not REALM_MENU then return end

commands = {
	named = {
		-- Commands that can be found by name are added here.
	},
	indexed = {
		-- Command names can be found by index here.
	}
}

function commands.register(identifier, description, function_variable)
	assert(identifier ~= nil, "Identifier must not be nil")
	commands["named"][string.upper(identifier)] = {description, function_variable}
	table.insert(commands["indexed"], string.upper(identifier))
end

function commands.unregister(identifier)
	assert(identifier ~= nil, "Identifier must not be nil")
	commands["named"][identifier] = nil
	for i = 1, #commands["indexed"] do
		if commands["indexed"][i] == identifier then
			commands["indexed"][i] = nil
		end
	end
end

local function help(command, args)
	local page_text = ""
	for i = 1, #commands["indexed"] do
		local command_name = commands["indexed"][i]
		if command_name ~= nil and commands["named"][command_name] ~= nil then
			page_text = page_text .. string.lower(command_name) .. " - " .. commands["named"][command_name][1] .. "\n"
		end
	end
	return page_text
end

local function value(command, args)
	local path = table.concat(args, ".")
	return "Path: " .. path .. "\nValue: " .. GetString(path)
end

local function exec(command, args)
	local code = table.concat(args, " ")
	code = loadstring(code)
	if code ~= nil then
		return code() -- Execute and return the code they've entered.
	end
	return tostring(nil)
end

-- Register default commands.
commands.register("help", "Shows the commands available.", help)
commands.register("menu", "Go back to the main menu.", Menu)
commands.register("restart", "Shows the commands available.", Restart)
commands.register("time", "Displays the time since the world loaded.", GetTime)
commands.register("value", "Returns all possible values at a key path.", value)
commands.register("exec", "Executes code passed as arguments.", exec)


local function roundvec(v, dec)
	v[1] = math.floor(v[1] * dec + .5) / dec
	v[2] = math.floor(v[2] * dec + .5) / dec
	v[3] = math.floor(v[3] * dec + .5) / dec
	return v
end

local function draw_line(dx, dy)
	UiPush()
		UiRotate(math.deg(math.atan2(-dy, dx)))
		UiRect(math.sqrt(dx^2 + dy^2), 1)
	UiPop()
end

local console_buffer = util.shared_buffer("savegame.console", 128)
local visible = false
local textbox_text = ""

local frames_per_second = 0
local tick_iterations = 0
local tick_time = 0
local tick_time_history = {}
local tick_time_max = 120

local vmin = Vec(-math.huge, -math.huge, -math.huge)
local vmax = Vec(math.huge, math.huge, math.huge)
local function get_object_count()
	return #QueryAabbBodies(vmin, vmax), #QueryAabbShapes(vmin, vmax)
end
local nbodies, nshapes = get_object_count()
local lasttick = -10

local function console_draw()
	local w, h = UiWidth(), UiHeight()
	local cw, ch = UiCenter(), UiMiddle()
	local text_size = 18

	tick_iterations = tick_iterations + 1
	tick_time = tick_time + GetTimeStep()
	if tick_time >= 1 then
		frames_per_second = tick_iterations
		tick_time = tick_time - 1
		tick_iterations = 0
	end

	if tick_iterations % 2 == 0 then
		table.insert(tick_time_history, GetTimeStep())
	end
	if #tick_time_history > tick_time_max then
		table.remove(tick_time_history, 1)
	end

	if not visible then return end

	local now = GetTime()
	local refresh_second = false
	if now - lasttick > 1 then
		lasttick = now
		refresh_second = true
	end

	local w_left, w_right = w * 0.4, w * 0.6

	UiMakeInteractive()
	UiPush()
		-- Draw the gray background box for the console.
		UiColor(.0, .0, .0, 0.8)
		UiImageBox("common/box-solid-shadow-50.png", w, h, -50, -50)
		UiPush()
			local w_console = w_left - 50
			UiTranslate(25, 20)
			UiWindow(w_console, h, true)
			UiTranslate(-5, 0)
			UiAlign("left bottom")
			UiTranslate(0, h - 60)
			UiWordWrap(w_console)

			-- Render the textbox background where the user enters a command.
			UiColor(.1, .1, .1, 0.2)
			UiImageBox("common/box-solid-shadow-50.png", w_console, 8, -50, -50)
			
			-- Show the current command in text.
			UiColor(1, 1, 1, 1)
			UiTranslate(10, 0)
			UiFont("../../mods/umf/assets/font/consolas.ttf", text_size)
			UiPush()
				UiAlign("left")
				if textbox_text == "" then UiColor(1, 1, 1, 0.2) end
				UiText(textbox_text == "" and "Start typing to write here, press enter to execute..." or textbox_text)
			UiPop()
			
			-- Draw the history of the console.
			UiTranslate(-5, -24)
			local len = console_buffer:len() - 1
			for i = len, 0, -1 do
				local data = console_buffer:get(i)
				local r, g, b, text = data:match("([^;]+);([^;]+);([^;]+);(.*)")

				if text then -- This should never be nil.
					UiColor(tonumber(r), tonumber(g), tonumber(b), 1)
					local tw, th = UiText(#text == 0 and " " or text, false)
					UiTranslate(0,-math.max(th, text_size))
				end
			end
		UiPop()

		-- Render the background of the tick graph.
		local w_info = w_right - 50
		UiTranslate(w_left + 25, 30)
		UiPush()
			UiColor(.1, .1, .1, 0.4)
			UiImageBox("common/box-solid-shadow-50.png", w_info, 200, -50, -50)
			UiColor(1, 1, 1, 1)
			UiImageBox("../../mods/umf/assets/image/graph.png", w_info, 200, 50, 50)

			UiColor(1, 1, 1, 1)
			UiPush()
				UiTextShadow(0.2, 0.2, 0.2, 3, 1)
				UiAlign("center middle")
				UiFont("bold.ttf", text_size)
				UiTranslate(w_info / 2, 10)
				UiText("FRAMETIME")
				UiTranslate(w_info / 2, 20)
				UiAlign("right")
				UiText(tostring(frames_per_second) .. " FPS")
			UiPop()

			-- Draw the graph line.
			UiTranslate(5, 197 - tick_time_history[1] * 2400) -- 60 * 40
			local dx = (w_info - 10) / (tick_time_max - 1)
			for i = 2, #tick_time_history do
				local dy = (tick_time_history[i] - tick_time_history[i - 1]) * 2400
				draw_line(math.ceil(dx), -dy)
				UiTranslate(dx, -dy)
			end
		UiPop()

		local gameinfo = {{"VERSION", GetString("game.version")}}
		local information = {{"GAME", gameinfo}}

		if REALM_HUD then
			-- Declare information variables.
			local camera_transform = MakeTransformation(GetCameraTransform())
			local player_transform = MakeTransformation(GetPlayerTransform())
			local camera_raycast = camera_transform:Raycast(100, -1)
			local camera_pyr = roundvec(Vector(camera_transform.rot:ToEuler()), 100)
			local player_pyr = roundvec(Vector(player_transform.rot:ToEuler()), 100)

			gameinfo[2] = {"PAUSED", GetBool("game.paused")}
			gameinfo[3] = {"LEVEL_ID", GetString("game.levelid")}
			gameinfo[4] = {"LEVEL_PATH", GetString("game.levelpath")}

			local playerinfo = {
				{"CAMERA POSITION (XYZ)", roundvec(camera_transform.pos, 100)},
				{"CAMERA ROTATION (PYR)", camera_pyr},
				{"CAMERA LOOK POS (XYZ)", roundvec(camera_raycast.hitpos, 100)},
				{"PLAYER POSITION (XYZ)", roundvec(player_transform.pos, 100)},
				{"PLAYER ROTATION (PYR)", player_pyr},
				{"PLAYER HEALTH", math.floor(GetPlayerHealth() * 100 + .5) .. "%"}
			}
			information[#information + 1] = {"PLAYER", playerinfo}

			if refresh_second then
				nbodies, nshapes = get_object_count()
			end

			local levelinfo = {
				{"BODIES", nbodies},
				{"SHAPES", nshapes},
				{"FIRE_COUNT", GetFireCount()},
				{"PRIMARY_TARGETS", GetInt("level.primary")},
				{"CLEARED_PRIMARY_TARGETS", GetInt("level.clearedprimary")},
				{"SECONDARY_TARGETS", GetInt("level.secondary")},
				{"CLEARED_SECONDARY_TARGETS", GetInt("level.clearedsecondary")},
				{"REQUIRED", GetInt("level.required")},
				{"ALARM_TRIGGERED", GetBool("level.alarm")},
				{"ALARM_TIMER", GetFloat("level.alarmtimer")},
				{"MISSION_TIME", GetFloat("level.missiontime")},
				{"FIRE_ALARM", GetBool("level.firealarm")},
				{"DISPATCH", GetBool("level.dispatch")},
				{"STATE", GetString("level.state")},
				{"COMPLETE", GetBool("level.complete")},
				{"INTERACT_INFO", GetString("level.interactinfo")}
			}
			information[#information + 1] = {"LEVEL", levelinfo}

			if camera_raycast.hit then
				local bodytr = Body(GetShapeBody(camera_raycast.shape)):GetTransform()
				playerinfo[#playerinfo + 1] = {"TARGET POSITION (XYZ)", roundvec(bodytr.pos, 100)}
				playerinfo[#playerinfo + 1] = {"TARGET ROTATION (PYR)", roundvec(Vector(bodytr.rot:ToEuler()), 100)}
			end
		end
		
		-- Draw information variables.
		UiColor(1, 1, 1, 1)
		UiFont("regular.ttf", text_size)
		UiTextShadow(0.2, 0.2, 0.2, 3, 1)
		UiWordWrap(w_info / 2 - 15)
		
		UiPush()
			UiTranslate(0, 240)
			UiPush()
				UiColor(.1, .1, .1, 0.4)
				UiImageBox("common/box-solid-shadow-50.png", w_info / 2 - 15, (3 * ch) / 2 - 40, -50, -50)
			UiPop()

			UiPush()
				UiAlign("center top")
				UiTranslate(w_info / 4, 0)
				UiFont("bold.ttf", text_size + 8)
				UiText("REGISTRY")
				-- TODO: Registry viewer
			UiPop()

		UiPop()

		UiPush()
			UiTranslate(w_info / 2 + 15, 240)
			UiPush()
				UiColor(.1, .1, .1, 0.4)
				UiImageBox("common/box-solid-shadow-50.png", w_info / 2 - 15, (3 * ch) / 2 - 40, -50, -50)
			UiPop()

			local offset = 0

			for i = 1, #information do
				local info = information[i]
				UiPush()
					UiAlign("center top")
					UiTranslate(w_info / 4, offset)
					UiFont("bold.ttf", text_size + 8)
					local _, th = UiText(info[1])
					offset = offset + th
				UiPop()

				UiPush()
					offset = offset + 20
					UiTranslate(20, offset)
					local panel_info = info[2]
					for i = 1, #panel_info do
						local _, th = UiText(panel_info[i][1] .. ": " .. tostring(panel_info[i][2]))
						UiTranslate(0, th)
						offset = offset + th
					end
				UiPop()
			end
		UiPop()
	UiPop()
end

local function printorerror(b, ...)
	if b then
		print(...)
	else
		printerror(...)
	end
end

hook.add("api.key.pressed", function(key)
	if visible then
		if string.len(key) == 1 then -- Has to be a letter, add it to the written textbox.
			textbox_text = textbox_text .. key
		elseif key == "space" then
			textbox_text = textbox_text .. " "
		elseif key == "return" then
			if textbox_text == "" then
				visible = false
			else
				-- Execute the command when the return button has been pressed.
				local input_split={}
				for input in string.gmatch(textbox_text, "([^ ]+)") do
					table.insert(input_split, input)
				end

				-- Make sure the command argument was valid.
				if input_split[1] ~= nil then
					local cmd = input_split[1]
					local command = commands.named[string.upper(cmd)]
					if command then
						table.remove(input_split, 1)

						local callback = command[2]
						if type(callback) == "function" then
							printorerror(pcall(callback, cmd, input_split))
						else
							print(callback)
						end
					else
						print("Unknown command, use \"help\" for a list of commands.")
					end
					textbox_text = ""
				end
			end
		elseif key == "esc" then
			visible = false
			textbox_text = ""
		end
	elseif key == "return" then
		visible = true
	end
end)

if UMF_CONFIG.devmode then
	hook.add("base.draw", "console.draw", console_draw)
end

hook.add("base.command.activate", "console.updateconfig", function()
	if UMF_CONFIG.devmode then
		hook.add("base.draw", "console.draw", console_draw)
	else
		hook.remove("base.draw", "console.draw")
	end
end)