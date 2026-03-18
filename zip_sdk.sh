#!/bin/bash

# 设置报错即停止
set -e

PODSPEC="ZhugeioAnalytics.podspec"
OUTPUT_DIR="release_zip"
TEMP_DIR="temp_archive"

# 1. 提取版本号
if [ ! -f "$PODSPEC" ]; then
    echo "❌ 找不到 $PODSPEC"
    exit 1
fi

VERSION=$(grep -E 's.version\s*=' "$PODSPEC" | sed -E 's/.*"([0-9.]+)".*/\1/')
echo "📦 检测到 SDK 版本: $VERSION"

# 2. 创建输出目录
mkdir -p "$OUTPUT_DIR"

# 清理并创建临时文件夹
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"

# --- 打包 Core (更名为 ZhugeioAnalytics) ---
echo "⚙️ 正在打包 zhugeio-ios-$VERSION.zip..."
CORE_TEMP="$TEMP_DIR/ZhugeioAnalytics"
mkdir -p "$CORE_TEMP"

# 复制 ZGCore 源码到 ZhugeioAnalytics 目录下
if [ -d "Zhugeio/Classes/ZGCore" ]; then
    cp -R Zhugeio/Classes/ZGCore "$CORE_TEMP/"
else
    echo "❌ 错误: 找不到 Zhugeio/Classes/ZGCore 目录"
    exit 1
fi

# 复制 资源文件
if [ -d "Zhugeio/Resources" ]; then
    cp -R Zhugeio/Resources "$CORE_TEMP/"
fi

# 写入版本及集成说明
cat <<EOF > "$CORE_TEMP/VERSION.txt"
Zhugeio Analytics iOS SDK
Version: $VERSION
Release Date: $(date +%Y-%m-%d)

Manual Integration Note:
1. Add the 'ZGCore' and 'Resources' folders to your Xcode project.
2. Link necessary frameworks: UIKit, Foundation, SystemConfiguration.
3. Ensure 'PrivacyInfo.xcprivacy' is included in your main bundle's resources.
EOF

# 执行压缩
echo "🧹 清理旧的 Core 包..."
rm -f "$OUTPUT_DIR/zhugeio-ios-$VERSION.zip"
(cd "$TEMP_DIR" && zip -q -r "../$OUTPUT_DIR/zhugeio-ios-$VERSION.zip" "ZhugeioAnalytics" -x "*.DS_Store" -x "__MACOSX")
echo "✅ 已生成: $OUTPUT_DIR/zhugeio-ios-$VERSION.zip"

# --- 打包 GMEncrypt ---
echo "🔐 正在打包 zhugeio-ios-gmencrypt-$VERSION.zip..."
GM_TEMP="$TEMP_DIR/ZhugeioAnalytics_GMEncrypt"
mkdir -p "$GM_TEMP"

# 复制 GMEncrypt 源码
if [ -d "Zhugeio/Classes/GMEncrypt" ]; then
    cp -R Zhugeio/Classes/GMEncrypt "$GM_TEMP/"
else
    echo "❌ 错误: 找不到 Zhugeio/Classes/GMEncrypt 目录"
    exit 1
fi

# 写入版本说明
cat <<EOF > "$GM_TEMP/VERSION.txt"
Zhugeio Analytics iOS SDK - GMEncrypt (GuoMi)
Version: $VERSION
Release Date: $(date +%Y-%m-%d)

Note: This component requires the 'ZhugeioAnalytics' Core package and 'GMOpenSSL' dependency.
EOF

# 执行压缩
echo "🧹 清理旧的 GMEncrypt 包..."
rm -f "$OUTPUT_DIR/zhugeio-ios-gmencrypt-$VERSION.zip"
(cd "$TEMP_DIR" && zip -q -r "../$OUTPUT_DIR/zhugeio-ios-gmencrypt-$VERSION.zip" "ZhugeioAnalytics_GMEncrypt" -x "*.DS_Store" -x "__MACOSX")
echo "✅ 已生成: $OUTPUT_DIR/zhugeio-ios-gmencrypt-$VERSION.zip"

# 3. 清理临时目录
rm -rf "$TEMP_DIR"

echo "--------------------------------------------------------"
echo "✅ 打包完成！生成文件位于 $OUTPUT_DIR 文件夹下"
echo "--------------------------------------------------------"
