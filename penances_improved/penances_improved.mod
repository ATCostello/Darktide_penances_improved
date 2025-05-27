return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`penances_improved` encountered an error loading the Darktide Mod Framework.")

		new_mod("penances_improved", {
			mod_script       = "penances_improved/scripts/mods/penances_improved/penances_improved",
			mod_data         = "penances_improved/scripts/mods/penances_improved/penances_improved_data",
			mod_localization = "penances_improved/scripts/mods/penances_improved/penances_improved_localization",
		})
	end,
	packages = {},
}
