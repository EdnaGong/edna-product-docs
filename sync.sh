#!/bin/bash
set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_DIR="/Users/fengur/Desktop/work/EdnaAHJobs/需求与方案"
DEST_DIR="$REPO_DIR/需求与方案"

echo "→ 同步 MD 文件..."
rm -rf "$DEST_DIR"

# 复制所有 MD 文件，保留目录层级（排除 demo 等非文档目录）
find "$SOURCE_DIR" -name "*.md" | while read -r file; do
  rel="${file#$SOURCE_DIR/}"
  dest="$DEST_DIR/$rel"
  mkdir -p "$(dirname "$dest")"
  cp "$file" "$dest"
done

echo "→ 生成侧边栏..."

# 清理文件名：去掉日期前缀和版本后缀
clean_name() {
  echo "$1" | sed 's/^[0-9]\{8\}_//' | sed 's/_v[0-9]*$//' | sed 's/_final$//'
}

# 递归生成侧边栏（目录在前，文件在后）
generate_sidebar() {
  local dir="$1"
  local indent="$2"
  local base="$REPO_DIR"

  # 先输出子目录
  for subdir in "$dir"/*/; do
    [ -d "$subdir" ] || continue
    local dname
    dname=$(basename "$subdir")
    echo "${indent}- **$dname**"
    generate_sidebar "$subdir" "${indent}  "
  done

  # 再输出 MD 文件
  for file in "$dir"/*.md; do
    [ -f "$file" ] || continue
    local fname
    fname=$(basename "$file" .md)
    [[ "$fname" == "_sidebar" ]] && continue
    [[ "$fname" == "README" ]] && continue
    local display rel_path
    display=$(clean_name "$fname")
    rel_path="${file#$base/}"
    echo "${indent}- [$display]($rel_path)"
  done
}

{
  echo "- **需求与方案**"
  generate_sidebar "$DEST_DIR" "  "
} > "$REPO_DIR/_sidebar.md"

echo "→ 提交并推送..."
cd "$REPO_DIR"
export HTTPS_PROXY=http://127.0.0.1:6789
git add -A
git diff --cached --quiet && echo "无变更，跳过提交" && exit 0
git commit -m "sync: $(date '+%Y-%m-%d %H:%M')"
git push origin main

echo "✓ 同步完成"
