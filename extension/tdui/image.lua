
TDUI.Image = TDUI.Panel {
	path = "",
	fit = "fit",

	ondraw = function(self, w, h)
		if not HasFile(self.path) then return end
		local iw, ih = self:GetImageSize()
		UiPush()
			if self.fit == "stretch" then
				UiScale(w / iw, h / ih)
			elseif self.fit == "cover" then
				local r, ir = w / h, iw / ih
				UiWindow(w, h, true)
				if r > ir then
					UiTranslate(0, h / 2 - ih * w / iw / 2)
					UiScale(w / iw)
				else
					UiTranslate(w / 2 - iw * h / ih / 2, 0)
					UiScale(h / ih)
				end
			elseif self.fit == "fit" then
				local r, ir = w / h, iw / ih
				if r > ir then
					UiTranslate(w / 2 - iw * h / ih / 2, 0)
					UiScale(h / ih)
				else
					UiTranslate(0, h / 2 - ih * w / iw / 2)
					UiScale(w / iw)
				end
			end
			self:DrawImage(iw, ih)
		UiPop()
	end,

	GetImageSize = function(self)
		return UiGetImageSize(self.path)
	end,
	DrawImage = function(self, w, h)
		UiImage(self.path)
	end,
}

TDUI.AtlasImage = TDUI.Image {
	atlas_width = 1,
	atlas_height = 1,
	atlas_x = 1,
	atlas_y = 1,

	GetImageSize = function(self)
		local iw, ih = UiGetImageSize(self.path)
		return iw / self.atlas_width, ih / self.atlas_height
	end,
	DrawImage = function(self, w, h)
		UiWindow(w, h, true)
		UiTranslate((1 - self.atlas_x) * w, (1 - self.atlas_y) * h)
		UiImage(self.path)
	end,
}