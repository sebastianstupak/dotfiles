local wezterm = require 'wezterm'

wezterm.on("gui-startup", function(cmd)
  local _, _, window = wezterm.mux.spawn_window(cmd or {})
  window:gui_window():toggle_fullscreen()
end)

return {
  adjust_window_size_when_changing_font_size = false,

  audible_bell = 'Disabled',
  window_background_image_hsb = {
	brightness = 0.015,
  },

  color_scheme = 'Catppuccin Mocha',

  disable_default_key_bindings = true,
  exit_behavior = 'Close',
  harfbuzz_features = {"calt=0", "clig=0", "liga=0"},
  
  enable_tab_bar = false,

  font_size = 20,
  font = wezterm.font('JetBrains Mono'),
  

  force_reverse_video_cursor = true,
  hide_mouse_cursor_when_typing = true,
  hide_tab_bar_if_only_one_tab = true,
  keys = {
    { action = wezterm.action.ActivateCommandPalette, mods = 'CTRL|SHIFT', key =     'P' },
    { action = wezterm.action.CopyTo    'Clipboard' , mods = 'CTRL|SHIFT', key =     'C' },
    { action = wezterm.action.DecreaseFontSize      , mods =       'CTRL', key =     '-' },
	{ action = wezterm.action.IncreaseFontSize      , mods =       'CTRL', key =     '+' },
	{ action = wezterm.action.IncreaseFontSize      , mods =       'CTRL', key =     '=' },
    { action = wezterm.action.Nop                   , mods =        'ALT', key = 'Enter' },
    { action = wezterm.action.PasteFrom 'Clipboard' , mods = 'CTRL|SHIFT', key =     'V' },
    { action = wezterm.action.ResetFontSize         , mods =       'CTRL', key =     '0' },
    { action = wezterm.action.ToggleFullScreen      ,                      key =   'F11' },
  },
  scrollback_lines = 10000,
  show_update_window = true,
  use_dead_keys = false,
  unicode_version = 15,
  macos_window_background_blur = 100,
  window_close_confirmation = 'NeverPrompt',
  window_padding = {
    left = '0.3cell',
    right = '0.3cell',
    top = '0.6cell',
    bottom = 0,
  }
}
