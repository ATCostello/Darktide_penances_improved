local mod = get_mod("penances_improved")
mod.version = "2.5.05"
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
	},
})

return {
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
	general_settings = {
		en = "{#color(" .. colours.title .. ")}General Settings{#reset()}",
	},
	placeholder = {
		en = "",
	},
	placeholder_tooltip = {
		en = "A placeholder entry to initialise the mod menu, does not do anything yet.\nMore features may be added at some point.",
	},
}
