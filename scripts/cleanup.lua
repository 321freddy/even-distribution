-- Inventory Cleanup Hotkey

local cleanup = {}
local drag = scripts.drag
local item_lib = scripts["item-lib"]
local util = scripts.util
local setup = scripts.setup
local metatables = scripts.metatables
local config = require("config")

local helpers = scripts.helpers
local _ = helpers.on

function cleanup.on_inventory_cleanup(event)
	local player = _(game.players[event.player_index]); if player:isnot("valid player") then return end
	local items  = _(player:trashItems())             ; if items:is("empty") then return end

	local area = util.getPerimeter(player.position, player:droprange())
	local entities = _(cleanup.getEntities(area, player)); if entities:is("empty") then return end
	
	local offY, marked = 0, metatables.new("entityAsIndex")
	local dropToChests = player:setting("drop-trash-to-chests")


	items:each(function(item, totalItems)

		local filtered = cleanup.filterEntities(entities, item, dropToChests)
		
		if #filtered > 0 then
			util.distribute(filtered, totalItems, function(entity, amount)
				
				local itemsInserted = 0
				
				if amount > 0 then
					local takenFromPlayer = player:removeItems(item, amount, false, true)
					
					if takenFromPlayer > 0 then
						itemsInserted = cleanup.insert(entity, item, takenFromPlayer)
						local failedToInsert = takenFromPlayer - itemsInserted
						
						if failedToInsert > 0 then
							player:returnItems(item, failedToInsert, false, true)
						end
					end
				end
				
				-- visuals
				if itemsInserted > 0 then
					drag.spawnDistributionText(entity, item, itemsInserted, offY)
					
					if not marked[entity] then
						drag.markEntity(entity, "cleanup-distribution-anim")
						marked[entity] = true
					end
				end

			end)
			offY = offY - 0.5
		end
	end)
end

function cleanup.insert(entity, item, amount)

	local prototype = game.item_prototypes[item]
	if entity.type == "furnace" and not (entity.get_recipe() or entity.previous_recipe) then
		local inventory = entity.get_fuel_inventory()
		if inventory then return inventory.insert{ name = item, count = amount } else return 0 end
	elseif entity.prototype.logistic_mode == "requester" then
		local requested = item_lib.getRemainingRequest(item, entity)
		if requested > 0 then return entity.insert{ name = item, count = math.min(amount, requested) } else return 0 end
	elseif prototype.type == "module" and entity.get_module_inventory() then
		local inventory = item_lib.getInputInventory(entity)  
		if inventory then return inventory.insert{ name = item, count = amount } else return 0 end -- Only insert modules in craftng machine input inventory
	elseif entity.type == "car" then
		if prototype.type == "ammo" then
			local inventory = entity.get_inventory(defines.inventory.car_ammo)
			if inventory then return inventory.insert{ name = item, count = amount } else return 0 end
		elseif prototype.fuel_category then
			local inventory = entity.get_fuel_inventory()
			if inventory then return inventory.insert{ name = item, count = amount } else return 0 end
		end
	end
	
	return entity.insert{ name = item, count = amount } -- Default distribution
end

function cleanup.filterEntities(entities, item, dropToChests)
	local result = metatables.new("entityAsIndex")
	local prototype = game.item_prototypes[item]
	
	_(entities):each(function(__, entity)

		if entity.can_insert(item) then
			if entity.burner and entity.burner.fuel_categories[prototype.fuel_category] and entity.get_fuel_inventory().can_insert(item) then
				result[entity] = entity
			elseif util.isCraftingMachine(entity) and item_lib.isIngredient(item, entity.get_recipe() or (entity.type == "furnace" and entity.previous_recipe)) then
				result[entity] = entity
			elseif entity.prototype.logistic_mode == "requester" and item_lib.getRemainingRequest(item, entity) > 0 then
				result[entity] = entity
			elseif dropToChests and (entity.type == "container" or entity.type == "logistic-container") and entity.get_item_count(item) > 0 then
				result[entity] = entity
			elseif entity.type == "lab" and entity.get_inventory(defines.inventory.lab_input).can_insert(item) then
				result[entity] = entity
			elseif entity.type == "ammo-turret" and item_lib.isTurretAmmo(prototype, entity) then
				result[entity] = entity
			elseif entity.type == "roboport" then
				result[entity] = entity
			elseif entity.type == "car" and prototype.type == "ammo" then
				result[entity] = entity
			end
		end
	end)
	
	return result
end

function cleanup.getEntities(area, player)
	local entities = {}
	for __,entity in ipairs(player.surface.find_entities_filtered{ area = area, force = player.force }) do
		if util.isValid(entity) and entity.operable and not util.isIgnoredEntity(entity, player) then
			entities[#entities + 1] = entity
		end
	end
	return entities
end



return cleanup