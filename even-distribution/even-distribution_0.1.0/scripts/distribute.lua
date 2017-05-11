local distribute = {}
local util = scripts.util

function distribute.on_tick(event) -- handles distribution events
	local distrEvents = global.distrEvents
	
	if distrEvents[event.tick] then
		for player_index, cache in pairs(distrEvents[event.tick]) do
			distribute.applyDistribution(player_index, cache) -- distribute items
			cache.half = false -- reset half flag after distribution
		end
		distrEvents[event.tick] = nil
	end
end

function distribute.applyDistribution(player_index, cache)
	local player = game.players[player_index]
	
	local takeFromCar = settings.get_player_settings(player)["take-from-car"].value
	local totalItems = distribute.getPlayerItemCount(player, cache.item, takeFromCar)
	if cache.half then totalItems = math.ceil(totalItems / 2) end
	
	local insertAmount = math.floor(totalItems / #cache.entities)
	local remainder = totalItems % #cache.entities
	
	for entity in util.epairs(cache.entities) do
		if util.isValid(entity) then
			local amount = insertAmount
			if remainder > 0 then
				amount = amount + 1
				remainder = remainder - 1
			end
			
			if amount > 0 then
				local takenFromPlayer = distribute.removePlayerItems(player, cache.item, amount, takeFromCar)
				local itemsInserted = 0
				
				if takenFromPlayer > 0 then
					itemsInserted = entity.insert{ name = cache.item, count = takenFromPlayer }
					local failedToInsert = takenFromPlayer - itemsInserted
					
					if failedToInsert > 0 then
						distribute.returnToPlayer(player, cache.item, failedToInsert, takeFromCar)
					end
				end
				
				distribute.spawnDistributedText(entity, cache.item, itemsInserted)
			end
			
			distribute.unmarkEntity(entity)
			cache.entities[entity] = nil
		end
	end
end

function distribute.getPlayerItemCount(player, item, includeCar)
	local cursor_stack = player.cursor_stack
	local count = player.get_inventory(defines.inventory.player_main).get_item_count(item) +
				  player.get_inventory(defines.inventory.player_quickbar).get_item_count(item)
	
	if cursor_stack.valid_for_read and cursor_stack.name == item then
		count = count + cursor_stack.count
	end
	
	if includeCar and player.driving and util.isValid(player.vehicle) then
		local vehicle = player.vehicle.get_inventory(defines.inventory.car_trunk)
		if util.isValid(vehicle) then count = count + vehicle.get_item_count(item) end
	end
		   
	return count
end

function distribute.removePlayerItems(player, item, amount, takeFromCar)
	local cursor_stack = player.cursor_stack
	
	local removed = player.get_inventory(defines.inventory.player_main).remove{ name = item, count = amount }
	if amount <= removed then return removed end
	
	removed = removed + player.get_inventory(defines.inventory.player_quickbar).remove{ name = item, count = amount - removed }
	if amount <= removed then return removed end
	
	if cursor_stack.valid_for_read and cursor_stack.name == item then
		local result = math.min(cursor_stack.count, amount - removed)
		removed = removed + result
		cursor_stack.count = cursor_stack.count - result
		if amount <= removed then return removed end
	end
	
	if takeFromCar and player.driving and util.isValid(player.vehicle) then
		local vehicle = player.vehicle.get_inventory(defines.inventory.car_trunk)
		if util.isValid(vehicle) then removed = removed + vehicle.remove{ name = item, count = amount - removed } end
	end
	
	return removed
end

function distribute.returnToPlayer(player, item, amount, takenFromCar)
	local remaining = amount - player.insert{ name = item, count = amount }
	
	if remaining > 0 and takenFromCar and player.driving and util.isValid(player.vehicle) then
		local vehicle = player.vehicle.get_inventory(defines.inventory.car_trunk)
		if util.isValid(vehicle) then remaining = remaining - vehicle.insert{ name = item, count = remaining } end
	end
	
	if remaining > 0 then
		player.surface.spill_item_stack(player.position, { name = item, count = remaining }, false)
	end
end

function distribute.on_selected_entity_changed(event)
	local index = event.player_index
	local player = game.players[index]
	local cache = global.cache[index]
	local cursor_stack = player.cursor_stack
	local selected = player.selected

	if util.isValid(selected) and cursor_stack.valid_for_read then
		cache.tick = event.tick
		cache.item = cursor_stack.name
		cache.itemCount = distribute.getBuildingItemCount(selected, cursor_stack.name)
		cache.cursorStackCount = cursor_stack.count
	end
end

function distribute.on_player_cursor_stack_changed(event)
	local index = event.player_index
	local player = game.players[index]
	local cache = global.cache[index]
	local selected = player.selected

	if cache.tick == event.tick and util.isValid(selected) then
		cache.itemCount = distribute.getBuildingItemCount(selected, cache.item) - cache.itemCount
		
		if cache.itemCount > 0 then
			-- determine if half a stack has been transferred (buggy if player only has 1 of the item in inventory but more in car!)
			cache.half = (cache.itemCount == math.floor(cache.cursorStackCount / 2))
			
			distribute.stackTransferred(selected, player, cache) -- handle stack transfer
		end
	end
end

function distribute.getBuildingItemCount(entity, item) -- counts the items and also includes items that are being consumed (fuel in burners, ingredients in assemblers, etc.)
	local count = entity.get_item_count(item)
	local type = entity.prototype.type
	
	if type == "assembling-machine" or type == "furnace" then
		if entity.recipe and entity.crafting_progress > 0 then
			count = count + distribute.getRecipeIngredientCount(entity.recipe, item)
		end
	else
		count = count + distribute.getOutputEntityItemCount(entity, item, "inserter")
		count = count + distribute.getOutputEntityItemCount(entity, item, "loader")
	end
	if entity.burner then
		local burning = entity.burner.currently_burning
		if burning and burning.name == item then count = count + 1 end
	end
	
	return count
end

function distribute.getRecipeIngredientCount(recipe, item) -- get count of a specific item in recipe ingredients
	for _,ingredient in pairs(recipe.ingredients) do
		if ingredient.name == item then return ingredient.amount end
	end
	return 0
end

function distribute.getOutputEntityItemCount(origin, item, outputType) -- get count of a specific item in any output inserters/loaders
	local count = 0
	for _,entity in pairs(origin.surface.find_entities_filtered{
		type = outputType, area = util.offsetBox(util.extendBox(origin.prototype.collision_box, 3), origin.position)
	}) do
		if outputType == "inserter" then
			if entity.pickup_target == origin then
				local held = entity.held_stack
				if held.valid_for_read and held.name == item then count = count + held.count end
			end
		elseif outputType == "loader" then
			if entity.loader_type == "output" then count = count + entity.get_item_count(item) end
		end
	end
	return count
end

function distribute.stackTransferred(entity, player, cache) -- handle vanilla stack transfer
	local distrEvents = global.distrEvents -- register new distribution event
	if cache.applyTick and distrEvents[cache.applyTick] then distrEvents[cache.applyTick][player.index] = nil end
	
	local delay = settings.get_player_settings(player)["distribution-delay"].value
	cache.applyTick = game.tick + math.ceil(60 * delay) -- wait before applying distribution (seconds defined in mod config)
	
	distrEvents[cache.applyTick] = distrEvents[cache.applyTick] or {}
	distrEvents[cache.applyTick][player.index] = cache
	
	cache.tick = nil -- reset event handler tick to avoid invalid on_player_cursor_stack_changed execution
	
	local giveToPlayer = entity.remove_item{ name = cache.item, count = cache.itemCount } -- give items back to player
	local cursor_stack = player.cursor_stack
	
	if giveToPlayer > 0 then
		if cursor_stack.valid_for_read then
			player.insert{ name = cache.item, count = giveToPlayer }
		else
			cursor_stack.set_stack{ name = cache.item, count = giveToPlayer }
		end
	end
	
	distribute.destroyTransferText(entity)
	if not cache.entities[entity] then
		distribute.markEntity(entity) -- visuals
		cache.entities[entity] = entity
	end
end

function distribute.markEntity(entity) -- create distribution marker
	local surface = entity.surface
	local pos = entity.position
	
	surface.create_entity{
		name = "distribution-marker",
		position = { pos.x, pos.y + 1 }
	}
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

function distribute.unmarkEntity(entity) -- destroy distribution marker
	local surface = entity.surface
	local pos = entity.position
	
	util.destroyIfValid(surface.find_entities_filtered{ 
		name = "distribution-marker",
		area = {{ pos.x - 0.1, pos.y + 0.9 }, { pos.x + 0.1, pos.y + 1.1 }},
		limit = 1
	}[1])
end

function distribute.spawnDistributedText(entity, item, amount) -- spawn distribution text
	local surface = entity.surface
	local pos = entity.position

	surface.create_entity{ -- spawn text
		name = "flying-text",
		position = { pos.x - 1, pos.y },
		text = {"", "       ", -amount, " ", game.item_prototypes[item].localised_name},
		color = { r = 1, g = 1, b = 1 }
	}
end

function distribute.on_preplayer_mined_item(event) -- remove mined/dead entities from cache
	local entity = event.entity
	
	for _,cache in pairs(global.cache) do
		if cache.entities[entity] then
			cache.entities[entity] = nil
			distribute.unmarkEntity(entity)
		end
	end
end

distribute.on_robot_pre_mined = distribute.on_preplayer_mined_item
distribute.on_entity_died = distribute.on_preplayer_mined_item

return distribute