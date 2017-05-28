-- Autotrash Modifications --

if settings.startup["early-autotrash-research"].value then
	local tech = data.raw.technology["character-logistic-trash-slots-1"]
	tech.prerequisites = { "logistics" }
	tech.unit = {
		count = 30,
		ingredients = { {"science-pack-1", 1} },
		time = 15
    }

	tech = data.raw.technology["auto-character-logistic-trash-slots"]
	tech.prerequisites = { "character-logistic-trash-slots-1" }
	tech.unit = {
		count = 50,
		ingredients = { {"science-pack-1", 1} },
		time = 15
    }
	
	tech = data.raw.technology["character-logistic-trash-slots-2"]
	tech.prerequisites = { "logistic-robotics" }
end