
TDUI.StackLayout = TDUI.Layout {
	orientation = "vertical";

	onlayout = function(self, data, pw, ph, ew, eh)
		self.__validated = true
		self.__prevew, self.__preveh = ew, eh
		local isvertical = data.orientation == "vertical"
		local nw, nh = self:ComputeSize(pw, ph)
		local pdw, pdh = self.padding[4] + self.padding[2], self.padding[1] + self.padding[3]
		local nfw, nfh = nw == -pdw, nh == -pdh
		if not nfw then ew = nw else ew = ew - pdw end
		if not nfh then eh = nh else eh = eh - pdh end
		if isvertical then if nfh then nh = 0 end else if nfw then nw = 0 end end
		for i = 1, #self do
			local child = self[i]
			local cw, ch = child:onlayout(child, nw, nh, ew, eh)
			if isvertical then
				if nfw and cw > nw and cw <= ew then nw = cw end
				if nfh then nh = nh + ch end
			else
				if nfw then nw = nw + cw end
				if nfh and ch > nh and ch <= eh then nh = ch end
			end
		end
		local dx, dy = self.padding[4], self.padding[1]
		for i = 1, #self do
			local child = self[i]
			local cw, ch = child:onlayout(child, nw, nh, ew, eh)
			child:ComputePosition(dx, dy, nw, nh)
			if isvertical then
				dy = dy + ch
			else
				dx = dx + cw
			end
		end
		if nfw then self.__realw = nw + pdw end
		if nfh then self.__realh = nh + pdh end
		return self.__realw + self.margin[4] + self.margin[2], self.__realh + self.margin[1] + self.margin[3]
	end
}