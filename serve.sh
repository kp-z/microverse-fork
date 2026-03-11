#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR/export"

# 检查导出文件是否存在
if [ ! -f "index.html" ]; then
    echo "❌ 未找到导出文件，请先运行: ./export.sh"
    exit 1
fi

echo "🎮 启动 Microverse Web 服务器..."
echo "📍 访问地址: http://localhost:5174"
echo "⏹️  停止服务器: Ctrl+C"
python3 -m http.server 5174
