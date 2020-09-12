local control = scripts.helpers
local _ = scripts.helpers.on

-- Helper functions for LuaControl --

function control:itemcount(...)
    if self.is_player() then 
        return self:playeritemcount(...) 
    else
        return self.get_item_count(...)
    end
end

function control:requests(...)
    if self.is_player() then 
        return _(self.character):entityrequests(...) 
    else
        return self:entityrequests(...) 
    end
end

function control:request(...)
    if self.is_player() then 
        return _(self.character):entityrequest(...) 
    else
        return self:entityrequest(...) 
    end
end

function control:remainingRequest(item)
	return self:request(item) - self.get_item_count(item)
end

function control:inventory(name)
    if name == nil or name == "main" then -- get main inventory
        return self.get_main_inventory() or
               (self.type == "container" and self.get_inventory(defines.inventory.chest)) or
               (self.type == "logistic-container" and self.get_inventory(defines.inventory.chest)) or
               (self.type == "car" and self.get_inventory(defines.inventory.car_trunk)) or
               (self.type == "spider-vehicle" and self.get_inventory(defines.inventory.car_trunk)) or
               (self.type == "cargo-wagon" and self.get_inventory(defines.inventory.cargo_wagon))

    elseif name == "input" then
        return (self.type == "furnace" and self.get_inventory(defines.inventory.furnace_source)) or
               (self.type == "assembling-machine" and self.get_inventory(defines.inventory.assembling_machine_input)) or
               (self.type == "lab" and self.get_inventory(defines.inventory.lab_input)) or
               (self.type == "rocket-silo" and self.get_inventory(defines.inventory.rocket_silo_rocket))
    
    elseif name == "output" then
        return self.get_output_inventory()
    
    elseif name == "modules" then
        return self.get_module_inventory()
    
    elseif name == "ammo" then
        return (self.type == "ammo-turret" and self.get_inventory(defines.inventory.turret_ammo)) or
               (self.type == "car" and self.get_inventory(defines.inventory.car_ammo)) or
               (self.type == "spider-vehicle" and self.get_inventory(defines.inventory.car_ammo)) or
               (self.type == "artillery-wagon" and self.get_inventory(defines.inventory.artillery_wagon_ammo)) or
               (self.type == "artillery-turret" and self.get_inventory(defines.inventory.artillery_turret_ammo)) or
               (self.type == "character" and self.get_inventory(defines.inventory.character_ammo)) or
               (self.type == "character" and self.get_inventory(defines.inventory.editor_ammo))
    
    elseif name == "fuel" then
        return self.get_fuel_inventory()
    
    elseif name == "burnt_result" then
        return self.get_burnt_result_inventory()
    end
    
    -- get specific inventory
    return self.get_inventory(defines.inventory[name])
end

function control:contents(name)
    if name == nil and self.is_player() then 
        return self:playercontents() 
    end

    local inv = self:inventory(name)
    if _(inv):isnot("valid") then return {} end
    return inv.get_contents()
end

local function insert(self, name, item, amount)
    if amount <= 0 then return 0 end
    local inv = self:inventory(name)
    return inv and inv.insert{ name = item, count = amount } or 0
end

-- priority insert with fuel and ammo limits
function control:customInsert(player, item, amount, fuelProfile, ammoProfile)
    local inserted = 0
    local prototype = game.item_prototypes[item]
    
    if amount <= 0 then return inserted end
    if prototype.fuel_category then
        local limit = math.max(0, player:itemLimit(prototype, fuelProfile) - self:itemcount(item))

        local insertedHere = insert(self, "fuel", item, math.min(amount, limit))
        inserted = inserted + insertedHere
        amount = amount - insertedHere
    end

    if amount <= 0 then return inserted end
	if prototype.type == "ammo" then
        local limit = math.max(0, player:itemLimit(prototype, ammoProfile) - self:itemcount(item))
        local insertedHere = insert(self, "ammo", item, math.min(amount, limit))
        inserted = inserted + insertedHere
        amount = amount - insertedHere
    end

    if amount <= 0 then return inserted 
    else
        local insertedHere = insert(self, "input", item, amount)
        inserted = inserted + insertedHere
        amount = amount - insertedHere
	end

    if amount <= 0 then return inserted end
    if not self:is("crafting machine") or not _(self.get_recipe()):hasIngredient(item) then
        local insertedHere = insert(self, "modules", item, amount)
        inserted = inserted + insertedHere
        amount = amount - insertedHere
    end

    if self.type == "roboport" then
        if amount <= 0 then return inserted end
        local insertedHere = insert(self, "roboport_robot", item, amount)
        inserted = inserted + insertedHere
        amount = amount - insertedHere

        if amount <= 0 then return inserted end
        insertedHere = insert(self, "roboport_material", item, amount)
        inserted = inserted + insertedHere
        amount = amount - insertedHere
    end
    
    if amount <= 0 then return inserted
    else
        local insertedHere = insert(self, "main", item, amount)
        inserted = inserted + insertedHere
        amount = amount - insertedHere
	end

    return inserted
end