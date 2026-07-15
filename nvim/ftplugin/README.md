# ftplugin

このディレクトリには、filetype ごとのローカル設定を置く。

- `ftplugin/markdown.lua`: Markdown 専用のインデント設定
- `ftplugin/lua.lua`: Lua 専用の 2 スペース設定
- `ftplugin/tex.lua`: TeX 専用の文章編集設定

基本方針:

- 全体設定は `lua/config/base.lua`
- ファイルタイプ固有の上書きは `ftplugin/<filetype>.lua`
- さらに後勝ちにしたい場合は `after/ftplugin/<filetype>.lua`
