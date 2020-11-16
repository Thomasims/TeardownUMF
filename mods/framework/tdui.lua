
if not UiWidth then return end

--[[
-- prototype code (desired outcome)
TDUI.Label = TDUI.Panel {

	text = ""
	font = RegisterFont("font/consolas.ttf"),
	fontSize = 24,

	Draw = function(self, w, h)
		UiFont(self.font, self.fontSize)
		UiAlign("left top")
		UiText(self.text)
		-- This example doesn't account for:
		--  * custom alignment
		--  * wrapping on width
		--  * Layout calculation
	end,
}

local window = TDUI.Frame {
	title = "Test Window",

	width = "80%h",
	height = "80%h",
	resizeable = true,

	padding = 10,

	TDUI.Label {
		text = "Something"
	}
}
]]

TDUI = setmetatable({}, {
	__newindex = function(self, k, v)
		rawset(self, k, v) -- Is extra processing necessary?
	end
})

TDUI.__PanelMeta = {
	__index = function(self, k)
		local __super = rawget(self, "__super")
		if __super then
			return __super[k]
		end
	end,
	__call = function(self, def)
		def.__super = self
		setmetatable(def, TDUI.__PanelMeta)
		def:__PerformRegister()
		return def
	end
}

local function parseFour(data)
	local dtype = type(data)
	if dtype == "number" then
		return {data, data, data, data}
	elseif dtype == "string" then
		local tmp = {}
		for match in data:gmatch("[^ ]+") do
			tmp[#tmp + 1] = match
		end
		data = tmp
		dtype = "table"
	end
	if dtype == "table" then
		if #data == 0 then return {0,0,0,0} end
		if #data == 1 then return {data[1], data[1], data[1], data[1]} end
		if #data < 4 then return {data[1], data[2], data[1], data[2]} end
		return data
	end
	return {0,0,0,0}
end

local function parsePos(data, w, h, def)
	if type(data) == "number" then return data end
	if type(data) ~= "string" then return 0 end

	local n, prc, mod = data:match("^(%d+)(%?)([wh]?)$")
	if mod == "w" then
		return w * tonumber(n) / 100
	elseif mod == "h" then
		return h * tonumber(n) / 100
	elseif prc == "%" then
		return def * tonumber(n) / 100
	end
	return tonumber(n)
end

-- Base Panel,
TDUI.Panel = setmetatable({
	margin = 0, padding = 0,
	clip = false,

	Draw = function(self, w, h)
		UiColor(1, 1, 1)
		UiTranslate(-40, -40)
		UiImageBox("common/box-solid-shadow-50.png", w+80, h+81, 50, 50)
		UiTranslate(40, 40)
		--UiColor(1, 0, 0, 0.2)
		--UiRect(w, h)
	end,

	__PerformDraw = function(self)
		if not rawget(self, "__validated") then
			self:__PerformLayout(self:GetParentSize())
		end
		local w, h = self:GetComputedSize()
		local f = self.Draw
		if f then f(self, w, h) end

		if self.clip then UiPush() UiWindow(w, h, true) end

		local x, y = 0, 0
		for i = 1, #self do
			local child = self[i]
			local dfx, dfy = child:GetComputedPos()
			UiTranslate(dfx - x, dfy - y)
			child:__PerformDraw()
			x, y = dfx, dfy
		end
		
		if self.clip then UiPop() end
	end,

	__PerformRegister = function(self)
		self.margin = parseFour(self.margin)
		self.padding = parseFour(self.padding)
	end,

	__PerformLayout = function(self, pw, ph)
		self.__realx = self.x and parsePos(self.x, pw, ph, pw) or 0
		self.__realy = self.y and parsePos(self.y, pw, ph, ph) or 0
		self.__realw = self.width and parsePos(self.width, pw, ph, pw) or 256
		self.__realh = self.height and parsePos(self.height, pw, ph, ph) or 256
		self.__validated = true
		for i = 1, #self do
			local child = self[i]
			child:__PerformLayout(self.__realw, self.__realh)
		end
	end,

	InvalidateLayout = function(self, immediate)
		self.__validated = false
		if immediate then
			self:__PerformLayout(self:GetParentSize())
		end
	end,

	SetParent = function(self, parent)
		local prev = self:GetParent()
		if prev then
			for i = 1, #prev do
				if prev[i] == self then
					table.remove(prev, i)
					prev:InvalidateLayout()
					break
				end
			end
		end
		if parent then
			parent[#parent + 1] = self
			rawset(self, "__parent", parent)
			parent:InvalidateLayout()
		end
	end,

	GetParent = function(self)
		return rawget(self, "__parent")
	end,

	GetComputedPos = function(self)
		return rawget(self, "__realx"), rawget(self, "__realy")
	end,

	GetComputedSize = function(self)
		return rawget(self, "__realw"), rawget(self, "__realh")
	end,

	SetSize = function(self, w, h) self.width, self.height = w, h self:InvalidateLayout() end,
	SetWidth = function(self, w) self.width = w self:InvalidateLayout() end,
	SetHeight = function(self, h) self.height = h self:InvalidateLayout() end,

	SetPos = function(self, x, y) self.x, self.y = x, y self:InvalidateLayout() end,
	SetX = function(self, x) self.x = x self:InvalidateLayout() end,
	SetY = function(self, y) self.y = y self:InvalidateLayout() end,

	GetParentSize = function(self)
		local parent = self:GetParent()
		if parent then
			return parent:GetComputedSize()
		else
			return UiWidth(), UiHeight()
		end
	end,
}, TDUI.__PanelMeta)


local ScreenPanel = TDUI.Panel {
	x = 0, y = 0,
	width = UiWidth(), height = UiHeight(),
	Draw = function() end
}

function TDUI.Panel:Popup(parent)
	self:SetParent(parent or ScreenPanel)
end

function TDUI.Panel:Close()
	self:SetParent()
end

hook.add("base.draw", "TDUI.ScreenPanel", function()
	UiPush()
	ScreenPanel:__PerformDraw()
	UiPop()
end)