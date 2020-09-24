-- Sets up the global table and parses settings

local setup = {}
local util = scripts.util
local metatables = scripts.metatables
local defaultTrash = require("default-trash")
local config = require("config")

local helpers = scripts.helpers
local _ = helpers.on

function setup.on_init()
	global.cache = global.cache or {}
	global.distrEvents = global.distrEvents or {}
	global.settings = global.settings or {}
	global.defaultTrash = setup.generateTrashItemList()

	global.allowedEntities = _(game.entity_prototypes)
								:where(function(prototype)
									return util.hasInventory(prototype) and 
										   not config.ignoredEntities[prototype.type] and 
										   not config.ignoredEntities[prototype.name]
								end)
								:map(function(name)
									return name, true
								end)
								:toPlain()

	-- GUI events are saved in global.guiEvents["EVENT NAME"][PLAYER INDEX][GUI ELEMENT INDEX]
	global.guiEvents = global.guiEvents or 
	{ 
		onCheckedStateChanged   = {},
		onClicked               = {},
		onElementChanged        = {},
		onSelectionStateChanged = {},
		onTextChanged           = {},
		onValueChanged          = {},
		onConfirmed             = {},
		onSelectedTabChanged    = {},
		onSwitchStateChanged    = {},
		onLocationChanged       = {}, 
	}

	-- Fuel upgrade list (ascending fuel value)
	global.fuelList = _(game.item_prototypes)
						:where("fuel")
						:toArray()
						:groupBy("fuel_category")
						:sort(function(a,b)
							return a.fuel_value < b.fuel_value or
								   a.fuel_acceleration_multiplier < b.fuel_acceleration_multiplier or
								   a.fuel_top_speed_multiplier < b.fuel_top_speed_multiplier or
								   a.fuel_emissions_multiplier < b.fuel_emissions_multiplier
						end)
						:toPlain()

	-- Ammo upgrade list (ascending damage)
	global.ammoList = _(game.item_prototypes)
						:where("ammo")
						:toArray()
						:groupBy(function(__,prototype)
							return prototype.get_ammo_type().category
						end)
						:sort(function(a,b)
							return _(a):calculateDamage() < _(b):calculateDamage()
						end)
						:toPlain()
	
	for player_index,player in pairs(game.players) do
		setup.setupPlayerGlobalTable(player_index, player)
	end

	for _,force in pairs(game.forces) do
		setup.enableLogisticsTab(force) 
	end
end

setup.on_configuration_changed = setup.on_init

function setup.on_player_created(event)
	setup.setupPlayerGlobalTable(event.player_index)
end

function setup.setupPlayerGlobalTable(player_index, player)
	player = player or game.players[player_index]
	setup.createPlayerCache(player_index)
	setup.migrateSettings(player)	
end

function setup.createPlayerCache(index)
	global.cache[index] = global.cache[index] or {}
	global.cache[index].items = global.cache[index].items or {}
	global.cache[index].markers = global.cache[index].markers or {}
	metatables.use(global.cache[index].markers, "entityAsIndex")
	global.cache[index].entities = global.cache[index].entities or {}
	metatables.use(global.cache[index].entities, "entityAsIndex")
end

function setup.migrateSettings(player)
	local settings = global.settings[player.index] or {}
	global.settings[player.index] = settings

	-- default values
	if settings.enableDragDistribute == nil         then settings.enableDragDistribute = true end
	if settings.enableDragFuelLimit == nil          then settings.enableDragFuelLimit = false end
	if settings.dragFuelLimit == nil                then settings.dragFuelLimit = 0.5 end
	if settings.dragFuelLimitType == nil            then settings.dragFuelLimitType = "stacks" end
	if settings.enableDragAmmoLimit == nil          then settings.enableDragAmmoLimit = false end
	if settings.dragAmmoLimit == nil                then settings.dragAmmoLimit = 0.5 end
	if settings.dragAmmoLimitType == nil            then settings.dragAmmoLimitType = "stacks" end
	if settings.dragMode == nil                     then settings.dragMode = "distribute" end
	if settings.takeFromInventory == nil            then settings.takeFromInventory = true end
	if settings.takeFromCar == nil                  then settings.takeFromCar = true end
	if settings.replaceItems == nil                 then settings.replaceItems = true end
	if settings.distributionDelay == nil            then settings.distributionDelay = 0.9 end

	if settings.enableInventoryCleanupHotkey == nil then settings.enableInventoryCleanupHotkey = true end
	if settings.cleanupRequestOverflow == nil       then settings.cleanupRequestOverflow = true end
	if settings.dropTrashToChests == nil       		then settings.dropTrashToChests = true end
	if settings.cleanupUseLimits == nil       		then settings.cleanupUseLimits = true end
	if settings.cleanupDropRange == nil       		then settings.cleanupDropRange = 30 end

	if settings.enableInventoryFillHotkey == nil    then settings.enableInventoryFillHotkey = true end

	-- migrate settings from old mod versions
	if settings.version == nil then
		settings.version                = "1.0.0"
		settings.enableDragDistribute   = player.mod_settings["enable-ed"].value
		settings.takeFromCar            = player.mod_settings["take-from-car"].value
		settings.cleanupRequestOverflow = player.mod_settings["cleanup-logistic-request-overflow"].value
		settings.dropTrashToChests      = player.mod_settings["drop-trash-to-chests"].value
		settings.distributionDelay      = player.mod_settings["distribution-delay"].value
		settings.cleanupDropRange       = player.mod_settings["max-inventory-cleanup-drop-range"].value
		dlog("Player ("..player.name..") settings migrated from none to 1.0.0")
	end
	--if settings.version == "0.3.x" then
		-- ...
	-- end
end


function setup.on_runtime_mod_setting_changed(event)
	
end

function setup.on_force_created(event)
	setup.enableLogisticsTab(event.force or event.destination)
end
setup.on_forces_merged = setup.on_force_created
setup.on_technology_effects_reset = setup.on_force_created

function setup.enableLogisticsTab(force)
	force.technologies["enable-logistics-tab"].researched = true
end

function setup.generateTrashItemList()
	local items = {}
	
	for name,item in pairs(game.item_prototypes) do
		if not (item.place_result or item.place_as_equipment_result or item.has_flag("hidden")) then -- or item.place_as_tile_result
			local default = defaultTrash[name] or defaultTrash[item.subgroup.name] or defaultTrash[item.group.name]
			
			if default and default ~= "ignore" then
				if item.fuel_category and not defaultTrash[name] then -- fuels default to 2 stacks as desired amount
					items[name] = 2 * item.stack_size
				else
					items[name] = default
				end
			end
		end
	end
	
	return items
end

function setup.on_load()
	metatables.refresh(global)
end

return setup