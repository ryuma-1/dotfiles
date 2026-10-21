local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- ========================================
-- 基本設定
-- ========================================

config.font = wezterm.font 'JetBrains Mono'

config.colors = {
  background = '#000000',
}

config.color_scheme = 'GitHub Dark'

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
  -- コピーモード (出力上を vim キーで移動・選択)
  -- Ctrl+Space + x
  -- ----------------------------------------

  {
    key = 'x',
    mods = 'LEADER',
    action = wezterm.action.ActivateCopyMode,
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

  -- ----------------------------------------
  -- 新しいウィンドウ
  -- Ctrl+Space + n
  -- ----------------------------------------

  {
    key = 'n',
    mods = 'LEADER',
    action = wezterm.action.SpawnWindow,
  },

  -- ----------------------------------------
  -- WezTerm を終了
  -- Ctrl+Space + e
  -- ----------------------------------------

  {
    key = 'e',
    mods = 'LEADER',
    action = wezterm.action.QuitApplication,
  },

  -- ----------------------------------------
  -- コピー
  -- Ctrl+Shift+c
  -- 端末上の選択があればそれをコピーし，無ければ CSI u 形式の Ctrl+Shift+c を送る
  -- (zsh-vi-mode のビジュアル選択を zsh 側でクリップボードへコピーするため)
  -- ----------------------------------------

  {
    key = 'C',
    mods = 'CTRL|SHIFT',
    action = wezterm.action_callback(function(window, pane)
      if window:get_selection_text_for_pane(pane) ~= '' then
        window:perform_action(wezterm.action.CopyTo 'Clipboard', pane)
      else
        window:perform_action(wezterm.action.SendString '\x1b[99;6u', pane)
      end
    end),
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

-- ========================================
-- コピーモード
-- u/d で半ページ上下 (1 行ずつ刻んで滑らかに見せる)
-- ========================================

local function smooth_half_page(direction)
  return wezterm.action_callback(function(window, pane)
    local rows = pane:get_dimensions().viewport_rows
    -- 1 行分の移動量 (1.5 にしているのは浮動小数の切り捨てで 0 行になるのを避けるため)
    local step = direction * 1.5 / rows
    for i = 1, math.floor(rows / 2) do
      wezterm.time.call_after(i * 0.008, function()
        window:perform_action(wezterm.action.CopyMode { MoveByPage = step }, pane)
      end)
    end
  end)
end

local copy_mode = wezterm.gui.default_key_tables().copy_mode
table.insert(copy_mode, { key = 'u', mods = 'NONE', action = smooth_half_page(-1) })
table.insert(copy_mode, { key = 'd', mods = 'NONE', action = smooth_half_page(1) })
config.key_tables = { copy_mode = copy_mode }


-- ----------------------------------------
-- ローカル設定の読み込み
-- ----------------------------------------

local ok, local_config = pcall(require, 'local')

if ok then
  for key, value in pairs(local_config) do
    config[key] = value
  end
end

return config
