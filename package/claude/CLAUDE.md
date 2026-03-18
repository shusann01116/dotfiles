## Bash コマンド発行ルール

以下のパターンは毎回パーミッション確認が発生するため、**絶対に使用しないこと**。
Subagent（Explore 含む）にも同様に適用される。

### クォート文字を含むコマンド

- **トリガー**: Bash コマンド内に `"..."` などのクォート付き文字列を含む
- **エラー**: `Command contains quoted characters in flag names`
- **禁止例**: `git log --oneline cfa3a54 -1 && echo "---" && git show cfa3a54 --stat`
- **代替**: 複数の Bash 呼び出しに分割する / Read・Grep 等の専用ツールを使用

### 連続クォート文字を含むコマンド

- **トリガー**: `'""'` のように連続するクォート文字が単語の先頭に現れる
- **エラー**: `Command contains consecutive quote characters at word start (potential obfuscation)`
- **禁止例**: `gh api user --jq '""'`
- **代替**: jq フィルタを変数やファイルに分離する / クォートの入れ子を避ける構成にする

### バックスラッシュによる空白エスケープ

- **トリガー**: `\ ` のようにバックスラッシュで空白文字をエスケープしている
- **エラー**: `Contains backslash-escaped whitespace`
- **禁止例**: `echo hello\ world`
- **代替**: クォートで囲む（`echo 'hello world'`）/ 空白を含むパスは変数に格納せず専用ツールを使用
- **git format での回避**: `git log --format=%H\ %ai` → `git log --format=%H%x20%ai` のように `%xNN`（16進コード）で空白を表現する

### `cd` と `git` の同一コマンド内での併用

- **トリガー**: `cd <path> && git <cmd>` のように `cd` と `git` を1コマンドで実行
- **エラー**: 毎回パーミッション確認ダイアログが発生
- **禁止例**: `cd /path/to/repo && git status`
- **代替**: `git -C /path/to/repo status` を使用 / 別々の Bash 呼び出しに分割

### `$()` コマンド置換を含むコマンド

- **トリガー**: Bash コマンド内に `$(...)` のコマンド置換を含む
- **エラー**: `Command contains $() command substitution`
- **禁止例**: `` for dir in /path/to/*/; do echo "=== $(basename "$dir") ==="; ls -1 "$dir"; done ``
- **代替**: Glob・Read・Grep 等の専用ツールを使用 / `$()` を使わない形にコマンドを分割

### シェル演算子前のバックスラッシュ

- **トリガー**: `\;`, `\|`, `\&`, `\<`, `\>` のようにシェル演算子の前にバックスラッシュがある
- **エラー**: `Command contains a backslash before a shell operator (;, |, &, <, >) which can hide command structure`
- **禁止例**: `find /path -name "*.css" -exec grep -l "pattern" {} \;`
- **代替**: Glob・Grep 等の専用ツールを使用 / `find -exec` を避けて `find -print` + パイプに分割
