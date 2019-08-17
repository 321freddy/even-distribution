-- Input --

data:extend{
	{
		type = "custom-input",
		name = "inventory-cleanup",
		key_sequence = "SHIFT + C",
		consuming = "all"
	}
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