local mod = get_mod("penances_improved")
local Blueprints = mod:io_dofile("penances_improved/scripts/mods/penances_improved/penances_improved_blueprints")

local ScriptCamera = require("scripts/foundation/utilities/script_camera")
local UIProfileSpawner = require("scripts/managers/ui/ui_profile_spawner")
local PenanceOverviewView = require("scripts/ui/views/penance_overview_view/penance_overview_view")
local PenanceOverviewViewDefinitions =
	require("scripts/ui/views/penance_overview_view/penance_overview_view_definitions")
local PenanceOverviewViewSettings = require("scripts/ui/views/penance_overview_view/penance_overview_view_settings")
local AchievementCategories = require("scripts/settings/achievements/achievement_categories")
local AchievementTypes = require("scripts/managers/achievements/achievement_types")
local AchievementUIHelper = require("scripts/managers/achievements/utility/achievement_ui_helper")
local InputUtils = require("scripts/managers/input/input_utils")
local ItemUtils = require("scripts/utilities/items")
local StatDefinitions = require("scripts/managers/stats/stat_definitions")
local ViewElementGrid = require("scripts/ui/view_elements/view_element_grid/view_element_grid")
local ViewElementInputLegend = require("scripts/ui/view_elements/view_element_input_legend/view_element_input_legend")
local ViewElementMenuPanel = require("scripts/ui/view_elements/view_element_menu_panel/view_element_menu_panel")
local TextUtilities = require("scripts/utilities/ui/text")
local UIFonts = require("scripts/managers/ui/ui_fonts")
local UIRenderer = require("scripts/managers/ui/ui_renderer")
local Breeds = require("scripts/settings/breed/breeds")
local ColorUtilities = require("scripts/utilities/ui/colors")
local CosmeticsInspectView = require("scripts/ui/views/cosmetics_inspect_view/cosmetics_inspect_view")
local UISettings = require("scripts/settings/ui/ui_settings")
local MasterItems = require("scripts/backend/master_items")
local UIWidget = require("scripts/managers/ui/ui_widget")
local ViewElementInventoryWeaponPreview =
	require("scripts/ui/view_elements/view_element_inventory_weapon_preview/view_element_inventory_weapon_preview")
local StoreItemDetailView = require("scripts/ui/views/store_item_detail_view/store_item_detail_view")
local StoreView = require("scripts/ui/views/store_view/store_view")
local BaseView = require("scripts/ui/views/base_view")

local cvi = get_mod("commodores_vestures_improved")

local ANIMATION_SLOTS_MAP = {
	slot_animation_emote_1 = true,
	slot_animation_emote_2 = true,
	slot_animation_emote_3 = true,
	slot_animation_emote_4 = true,
	slot_animation_emote_5 = true,
	slot_animation_end_of_round = true,
}

if not cvi then
	CosmeticsInspectView._spawn_profile = function(self, profile, initial_rotation, disable_rotation_input)
		if profile then
			if self._profile_spawner then
				self._profile_spawner:destroy()

				self._profile_spawner = nil
			end

			local world = self._world_spawner:world()
			local camera = self._world_spawner:camera()
			local unit_spawner = self._world_spawner:unit_spawner()

			self._profile_spawner = UIProfileSpawner:new("CosmeticsInspectView", world, camera, unit_spawner)

			if disable_rotation_input then
				self._profile_spawner:disable_rotation_input()
			end

			local camera_position = ScriptCamera.position(camera)
			local spawn_position = Unit.world_position(self._spawn_point_unit, 1)
			local spawn_rotation = Unit.world_rotation(self._spawn_point_unit, 1)

			if initial_rotation then
				local character_initial_rotation = Quaternion.axis_angle(Vector3(0, 0, 1), initial_rotation)

				spawn_rotation = Quaternion.multiply(character_initial_rotation, spawn_rotation)
			end

			camera_position.z = 0

			self._profile_spawner:spawn_profile(profile, spawn_position, spawn_rotation)

			self._spawned_profile = profile

			local selected_slot = self._selected_slot
			local selected_slot_name = selected_slot and selected_slot.name

			if selected_slot_name == "slot_companion_gear_full" then
				self._profile_spawner:toggle_character(false)
			elseif ANIMATION_SLOTS_MAP[selected_slot_name] then
				local companion_state_machine = self._context
				local item = self._preview_item
				local toggle_companion = item
					and item.companion_state_machine ~= nil
					and item.companion_state_machine ~= ""

				self._profile_spawner:toggle_companion(toggle_companion)
			else
				self._profile_spawner:toggle_companion(false)
			end
		end
	end
end

local weapon_preview_loaded = false
mod:hook_safe(CLASS.InventoryWeaponCosmeticsView, "cb_switch_tab", function(self, element)
	weapon_preview_loaded = true
end)

local InventoryWeaponCosmeticsView =
	require("scripts/ui/views/inventory_weapon_cosmetics_view/inventory_weapon_cosmetics_view")
local Definitions =
	require("scripts/ui/views/inventory_weapon_cosmetics_view/inventory_weapon_cosmetics_view_definitions")

InventoryWeaponCosmeticsView.on_enter = function (self)
	InventoryWeaponCosmeticsView.super.on_enter(self)

	self._render_settings.alpha_multiplier = 0
	self._inventory_items = {}

	self:_setup_forward_gui()

	self._background_widget = self:_create_widget("background", Definitions.background_widget)

	if not self._selected_item then
		return
	end

	local grid_size = Definitions.grid_settings.grid_size

	self._content_blueprints = require("scripts/ui/view_content_blueprints/item_blueprints")(grid_size)

	self:_setup_input_legend()

	if not self._on_enter_anim_id then
		self._on_enter_anim_id = self:_start_animation("on_enter", self._widgets_by_name, self)
	end

	if self._parent then
		self._world_spawner = self._parent:world_spawner()
	end

	if self._presentation_item then
		self:_setup_weapon_preview()
		self:_preview_item(self._presentation_item)
	end

	self:present_grid_layout({})
	self:_register_button_callbacks()
	self:_setup_menu_tabs()
	self:_load_layout()
	self:_register_event("event_force_refresh_inventory", "event_force_refresh_inventory")
end

CosmeticsInspectView._handle_back_pressed = function(self)
	if Managers.ui:view_active("inventory_weapon_cosmetics_view") and weapon_preview_loaded then
		Managers.ui:close_view("inventory_weapon_cosmetics_view")
	end

	local view_name = "cosmetics_inspect_view"
	Managers.ui:close_view(view_name)
end

mod:hook_require("scripts/ui/views/cosmetics_inspect_view/cosmetics_inspect_view_definitions", function(instance)
	local portrait_preview_panel_size = {
		400,
		400,
	}

	local insignia_preview_panel_size = {
		160,
		400,
	}

	instance.scenegraph_definition.weapon_viewport = {
		horizontal_alignment = "center",
		parent = "screen",
		vertical_alignment = "center",
		size = {
			1920,
			1080,
		},
		position = {
			0,
			0,
			3,
		},
	}
	instance.scenegraph_definition.weapon_pivot = {
		horizontal_alignment = "center",
		parent = "weapon_viewport",
		vertical_alignment = "center",
		size = {
			0,
			0,
		},
		position = {
			300,
			0,
			1,
		},
	}

	instance.scenegraph_definition.portrait_preview_panel = {
		horizontal_alignment = "center",
		parent = "canvas",
		vertical_alignment = "center",
		size = portrait_preview_panel_size,
		position = {
			150,
			0,
			0,
		},
	}

	instance.scenegraph_definition.character_insignia = {
		horizontal_alignment = "center",
		parent = "canvas",
		vertical_alignment = "center",
		size = insignia_preview_panel_size,
		position = {
			50,
			0,
			0,
		},
	}

	instance.widget_definitions.portrait_preview_panel = UIWidget.create_definition({
		{
			pass_type = "texture",
			style_id = "portrait_frame",
			value = "content/ui/materials/base/ui_portrait_frame_base",
			value_id = "texture",
			visible = false,
			style = {
				material_values = {
					columns = 1,
					grid_index = 1,
					rows = 1,
					use_placeholder_texture = 1,
				},
				color = {
					255,
					255,
					255,
					255,
				},
			},
		},
	}, "portrait_preview_panel")

	instance.widget_definitions.character_insignia = UIWidget.create_definition({
		{
			pass_type = "texture",
			style_id = "character_insignia",
			value = "content/ui/materials/base/ui_default_base",
			value_id = "character_insignia",
			visible = false,
			style = {
				horizontal_alignment = "center",
				vertical_alignment = "center",
				size = insignia_preview_panel_size,
				offset = {
					0,
					0,
					1,
				},
				material_values = {},
				color = {
					255,
					255,
					255,
					255,
				},
			},
		},
	}, "character_insignia")
end)

CosmeticsInspectView._cb_set_player_insignia = function(self, widget, item)
	local icon_style = widget.style.character_insignia
	local material_values = icon_style.material_values

	if item.icon_material and item.icon_material ~= "" then
		if material_values.texture_map then
			material_values.texture_map = nil
		end

		widget.content.character_insignia = item.icon_material
	else
		material_values.texture_map = item.icon
	end

	icon_style.color[1] = 255
end

local CosmeticsInspectViewSettings = require("scripts/ui/views/cosmetics_inspect_view/cosmetics_inspect_view_settings")
local ItemSlotSettings = require("scripts/settings/item/item_slot_settings")
local UIWorldSpawner = require("scripts/managers/ui/ui_world_spawner")
local WorldRenderUtils = require("scripts/utilities/world_render")

CosmeticsInspectView._setup_background_world = function(self)
	local profile = self._preview_profile or self._mannequin_profile
	local archetype = profile and profile.archetype
	local breed_name = profile and archetype.breed or "human"
	local default_camera_event_id = "event_register_cosmetics_preview_default_camera_" .. breed_name

	self[default_camera_event_id] = function(instance, camera_unit)
		if instance._context then
			instance._context.camera_unit = camera_unit
		end

		instance._default_camera_unit = camera_unit

		local viewport_name = CosmeticsInspectViewSettings.viewport_name
		local viewport_type = CosmeticsInspectViewSettings.viewport_type
		local viewport_layer = CosmeticsInspectViewSettings.viewport_layer
		local shading_environment = CosmeticsInspectViewSettings.shading_environment

		instance._world_spawner:create_viewport(
			camera_unit,
			viewport_name,
			viewport_type,
			viewport_layer,
			shading_environment
		)
		instance:_unregister_event(default_camera_event_id)
	end

	self:_register_event(default_camera_event_id)

	self._item_camera_by_slot_id = {}

	for slot_name, slot in pairs(ItemSlotSettings) do
		if slot.slot_type == "gear" then
			local item_camera_event_id = "event_register_cosmetics_preview_item_camera_"
				.. breed_name
				.. "_"
				.. slot_name

			self[item_camera_event_id] = function(instance, camera_unit)
				instance._item_camera_by_slot_id[slot_name] = camera_unit

				instance:_unregister_event(item_camera_event_id)
			end

			self:_register_event(item_camera_event_id)
		end
	end

	self:_register_event("event_register_cosmetics_preview_character_spawn_point")

	local world_name = CosmeticsInspectViewSettings.world_name
	local world_layer = CosmeticsInspectViewSettings.world_layer
	local world_timer_name = CosmeticsInspectViewSettings.timer_name

	self._world_spawner = UIWorldSpawner:new(world_name, world_layer, world_timer_name, self.view_name)

	local level_name = CosmeticsInspectViewSettings.level_name

	self._world_spawner:spawn_level(level_name)
end

CosmeticsInspectView._setup_weapon_preview = function(self)
	if not self._weapon_preview then
		local reference_name = "weapon_preview"
		local layer = 10
		local context = {
			draw_background = false,
			ignore_blur = false,
		}
		self._weapon_preview = self:_add_element(ViewElementInventoryWeaponPreview, reference_name, layer, context)

		local allow_rotation = true

		self._weapon_preview:set_force_allow_rotation(allow_rotation)
		self:_set_weapon_zoom(self._weapon_zoom_fraction)
	end
end

CosmeticsInspectView._set_weapon_zoom = function(self, fraction)
	self._weapon_zoom_fraction = fraction

	self:_update_weapon_preview_viewport()
end

CosmeticsInspectView._update_weapon_preview_viewport = function(self)
	local weapon_preview = self._weapon_preview

	if weapon_preview then
		local weapon_zoom_fraction = self._weapon_zoom_fraction or 1
		local use_custom_zoom = true
		local optional_node_name = "p_zoom"
		local optional_pos
		local min_zoom = self._min_zoom
		local max_zoom = self._max_zoom

		weapon_preview:set_weapon_zoom(
			weapon_zoom_fraction,
			use_custom_zoom,
			optional_node_name,
			optional_pos,
			min_zoom,
			max_zoom
		)
	end
end

CosmeticsInspectView._preview_item_func = function(self, item)
	if item then
		local item_display_name = item.display_name
		local slots = item.slots or {}
		local item_name = item.name
		local gear_id = item.gear_id or item_name

		if self._weapon_preview then
			local disable_auto_spin = false

			self._weapon_preview:present_item(item, disable_auto_spin)
		end

		local visible = true

		self:_set_preview_widgets_visibility(visible)
	end
end

CosmeticsInspectView._start_preview_item = function(self)
	local item = self._preview_item
	self._previewed_item = item
	self._spawn_player = true
	self:_stop_previewing()

	if self._widgets_by_name.portrait_preview_panel then
		self._widgets_by_name.portrait_preview_panel.visible = false
	end
	if self._widgets_by_name.character_insignia then
		self._widgets_by_name.character_insignia.visible = false
	end

	if item then
		local item_display_name = item.display_name

		if string.match(item_display_name, "unarmed") then
			return
		end

		local item_name = item.name
		local selected_slot = self._selected_slot
		local selected_slot_name = selected_slot and selected_slot.name
		local presentation_profile = self._presentation_profile
		local presentation_loadout = presentation_profile.loadout

		if selected_slot_name then
			presentation_loadout[selected_slot_name] = item
		end

		local animation_slot = ANIMATION_SLOTS_MAP[selected_slot_name]

		if animation_slot then
			local context = self._context
			local state_machine = item.state_machine
			local item_animation_event = item.animation_event
			local item_face_animation_event = item.face_animation_event
			local animation_event_name_suffix = self._animation_event_name_suffix

			self._disable_zoom = context.disable_zoom or true
			context.state_machine = context.state_machine or item.state_machine
			context.animation_event = context.animation_event or item_animation_event
			context.face_animation_event = self._previewed_with_gear
					and (context.face_animation_event or item_face_animation_event)
				or nil

			local animation_event = item_animation_event

			if animation_event_name_suffix then
				animation_event = animation_event .. animation_event_name_suffix
			end

			if self._profile_spawner then
				self._profile_spawner:assign_state_machine(
					context.state_machine,
					context.item_animation_event,
					context.item_face_animation_event
				)
			end

			local animation_event_variable_data = self._animation_event_variable_data

			if animation_event_variable_data and self._profile_spawner then
				local index = animation_event_variable_data.index
				local value = animation_event_variable_data.value

				if self._profile_spawner then
					self._profile_spawner:assign_animation_variable(index, value)
				end
			end

			local prop_item_key = item.prop_item
			local prop_item = prop_item_key and prop_item_key ~= "" and MasterItems.get_item(prop_item_key)

			context.prop_item = context.prop_item or prop_item

			if context.prop_item then
				local prop_item_slot = context.prop_item.slots[1]

				presentation_loadout[prop_item_slot] = context.prop_item

				if self._profile_spawner then
					self._profile_spawner:wield_slot(prop_item_slot)
				end
			end
		end

		self:_set_preview_widgets_visibility(true)

		local property_text = ItemUtils.item_property_text(item, true)
		local restriction_text, present_restriction_text = ItemUtils.restriction_text(item)

		if not present_restriction_text then
			restriction_text = nil
		end

		self.hide_character = false
		if Managers.ui:view_active("penance_overview_view") and weapon_preview_loaded then
			if item.item_type == "PORTRAIT_FRAME" then
				if self._widgets_by_name.portrait_preview_panel then
					self._preview_player = false
					self._spawn_player = false
					self._can_preview_with_gear = false
					self.hide_character = true
					self._on_enter_animation_triggered = false
					self._previewed_with_gear = false

					self:_setup_weapon_preview()

					self._widgets_by_name.portrait_preview_panel.visible = true
					local icon
					if item.texture_resource then
						icon = item.texture_resource
					else
						icon = "content/ui/textures/nameplates/portrait_frames/default"
					end

					local widget = self._widgets_by_name.portrait_preview_panel
					local material_values = widget.style.portrait_frame.material_values

					material_values.portrait_frame_texture = icon
				end
			elseif item.item_type == "CHARACTER_INSIGNIA" then
				if self._widgets_by_name.character_insignia then
					self._preview_player = false
					self._spawn_player = false
					self._can_preview_with_gear = false
					self.hide_character = true
					self._on_enter_animation_triggered = false
					self._previewed_with_gear = false

					self:_setup_weapon_preview()

					local widget = self._widgets_by_name.character_insignia
					widget.visible = true
					local cb = callback(self, "_cb_set_player_insignia", widget)

					widget.content.insignia_load_id = Managers.ui:load_item_icon(item, cb)
				end
			elseif item.item_type == "WEAPON_TRINKET" then
				self._preview_player = false
				self._spawn_player = false
				self._can_preview_with_gear = false
				self.hide_character = true
				self._on_enter_animation_triggered = false
				self._previewed_with_gear = false

				self._weapon_zoom_fraction = -0.45
				self._weapon_zoom_target = -0.45
				self._min_zoom = -0.45
				self._max_zoom = 4
				self:_setup_weapon_preview()
				local visual_item = ItemUtils.weapon_trinket_preview_item(item)
				CosmeticsInspectView._preview_item_func(self, visual_item)

				if cvi then
					self._weapon_preview:center_align(0, {
						-0.0,
						-0.0,
						-0.1,
					})
				else
					self._weapon_preview:center_align(0, {
						-0.4,
						-0.0,
						-0.1,
					})
				end
			elseif item.item_type == "CHARACTER_TITLE" then
				self._preview_player = false
				self._spawn_player = false
				self._can_preview_with_gear = false
				self._on_enter_animation_triggered = false
				self._previewed_with_gear = false
				self.hide_character = true

				self:_setup_weapon_preview()
			elseif item.item_type == "WEAPON_SKIN" then
				self._preview_player = false
				self._spawn_player = false
				self._can_preview_with_gear = false
				self.hide_character = true
				self._on_enter_animation_triggered = false
				self._previewed_with_gear = false

				self._weapon_zoom_fraction = -0.45
				self._weapon_zoom_target = -0.45
				self._min_zoom = -0.45
				self._max_zoom = 4
				self:_setup_weapon_preview()
				local visual_item = ItemUtils.weapon_skin_preview_item(item)
				CosmeticsInspectView._preview_item_func(self, visual_item)

				if cvi then
					self._weapon_preview:center_align(0, {
						-0.0,
						-2.0,
						-0.2,
					})
				else
					self._weapon_preview:center_align(0, {
						-0.4,
						-2.0,
						-0.2,
					})
				end
			end
		end

		local description = item.description and Localize(item.description)

		self:_setup_item_description(description, restriction_text, property_text)
		self:_setup_title(item)
	elseif self._bundle_data then
		local description = self._bundle_data.description or ""

		self:_setup_item_description(description)

		local texture_data = self._bundle_data.image

		if texture_data then
			local url = texture_data.url

			self._image_url = url

			Managers.url_loader:load_texture(url)

			self._widgets_by_name.bundle_background.style.bundle.material_values.texture_map = texture_data.texture
		end

		local title_item_data = {
			item_type = Localize(UISettings.item_type_localization_lookup[Utf8.upper(self._bundle_data.type)]),
			display_name = self._bundle_data.title,
		}

		self:_setup_title(title_item_data, true)
		self:_set_preview_widgets_visibility(true)
	end
end

local function _stats_sort_iterator(stats, stats_sorting)
	local sort_table = stats_sorting or table.keys(stats)
	local ii = 0

	return function()
		ii = ii + 1

		return sort_table[ii], stats[sort_table[ii]]
	end
end

-- Override default card layout
PenanceOverviewView._get_achievement_card_layout = function(self, achievement_id, is_tooltip)
	local player = self:_player()
	local achievement = AchievementUIHelper.achievement_definition_by_id(achievement_id)
	local achievement_definition = Managers.achievements:achievement_definition(achievement_id)
	local can_claim = not is_tooltip and self:_can_claim_achievement_by_id(achievement_id)
	local is_complete = not can_claim and Managers.achievements:achievement_completed(player, achievement_id)
	local is_favorite = AchievementUIHelper.is_favorite_achievement(achievement_id)
	local achievement_score = achievement.score or 0
	local achievement_family_order = AchievementUIHelper.get_achievement_family_order(achievement)
	local draw_progress_bar = self:_achievement_should_display_progress_bar(achievement_definition, is_complete)
	local use_spacing = true
	local blueprint = PenanceOverviewViewDefinitions.grid_blueprints
	local layout = {}
	local layout_blueprint_names_by_grid = PenanceOverviewViewSettings.blueprints_by_page
	local layout_blueprint_names = is_tooltip and layout_blueprint_names_by_grid.tooltip
		or layout_blueprint_names_by_grid.carousel
	local scenegraph_id = is_tooltip and "tooltip_grid" or "carousel_card"
	local grid_size = self:_get_scenegraph_size(scenegraph_id)
	local height_used = 0

	if can_claim then
		layout[#layout + 1] = {
			widget_type = "claim_overlay",
			size = {
				grid_size[1],
				grid_size[2],
			},
		}
	end

	if not is_tooltip then
		layout[#layout + 1] = {
			widget_type = layout_blueprint_names.tracked,
			achievement_id = achievement_id,
			tracked = is_favorite,
		}
		layout[#layout + 1] = {
			widget_type = layout_blueprint_names.completed,
			achievement_id = achievement_id,
			completed = is_complete,
		}
		layout[#layout + 1] = {
			widget_type = layout_blueprint_names.category,
			achievement = achievement,
		}
	else
		layout[#layout + 1] = {
			widget_type = layout_blueprint_names.dynamic_spacing,
			size = {
				grid_size[1],
				20,
			},
		}
	end

	height_used = height_used + blueprint[layout_blueprint_names.tracked].size[2]

	if use_spacing then
		layout[#layout + 1] = {
			widget_type = layout_blueprint_names.dynamic_spacing,
			size = {
				grid_size[1],
				10,
			},
		}
		height_used = height_used + 10
	end

	layout[#layout + 1] = {
		widget_type = layout_blueprint_names.penance_icon,
		texture = achievement.icon,
		completed = is_complete,
		can_claim = can_claim,
		family_index = achievement_family_order,
	}
	height_used = height_used + blueprint[layout_blueprint_names.penance_icon].size[2]

	if use_spacing then
		layout[#layout + 1] = {
			widget_type = layout_blueprint_names.dynamic_spacing,
			size = {
				grid_size[1],
				5,
			},
		}
		height_used = height_used + 5
	end

	local title = AchievementUIHelper.localized_title(achievement_definition)

	if title then
		layout[#layout + 1] = {
			widget_type = layout_blueprint_names.header,
			text = title,
		}
		height_used = height_used + blueprint[layout_blueprint_names.header].size[2]
	end

	if draw_progress_bar and not can_claim then
		if use_spacing then
			layout[#layout + 1] = {
				widget_type = layout_blueprint_names.dynamic_spacing,
				size = {
					grid_size[1],
					10,
				},
			}
			height_used = height_used + 10
		end

		local bar_progress, progress, goal = self:_get_achievement_bar_progress(achievement_definition)
		local progress_text = progress > 0
				and TextUtilities.apply_color_to_text(
					tostring(progress),
					Color.ui_achievement_icon_completed(255, true)
				)
			or tostring(progress)

		layout[#layout + 1] = {
			widget_type = layout_blueprint_names.progress_bar,
			text = progress_text .. "/" .. tostring(goal),
			progress = bar_progress,
		}
		height_used = height_used + blueprint[layout_blueprint_names.progress_bar].size[2]

		if use_spacing then
			layout[#layout + 1] = {
				widget_type = layout_blueprint_names.dynamic_spacing,
				size = {
					grid_size[1],
					10,
				},
			}
			height_used = height_used + 10
		end
	end

	local min_description_height = 10
	local description = AchievementUIHelper.localized_description(achievement_definition)
	local description_layout_entry

	if description and not can_claim then
		description_layout_entry = {
			widget_type = layout_blueprint_names.body,
			text = description,
			size = {},
		}
		layout[#layout + 1] = description_layout_entry
	end

	local reward_item, item_group = AchievementUIHelper.get_reward_item(achievement_definition)
	local reward_layouts = {}
	local reward_layouts_height = 0

	if reward_item then
		reward_layouts[#reward_layouts + 1] = {
			widget_type = layout_blueprint_names.score_and_reward,
			item = reward_item,
			item_group = item_group,
			score = achievement_score,
		}
		reward_layouts_height = reward_layouts_height + blueprint[layout_blueprint_names.score_and_reward].size[2]
	else
		reward_layouts[#reward_layouts + 1] = {
			widget_type = layout_blueprint_names.score,
			score = achievement_score,
		}
		reward_layouts_height = reward_layouts_height + blueprint[layout_blueprint_names.score].size[2]
	end

	local space_left = grid_size[2] - (height_used + reward_layouts_height)
	local stats = achievement_definition.stats
	local stats_sorting = achievement_definition.stats_sorting

	if stats and not can_claim then
		local stats_layouts = {}
		local allowed_stats_height = is_tooltip and math.huge or space_left - min_description_height
		local top_spacing = 10
		local bottom_spacing = 10

		if use_spacing then
			allowed_stats_height = allowed_stats_height - (top_spacing + bottom_spacing)
		end

		local stat_size = {
			blueprint[layout_blueprint_names.stat].size[1],
			blueprint[layout_blueprint_names.stat].size[2],
		}
		local max_amount_on_per_column = math.floor(allowed_stats_height / stat_size[2])

		if not is_tooltip then
			max_amount_on_per_column = math.min(max_amount_on_per_column, 4)
		end

		local player_id = player.remote and player.stat_id or player:local_player_id()

		for stat_name, stat_settings in _stats_sort_iterator(stats, stats_sorting) do
			local target = stat_settings.target
			local value = math.min(Managers.stats:read_user_stat(player_id, stat_name), target)
			local value_text = value > 0
					and TextUtilities.apply_color_to_text(
						tostring(value),
						Color.ui_achievement_icon_completed(255, true)
					)
				or tostring(value)
			local target_text = value == target
					and TextUtilities.apply_color_to_text(
						tostring(target),
						Color.ui_achievement_icon_completed(255, true)
					)
				or tostring(target)
			local progress_text = value_text .. "/" .. target_text
			local loc_stat_name = string.format("• %s", Localize(StatDefinitions[stat_name].stat_name or "unknown"))

			stats_layouts[#stats_layouts + 1] = {
				widget_type = layout_blueprint_names.stat,
				text = loc_stat_name,
				value = progress_text,
				size = {
					stat_size[1],
					stat_size[2],
				},
			}
		end

		local max_stat_amount

		if max_amount_on_per_column < #stats_layouts then
			local num_columns = 2

			stat_size[1] = stat_size[1] / num_columns
			max_stat_amount = math.min(max_amount_on_per_column * num_columns, #stats_layouts)

			local biggest_column_amount = math.ceil(max_stat_amount / num_columns)

			height_used = height_used + stat_size[2] * biggest_column_amount
		else
			max_stat_amount = math.min(#stats_layouts, max_amount_on_per_column)
			height_used = height_used + stat_size[2] * max_stat_amount
		end

		if use_spacing and #stats_layouts > 0 then
			layout[#layout + 1] = {
				widget_type = layout_blueprint_names.dynamic_spacing,
				size = {
					grid_size[1],
					top_spacing,
				},
			}
			height_used = height_used + top_spacing
		end

		for i = 1, max_stat_amount do
			local stat_layout = stats_layouts[i]

			if stat_layout then
				stat_layout.size = stat_size
				layout[#layout + 1] = stat_layout
			end
		end

		if max_stat_amount < #stats_layouts then
			layout[#layout + 1] = {
				strict_size = true,
				widget_type = layout_blueprint_names.body,
				text_color = Color.terminal_text_body_sub_header(255, true),
				text = Localize("loc_penance_menu_additional_objectives_info", true, {
					num_extra_objectives = tostring(#stats_layouts - max_stat_amount),
				}),
				size = {
					nil,
					20,
				},
			}
			height_used = height_used + 20
		end

		if use_spacing and #stats_layouts > 0 then
			layout[#layout + 1] = {
				widget_type = layout_blueprint_names.dynamic_spacing,
				size = {
					grid_size[1],
					bottom_spacing,
				},
			}
			height_used = height_used + bottom_spacing
		end

		space_left = grid_size[2] - (height_used + reward_layouts_height)
	end

	local achievement_type_name = achievement_definition.type

	if achievement_type_name == "meta" and not can_claim then
		local sub_achievements = achievement_definition.achievements
		local num_sub_achievements = table.size(sub_achievements)
		local num_entries = 0
		local max_entries = is_tooltip and 999 or 5
		local sub_achievement_entries = {}
		local blueprint_name = is_tooltip and "penance_icon_and_name" or "penance_icon_small"

		for sub_achievement_id, _ in pairs(sub_achievements) do
			if num_entries < max_entries then
				num_entries = num_entries + 1

				local sub_achievement = AchievementUIHelper.achievement_definition_by_id(sub_achievement_id)
				local sub_achievement_is_complete =
					Managers.achievements:achievement_completed(player, sub_achievement_id)
				local sub_achievement_title = AchievementUIHelper.localized_title(sub_achievement)
				local sub_achievement_family_order = AchievementUIHelper.get_achievement_family_order(sub_achievement)
				local sub_achievement_description = AchievementUIHelper.localized_description(sub_achievement)

				local sub_achievement_definition = Managers.achievements:achievement_definition(sub_achievement_id)

				local value = "n/a"

				local progress = 0
				local goal = 1
				local type = AchievementTypes[sub_achievement_definition.type]
				if type and type.get_progress ~= nil then
					progress, goal = type.get_progress(sub_achievement_definition, player)
					if sub_achievement_is_complete then
						value = goal .. "/" .. goal
					else
						value = progress .. "/" .. goal
					end
				end

				sub_achievement_entries[#sub_achievement_entries + 1] = {
					widget_type = layout_blueprint_names[blueprint_name],
					texture = sub_achievement.icon,
					completed = sub_achievement_is_complete,
					text = sub_achievement_title,
					family_index = sub_achievement_family_order,
					value = value,
					description = sub_achievement_description,
				}

				-- ADD SUB SUB ACHIEVEMENTS
				local sub_sub_achievements = sub_achievement.achievements
				local sub_blueprint_name = is_tooltip and "sub_penance_icon_and_name" or "penance_icon_small"
				if sub_sub_achievements then
					for sub_sub_achievement_id, _ in pairs(sub_sub_achievements) do
						if num_entries < max_entries then
							num_entries = num_entries + 1

							local sub_sub_achievement =
								AchievementUIHelper.achievement_definition_by_id(sub_sub_achievement_id)
							local sub_sub_achievement_is_complete =
								Managers.achievements:achievement_completed(player, sub_sub_achievement_id)
							local sub_sub_achievement_title = AchievementUIHelper.localized_title(sub_sub_achievement)
							local sub_sub_achievement_family_order =
								AchievementUIHelper.get_achievement_family_order(sub_sub_achievement)
							local sub_sub_achievement_description =
								AchievementUIHelper.localized_description(sub_sub_achievement)
							local sub_sub_achievement_definition =
								Managers.achievements:achievement_definition(sub_sub_achievement_id)

							local value = "n/a"

							local progress = 0
							local goal = 1
							local type = AchievementTypes[sub_sub_achievement_definition.type]
							if type and type.get_progress ~= nil then
								progress, goal = type.get_progress(sub_sub_achievement_definition, player)
								if sub_sub_achievement_is_complete then
									value = goal .. "/" .. goal
								else
									value = progress .. "/" .. goal
								end
							end

							sub_achievement_entries[#sub_achievement_entries + 1] = {
								widget_type = layout_blueprint_names[sub_blueprint_name],
								texture = sub_sub_achievement.icon,
								completed = sub_sub_achievement_is_complete,
								value = value,
								text = sub_sub_achievement_title,
								description = sub_sub_achievement_description,
								family_index = sub_sub_achievement_family_order,
							}
						end
					end
				end
			else
				break
			end
		end

		local num_rows

		if blueprint_name == "penance_icon_small" then
			local entry_width = blueprint[layout_blueprint_names[blueprint_name]].size[1]
			local total_entries_width = entry_width * num_entries
			local width_left = grid_size[1] - total_entries_width
			local mid_spacing = math.min(num_entries > 0 and width_left / (num_entries - 1) or 0, 10)
			local total_mid_spacing = mid_spacing * (num_entries - 1)
			local side_spacing = (grid_size[1] - (total_entries_width + total_mid_spacing)) * 0.5

			layout[#layout + 1] = {
				widget_type = layout_blueprint_names.dynamic_spacing,
				size = {
					side_spacing,
					0,
				},
			}

			for i = 1, #sub_achievement_entries do
				layout[#layout + 1] = sub_achievement_entries[i]

				if i < #sub_achievement_entries then
					layout[#layout + 1] = {
						widget_type = layout_blueprint_names.dynamic_spacing,
						size = {
							mid_spacing,
							0,
						},
					}
				end
			end

			layout[#layout + 1] = {
				widget_type = layout_blueprint_names.dynamic_spacing,
				size = {
					side_spacing,
					0,
				},
			}

			local total_width = entry_width * num_entries

			num_rows = math.ceil(total_width / grid_size[1])
		else
			if use_spacing then
				layout[#layout + 1] = {
					widget_type = layout_blueprint_names.dynamic_spacing,
					size = {
						grid_size[1],
						20,
					},
				}
				height_used = height_used + 20
			end

			for i = 1, #sub_achievement_entries do
				layout[#layout + 1] = sub_achievement_entries[i]

				if i < #sub_achievement_entries then
					layout[#layout + 1] = {
						widget_type = layout_blueprint_names.dynamic_spacing,
						size = {
							grid_size[1],
							10,
						},
					}
					height_used = height_used + 10
				end
			end

			num_rows = num_entries
		end

		local height_added = blueprint[layout_blueprint_names.penance_icon_small].size[2] * num_rows

		if max_entries < num_sub_achievements then
			if use_spacing then
				layout[#layout + 1] = {
					widget_type = layout_blueprint_names.dynamic_spacing,
					size = {
						grid_size[1],
						10,
					},
				}
				height_added = height_added + 10
			end

			layout[#layout + 1] = {
				strict_size = true,
				widget_type = layout_blueprint_names.body,
				text_color = Color.terminal_text_body_sub_header(255, true),
				text = Localize("loc_penance_menu_additional_objectives_info", true, {
					num_extra_objectives = tostring(num_sub_achievements - max_entries),
				}),
				size = {
					nil,
					20,
				},
			}
			height_added = height_added + 20

			if use_spacing then
				layout[#layout + 1] = {
					widget_type = layout_blueprint_names.dynamic_spacing,
					size = {
						grid_size[1],
						10,
					},
				}
				height_added = height_added + 10
			end
		elseif use_spacing then
			layout[#layout + 1] = {
				widget_type = layout_blueprint_names.dynamic_spacing,
				size = {
					grid_size[1],
					20,
				},
			}
			height_added = height_added + 20
		end

		height_used = height_used + height_added
		space_left = space_left - height_added
	end

	if description_layout_entry then
		description_layout_entry.size[2] = space_left
		height_used = height_used + space_left
	elseif can_claim then
		layout[#layout + 1] = {
			widget_type = layout_blueprint_names.dynamic_spacing,
			size = {
				grid_size[1],
				space_left,
			},
		}
		height_used = height_used + space_left
	end

	if #reward_layouts > 0 then
		table.append(layout, reward_layouts)

		height_used = height_used + reward_layouts_height
	end

	layout.achievement_id = achievement_id
	layout.tracked = AchievementUIHelper.is_favorite_achievement(achievement_id)

	return layout
end

-- Penance grid sorting: by recency or recently completed
local function _parse_completion_time_to_epoch(completion_time)
	if not completion_time then
		return 0
	end

	-- If it's already a number
	if type(completion_time) == "number" then
		return tonumber(completion_time) or 0
	end

	-- Try ISO8601-ish "YYYY-MM-DDTHH:MM:SS" -> os.time table
	local y, m, d, hh, mm, ss = completion_time:match("(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)")
	if y then
		return os.time({
			year = tonumber(y),
			month = tonumber(m),
			day = tonumber(d),
			hour = tonumber(hh),
			min = tonumber(mm),
			sec = tonumber(ss),
		}) or 0
	end

	return 0
end

-- Override the function that adds a category block (keeps header/spacing)
-- but adds optional sorting modes:
--   nil or "default"            -> use original comparator
--   "recent"                    -> sort by completion timestamp (most recent first)
--   "recently_completed"        -> put completed items first, sorted by completion time desc, then others
PenanceOverviewView._add_category_to_penance_grid_layout = function(self, layout, show_header, category_id, comparator)
	local category = AchievementCategories[category_id]

	if not category then
		return
	end

	local achievements = self._achievements_by_category[category_id]
	local filter = self._penance_grid_filters and self._penance_grid_filters[self._current_filter_index].filter

	achievements = achievements
		and (filter and table.filter_array(achievements, filter) or table.shallow_copy_array(achievements))

	local achievement_count = achievements and #achievements or 0

	if achievement_count == 0 then
		return
	end

	local grid_scenegraph_id = "penance_grid"
	local grid_size = self:_get_scenegraph_size(grid_scenegraph_id)

	layout[#layout + 1] = {
		widget_type = "dynamic_spacing",
		size = {
			grid_size[1],
			10,
		},
	}

	local display_name = category.display_name

	if show_header then
		layout[#layout + 1] = {
			widget_type = "header",
			text = Localize(display_name),
		}
	end

	-- Custom sorting when requested:
	local sort_mode = self._penance_sort_mode or "default"
	if sort_mode == "recent" then
		local player = self:_player()
		-- sort by completion timestamp (desc), tie-breaker favorites then index
		table.sort(achievements, function(a_id, b_id)
			local a_completed, a_time = Managers.achievements:achievement_completed(player, a_id)
			local b_completed, b_time = Managers.achievements:achievement_completed(player, b_id)

			local a_ts = _parse_completion_time_to_epoch(a_time)
			local b_ts = _parse_completion_time_to_epoch(b_time)

			if a_ts ~= b_ts then
				return a_ts > b_ts -- most recent first
			end

			-- keep favorites higher if present
			local a_fav = self:is_favorite_achievement(a_id)
			local b_fav = self:is_favorite_achievement(b_id)
			if a_fav ~= b_fav then
				return a_fav
			end

			local a_def = Managers.achievements:achievement_definition(a_id)
			local b_def = Managers.achievements:achievement_definition(b_id)

			return (a_def and b_def) and (a_def.index < b_def.index) or false
		end)
	elseif sort_mode == "recently_completed" then
		local player = self:_player()
		-- completed ones first (most recently completed first), then uncompleted ordered by favorite/index
		table.sort(achievements, function(a_id, b_id)
			local a_completed, a_time = Managers.achievements:achievement_completed(player, a_id)
			local b_completed, b_time = Managers.achievements:achievement_completed(player, b_id)

			if a_completed and not b_completed then
				return true
			elseif b_completed and not a_completed then
				return false
			end

			-- if both completed (or both uncompleted), compare timestamps (completed case will matter)
			local a_ts = _parse_completion_time_to_epoch(a_time)
			local b_ts = _parse_completion_time_to_epoch(b_time)

			if a_ts ~= b_ts then
				return a_ts > b_ts
			end

			-- favorites next
			local a_fav = self:is_favorite_achievement(a_id)
			local b_fav = self:is_favorite_achievement(b_id)
			if a_fav ~= b_fav then
				return a_fav
			end

			local a_def = Managers.achievements:achievement_definition(a_id)
			local b_def = Managers.achievements:achievement_definition(b_id)

			return (a_def and b_def) and (a_def.index < b_def.index) or false
		end)
	else
		if comparator then
			table.sort(achievements, comparator)
		end
	end

	-- Add the entries to the layout
	for i = 1, achievement_count do
		local achievement_id = achievements[i]

		layout[#layout + 1] = self:_get_penance_layout_entry_by_achievement_id(achievement_id)
	end

	layout[#layout + 1] = {
		widget_type = "dynamic_spacing",
		size = {
			grid_size[1],
			10,
		},
	}
end

PenanceOverviewView._set_penance_sort_mode = function(self, mode)
	self._penance_sort_mode = mode
	local index = self._selected_option_button_index or 1
	self:_select_category(index)
end

PenanceOverviewView._toggle_penance_sort_mode = function(self)
	if not self._penance_sort_mode or self._penance_sort_mode == "default" then
		self._penance_sort_mode = "recent"
		--elseif self._penance_sort_mode == "recent" then
		--self._penance_sort_mode = "recently_completed"
	else
		self._penance_sort_mode = "default"
	end

	local index = self._selected_option_button_index or 1
	self:_select_category(index)
end

PenanceOverviewView._present_penance_grid_layout = function(self, layout, optional_display_name)
	local grid = self._penance_grid
	local left_click_callback = callback(self, "_cb_on_penance_pressed")
	local right_click_callback

	local function optional_on_present_callback()
		grid:select_first_index()
	end

	grid:present_grid_layout(
		layout,
		PenanceOverviewViewDefinitions.grid_blueprints,
		left_click_callback,
		right_click_callback,
		nil,
		nil,
		optional_on_present_callback
	)
	grid:set_handle_grid_navigation(true)
end

PenanceOverviewView._should_show_view_operative = function(self)
	local index, entry, achievement_id = self:_get_target()

	local achievement_definition = Managers.achievements:achievement_definition(achievement_id)
	local reward_item, item_group

	if achievement_definition then
		reward_item, item_group = AchievementUIHelper.get_reward_item(achievement_definition)
	end
	local display = false
	if reward_item then
		display = true
	end

	-- If hovered over reward track then display too.
	if self._wintrack_element and self._wintrack_element:currently_hovered_item() then
		display = true
	end

	return display
end

PenanceOverviewView._cb_view_on_operative = function(self)
	local index, entry, achievement_id = self:_get_target()

	local achievement_definition = Managers.achievements:achievement_definition(achievement_id)
	local reward_item, item_group
	if achievement_definition then
		reward_item, item_group = AchievementUIHelper.get_reward_item(achievement_definition)
	end

	if self._wintrack_element and self._wintrack_element:currently_hovered_item() then
		reward_item = self._wintrack_element:currently_hovered_item()
	end

	local view_name = "cosmetics_inspect_view"

	local previewed_item = reward_item

	local context

	if previewed_item then
		local item_type = previewed_item.item_type
		local is_weapon = item_type == "WEAPON_MELEE" or item_type == "WEAPON_RANGED"

		if is_weapon or item_type == "GADGET" then
			view_name = "inventory_weapon_details_view"
		end

		local player = self:_player()
		local player_profile = player:profile()
		local include_skin_item_texts = true
		local item = item_type == "WEAPON_SKIN"
				and ItemUtils.weapon_skin_preview_item(previewed_item, include_skin_item_texts)
			or previewed_item
		local is_item_supported_on_played_character = false
		local item_archetypes = item.archetypes

		if item_archetypes and not table.is_empty(item_archetypes) then
			is_item_supported_on_played_character = table.array_contains(item_archetypes, player_profile.archetype.name)
		else
			is_item_supported_on_played_character = true
		end

		local profile = is_item_supported_on_played_character and table.clone_instance(player_profile)
			or ItemUtils.create_mannequin_profile_by_item(item)

		context = {
			use_store_appearance = true,
			profile = profile,
			preview_with_gear = is_item_supported_on_played_character,
			preview_item = item,
		}

		if item_type == "WEAPON_SKIN" then
			local slots = item.slots
			local slot_name = slots[1]

			profile.loadout[slot_name] = item

			local archetype = profile.archetype
			local breed_name = archetype.breed
			local breed = Breeds[breed_name]
			local state_machine = breed.inventory_state_machine
			local animation_event = item.inventory_animation_event or "inventory_idle_default"

			context.disable_zoom = true
			context.state_machine = state_machine
			context.animation_event = animation_event
			context.wield_slot = slot_name
			context.preview_item = reward_item
		end
	end

	local local_player_id = 1
	local player = Managers.player:local_player(local_player_id)
	local character_id = player:character_id()
	Managers.data_service.gear:fetch_inventory(character_id):next(function(items)
		if self._destroyed then
			return
		end

		if self._destroyed then
			return
		end

		self._inventory_items = items

		local selected_item
		for _, item in pairs(items) do
			if item.__master_item.item_type == "WEAPON_MELEE" then
				selected_item = item
				break
			end
		end
		if not Managers.ui:view_active("inventory_weapon_cosmetics_view") then
			self._customize_view_opened = true

			Managers.ui:open_view("inventory_weapon_cosmetics_view", nil, nil, nil, nil, {
				player = Managers.player:local_player(1),
				preview_item = selected_item,
				parent = self._parent,
				new_items_gear_ids = self._parent and self._parent._new_items_gear_ids,
			})
		end

		if context and not Managers.ui:view_active(view_name) then
			Managers.ui:open_view(view_name, nil, nil, nil, nil, context)

			self._inpect_view_opened = view_name
		end
	end)
end

local add_definitions = function(definitions)
	if not definitions then
		return
	end

	local penance_grid_size = PenanceOverviewViewSettings.penance_grid_size

	definitions.scenegraph_definition = definitions.scenegraph_definition or {}
	definitions.widget_definitions = definitions.widget_definitions or {}

	definitions.scenegraph_definition.recent_penance_grid = {
		horizontal_alignment = "left",
		parent = "penance_grid_background",
		vertical_alignment = "top",
		size = penance_grid_size,
		position = {
			0,
			-13,
			1,
		},
	}

	local function format_favorites(_)
		local curr, max = AchievementUIHelper.favorite_achievement_count()

		return string.format(" (%d / %d)", curr, max)
	end

	definitions.legend_inputs = {
		{
			alignment = "left_alignment",
			display_name = "loc_settings_menu_close_menu",
			input_action = "back",
			on_pressed_callback = "cb_on_close_pressed",
		},
		{
			display_name = "loc_achievements_view_button_hint_favorite_achievement",
			input_action = "hotkey_item_inspect",
			on_pressed_callback = "_on_favorite_pressed",
			visibility_function = function(parent)
				return not parent._using_cursor_navigation and parent:_cb_favorite_legend_visibility(true)
			end,
			suffix_function = format_favorites,
		},
		{
			display_name = "loc_achievements_view_button_hint_unfavorite_achievement",
			input_action = "hotkey_item_inspect",
			on_pressed_callback = "_on_favorite_pressed",
			visibility_function = function(parent)
				return not parent._using_cursor_navigation and parent:_cb_favorite_legend_visibility(false)
			end,
			suffix_function = format_favorites,
		},
		{
			display_name = "loc_achievements_view_button_hint_favorite_achievement",
			input_action = "secondary_action_pressed",
			on_pressed_callback = "_on_favorite_pressed",
			visibility_function = function(parent)
				return parent._using_cursor_navigation and parent:_cb_favorite_legend_visibility(true)
			end,
			suffix_function = format_favorites,
		},
		{
			display_name = "loc_achievements_view_button_hint_unfavorite_achievement",
			input_action = "secondary_action_pressed",
			on_pressed_callback = "_on_favorite_pressed",
			visibility_function = function(parent)
				return parent._using_cursor_navigation and parent:_cb_favorite_legend_visibility(false)
			end,
			suffix_function = format_favorites,
		},
		{
			alignment = "right_alignment",
			display_name = "",
			input_action = "hotkey_menu_special_1",
			on_pressed_callback = "cb_on_toggle_penance_appearance",
			visibility_function = function(parent, id)
				local display_name = parent._use_large_penance_entries and "loc_penance_menu_input_desc_show_grid"
					or "loc_penance_menu_input_desc_show_list"

				parent._input_legend_element:set_display_name(id, display_name)

				return parent._selected_top_option_key == "browser"
					and not parent._wintracks_focused
					and parent._enter_animation_complete
			end,
		},
		{
			alignment = "right_alignment",
			display_name = "",
			input_action = "hotkey_toggle_item_tooltip",
			on_pressed_callback = "_toggle_penance_sort_mode",
			visibility_function = function(parent, id)
				local display_name = parent._penance_sort_mode or "default"

				if display_name == "default" then
					display_name = "loc_PI_default"
				else
					display_name = "loc_PI_recently_completed"
				end

				parent._input_legend_element:set_display_name(id, display_name)

				return parent._selected_top_option_key == "browser"
					and not parent._wintracks_focused
					and parent._enter_animation_complete
			end,
		},
		{
			alignment = "right_alignment",
			display_name = "",
			input_action = "cycle_list_primary",
			on_pressed_callback = "cb_on_switch_focus",
			visibility_function = function(parent, id)
				local display_name = parent._wintracks_focused and "loc_penance_menu_input_desc_focus_penances"
					or "loc_penance_menu_input_desc_focus_track"

				parent._input_legend_element:set_display_name(id, display_name)

				return not parent._using_cursor_navigation
					and parent._wintrack_element
					and parent._enter_animation_complete
			end,
		},
		{
			display_name = "loc_PI_view_on_operative",
			input_action = "accept_invite_notification",
			on_pressed_callback = "_cb_view_on_operative",
			visibility_function = function(parent)
				return parent:_should_show_view_operative()
			end,
		},
	}
end

local function _setup_blueprint_penance_icon_and_name(input_size, edge_padding)
	edge_padding = edge_padding or 0

	return {
		size = {
			input_size[1],
			50,
		},
		size_function = function(parent, element, ui_renderer)
			local size = element.size

			return size and {
				size[1] or input_size[1],
				size[2] or 50,
			} or {
				input_size[1],
				50,
			}
		end,
		pass_template = {
			{
				pass_type = "texture",
				style_id = "texture",
				value = "content/ui/materials/icons/achievements/achievement_icon_container_v2",
				style = {
					horizontal_alignment = "left",
					size = {
						50,
						50,
					},
					material_values = {
						icon = "content/ui/textures/icons/achievements/achievement_icon_0010",
					},
					color = {
						255,
						255,
						255,
						255,
					},
					offset = {
						edge_padding * 0.5,
						0,
						1,
					},
				},
				change_function = function(content, style)
					local completed = content.completed
					local color_value = completed and 120 or 255

					style.color[2] = color_value
					style.color[3] = color_value
					style.color[4] = color_value
				end,
			},
			{
				pass_type = "texture",
				style_id = "outer_shadow",
				value = "content/ui/materials/icons/achievements/frames/achievements_dropshadow_medium",
				style = {
					horizontal_alignment = "left",
					scale_to_material = true,
					size = {
						56,
						56,
					},
					color = Color.black(200, true),
					size_addition = {
						0,
						0,
					},
					offset = {
						12,
						-3,
						7,
					},
				},
			},
			{
				pass_type = "text",
				style_id = "complete_sign",
				value = "",
				style = {
					drop_shadow = true,
					font_size = 48,
					font_type = "proxima_nova_bold",
					text_horizontal_alignment = "center",
					text_vertical_alignment = "center",
					size = {
						50,
						50,
					},
					text_color = Color.ui_terminal(255, true),
					offset = {
						edge_padding * 0.5,
						0,
						2,
					},
				},
				visibility_function = function(content, style)
					return content.completed
				end,
			},
			{
				pass_type = "text",
				style_id = "text",
				value = "n/a",
				value_id = "text",
				style = {
					font_size = 16,
					font_type = "proxima_nova_bold",
					text_horizontal_alignment = "left",
					text_vertical_alignment = "center",
					text_color = Color.terminal_text_header(255, true),
					offset = {
						edge_padding * 0.5 + 50 + 10,
						-16,
						3,
					},
					size_addition = {
						-(50 + edge_padding + 10),
						0,
					},
				},
			},
			{
				pass_type = "text",
				style_id = "description",
				value = "n/a",
				value_id = "description",
				style = {
					font_size = 14,
					font_type = "proxima_nova_bold",
					text_horizontal_alignment = "left",
					text_vertical_alignment = "center",
					text_color = Color.terminal_text_body(255, true),
					offset = {
						edge_padding * 0.5 + 50 + 10,
						8,
						3,
					},
					size_addition = {
						-(50 + edge_padding + 10),
						0,
					},
				},
			},
			{
				pass_type = "text",
				style_id = "value",
				value = "n/a",
				value_id = "value",
				style = {
					font_size = 16,
					font_type = "proxima_nova_bold",
					text_horizontal_alignment = "right",
					text_vertical_alignment = "top",
					text_color = Color.terminal_text_body(255, true),
					offset = {
						-(10 + edge_padding * 0.5),
						0,
						3,
					},
				},
			},
			visibility_function = function(content, style)
				return content.value ~= "n/a"
			end,
		},
		init = function(parent, widget, element, callback_name, secondary_callback_name, ui_renderer)
			local style = widget.style
			local content = widget.content
			local text = element.text
			local description = element.description
			local optional_text_color = element.text_color
			local value = element.value

			if optional_text_color then
				ColorUtilities.color_copy(optional_text_color, style.text.text_color)
			end

			local size = content.size
			local text_style = style.text
			local text_options = UIFonts.get_font_options_by_style(text_style)
			local max_width = (size[1] - (20 + math.abs(text_style.size_addition[1]))) * 2
			local croped_text = UIRenderer.crop_text_width(
				ui_renderer,
				text,
				text_style.font_type,
				text_style.font_size,
				max_width,
				nil,
				text_options
			)

			if description then
				content.element = element
				content.text = croped_text
				content.completed = element.completed
				content.value = value

				local croped_text_desc = UIRenderer.crop_text_width(
					ui_renderer,
					description,
					text_style.font_type,
					text_style.font_size,
					max_width,
					nil,
					text_options
				)
				content.description = croped_text_desc

				local texture = element.texture

				if texture then
					style.texture.material_values.icon = texture
				end

				local family_index = element.family_index

				if family_index then
					local number_texture = PenanceOverviewViewSettings.roman_numeral_texture_array[family_index]

					if texture and number_texture then
						style.texture.material_values.icon_number = number_texture
					end
				end
			end
		end,
	}
end

local function _setup_blueprint_sub_penance_icon_and_name(input_size, edge_padding)
	edge_padding = edge_padding or 0

	return {
		size = {
			input_size[1],
			50,
		},
		size_function = function(parent, element, ui_renderer)
			local size = element.size

			return size and {
				size[1] or input_size[1],
				size[2] or 50,
			} or {
				input_size[1],
				50,
			}
		end,
		pass_template = {
			{
				pass_type = "texture",
				style_id = "texture",
				value = "content/ui/materials/icons/achievements/achievement_icon_container_v2",
				style = {
					horizontal_alignment = "left",
					size = {
						50,
						50,
					},
					material_values = {
						icon = "content/ui/textures/icons/achievements/achievement_icon_0010",
					},
					color = {
						255,
						255,
						255,
						255,
					},
					offset = {
						edge_padding * 2,
						0,
						1,
					},
				},
				change_function = function(content, style)
					local completed = content.completed
					local color_value = completed and 120 or 255

					style.color[2] = color_value
					style.color[3] = color_value
					style.color[4] = color_value
				end,
			},
			{
				pass_type = "texture",
				style_id = "outer_shadow",
				value = "content/ui/materials/icons/achievements/frames/achievements_dropshadow_medium",
				style = {
					horizontal_alignment = "left",
					scale_to_material = true,
					size = {
						56,
						56,
					},
					color = Color.black(200, true),
					size_addition = {
						0,
						0,
					},
					offset = {
						57,
						-3,
						7,
					},
				},
			},
			{
				pass_type = "text",
				style_id = "complete_sign",
				value = "",
				style = {
					drop_shadow = true,
					font_size = 48,
					font_type = "proxima_nova_bold",
					text_horizontal_alignment = "center",
					text_vertical_alignment = "center",
					size = {
						50,
						50,
					},
					text_color = Color.ui_terminal(255, true),
					offset = {
						edge_padding * 2,
						0,
						2,
					},
				},
				visibility_function = function(content, style)
					return content.completed
				end,
			},
			{
				pass_type = "text",
				style_id = "text",
				value = "n/a",
				value_id = "text",
				style = {
					font_size = 16,
					font_type = "proxima_nova_bold",
					text_horizontal_alignment = "left",
					text_vertical_alignment = "center",
					text_color = Color.terminal_text_header(255, true),
					offset = {
						edge_padding * 2 + 50 + 10,
						-16,
						3,
					},
					size_addition = {
						-(100 + edge_padding),
						0,
					},
				},
			},
			{
				pass_type = "text",
				style_id = "description",
				value = "n/a",
				value_id = "description",
				style = {
					font_size = 14,
					font_type = "proxima_nova_bold",
					text_horizontal_alignment = "left",
					text_vertical_alignment = "center",
					text_color = Color.terminal_text_body(255, true),
					offset = {
						edge_padding * 2 + 50 + 10,
						8,
						3,
					},
					size_addition = {
						-(100 + edge_padding + 10),
						0,
					},
				},
			},
			{
				pass_type = "text",
				style_id = "value",
				value = "n/a",
				value_id = "value",
				style = {
					font_size = 16,
					font_type = "proxima_nova_bold",
					text_horizontal_alignment = "right",
					text_vertical_alignment = "top",
					text_color = Color.terminal_text_body(255, true),
					offset = {
						-(10 + edge_padding * 0.5),
						0,
						3,
					},
				},
				visibility_function = function(content, style)
					return content.value ~= "n/a"
				end,
			},
		},
		init = function(parent, widget, element, callback_name, secondary_callback_name, ui_renderer)
			local style = widget.style
			local content = widget.content
			local text = element.text
			local description = element.description

			local optional_text_color = element.text_color
			local value = element.value

			if optional_text_color then
				ColorUtilities.color_copy(optional_text_color, style.text.text_color)
			end

			local size = content.size
			local text_style = style.text
			local text_options = UIFonts.get_font_options_by_style(text_style)
			local max_width = (size[1] - (20 + math.abs(text_style.size_addition[1]))) * 2
			local croped_text = UIRenderer.crop_text_width(
				ui_renderer,
				text,
				text_style.font_type,
				text_style.font_size,
				max_width,
				nil,
				text_options
			)

			content.element = element
			content.text = croped_text
			content.completed = element.completed
			content.value = value

			local croped_text_desc = UIRenderer.crop_text_width(
				ui_renderer,
				description,
				text_style.font_type,
				text_style.font_size,
				max_width,
				nil,
				text_options
			)
			content.description = croped_text_desc

			local texture = element.texture

			if texture then
				style.texture.material_values.icon = texture
			end

			local family_index = element.family_index

			if family_index then
				local number_texture = PenanceOverviewViewSettings.roman_numeral_texture_array[family_index]

				if texture and number_texture then
					style.texture.material_values.icon_number = number_texture
				end
			end
		end,
	}
end

local add_blueprints = function(blueprints)
	if not blueprints then
		return
	end

	blueprints.penance_large = blueprints.penance_large or {}

	blueprints.penance_large.init = function(
		parent,
		widget,
		element,
		callback_name,
		secondary_callback_name,
		ui_renderer
	)
		local style = widget.style
		local content = widget.content

		content.element = element

		local texture = element.texture

		if texture then
			style.texture.material_values.icon = texture
		end

		local family_index = element.family_index

		if family_index then
			local number_texture = PenanceOverviewViewSettings.roman_numeral_texture_array[family_index]

			if texture and number_texture then
				style.texture.material_values.icon_number = number_texture
			end
		end

		local can_claim = element.can_claim

		content.can_claim = can_claim

		local bar_progress = element.bar_progress

		content.bar_progress = bar_progress

		local completed = element.completed

		content.completed = completed

		local tracked = element.tracked

		content.tracked = tracked

		local reward_icon = element.reward_icon

		if reward_icon then
			local reward_icon_style = style.reward_icon
			local material_values = reward_icon_style.material_values

			material_values.texture_map = reward_icon
		else
			style.reward_emblem.offset[2] = 0
			style.reward_score.offset[2] = 0
		end

		local title_text = element.title or "n/a"

		if title_text then
			local title_text_style = style.title
			local size = content.size
			local text_max_width = size[1] + title_text_style.size_addition[1] - 30
			local text_options = UIFonts.get_font_options_by_style(title_text_style)
			local title_text_croped = UIRenderer.crop_text_width(
				ui_renderer,
				title_text,
				title_text_style.font_type,
				title_text_style.font_size,
				text_max_width,
				nil,
				text_options
			)

			content.title = title_text_croped
		end

		local player = Managers.player:local_player(1)
		local _, completion_time = Managers.achievements:achievement_completed(player, element.achievement_id)
		local timestamp
		if completion_time and completion_time ~= 0 then
			local pattern = "(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)"

			-- if completion_time is not a number (needs to be a string to match pattern)
			if type(completion_time) ~= "number" then
				local year, month, day, hour, minute, second = completion_time:match(pattern)

				timestamp = os.time({
					year = year,
					month = month,
					day = day,
					hour = hour,
					min = minute,
					sec = second,
				})
			end
		end
		local date
		if timestamp then
			date = os.date("%c", timestamp)
		end
		local description_text = not can_claim
				and completed
				and date
				and TextUtilities.apply_color_to_text(
					Localize("loc_notification_desc_achievement_completed"),
					Color.terminal_text_key_value(255, true)
				) .. "\nCompleted on: " .. date
			or not can_claim and completed and TextUtilities.apply_color_to_text(
				Localize("loc_notification_desc_achievement_completed"),
				Color.terminal_text_key_value(255, true)
			)
			or element.description
			or "n/a"

		if description_text then
			local description_text_style = style.description
			local size = content.size
			local num_rows = bar_progress and 3 or 4
			local text_max_width = (size[1] + description_text_style.size_addition[1] - 60) * num_rows
			local text_options = UIFonts.get_font_options_by_style(description_text_style)
			local description_text_croped = UIRenderer.crop_text_width(
				ui_renderer,
				description_text,
				description_text_style.font_type,
				description_text_style.font_size,
				text_max_width,
				nil,
				text_options
			)

			content.description = description_text_croped
		end

		content.bar_values_text = not can_claim and element.bar_values_text or ""
		content.reward_score = element.achievement_score and "+" .. element.achievement_score or ""

		if bar_progress then
			style.description.offset[2] = style.description.offset[2] + 25
		end

		content.hotspot.pressed_callback = callback(parent, callback_name, widget, element)
		content.hotspot.right_pressed_callback = callback(parent, secondary_callback_name, widget, element)

		if bar_progress then
			style.bar.size[1] = style.bar.default_size[1] * bar_progress
		end

		local texture_color = element.color

		if texture_color then
			local color = style.texture.color

			color[1] = texture_color[1]
			color[2] = texture_color[2]
			color[3] = texture_color[3]
			color[4] = texture_color[4]
		end
	end
	local tooltip_grid_size = PenanceOverviewViewSettings.tooltip_grid_size
	local tooltip_entries_width = PenanceOverviewViewSettings.tooltip_entries_width
	local tooltip_blueprint_size = {
		tooltip_entries_width,
		tooltip_grid_size[2],
	}
	local carousel_penance_size = PenanceOverviewViewSettings.carousel_penance_size

	PenanceOverviewViewSettings.blueprints_by_page = {
		carousel = {
			body = "carousel_penance_body",
			category = "carousel_penance_category",
			completed = "carousel_penance_completed",
			dynamic_spacing = "dynamic_spacing",
			header = "carousel_penance_header",
			penance_icon = "carousel_penance_icon",
			penance_icon_and_name = "carousel_penance_icon_and_name",
			penance_icon_small = "carousel_penance_icon_small",
			sub_penance_icon_and_name = "carousel_sub_penance_icon_and_name",
			progress_bar = "carousel_penance_progress_bar",
			score = "carousel_penance_reward",
			score_and_reward = "carousel_penance_score_and_reward",
			stat = "carousel_penance_stat",
			tracked = "carousel_penance_tracked",
		},
		tooltip = {
			body = "tooltip_penance_body",
			category = "tooltip_penance_category",
			completed = "tooltip_penance_completed",
			dynamic_spacing = "dynamic_spacing",
			header = "tooltip_penance_header",
			penance_icon = "tooltip_penance_icon",
			penance_icon_and_name = "tooltip_penance_icon_and_name",
			penance_icon_small = "tooltip_penance_icon_small",
			sub_penance_icon_and_name = "tooltip_sub_penance_icon_and_name",
			progress_bar = "tooltip_penance_progress_bar",
			score = "tooltip_penance_reward",
			score_and_reward = "tooltip_penance_score_and_reward",
			stat = "tooltip_penance_stat",
			tracked = "tooltip_penance_tracked",
		},
	}

	blueprints.tooltip_sub_penance_icon_and_name =
		_setup_blueprint_sub_penance_icon_and_name(tooltip_blueprint_size, 30)
	blueprints.carousel_sub_penance_icon_and_name = _setup_blueprint_sub_penance_icon_and_name(carousel_penance_size)
	blueprints.tooltip_penance_icon_and_name = _setup_blueprint_penance_icon_and_name(tooltip_blueprint_size, 30)
	blueprints.carousel_penance_icon_and_name = _setup_blueprint_penance_icon_and_name(carousel_penance_size)
end

mod:hook_require("scripts/ui/views/penance_overview_view/penance_overview_view_blueprints", function(blueprints)
	add_blueprints(blueprints)
end)

mod:hook_require("scripts/ui/views/penance_overview_view/penance_overview_view_definitions", function(definitions)
	add_definitions(definitions)
end)

if not cvi then
	CosmeticsInspectView._setup_input_legend = function(self)
		local context = self._context
		local use_store_appearance = context.use_store_appearance

		self._input_legend_element = self:_add_element(ViewElementInputLegend, "input_legend", 50)

		local menu_zoom_out = "loc_inventory_menu_zoom_out"
		local menu_zoom_in = "loc_inventory_menu_zoom_in"
		local menu_preview_with_gear_off = "loc_inventory_menu_preview_with_gear_off"
		local menu_preview_with_gear_on = "loc_inventory_menu_preview_with_gear_on"

		local legend_inputs = {
			{
				alignment = "left_alignment",
				display_name = "loc_settings_menu_close_menu",
				input_action = "back",
				on_pressed_callback = "cb_on_close_pressed",
			},
			{
				alignment = "right_alignment",
				input_action = "hotkey_menu_special_1",
				on_pressed_callback = "cb_on_preview_with_gear_toggled",
				display_name = menu_preview_with_gear_off,
				visibility_function = function(parent, id)
					local display_name = parent._previewed_with_gear and menu_preview_with_gear_off
						or menu_preview_with_gear_on

					parent._input_legend_element:set_display_name(id, display_name)

					local visible = parent:_can_preview()
					if parent.hide_character and parent.hide_character == true then
						visible = false
					end

					return visible
				end,
			},
			{
				alignment = "right_alignment",
				display_name = "loc_inventory_menu_swap_weapon",
				input_action = "hotkey_menu_special_1",
				on_pressed_callback = "cb_on_weapon_swap_pressed",
				store_appearance_option = true,
				visibility_function = function(parent)
					return parent:_can_swap_weapon()
				end,
			},
			{
				alignment = "right_alignment",
				display_name = "loc_inventory_menu_zoom_in",
				input_action = "hotkey_menu_special_2",
				on_pressed_callback = "cb_on_camera_zoom_toggled",
				visibility_function = function(parent, id)
					local display_name = parent._camera_zoomed_in and menu_zoom_out or menu_zoom_in

					parent._input_legend_element:set_display_name(id, display_name)

					local visible = true
					if parent.hide_character and parent.hide_character == true then
						visible = false
					end
					return visible
				end,
			},
			{
				alignment = "right_alignment",
				display_name = "loc_preview_voice",
				input_action = "hotkey_item_inspect",
				on_pressed_callback = "cb_preview_voice",
				visibility_function = function(parent, id)
					return parent:_can_preview_voice()
				end,
			},
		}

		for i = 1, #legend_inputs do
			local legend_input = legend_inputs[i]
			local valid = true

			if legend_input.store_appearance_option and not use_store_appearance then
				valid = false
			end

			if valid then
				local on_pressed_callback = legend_input.on_pressed_callback
					and callback(self, legend_input.on_pressed_callback)

				self._input_legend_element:add_entry(
					legend_input.display_name,
					legend_input.input_action,
					legend_input.visibility_function,
					on_pressed_callback,
					legend_input.alignment
				)
			end
		end
	end
end

-- fix compatibility with weapon customization extended mod
mod.on_all_mods_loaded = function()
	local WCVI = get_mod("weapon_cosmetics_view_improved")

	if not WCVI then -- same fix is implemented in WCVI mod
		local weapon_customization = get_mod("weapon_customization")

		local vector3 = Vector3
		local vector3_box = Vector3Box
		local vector3_unbox = vector3_box.unbox
		local Unit = Unit
		local unit_set_local_position = Unit.set_local_position

		if weapon_customization then
			weapon_customization.set_light_positions = function(self)
				-- Get cosmetic view
				self:get_cosmetic_view()
				if self.preview_lights and self.cosmetics_view then
					for _, unit_data in pairs(self.preview_lights) do
						-- Get default position
						if unit_data.position then
							local default_position = vector3_unbox(unit_data.position)
							-- Get difference to link unit position
							local weapon_spawner = self.cosmetics_view._weapon_preview._ui_weapon_spawner
							if
								weapon_spawner
								and weapon_spawner._link_unit_position
								and weapon_spawner._link_unit_base_position
							then
								local link_difference = vector3_unbox(weapon_spawner._link_unit_base_position)
									- vector3_unbox(weapon_spawner._link_unit_position)
								-- Position with offset
								local light_position = vector3(
									default_position[1],
									default_position[2] - link_difference[2],
									default_position[3]
								)
								-- mod:info("WEAPONCUSTOMIZATION.set_light_positions: " .. tostring(unit_data.unit))
								if not tostring(unit_data.unit) == "[Unit (deleted)]" then
									unit_set_local_position(unit_data.unit, 1, light_position)
								end
							end
						end
					end
				end
			end
		end
	end
end
