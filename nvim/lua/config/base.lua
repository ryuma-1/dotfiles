-- エンコーディング設定
vim.opt.encoding = 'utf8'
vim.scriptencoding = 'utf8'

-- 共通オプション
vim.opt.termguicolors = true
vim.opt.signcolumn = 'yes:1'
-- nvim-ufo は折りたたみ有効が前提．foldlevel を高くしてファイルを開いた直後は全展開のままにする
vim.opt.foldenable = true
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.laststatus = 3
vim.opt.directory = vim.fn.stdpath('data') .. '/swp'
vim.opt.hidden = true
vim.opt.showmatch = true
vim.opt.fileencoding = 'utf-8'
vim.opt.fileencodings = 'ucs-boms,utf-8,euc-jp,cp932'
vim.opt.fileformats = 'unix,dos,mac'
vim.opt.ambiwidth = 'single'
vim.opt.history = 5000
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.list = true
vim.opt.listchars = { tab = '<->' }
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.backspace = 'indent,eol,start'
vim.opt.pumblend = 30
-- <leader>k でマウスの on/off を切り替え，次回起動時も状態を引き継ぐ
local mouse_file = vim.fn.stdpath('state') .. '/mouse'
local saved_mouse = vim.uv.fs_stat(mouse_file) and vim.fn.readfile(mouse_file) or {}
vim.opt.mouse = saved_mouse[1] == 'off' and '' or 'a'
vim.keymap.set('n', '<leader>k', function()
    local state = vim.o.mouse == '' and 'on' or 'off'
    vim.o.mouse = state == 'on' and 'a' or ''
    vim.fn.writefile({ state }, mouse_file)
    vim.notify('Mouse ' .. state)
end, { silent = true, desc = 'Toggle mouse' })
-- bufferline の hover イベントはマウス移動の通知が必要なため有効化する
vim.opt.mousemoveevent = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.updatetime = 300
vim.opt.virtualedit:append("block")
vim.opt.wrap = true
vim.opt.breakindent = true
vim.opt.showbreak = "↳ "
vim.opt.scrolloff = 5

vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
        vim.api.nvim_set_hl(0, "NonText", {
            fg = "#696969",
        })
    end,
})

-- Unityなどの外部ファイル変更を自動反映する設定
vim.opt.autoread = true
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  pattern = "*",
  command = "if mode() != 'c' | checktime | endif",
})
-- 操作がなくても外部変更(Claude Code等)を拾うため、1秒ごとに checktime する
vim.uv.new_timer():start(1000, 1000, vim.schedule_wrap(function()
  if vim.fn.mode() ~= "c" and vim.fn.getcmdwintype() == "" then
    vim.cmd("checktime")
  end
end))

-- Tex Flavor
vim.g.tex_flavor = 'latex'

-- 日本語入力モード: <leader>j で有効化すると，インサートで IME ON / それ以外で OFF にする
if vim.fn.executable('ibus') == 1 then
    local ime_on, ime_off = 'meltype', 'xkb:us::eng'
    local desired, switching
    -- 切替は非同期なので，<CR> の i<CR><ESC> のような連続切替で順序が前後しないよう直列に流す
    local function switch_ime(engine)
        desired = engine
        if switching then return end
        switching = true
        vim.system({ 'ibus', 'engine', engine }, {}, vim.schedule_wrap(function()
            switching = false
            if desired ~= engine then switch_ime(desired) end
        end))
    end

    local group = vim.api.nvim_create_augroup('JapaneseInputMode', { clear = true })
    local enabled = false
    vim.keymap.set('n', '<leader>j', function()
        enabled = not enabled
        vim.api.nvim_clear_autocmds({ group = group })
        if enabled then
            vim.api.nvim_create_autocmd('InsertEnter', { group = group, callback = function() switch_ime(ime_on) end })
            vim.api.nvim_create_autocmd('InsertLeave', { group = group, callback = function() switch_ime(ime_off) end })
            switch_ime(ime_off)
        end
        vim.notify('Japanese input mode ' .. (enabled and 'on' or 'off'))
    end, { silent = true, desc = 'Toggle Japanese input mode' })
end

-- 自作コマンド: カーソル位置復元
vim.api.nvim_create_autocmd('BufRead', {
    callback = function(opts)
        vim.api.nvim_create_autocmd('BufWinEnter', {
            once = true,
            buffer = opts.buf,
            callback = function()
                local ft = vim.bo[opts.buf].filetype
                local last_known_line = vim.api.nvim_buf_get_mark(opts.buf, '"')[1]
                if
                    not (ft:match('commit') or ft:match('rebase'))
                    and last_known_line > 1
                    and last_known_line <= vim.api.nvim_buf_line_count(opts.buf)
                then
                    vim.api.nvim_feedkeys([[g`"]], 'nx', false)
                end
            end,
        })
    end,
})
