
TDUI.SlicePanel = TDUI.Panel {
	color = {1, 1, 1, 1},

	predraw = function(self, w, h)
		UiPush()
		UiColor(
			self.color[1] or 1,
			self.color[2] or 1,
			self.color[3] or 1,
			self.color[4] or 1
		)
		local t = self.template
		UiTranslate(-t.offset_left, -t.offset_top)
		UiImageBox(
			t.image,
			w + t.offset_left + t.offset_right,
			h + t.offset_top + t.offset_bottom,
			t.slice_x, t.slice_y
		)
		UiPop()
	end
}

TDUI.SlicePanel.SolidShadow50 = {
	image = "ui/common/box-solid-shadow-50.png",
	slice_x = 50, slice_y = 50,
	offset_left = 40, offset_top = 40,
	offset_bottom = 41, offset_right = 40,
}

TDUI.SlicePanel.template = TDUI.SlicePanel.SolidShadow50