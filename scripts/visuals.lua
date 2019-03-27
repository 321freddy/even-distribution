local this = {}
local util = scripts.util
local metatables = scripts.metatables
local config = require("config")

local helpers = scripts.helpers
local _ = helpers.on

function helpers:mark(player, item, count) -- create highlight-box marker with item and count
    
    if item ~= nil then

        local box = _(self.selection_box)
        local x_scale = 0.63 * box:boxwidth()
        local y_scale = 0.63 * box:boxheight()

        return {
            rendering.draw_sprite{
                sprite = "utility/entity_info_dark_background",
                render_layer = "selection-box",
                target = self,
                players = {player},
                surface = self.surface,
                x_scale = x_scale,
                y_scale = y_scale,
            },
            rendering.draw_sprite{
                sprite = "item/"..item,
                render_layer = "selection-box",
                target = self,
                players = {player},
                surface = self.surface,
                x_scale = x_scale,
                y_scale = y_scale,
            },
            self.surface.create_entity{
                name = "highlight-box",
                position = self.position,
                source = self,
                render_player_index = player.index,
                box_type = "electricity",
                blink_interval = 0,
            },
        }
    else
        -- blink animation
        return self.surface.create_entity{
            name = "highlight-box",
            position = self.position,
            source = self,
            render_player_index = player.index,
            box_type = "electricity",
            blink_interval = 6,
            time_to_live = 60 * 1,
        }
    end
end

function helpers:unmark() -- destroy distribution marker of entity
    local source, player

    self:where("table", function(__, marker)
            marker.destroy()
        end)
        :where("number", function(__, id)
            source = source or _(rendering.get_target(id).entity)
            player = player or _(rendering.get_players(id)[1])
            rendering.destroy(id)
        end)

    if source:is("valid") and player:is("valid player") then source:mark(player) end
end

function this.unmark(cache) -- destroy all distribution markers of a player (using cache)
	_(cache.markers):each(function(markers)
        _(markers):unmark()
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