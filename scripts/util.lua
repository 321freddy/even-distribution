local util = {}

function util.doEvery(tick, func, args)
	if (game.tick % tick) == 0 then func(args) end
end

function util.offsetBox(box, off)
	local x1, y1, x2, y2 = box.left_top.x, box.left_top.y, box.right_bottom.x, box.right_bottom.y
	return {left_top = {x = x1 + off.x, y = y1 + off.y}, right_bottom = {x = x2 + off.x, y = y2 + off.y}}
end

function util.extendBox(box, tiles)
	local x1, y1, x2, y2 = box.left_top.x, box.left_top.y, box.right_bottom.x, box.right_bottom.y
	return {left_top = {x = x1 - tiles, y = y1 - tiles}, right_bottom = {x = x2 + tiles, y = y2 + tiles}}
end

function util.getPerimeter(pos, radius)
	return {left_top = {x = pos.x - radius, y = pos.y - radius}, right_bottom = {x = pos.x + radius, y = pos.y + radius}}
end

function util.isValid(object)
	return object and object.valid
end

function util.destroyIfValid(object)
	if util.isValid(object) then object.destroy() end
end

function util.isValidPlayer(player) -- valid, connected and alive player
	return util.isValid(player) and player.connected and player.controller_type ~= defines.controllers.ghost
end

function util.isCraftingMachine(entity)
	return entity.type == "furnace" or entity.type == "assembling-machine" or entity.type == "rocket-silo"
end

function util.getPlayerMainInventory(player)
	if player.controller_type == defines.controllers.character then
		return player.get_inventory(defines.inventory.player_main)
	elseif player.controller_type == defines.controllers.god then
		return player.get_inventory(defines.inventory.god_main)
	end
end

function util.shallowCopy(original) -- Creates a shallow copy of a table
    copy = {}
    for key,value in pairs(original) do copy[key] = value  end
    return copy
end

function util.countTable(tbl)
	local count = 0
	for _,__ in pairs(tbl) do count = count + 1 end
	return count
end

function util.isEmpty(tbl)
	return next(tbl) == nil
end

function util.epairs(tbl) -- iterator for tables with entity based indices
	local id, start
	local surface, x, y
	local tbls, tblsx, value
	
	tblId = rawget(tbl, "id")
	tblPos = rawget(tbl, "pos")
	if tblId then
		start = true
	elseif not tblPos then
		return function () end
	end
	
	return function ()
		if id or start then
			start = false
			id, value = next(tblId, id)
			
			if value == nil then
				if not tblPos then return end
				surface, tbls = next(tblPos)
				if not tbls then return end
				x, tblsx = next(tbls)
			else
				return value
			end
		end
		
		while value == nil do
			y, value = next(tblsx, y)
			
			if value == nil then
				x, tblsx = next(tbls, x)
				y = nil
				
				if not tblsx then
					surface, tbls = next(tblPos, surface)
					if not tbls then return end
					x, tblsx = next(tbls, x)
					y = nil
				end
			end
		end
		
		return value
	end
end

return util