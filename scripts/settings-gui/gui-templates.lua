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
		--dlog("clicked")
	end,
	children = {
		{
			type = "scroll-pane",
			style = "control_settings_scroll_pane", --"scroll_pane_with_dark_background_under_subheader",
			vertical_scroll_policy = "auto-and-reserve-space",
			onCreated = function(self, data)
				_(self.style):set{
					minimal_width = 350,
					minimal_height = 344,
					maximal_height = 600,
				}
			end,
			children = {
				{
					type = "frame",
					direction = "vertical",
					style = "ed_settings_inner_frame",
					children = 
					{
						{
							type = "flow",
							name = "frame_header",
							direction = "horizontal",
							children = 
							{
								{
									type = "label",
									name = "frame_caption",
									style = "heading_3_label_yellow",
									caption = "CTRL+Click Drag: Distribute items",
								},
								{
									type = "empty-widget",
									style = "ed_stretch",
								},
								{
									type = "checkbox",
									name = "enable_drag_distribute",
									caption = "Enable",
									state = true,
									onCreated = function(self)
										local player = _(self.gui.player)
										self.state = player:setting("enable-ed")
										self.parent.frame_caption.enabled = self.state
									end,
									onChanged = function(event)
										local self = event.element
										self.parent.parent.frame_content.visible = self.state
										self.parent.frame_caption.enabled = self.state

										local player = event.element.gui.player
										player.mod_settings["enable-ed"] = {value=self.state}
									end,
								},
							}
						},
						{
							type = "flow",
							name = "frame_content",
							direction = "vertical",
							onCreated = function(self)
								self.visible = _(self.gui.player):setting("enable-ed")
							end,
							children = 
							{
								{
									type = "label",
									caption = "123123123123",
								},
								{
									type = "label",
									caption = "asdasdasdasd",
								},
							}
						},
					}
				},
				{
					type = "frame",
					direction = "vertical",
					style = "ed_settings_inner_frame",
					children = 
					{
						{
							type = "flow",
							name = "frame_header",
							direction = "horizontal",
							children = 
							{
								{
									type = "label",
									name = "frame_caption",
									style = "heading_3_label_yellow",
									caption = "CTRL+Click Drag: Take items",
								},
								{
									type = "empty-widget",
									style = "ed_stretch",
								},
								{
									type = "checkbox",
									name = "enable_drag_take",
									caption = "Enable",
									state = true,
									onChanged = function(event)
										local self = event.element
										self.parent.parent.frame_content.visible = self.state
										self.parent.frame_caption.enabled = self.state
									end,
								},
							}
						},
						{
							type = "flow",
							name = "frame_content",
							direction = "vertical",
							children = 
							{
								{
									type = "label",
									caption = "123123123123",
								},
								{
									type = "label",
									caption = "asdasdasdasd",
								},
							}
						},
					}
				},
				{
					type = "frame",
					direction = "vertical",
					style = "ed_settings_inner_frame",
					children = 
					{
						{
							type = "flow",
							name = "frame_header",
							direction = "horizontal",
							children = 
							{
								{
									type = "label",
									name = "frame_caption",
									style = "heading_3_label_yellow",
									caption = "Inventory Cleanup Hotkey",
								},
								{
									type = "empty-widget",
									style = "ed_stretch",
								},
								{
									type = "checkbox",
									name = "enable_ic",
									caption = "Enable",
									state = true,
									onChanged = function(event)
										local self = event.element
										self.parent.parent.frame_content.visible = self.state
										self.parent.frame_caption.enabled = self.state
									end,
								},
							}
						},
						{
							type = "flow",
							name = "frame_content",
							direction = "vertical",
							children = 
							{
								{
									type = "label",
									caption = "123123123123",
								},
								{
									type = "label",
									caption = "asdasdasdasd",
								},
							}
						},
					}
				},
			}
		},
	}
}

return {this, function(_controller) controller = _controller end}