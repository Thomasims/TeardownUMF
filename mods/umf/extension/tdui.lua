

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

	local n, prc, mod = data:match("^(-?%d+)(%%?)([wh]?)$")
	if mod == "w" then
		return w * tonumber(n) / 100
	elseif mod == "h" then
		return h * tonumber(n) / 100
	elseif prc == "%" then
		return def * tonumber(n) / 100
	end
	return tonumber(n)
end

local function parseAlign(data)
	local alignx, aligny = 1, 1
	for str in data:gmatch("[^ ]+") do
		if str == "left" then alignx = 1 break end
		if str == "center" then alignx = 0 break end
		if str == "right" then alignx = -1 break end
		if str == "top" then aligny = 1 break end
		if str == "middle" then aligny = 0 break end
		if str == "bottom" then aligny = -1 break end
	end
	return alignx, aligny
end

TDUI.Layout = setmetatable({
	onlayout = function(self, data, pw, ph, ew, eh)
		self.__validated = true
		self.__prevew, self.__preveh = ew, eh
		local nw, nh = self:ComputeSize(pw, ph)
		local p1, p2, p3, p4 = self.padding[1], self.padding[2], self.padding[3], self.padding[4]
		for i = 1, #self do
			local child = self[i]
			child:onlayout(child, nw, nh, ew, eh)
			child:ComputePosition(p4, p1, nw, nh)
		end
		return self.__realw + self.margin[4] + self.margin[2], self.__realh + self.margin[1] + self.margin[3]
	end
}, TDUI.__PanelMeta)

-- Base Panel,
TDUI.Panel = setmetatable({
	__alignx = 1, __aligny = 1,
	__realx = 0, __realy = 0,
	__realw = 0, __realh = 0,
	margin = 0, padding = 0,
	align = "left top",
	clip = false,

	layout = TDUI.Layout,

	oninit = function(self) end,

	ondraw = function(self, w, h)
		--UiColor(1, 1, 1)
		--UiTranslate(-40, -40)
		--UiImageBox("common/box-solid-shadow-50.png", w+80, h+81, 50, 50)
		--UiTranslate(40, 40)
		--UiColor(1, 0, 0, 0.2)
		--UiRect(w, h)
	end,

	__Draw = function(self)
		if not rawget(self, "__validated") then
			self:InvalidateLayout(true)
		end
		local w, h = self:GetComputedSize()
		self:ondraw(w, h)

		if self.clip then UiPush() UiWindow(w, h, true) end

		local x, y = 0, 0
		for i = 1, #self do
			local child = self[i]
			local dfx, dfy = child:GetComputedPos()
			UiTranslate(dfx - x, dfy - y)
			child:__Draw()
			x, y = dfx, dfy
		end
		UiTranslate(-x, -y)
		
		if self.clip then UiPop() end
	end,

	__PerformRegister = function(self)
		self.margin = parseFour(self.margin)
		self.padding = parseFour(self.padding)
		self.__alignx, self.__aligny = parseAlign(self.align)
		self:oninit()
	end,

	onlayout = function(self, data, pw, ph, ew, eh)
		-- onlayout must do 2 things:
		--  1. Position its children within the available space
		--  2. Compute its own size for the layout of its parent

		-- TODO: Optimize for static sizes and unchanged bounds


		local selflayout = self.layout
		if selflayout then
			local f = selflayout.onlayout
			if f and f ~= self.onlayout then
				return f(self, selflayout, pw, ph, ew, eh)
			end
		end
		warning("Unable to compute layout")
		self.__validated = true
		self:ComputeSize(pw, ph)
		for i = 1, #self do
			local child = self[i]
			child:ComputePosition(0, 0, self.__realw, self.__realh)
			child:onlayout(child, self.__realw, self.__realh, self.__realw, self.__realh)
		end
		return self.__realw, self.__realh

		--[[self.__realx = self.x and parsePos(self.x, pw, ph, pw) or 0
		self.__realy = self.y and parsePos(self.y, pw, ph, ph) or 0
		self.__realw = self.width and parsePos(self.width, pw, ph, pw) or 256
		self.__realh = self.height and parsePos(self.height, pw, ph, ph) or 256
		self.__validated = true
		for i = 1, #self do
			local child = self[i]
			child:__PerformLayout(self.__realw, self.__realh)
		end]]
	end,

	ComputePosition = function(self, dx, dy, pw, ph)
		local x = self.x and parsePos(self.x, pw, ph, pw) or 0
		if self.__alignx == 1 then
			self.__realx = x + self.margin[4] + dx
		elseif self.__alignx == 0 then
			self.__realx = x + (pw - self.__realw) / 2 + dx
		elseif self.__alignx == -1 then
			self.__realx = x + pw - self.margin[2] - self.__realw + dx
		end

		local y = self.y and parsePos(self.y, pw, ph, ph) or 0
		if self.__aligny == 1 then
			self.__realy = y + self.margin[1] + dy
		elseif self.__aligny == 0 then
			self.__realy = y + (ph - self.__realh) / 2 + dy
		elseif self.__aligny == -1 then
			self.__realy = y + ph - self.margin[3] - self.__realh + dy
		end

		return self.__realx, self.__realy
	end,

	ComputeSize = function(self, pw, ph)
		self.__realw = (self.width and parsePos(self.width, pw, ph, pw) or 0)
		self.__realh = (self.height and parsePos(self.height, pw, ph, ph) or 0)
		return self.__realw - self.padding[4] - self.padding[2], self.__realh - self.padding[1] - self.padding[3]
	end,

	InvalidateLayout = function(self, immediate)
		if immediate then
			local cw, ch = self:GetComputedSize()
			local pw, ph = self:GetParentSize()
			self:onlayout(self, pw, ph, self.__prevew or pw, self.__preveh or ph)
			local nw, nh = self:GetComputedSize()
			if nw ~= cw or nh ~= ch then
				self:InvalidateParentLayout(true)
			end
		else
			self.__validated = false
		end
	end,

	InvalidateParentLayout = function(self, immediate)
		local parent = self:GetParent()
		if parent then
			return parent:InvalidateLayout(immediate)
		else
			local pw, ph = UiWidth(), UiHeight()
			self:InvalidateLayout(immediate)
			self.__realx = self.x and parsePos(self.x, pw, ph, pw) or 0
			self.__realy = self.y and parsePos(self.y, pw, ph, ph) or 0
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
		return self.__realx, self.__realy
	end,

	GetComputedSize = function(self)
		return self.__realw, self.__realh
	end,

	SetSize = function(self, w, h) self.width, self.height = w, h self:InvalidateLayout() end,
	SetWidth = function(self, w) self.width = w self:InvalidateLayout() end,
	SetHeight = function(self, h) self.height = h self:InvalidateLayout() end,

	SetPos = function(self, x, y) self.x, self.y = x, y self:InvalidateLayout() end,
	SetX = function(self, x) self.x = x self:InvalidateLayout() end,
	SetY = function(self, y) self.y = y self:InvalidateLayout() end,

	SetMargin = function(self, top, right, bottom, left)
		if right then top = {top, right, bottom, left} end
		self.margin = parseFour(top)
		self:InvalidateLayout()
	end,

	SetPadding = function(self, top, right, bottom, left)
		if right then top = {top, right, bottom, left} end
		self.padding = parseFour(top)
		self:InvalidateLayout()
	end,

	GetParentSize = function(self)
		local parent = self:GetParent()
		if parent then
			return parent:GetComputedSize()
		else
			return UiWidth(), UiHeight()
		end
	end,
}, TDUI.__PanelMeta)

TDUI.Layout.__super = TDUI.Panel

local ScreenPanel = TDUI.Panel {
	x = 0, y = 0,
	width = 0, height = 0
}

function TDUI.Panel:Popup(parent)
	self:SetParent(parent or ScreenPanel)
end

function TDUI.Panel:Close()
	self:SetParent()
end

hook.add("base.init", "api.tdui.init", function()
	ScreenPanel:SetSize(UiWidth(), UiHeight())
end)

hook.add("base.draw", "api.tdui.ScreenPanel", function()
	UiPush()
	softassert(pcall(ScreenPanel.__Draw, ScreenPanel))
	UiPop()
end)

include("panels/layout.lua")
