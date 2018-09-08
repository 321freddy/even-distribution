local distribute = {}
local util = scripts.util
local setup = scripts.setup
local item_lib = scripts["item-lib"]

local colors = { -- flying text colors
	insufficientItems = { r = 1, g = 0, b = 0 }, -- red
	targetFull = { r = 1, g = 1, b = 0 }, -- yellow
	default = { r = 1, g = 1, b = 1 }, -- white
}

local ignoredEntities = { ["player"] = true, ["character-corpse"] = true, ["factory-overlay-controller"] = true }

function distribute.isIgnoredEntity(entity, player)
	return ignoredEntities[entity.type] or ignoredEntities[entity.name] or global.settings[player.index].ignoredEntities[entity.name]
end

function distribute.on_tick(event) -- handles distribution events
	local distrEvents = global.distrEvents
	
	if distrEvents[event.tick] then
		for player_index, cache in pairs(distrEvents[event.tick]) do
			distribute.distributeItems(player_index, cache) -- distribute items
			cache.half = false -- reset half flag after distribution
		end
		distrEvents[event.tick] = nil
	end
end

function distribute.distributeItems(player_index, cache)
	local player = game.players[player_index]
	
	if util.isValidPlayer(player) then
		local takeFromCar = player.mod_settings["take-from-car"].value
		local totalItems = item_lib.getPlayerItemCount(player, cache.item, takeFromCar)
		if cache.half then totalItems = math.ceil(totalItems / 2) end
		
		distribute.distributeItem(player, cache.entities, cache.item, takeFromCar, totalItems, false)
	end
		
	distribute.resetCache(cache)
end

function distribute.distributeItem(player, entities, item, takeFromCar, totalItems, cleanup, offY, marked)
	local insertAmount = math.floor(totalItems / #entities)
	local remainder = totalItems % #entities
	
	for entity in util.epairs(entities) do
		if util.isValid(entity) then
			local amount = insertAmount
			if remainder > 0 then
				amount = amount + 1
				remainder = remainder - 1
			end
			
			local itemsInserted = 0
			local color
			
			if amount > 0 then
				local takenFromPlayer = item_lib.removePlayerItems(player, item, amount, takeFromCar, cleanup)
				
				if not cleanup and takenFromPlayer < amount then color = colors.insufficientItems end
				
				if takenFromPlayer > 0 then
					itemsInserted = item_lib.entityInsert(entity, item, takenFromPlayer, cleanup)
					local failedToInsert = takenFromPlayer - itemsInserted
					
					if failedToInsert > 0 then
						item_lib.returnToPlayer(player, item, failedToInsert, takeFromCar, cleanup)
						color = colors.targetFull
					end
				end
			elseif not cleanup then
				color = colors.insufficientItems
			end
			
			-- visuals
			if not cleanup or itemsInserted > 0 then
				distribute.spawnDistributionText(entity, item, itemsInserted, offY, color)
				
				if cleanup and marked and not marked[entity] then
					distribute.markEntity(entity, "cleanup-distribution-anim")
					marked[entity] = true
				end
			end
		end
	end
end

function distribute.on_selected_entity_changed(event)
	local index = event.player_index
	local player = game.players[index]
	if not util.isValidPlayer(player) or not player.mod_settings["enable-ed"].value then return end
	
	local cursor_stack = player.cursor_stack
	local selected = player.selected

	if util.isValid(selected) and cursor_stack.valid_for_read then
		local cache = global.cache[index]
		cache.tick = event.tick
		cache.item = cursor_stack.name
		cache.itemCount = item_lib.getBuildingItemCount(selected, cursor_stack.name)
		cache.cursorStackCount = cursor_stack.count
		
		if util.isCraftingMachine(selected) then
			cache.isCrafting = selected.is_crafting()
			cache.inputContents = item_lib.getInputContents(selected)
		end
		
		if selected.burner then cache.remainingFuel = selected.burner.remaining_burning_fuel end
	end
end

function distribute.on_player_cursor_stack_changed(event)
	local index = event.player_index
	local player = game.players[index]
	local cache = global.cache[index]
	local selected = player.selected

	if cache.tick == event.tick and util.isValid(selected) and cache.item then
		cache.itemCount = item_lib.getBuildingItemCount(selected, cache.item) - cache.itemCount
		
		if cache.itemCount > 0 then
			-- determine if half a stack has been transferred (buggy if player only has 1 of the item in inventory but more in car!)
			cache.half = (cache.itemCount == math.floor(cache.cursorStackCount / 2))
			
			distribute.stackTransferred(selected, player, cache) -- handle stack transfer
		end
	end
end

function distribute.stackTransferred(entity, player, cache) -- handle vanilla stack transfer
	if not distribute.isIgnoredEntity(entity, player) then
		local distrEvents = global.distrEvents -- register new distribution event
		if cache.applyTick and distrEvents[cache.applyTick] then distrEvents[cache.applyTick][player.index] = nil end
		
		-- wait before applying distribution (seconds defined in mod config)
		local delay = player.mod_settings["distribution-delay"].value
		cache.applyTick = game.tick + math.max(math.ceil(60 * delay), 1)
		
		distrEvents[cache.applyTick] = distrEvents[cache.applyTick] or {}
		distrEvents[cache.applyTick][player.index] = cache
		
		if not cache.entities[entity] then
			cache.markers[entity] = distribute.markEntity(entity) -- visuals
			cache.entities[entity] = entity
		end
	end
	
	cache.tick = nil -- reset event handler tick to avoid invalid on_player_cursor_stack_changed execution
	
	-- give items back to player
	local giveToPlayer = entity.remove_item{ name = cache.item, count = cache.itemCount }
	local cursor_stack = player.cursor_stack
	
	if not player.mod_settings["immediately-start-crafting"].value or distribute.isIgnoredEntity(entity, player) then
		giveToPlayer = giveToPlayer + distribute.undoConsumption(entity, player, cache)
	end
	
	if giveToPlayer > 0 then
		if cursor_stack.valid_for_read then
			player.insert{ name = cache.item, count = giveToPlayer }
		else
			cursor_stack.set_stack{ name = cache.item, count = giveToPlayer }
		end
	end
	
	distribute.destroyTransferText(entity)
end

function distribute.undoConsumption(entity, player, cache) -- some entities consume items directly after vanilla stack transfer
	local item = cache.item
	local burner = entity.burner
	
	if util.isCraftingMachine(entity) and not cache.isCrafting and entity.is_crafting() and item_lib.isIngredient(item, entity.get_recipe())then
		local returnCount = item_lib.getRecipeIngredientCount(entity.get_recipe(), item)
		local inputContents = item_lib.getInputContents(entity)
		
		for name,count in pairs(cache.inputContents) do
			local missing = count - (inputContents[name] or 0)
			if missing > 0 then entity.insert{ name = name, count = missing } end
			if item == name then returnCount = returnCount - missing end
		end
		
		entity.crafting_progress = 0
		return returnCount
	elseif burner and burner.remaining_burning_fuel > cache.remainingFuel and burner.currently_burning.name == item then
		burner.remaining_burning_fuel = 0
		return 1
	end
	
	return 0
end

function distribute.markEntity(entity, name, x, y) -- create distribution marker
	name = name or "distribution-marker"
	local pos = entity.position
	local params = {
		name = name,
		position = { pos.x + (x or 0), pos.y + (y or 0) },
		force = entity.force,
	}
	
	if name == "distribution-marker" then
		marker = entity.surface.create_entity(params)
		marker.destructible = false
		return marker
	else
		entity.surface.create_trivial_smoke(params)
	end
end

function distribute.destroyTransferText(entity) -- remove flying text from stack transfer
	local surface = entity.surface
	local pos = entity.position
	
	util.destroyIfValid(surface.find_entities_filtered{
		name = "flying-text",
		area = {{pos.x, pos.y - 1}, {pos.x, pos.y}},
		limit = 1
	}[1])
end

function distribute.unmarkEntities(cache) -- destroy all distribution markers of a player (using cache)
	for marker in util.epairs(cache.markers) do
		if util.isValid(marker) then
			distribute.markEntity(marker, "distribution-final-anim", 0, 0)
			marker.destroy()
		end
	end
	
	cache.markers = setup.newEAITable()
end

function distribute.spawnDistributionText(entity, item, amount, offY, color) -- spawn distribution text
	local surface = entity.surface
	local pos = entity.position

	surface.create_entity{ -- spawn text
		name = "distribution-text",
		position = { pos.x - 0.5, pos.y + (offY or 0) },
		text = {"", "       ", -amount, " ", game.item_prototypes[item].localised_name},
		color = color or colors.default
	}
end

function distribute.resetCache(cache)
	cache.item = nil
	cache.entities = setup.newEAITable()
	distribute.unmarkEntities(cache)
end

function distribute.on_pre_player_mined_item(event) -- remove mined/dead entities from cache
	local entity = event.entity
	
	for _,cache in pairs(global.cache) do
		if cache.entities[entity] then
			cache.entities[entity] = nil
			util.destroyIfValid(cache.markers[entity]) -- remove marker
			cache.markers[entity] = nil
		end
	end
end

distribute.on_robot_pre_mined = distribute.on_pre_player_mined_item
distribute.on_entity_died = distribute.on_pre_player_mined_item

function distribute.script_raised_destroy(event)
	event = event or {}
	event.entity = event.entity or event.destroyed_entity or event.destroyedEntity or event.target or nil
	
	if (util.isValid(event.entity)) then distribute.on_pre_player_mined_item(event) end
end

function distribute.on_player_died(event) -- resets distribution cache and events for that player
	local cache = global.cache[event.player_index]
	
	if cache then
		distribute.resetCache(cache)
		
		local distrEvents = global.distrEvents -- remove distribution event
		if cache.applyTick and distrEvents[cache.applyTick] then
			distrEvents[cache.applyTick][event.player_index] = nil
			cache.applyTick = nil
		end
	end
end

distribute.on_player_left_game = distribute.on_player_died

--[[
-- picker extended dollies fix
function distribute.on_picker_dollies_moved(event)
	local entity = event.moved_entity
	
	if util.isValid(entity) then
		for index,cache in pairs(global.cache) do
			local marker = cache.markers[entity]
			local pos = entity.position
			if util.isValid(marker) then marker.teleport{ pos.x, pos.y + 1 } end
		end
	end
end

if remote.interfaces["picker"] and remote.interfaces["picker"]["dolly_moved_entity_id"] then
	local eventID = remote.call("picker", "dolly_moved_entity_id")
	if type(eventID) == "number" then
		script.on_event(remote.call("picker", "dolly_moved_entity_id"), distribute.on_picker_dollies_moved)
	end
end
]]--

return distribute