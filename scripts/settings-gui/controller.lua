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


function this.on_gui_opened(event)
	local index  = event.player_index
	local player = _(game.players[index])
	local cache  = _(global.cache[index])

	if event.gui_type == defines.gui_type.controller and player:is("valid player") then
		this.buildGUI(player, cache)
		
	else -- if openend then
		this.destroyGUI(player, cache)
	end
end

function this.on_gui_closed(event)
	local index = event.player_index
	local player = game.players[index]
	local cache = global.cache[index]

	this.destroyGUI(player, cache)
end

function this.buildGUI(player, cache)
	this.destroyGUI(player, cache)
	gui.create(player, templates.settingsWindow, { })
end

function this.destroyGUI(player, cache)
	gui.destroy(player, templates.settingsWindow)
	--cache.openedEntityGui = nil
end

return this