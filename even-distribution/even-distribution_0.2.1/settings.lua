data:extend{
	{
		type = "double-setting",
		name = "distribution-delay",
		setting_type = "runtime-per-user",
		order = "a",
		default_value = 0.9,
		minimum_value = 0.01
	},
	{
		type = "bool-setting",
		name = "take-from-car",
		setting_type = "runtime-per-user",
		order = "b",
		default_value = true
	},
	{
		type = "string-setting",
		name = "inventory-cleanup-custom-trash",
		order = "d",
		setting_type = "runtime-per-user",
		default_value = "iron-plate:600 copper-plate:600",
		allow_blank = true
	},
	{
		type = "int-setting",
		name = "max-inventory-cleanup-drop-range",
		order = "c",
		setting_type = "runtime-per-user",
		default_value = 30,
		minimum_value = 0,
		maximum_value = 100
	},
	{
		type = "bool-setting",
		name = "cleanup-logistic-request-overflow",
		order = "e",
		setting_type = "runtime-per-user",
		default_value = true
	},
	{
		type = "bool-setting",
		name = "early-autotrash-research",
		order = "a",
		setting_type = "startup",
		default_value = true,
	}
}