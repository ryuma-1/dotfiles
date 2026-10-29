local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- ローカル設定 (~/.config/wezterm/local.lua)．config へのマージは末尾で行う
local ok, local_config = pcall(require, 'local')
if not ok then
  local_config = {}
end

-- config のフィールドではないので取り出しておく (マージすると未知のキーでエラーになる)
local leader_lock_mods = local_config.leader_lock_mods or 'CTRL'
local_config.leader_lock_mods = nil

-- ========================================
-- 基本設定
-- ========================================

config.font = wezterm.font 'HackGenConsoleNF'

config.colors = {
  background = '#000000',
}

config.color_scheme = 'GitHub Dark'

-- ========================================
-- キーバインド
-- ========================================

-- Leader f でフォーカス中のペイン (tab_id -> pane_id)．フォーカス中は Leader hjkl でペインを移動しない
local focused = {}

local function activate_pane(dir)
  return wezterm.action_callback(function(window, pane)
    if focused[pane:tab():tab_id()] ~= pane:pane_id() then
      window:perform_action(wezterm.action.ActivatePaneDirection(dir), pane)
    end
  end)
end

config.keys = {

  -- ----------------------------------------
  -- ペイン移動
  -- Ctrl+Space + h/j/k/l
  -- ----------------------------------------

  {
    key = 'h',
    mods = 'LEADER',
    action = activate_pane 'Left',
  },

  {
    key = 'j',
    mods = 'LEADER',
    action = activate_pane 'Down',
  },

  {
    key = 'k',
    mods = 'LEADER',
    action = activate_pane 'Up',
  },

  {
    key = 'l',
    mods = 'LEADER',
    action = activate_pane 'Right',
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
  -- タブ移動モード (h/l でタブの位置を入れ替え，Enter/Esc で終了)
  -- Ctrl+Space + m
  -- ----------------------------------------

  {
    key = 'm',
    mods = 'LEADER',
    action = wezterm.action.ActivateKeyTable { name = 'move_tab', one_shot = false },
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
  -- アクティブペインを 9 割の大きさに広げる (もう一度押すと半分に戻す．広げている間は hjkl で移動しない)
  -- Ctrl+Space + f
  -- ----------------------------------------

  {
    key = 'f',
    mods = 'LEADER',
    action = wezterm.action_callback(function(window, pane)
      local tab = pane:tab()
      local restore = focused[tab:tab_id()] == pane:pane_id()
      focused[tab:tab_id()] = not restore and pane:pane_id() or nil
      local size = tab:get_size()
      for _, p in ipairs(tab:panes_with_info()) do
        if p.is_active then
          -- 左右に並んでいれば幅，上下に並んでいれば高さを，それぞれ独立に変える
          for _, axis in ipairs {
            { total = size.cols, cur = p.width, first = p.left == 0, back = 'Left', fwd = 'Right' },
            { total = size.rows, cur = p.height, first = p.top == 0, back = 'Up', fwd = 'Down' },
          } do
            if axis.cur < axis.total then
              local target = restore and math.floor((axis.total - 1) / 2) or math.floor(axis.total * 0.9)
              local delta = target - axis.cur
              -- AdjustPaneSize は境界線を指定方向へ動かすので，左/上のペインを広げるなら Right/Down
              local dir = (axis.first == (delta > 0)) and axis.fwd or axis.back
              window:perform_action(wezterm.action.AdjustPaneSize { dir, math.abs(delta) }, pane)
            end
          end
        end
      end
    end),
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
  -- スクロールバックを nvim で開く
  -- Ctrl+Space + o
  -- ----------------------------------------

  {
    key = 'o',
    mods = 'LEADER',
    action = wezterm.action_callback(function(window, pane)
      local name = os.tmpname()
      local f = io.open(name, 'w+')
      f:write(pane:get_lines_as_text(pane:get_dimensions().scrollback_rows))
      f:close()
      -- 読み込んだ直後に nvim 側で一時ファイルを消す (バッファは残る)
      window:perform_action(
        wezterm.action.SpawnCommandInNewTab { args = { 'nvim', '+', '-c', 'call delete(@%)', name } },
        pane
      )
    end),
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
-- ========================================
-- Leader ロック
-- Leader → Leader で Enter / Escape を押すまで Leader 状態を維持する
-- (LEADER 付きのバインドを修飾キーなしでコピーする)
-- ========================================

local leader_lock = {
  { key = 'Enter', mods = 'NONE', action = wezterm.action.PopKeyTable },
  { key = 'Escape', mods = 'NONE', action = wezterm.action.PopKeyTable },
}
for _, k in ipairs(config.keys) do
  if k.mods == 'LEADER' then
    table.insert(leader_lock, { key = k.key, mods = 'NONE', action = k.action })
  end
end
table.insert(config.keys, {
  key = 'Space',
  mods = 'LEADER|' .. leader_lock_mods,
  action = wezterm.action.ActivateKeyTable { name = 'leader_lock', one_shot = false },
})

local move_tab = {
  { key = 'h', mods = 'NONE', action = wezterm.action.MoveTabRelative(-1) },
  { key = 'l', mods = 'NONE', action = wezterm.action.MoveTabRelative(1) },
  { key = 'Enter', mods = 'NONE', action = wezterm.action.PopKeyTable },
  { key = 'Escape', mods = 'NONE', action = wezterm.action.PopKeyTable },
}

config.key_tables = { copy_mode = copy_mode, leader_lock = leader_lock, move_tab = move_tab }

-- ========================================
-- Leader 入力中はタブバー右端に色付きで表示し，押せるキーを並べる
-- (config.keys の LEADER キーを変えたらここも更新する)
-- ========================================

local leader_hint = ' hjkl:pane  H/L:tab  m:move tab  s/v:split  f:focus  w/W:close  x:copy  t:tab  n:win  o:nvim  e:quit '

wezterm.on('update-status', function(window, _)
  if window:active_key_table() == 'move_tab' then
    window:set_right_status(wezterm.format {
      { Foreground = { Color = '#c9d1d9' } },
      { Text = ' h/l:move  Enter/Esc:done ' },
      { Background = { Color = '#d2a8ff' } },
      { Foreground = { Color = '#000000' } },
      { Attribute = { Intensity = 'Bold' } },
      { Text = ' MOVE TAB ' },
    })
    return
  end
  if window:active_key_table() == 'copy_mode' then
    window:set_right_status(wezterm.format {
      { Foreground = { Color = '#c9d1d9' } },
      { Text = ' v/V:select  y:copy  u/d:half page  q/Esc:quit ' },
      { Background = { Color = '#7ee787' } },
      { Foreground = { Color = '#000000' } },
      { Attribute = { Intensity = 'Bold' } },
      { Text = ' COPY ' },
    })
    return
  end
  local locked = window:active_key_table() == 'leader_lock'
  if not (window:leader_is_active() or locked) then
    window:set_right_status('')
    return
  end
  window:set_right_status(wezterm.format {
    { Foreground = { Color = '#c9d1d9' } },
    { Text = leader_hint .. (locked and ' Enter/Esc:unlock ' or ' ' .. leader_lock_mods .. '+Space:lock ') },
    { Background = { Color = locked and '#ffa657' or '#79c0ff' } },
    { Foreground = { Color = '#000000' } },
    { Attribute = { Intensity = 'Bold' } },
    { Text = locked and ' LEADER LOCK ' or ' LEADER ' },
  })
end)


-- ----------------------------------------
-- ローカル設定の読み込み
-- ----------------------------------------

for key, value in pairs(local_config) do
  config[key] = value
end

return config
