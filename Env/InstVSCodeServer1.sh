#!/bin/bash

# 通用 VS Code Server 手动安装脚本
# 参数1: commit ID（如 a1b2c3...）
# 参数2: VS Code Server 安装包的绝对路径（如 /tmp/vscode-server-linux-x64.tar.gz）

set -e  # 遇错立即退出

if [ $# -ne 2 ]; then
    echo "Usage: $0 <commit_id> <package_path>"
    exit 1
fi

COMMIT_ID="$1"
PKG_PATH="$2"

if [ ! -f "$PKG_PATH" ]; then
    echo "Error: package not found at $PKG_PATH"
    exit 1
fi

TARGET_DIR="$HOME/.vscode-server/bin/$COMMIT_ID"
mkdir -p "$TARGET_DIR"

cp "$PKG_PATH" "$TARGET_DIR/"
cd "$TARGET_DIR"
tar -xzf "$(basename "$PKG_PATH")" --strip-components=1
touch "vscode-remote-lock.$COMMIT_ID"
rm -f "$(basename "$PKG_PATH")"

echo "Success: VS Code Server ($COMMIT_ID) installed."
