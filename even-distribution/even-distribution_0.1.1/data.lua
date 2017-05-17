data:extend{
	{
		type = "smoke",
		name = "distribution-marker",
		flags = {"not-repairable", "not-blueprintable", "not-deconstructable", "placeable-off-grid", "not-on-map"},
		duration = 9999999,
		spread_duration = 10,
		start_scale = 0.001,
		end_scale = 1,
		color = { r = 1, g = 1, b = 1, a = 1 },
		cyclic = true,
		affected_by_wind = false,
		show_when_smoke_off = true,
		movement_slow_down_factor = 0,
		vertical_speed_slowdown = 0,
		render_layer = "selection-box",
		animation =
		{
			filename = "__even-distribution__/graphics/distribution-marker.png",
			width = 64,
			height = 64,
			scale = 0.5,
			frame_count = 1
		}
	},
	{
		type = "flying-text",
		name = "distribution-text",
		flags = {"not-on-map", "placeable-off-grid"},
		time_to_live = 150,
		speed = 0.05
	},
}