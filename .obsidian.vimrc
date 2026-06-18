" ====================================================================
" 1. 基本設定
" ====================================================================
" システムのクリップボードとヤンク・削除を同期
set clipboard=unnamed

" リーダーキーの設定
unmap <Space>

" ====================================================================
" 2. キーマッピング（基本操作・ショートカット）
" ====================================================================
" 挿入モードから抜ける
imap jk <Esc>

" 検索ハイライトの消去
nmap <Esc><Esc> :nohl<CR>

" 論理行ではなく表示行単位で移動
nmap j gj
nmap k gk

" 検索時、ヒットしたワードを常に画面中央(zz)に配置
nmap n nzz
nmap N Nzz

" Visual mode ペースト（バッファの上書きを防ぐ入れ替え）
vmap p P
vmap P p

" インサートモードでのカーソル移動・削除
imap <C-h> <Left>
imap <C-l> <Right>
imap <C-j> <Down>
imap <C-k> <Up>
imap <C-q> <BS>
imap <C-e> <Del>

" --- ObsidianのコマンドをVimキーにバインドする設定 ---

" 左右に画面分割
exmap vsplit obcommand workspace:split-vertical
nmap <Space>v :vsplit<CR>

" 上下に画面分割
exmap split obcommand workspace:split-horizontal
nmap <Space>s :split<CR>

" タブ（ペイン）を閉じる
exmap close obcommand workspace:close
nmap <Space>q :close<CR>

" 次のタブへ移動
exmap nextTab obcommand workspace:next-tab
nmap <C-l> :nextTab<CR>

" 前のタブへ移動
exmap prevTab obcommand workspace:previous-tab
nmap <C-h> :prevTab<CR>
