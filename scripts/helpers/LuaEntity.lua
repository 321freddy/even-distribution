local util = scripts.util
local config = require("config")
local entity = scripts.helpers
local _ = scripts.helpers.on

-- Helper functions for LuaEntity --

-- counts the items and also includes items that are being consumed (fuel in burners, ingredients in assemblers, etc.)
function entity:entityitemcount(item)
    local count = self.get_item_count(item)
	
    if self:is("crafting machine") then
		local ingredients = _(self.get_recipe()):ingredientcount(item)
		
		if ingredients > 0 then
			if self.is_crafting() then count = count + ingredients end
			count = count + self.products_finished * ingredients
			if self.type == "rocket-silo" then
				count = count + self.rocket_parts * ingredients
			end
		end
	else
		count = count + self:outputitemcount(item)
    end
    
	if self:has("valid", "burner") then
		local burning = self.burner.currently_burning
		if burning and burning.name == item then count = count + 1 end
	end
	
	return count
end

function entity:outputitemcount(item) -- get count of a specific item in any output inserters/loaders
    local count = 0
    local filter = {
        type = "inserter",
        area = _(self.bounding_box):expand(3)
	}
    
	for __,entity in pairs(self.surface.find_entities_filtered(filter)) do
        if entity.pickup_target == self:toPlain() then
            local held = entity.held_stack
            if held.valid_for_read and held.name == item then 
                count = count + held.count 
            end
        end
    end

    filter.type = "loader"
    for __,entity in pairs(self.surface.find_entities_filtered(filter)) do
        if entity.loader_type == "output" then 
            count = count + entity.get_item_count(item) 
        end
    end
    
	return count
end

function entity:entityrequests() -- fetch all requests as table
	local requests = {}
	
    if self.request_slot_count > 0 then
		for i = 1, self.request_slot_count do
			local request = self.get_request_slot(i)
			if request then
				local item, amount = request.name, request.count
				requests[item] = math.max(requests[item] or 0, amount)
			end
		end
	end
	
	return requests
end

function entity:entityrequest(item) -- fetch specific item request
	local count = 0

	if self.request_slot_count > 0 then
		for i = 1, self.request_slot_count do
			local request = self.get_request_slot(i)
			if request and request.name == item and request.count > count then 
				count = request.count 
			end
		end
	end

	return count
end

function entity:isIgnored(player)
	return config.ignoredEntities[self.type] or 
		   config.ignoredEntities[self.name] or 
		   global.settings[player.index].ignoredEntities[self.name]
end

-- for turrets
function entity:supportsAmmo(item)
	local attackParameters = self.prototype.attack_parameters
	local ammoType = item.get_ammo_type("turret") or item.get_ammo_type()
	return attackParameters and (attackParameters.ammo_category == ammoType.category)
end