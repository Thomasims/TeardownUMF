

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

local function createchild(self, def)
	setmetatable(def, {
		__index = self,
		__call = createchild,
		__PANEL = true,
	})
	if self and self.__PerformInherit then self:__PerformInherit(def) end
	if def.__PerformRegister then def:__PerformRegister() end
	return def
end

TDUI = createchild(nil, {})

local function parseFour(data)
	local dtype = type(data)
	if dtype == "number" then
		return {data, data, data, data}
	elseif dtype == "string" then
		local tmp = {}
		for match in data:gmatch("[^ ]+") do
			tmp[#tmp + 1] = tonumber(match)
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
	if type(data) == "function" then return data(w, h, def) end
	if type(data) ~= "string" then return 0 end
	if data:find("function") then return 0 end

	local code = "local _,_w,_h = ...\nreturn" .. data:gsub("(-?)([%d.]+)(%%?)([wh]?)", function(sub, n, prc, mod)
		if prc == "" and mod == "" then return sub .. n end
		return sub .. "(" .. n .. "*_" .. mod .. ")"
	end)
	local fn, err = loadstring(code)
	assert(fn, err)
	setfenv(fn, {})

	return fn(def / 100, w / 100, h / 100)
end

local function parseAlign(data)
	local alignx, aligny = 1, 1
	for str in data:gmatch("%w+") do
		if str == "left" then alignx = 1 end
		if str == "center" then alignx = 0 end
		if str == "right" then alignx = -1 end
		if str == "top" then aligny = 1 end
		if str == "middle" then aligny = 0 end
		if str == "bottom" then aligny = -1 end
	end
	return alignx, aligny
end

TDUI.Slot = function(name)
	return { __SLOT = name }
end

-- Base Panel,
TDUI.Panel = TDUI {
	__alignx = 1, __aligny = 1,
	__realx = 0, __realy = 0,
	__realw = 0, __realh = 0,
	margin = {0, 0, 0, 0}, padding = {0, 0, 0, 0},
	boxsizing = "parent",
	align = "left top",
	clip = false,
	visible = true,

	layout = TDUI.Layout,

	oninit = function(self) end,

	predraw = function(self, w, h) end,
	ondraw = function(self, w, h)
		--UiColor(1, 1, 1)
		--UiTranslate(-40, -40)
		--UiImageBox("common/box-solid-shadow-50.png", w+80, h+81, 50, 50)
		--UiTranslate(40, 40)
		--UiColor(1, 0, 0, 0.2)
		--UiRect(w, h)
	end,
	postdraw = function(self, w, h) end,

	__Draw = function(self)
		if not self.visible then return end
		if not rawget(self, "__validated") then
			self:InvalidateLayout(true)
		end
		local w, h = self:GetComputedSize()
		self:predraw(w, h)
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

		self:postdraw(w, h)
	end,

	__PerformRegister = function(self)
		self.margin = parseFour(self.margin)
		self.padding = parseFour(self.padding)
		self.__alignx, self.__aligny = parseAlign(self.align)
		local i = 1
		self.__dynamic = {}
		local hasslots, slots = false, rawget(self, "__SLOTS") or {}
		while i <= #self do
			if type(self[i]) == "function" or (type(self[i]) == "table" and type(self[i].__SLOT) == "string") then
				local id = #self.__dynamic + 1
				local result
				if self[i] == TDUI.Slot or (type(self[i]) == "table" and type(self[i].__SLOT) == "string") then
					local name = self[i] == TDUI.Slot and "default" or self[i].__SLOT
					result = {}
					local content
					print("creating func for " .. name)
					slots[name] = function(c)
						content = c
						self:__RefreshDynamic(id)
					end
					self.__dynamic[id] = {func = function()
						return content
					end, min = i, count = 0}
					hasslots = true
				else
					result = self[i](self, id)
					self.__dynamic[id] = {func = self[i], min = i, count = #result}
				end
				if #result == 0 then
					table.remove(self, i)
				elseif #result == 1 then
					self[i] = result[1]
				else
					for j = #self, i + 1, -1 do
						self[j + #result - 1] = self[j]
					end
					for j = 1, #result do
						self[i + j - 1] = result[j]
					end
				end
				i = i - 1
			else
				local cslots = rawget(self[i], "__SLOTS")
				if cslots then -- TODO: WHY DOES THIS SECTION WORK???
					hasslots = true -- need to use __dynamic to make sure the right child is being referenced
					for name, update in pairs(cslots) do
						slots[name] = update
					end
					self[i].__SLOTS = nil
				end
				rawset(self[i], "__parent", self)
			end
			i = i + 1
		end
		if hasslots then
			self.__SLOTS = slots
		end
		self:oninit()
	end,

	__PerformInherit = function(self, child)
		local SLOTS = rawget(self, "__SLOTS")
		if SLOTS then
			for name, update in pairs(SLOTS) do
				local src = name == "default" and child or child[name]
				update(src)
			end
		end
		if SLOTS and SLOTS.default then
			for i = 1, #child do
				child[i] = nil
			end
		end
		if #self > 0 then
			for i = #child, 1, -1 do
				child[i + #self] = child[i]
			end
			for i = 1, #self do
				local meta = getmetatable(self[i])
				if meta and meta.__PANEL then
					child[i] = self[i] {}
				else
					child[i] = self[i]
				end
			end
		end
	end,

	__RefreshDynamic = function(self, id)
		local dyn = self.__dynamic[id]
		if not dyn then return end
		local result = dyn.func(self, id)
		local d = #result - dyn.count
		if d > 0 then
			for i = #self, dyn.min + dyn.count, -1 do
				self[i + d] = self[i]
			end
		elseif d < 0 then
			for i = dyn.min + dyn.count, #self - d do
				self[i + d] = self[i]
			end
		end
		for i = 1, #result do
			self[dyn.min + i - 1] = result[i]
		end
		dyn.count = #result
		for i = id + 1, #self.__dynamic do
			self.__dynamic[i].min = self.__dynamic[i].min + d
		end
		self:InvalidateLayout()
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
			child:onlayout(child, self.__realw, self.__realh, self.__realw, self.__realh)
			child:ComputePosition(0, 0, self.__realw, self.__realh)
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
		if self.boxsizing == "parent" then
			local parent = self:GetParent()
			if parent then
				pw = pw - self.margin[4] - self.margin[2]
				ph = ph - self.margin[1] - self.margin[3]
			end
		end

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
		if self.boxsizing == "parent" then
			local parent = self:GetParent()
			if parent then
				pw = pw - self.margin[4] - self.margin[2]
				ph = ph - self.margin[1] - self.margin[3]
			end
		end
		self.__realw = (self.width and parsePos(self.width, pw, ph, pw) or 0)
		self.__realh = (self.height and parsePos(self.height, pw, ph, ph) or 0)
		if self.ratio then
			if self.width and not self.height then
				self.__realh = self.__realw * self.ratio
			elseif self.height and not self.width then
				self.__realw = self.__realh / self.ratio
			end
		end
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
	
	Hide = function(self) self.visible = false end,
	Show = function(self) self.visible = true end,
}

TDUI.Layout = TDUI.Panel {
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
}

TDUI.SimpleForEach = function(tab, callback)
	return function()
		local rt = {}
		for i = 1, #tab do
			local e = callback(tab[i], i, tab)
			if e then rt[#rt + 1] = e end
		end
		return rt
	end
end

TDUI.Panel.layout = TDUI.Layout

local ScreenPanel = TDUI.Panel {
	x = 0, y = 0,
	width = 0, height = 0,
}

function TDUI.Panel:Popup(parent)
	self:SetParent(parent or ScreenPanel)
end

function TDUI.Panel:Close()
	self:SetParent()
end

hook.add("base.draw", "api.tdui.ScreenPanel", function()
	if ScreenPanel.width == 0 then
		ScreenPanel:SetSize(UiWidth(), UiHeight())
	end
	UiPush()
	softassert(pcall(ScreenPanel.__Draw, ScreenPanel))
	UiPop()
end)
