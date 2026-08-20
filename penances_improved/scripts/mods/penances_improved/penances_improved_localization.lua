local mod = get_mod("penances_improved")
mod.version = "2.6.03"
mod:info("Penance View Improved is installed, using version: " .. tostring(mod.version))

local colours = {
	title = "200,140,20",
	subtitle = "226,199,126",
	text = "169,191,153",
}

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function utf8_chars(s)
	local chars = {}
	for char in string.gmatch(s, "[%z\1-\127\194-\244][\128-\191]*") do
		table.insert(chars, char)
	end
	return chars
end

mod.gradientText = function(text, startColor, endColor, colorSpaces)
	local result = ""
	local chars = utf8_chars(text)
	local visibleIndex = 0

	for _, char in ipairs(chars) do
		if colorSpaces or char ~= " " then
			visibleIndex = visibleIndex + 1
		end
	end

	local currentIndex = 0

	for _, char in ipairs(chars) do
		if not colorSpaces and char == " " then
			result = result .. char
		else
			currentIndex = currentIndex + 1
			local t = (visibleIndex <= 1) and 0 or (currentIndex - 1) / (visibleIndex - 1)

			local r = math.floor(lerp(startColor[1], endColor[1], t))
			local g = math.floor(lerp(startColor[2], endColor[2], t))
			local b = math.floor(lerp(startColor[3], endColor[3], t))

			result = result .. string.format("{#color(%d,%d,%d)}%s", r, g, b, char)
		end
	end

	result = "{#color(" .. colours.title .. ")}" .. result .. "{#reset()}"
	return result
end

mod:add_global_localize_strings({
	loc_PI_recently_completed = {
		en = "Sort: Recently Completed",
		ru = "Недавно выполненные",
		["zh-cn"] = "最近完成",
		["zh-tw"] = "最近完成",
	},
	loc_PI_view_on_operative = {
		en = "Inspect Reward",
		ru = "Посмотреть награды",
		["zh-cn"] = "预览奖励",
		["zh-tw"] = "預覽獎勵",
	},
	loc_PI_swap_operative = {
		en = "Change Operative",
		ru = "Смена оперативника",
		["zh-cn"] = "变更特工",
		["zh-tw"] = "變更特工",
	},
	loc_PI_default = {
		en = "Sort: Default",
		ru = "По умолчанию",
		["zh-cn"] = "默认",
		["zh-tw"] = "預設",
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

local mod_name = {
	en = "Penance View Improved",
	ru = "Улучшенный вид Искуплений",
	["zh-cn"] = "苦修视图改进",
	["zh-tw"] = "苦修視圖改進",
}

mod.localisation = {

	mod_name = {
		en = mod_name["en"],
		ru = mod_name["ru"],
		["zh-cn"] = mod_name["zh-cn"],
		["zh-tw"] = mod_name["zh-tw"],
	},
	mod_name_pizazz = {
		en = mod.gradientText(mod_name["en"], { 255, 0, 83 }, { 255, 150, 0 }, true),
		ru = mod.gradientText(mod_name["ru"], { 255, 0, 83 }, { 255, 150, 0 }, true),
		["zh-cn"] = mod.gradientText(mod_name["zh-cn"], { 255, 0, 83 }, { 255, 150, 0 }, true),
		["zh-tw"] = mod.gradientText(mod_name["zh-tw"], { 255, 0, 83 }, { 255, 150, 0 }, true),
	},
	mod_name_boring = {
		en = mod_name["en"],
		ru = mod_name["ru"],
		["zh-cn"] = mod_name["zh-cn"],
		["zh-tw"] = mod_name["zh-tw"],
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
		["zh-tw"] = "增加「最近完成」的苦修頁面；更多苦修和子級苦修細節；在你的特工身上預覽獎勵物品；以及更多功能！",
	},

	mod_name_pizazz_toggle = {
		en = "Enable Name Pizazz",
		ru = "Включить красочные имена",
		["zh-cn"] = "启用名称特效",
		["zh-tw"] = "啟用名稱特效",
	},
	mod_name_pizazz_tooltip = {
		en = "Toggles the rainbow colours effect on the mod name text. Requires a reload.\nIf enabled, you will get a small euphoric experience everytime you scroll through the mod menu, \nIf disabled - you will be a John Darktide and have no rainbow sprinkles (but I'll love you anyway).",
		ru = "Включает радужный эффект для текста имени мода. Требуется перезагрузка.\nЕсли включено, вы будете получать небольшой эйфорический опыт каждый раз, когда прокручиваете меню модов.\nЕсли выключено - вы будете Джоном Дарктайдом и без радужных посыпок (но я все равно буду вас любить).",
		["zh-cn"] = "切换模组名称的彩虹颜色效果。需要重新加载。\n启用后，每次滚动模组菜单时你都会获得小小的愉悦体验。\n禁用后，你将失去彩虹点缀（但我仍然爱你）。",
		["zh-tw"] = "切換模組名稱的彩虹顏色效果。需要重新載入。\n啟用後，每次滾動模組選單時你都會獲得小小的愉悅體驗。\n停用後，你將成為一般的黑暗潮汐玩家，失去彩虹點綴（但我仍然愛你）。",
	},
	general_settings = {
		en = "{#color(" .. colours.title .. ")}General Settings{#reset()}",
		ru = "{#color(" .. colours.title .. ")}Основные настройки{#reset()}",
		["zh-cn"] = "{#color(" .. colours.title .. ")}通用设置{#reset()}",
		["zh-tw"] = "{#color(" .. colours.title .. ")}一般設定{#reset()}",
	},
	legend_settings = {
		en = "{#color(" .. colours.title .. ")}Keybind Settings{#reset()}",
		ru = "{#color(" .. colours.title .. ")}Настройки привязок клавиш{#reset()}",
		["zh-cn"] = "{#color(" .. colours.title .. ")}快捷键设置{#reset()}",
		["zh-tw"] = "{#color(" .. colours.title .. ")}快捷鍵設定{#reset()}",
	},
	keybind_sort_mode = {
		en = "Sort Mode Keybind (Requires game reload)",
		ru = "Привязка режима сортировки (требуется перезагрузка игры)",
		["zh-cn"] = "排序模式快捷键（需要重新加载游戏）",
		["zh-tw"] = "排序模式快捷鍵（需要重新載入遊戲）",
	},
	keybind_sort_mode_tooltip = {
		en = "Select which game input action to use for cycling sort modes.\nShown in the penance view legend. Changing this requires reloading the game.",
		ru = "Выберите действие ввода для переключения режимов сортировки.\nОтображается в легенде вида искуплений. Изменение требует перезагрузки игры.",
		["zh-cn"] = "选择用于切换排序模式的游戏输入操作。\n显示在苦行视图图例中。更改此设置需要重新加载游戏。",
		["zh-tw"] = "選擇用於切換排序模式的遊戲輸入操作。\n顯示在苦行視圖圖例中。更改此設定需要重新載入遊戲。",
	},
	keybind_inspect_reward = {
		en = "Inspect Reward Keybind (Requires game reload)",
		ru = "Привязка осмотра награды (требуется перезагрузка игры)",
		["zh-cn"] = "预览奖励快捷键（需要重新加载游戏）",
		["zh-tw"] = "預覽獎勵快捷鍵（需要重新載入遊戲）",
	},
	keybind_inspect_reward_tooltip = {
		en = "Select which game input action to use for inspecting rewards.\nShown in the penance view legend. Changing this requires reloading the game.",
		ru = "Выберите действие ввода для осмотра наград.\nОтображается в легенде вида искуплений. Изменение требует перезагрузки игры.",
		["zh-cn"] = "选择用于预览奖励的游戏输入操作。\n显示在苦行视图图例中。更改此设置需要重新加载游戏。",
		["zh-tw"] = "選擇用於預覽獎勵的遊戲輸入操作。\n顯示在苦行視圖圖例中。更改此設定需要重新載入遊戲。",
	},
	off = {
		en = Localize("loc_setting_checkbox_off"),
		ru = Localize("loc_setting_checkbox_off"),
		["zh-cn"] = Localize("loc_setting_checkbox_off"),
		["zh-tw"] = Localize("loc_setting_checkbox_off"),
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
