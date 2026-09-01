-- Copyright (C) 2020-2026 Aditya Shakya <adi1090x@gmail.com>
-- Hyprland Lua configuration file for Archcraft (Catppuccin)
-- Hyprland Version: 0.56.1+

local home = os.getenv("HOME") or "/home/user"
local hyprDir = home .. "/.config/hyprcat"
local scripts = hyprDir .. "/scripts"

local alacritty       = scripts .. "/alacritty"
local files           = "thunar"
local editor          = "geany"
local browser         = "firefox"
local volume          = scripts .. "/volume"
local backlight       = scripts .. "/brightness"
local screenshot      = scripts .. "/screenshot"
local colorpicker     = scripts .. "/colorpicker"

local rofi_launcher   = scripts .. "/rofi_launcher"
local rofi_runner     = scripts .. "/rofi_runner"
local rofi_mpd        = scripts .. "/rofi_mpd"
local rofi_spotify    = scripts .. "/rofi_spotify"
local rofi_network    = scripts .. "/rofi_network"
local rofi_bluetooth  = scripts .. "/rofi_bluetooth"
local rofi_powermenu  = scripts .. "/rofi_powermenu"
local rofi_screenshot = scripts .. "/rofi_screenshot"
local rofi_asroot     = scripts .. "/rofi_asroot"

------------------
---- MONITORS ----
------------------
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

-------------------
---- AUTOSTART ----
-------------------
hl.on("hyprland.start", function()
    hl.exec_cmd("hyprpaper --config " .. hyprDir .. "/hyprpaper.conf")
    hl.exec_cmd("hypridle --config " .. hyprDir .. "/hypridle.conf")
    hl.exec_cmd("hyprsunset")
    hl.exec_cmd(scripts .. "/startup")
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------
hl.env("XCURSOR_THEME", "Sweet")
hl.env("XCURSOR_SIZE", "16")

-----------------------
---- LOOK AND FEEL ----
-----------------------
hl.config({
    general = {
        border_size = 4,
        gaps_in = 10,
        gaps_out = 20,
        float_gaps = 0,
        gaps_workspaces = -20,
        col = {
            active_border = { colors = {"0xFF89B4FA", "0xFFF38BA8"}, angle = 45 },
            inactive_border = { colors = {"0xFF28283d", "0xFF32324d"}, angle = 45 },
            nogroup_border = "0xFF32324d",
            nogroup_border_active = "0xFF89B4FA",
        },
        layout = "dwindle",
        no_focus_fallback = false,
        resize_on_border = true,
        extend_border_grab_area = 15,
        hover_icon_on_border = true,
        allow_tearing = false,
        resize_corner = 0,
        modal_parent_blocking = true,
        snap = {
            enabled = false,
            window_gap = 10,
            monitor_gap = 10,
            border_overlap = false,
            respect_gaps = false,
        },
    },

    decoration = {
        rounding = 12,
        rounding_power = 2.0,
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        fullscreen_opacity = 1.0,
        dim_modal = true,
        dim_inactive = false,
        dim_strength = 0.5,
        dim_special = 0.2,
        dim_around = 0.4,
        border_part_of_window = true,
        blur = {
            enabled = false,
            size = 8,
            passes = 3,
            ignore_opacity = true,
            new_optimizations = true,
            xray = false,
            noise = 0.0117,
            contrast = 0.8916,
            brightness = 0.8172,
            vibrancy = 0.1696,
            vibrancy_darkness = 0.0,
            special = false,
            popups = true,
            popups_ignorealpha = 0.2,
            input_methods = false,
            input_methods_ignorealpha = 0.2,
        },
        shadow = {
            enabled = true,
            range = 25,
            render_power = 3,
            sharp = false,
            color = 0x66000000,
            color_inactive = 0x66000000,
            offset = "0 0",
            scale = 1.0,
        },
    },

    animations = {
        enabled = true,
        workspace_wraparound = false,
    },

    input = {
        kb_options = "caps:swapescape",
        numlock_by_default = false,
        resolve_binds_by_sym = false,
        repeat_rate = 25,
        repeat_delay = 600,
        sensitivity = 0.5,
        accel_profile = "adaptive",
        force_no_accel = false,
        rotation = 0,
        left_handed = false,
        scroll_method = "2fg",
        scroll_button = 0,
        scroll_button_lock = 0,
        scroll_factor = 1.0,
        natural_scroll = false,
        follow_mouse = 1,
        follow_mouse_threshold = 0.0,
        focus_on_close = 0,
        mouse_refocus = true,
        float_switch_override_focus = 1,
        special_fallthrough = false,
        off_window_axis_events = 1,
        emulate_discrete_scroll = 1,
        touchpad = {
            disable_while_typing = true,
            natural_scroll = false,
            scroll_factor = 1.0,
            middle_button_emulation = false,
            clickfinger_behavior = false,
            tap_to_click = true,
            drag_lock = false,
            tap_and_drag = true,
            flip_x = false,
            flip_y = false,
            drag_3fg = 0,
        },
        touchdevice = {
            enabled = true,
            transform = 0,
        },
        virtualkeyboard = {
            share_states = false,
            release_pressed_on_close = false,
        },
        tablet = {
            transform = 0,
            region_position = "0 0",
            absolute_region_position = false,
            region_size = "0 0",
            relative_input = false,
            left_handed = false,
            active_area_size = "0 0",
            active_area_position = "0 0",
        },
    },

    gestures = {
        workspace_swipe_distance = 300,
        workspace_swipe_touch = false,
        workspace_swipe_invert = true,
        workspace_swipe_touch_invert = false,
        workspace_swipe_min_speed_to_force = 30,
        workspace_swipe_cancel_ratio = 0.5,
        workspace_swipe_create_new = true,
        workspace_swipe_direction_lock = true,
        workspace_swipe_direction_lock_threshold = 10,
        workspace_swipe_forever = false,
        workspace_swipe_use_r = false,
        close_max_timeout = 100,
    },

    group = {
        auto_group = true,
        insert_after_current = true,
        focus_removed_window = true,
        drag_into_group = 1,
        merge_groups_on_drag = true,
        merge_groups_on_groupbar = true,
        merge_floated_into_tiled_on_groupbar = false,
        group_on_movetoworkspace = false,
        col = {
            border_active = "0xFF89B4FA",
            border_inactive = "0xFF28283d",
            border_locked_active = "0xFFF38BA8",
            border_locked_inactive = "0xFF28283d",
        },
        groupbar = {
            enabled = true,
            font_family = "RobotoMono Nerd Font",
            font_size = 12,
            font_weight_active = "bold",
            font_weight_inactive = "normal",
            gradients = true,
            height = 22,
            indicator_gap = 0,
            indicator_height = 0,
            stacked = false,
            priority = 3,
            render_titles = true,
            text_offset = 0,
            scrolling = true,
            rounding = 0,
            rounding_power = 2.0,
            gradient_rounding = 10,
            gradient_rounding_power = 2.0,
            round_only_edges = true,
            gradient_round_only_edges = true,
            text_color = "0xFF1E1E2E",
            text_color_inactive = "0xFFCDD6F4",
            text_color_locked_active = "0xFF1E1E2E",
            text_color_locked_inactive = "0xFFCDD6F4",
            col = {
                active = "0xFF89B4FA",
                inactive = "0xFF28283d",
                locked_active = "0xFFF38BA8",
                locked_inactive = "0xFF28283d",
            },
            gaps_in = 5,
            gaps_out = 5,
            keep_upper_gap = false,
            blur = false,
        },
    },

    binds = {
        pass_mouse_when_bound = false,
        scroll_event_delay = 300,
        workspace_back_and_forth = false,
        hide_special_on_workspace_change = false,
        allow_workspace_cycles = false,
        workspace_center_on = 0,
        focus_preferred_method = 0,
        ignore_group_lock = false,
        movefocus_cycles_fullscreen = true,
        movefocus_cycles_groupfirst = false,
        disable_keybind_grabbing = false,
        window_direction_monitor_fallback = true,
        allow_pin_fullscreen = false,
        drag_threshold = 0,
    },

    cursor = {
        invisible = false,
        sync_gsettings_theme = true,
        no_hardware_cursors = false,
        no_break_fs_vrr = false,
        min_refresh_rate = 24,
        hotspot_padding = 1,
        inactive_timeout = 0,
        no_warps = false,
        persistent_warps = false,
        warp_on_change_workspace = false,
        warp_on_toggle_special = 0,
        zoom_factor = 1.0,
        zoom_rigid = false,
        zoom_detached_camera = true,
        enable_hyprcursor = true,
        hide_on_key_press = false,
        hide_on_touch = false,
        hide_on_tablet = true,
        use_cpu_buffer = false,
        warp_back_after_non_mouse_input = false,
        zoom_disable_aa = false,
    },

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = false,
        disable_scale_notification = false,
        col = { splash = "0xFFFFFF" },
        font_family = "RobotoMono Nerd Font",
        splash_font_family = "RobotoMono Nerd Font",
        force_default_wallpaper = 0,
        vrr = 0,
        mouse_move_enables_dpms = false,
        key_press_enables_dpms = false,
        name_vk_after_proc = true,
        always_follow_on_dnd = true,
        layers_hog_keyboard_focus = true,
        animate_manual_resizes = false,
        animate_mouse_windowdragging = false,
        disable_autoreload = false,
        enable_swallow = false,
        focus_on_activate = true,
        mouse_move_focuses_monitor = true,
        allow_session_lock_restore = false,
        session_lock_xray = false,
        background_color = 0x000000,
        close_special_on_empty = true,
        on_focus_under_fullscreen = 2,
        exit_window_retains_fullscreen = false,
        initial_workspace_tracking = 1,
        middle_click_paste = true,
        render_unfocused_fps = 15,
        disable_xdg_env_checks = false,
        lockdead_screen_delay = 1000,
        enable_anr_dialog = true,
        anr_missed_pings = 1,
        size_limits_tiled = false,
        disable_watchdog_warning = false,
    },

    xwayland = {
        enabled = true,
        use_nearest_neighbor = true,
        force_zero_scaling = false,
        create_abstract_socket = false,
    },

    opengl = {
        nvidia_anti_flicker = true,
    },

    render = {
        direct_scanout = false,
        expand_undersized_textures = true,
        xp_mode = false,
        ctm_animation = 2,
        cm_enabled = true,
        send_content_type = true,
        cm_auto_hdr = 1,
        new_render_scheduling = false,
        non_shader_cm = 3,
        cm_sdr_eotf = 0,
    },

    ecosystem = {
        no_update_news = false,
        no_donation_nag = false,
        enforce_permissions = false,
    },

    dwindle = {
        force_split = 0,
        preserve_split = false,
        smart_split = false,
        smart_resizing = true,
        permanent_direction_override = false,
        special_scale_factor = 0.8,
        split_width_multiplier = 1.0,
        use_active_for_splits = true,
        default_split_ratio = 1.0,
        split_bias = 0,
        precise_mouse_move = false,
    },

    master = {
        allow_small_split = false,
        special_scale_factor = 0.8,
        mfact = 0.55,
        new_status = "slave",
        new_on_top = false,
        new_on_active = "none",
        orientation = "left",
        slave_count_for_center_master = 2,
        center_master_fallback = "left",
        smart_resizing = true,
        drop_at_cursor = true,
        always_keep_position = false,
    },
})

--------------------
---- ANIMATIONS ----
--------------------
hl.animation({ leaf = "windowsIn", enabled = true, speed = 5, bezier = "default", style = "popin 0%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 5, bezier = "default", style = "popin" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 5, bezier = "default", style = "slide" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "default", style = "slide" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 4, bezier = "default", style = "slide" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 8, bezier = "default" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 8, bezier = "default" })
hl.animation({ leaf = "fadeSwitch", enabled = true, speed = 8, bezier = "default" })
hl.animation({ leaf = "fadeShadow", enabled = true, speed = 8, bezier = "default" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 8, bezier = "default" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 8, bezier = "default" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 8, bezier = "default" })
hl.animation({ leaf = "fadePopupsIn", enabled = true, speed = 5, bezier = "default" })
hl.animation({ leaf = "fadePopupsOut", enabled = true, speed = 5, bezier = "default" })
hl.animation({ leaf = "fadeDpms", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 20, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 20, bezier = "default", style = "once" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 5, bezier = "default", style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 5, bezier = "default", style = "slide" })
hl.animation({ leaf = "specialWorkspaceIn", enabled = true, speed = 5, bezier = "default", style = "fade" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 5, bezier = "default", style = "fade" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "monitorAdded", enabled = true, speed = 10, bezier = "default" })

------------------
---- GESTURES ----
------------------
-- 3-finger touchpad gestures for window navigation
hl.gesture({
    fingers = 3,
    direction = "left",
    action = function()
        hl.exec_cmd("hyprctl dispatch movefocus l")
    end,
})
hl.gesture({
    fingers = 3,
    direction = "right",
    action = function()
        hl.exec_cmd("hyprctl dispatch movefocus r")
    end,
})
hl.gesture({
    fingers = 3,
    direction = "up",
    action = function()
        hl.exec_cmd("hyprctl dispatch movefocus u")
    end,
})
hl.gesture({
    fingers = 3,
    direction = "down",
    action = function()
        hl.exec_cmd("hyprctl dispatch movefocus d")
    end,
})

-- 3-finger window actions & modifiers
hl.gesture({ fingers = 3, direction = "pinch", action = "fullscreen" })
hl.gesture({ fingers = 3, direction = "swipe", mods = "SUPER", action = "resize" })
hl.gesture({ fingers = 3, direction = "swipe", mods = "ALT", action = "move" })

-- 4-finger workspace swipe
hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })

----------------------
---- WINDOW RULES ----
----------------------
hl.window_rule({ match = { class = "foot-float|alacritty-float|kitty-float" }, float = true })
hl.window_rule({ match = { class = "yad|nm-connection-editor|org.pulseaudio.pavucontrol" }, float = true })
hl.window_rule({ match = { class = "xfce-polkit|kvantummanager|qt5ct|qt6ct" }, float = true })
hl.window_rule({ match = { class = "feh|viewnior|gimp|MPlayer" }, float = true })
hl.window_rule({ match = { class = "VirtualBox Manager|qemu|Qemu-system-x86_64" }, float = true })
hl.window_rule({ match = { title = "File Operation Progress" }, float = true })
hl.window_rule({ match = { title = "Confirm to replace files" }, float = true })
hl.window_rule({ match = { class = "thunar", title = "(Rename .*)" }, float = true })
hl.window_rule({ match = { class = "Yad|yad" }, float = true, size = "60% 64%" })
hl.window_rule({ match = { class = "io.calamares.calamares" }, float = true, center = true })
hl.window_rule({ match = { title = "^(Archcraft Installer)(.*)$" }, float = true })
hl.window_rule({ match = { class = "viewnior" }, size = "60% 64%", center = true })
hl.window_rule({ match = { class = "Alacritty|alacritty|alacritty-float" }, size = "785 450" })
hl.window_rule({ match = { class = "foot-full|alacritty-full|kitty-full" }, animation = "slide down" })
hl.window_rule({ match = { class = "wlogout" }, animation = "slide up" })
hl.window_rule({ match = { class = "firefox" }, workspace = 2 })
hl.window_rule({ match = { class = "firefox", title = "(Picture-in-Picture)" }, float = true, size = "50% 50%", move = "100%-w-40 100%-w-40" })

hl.layer_rule({ match = { namespace = "wallpaper" }, blur = true })
hl.layer_rule({ match = { namespace = "waybar" }, blur = true })
hl.layer_rule({ match = { namespace = "rofi" }, animation = "slide" })
hl.layer_rule({ match = { namespace = "notifications" }, animation = "slide" })

----------------------
---- KEYBINDINGS -----
----------------------
local function dsp(cmd)
    return hl.dsp.exec_raw("dispatch " .. cmd)
end

-- Terminal
hl.bind("SUPER + Return", hl.dsp.exec_cmd(alacritty))
hl.bind("SUPER + SHIFT + Return", hl.dsp.exec_cmd(alacritty .. " -f"))
hl.bind("SUPER + ALT + Return", hl.dsp.exec_cmd(alacritty .. " -F"))

-- Apps
hl.bind("SUPER + SHIFT + F", hl.dsp.exec_cmd(files))
hl.bind("SUPER + SHIFT + E", hl.dsp.exec_cmd(editor))
hl.bind("SUPER + SHIFT + W", hl.dsp.exec_cmd(browser))

-- Rofi
hl.bind("SUPER + SUPER_L", hl.dsp.exec_cmd(rofi_launcher), { release = true })
hl.bind("SUPER + D", hl.dsp.exec_cmd(rofi_launcher))
hl.bind("ALT + F1", hl.dsp.exec_cmd(rofi_launcher))
hl.bind("ALT + F2", hl.dsp.exec_cmd(rofi_runner))
hl.bind("SUPER + R", hl.dsp.exec_cmd(rofi_asroot))
hl.bind("SUPER + B", hl.dsp.exec_cmd(rofi_bluetooth))
hl.bind("SUPER + M", hl.dsp.exec_cmd(rofi_spotify))
hl.bind("SUPER + N", hl.dsp.exec_cmd(rofi_network))
hl.bind("SUPER + X", hl.dsp.exec_cmd(rofi_powermenu))
hl.bind("SUPER + S", hl.dsp.exec_cmd(rofi_screenshot))

-- Misc
hl.bind("SUPER + P", hl.dsp.exec_cmd(colorpicker))
hl.bind("CTRL + ALT + L", hl.dsp.exec_cmd("hyprlock --config " .. hyprDir .. "/hyprlock.conf"))

-- Function keys
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(backlight .. " --inc"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(backlight .. " --dec"), { locked = true, repeating = true })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(volume .. " --inc"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(volume .. " --dec"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(volume .. " --toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd(volume .. " --toggle-mic"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("mpc next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("mpc prev"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("mpc toggle"), { locked = true })
hl.bind("XF86AudioStop", hl.dsp.exec_cmd("mpc stop"), { locked = true })

-- Screenshots
hl.bind("Print", hl.dsp.exec_cmd(screenshot .. " --now"), { locked = true })
hl.bind("ALT + Print", hl.dsp.exec_cmd(screenshot .. " --in5"), { locked = true })
hl.bind("SHIFT + Print", hl.dsp.exec_cmd(screenshot .. " --in10"), { locked = true })
hl.bind("CTRL + Print", hl.dsp.exec_cmd(screenshot .. " --win"))
hl.bind("SUPER + Print", hl.dsp.exec_cmd(screenshot .. " --area"))

-- Window Management
hl.bind("SUPER + C", dsp("killactive"))
hl.bind("SUPER + Q", dsp("forcekillactive"))
hl.bind("SUPER + Space", dsp("togglefloating"))
hl.bind("SUPER + F", dsp("fullscreen 0"))
hl.bind("SUPER + SHIFT + P", dsp("pin"))
hl.bind("SUPER + Tab", dsp("cyclenext"))
hl.bind("ALT + Tab", dsp("swapnext"))
hl.bind("SUPER + SHIFT + Tab", dsp("focuscurrentorlast"))
hl.bind("CTRL + ALT + Delete", dsp("exit"))

-- Focus
hl.bind("SUPER + left", dsp("movefocus l"))
hl.bind("SUPER + right", dsp("movefocus r"))
hl.bind("SUPER + up", dsp("movefocus u"))
hl.bind("SUPER + down", dsp("movefocus d"))

-- Move Active
hl.bind("SUPER + SHIFT + left", dsp("movewindow l"))
hl.bind("SUPER + SHIFT + right", dsp("movewindow r"))
hl.bind("SUPER + SHIFT + up", dsp("movewindow u"))
hl.bind("SUPER + SHIFT + down", dsp("movewindow d"))

-- Resize Active
hl.bind("SUPER + CTRL + left", dsp("resizeactive -20 0"), { repeating = true })
hl.bind("SUPER + CTRL + right", dsp("resizeactive 20 0"), { repeating = true })
hl.bind("SUPER + CTRL + up", dsp("resizeactive 0 -20"), { repeating = true })
hl.bind("SUPER + CTRL + down", dsp("resizeactive 0 20"), { repeating = true })

-- Move Active (Floating Only)
hl.bind("SUPER + ALT + left", dsp("moveactive -20 0"), { repeating = true })
hl.bind("SUPER + ALT + right", dsp("moveactive 20 0"), { repeating = true })
hl.bind("SUPER + ALT + up", dsp("moveactive 0 -20"), { repeating = true })
hl.bind("SUPER + ALT + down", dsp("moveactive 0 20"), { repeating = true })

-- Workspaces 1..9
for i = 1, 9 do
    hl.bind("SUPER + " .. i, dsp("workspace " .. i))
    hl.bind("SUPER + SHIFT + " .. i, dsp("movetoworkspace " .. i))
end

-- Special workspace
hl.bind("SUPER + 0", dsp("togglespecialworkspace"))
hl.bind("SUPER + SHIFT + 0", dsp("movetoworkspacesilent special"))

-- Seamless Workspace Switching
hl.bind("CTRL + ALT + left", dsp("workspace e-1"))
hl.bind("CTRL + ALT + right", dsp("workspace e+1"))
hl.bind("CTRL + ALT + SHIFT + left", dsp("movetoworkspace e-1"))
hl.bind("CTRL + ALT + SHIFT + right", dsp("movetoworkspace e+1"))

-- Groups
hl.bind("SUPER + G", dsp("togglegroup"))
hl.bind("SUPER + H", dsp("changegroupactive b"))
hl.bind("SUPER + L", dsp("changegroupactive f"))
hl.bind("SUPER + SHIFT + L", dsp("lockactivegroup toggle"))
hl.bind("SUPER + ALT + M", dsp("moveoutofgroup"))
hl.bind("SUPER + comma", dsp("movegroupwindow"))
hl.bind("SUPER + period", dsp("movegroupwindow b"))

-- Submaps
hl.bind("SUPER + SHIFT + R", dsp("submap resize"))
hl.bind("SUPER + SHIFT + M", dsp("submap move"))

-- Mouse
hl.bind("SUPER + mouse_down", dsp("workspace e-1"))
hl.bind("SUPER + mouse_up", dsp("workspace e+1"))
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind("SUPER + Control_R", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + ALT_R", hl.dsp.window.resize(), { mouse = true })
