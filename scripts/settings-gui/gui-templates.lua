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


local function updateLimiter(flow, profiles, action, newValue) -- switch to next type
	local player  = _(flow.gui.player)
	local value   = action == "value" and newValue or player:setting(profiles.valueSetting)
	local oldType = player:setting(profiles.typeSetting)
	local type    = action == "type" and profiles[oldType].next or oldType
	local profile = profiles[type]
	local name    = profiles.name
	local enabled = true

	if profiles.enableSetting then
		enabled = player:setting(profiles.enableSetting)
		if action == "enable" then enabled = flow[name.."_checkbox"].state end
	end

	-- clamp value to bounds
	local decimal = (profile.step < 1)
	if not decimal then value = math.floor(value) end
	-- if value > profile.max then value = profile.max end
	if value < profile.min then value = profile.min end
	
	-- update GUI
	flow[name.."_textfield"].allow_decimal = decimal
	flow[name.."_slider"].set_slider_minimum_maximum(profile.min, profile.max)
	flow[name.."_slider"].set_slider_value_step(profile.step)
	
	flow[name.."_slider"].slider_value = value
	flow[name.."_textfield"].text      = value
	flow[name.."_type"].caption        = {profiles.typeLocale.."."..type}
	
	if profiles.enableSetting then
		flow[name.."_checkbox"].state    = enabled
		flow[name.."_slider"].enabled    = enabled
		flow[name.."_textfield"].enabled = enabled
		flow[name.."_type"].enabled      = enabled
	end

	flow.tooltip    = {profiles.tooltipLocale.."."..(enabled and type or "disabled"), value, math.floor(value*100)}
	for _,child in pairs(flow.children) do
		child.tooltip = flow.tooltip
	end

	-- save settings
	if profiles.enableSetting then
		player:changeSetting(profiles.enableSetting, enabled)
	end
	player:changeSetting(profiles.typeSetting, type)
	player:changeSetting(profiles.valueSetting, value)
end

local function updateIgnoredEntities(self)
	local player = _(self.gui.player)
	self.clear()
		
	for name in pairs(player:setting("ignoredEntities")) do
		gui.create(player, this.templates.ignoredEntityChooser, { name = name }, self)
	end
	gui.create(player, this.templates.ignoredEntityChooser, {}, self)
end

this.templates.settingsWindow = {
	type = "frame",
	name = "ed_settings_window",
	direction = "vertical",
	--caption = "Even Distribution",
	root = function(player) return player.gui.screen end,
	onCreated = function(self)
		local player = _(self.gui.player)
		local resolution = player.display_resolution
		local scale = player.display_scale

		self.location = { 0, resolution.height / (4.85 * scale * scale)  }

		self.frame_header.drag_target = self
		self.frame_header.frame_caption.drag_target = self
		self.frame_header.filler.drag_target = self
	end,
	onClicked = function(event)
		local index  = event.player_index
		local player = _(event.element.gui.player)
		local cache  = _(global.cache[player.index])

		-- ...
		--dlog("clicked")
	end,
	children = {
		{
			type = "flow",
			name = "frame_header",
			direction = "horizontal",
			children = 
			{
				{
					type = "label",
					name = "frame_caption",
					style = "frame_title",
					caption = "Even Distribution",
				},
				{
					type = "empty-widget",
					name = "filler",
					style = {
						parent = "draggable_space_header",
						height = 24,
						natural_height = 24,
						right_margin = 8,
						horizontally_stretchable = true,
						vertically_stretchable = true,
					}
				},
				-- {
				-- 	type = "sprite-button",
				-- 	name = "save",
				-- 	visible = false,
				-- 	sprite = "utility/check_mark",
				-- 	style = {
				-- 		parent = "green_button",
				-- 		padding = 0,
				-- 		width = 24,
				-- 		height = 24,
				-- 	},
				-- 	onChanged = function(event)
				-- 		local player = _(event.element.gui.player)
				-- 		controller.destroyGUI(player)
				-- 	end,
				-- },
				{
					type = "sprite-button",
					name = "close",
					sprite = "utility/close_white",
					hovered_sprite = "utility/close_black",
					clicked_sprite = "utility/close_black",
					style = "frame_action_button",
					onChanged = function(event)
						local player = _(event.element.gui.player)
						controller.destroyGUI(player)
					end,
				},
			}
		},
		{
			type = "scroll-pane",
			vertical_scroll_policy = "auto-and-reserve-space",
			style = {
				parent = "control_settings_scroll_pane", --"scroll_pane_with_dark_background_under_subheader",
				minimal_width = 450, --530, -- 350,
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
									caption = {"settings-gui.drag-title"},
								},
								{
									type = "empty-widget",
									style = "ed_stretch",
								},
								{
									type = "checkbox",
									name = "enable_drag_distribute",
									caption = {"settings-gui.enable"},
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
									direction = "vertical",
									style = {
										horizontal_align = "center",
										top_margin = 16, --4,
										bottom_margin = 16, --4
									},
									children = 
									{
										{
											type = "switch",
											name = "mode_switch",
											left_label_caption  = {"", "[font=default-large-semibold]", {"settings-gui.drag-evenly-distribute"}, "[/font]"},
											right_label_caption = {"", "[font=default-large-semibold]", {"settings-gui.drag-balance-inventories"}, "[/font]"},
											style = {
												horizontally_stretchable = true,
											},
											onCreated = function(self)
												if _(self.gui.player):setting("dragMode") == "distribute" then
													self.switch_state = "left"
												else
													self.switch_state = "right"
												end
											end,
											onChanged = function(event)
												local self = event.element
												if self.switch_state == "left" then
													_(self.gui.player):changeSetting("dragMode", "distribute")
												else
													_(self.gui.player):changeSetting("dragMode", "balance")
												end
											end,
										},
									}
								},
								{
									type = "flow",
									direction = "horizontal",
									style = {
										vertical_align = "center",
										-- top_margin = 16, --4,
									},
									children = 
									{
										{
											type = "label",
											-- style = "heading_3_label_yellow",
											caption = {"settings-gui.distribute-from"},
										},
										{
											type = "empty-widget",
											style = "ed_stretch",
										},
										{
											type = "sprite-button",
											name = "button_take_from_hand",
											tooltip = {"settings-gui.hand-tooltip"},
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
											tooltip = {"settings-gui.inventory-tooltip"},
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
												local nowActive = event.element.style.name == "ed_switch_button"
												if flow.button_take_from_car.style.name == "ed_switch_button_selected" then nowActive = true end

												flow.button_take_from_inventory.style = nowActive and "ed_switch_button_selected" or "ed_switch_button"
												flow.button_take_from_car.style       = "ed_switch_button"
												
												local player = _(flow.gui.player)
												player:changeSetting("takeFromInventory", nowActive)
												player:changeSetting("takeFromCar", false)
											end,
										},
										{
											type = "sprite-button",
											name = "button_take_from_car",
											tooltip = {"settings-gui.car-tooltip"},
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
												local nowActive = event.element.style.name == "ed_switch_button"
												
												flow.button_take_from_inventory.style = "ed_switch_button_selected"
												flow.button_take_from_car.style       = nowActive and "ed_switch_button_selected" or "ed_switch_button"
												
												local player = _(flow.gui.player)
												player:changeSetting("takeFromInventory", true)
												player:changeSetting("takeFromCar", nowActive)
											end,
										},
									}
								},
								{
									type = "flow",
									direction = "horizontal",
									style = {
										vertical_align = "center",
									},
									onCreated = function(self)
										updateLimiter(self, config.fuelLimitProfiles)
									end,
									children = 
									{
										{
											type = "checkbox",
											name = "fuel_drag_limit_checkbox",
											caption = {"", {"settings-gui.fuel-limit"}, " [img=info]"},
											state = true,
											onChanged = function(event)
												updateLimiter(event.element.parent, config.fuelLimitProfiles, "enable")
											end,
										},
										{
											type = "empty-widget",
											style = "ed_stretch",
										},
										{
											type = "slider",
											name = "fuel_drag_limit_slider",
											--style = "red_slider",
											discrete_slider = false,
											discrete_values = true,
											onChanged = function(event)
												local value = event.element.slider_value
												if type(value) == "number" then
													updateLimiter(event.element.parent, config.fuelLimitProfiles, "value", value)
												end
											end,
										},
										{
											type = "textfield",
											name = "fuel_drag_limit_textfield",
											style = {
												parent = "slider_value_textfield",
												width = 60,
											},
											numeric = true,
											allow_negative = false,
											lose_focus_on_confirm = true,
											onChanged = function(event)
												local value = tonumber(event.element.text)
												if type(value) == "number" then
													updateLimiter(event.element.parent, config.fuelLimitProfiles, "value", value)
												end
											end,
										},
										{
											type = "button",
											name = "fuel_drag_limit_type",
											style = {
												padding = 0,
												width = 56, -- 38,
											},
											-- caption = "Stacks",
											onChanged = function(event)
												updateLimiter(event.element.parent, config.fuelLimitProfiles, "type")
											end,
										},
									}
								},
								{
									type = "flow",
									direction = "horizontal",
									style = {
										vertical_align = "center",
									},
									onCreated = function(self)
										updateLimiter(self, config.ammoLimitProfiles)
									end,
									children = 
									{
										{
											type = "checkbox",
											name = "ammo_drag_limit_checkbox",
											caption = {"", {"settings-gui.ammo-limit"}, " [img=info]"},
											state = true,
											onChanged = function(event)
												updateLimiter(event.element.parent, config.ammoLimitProfiles, "enable")
											end,
										},
										{
											type = "empty-widget",
											style = "ed_stretch",
										},
										{
											type = "slider",
											name = "ammo_drag_limit_slider",
											--style = "red_slider",
											discrete_slider = false,
											discrete_values = true,
											onChanged = function(event)
												local value = event.element.slider_value
												if type(value) == "number" then
													updateLimiter(event.element.parent, config.ammoLimitProfiles, "value", value)
												end
											end,
										},
										{
											type = "textfield",
											name = "ammo_drag_limit_textfield",
											style = {
												parent = "slider_value_textfield",
												width = 60,
											},
											numeric = true,
											allow_negative = false,
											lose_focus_on_confirm = true,
											onChanged = function(event)
												local value = tonumber(event.element.text)
												if type(value) == "number" then
													updateLimiter(event.element.parent, config.ammoLimitProfiles, "value", value)
												end
											end,
										},
										{
											type = "button",
											name = "ammo_drag_limit_type",
											style = {
												padding = 0,
												width = 56, -- 38,
											},
											onChanged = function(event)
												updateLimiter(event.element.parent, config.ammoLimitProfiles, "type")
											end,
										},
									}
								},
								{
									type = "checkbox",
									name = "replace_items",
									caption = {"settings-gui.replace-items"},
									style = {
										minimal_height = 28,
									},
									state = true,
									onCreated = function(self)
										local player = _(self.gui.player)
										self.state = player:setting("replaceItems")
									end,
									onChanged = function(event)
										local self = event.element
										local player = _(self.gui.player)
										player:changeSetting("replaceItems", self.state)
									end,
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
									caption = {"settings-gui.inventory-cleanup-title"},
								},
								{
									type = "empty-widget",
									style = "ed_stretch",
								},
								{
									type = "checkbox",
									name = "enable_inventory_cleanup_hotkey",
									caption = {"settings-gui.enable"},
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
									caption = {"", "[color=gray]", {"settings-gui.inventory-cleanup-description"}, "[/color]"},
								},
								{
									type = "label",
									caption = {"settings-gui.inventory-cleanup-list"},
								},
								{
									type = "flow",
									direction = "horizontal",
									style = {
										vertical_align = "center",
										top_margin = 8,
										bottom_margin = 8,
									},
									children = 
									{
										{
											type = "button",
											name = "button_defaults",
											tooltip = {"settings-gui.include-defaults-description"},
											style = {
												parent = "ed_switch_button_selected",
												minimal_width  = 40*2,
												minimal_height = 40*2+20,
												left_margin    = -2,
												right_margin   = -2,
												padding        = 2,
											},
											-- onChanged = function(event)
											-- 	local flow = event.element.parent
											-- 	flow.button_take_from_inventory.style = "ed_switch_button"
											-- 	flow.button_take_from_car.style       = "ed_switch_button"
												
											-- 	local player = _(flow.gui.player)
											-- 	player:changeSetting("takeFromInventory", false)
											-- 	player:changeSetting("takeFromCar", false)
											-- end,
											children = {
												{
													type = "flow",
													direction = "vertical",
													ignored_by_interaction = true,
													style = {
														horizontal_align = "center",
														vertical_spacing = 2,
													},
													children = {
														{
															type = "flow",
															direction = "horizontal",
															ignored_by_interaction = true,
															style = {
																horizontal_spacing = 2,
																top_margin = 2,
															},
															children = {
																{
																	type = "sprite",
																	sprite = "item/iron-ore",
																	ignored_by_interaction = true,
																},
																{
																	type = "sprite",
																	sprite = "item/copper-cable",
																	ignored_by_interaction = true,
																},
															}
														},
														{
															type = "flow",
															direction = "horizontal",
															ignored_by_interaction = true,
															style = {
																horizontal_spacing = 2,
																top_margin = 2,
															},
															children = {
																{
																	type = "sprite",
																	sprite = "item/iron-stick",
																	ignored_by_interaction = true,
																},
																{
																	type = "sprite",
																	sprite = "item/automation-science-pack",
																	ignored_by_interaction = true,
																},
															}
														},
														{
															type = "label",
															caption = "Defaults",
															ignored_by_interaction = true,
															style = {
																parent = "black_label",
																font = "default-bold",
															}
														},
													}
												},
												{
													type = "checkbox",
													ignored_by_interaction = true,
													state = true,
													enabled = false,
												},
											}
										},
										{
											type = "button",
											name = "button_trashslots",
											tooltip = {"settings-gui.include-trashslots-description"},
											style = {
												parent = "ed_switch_button_selected",
												minimal_width  = 40*2,
												minimal_height = 40*2+20,
												left_margin    = -2,
												right_margin   = -2,
												padding        = 2,
											},
											children = {
												{
													type = "checkbox",
													ignored_by_interaction = true,
													state = true,
													enabled = false,
												},
												{
													type = "flow",
													direction = "vertical",
													ignored_by_interaction = true,
													style = {
														horizontal_align = "center",
													},
													children = {
														{
															type = "sprite",
															sprite = "ed_trash",
															ignored_by_interaction = true,
															style = {
																top_margin = 18,
																bottom_margin = 18,
															}
														},
														{
															type = "label",
															caption = "Trash slots",
															ignored_by_interaction = true,
															style = {
																parent = "black_label",
																font = "default-bold"
															}
														},
													}
												},
											}
										},
										{
											type = "sprite-button",
											name = "button_autotrash",
											tooltip = {"settings-gui.include-autotrash-description"},
											style = {
												parent = "ed_switch_button_selected",
												minimal_width  = 40*2,
												minimal_height = 40*2+20,
												left_margin    = -2,
												right_margin   = -2,
												padding        = 2,
											},
											children = {
												{
													type = "checkbox",
													ignored_by_interaction = true,
													state = true,
													enabled = false,
												},
												{
													type = "flow",
													direction = "vertical",
													ignored_by_interaction = true,
													style = {
														horizontal_align = "center",
													},
													children = {
														{
															type = "sprite",
															sprite = "ed_autotrash",
															ignored_by_interaction = true,
															style = {
																top_margin = 10,
																bottom_margin = 10,
															}
														},
														{
															type = "label",
															caption = "Auto-trash",
															ignored_by_interaction = true,
															style = {
																parent = "black_label",
																font = "default-bold"
															}
														},
													}
												},
											}
										},
										{
											type = "sprite-button",
											name = "button_request_overflow",
											tooltip = {"settings-gui.cleanup-request-overflow-description"},
											style = {
												parent = "ed_switch_button_selected",
												minimal_width  = 40*2,
												minimal_height = 40*2+20,
												left_margin    = -2,
												right_margin   = -2,
												padding        = 2,
											},
											onCreated = function(self)
												local player = _(self.gui.player)
												self.style = player:setting("cleanupRequestOverflow") and "ed_switch_button_selected" or "ed_switch_button"
											end,
											onChanged = function(event)
												local self = event.element
												local player = _(self.gui.player)
												local nowActive = self.style.name == "ed_switch_button"

												player:changeSetting("cleanupRequestOverflow", nowActive)
												self.style = nowActive and "ed_switch_button_selected" or "ed_switch_button"
												self.checkbox_request_overflow.state = nowActive
											end,
											children = {
												{
													type = "checkbox",
													name = "checkbox_request_overflow",
													tooltip = {"settings-gui.cleanup-request-overflow-description"},
													state = true,
													onCreated = function(self)
														local player = _(self.gui.player)
														self.state = player:setting("cleanupRequestOverflow")
													end,
													onChanged = function(event)
														local self = event.element
														local player = _(self.gui.player)
														player:changeSetting("cleanupRequestOverflow", self.state)
														self.parent.style = self.state and "ed_switch_button_selected" or "ed_switch_button"
													end,
												},
												{
													type = "flow",
													direction = "vertical",
													ignored_by_interaction = true,
													style = {
														horizontal_align = "center",
														width = 65,
													},
													children = {
														{
															type = "sprite",
															sprite = "ed_overflow",
															ignored_by_interaction = true,
															style = {
																top_margin = 16,
																bottom_margin = 4,
															}
														},
														{
															type = "label",
															caption = "Request",
															ignored_by_interaction = true,
															style = {
																parent = "black_label",
																font = "default-bold",
																bottom_margin = -8,
															}
														},
														{
															type = "label",
															caption = "Overflow",
															ignored_by_interaction = true,
															style = {
																parent = "black_label",
																font = "default-bold",
															}
														},
													}
												},
											}
										},
									}
								},
								{
									type = "label",
									caption = {"settings-gui.inventory-cleanup-configure"},
								},
								{
									type = "label",
									caption = {"settings-gui.inventory-cleanup-ignore"},
									style = {
										top_margin = -6,
									}
								},
								{
									type = "label",
									caption = " ",
								},
								{
									type = "checkbox",
									name = "drop_trash_to_chests",
									caption = {"", {"settings-gui.drop-trash-to-chests"}, " [img=info]"},
									tooltip = {"settings-gui.drop-trash-to-chests-description"},
									state = true,
									onCreated = function(self)
										local player = _(self.gui.player)
										self.state = player:setting("dropTrashToChests")
									end,
									onChanged = function(event)
										local self = event.element
										local player = _(self.gui.player)
										player:changeSetting("dropTrashToChests", self.state)
									end,
								},
								{
									type = "checkbox",
									name = "item_limits",
									caption = {"settings-gui.item-limits"},
									state = true,
									onCreated = function(self)
										local player = _(self.gui.player)
										self.state = player:setting("cleanupUseLimits")
									end,
									onChanged = function(event)
										local self = event.element
										local player = _(self.gui.player)
										player:changeSetting("cleanupUseLimits", self.state)
									end,
								},
							}
						},
					}
				},
				-- {
				-- 	type = "frame",
				-- 	direction = "vertical",
				-- 	style = "ed_settings_inner_frame",
				-- 	children = 
				-- 	{
				-- 		{
				-- 			type = "flow",
				-- 			name = "frame_header",
				-- 			direction = "horizontal",
				-- 			children = 
				-- 			{
				-- 				{
				-- 					type = "label",
				-- 					name = "frame_caption",
				-- 					style = "heading_3_label_yellow",
				-- 					caption = "Inventory Fill hotkey",--{"", {"settings-gui.inventory-cleanup-title"}, " [img=info]"},
				-- 					-- tooltip = {"settings-gui.inventory-cleanup-description"},
				-- 				},
				-- 				{
				-- 					type = "empty-widget",
				-- 					style = "ed_stretch",
				-- 				},
				-- 				{
				-- 					type = "checkbox",
				-- 					name = "enable_inventory_fill_hotkey",
				-- 					caption = {"settings-gui.enable"},
				-- 					state = true,
				-- 					onCreated = function(self)
				-- 						local player = _(self.gui.player)
				-- 						self.state = player:setting("enableInventoryCleanupHotkey")
				-- 						self.parent.frame_caption.enabled = self.state
				-- 					end,
				-- 					onChanged = function(event)
				-- 						local self = event.element
				-- 						self.parent.parent.frame_content.visible = self.state
				-- 						self.parent.frame_caption.enabled = self.state

				-- 						local player = _(self.gui.player)
				-- 						player:changeSetting("enableInventoryCleanupHotkey", self.state)
				-- 					end,
				-- 				},
				-- 			}
				-- 		},
				-- 		{
				-- 			type = "flow",
				-- 			name = "frame_content",
				-- 			direction = "vertical",
				-- 			onCreated = function(self)
				-- 				self.visible = _(self.gui.player):setting("enableInventoryCleanupHotkey")
				-- 			end,
				-- 			children = 
				-- 			{
				-- 				{
				-- 					type = "label",
				-- 					caption = {"", "[color=gray]", {"settings-gui.inventory-cleanup-configure"}, "[/color]"},
				-- 				},
				-- 				{
				-- 					type = "checkbox",
				-- 					name = "include_defaults",
				-- 					caption = {"settings-gui.include-defaults"},
				-- 					state = true,
				-- 					enabled = false,
				-- 					onCreated = function(self)
				-- 						local player = _(self.gui.player)
				-- 						-- self.state = player:setting("enableDragDistribute")
				-- 					end,
				-- 					onChanged = function(event)
				-- 						local self = event.element
				-- 						local player = _(self.gui.player)
				-- 						-- player:changeSetting("enableDragDistribute", self.state)
				-- 					end,
				-- 				},
				-- 				{
				-- 					type = "checkbox",
				-- 					name = "include_trashslots",
				-- 					caption = {"settings-gui.include-trashslots"},
				-- 					state = true,
				-- 					enabled = false,
				-- 					onCreated = function(self)
				-- 						local player = _(self.gui.player)
				-- 						-- self.state = player:setting("enableDragDistribute")
				-- 					end,
				-- 					onChanged = function(event)
				-- 						local self = event.element
				-- 						local player = _(self.gui.player)
				-- 						-- player:changeSetting("enableDragDistribute", self.state)
				-- 					end,
				-- 				},
				-- 				{
				-- 					type = "checkbox",
				-- 					name = "include_autotrash",
				-- 					caption = {"", {"settings-gui.include-autotrash"}, " [img=info]"},
				-- 					tooltip = {"settings-gui.include-autotrash-description"},
				-- 					state = true,
				-- 					enabled = false,
				-- 					onCreated = function(self)
				-- 						local player = _(self.gui.player)
				-- 						-- self.state = player:setting("enableDragDistribute")
				-- 					end,
				-- 					onChanged = function(event)
				-- 						local self = event.element
				-- 						local player = _(self.gui.player)
				-- 						-- player:changeSetting("enableDragDistribute", self.state)
				-- 					end,
				-- 				},
				-- 				{
				-- 					type = "checkbox",
				-- 					name = "cleanup_request_overflow",
				-- 					caption = {"", {"settings-gui.cleanup-request-overflow"}, " [img=info]"},
				-- 					tooltip = {"settings-gui.cleanup-request-overflow-description"},
				-- 					state = true,
				-- 					onCreated = function(self)
				-- 						local player = _(self.gui.player)
				-- 						self.state = player:setting("cleanupRequestOverflow")
				-- 					end,
				-- 					onChanged = function(event)
				-- 						local self = event.element
				-- 						local player = _(self.gui.player)
				-- 						player:changeSetting("cleanupRequestOverflow", self.state)
				-- 					end,
				-- 				},
				-- 			}
				-- 		},
				-- 	}
				-- },
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
									caption = "Advanced",--{"", {"settings-gui.inventory-cleanup-title"}, " [img=info]"},
									-- tooltip = {"settings-gui.inventory-cleanup-description"},
								},
								{
									type = "empty-widget",
									style = "ed_stretch",
								},
								{
									type = "sprite-button",
									name = "expand_advanced",
									sprite = "utility/expand",
									hovered_sprite = "utility/expand_dark",
									clicked_sprite = "utility/expand_dark",
									style = "frame_action_button",
									onChanged = function(event)
										local self = event.element
										if self.sprite == "utility/expand" then
											self.parent.parent.frame_content.visible = true
											self.sprite = "utility/collapse"
											self.hovered_sprite = "utility/collapse_dark"
											self.clicked_sprite = "utility/collapse_dark"
										else
											self.parent.parent.frame_content.visible = false
											self.sprite = "utility/expand"
											self.hovered_sprite = "utility/expand_dark"
											self.clicked_sprite = "utility/expand_dark"
										end
									end,
								},
							}
						},
						{
							type = "flow",
							name = "frame_content",
							direction = "vertical",
							visible = false,
							-- onCreated = function(self)
							-- 	self.visible = _(self.gui.player):setting("enableInventoryCleanupHotkey")
							-- end,
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
											caption = {"", {"settings-gui.distribution-delay"}, " [img=info]"},
											tooltip = {"settings-gui.distribution-delay-description"},
										},
										{
											type = "empty-widget",
											style = "ed_stretch",
										},
										{
											type = "slider",
											name = "delay_slider",
											discrete_slider = false,
											discrete_values = true,
											minimum_value = 0,
											maximum_value = 5,
											value_step = 0.1,
											onCreated = function(self)
												local player = _(self.gui.player)
												self.slider_value = player:setting("distributionDelay")
											end,
											onChanged = function(event)
												local self = event.element
												local player = _(self.gui.player)
												local value = self.slider_value

												if type(value) == "number" then
													-- clamp value to bounds
													-- if value > 5 then value = 5 end
													if value < 0 then value = 0 end

													self.slider_value = value
													self.parent.delay_textfield.text = value

													player:changeSetting("distributionDelay", value)
												end
											end,
										},
										{
											type = "textfield",
											name = "delay_textfield",
											style = {
												parent = "slider_value_textfield",
												width = 60,
											},
											numeric = true,
											allow_decimal = true,
											allow_negative = false,
											lose_focus_on_confirm = true,
											onCreated = function(self)
												local player = _(self.gui.player)
												self.text = player:setting("distributionDelay")
											end,
											onChanged = function(event)
												local self = event.element
												local player = _(self.gui.player)
												local value = tonumber(self.text)

												if type(value) == "number" then
													-- clamp value to bounds
													-- if value > 5 then value = 5 end
													if value < 0 then value = 0 end

													self.text = value
													self.parent.delay_slider.slider_value = value

													player:changeSetting("distributionDelay", value)
												end
											end,
										},
										{
											type = "button",
											name = "delay_type",
											enabled = false,
											caption = "s",
											style = {
												padding = 0,
												width = 56, -- 38,
											},
										},
									},
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
											caption = {"", {"settings-gui.max-inventory-cleanup-drop-range"}, " [img=info]"},
											tooltip = {"settings-gui.max-inventory-cleanup-drop-range-description"},
										},
										{
											type = "empty-widget",
											style = "ed_stretch",
										},
										{
											type = "slider",
											name = "range_slider",
											discrete_slider = false,
											discrete_values = true,
											minimum_value = 0,
											maximum_value = 100,
											value_step = 1,
											onCreated = function(self)
												local player = _(self.gui.player)
												self.slider_value = player:setting("cleanupDropRange")
											end,
											onChanged = function(event)
												local self = event.element
												local player = _(self.gui.player)
												local value = self.slider_value
												
												if type(value) == "number" then
													-- clamp value to bounds
													value = math.floor(value)
													-- if value > 100 then value = 100 end
													if value < 0 then value = 0 end

													self.slider_value = value
													self.parent.range_textfield.text = value

													player:changeSetting("cleanupDropRange", value)
												end
											end,
										},
										{
											type = "textfield",
											name = "range_textfield",
											style = {
												parent = "slider_value_textfield",
												width = 60,
											},
											numeric = true,
											allow_decimal = false,
											allow_negative = false,
											lose_focus_on_confirm = true,
											onCreated = function(self)
												local player = _(self.gui.player)
												self.text = player:setting("cleanupDropRange")
											end,
											onChanged = function(event)
												local self = event.element
												local player = _(self.gui.player)
												local value = tonumber(self.text)
												
												if type(value) == "number" then
													-- clamp value to bounds
													value = math.floor(value)
													-- if value > 100 then value = 100 end
													if value < 0 then value = 0 end

													self.text = value
													self.parent.range_slider.slider_value = value

													player:changeSetting("cleanupDropRange", value)
												end
											end,
										},
										{
											type = "button",
											name = "range_type",
											enabled = false,
											caption = "tiles",
											style = {
												padding = 0,
												width = 56, -- 38,
											},
										},
									},
								},
								{
									type = "flow",
									direction = "horizontal",
									children = 
									{
										{
											type = "label",
											caption = {"settings-gui.ignored-entities"},
											style = {
												top_margin = 10,
											},
										},
										{
											type = "empty-widget",
											style = "ed_stretch",
										},
										{
											type = "table",
											column_count = 6,
											draw_vertical_lines = false,
											draw_horizontal_lines = false,
											draw_horizontal_line_after_headers = false,
											vertical_centering = false,
											onCreated = updateIgnoredEntities,
										},
									},
								},
							}
						},
					}
				},
			}
		},
	}
}

this.templates.ignoredEntityChooser = {
	type = "choose-elem-button",
	name = "ignored_entity_chooser",
	unique = false,
	elem_type = "entity",
	onCreated = function(self, data)
		self.elem_value = data.name
		self.elem_filters = {{ filter = "name", name = _(global.allowedEntities):keys():toPlain() }}
	end,
	onChanged = function(event)
		local parent = event.element.parent
		local player = _(parent.gui.player)
		local ignoredEntities = {}

		for __,child in pairs(parent.children) do
			local value = child.elem_value
			if value then ignoredEntities[value] = true end
		end

		player:changeSetting("ignoredEntities", ignoredEntities)
		updateIgnoredEntities(parent)
	end,
}

return {this, function(_controller) controller = _controller end}