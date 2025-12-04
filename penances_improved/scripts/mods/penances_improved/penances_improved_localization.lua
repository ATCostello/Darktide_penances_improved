local mod = get_mod("penances_improved")

mod:add_global_localize_strings(
    {
        loc_PI_recently_completed = {
			en = "Sort: Recently Completed", 
			ru = "Недавно выполненные", 
			["zh-cn"] = "最近完成"
		},
        loc_PI_view_on_operative = {
			en = "Inspect Reward", 
			ru = "Посмотреть награды", 
			["zh-cn"] = "预览奖励"
		},
        loc_PI_swap_operative = {
			en = "Change Operative", 
			ru = "Смена оперативника", 
			["zh-cn"] = "变更特工"
		},
		loc_PI_default = {
			en = "Sort: Default"
		}
    }
)

return {
    mod_name = {
		en = "Penance View Improved", 
		ru = "Улучшенный вид Искуплений", 
		["zh-cn"] = "苦修视图改进"
	},
    mod_description = {
        en = "Improves the penance screen by adding \"Recently completed\" penances, more details about each penance and sub-penance, ability to view rewards on your operatives and more!",
        ru = "Penance View Improved - Улучшает экран Искуплений, добавляя «Недавно выполненные» Искупления, более подробную информацию о каждом Искуплении и других Искуплениях, нужных для их выполнения, а также возможность просматривать награды ваших оперативников и многое другое!",
        ["zh-cn"] = "增加「最近完成」的苦修页面；更多苦修和子级苦修细节；在你的特工身上预览奖励物品；以及更多功能！"
    }
}
