-- Hyprland config (Lua). Converted from hyprland.conf.
-- See https://wiki.hypr.land/Configuring/Start/

-- nvidia bits are handled by profile.d:
--   LIBVA_DRIVER_NAME=nvidia, XDG_SESSION_TYPE=wayland, GBM_BACKEND=nvidia-drm,
--   __GLX_VENDOR_LIBRARY_NAME=nvidia, AQ_DRM_DEVICES=/dev/dri/card1:/dev/dri/card0

hl.config({
	debug = {
		disable_logs = false,
	},
})

-- Dark mode for GTK4 apps
hl.on("hyprland.start", function()
	hl.exec_cmd('gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"')
end)

-- hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")   -- for Qt apps

-------------------
---- PER-HOST -----
-------------------

local hostname = os.getenv("HOSTNAME")
if not hostname or hostname == "" then
	local f = io.open("/etc/hostname", "r")
	if f then
		hostname = f:read("l")
		f:close()
	end
end

if hostname and hostname ~= "" then
	-- require() throws for a missing module, so guard it: a host without
	-- its own monitors_/exec_ file should not kill the rest of this config.
	for _, mod in ipairs({ "monitors_" .. hostname, "exec_" .. hostname }) do
		local ok, err = pcall(require, mod)
		if not ok then
			hl.notification.create({ text = "hyprland.lua: " .. tostring(err), timeout = 8000, icon = "warning" })
		end
	end
end

---------------------
---- MY PROGRAMS ----
---------------------

local terminal = "kitty"
local fileManager = "nautilus"
local menu = "walker"

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
	hl.exec_cmd("awww-daemon")
	hl.exec_cmd("hypridle")
	hl.exec_cmd("qs -c bar -d")
	hl.exec_cmd("elephant")
	hl.exec_cmd("walker --gapplication-service")
	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
	general = {
		gaps_in = 5,
		gaps_out = 10,

		border_size = 2,

		-- Set to true to enable resizing windows by clicking and dragging on borders and gaps
		resize_on_border = false,

		col = {
			active_border = { colors = { "rgba(8f8f8f05)", "rgba(8f8f8f55)" }, angle = 45 },
			inactive_border = "rgba(8f8f8f05)",
		},

		-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before turning this on
		allow_tearing = false,

		layout = "dwindle",
	},

	decoration = {
		rounding = 3,

		-- Change transparency of focused and unfocused windows
		active_opacity = 1.0,
		inactive_opacity = 1.0,

		shadow = {
			enabled = true,
			color = "rgba(1a1a1aee)",
		},

		blur = {
			enabled = true,
			size = 10,
			passes = 1,
			vibrancy = 0.1696,
		},
	},

	animations = {
		enabled = true,
	},

	-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/ for more
	dwindle = {
		preserve_split = true, -- You probably want this
	},

	-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/ for more
	master = {
		new_status = "master",
	},

	cursor = {
		no_hardware_cursors = true,
		enable_hyprcursor = true,
	},

	misc = {
		force_default_wallpaper = -1, -- Set to 0 or 1 to disable the anime mascot wallpapers
		disable_hyprland_logo = false, -- If true disables the random hyprland logo / anime girl background. :(
		allow_session_lock_restore = true, -- Lets a new lock take over if the lock screen crashes
	},
})

hl.layer_rule({ match = { namespace = "waybar" }, blur = true })
hl.layer_rule({ match = { namespace = "kitty" }, blur = true })
hl.layer_rule({ match = { namespace = "quickshell" }, blur = true, blur_popups = true, ignore_alpha = 0 })
-- The lock screen fade-out copy: Quickshell does the fade, so no Hyprland animation
hl.layer_rule({ match = { namespace = "quickshell-lock" }, no_anim = true })

----------------------
---- ANIMATIONS ------
----------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve("myBezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
hl.curve("overshot", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.1 } } })
hl.curve("easeInOutQuint", { type = "bezier", points = { { 0.22, 1 }, { 0.36, 1 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 2, bezier = "easeInOutQuint" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, bezier = "default", style = "slidefade 80%" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 8, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 7, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "default" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 6, bezier = "default", style = "fade" })

--#############
--### INPUT ###
--#############

hl.config({
	input = {
		kb_layout = "fr",
		kb_variant = "oss",
		kb_model = "",
		kb_options = "grp:win_space_toggle",
		kb_rules = "",

		follow_mouse = 1,
		repeat_rate = 50,
		repeat_delay = 300,

		sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

		touchpad = {
			natural_scroll = true,
		},
	},
})

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Gestures/
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- Per-device config, see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/
hl.device({ name = "logitech-usb-receiver", sensitivity = -0.7 })
hl.device({ name = "logitech-mx-master-3s", sensitivity = -0.2 })

--###################
--### KEYBINDINGS ###
--###################

local mainMod = "SUPER"

hl.bind(mainMod .. " + a", hl.dsp.exec_cmd("loginctl lock-session"))

-- Cursor zoom, clamped to [1, 5]. Done in lua rather than shelling out to
-- `hyprctl keyword` + jq like the old config did.
local function zoom(mult)
	local current = hl.get_config("cursor.zoom_factor") or 1
	local target = math.max(1, math.min(5, current * mult))
	hl.config({ cursor = { zoom_factor = target } })
end

local function zoomIn()
	zoom(1.25)
end
local function zoomOut()
	zoom(0.8)
end

-- Scroll binds have a cooldown (binds.scroll_event_delay, 300ms by default);
-- wheel events arriving inside it are passed to the focused window instead of
-- the bind. Shorten it while the resize submap is active.
local scrollDelay = 300

local function enterResize()
	hl.config({ binds = { scroll_event_delay = 20 } })
	hl.dispatch(hl.dsp.submap("resize"))
end

local function leaveResize()
	hl.config({ binds = { scroll_event_delay = scrollDelay } })
	hl.dispatch(hl.dsp.submap("reset"))
end

hl.bind(mainMod .. " + Z", enterResize)
hl.define_submap("resize", function()
	hl.bind("l", hl.dsp.window.resize({ x = 20, y = 0, relative = true }), { repeating = true })
	hl.bind("h", hl.dsp.window.resize({ x = -20, y = 0, relative = true }), { repeating = true })
	hl.bind("k", hl.dsp.window.resize({ x = 0, y = -20, relative = true }), { repeating = true })
	hl.bind("j", hl.dsp.window.resize({ x = 0, y = 20, relative = true }), { repeating = true })

	hl.bind("right", hl.dsp.window.resize({ x = 20, y = 0, relative = true }), { repeating = true })
	hl.bind("left", hl.dsp.window.resize({ x = -20, y = 0, relative = true }), { repeating = true })
	hl.bind("up", hl.dsp.window.resize({ x = 0, y = -20, relative = true }), { repeating = true })
	hl.bind("down", hl.dsp.window.resize({ x = 0, y = 20, relative = true }), { repeating = true })

	hl.bind("f", hl.dsp.window.fullscreen({ mode = "fullscreen" }), { repeating = true })

	hl.bind("mouse_down", zoomIn)
	hl.bind("mouse_up", zoomOut)
	hl.bind("p", zoomIn, { repeating = true })
	hl.bind("o", zoomOut, { repeating = true })

	hl.bind("catchall", leaveResize)
end)

-- hl.gesture({ fingers = 3, direction = "pinch", action = "cursor_zoom", zoom_level = 1, mode = "live" })

hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("grimblast --freeze copy area"))
hl.bind("Print", hl.dsp.exec_cmd("grimblast --freeze copy area"))

hl.bind(mainMod .. " + right", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + left", hl.dsp.focus({ workspace = "e-1" }))

-- See https://wiki.hypr.land/Configuring/Basics/Binds/ for more
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo()) -- dwindle
hl.bind(mainMod .. " + s", hl.dsp.layout("togglesplit"))

-- Move focus
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + h", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + j", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + l", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "up" }))

hl.bind(mainMod .. " + SHIFT + H", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.focus({ workspace = "e+1" }))

-- Switch workspaces / move active window to a workspace.
-- French AZERTY: the unmodified keys, not 0-9.
-- See https://wiki.hypr.land/Configuring/Basics/Binds/#workspace-bindings-on-non-qwerty-layouts
local workspaceKeys = {
	"ampersand",
	"eacute",
	"quotedbl",
	"apostrophe",
	"parenleft",
	"minus",
	"egrave",
	"underscore",
	"ccedilla",
	"agrave",
}

for i, key in ipairs(workspaceKeys) do
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + V", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl s 10%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 10%-"), { locked = true, repeating = true })

-- Media keys
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true }) -- the stupid key is called play, but it toggles
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- Dock
hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("~/.config/hypr/scripts/lidclosed.sh"), { locked = true })
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd("~/.config/hypr/scripts/lidopened.sh"), { locked = true })

--##############################
--### WINDOWS AND WORKSPACES ###
--##############################

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Ignore maximize requests from all apps. You'll probably like this.
hl.window_rule({ match = { class = ".*" }, suppress_event = "maximize" })

-- "Smart gaps" / "No gaps when only"
hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]", gaps_out = 0, gaps_in = 0 })

hl.window_rule({
	name = "alone_no_border",
	match = { float = false, workspace = "w[tv1]" },
	border_size = 0,
	rounding = 0,
})
hl.window_rule({
	name = "fullscreen_alone",
	match = { float = false, workspace = "f[1]" },
	border_size = 0,
	rounding = 0,
})

-- Hide Wayland to X bridge
hl.window_rule({
	match = { class = "^(xwaylandvideobridge)$" },
	opacity = "0.0 override",
	no_anim = true,
	no_initial_focus = true,
	max_size = { 1, 1 },
	no_blur = true,
	no_focus = true,
})

-- Temp
hl.window_rule({ match = { class = "kitty" }, opacity = "0.95" })
