

TDUI.Window = TDUI.Panel {
	color = {1, 1, 1, 1},

	predraw = function(self, w, h)
	end,

	TDUI.Panel {

		TDUI.Slot "title"
	},

	TDUI.Panel {

		TDUI.Slot
	},
}