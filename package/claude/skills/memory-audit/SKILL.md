---
name: memory-audit
description: プロジェクトメモリ（~/.config/claude/projects/<project>/memory/）の棚卸し。インデックス整合・参照先存在の機械検証とタイプ別の文脈判断で keep/update/merge/delete を提案し、承認後に適用する。「メモリを棚卸しして」「メモリの整理」「メモリの監査」「memory audit」で起動。
---

# Memory Audit

対象はシステムプロンプトの Memory セクションに記載されたディレクトリ（以下 MEMORY_DIR）。
削除・統合・上書きは処分案レポートのユーザー承認後のみ行う。承認前の工程は読み取りとレポート生成に限定する。

メモリは git 管理外で、MEMORY.md は並行セッションが随時追記する。このため:

- 件数はスナップショット。各工程で必ず再列挙する
- 監査開始後に追加されたメモリは処分対象にしない（keep 扱い）

## 0. バックアップ

scratchpad に MEMORY_DIR を丸ごとコピーしてから開始する（唯一の復元手段）。

## 1. 機械検証（パス1）

```bash
python3 <このスキルのディレクトリ>/scripts/index_check.py <MEMORY_DIR>
```

検出: インデックス孤児（recall されない死蔵メモリ）/ 幽霊行 / リンクなし直書き行 / frontmatter 欠落 / 重複行 / wikilink の分類。
`wikilink_slug_mismatch` は実在メモリを指すのに snake/kebab 形式ずれで解決しないリンクで修復対象、`wikilink_missing_INFO` は規約上「あとで書く価値の印」なので INFO 扱い。

## 2. 文脈判断（パス2）

**1ファイル = 1体**のサブエージェント（Sonnet 相当を model 指定、読み取り専用、general-purpose か claude）で並列判定する。
対象はパス1のフラグ付き全件 + feedback/project タイプ全件。reference は参照先検証がそのまま文脈判断を兼ねるため全件出す。

- **reference**: 本文中のパス・コマンド・スクリプト名・設定値を対象リポジトリ（関連リポジトリ含む）に対して検証。
  消滅 → delete、変質 → update、外部サービスで検証不能 → keep（evidence に UNVERIFIABLE と明記）
- **project**: 記録された作業の完了・方針転換を git log・openspec 等の課題管理・gh CLI で突き合わせ。
  完了 → delete、部分完了 → update
- **feedback**: CLAUDE.md（プロジェクト・local・グローバル）と .claude/rules/、関連スキルの SKILL.md への
  昇格済みを検出 → delete（二重コンテキスト解消）。lint 等で機械強制済みも delete。メモリ間の主題重複 → merge

プロンプトに含める指示:

- 出力は共通スキーマの**単一 JSON オブジェクトのみ**（file / type / verdict / merge_into / rationale 2文以内 / evidence 3項目以内 / proposed_change）。前置き禁止・evidence 簡潔化はオーケストレーターのコンテキスト保護のため必須
- ファイルの編集・削除の禁止（読み取りと判定のみ）
- メモリ間の重複判定は MEMORY_DIR/MEMORY.md のインデックスを Read して行い、確信が持てなければ keep + rationale に候補名
- 作成直後（当日）のメモリは原則 keep
- Bash にクォート・$()・エスケープ空白を入れない（権限確認が発生する）。Grep/Glob/Read を優先

## 3. レポートと承認

処分区分ごと（delete / merge / update / インデックス修復 / INFO）にまとめ、delete と merge は1件ずつ根拠と証跡を提示する。

- merge の**相互指し合い**（A→B と B→A）はオーケストレーターが存続側を決めて1組に解決する（固有情報が多い側・被参照が多い側を存続）
- 承認は区分単位で取り、承認されなかった項目は keep に落とす。個別除外も受け付ける

## 4. 適用と再検証

1. 適用直前に MEMORY_DIR のファイル一覧と MEMORY.md を再読し、監査開始後の追加分は keep 扱いにする
2. 承認済み処分を適用する
   - delete: rm + MEMORY.md の該当行削除
   - merge: 統合先に内容を取り込み → 統合元を rm → 該当行削除
   - update: 本文と frontmatter description を Edit
   - リンクなし直書き行: frontmatter 付きファイルに実体化し、行をリンク形式に書き換え
   - wikilink_slug_mismatch: リンク先ファイルの実際の frontmatter name に正規化
3. `scripts/index_check.py` を再実行し、orphans / ghosts / linkless_index_lines / frontmatter_issues / wikilink_slug_mismatch がすべて空であることを確認する
4. 適用サマリー（削除 N・統合 N・更新 N）とバックアップの場所を報告する
