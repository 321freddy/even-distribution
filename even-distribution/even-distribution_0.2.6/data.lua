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

local function createMarker(name, type, duration, spread_duration, fade_away_duration, start_scale, end_scale)
	return {
		type = type,
		name = name,
		flags = {"not-repairable", "not-blueprintable", "not-deconstructable", "placeable-off-grid", "not-on-map"},
		duration = duration,
		spread_duration = spread_duration,
		fade_away_duration = fade_away_duration,
		start_scale = start_scale,
		end_scale = end_scale,
		color = { r = 1, g = 1, b = 1, a = 1 },
		cyclic = true,
		affected_by_wind = false,
		show_when_smoke_off = true,
		movement_slow_down_factor = 0,
		vertical_speed_slowdown = 0,
		render_layer = "selection-box",
		[type == "trivial-smoke" and "animation" or "picture"] =
		{
			filename = "__even-distribution__/graphics/distribution-marker.png",
			width = 64,
			height = 64,
			scale = 0.5,
			frame_count = 1
		}
	}
end

data:extend{
	createMarker("distribution-marker", "simple-entity-with-force", 9999999, 10, nil, 0.001, 1),
	createMarker("distribution-final-anim", "trivial-smoke", 20, 20, 20, 1, 2),
	createMarker("cleanup-distribution-anim", "trivial-smoke", 28, 28, 20, 0.001, 2),
	{
		type = "flying-text",
		name = "distribution-text",
		flags = {"not-on-map", "placeable-off-grid"},
		time_to_live = 150,
		speed = 0.05
	}
}