local this = {}
local player = scripts.helpers
local _ = scripts.helpers.on

-- Helper functions for LuaPlayer --

function player:setting(name)
    return self.mod_settings[name].value
end

function player:droprange()
	return math.min(self.reach_distance * config.rangeMultiplier, self:setting("max-inventory-cleanup-drop-range"))
end

function player:trashItems()
	local playerContents = self:contents()
	local trashslots     = self:inventory("player_trash")
	local customTrash    = global.settings[self.index].customTrash
	local defaultTrash   = global.defaultTrash
	
	local trash
	if _(trashslots):is("valid") then trash = trashslots.get_contents() else trash = {} end
	
	local autoTrash
	if self:has("valid", "character") then autoTrash = self.auto_trash_filters else autoTrash = {} end
	
	local requests
	if self:setting("cleanup-logistic-request-overflow") then requests = self:requests() else requests = {} end
	
	for item,count in pairs(playerContents) do
		local targetAmount = autoTrash[item] or requests[item] or customTrash[item] or defaultTrash[item]
		
		if targetAmount then
			local surplus = count - targetAmount
			if surplus > 0 then trash[item] = (trash[item] or 0) + surplus end
		end
	end
	
	return trash
end

function player:itemcount(item, includeCar)
	local mainInv      = self:inventory(); if _(mainInv):isnot("valid") then return 0 end
	local cursor_stack = self.cursor_stack
	local count        = mainInv.get_item_count(item)
	
	if cursor_stack.valid_for_read and cursor_stack.name == item then
		count = count + cursor_stack.count
	end
	
	if includeCar and self.driving and self:has("valid", "vehicle") then
		local vehicleInv = _(self.vehicle):inventory("car_trunk")
		if _(vehicleInv):is("valid") then count = count + vehicleInv.get_item_count(item) end
	end
		   
	return count
end

function player:contents()
	local mainInv      = self:inventory(); if _(mainInv):isnot("valid") then return {} end
	local cursor_stack = self.cursor_stack
	local contents     = mainInv.get_contents()

	if cursor_stack.valid_for_read then
		local item = cursor_stack.name
		contents[item] = (contents[item] or 0) + cursor_stack.count
	end
		   
	return contents
end

function player:requests()
	local requests = {}
	local character = self.character
	
    if _(character):is("valid") and character.request_slot_count > 0 then -- fetch requests
    
		for i = 1, character.request_slot_count do
			local request = character.get_request_slot(i)
			if request then
				local item, amount = request.name, request.count
				requests[item] = math.max(requests[item] or 0, amount)
			end
		end
	end
	
	return requests
end

function player:inventory(name)

    if name == nil then -- get main inventory
        return self.get_main_inventory()
    end
    
    -- get specific inventory
    return self.get_inventory(defines.inventory[name])
end

return this