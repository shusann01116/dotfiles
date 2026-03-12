## Bash コマンド発行ルール

以下のパターンは毎回パーミッション確認が発生するため、**絶対に使用しないこと**:

### 1. クォート文字を含むコマンド

`echo "---"` のようなクォート付き文字列を含む Bash コマンドは「Command contains quoted characters in flag names」エラーが発生する。テキスト出力には Bash ではなく直接テキストを返すこと。

**禁止例:**

```bash
git log --oneline cfa3a54 -1 && echo "---" && git show cfa3a54 --stat
```

**代替:** 複数の Bash ツール呼び出しに分割するか、Read/Grep 等の専用ツールを使用する。

### 2. `cd` と `git` の同一コマンド内での併用

`cd` と `git` を一つのコマンドとして発行すると毎回パーミッション確認が発生する。必ず別々のコマンドとして実行すること。これは Subagent（Explore 含む）でも同様。

**禁止例:**

```bash
cd /path/to/repo && git status
```

**代替:** `git -C /path/to/repo status` を使用するか、別々の Bash 呼び出しに分割する。

### 3. `$()` コマンド置換を含むコマンド

`$()` を含む Bash コマンドは「Command contains $() command substitution」エラーが発生する。

**禁止例:**

```bash
for dir in /path/to/*/; do echo "=== $(basename "$dir") ==="; ls -1 "$dir"; done
```

**代替:** Glob/Read/Grep 等の専用ツールを使用するか、`$()` を使わない形にコマンドを分割する。
