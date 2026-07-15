-- WSL 判定
local s_obj = vim.system({'sh', '-c', 'uname -r | grep -q microsoft'})
local res = s_obj:wait(1000)
IsWSL = (res.code == 0)

-- エンコーディング設定
vim.opt.encoding = 'utf8'
vim.scriptencoding = 'utf8'

-- 共通オプション
vim.opt.termguicolors = true
vim.opt.signcolumn = 'yes:1'
vim.opt.foldenable = false
vim.opt.laststatus = 3
vim.opt.directory = vim.fn.stdpath('data') .. '/swp'
vim.opt.hidden = true
vim.opt.showmatch = true
vim.opt.clipboard = 'unnamedplus' -- 既存の "unnamedplus" と一致
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
vim.opt.mouse = 'a'
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

-- Unityなどの外部ファイル変更を自動反映する設定
vim.opt.autoread = true
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  pattern = "*",
  command = "if mode() != 'c' | checktime | endif",
})

-- Tex Flavor
vim.g.tex_flavor = 'latex'

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
                    not (ft:match('commit') and ft:match('rebase'))
                    and last_known_line > 1
                    and last_known_line <= vim.api.nvim_buf_line_count(opts.buf)
                then
                    vim.api.nvim_feedkeys([[g`"]], 'nx', false)
                end
            end,
        })
    end,
})
