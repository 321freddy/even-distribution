local config = {}

config.colors = -- flying text colors
{
	insufficientItems = { r = 1, g = 0, b = 0 }, -- red
	targetFull = { r = 1, g = 1, b = 0 }, -- yellow
	default = { r = 1, g = 1, b = 1 }, -- white
}

config.ignoredEntities = -- entity type or name
{ 
    ["player"] = true, 
    ["character-corpse"] = true, 
    ["factory-overlay-controller"] = true,

    ["transport-belt"] = true, 
    ["underground-belt"] = true, 
    ["splitter"] = true, 
    ["loader"] = true, 
    ["simple-entity"] = true, 
    ["simple-entity-with-force"] = true, 
    ["simple-entity-with-owner"] = true,
}

config.rangeMultiplier = 3 -- inventory cleanup drop range multiplier

config.fuelLimitProfiles = 
{
    typeSetting  = "dragFuelLimitType",
    valueSetting = "dragFuelLimit",

    stacks = {
        min  = 0,
        max  = 1,
        step = 0.1,
        next = "items",
    },
    items = {
        min  = 0,
        max  = 200,
        step = 1,
        next = "mj",
    },
    mj = {
        min  = 0,
        max  = 100,
        step = 1,
        next = "stacks",
    },
}

return config