local mod = get_mod("penances_improved")
mod.version = "2.6.0"
mod:info("Penance View Improved is installed, using version: " .. tostring(mod.version))

local colours = {
	title = "200,140,20",
	subtitle = "226,199,126",
	text = "169,191,153",
}

mod:add_global_localize_strings({
	loc_PI_recently_completed = {
		en = "Sort: Recently Completed",
		ru = "Недавно выполненные",
		["zh-cn"] = "最近完成",
	},
	loc_PI_view_on_operative = {
		en = "Inspect Reward",
		ru = "Посмотреть награды",
		["zh-cn"] = "预览奖励",
	},
	loc_PI_swap_operative = {
		en = "Change Operative",
		ru = "Смена оперативника",
		["zh-cn"] = "变更特工",
	},
	loc_PI_default = {
		en = "Sort: Default",
		ru = "По умолчанию",
		["zh-cn"] = "默认",
	},
})

mod._available_aliases = {
	"character_create_randomize",
	"hotkey_item_favorite",
	"hotkey_help",
	"hotkey_inventory",
	"hotkey_loadout",
	"hotkey_menu_special_1",
	"hotkey_menu_special_2",
	"hotkey_toggle_item_tooltip",
	"accept_invite_notification",
	"hotkey_item_inspect",
	"hotkey_item_discard",
	"hotkey_start_game",
	"group_finder_group_inspect",
	"next_hint",
	"cycle_list_secondary",
	"notification_option_a",
	"notification_option_b",
	"talent_unequip",
}

local InputUtils = require("scripts/managers/input/input_utils")

mod.localisation = {
	mod_name = {
		en = "{#color("
			.. colours.title
			.. ")} "
			.. "{#color(255,0,83)}P{#color(255,10,77)}e{#color(255,20,71)}n{#color(255,30,66)}a{#color(255,40,60)}n{#color(255,50,55)}c{#color(255,60,49)}e{#color(255,70,44)}s {#color(255,80,38)}I{#color(255,90,33)}m{#color(255,100,27)}p{#color(255,109,22)}r{#color(255,120,16)}o{#color(255,130,11)}v{#color(255,140,5)}e{#color(255,150,0)}d{#reset()}",
		ru = "Улучшенный вид Искуплений",
		["zh-cn"] = "苦修视图改进",
	},
	mod_description = {
		en = "{#color("
			.. colours.text
			.. ")}"
			.. "'Recently completed' sorting, sub-penance details, view all rewards, inspect insignias and frames and more, to improve the penances screen."
			.. "{#reset()}\n\n"
			.. "{#color("
			.. colours.subtitle
			.. ")}Author: "
			.. "{#color("
			.. colours.text
			.. ")}Alfthebigheaded\n"
			.. "{#color("
			.. colours.subtitle
			.. ")}Version: {#color("
			.. colours.text
			.. ")}"
			.. mod.version
			.. "{#reset()}",
		ru = "Penance View Improved - Улучшает экран Искуплений, добавляя «Недавно выполненные» Искупления, более подробную информацию о каждом Искуплении и других Искуплениях, нужных для их выполнения, а также возможность просматривать награды ваших оперативников и многое другое!",
		["zh-cn"] = "增加「最近完成」的苦修页面；更多苦修和子级苦修细节；在你的特工身上预览奖励物品；以及更多功能！",
	},
	mod_name_pizazz = {
		en = "{#color("
			.. colours.title
			.. ")} "
			.. "{#color(255,0,83)}P{#color(255,10,77)}e{#color(255,20,71)}n{#color(255,30,66)}a{#color(255,40,60)}n{#color(255,50,55)}c{#color(255,60,49)}e{#color(255,70,44)}s {#color(255,80,38)}I{#color(255,90,33)}m{#color(255,100,27)}p{#color(255,109,22)}r{#color(255,120,16)}o{#color(255,130,11)}v{#color(255,140,5)}e{#color(255,150,0)}d{#reset()}",
		ru = "Улучшенный вид Искуплений",
		["zh-cn"] = "苦修视图改进",
	},
	mod_name_boring = {
		en = "Penance View Improved",
	},
	mod_name_pizazz_toggle = {
		en = "Enable Name Pizazz",
	},
	mod_name_pizazz_tooltip = {
		en = "Toggles the rainbow colours effect on the mod name text. Requires a reload.\nIf enabled, you will get a small euphoric experience everytime you scroll through the mod menu, \nIf disabled - you will be a John Darktide and have no rainbow sprinkles (but I'll love you anyway).",
	},
	general_settings = {
		en = "{#color(" .. colours.title .. ")}General Settings{#reset()}",
	},
	legend_settings = {
		en = "{#color(" .. colours.title .. ")}Keybind Settings{#reset()}",
	},
	keybind_sort_mode = {
		en = "Sort Mode Keybind (Requires game reload)",
	},
	keybind_sort_mode_tooltip = {
		en = "Select which game input action to use for cycling sort modes.\nShown in the penance view legend. Changing this requires reloading the game.",
	},
	keybind_inspect_reward = {
		en = "Inspect Reward Keybind (Requires game reload)",
	},
	keybind_inspect_reward_tooltip = {
		en = "Select which game input action to use for inspecting rewards.\nShown in the penance view legend. Changing this requires reloading the game.",
	},
	off = {
		en = Localize("loc_setting_checkbox_off"),
	},
}

for _, action in ipairs(mod._available_aliases) do
	local alias_key = Managers.ui:get_input_alias_key(action, "View")
	local input_text = InputUtils.input_text_for_current_input_device("View", alias_key)
	mod.localisation[action] = { en = input_text }
end

mod.toggle_pizazz = function()
	for key, values in pairs(mod.localisation) do
		if key == "mod_name" then
			for language, text in pairs(values) do
				if mod:get("mod_name_pizazz_toggle") then
					mod.localisation[key][language] = mod.localisation["mod_name_pizazz"][language]
				else
					mod.localisation[key][language] = mod.localisation["mod_name_boring"][language]
				end
			end
		end
	end
end

mod.toggle_pizazz()

return mod.localisation
