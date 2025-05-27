local InputUtilities = require("scripts/managers/input/input_utils")
local PenanceOverviewViewDefinitions = require(
"scripts/ui/views/penance_overview_view/penance_overview_view_definitions")
local PenanceBlueprints = require("scripts/ui/views/penance_overview_view/penance_overview_view_blueprints")
local PenanceOverviewViewSettings = require("scripts/ui/views/penance_overview_view/penance_overview_view_settings")
local carousel_penance_size = PenanceOverviewViewSettings.carousel_penance_size

local reward_icon_large = {
    164,
    164,
}
local reward_glow_large = {
    328,
    328,
}
local reward_icon_medium = {
    112,
    112,
}
local reward_glow_medium = {
    224,
    224,
}
local reward_icon_small = {
    94,
    94,
}
local reward_glow_small = {
    188,
    188,
}

local claim_overlay = {
    size = {
        carousel_penance_size[1],
        0,
    },
    pass_template = {
        {
            pass_type = "texture",
            style_id = "overlay",
            value = "content/ui/materials/backgrounds/default_square",
            style = {
                size = {
                    0,
                    0,
                },
                color = {
                    250,
                    0,
                    0,
                    0,
                },
                offset = {
                    0,
                    0,
                    10,
                },
            },
        },
        {
            pass_type = "texture",
            style_id = "icon",
            value = "content/ui/materials/frames/achievements/penance_reward_symbol",
            style = {
                size = reward_icon_large,
                color = {
                    255,
                    255,
                    255,
                    255,
                },
                offset = {
                    0,
                    0,
                    12,
                },
            },
        },
        {
            pass_type = "texture",
            style_id = "glow",
            value = "content/ui/materials/frames/achievements/wintrack_claimed_reward_display_background_glow",
            style = {
                scale_to_material = true,
                color = Color.ui_terminal(255, true),
                offset = {
                    0,
                    0,
                    11,
                },
                size = reward_glow_large,
            },
        },
        {
            pass_type = "text",
            style_id = "title",
            value_id = "title",
            style = {
                font_size = 30,
                font_type = "proxima_nova_bold",
                text_horizontal_alignment = "center",
                text_vertical_alignment = "center",
                text_color = Color.terminal_text_key_value(255, true),
                offset = {
                    20,
                    100,
                    13,
                },
                size = {
                    0,
                    0,
                },
                size_addition = {
                    -40,
                    0,
                },
            },
            value = Localize("loc_penance_menu_completed_title"),
        },
        {
            pass_type = "text",
            style_id = "description",
            value_id = "description",
            style = {
                font_size = 24,
                font_type = "proxima_nova_bold",
                text_horizontal_alignment = "center",
                text_vertical_alignment = "center",
                text_color = Color.terminal_text_header(255, true),
                offset = {
                    20,
                    135,
                    13,
                },
                size = {
                    0,
                    0,
                },
                size_addition = {
                    -40,
                    0,
                },
            },
            value = Localize("loc_penance_menu_claim_button"),
        },
    },
    init = function(parent, widget, element, callback_name, secondary_callback_name, ui_renderer)
        local size = element.size
        local style = widget.style

        if size then
            local title_style = style.title

            if title_style then
                local title_size = title_style.size

                title_size[1] = size[1]
                title_size[2] = size[2]
            end

            local description_style = style.description

            if description_style then
                local description_size = description_style.size

                description_size[1] = size[1]
                description_size[2] = size[2]
            end

            local overlay_style = style.overlay

            if overlay_style then
                local texture_size = overlay_style.size

                texture_size[1] = size[1]
                texture_size[2] = size[2]
            end

            local icon_style = style.icon

            if icon_style then
                local texture_size = icon_style.size
                local offset = icon_style.offset

                offset[1] = (size[1] - texture_size[1]) * 0.5
                offset[2] = (size[2] - texture_size[2]) * 0.5
            end

            local glow_style = style.glow

            if glow_style then
                local texture_size = glow_style.size
                local offset = glow_style.offset

                offset[1] = (size[1] - texture_size[1]) * 0.5
                offset[2] = (size[2] - texture_size[2]) * 0.5
            end
        end
    end,
    update = function(parent, widget, input_service, dt, t, ui_renderer)
        if parent._using_cursor_navigation then
            widget.content.description = Localize("loc_penance_menu_claim_button")
        elseif widget.content.hovered or widget.content.hovered then
            local action = "confirm_pressed"
            local service_type = "View"
            local alias_key = Managers.ui:get_input_alias_key(action, service_type)
            local input_text = InputUtilities.input_text_for_current_input_device(service_type, alias_key)

            widget.content.description = string.format("%s %s", input_text, Localize("loc_penance_menu_claim_button"))
        else
            widget.content.description = ""
        end
    end,
}

return {
    claim_overlay
}
