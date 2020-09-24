data:extend{
	{
		type = "custom-input",
		name = "inventory-cleanup",
		key_sequence = "SHIFT + C",
		consuming = "game-only"
	},
	{
		type = "custom-input",
		name = "open-even-distribution-settings",
		key_sequence = "ALT + E",
		consuming = "game-only"
	},
	{
		type = "shortcut",
		name = "open-even-distribution-settings",
		order = "a",
		action = "lua",
		localised_name = {"shortcut.open-even-distribution-settings"},
		toggleable=true,
		style = "blue",
		icon =
		{
			filename = "__even-distribution__/graphics/icon.png",
			priority = "extra-high-no-scale",
			size = 64,
			scale = 1,
			flags = {"icon"}
		},
		small_icon =
		{
			filename = "__even-distribution__/graphics/icon.png",
			priority = "extra-high-no-scale",
			size = 64,
			scale = 1,
			flags = {"icon"}
		},
		disabled_small_icon =
		{
			filename = "__even-distribution__/graphics/icon.png",
			priority = "extra-high-no-scale",
			size = 64,
			scale = 1,
			flags = {"icon"}
		},
	},
}