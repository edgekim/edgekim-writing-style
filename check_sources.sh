#!/bin/bash
# 메모리의 글쓰기 지시 파일이 지난 배포 뒤 바뀌었는지 본다.
# 출력: CHANGED <파일>, MISSING <파일>, NEW_FEEDBACK <파일>(sources.txt에 없는 feedback 파일)
# --update: 현재 상태를 .sources.lock에 기록(배포 뒤 실행)
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
MEM="${MEMORY_DIR:-$HOME/.claude/projects/$(echo "$HOME" | tr "/." "--")/memory}"
LOCK="$DIR/.sources.lock"
touch "$LOCK"
if [ "$1" = "--update" ]; then
  : > "$LOCK.tmp"
  while read -r f; do [ -f "$MEM/$f" ] && echo "$(shasum -a 256 "$MEM/$f" | cut -d' ' -f1) $f" >> "$LOCK.tmp"; done < "$DIR/sources.txt"
  for f in "$MEM"/feedback_*.md; do echo "seen $(basename "$f")" >> "$LOCK.tmp"; done
  mv "$LOCK.tmp" "$LOCK"; echo "lock updated"; exit 0
fi
while read -r f; do
  if [ ! -f "$MEM/$f" ]; then echo "MISSING $f"; continue; fi
  h=$(shasum -a 256 "$MEM/$f" | cut -d' ' -f1)
  grep -q "^$h $f$" "$LOCK" || echo "CHANGED $f"
done < "$DIR/sources.txt"
for f in "$MEM"/feedback_*.md; do
  b=$(basename "$f")
  grep -qx "$b" "$DIR/sources.txt" && continue
  grep -q "^seen $b$" "$LOCK" || echo "NEW_FEEDBACK $b"
done
