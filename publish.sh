#!/bin/bash

set -e

PODSPEC="ZhugeioAnalytics.podspec"

# -----------------------------
# 1. 提取 podspec 版本号
# -----------------------------
if [ ! -f "$PODSPEC" ]; then
  echo "❌ 找不到 $PODSPEC"
  exit 1
fi

VERSION=$(grep -E 's.version\s*=' "$PODSPEC" | sed -E 's/.*"([0-9.]+)".*/\1/')

if [ -z "$VERSION" ]; then
  echo "❌ 无法从 $PODSPEC 中解析版本号"
  exit 1
fi

echo "📦 检测到版本号: $VERSION"


# -----------------------------
# 2. 确保文件提交到 git
# -----------------------------
echo "🔧 提交 git 变更..."
git add .
git commit -m "release $VERSION" || true
git push


# -----------------------------
# 3. 创建并推送 Git Tag
# -----------------------------
echo "🏷 处理 Git tag $VERSION..."

if git rev-parse "$VERSION" >/dev/null 2>&1; then
  echo "⚠️ Tag $VERSION 已存在，跳过创建"
else
  git tag "$VERSION"
fi

git push origin "$VERSION"


# -----------------------------
# 4. 执行 pod trunk push
# -----------------------------
echo "🚀 发布到 CocoaPods..."

pod trunk push "$PODSPEC" --allow-warnings

echo "🎉 发布完成！版本: $VERSION"

