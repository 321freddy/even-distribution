-- Controller for the Even Distribution settings GUI

local this = {}
local util = scripts.util
local components = scripts.components
local gui = scripts["gui-tools"]
local mod_gui = require("mod-gui")
local config = require("config")
local templates = scripts["settings-gui.gui-templates"].templates

local helpers = scripts.helpers
local _ = helpers.on

function this.on_lua_shortcut(event)
	local player = _(game.players[event.player_index]); if player:isnot("valid player") then return end

	if event.prototype_name == "open-even-distribution-settings" then
		
		if player.is_shortcut_toggled("open-even-distribution-settings") then
			this.destroyGUI(player)
		else
			this.buildGUI(player)
		end
	end
end

function this.on_open_even_distribution_settings(event)
	local player = _(game.players[event.player_index]); if player:isnot("valid player") then return end

	if player.is_shortcut_toggled("open-even-distribution-settings") then
		this.destroyGUI(player)
	else
		this.buildGUI(player)
	end
end

function this.buildGUI(player)
	gui.destroy(player, templates.settingsWindow)
	gui.create(player, templates.settingsWindow, { })
	player.set_shortcut_toggled("open-even-distribution-settings", true)
end

function this.destroyGUI(player)
	gui.destroy(player, templates.settingsWindow)
	player.set_shortcut_toggled("open-even-distribution-settings", false)
end

return this