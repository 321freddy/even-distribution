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
	name = "ed_settings_window",
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
			vertical_scroll_policy = "auto-and-reserve-space",
			style = {
				parent = "control_settings_scroll_pane", --"scroll_pane_with_dark_background_under_subheader",
				minimal_width = 350,
				minimal_height = 344, -- Inventory GUI height
				maximal_height = 600,
			},
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
										self.state = player:setting("enableDragDistribute")
										self.parent.frame_caption.enabled = self.state
									end,
									onChanged = function(event)
										local self = event.element
										self.parent.parent.frame_content.visible = self.state
										self.parent.frame_caption.enabled = self.state

										local player = _(self.gui.player)
										player:changeSetting("enableDragDistribute", self.state)
									end,
								},
							}
						},
						{
							type = "flow",
							name = "frame_content",
							direction = "vertical",
							onCreated = function(self)
								self.visible = _(self.gui.player):setting("enableDragDistribute")
							end,
							children = 
							{
								{
									type = "flow",
									direction = "horizontal",
									style = {
										vertical_align = "center",
									},
									children = 
									{
										{
											type = "label",
											-- style = "heading_3_label_yellow",
											caption = "Distribute items from",
										},
										{
											type = "empty-widget",
											style = "ed_stretch",
										},
										
									}
								},
								{
									type = "flow",
									direction = "horizontal",
									style = {
										vertical_align = "center",
									},
									children = 
									{
										{
											type = "label",
											-- style = "heading_3_label_yellow",
											caption = "Distribute items from",
										},
										{
											type = "empty-widget",
											style = "ed_stretch",
										},
										{
											type = "sprite-button",
											name = "button_take_from_hand",
											tooltip = "Hand",
											sprite = "utility/hand",
											style = {
												parent = "ed_switch_button_selected",
												minimal_width  = 40,
												minimal_height = 40,
												left_margin    = -2,
												right_margin   = -2,
											},
											onChanged = function(event)
												local flow = event.element.parent
												flow.button_take_from_inventory.style = "ed_switch_button"
												flow.button_take_from_car.style       = "ed_switch_button"
												
												local player = _(flow.gui.player)
												player:changeSetting("takeFromInventory", false)
												player:changeSetting("takeFromCar", false)
											end,
										},
										{
											type = "sprite-button",
											name = "button_take_from_inventory",
											tooltip = "Inventory",
											sprite = "entity/character",
											style = {
												parent = "ed_switch_button",
												minimal_width  = 40,
												minimal_height = 40,
												left_margin    = -2,
												right_margin   = -2,
											},
											onCreated = function(self)
												local player = _(self.gui.player)
												self.style = player:setting("takeFromInventory") and "ed_switch_button_selected" or "ed_switch_button"
											end,
											onChanged = function(event)
												local flow = event.element.parent
												flow.button_take_from_inventory.style = "ed_switch_button_selected"
												flow.button_take_from_car.style       = "ed_switch_button"
												
												local player = _(flow.gui.player)
												player:changeSetting("takeFromInventory", true)
												player:changeSetting("takeFromCar", false)
											end,
										},
{
											type = "sprite-button",
											name = "button_take_from_car",
											tooltip = "Vehicle you are currently driving",
											sprite = "entity/car",
											style = {
												parent = "ed_switch_button",
												minimal_width  = 40,
												minimal_height = 40,
												left_margin    = -2,
												right_margin   = -2,
											},
											onCreated = function(self)
												local player = _(self.gui.player)
												self.style = player:setting("takeFromCar") and "ed_switch_button_selected" or "ed_switch_button"
											end,
											onChanged = function(event)
												local flow = event.element.parent
												flow.button_take_from_inventory.style = "ed_switch_button_selected"
												flow.button_take_from_car.style       = "ed_switch_button_selected"
												
												local player = _(flow.gui.player)
												player:changeSetting("takeFromInventory", true)
												player:changeSetting("takeFromCar", true)
											end,
										},
									}
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
									onCreated = function(self)
										local player = _(self.gui.player)
										self.state = player:setting("enableDragTake")
										self.parent.frame_caption.enabled = self.state
									end,
									onChanged = function(event)
										local self = event.element
										self.parent.parent.frame_content.visible = self.state
										self.parent.frame_caption.enabled = self.state

										local player = _(self.gui.player)
										player:changeSetting("enableDragTake", self.state)
									end,
								},
							}
						},
						{
							type = "flow",
							name = "frame_content",
							direction = "vertical",
							onCreated = function(self)
								self.visible = _(self.gui.player):setting("enableDragTake")
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
									caption = "Inventory Cleanup Hotkey",
								},
								{
									type = "empty-widget",
									style = "ed_stretch",
								},
								{
									type = "checkbox",
									name = "enable_inventory_cleanup_hotkey",
									caption = "Enable",
									state = true,
									onCreated = function(self)
										local player = _(self.gui.player)
										self.state = player:setting("enableInventoryCleanupHotkey")
										self.parent.frame_caption.enabled = self.state
									end,
									onChanged = function(event)
										local self = event.element
										self.parent.parent.frame_content.visible = self.state
										self.parent.frame_caption.enabled = self.state

										local player = _(self.gui.player)
										player:changeSetting("enableInventoryCleanupHotkey", self.state)
									end,
								},
							}
						},
						{
							type = "flow",
							name = "frame_content",
							direction = "vertical",
							onCreated = function(self)
								self.visible = _(self.gui.player):setting("enableInventoryCleanupHotkey")
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
			}
		},
	}
}

return {this, function(_controller) controller = _controller end}