#!/usr/bin/env bash
# 授信 Skill 安装 / 更新脚本（macOS、Linux）
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/Nicky-zzy/bank-corporate-credit-skills.git}"
SRC_DIR="${SKILL_SRC:-$HOME/.bank-credit-skills}"
QUIET=0
for a in "$@"; do
  case "$a" in
    --quiet|-q) QUIET=1 ;;
  esac
done

say() { if [ "$QUIET" -eq 0 ]; then printf '%s\n' "$*"; fi; }
fail() { printf '错误：%s\n' "$*" >&2; exit 1; }

# ---------- 1. 定位 skill 根目录 ----------
STATE_FILE="$SRC_DIR/.skill_home"
if [ -z "${SKILL_HOME:-}" ] && [ -f "$STATE_FILE" ]; then
  SKILL_HOME="$(cat "$STATE_FILE")"
fi
if [ -z "${SKILL_HOME:-}" ]; then
  for c in \
    "$HOME/.doubao/agent_mode/workspace/.skills" \
    "$HOME/.doubao/agent_mode/.skills" \
    "$HOME/.doubao/.skills" \
    "$HOME/.skills"; do
    if [ -d "$c" ]; then SKILL_HOME="$c"; break; fi
  done
fi
if [ -z "${SKILL_HOME:-}" ]; then
  fail "未找到 skill 目录。请指定：SKILL_HOME=/你的/skill根目录 bash install.sh"
fi
[ -d "$SKILL_HOME" ] || fail "目录不存在：$SKILL_HOME"

# ---------- 2. 取得或更新源码 ----------
command -v git >/dev/null 2>&1 || fail "未安装 git，请先安装 Git，或下载仓库 zip 解压到 $SRC_DIR 后重试"

if [ -d "$SRC_DIR/.git" ]; then
  branch="$(git -C "$SRC_DIR" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@' || true)"
  [ -n "$branch" ] || branch="main"
  git -C "$SRC_DIR" fetch -q origin "$branch"
  git -C "$SRC_DIR" checkout -q "$branch" 2>/dev/null || true
  git -C "$SRC_DIR" reset -q --hard "origin/$branch"
  say "已更新源码：$SRC_DIR（$branch）"
elif [ -f "$SRC_DIR/VERSION" ]; then
  say "检测到本地源码目录（非 git），跳过拉取：$SRC_DIR"
else
  mkdir -p "$(dirname "$SRC_DIR")"
  git clone -q "$REPO_URL" "$SRC_DIR"
  say "已克隆仓库：$SRC_DIR"
fi

printf '%s\n' "$SKILL_HOME" > "$STATE_FILE"

# ---------- 3. 同步每个 skill ----------
VERSION="$(cat "$SRC_DIR/VERSION" 2>/dev/null | tr -d '[:space:]')"
[ -n "$VERSION" ] || VERSION="unknown"
SYNCED=0
for d in "$SRC_DIR"/skills/*/; do
  [ -f "$d/SKILL.md" ] || continue
  name="$(basename "$d")"
  rm -rf "${SKILL_HOME:?}/$name"
  cp -R "$d" "$SKILL_HOME/$name"
  printf '%s\n' "$VERSION" > "$SKILL_HOME/$name/.installed-version"
  say "已同步 $name v$VERSION → $SKILL_HOME/$name"
  SYNCED=$((SYNCED + 1))
done
[ "$SYNCED" -gt 0 ] || fail "仓库内未找到任何 skills/*/SKILL.md"

say "完成。新开一个会话后，技能列表才会重新扫描并生效。"
