-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- Disable default volume media keys
hl.unbind("XF86AudioLowerVolume")
hl.unbind("XF86AudioRaiseVolume")
hl.unbind("XF86AudioMute")

-- Disable default keyboard brightness keys
hl.unbind("XF86KbdBrightnessDown")
hl.unbind("XF86KbdBrightnessUp")

-- Disable default display brightness keys
hl.unbind("XF86MonBrightnessDown")
hl.unbind("XF86MonBrightnessUp")

-- New volume bindings using F-keys
o.bind("F11", "Volume Down", "omarchy audio output volume lower")
o.bind("F12", "Volume Up", "omarchy audio output volume raise")
o.bind("F10", "Mute", "omarchy audio output volume mute-toggle")

-- New keyboard brightness bindings using F-keys
o.bind("F5", "Keyboard Brightness Down", "omarchy brightness keyboard down")
o.bind("F6", "Keyboard Brightness Up", "omarchy brightness keyboard up")

-- New display brightness bindings using F-keys
o.bind("F1", "Display Brightness Down", "omarchy brightness display 5%-")
o.bind("F2", "Display Brightness Up", "omarchy brightness display +5%")

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")
