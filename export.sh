#!/bin/bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "🎮 开始导出 Microverse Web 版本..."

# 检查 Godot 是否安装
if ! command -v godot &> /dev/null; then
    echo "❌ Godot 未安装，请先安装 Godot 4.4+"
    echo "macOS: brew install --cask godot"
    echo "或访问: https://godotengine.org/download"
    exit 1
fi

# 创建导出目录
mkdir -p export

# 使用 Godot 命令行导出
godot --headless --export-release "Web" "export/index.html"

echo "✅ Microverse Web 版本导出完成！"
echo "📁 导出位置: $SCRIPT_DIR/export/"
echo "🚀 运行: ./serve.sh"
