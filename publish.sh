#!/bin/bash

set -e

PODSPEC="ZhugeioAnalytics.podspec"
CONFIG_HEADER="Zhugeio/ZGCore/ZhugeConfig.h"

# ==========================================
# 模式 1: 修改版本号 (传入了版本号参数)
# 举例: ./publish.sh 4.1.4
# ==========================================
if [ -n "$1" ]; then
    NEW_VERSION="$1"
    echo "🛠  模式: 修改版本号 -> $NEW_VERSION"
    
    # 简单的版本号格式校验
    if [[ ! "$NEW_VERSION" =~ ^[0-9]+(\.[0-9]+)+([-a-zA-Z0-9.]+)?$ ]]; then
         echo "❌ 错误: 版本号格式看起来不对: '$NEW_VERSION'"
         exit 1
    fi

    # 1. 修改 Podspec
    if [ ! -f "$PODSPEC" ]; then
        echo "❌ 找不到文件: $PODSPEC"
        exit 1
    fi
    # 替换 s.version = "x.y.z" 或 'x.y.z'
    sed -i "" -E "s/(s.version[[:space:]]*=[[:space:]]*['\"])[^'\"]+(['\"])/\1$NEW_VERSION\2/" "$PODSPEC"
    echo "✅ 已更新 $PODSPEC"

    # 2. 修改 ZhugeConfig.h
    if [ ! -f "$CONFIG_HEADER" ]; then
        echo "❌ 找不到文件: $CONFIG_HEADER"
        exit 1
    fi
    # 替换 #define ZG_SDK_VERSION @"x.y.z"
    sed -i "" -E "s/(#define[[:space:]]+ZG_SDK_VERSION[[:space:]]+@\\\")[^\"]+(\\\")/\1$NEW_VERSION\2/" "$CONFIG_HEADER"
    echo "✅ 已更新 $CONFIG_HEADER"

    # 3. 输出 git diff
    echo ""
    echo "📄 Git Diff 预览:"
    echo "========================================"
    git diff "$PODSPEC" "$CONFIG_HEADER"
    echo "========================================"
    echo "✨ 版本号修改完成 (未提交代码)。"
    echo "👉 确认无误后，请运行不带参数的 ./publish.sh 进行正式发布。"
    exit 0
fi

# ==========================================
# 模式 2: 正式发布流程 (无参数)
# ==========================================
echo "🚀 模式: 正式发布"

# 1. 提取 podspec 版本号
if [ ! -f "$PODSPEC" ]; then
  echo "❌ 找不到 $PODSPEC"
  exit 1
fi

# 提取版本号
VERSION=$(grep -E 's.version\s*=' "$PODSPEC" | sed -E 's/.*"([0-9.]+)".*/\1/')

if [ -z "$VERSION" ]; then
  echo "❌ 无法从 $PODSPEC 中解析版本号"
  exit 1
fi

echo "📦 检测到当前版本: $VERSION"

# 2. 预检：验证 Podspec
echo "🔍 正在进行本地验证 (pod lib lint)..."
pod lib lint "$PODSPEC" --allow-warnings --verbose

# 3. 提交 Git 变更
if [ -n "$(git status --porcelain)" ]; then
    echo "🔧 提交未保存的变更..."
    git add .
    git commit -m "release $VERSION" || echo "⚠️ 提交步骤无变更"
    git push
else
    echo "✅ 工作区干净，无需提交"
fi

# 4. 创建并推送 Git Tag
echo "🏷 处理 Git tag $VERSION..."

if git rev-parse "$VERSION" >/dev/null 2>&1; then
  echo "⚠️ Tag $VERSION 已存在"
else
  git tag "$VERSION"
  git push origin "$VERSION"
fi

# 5. 执行 pod trunk push
echo "☁️ 发布到 CocoaPods..."

if pod trunk push "$PODSPEC" --allow-warnings; then
    echo "🎉 发布完成！版本: $VERSION"
else
    echo "❌ 发布失败！"
    exit 1
fi