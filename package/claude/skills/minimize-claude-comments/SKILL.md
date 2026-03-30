---
name: minimize-claude-comments
description: |
  PR 上の @claude 関連コメントを一括で minimize（折りたたみ）する。
  対象: github-actions[bot] の応答コメント + 自分の @claude メンションコメント。
  `/minimize-claude-comments` または `/minimize-claude-comments #123` で呼び出す。
  「claude のコメントを片付けて」「PR のボットコメントを畳んで」「minimize comments」
  のような指示でもトリガーする。
allowed-tools: Bash(${SKILL_DIR}/scripts/minimize-claude-comments.sh *)
---

# Minimize Claude Comments

PR 上の @claude 関連コメントを GitHub GraphQL API で一括 minimize する。
対象は 2 種類:

1. `github-actions[bot]` の応答コメント（ボットのレビュー結果）
2. 自分が `@claude` を呼び出すために書いたトリガーコメント

レビュー対応後に不要になったこれらのコメントを、1回の操作でまとめて折りたたむ。

## 使い方

```
/minimize-claude-comments #888
/minimize-claude-comments 888
```

## 手順

1. 引数から PR 番号を取得する。`#` プレフィックスがあれば除去する。
   引数がない場合は、ユーザーに PR 番号を聞く。

2. リポジトリの `owner/repo` を特定する。
   `gh repo view --json nameWithOwner --jq .nameWithOwner` を使う。

3. スクリプトを実行する:

   ```
   ${SKILL_DIR}/scripts/minimize-claude-comments.sh <owner/repo> <pr-number>
   ```

4. スクリプトの出力結果をユーザーに報告する。
   - 成功時: minimize したコメント数を伝える
   - 対象なし: 「minimize 対象のコメントはありませんでした」と伝える
   - エラー時: エラーメッセージを伝える
