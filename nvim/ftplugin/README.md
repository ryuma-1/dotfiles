# ftplugin

このディレクトリには、filetype ごとのローカル設定を置く。

標準 ftplugin の設定より後に適用するため、独自設定は
`after/ftplugin/<filetype>.lua` に置く。

- `after/ftplugin/markdown.lua`: Markdown 専用のインデント設定
- `after/ftplugin/lua.lua`: Lua 専用の 2 スペース設定
- `after/ftplugin/tex.lua`: TeX 専用の文章編集設定

全体設定は `lua/config/base.lua` に置く。
