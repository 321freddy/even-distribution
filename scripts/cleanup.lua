-- Inventory Cleanup Hotkey

local cleanup = {}
local drag = scripts.drag
local util = scripts.util
local metatables = scripts.metatables
local config = require("config")

local helpers = scripts.helpers
local _ = helpers.on

function cleanup.on_inventory_cleanup(event)
	local player = _(game.players[event.player_index])
	if player:isnot("valid player") or not player:setting("enableInventoryCleanupHotkey") then return end
	
	local items    = _(player:trashItems())              ; if items:is("empty") then return end
	local area     = _(player.position):perimeter(player:droprange())
	local entities = _(cleanup.getEntities(area, player)); if entities:is("empty") then return end
	
	local offY, marked = 0, metatables.new("entityAsIndex")
	local dropToChests = player:setting("dropTrashToChests")


	items:each(function(item, totalItems)

		local filtered = cleanup.filterEntities(entities, item, dropToChests)
		
		if #filtered > 0 then
			util.distribute(filtered, totalItems, function(entity, amount)
				
				local itemsInserted = 0
				entity = _(entity)
				
				if amount > 0 then
					local takenFromPlayer = player:removeItems(item, amount, true, false, true)
					
					if takenFromPlayer > 0 then
						itemsInserted = cleanup.insert(player, entity, item, takenFromPlayer)
						local failedToInsert = takenFromPlayer - itemsInserted
						
						if failedToInsert > 0 then
							player:returnItems(item, failedToInsert, false, true)
						end
					end
				end
				
				-- visuals
				if itemsInserted > 0 then
					entity:spawnDistributionText(item, itemsInserted, offY)
					
					if not marked[entity] then
						entity:mark(player)
						marked[entity] = true
					end
				end

			end)
			offY = offY - 0.5
		end
	end)

	-- if #marked > 0 then
	-- 	player.play_sound{ path = "utility/tutorial_notice" }
	-- end
end

function cleanup.insert(player, entity, item, amount)

	local useFuelLimit = player:setting("cleanupUseFuelLimit")
	local useAmmoLimit = player:setting("cleanupUseAmmoLimit")
	if entity.type == "furnace" and not (entity.get_recipe() or entity.previous_recipe) then
		return entity:customInsert(player, item, amount, false, true, false, useFuelLimit, useAmmoLimit, {
			fuel     = true,
			ammo     = false,
			input    = false,
			modules  = false,
			roboport = false,
			main     = false,
		})

	elseif entity.prototype.logistic_mode == "requester" then
		local requested = entity:remainingRequest(item)
		return entity:customInsert(player, item, math.min(amount, requested), false, true, false, useFuelLimit, useAmmoLimit, {
			fuel     = false,
			ammo     = false,
			input    = false,
			modules  = false,
			roboport = false,
			main     = true,
		})
		
	elseif entity.type == "car" or entity.type == "spider-vehicle" then
		return entity:customInsert(player, item, amount, false, true, false, useFuelLimit, useAmmoLimit, {
			fuel     = true,
			ammo     = true,
			input    = false,
			modules  = false,
			roboport = false,
			main     = false,
		})
	end
	
	-- Default priority insertion
	return entity:customInsert(player, item, amount, false, true, false, useFuelLimit, useAmmoLimit, {
		fuel     = true,
		ammo     = true,
		input    = true,
		modules  = false,
		roboport = true,
		main     = true,
	}) 
end

function cleanup.filterEntities(entities, item, dropToChests)
	local result = metatables.new("entityAsIndex")
	local prototype = game.item_prototypes[item]
	
	_(entities):each(function(__, entity)
		entity = _(entity)

		if entity.can_insert(item) then
			if entity.burner and entity.burner.fuel_categories[prototype.fuel_category] and entity:inventory("fuel").can_insert(item) then
				result[entity] = entity
			elseif entity:is("crafting machine") and _(entity.get_recipe() or (entity.type == "furnace" and entity.previous_recipe)):hasIngredient(item) then
				result[entity] = entity
			elseif entity.prototype.logistic_mode == "requester" and entity:remainingRequest(item) > 0 then
				result[entity] = entity
			elseif dropToChests and (entity.type == "container" or entity.type == "logistic-container") and entity.get_item_count(item) > 0 then
				result[entity] = entity
			elseif entity.type == "lab" and entity:inventory("lab_input").can_insert(item) then
				result[entity] = entity
			elseif entity.type == "ammo-turret" and entity:supportsAmmo(prototype) then
				result[entity] = entity
			elseif entity.type == "roboport" then
				result[entity] = entity
			elseif (entity.type == "car" or entity.type == "spider-vehicle") and prototype.type == "ammo" then
				result[entity] = entity
			end
		end
	end)
	
	return result
end

function cleanup.getEntities(area, player)
	local entities = {}

	for __,entity in ipairs(player.surface.find_entities_filtered{ area = area, force = player.force }) do

		if _(entity):is("valid") and 
		   entity.operable and 
		   not entity.to_be_deconstructed(player.force) and 
		   not _(entity):isIgnored(player) then
			
			entities[#entities + 1] = entity
		end
	end
	
	return entities
end



return cleanup