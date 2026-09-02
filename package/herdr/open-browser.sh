#!/bin/sh
# terminal-browser を現在フォーカス中のペインの右分割で開く。
# herdr の [[keys.command]] type="shell" から呼ばれる。
# herdr サーバーの PATH には ~/.local/bin が無いため絶対パスで起動する。
set -e

extract_pane_id() {
  /usr/bin/python3 -c 'import sys,json;print(json.load(sys.stdin)["result"]["pane"]["pane_id"])'
}

pane=$(herdr pane current | extract_pane_id)
new=$(herdr pane split "$pane" --direction right | extract_pane_id)
herdr pane run "$new" "$HOME/.local/bin/terminal-browser"
