local this = {}
local util = scripts.util
local setup = scripts.setup
local metatables = scripts.metatables
local item_lib = scripts["item-lib"]
local config = require("config")

function this.on_tick(event) -- handles distribution events
	local distrEvents = global.distrEvents
	
	if distrEvents[event.tick] then
		for player_index, cache in pairs(distrEvents[event.tick]) do
			this.distributeItems(player_index, cache) -- distribute items
		end
		distrEvents[event.tick] = nil
	end
end

function this.distributeItems(player_index, cache)
	local player = game.players[player_index]
	
	if util.isValidPlayer(player) then
		local takeFromCar = player.mod_settings["take-from-car"].value
		local item = cache.item
		local totalItems = item_lib.getPlayerItemCount(player, item, takeFromCar)
		if cache.half then totalItems = math.ceil(totalItems / 2) end

		util.distribute(cache.entities, totalItems, function(entity, amount)

			local itemsInserted = 0
			local color
			
			if amount > 0 then
				local takenFromPlayer = item_lib.removePlayerItems(player, item, amount, takeFromCar, false)
				
				if takenFromPlayer < amount then color = config.colors.insufficientItems end
				
				if takenFromPlayer > 0 then
					itemsInserted = entity.insert{ name = item, count = takenFromPlayer }
					local failedToInsert = takenFromPlayer - itemsInserted
					
					if failedToInsert > 0 then
						item_lib.returnToPlayer(player, item, failedToInsert, takeFromCar, false)
						color = config.colors.targetFull
					end
				end
			else
				color = config.colors.insufficientItems
			end
			
			-- visuals
			this.spawnDistributionText(entity, item, itemsInserted, 0, color)

		end)
	end
		
	this.resetCache(cache)
end

function this.on_selected_entity_changed(event)
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

function this.on_player_fast_transferred(event)
	local index = event.player_index
	local player = game.players[index]
	local cache = global.cache[index]
	local selected = player.selected

	if cache.tick == event.tick and util.isValid(selected) and event.entity == selected then

		if event.from_player then
			if cache.item then
				cache.itemCount = item_lib.getBuildingItemCount(selected, cache.item) - cache.itemCount
				
				cache.half = false
				if cache.itemCount > 0 then
					-- determine if half a stack has been transferred (buggy if player only has 1 of the item in inventory but more in car!)
					cache.half = (cache.itemCount == math.floor(cache.cursorStackCount / 2))
				end

				this.stackTransferred(selected, player, cache) -- handle stack transfer
			end
		else
			-- ...
		end

	end
end

function this.stackTransferred(entity, player, cache) -- handle vanilla stack transfer
	if not util.isIgnoredEntity(entity, player) then
		local distrEvents = global.distrEvents -- register new distribution event
		if cache.applyTick and distrEvents[cache.applyTick] then distrEvents[cache.applyTick][player.index] = nil end
		
		-- wait before applying distribution (seconds defined in mod config)
		local delay = player.mod_settings["distribution-delay"].value
		cache.applyTick = game.tick + math.max(math.ceil(60 * delay), 1)
		
		distrEvents[cache.applyTick] = distrEvents[cache.applyTick] or {}
		distrEvents[cache.applyTick][player.index] = cache
		
		if not cache.entities[entity] then
			--cache.markers[entity] = this.markEntity(entity) -- visuals
			cache.entities[entity] = entity

			rendering.draw_sprite{
				sprite = "item/"..cache.item,
				render_layer = "selection-box",
				target = entity,
				players = {player},
				surface = entity.surface,
			}

			local pos = entity.position
			cache.markers[entity] = entity.surface.create_entity{
				name = "highlight-box",
				position = { pos.x + (x or 0), pos.y + (y or 0) },
				source = entity,
				render_player_index = player.index,
				box_type = "electricity",
				blink_interval = 0,
			}
		end
	end
	
	cache.tick = nil -- reset event handler tick to avoid invalid on_player_cursor_stack_changed execution
	
	-- give items back to player
	local giveToPlayer = entity.remove_item{ name = cache.item, count = cache.itemCount }
	local cursor_stack = player.cursor_stack
	
	if not player.mod_settings["immediately-start-crafting"].value or util.isIgnoredEntity(entity, player) then
		giveToPlayer = giveToPlayer + this.undoConsumption(entity, player, cache)
	end
	
	if giveToPlayer > 0 then
		if cursor_stack.valid_for_read then
			player.insert{ name = cache.item, count = giveToPlayer }
		else
			cursor_stack.set_stack{ name = cache.item, count = giveToPlayer }
		end
	end
	
	this.destroyTransferText(entity)
end

function this.undoConsumption(entity, player, cache) -- some entities consume items directly after vanilla stack transfer
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

function this.markEntity(entity, name, x, y) -- create distribution marker
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

function this.destroyTransferText(entity) -- remove flying text from stack transfer
	local surface = entity.surface
	local pos = entity.position
	
	util.destroyIfValid(surface.find_entities_filtered{
		name = "flying-text",
		area = {{pos.x, pos.y - 1}, {pos.x, pos.y}},
		limit = 1
	}[1])
end

function this.unmarkEntities(cache) -- destroy all distribution markers of a player (using cache)
	for marker in util.epairs(cache.markers) do
		if util.isValid(marker) then
			this.markEntity(marker, "distribution-final-anim", 0, 0)
			marker.destroy()
		end
	end
	
	cache.markers = metatables.new("entityAsIndex")
end

function this.spawnDistributionText(entity, item, amount, offY, color) -- spawn distribution text
	local surface = entity.surface
	local pos = entity.position

	surface.create_entity{ -- spawn text
		name = "distribution-text",
		position = { pos.x - 0.5, pos.y + (offY or 0) },
		text = {"", "       ", -amount, " ", game.item_prototypes[item].localised_name},
		color = color or config.colors.default
	}
end

function this.resetCache(cache)
	cache.item = nil
	cache.half = false
	cache.entities = metatables.new("entityAsIndex")
	this.unmarkEntities(cache)
	rendering.clear() -- TODO: fix
end

function this.on_pre_player_mined_item(event) -- remove mined/dead entities from cache
	local entity = event.entity
	
	for _,cache in pairs(global.cache) do
		if cache.entities[entity] then
			cache.entities[entity] = nil
			util.destroyIfValid(cache.markers[entity]) -- remove marker
			cache.markers[entity] = nil
		end
	end
end

this.on_robot_pre_mined = this.on_pre_player_mined_item
this.on_entity_died = this.on_pre_player_mined_item

function this.script_raised_destroy(event)
	event = event or {}
	event.entity = event.entity or event.destroyed_entity or event.destroyedEntity or event.target or nil
	
	if (util.isValid(event.entity)) then this.on_pre_player_mined_item(event) end
end

function this.on_player_died(event) -- resets distribution cache and events for that player
	local cache = global.cache[event.player_index]
	
	if cache then
		this.resetCache(cache)
		
		local distrEvents = global.distrEvents -- remove distribution event
		if cache.applyTick and distrEvents[cache.applyTick] then
			distrEvents[cache.applyTick][event.player_index] = nil
			cache.applyTick = nil
		end
	end
end

this.on_player_left_game = this.on_player_died

return this