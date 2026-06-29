local mod = get_mod("penances_improved")

local _get_keybind_list = function()
	local list = {
		{ text = "off", value = "off" }
	}
	for _, action in ipairs(mod._available_aliases) do
		list[#list + 1] = { text = action, value = action }
	end
	return list
end

mod.settings_widgets = {}

table.insert(mod.settings_widgets, {
	setting_id = "general_settings",
	type = "group",
	sub_widgets = {
		{
			setting_id = "mod_name_pizazz_toggle",
			type = "checkbox",
			default_value = true,
			tooltip = "mod_name_pizazz_tooltip",
		},
	},
})

table.insert(mod.settings_widgets, {
	setting_id = "legend_settings",
	type = "group",
	sub_widgets = {
		{
			setting_id = "keybind_sort_mode",
			type = "dropdown",
			default_value = "hotkey_toggle_item_tooltip",
			options = _get_keybind_list(),
			tooltip = "keybind_sort_mode_tooltip",
		},
		{
			setting_id = "keybind_inspect_reward",
			type = "dropdown",
			default_value = "accept_invite_notification",
			options = _get_keybind_list(),
			tooltip = "keybind_inspect_reward_tooltip",
		},
	},
})

return {
	name = mod:localize("mod_name"),
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = mod.settings_widgets,
	},
}
