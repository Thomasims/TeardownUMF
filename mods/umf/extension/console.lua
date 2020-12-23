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


local function draw_information(label, data)
	UiTextShadow(0.2, 0.2, 0.2, 3, 1)
	local w, h = UiText(label)
	UiTranslate(w + 5, 0)
	UiText(data)
	UiTranslate(-(w + 5), 0)
end
local function draw_line(dx, dy)
	local k = dy / dx
	for i = 1, dx, 1 do
		UiText(".") -- This is a very inefficient way to draw a 2D line.
		UiTranslate(1, k)
	end
end

local function get_object_count()
	local shapes = 0
	local bodies = 0
	for i = 1, 8192 do -- This should be optimized to only run the amount of iterations needed.
		shapes = shapes + #GetBodyShapes(i)
		if #GetBodyShapes(i) > 0 then
			bodies = bodies + 1
		end
	end
	return {bodies, shapes}
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
	return "Path: " .. path .. "\nInt: " .. GetInt(path) .. "\nFloat: " .. GetFloat(path) .. "\nBool: " .. tostring(GetBool(path)) .. "\nString: " .. GetString(path)
end
local function exec(command, args)
	local code = table.concat(args, " ")
	code = loadstring(code)
	if code ~= nil then
		return code() -- Execute and return the code they've entered.
	end
	return tostring(nil)
end


if REALM_HUD or REALM_MENU then
	local console_buffer = util.shared_buffer("savegame.console", 128)
	local visible = false;
	local textbox_text = ""

	local frames_per_second = 0
	local tick_iterations = 0
	local tick_time = 0
	local tick_time_history = {}

	-- Register default commands.
	commands.register("help", "Shows the commands available.", help)
	commands.register("menu", "Go back to the main menu.", Menu)
	commands.register("restart", "Shows the commands available.", Restart)
	commands.register("time", "Displays the time since the world loaded.", GetTime)
	commands.register("value", "Returns all possible values at a key path.", value)
	commands.register("exec", "Executes code passed as arguments.", exec)

	hook.add("base.draw", "console.draw", function()
		local w, h = UiWidth(), UiHeight()
		local cw, ch = UiCenter(), UiMiddle()
		local text_size = 18

		if InputPressed("return") then
			-- Execute the command when the return button has been pressed.
			if visible and textbox_text ~= "" then
				local input_split={}
				for input in string.gmatch(textbox_text, "([^ ]+)") do
					table.insert(input_split, input)
				end

				-- Make sure the command argument was valid.
				if input_split[1] ~= nil then
					local command = commands["named"][string.upper(input_split[1])]
					local args = {}

					for i = 2, #input_split do
						table.insert(args, input_split[i])
					end

					if command == nil then 
						print("Unknown command, use \"help\" for a list of commands.")
					else
						local returned = type(command[2]) == "function" and command[2](input_split[1], args) or command[2]
						print(tostring(returned)) -- Print the return value of the function/variable.
					end
					textbox_text = ""
				end
			end

			visible = true
		elseif InputPressed("esc") and visible then
			SetPaused(false)
			visible = false
			textbox_text = ""
		end

		if not visible or visible == 0 then return end

		UiMakeInteractive()
		UiPush()
			-- Draw the gray background box for the console.
			UiColor(.0, .0, .0, 0.95)
			UiImageBox("common/box-solid-shadow-50.png", w, h, -50, -50)
			UiPush()
				UiTranslate(25, 20)
				UiWindow(w / 3, h, true)
				UiTranslate(-5, 0)
				UiAlign("left bottom")
				UiTranslate(0, h - 60)
				UiWordWrap(w / 3)

				-- Render the textbox background where the user enters a command.
				UiColor(.1, .1, .1, 0.2)
				UiImageBox("common/box-solid-shadow-50.png", cw - 40, 8, -50, -50)
				
				-- Show the current command in text.
				UiColor(1, 1, 1, 1)
				UiTranslate(10, 0)
				UiFont("../../mods/umf/assets/font/consolas.ttf", text_size)
				UiPush()
					UiAlign("left")
					UiText(textbox_text)
				UiPop()
				
				-- Draw the history of the console.
				UiTranslate(-5, -20)
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
			UiTranslate(w / 3 + 60, 30)
			UiPush()
				UiColor(.1, .1, .1, 0.2)
				UiImageBox("common/box-solid-shadow-50.png", 1180, 200, -50, -50)

				UiColor(1, 1, 1, 1)
				UiPush()
					UiFont("bold.ttf", text_size)
					UiTranslate(1180 / 2 - 40, 20)
					draw_information("TICKS PER FRAME", "")
				UiPop()

				-- Draw the graph line.
				UiFont("regular.ttf", text_size)
				UiTranslate(0, 100)
				for i = 1, #tick_time_history do
					draw_line(10, (tick_time_history[i] - (i > 1 and tick_time_history[i - 1] or 0.0165)) * 1000)
				end
			UiPop()

			-- Declare information variables.
			local bodies_and_shapes = get_object_count()
			local camera_transform = MakeTransformation(GetCameraTransform());
			local camera_raycast = Transformation(camera_transform.pos, camera_transform.rot * QuatEuler(180, 0, 0)):Raycast(dist, 1, radius, rejectTransparent);
			local camera_pitch, camera_yaw, camera_roll = MakeQuaternion(GetCameraTransform().rot):ToEuler()
			local player_pitch, player_yaw, player_roll = MakeQuaternion(GetPlayerTransform().rot):ToEuler()

			local information = {
				game = {
					{"FPS", frames_per_second},
					{"VERSION", GetString("game.version")},
					{"PAUSED", tostring(GetBool("game.paused"))},
					{"LEVEL_ID", GetString("game.levelid")},
					{"LEVEL_PATH", GetString("game.levelpath")},
					{"PLAYBACK_LOADED", tostring(GetBool("game.path.loaded"))},
					{"PLAYBACK_RECORDING", tostring(GetBool("game.path.recording"))},
					{"PLAYBACK_LENGTH (s)", tostring(math.floor(GetFloat("game.path.length") * 100) / 100)},
					{"PLAYBACK_PATH (XYZ)", tostring(math.floor(GetFloat("game.path.current.x") * 100) / 100) .. "   " .. tostring(math.floor(GetFloat("game.path.current.y") * 100) / 100) .. "   " .. tostring(math.floor(GetFloat("game.path.current.z") * 100) / 100)},
					{"PLAYBACK_POS (s)", tostring(math.floor(GetFloat("game.path.pos") * 100) / 100)},
					{"PLAYBACK_ALPHA", tostring(math.floor(GetFloat("game.path.alpha") * 100) / 100)}
				},
				level = {
					{"BODIES", bodies_and_shapes[1]},
					{"SHAPES", bodies_and_shapes[2]},
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
				},
				player = {
					{"CAMERA POSITION (XYZ)", tostring(math.floor(GetCameraTransform().pos[1] * 100) / 100) .. "   " .. tostring(math.floor(GetCameraTransform().pos[2] * 100) / 100) .. "   " .. tostring(math.floor(GetCameraTransform().pos[3] * 100) / 100)},
					{"CAMERA ROTATION (PYR)", tostring(math.floor(camera_pitch * 100) / 100) .. "   " .. tostring(math.floor(camera_yaw * 100) / 100) .. "   " .. tostring(math.floor(camera_roll * 100) / 100)},
					{"CAMERA LOOK POSITION (XYZ)", tostring(math.floor(camera_raycast.hit[1] * 100) / 100) .. "   " .. tostring(math.floor(camera_raycast.hit[2] * 100) / 100) .. "   " .. tostring(math.floor(camera_raycast.hit[3] * 100) / 100)},
					{"PLAYER POSITION (XYZ)", tostring(math.floor(GetPlayerTransform().pos[1] * 100) / 100) .. "   " .. tostring(math.floor(GetPlayerTransform().pos[2] * 100) / 100) .. "   " .. tostring(math.floor(GetPlayerTransform().pos[3] * 100) / 100)},
					{"PLAYER ROTATION (PYR)", tostring(math.floor(player_pitch * 100) / 100) .. "   " .. tostring(math.floor(player_yaw * 100) / 100) .. "   " .. tostring(math.floor(player_roll * 100) / 100)},
					{"PLAYER HEALTH", tostring(GetPlayerHealth())}
				}
			}
			
			-- Draw information variables.
			UiColor(1, 1, 1, 1)
			UiFont("regular.ttf", text_size)
			
			UiPush()
				UiTranslate(0, 240)
				UiPush()
					UiColor(.1, .1, .1, 0.2)
					UiImageBox("common/box-solid-shadow-50.png", 1, (3 * ch) / 2 - 40, -50, -50)
					UiImageBox("common/box-solid-shadow-50.png", 1180 / 3, (3 * ch) / 2 - 40, -50, -50)
				UiPop()

				UiPush()
					UiTranslate((1180 / 3) / 2 - 40, 20)
					UiFont("bold.ttf", text_size + 8)
					draw_information("GAME", "")
				UiPop()
				UiTranslate(20, 50)
				local game_info = information["game"];
				for i = 1, #game_info do
					draw_information(game_info[i][1] .. ": ", game_info[i][2])
					UiTranslate(0, 20)
				end
			UiPop()

			UiPush()
				UiTranslate(1180 / 3, 240)
				UiPush()
					UiColor(.1, .1, .1, 0.2)
					UiImageBox("common/box-solid-shadow-50.png", 1180 / 3, (3 * ch) / 2 - 40, -50, -50)
				UiPop()

				UiPush()
					UiTranslate((1180 / 3) / 2 - 40, 20)
					UiFont("bold.ttf", text_size + 8)
					draw_information("LEVEL", "")
				UiPop()
				UiTranslate(20, 50)
				local level_info = information["level"];
				for i = 1, #level_info do
					draw_information(level_info[i][1] .. ": ", level_info[i][2])
					UiTranslate(0, 20)
				end
			UiPop()

			UiPush()
				UiTranslate((2 * 1180) / 3, 240)
				UiPush()
					UiColor(.1, .1, .1, 0.2)
					UiImageBox("common/box-solid-shadow-50.png", 1180 / 3, (3 * ch) / 2 - 40, -50, -50)
					UiTranslate(1180 / 3, 0)
					UiImageBox("common/box-solid-shadow-50.png", 1, (3 * ch) / 2 - 40, -50, -50)
				UiPop()

				UiPush()
					UiTranslate((1180 / 3) / 2 - 40, 20)
					UiFont("bold.ttf", text_size + 8)
					draw_information("PLAYER", "")
				UiPop()
				UiTranslate(20, 50)
				local player_info = information["player"];
				for i = 1, #player_info do
					draw_information(player_info[i][1] .. ": ", player_info[i][2])
					UiTranslate(0, 20)
				end
			UiPop()
		UiPop()
	end

	if UMF_CONFIG.devmode then
		hook.add("base.draw", "console.draw", console)
	end

	hook.add("base.command.activate", "console.updateconfig", function()
		if UMF_CONFIG.devmode then
			hook.add("base.draw", "console.draw", console)
		else
			hook.remove("base.draw", "console.draw")
		end
	end)

	hook.add("base.tick", "console.tick", function(dt)
		tick_iterations = tick_iterations + 1
		tick_time = tick_time + GetTimeStep()
		if tick_iterations % 2 == 0 then
			table.insert(tick_time_history, GetTimeStep())
		end
		if tick_time >= 1 then
			frames_per_second = tick_iterations
			tick_time = 0
			tick_iterations = 0
		end

		if #tick_time_history >= 119 then
			table.remove(tick_time_history, 1)
		end
	end)

	hook.add("api.key.pressed", function(key)
		if visible then
			if string.len(key) == 1 then -- Has to be a letter, add it to the written textbox.
				textbox_text = textbox_text .. key
			elseif key == "space" then
				textbox_text = textbox_text .. " "
			end
		end
	end)
end