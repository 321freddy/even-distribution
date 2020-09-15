-- Input --

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


-- Entities --

data:extend{
	{
		type = "flying-text",
		name = "distribution-text",
		flags = {"not-on-map", "placeable-off-grid"},
		time_to_live = 150,
		speed = 0.05
	}
}


-- Technologies --

data:extend{
	{
		type = "technology",
		name = "enable-logistics-tab",
		icon_size = 256,
		icon = "__even-distribution__/graphics/tech.png",
		effects =
		{
		  {
			type = "character-logistic-requests",
			modifier = true
		  },
		  {
			type = "auto-character-logistic-trash-slots",
			modifier = true
		  },
		  {
			type = "character-logistic-trash-slots",
			modifier = 10
		  }
		},
		unit =
		{
		  count = 1,
		  ingredients = {},
		  time = 1,
		},
		order = "zzzz",
	  },
}

-- remove additional trash slots, so we have the default 30 slots
local tech = data.raw.technology["logistic-robotics"]
if tech and tech.effects then
	for i,effect in pairs(tech.effects) do
		if effect.type == "character-logistic-trash-slots" and effect.modifier and effect.modifier > 10 then
			effect.modifier = effect.modifier - 10
			break
		end
	end
end


-- Sprites --

data:extend{
	{
		type = "sprite",
		name = "ed_trash",
		filename = "__even-distribution__/graphics/trash.png",
		priority = "extra-high-no-scale",
		size = 32,
		flags = {"gui-icon"},
		mipmap_count = 2,
		scale = 1
	},
	{
		type = "sprite",
		name = "ed_autotrash",
		filename = "__even-distribution__/graphics/autotrash.png",
		priority = "extra-high-no-scale",
		width = 32,
		height = 48,
		flags = {"gui-icon"},
	},
	{
		type = "sprite",
		name = "ed_overflow",
		filename = "__even-distribution__/graphics/overflow.png",
		priority = "extra-high-no-scale",
		size = 64,
		flags = {"gui-icon"},
		scale = 0.5
	},
}


-- Styles --

local style = data.raw["gui-style"].default

style.ed_stretch = {
	type = "empty_widget_style",
	horizontally_stretchable = "on",
}

style.ed_settings_inner_frame = {
	type = "frame_style",
	parent = "frame",
	horizontally_stretchable = "on",
}


style.ed_switch_button = {
	type = "button_style",
	parent = "button",
	left_padding = 0,
	right_padding = 0,

	hovered_font_color = button_default_font_color,
	hovered_graphical_set =
	{
		base = {position = {0, 17}, corner_size = 8},
		shadow = default_dirt
	},
	clicked_font_color = button_default_font_color,
	clicked_graphical_set =
	{
		base = {position = {0, 17}, corner_size = 8},
		shadow = default_dirt
	},
	-- clicked_font_color = button_hovered_font_color,
	-- clicked_graphical_set =
	-- {
	-- 	base = {position = {225, 17}, corner_size = 8},
	-- 	shadow = default_dirt
	-- },
}

style.ed_switch_button_selected = {
	type = "button_style",
	parent = "button",
	left_padding = 0,
	right_padding = 0,

	-- selected button graphical sets as default
	default_font_color = button_hovered_font_color,
	default_graphical_set =
	{
		base = {position = {225, 17}, corner_size = 8},
		shadow = default_dirt
	},
	-- hovered_font_color = button_hovered_font_color,
	-- hovered_graphical_set =
	-- {
	-- 	base = {position = {369, 17}, corner_size = 8},
	-- 	shadow = default_dirt
	-- },
	hovered_font_color = button_hovered_font_color,
	hovered_graphical_set =
	{
		base = {position = {225, 17}, corner_size = 8},
		shadow = default_dirt
	},
	-- clicked_font_color = button_hovered_font_color,
	-- clicked_graphical_set =
	-- {
	-- 	base = {position = {352, 17}, corner_size = 8},
	-- 	shadow = default_dirt
	-- },
	clicked_font_color = button_hovered_font_color,
	clicked_graphical_set =
	{
		base = {position = {225, 17}, corner_size = 8},
		shadow = default_dirt
	},
}
