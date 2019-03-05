-- Common functions for handling items

local item_lib = {}
local util = scripts.util

function item_lib.getBuildingItemCount(entity, item) -- counts the items and also includes items that are being consumed (fuel in burners, ingredients in assemblers, etc.)
	local count = entity.get_item_count(item)
	
	if util.isCraftingMachine(entity) then
		if entity.get_recipe() then
			local ingredients = item_lib.getRecipeIngredientCount(entity.get_recipe(), item)
			if entity.is_crafting() then count = count + ingredients end
			count = count + entity.products_finished * ingredients
			if entity.type == "rocket-silo" then
				count = count + entity.rocket_parts * ingredients
			end
		end
	else
		count = count + item_lib.getOutputEntityItemCount(entity, item, "inserter")
		count = count + item_lib.getOutputEntityItemCount(entity, item, "loader")
	end
	if entity.burner then
		local burning = entity.burner.currently_burning
		if burning and burning.name == item then count = count + 1 end
	end
	
	return count
end

function item_lib.getOutputEntityItemCount(origin, item, outputType) -- get count of a specific item in any output inserters/loaders
	local count = 0
	for __,entity in pairs(origin.surface.find_entities_filtered{
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

function item_lib.getRecipeIngredientCount(recipe, item) -- get count of a specific item in recipe ingredients
	if not recipe then return 0 end
	for __,ingredient in pairs(recipe.ingredients) do
		if ingredient.name == item then return ingredient.amount end
	end
	return 0
end

function item_lib.getRecipeIngredients(recipe)
	local ingredients = {}
	
	for __,ingredient in pairs(recipe.ingredients) do
		local type, name, amount = ingredient.type, ingredient.name, ingredient.amount
		if type == "item" then ingredients[name] = amount end
	end
	
	return ingredients
end

function item_lib.isIngredient(item, recipe)
	if not recipe then return false end
	for __,ingredient in ipairs(recipe.ingredients) do
		if ingredient.type == "item" and ingredient.name == item then return true end
	end
end

function item_lib.isTurretAmmo(item, turret)
	local attackParameters = turret.prototype.attack_parameters
	local ammoType = item.get_ammo_type("turret") or item.get_ammo_type()
	return attackParameters and (attackParameters.ammo_category == ammoType.category)
end

function item_lib.getRequestAmount(item, requester)
	local count = 0
	if requester.request_slot_count > 0 then
		for i = 1, requester.request_slot_count do
			local request = requester.get_request_slot(i)
			if request and request.name == item and request.count > count then count = request.count end
		end
	end
	return count
end

function item_lib.getRemainingRequest(item, requester)
	return item_lib.getRequestAmount(item, requester) - requester.get_item_count(item)
end

function item_lib.getInputInventory(entity)
	return entity.get_inventory(defines.inventory.furnace_source) or
		   entity.get_inventory(defines.inventory.assembling_machine_input) or
		   entity.get_inventory(defines.inventory.lab_input) or
		   entity.get_inventory(defines.inventory.rocket_silo_rocket)
end

function item_lib.getInputContents(entity)
	local input = item_lib.getInputInventory(entity)
	if input then return input.get_contents() end
	return {}
end

return item_lib