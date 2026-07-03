#!/usr/bin/env python3
"""メモリディレクトリの機械検証。使い方: python3 index_check.py <memory_dir>

検出対象:
- orphans: ファイルは存在するが MEMORY.md に載っていない（recall されない死蔵メモリ）
- ghosts: MEMORY.md にあるがファイルが存在しない
- duplicate_index_entries: 同一ファイルへの重複行
- linkless_index_lines: リンクなしの直書き行（Why/How を持てない規約違反）
- frontmatter_issues: name / description / type の欠落
- wikilink_slug_mismatch: [[link]] が実在メモリを指すのにスラッグ形式ずれで解決しない（修復対象）
- wikilink_missing_INFO: 本当に未作成の [[link]]（規約上「あとで書く価値の印」であり INFO 扱い）
"""
import json
import os
import re
import sys

memory_dir = sys.argv[1]
index_path = os.path.join(memory_dir, "MEMORY.md")

files = sorted(
    f for f in os.listdir(memory_dir)
    if f.endswith(".md") and f != "MEMORY.md"
)
with open(index_path, encoding="utf-8") as fp:
    index_text = fp.read()

linked = re.findall(r"\]\(([^)]+\.md)\)", index_text)
entry_lines = [l for l in index_text.splitlines() if l.startswith("- ")]
linkless = [l for l in entry_lines if not re.search(r"\]\([^)]+\.md\)", l)]

orphans = [f for f in files if f not in linked]
ghosts = sorted(set(f for f in linked if f not in files))
dupes = sorted(f for f in set(linked) if linked.count(f) > 1)

fm_issues = []
names = set()
bodies = {}
for f in files:
    with open(os.path.join(memory_dir, f), encoding="utf-8") as fp:
        text = fp.read()
    bodies[f] = text
    m = re.match(r"---\n(.*?)\n---", text, re.S)
    if not m:
        fm_issues.append({"file": f, "issue": "frontmatter なし"})
        continue
    fm = m.group(1)
    for field in ("name:", "description:", "type:"):
        if field not in fm:
            fm_issues.append({"file": f, "issue": field + " 欠落"})
    nm = re.search(r"name:\s*(\S+)", fm)
    if nm:
        names.add(nm.group(1))

# wikilink をスラッグ形式ずれ（修復対象）と未作成（INFO）に分類する。
# 形式ずれの判定はハイフン/アンダースコアの正規化一致で行う
basenames = {f[:-3] for f in files}
normalized = {b.replace("-", "_"): b for b in basenames}
slug_mismatch = []
missing = []
for f, text in bodies.items():
    for target in re.findall(r"\[\[([^\]]+)\]\]", text):
        if target in names or target in basenames:
            continue
        target_norm = target.replace("-", "_")
        if target_norm in normalized:
            slug_mismatch.append({
                "file": f,
                "target": target,
                "existing_file": normalized[target_norm] + ".md",
            })
        else:
            missing.append({"file": f, "target": target})

print(json.dumps({
    "total_files": len(files),
    "index_entry_lines": len(entry_lines),
    "orphans": orphans,
    "ghosts": ghosts,
    "duplicate_index_entries": dupes,
    "linkless_index_lines": linkless,
    "frontmatter_issues": fm_issues,
    "wikilink_slug_mismatch": slug_mismatch,
    "wikilink_missing_INFO": missing,
}, ensure_ascii=False, indent=2))
