local this = {}
local util = scripts.util
local metatables = scripts.metatables
local config = require("config")

local helpers = scripts.helpers
local _ = helpers.on

function helpers:mark(type, x, y) -- create distribution marker of given type on entity
	type = type or "distribution-marker"
	local pos = self.position
	local params = {
		name = type,
		position = { pos.x + (x or 0), pos.y + (y or 0) },
		force = self.force,
	}
	
	if type == "distribution-marker" then
		marker = self.surface.create_entity(params)
		marker.destructible = false
		return marker
	else
		self.surface.create_trivial_smoke(params)
	end
end

function helpers:unmark() -- destroy distribution marker of entity
	self:mark("distribution-final-anim")
    self.destroy()
end

function this.unmark(cache) -- destroy all distribution markers of a player (using cache)
	_(cache.markers):where("valid", function(marker)
		_(marker):unmark()
	end)
	
	cache.markers = metatables.new("entityAsIndex")
end



function helpers:destroyTransferText() -- remove flying text from stack transfer
	local surface = self.surface
	local pos = self.position
	
	util.destroyIfValid(surface.find_entities_filtered{
		name = "flying-text",
		area = {{pos.x, pos.y - 1}, {pos.x, pos.y}},
		limit = 1
	}[1])
end

function helpers:spawnDistributionText(item, amount, offY, color) -- spawn distribution text on entity
	local surface = self.surface
	local pos = self.position

	surface.create_entity{ -- spawn text
		name = "distribution-text",
		position = { pos.x - 0.5, pos.y + (offY or 0) },
		text = {"", "       ", -amount, " ", game.item_prototypes[item].localised_name},
		color = color or config.colors.default
	}
end

return this