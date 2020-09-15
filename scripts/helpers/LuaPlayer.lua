local config = require("config")
local player = scripts.helpers
local _ = scripts.helpers.on

-- Helper functions for LuaPlayer --

function player:setting(name)
	local setting = global.settings[self.index][name]
	if setting == nil then return self.mod_settings[name].value end
	return setting
end

function player:changeSetting(name, newValue)
	local setting = global.settings[self.index]
	if setting[name] == nil then 
		self.mod_settings[name] = { value = newValue } 
	else
		setting[name] = newValue
	end
end

function player:droprange()
	return math.min(self.reach_distance * config.rangeMultiplier, self:setting("max-inventory-cleanup-drop-range"))
end

function player:trashItems()
	local defaultTrash = global.defaultTrash
	local trash        = self:contents("character_trash")
	
	local requests, autoTrash
	if self:has("valid", "character") then 
		autoTrash = self.auto_trash_filters

		for item,amount in pairs(autoTrash) do
			if amount >= 4294967295 then -- max value set to infinity, so no autotrash
				autoTrash[item] = nil
			end
		end

		if self:setting("cleanupRequestOverflow") then 
			requests = self:requests()
		else 
			requests = {} 
		end
	else 
		requests = {} 
		autoTrash = {}
	end

	for item,count in pairs(self:contents()) do
		local targetAmount = autoTrash[item] or requests[item] or defaultTrash[item] --or customTrash[item] or defaultTrash[item]
		
		if targetAmount then
			local surplus = count - targetAmount
			if surplus > 0 then trash[item] = (trash[item] or 0) + surplus end
		end
	end
	
	return trash
end

function player:playeritemcount(item, includeInv, includeCar)
	local count = 0
	
	local cursor_stack = self.cursor_stack
	if cursor_stack.valid_for_read and cursor_stack.name == item then
		count = count + cursor_stack.count
	elseif not includeInv and not includeCar then
		return global.cache[self.index].cursorStackCount or 0
	end

	if includeInv then
		local mainInv = self:inventory(); 
		if _(mainInv):is("valid") then count = count + mainInv.get_item_count(item) end
	end

	if includeCar and self.driving and self:has("valid", "vehicle") then
		local vehicleInv = _(self.vehicle):inventory("car_trunk")
		if _(vehicleInv):is("valid") then count = count + vehicleInv.get_item_count(item) end
	end
		   
	return count
end

function player:playercontents()
	local contents     = self:contents("main")
	local cursor_stack = self.cursor_stack
	
	if cursor_stack.valid_for_read then
		local item = cursor_stack.name
		contents[item] = (contents[item] or 0) + cursor_stack.count
	end
		   
	return contents
end

function player:removeItems(item, amount, takeFromInv, takeFromCar, takeFromTrash)
	local removed = 0
	if takeFromTrash then
		local trash = self:inventory("character_trash")
		if _(trash):is("valid") then
			removed = trash.remove{ name = item, count = amount }
			if amount <= removed then return removed end
		end
	end	

	if takeFromInv then
		local main = self:inventory()
		if _(main):is("valid") then
			removed = removed + main.remove{ name = item, count = amount - removed }
			if amount <= removed then return removed end
		end
	end
	
	local cursor_stack = self.cursor_stack
	if cursor_stack.valid_for_read and cursor_stack.name == item then
		local result = math.min(cursor_stack.count, amount - removed)
		removed = removed + result
		cursor_stack.count = cursor_stack.count - result
		if amount <= removed then return removed end
	elseif not takeFromInv and not takeFromCar and not takeFromTrash then
		local main = self:inventory()
		if _(main):is("valid") then
			return removed + main.remove{ name = item, count = amount - removed }
		end
	end
	
	if takeFromCar and self.driving and self:has("valid", "vehicle") then
		local vehicleInv = _(self.vehicle):inventory("car_trunk")
		if _(vehicleInv):is("valid") then removed = removed + vehicleInv.remove{ name = item, count = amount - removed } end
	end
	
	return removed
end

function player:returnItems(item, amount, takenFromCar, takenFromTrash)
	local remaining = amount - self.insert{ name = item, count = amount }
	
	if remaining > 0 and takenFromCar and self.driving and self:has("valid", "vehicle") then
        local vehicleInv = _(self.vehicle):inventory("car_trunk")
        if _(vehicleInv):is("valid") then remaining = remaining - vehicleInv.insert{ name = item, count = remaining } end
	end
	
	if remaining > 0 and takenFromTrash then
        local trash = self:inventory("character_trash")
        if _(trash):is("valid") then remaining = remaining - trash.insert{ name = item, count = remaining } end
	end
	
	if remaining > 0 then
		self.surface.spill_item_stack(self.position, { name = item, count = remaining }, false)
	end
end

function player:itemLimit(prototype, profile)
	if profile and self:setting(profile.enableSetting) then
		local limit = self:setting(profile.valueSetting)
		local type = self:setting(profile.typeSetting)

		if type == "items" then
			return math.ceil(limit)
		elseif type == "stacks" then
			return math.ceil(limit * (prototype.stack_size or 1))
		elseif type == "mj" then
			return math.ceil((limit * 1000000) / (prototype.fuel_value or 1))
		end
	end

	return math.huge
end