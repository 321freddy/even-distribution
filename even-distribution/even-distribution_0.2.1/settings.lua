data:extend{
	{
		type = "double-setting",
		name = "distribution-delay",
		setting_type = "runtime-per-user",
		order = "aa",
		default_value = 0.9,
		minimum_value = 0.01
	},
	{
		type = "bool-setting",
		name = "take-from-car",
		setting_type = "runtime-per-user",
		order = "ab",
		default_value = true
	},
	{
		type = "bool-setting",
		name = "immediately-start-crafting",
		order = "ac",
		setting_type = "runtime-per-user",
		default_value = true,
	},
	{
		type = "string-setting",
		name = "inventory-cleanup-custom-trash",
		order = "bb",
		setting_type = "runtime-per-user",
		default_value = "iron-plate:600 copper-plate:600",
		allow_blank = true
	},
	{
		type = "int-setting",
		name = "max-inventory-cleanup-drop-range",
		order = "ba",
		setting_type = "runtime-per-user",
		default_value = 30,
		minimum_value = 0,
		maximum_value = 100
	},
	{
		type = "bool-setting",
		name = "cleanup-logistic-request-overflow",
		order = "bc",
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