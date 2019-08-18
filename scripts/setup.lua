-- Sets up the global table and parses settings

local setup = {}
local util = scripts.util
local metatables = scripts.metatables
local defaultTrash = require("default-trash")

function setup.on_init()
	global.cache = global.cache or {}
	global.distrEvents = global.distrEvents or {}
	global.settings = global.settings or {}
	global.defaultTrash = setup.generateTrashItemList()

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
	
	for player_index,player in pairs(game.players) do
		setup.createPlayerCache(player_index)

		-- init default settings
		local settings = global.settings[player_index] or {}

		if settings.customTrash == nil then
			settings.customTrash = {
				["iron-plate"]      = 800,
				["copper-plate"]    = 600,
				["steel-plate"]     = 600,
				["stone-brick"]     = 400,
				["artillery-shell"] = 0,
			}
		end
		if settings.enableDragDistribute == nil         then settings.enableDragDistribute = true end
		if settings.enableDragTake == nil               then settings.enableDragTake = true end
		if settings.enableInventoryCleanupHotkey == nil then settings.enableInventoryCleanupHotkey = true end
		if settings.takeFromInventory == nil            then settings.takeFromInventory = true end
		if settings.takeFromCar == nil                  then settings.takeFromCar = true end
		if settings.cleanupRequestOverflow == nil       then settings.cleanupRequestOverflow = true end


		-- migrate settings from old mod version
		if settings.version == nil then
			if player.mod_settings["inventory-cleanup-custom-trash"].value == "iron-plate:800 copper-plate:600 steel-plate:600 stone-brick:400" then
				-- change saved default value from old mod version
				settings.customTrash["artillery-shell"] = 0
			end

			settings.enableDragDistribute   = player.mod_settings["enable-ed"].value
			settings.takeFromCar            = player.mod_settings["take-from-car"].value
			settings.cleanupRequestOverflow = player.mod_settings["cleanup-logistic-request-overflow"].value

		--elseif settings.version == "0.3.x" then
			-- ...
		end

		-- update settings
		settings.version = game.active_mods["even-distribution"]
		global.settings[player_index] = settings

		setup.parsePlayerSettings(player_index)

		dlog(global.settings)
	end
end

setup.on_configuration_changed = setup.on_init

function setup.on_player_created(event)
	setup.createPlayerCache(event.player_index)
	setup.parsePlayerSettings(event.player_index)
	
	-- local player = game.players[event.player_index]
	-- player.print({"message.usage"}, {r=1, g=0.85, b=0})
end

function setup.on_runtime_mod_setting_changed(event)
	local setting = setup.parsedSettings[event.setting]
	if setting then setting.parse(event.player_index) end
end

function setup.createPlayerCache(index)
	global.cache[index] = global.cache[index] or {}
	global.cache[index].items = global.cache[index].items or {}
	global.cache[index].markers = global.cache[index].markers or {}
	metatables.use(global.cache[index].markers, "entityAsIndex")
	global.cache[index].entities = global.cache[index].entities or {}
	metatables.use(global.cache[index].entities, "entityAsIndex")
end

function setup.parsePlayerSettings(index)
	for __,setting in pairs(setup.parsedSettings) do setting.parse(index) end
end

local function logSettingParseError(playerIndex, setting, value)
	local player, playerName = game.players[playerIndex], "<UNKNOWN>"
	local msg = {"message.setting-parse-error", {"mod-setting-name."..setting}, value, ""}
	
	if util.isValid(player) then
		player.print(msg)
		playerName = player.name
	end
	
	msg[4] = {"message.for-user", playerName}
	log(msg)
end

local function parsedListSetting(settingName, settingInternal, regex, toString, isValid)
	return {
		parse = function (index)
			local setting = game.players[index].mod_settings[settingName].value
			local parsed = {}
			
			for name,value in string.gmatch(setting, regex) do
				name = string.lower(name)
				value = value and tonumber(value)
				
				if isValid(name, value) then
					parsed[name] = value or true
				else
					logSettingParseError(index, settingName, toString(name, value))
				end
			end
			
			global.settings[index][settingInternal] = parsed
		end
	}
end

setup.parsedSettings = {
	["ignored-entities"] = parsedListSetting(
		"ignored-entities", "ignoredEntities", "%s*([^ ]+)%s*",
		function (name) return tostring(name) end, -- toString
		function (name) return game.entity_prototypes[name] end -- isValid
	),
}

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