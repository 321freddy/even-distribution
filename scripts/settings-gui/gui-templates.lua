-- GUI templates for the Even Distribution settings

local this = {templates = {}}
local util = scripts.util
local config = require("config")
local gui = scripts["gui-tools"]
local controller

local helpers = scripts.helpers
local _ = helpers.on


-- this.templates.showSettingsButton = {
-- 	type = "sprite-button",
-- 	name = "show-settings-button",
-- 	onCreated = function (self, data)
-- 		-- self.style = "attach-notes-view-button"
-- 		-- self.tooltip = { "tooltips.view-note" }
		
-- 		_(self.style):set{
-- 			width  = 36,
-- 			height = 36,
-- 		}
-- 	end,
-- 	onClicked = function (event)
-- 		local player = _(event.element.gui.player)
-- 		local opened = _(player.opened)
-- 		local cache  = _(global.cache[player.index])
		
-- 		if notes[opened] then
		
-- 			cache.noteIsHidden = not cache.noteIsHidden -- toggle hidden state if note is present
-- 		else
-- 			notes[opened] = {} -- create new note if no note is present
			
-- 			local note = notes[opened]
-- 			local setting = player.mod_settings["show-marker-by-default"].value
-- 			if setting and not components.marker.isDisabledForEntity(opened) then -- create marker if necessary
-- 				if not util.isValid(note.marker) then note.marker = components.marker.create(opened) end
-- 			end
			
-- 			cache.noteIsHidden = false
-- 		end
		
-- 		controller.buildGUI(player, cache) -- rebuild gui
-- 		opened.last_user = player
-- 	end
-- }


this.templates.settingsWindow = {
	type = "frame",
	name = "settings-window",
	direction = "vertical",
	caption = "Even Distribution",
	root = function(player) return player.gui.screen end,
	onClicked = function(event)
		local index  = event.player_index
		local player = _(event.element.gui.player)
		local cache  = _(global.cache[player.index])

		-- ...
	end,
	children = {
		{
			type = "tabbed-pane",
			children = {
				{
					type = "tab",
					caption = "CTRL+Click Drag: Distribute items",
				},
				{
					type = "tab",
					caption = "CTRL+Click Drag: Take items",
				},
				{
					type = "tab",
					caption = "Inventory Cleanup Hotkey",
				},
			}
		},
	}
}

return {this, function(_controller) controller = _controller end}