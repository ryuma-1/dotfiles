local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- ========================================
-- 基本設定
-- ========================================

config.font = wezterm.font 'JetBrains Mono'
config.font_size = 14

config.colors = {
  background = '#111111',

  cursor_bg = '#ffffff',
  cursor_fg = '#111111',

  ansi = {
    '#000000',
    '#CC0000',
    '#00A600',
    '#A6A600',
    '#0000B2',
    '#B200B2',
    '#00A6B2',
    '#BFBFBF',
  },

  brights = {
    '#666666',
    '#E50000',
    '#00D900',
    '#E5E500',
    '#0000FF',
    '#E500E5',
    '#00E5E5',
    '#FFFFFF',
  },
}

config.colors.split = '#444444'

-- ========================================
-- Leader
-- Ctrl+Space
-- ========================================

config.leader = {
  key = 'Space',
  mods = 'CTRL',
  timeout_milliseconds = 1000,
}

-- ========================================
-- キーバインド
-- ========================================

config.keys = {

  -- ----------------------------------------
  -- ペイン移動
  -- Ctrl+Space + h/j/k/l
  -- ----------------------------------------

  {
    key = 'h',
    mods = 'LEADER',
    action = wezterm.action.ActivatePaneDirection 'Left',
  },

  {
    key = 'j',
    mods = 'LEADER',
    action = wezterm.action.ActivatePaneDirection 'Down',
  },

  {
    key = 'k',
    mods = 'LEADER',
    action = wezterm.action.ActivatePaneDirection 'Up',
  },

  {
    key = 'l',
    mods = 'LEADER',
    action = wezterm.action.ActivatePaneDirection 'Right',
  },

  -- ----------------------------------------
  -- タブ移動
  -- Ctrl+Space + Shift+h/l
  -- ----------------------------------------

  {
    key = 'H',
    mods = 'LEADER',
    action = wezterm.action.ActivateTabRelative(-1),
  },

  {
    key = 'L',
    mods = 'LEADER',
    action = wezterm.action.ActivateTabRelative(1),
  },

  -- ----------------------------------------
  -- 上下分割
  -- Ctrl+Space + s
  -- ----------------------------------------

  {
    key = 's',
    mods = 'LEADER',
    action = wezterm.action.SplitVertical {
      domain = 'CurrentPaneDomain',
    },
  },

  -- ----------------------------------------
  -- 左右分割
  -- Ctrl+Space + v
  -- ----------------------------------------

  {
    key = 'v',
    mods = 'LEADER',
    action = wezterm.action.SplitHorizontal {
      domain = 'CurrentPaneDomain',
    },
  },

  -- ----------------------------------------
  -- ペインを閉じる
  -- Ctrl+Space + w
  -- ----------------------------------------

  {
    key = 'w',
    mods = 'LEADER',
    action = wezterm.action.CloseCurrentPane {
      confirm = true,
    },
  },

  -- ----------------------------------------
  -- タブを閉じる
  -- Ctrl+Space + Shift+w
  -- ----------------------------------------

  {
    key = 'W',
    mods = 'LEADER',
    action = wezterm.action.CloseCurrentTab {
      confirm = true,
    },
  },

  -- ----------------------------------------
  -- 新しいタブ
  -- Ctrl+Space + t
  -- ----------------------------------------

  {
    key = 't',
    mods = 'LEADER',
    action = wezterm.action.SpawnTab 'CurrentPaneDomain',
  },

  -- ========================================
  -- Alt + 0〜9
  -- タブを直接選択
  -- ========================================

  {
    key = '0',
    mods = 'ALT',
    action = wezterm.action.ActivateLastTab,
  },

  {
    key = '1',
    mods = 'ALT',
    action = wezterm.action.ActivateTab(0),
  },

  {
    key = '2',
    mods = 'ALT',
    action = wezterm.action.ActivateTab(1),
  },

  {
    key = '3',
    mods = 'ALT',
    action = wezterm.action.ActivateTab(2),
  },

  {
    key = '4',
    mods = 'ALT',
    action = wezterm.action.ActivateTab(3),
  },

  {
    key = '5',
    mods = 'ALT',
    action = wezterm.action.ActivateTab(4),
  },

  {
    key = '6',
    mods = 'ALT',
    action = wezterm.action.ActivateTab(5),
  },

  {
    key = '7',
    mods = 'ALT',
    action = wezterm.action.ActivateTab(6),
  },

  {
    key = '8',
    mods = 'ALT',
    action = wezterm.action.ActivateTab(7),
  },

  {
    key = '9',
    mods = 'ALT',
    action = wezterm.action.ActivateTab(8),
  },
}

return config
