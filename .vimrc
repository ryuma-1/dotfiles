" ====================================================================
" 1. Vim標準・基本オプション設定
" ====================================================================
" 行番号をハイブリッド表示（カレント絶対行、他は相対行）
set number
set relativenumber

" システムのクリップボードとヤンク・削除を同期
set clipboard=unnamedplus,unnamed

" スクロール時に上下に5行の余白を維持する（視線ブレ防止）
set scrolloff=5


" ====================================================================
" 2. プラグイン管理 (vim-plug)
" ====================================================================
call plug#begin('~/.vim/plugged')

" カラーテーマ「One Dark」
Plug 'joshdick/onedark.vim'

" 滑らかなスクロール
Plug 'terryma/vim-smooth-scroll'

call plug#end()


" ====================================================================
" 3. カラーテーマ（One Dark）の設定
" ====================================================================
" ターミナルで24bit True Color（真色）を有効にする
if (has("nvim"))
  let $NVIM_TUI_ENABLE_TRUE_COLOR=1
endif
if (has("termguicolors"))
  set termguicolors
endif

" 背景を暗く設定
set background=dark

" ※重要: colorscheme を呼び出す前に背景色のオーバーライドを記述
let g:onedark_color_overrides = {
\ "background": {"gui": "#050505", "cterm": "232", "cterm16": "0" }
\}

" カラーテーマをonedarkに指定
colorscheme onedark


" ====================================================================
" 4. キーマッピング（基本操作・ショートカット）
" ====================================================================
" リーダーキーの設定
let mapleader = " "
let maplocalleader = " "

" 挿入モードから抜ける
inoremap jk <ESC>

" 検索ハイライトの消去
nnoremap <ESC><ESC> :nohlsearch<CR>

" 論理行ではなく表示行単位で移動
nnoremap j gj
nnoremap k gk

" 検索時、ヒットしたワードを常に画面中央(zz)に配置
nnoremap n nzz
nnoremap N Nzz

" カーソル現在行のトグル（※カスタムコマンド用）
nnoremap zx :CenterCursorToggle<CR>zz

" Visual mode ペースト（バッファの上書きを防ぐ入れ替え）
vnoremap p P
vnoremap P p

" インサート / コマンドモードでのカーソル移動・削除
inoremap <C-h> <Left>
inoremap <C-l> <Right>
cnoremap <C-h> <Left>
cnoremap <C-l> <Right>
inoremap <C-j> <Down>
inoremap <C-k> <Up>
inoremap <C-q> <BS>
inoremap <C-e> <Del>

" 行の移動（Alt + j/k）
nnoremap <A-j> :move .+1<CR>==
nnoremap <A-k> :move .-2<CR>==
vnoremap <A-j> :move '>+1<CR>gv=gv
vnoremap <A-k> :move '<-2<CR>gv=gv

" バッファ / ウィンドウ操作
nnoremap <C-j> :bnext<CR>
nnoremap <C-k> :bprevious<CR>
nnoremap <C-h> <C-w>W
nnoremap <C-l> <C-w>w
nnoremap <leader>s :split<CR>
nnoremap <leader>v :vsplit<CR>
nnoremap <leader>q <C-w>q


" ====================================================================
" 5. プラグイン固有のキーマッピング設定
" ====================================================================
" vim-smooth-scroll：滑らかにスクロール
" （プラグインの関数を呼び出すため、必ず一番下に配置します）
noremap <silent> <C-d> :call smooth_scroll#down(&scroll, 12, 2)<CR>
noremap <silent> <C-u> :call smooth_scroll#up(&scroll, 12, 2)<CR>
noremap <silent> <C-f> :call smooth_scroll#down(&scroll*2, 12, 4)<CR>
noremap <silent> <C-b> :call smooth_scroll#up(&scroll*2, 12, 4)<CR>
