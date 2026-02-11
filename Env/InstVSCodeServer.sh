#!/bin/bash

set -e

if [ $# -ne 1 ]; then
    echo "Usage: $0 <package_path>"
    exit 1
fi

PKG_PATH="$1"
if [ ! -f "$PKG_PATH" ]; then
    echo "Error: package not found at $PKG_PATH"
    exit 1
fi

echo "[INFO] Package path: $PKG_PATH"

BASE_DIR="$HOME/.vscode-server/bin"
mkdir -p "$BASE_DIR"

TMP_DIR="$BASE_DIR/tmp.$$"
mkdir "$TMP_DIR"
echo "[INFO] Temporary directory: $TMP_DIR"

# 解压
tar -xzf "$PKG_PATH" -C "$TMP_DIR"

# 确定根目录
EXTRACT_ROOT=""
if [ -f "$TMP_DIR/bin/helpers/browser.sh" ]; then
    EXTRACT_ROOT="$TMP_DIR"
elif [ -f "$TMP_DIR/vscode-server-linux-x64/bin/helpers/browser.sh" ]; then
    EXTRACT_ROOT="$TMP_DIR/vscode-server-linux-x64"
elif [ -f "$TMP_DIR/vscode-server-linux-arm64/bin/helpers/browser.sh" ]; then
    EXTRACT_ROOT="$TMP_DIR/vscode-server-linux-arm64"
elif [ -f "$TMP_DIR/vscode-server-linux-armhf/bin/helpers/browser.sh" ]; then
    EXTRACT_ROOT="$TMP_DIR/vscode-server-linux-armhf"
else
    for d in "$TMP_DIR"/*; do
        if [ -d "$d" ] && [ -f "$d/bin/helpers/browser.sh" ]; then
            EXTRACT_ROOT="$d"
            break
        fi
    done
fi

if [ -z "$EXTRACT_ROOT" ] || [ ! -f "$EXTRACT_ROOT/bin/helpers/browser.sh" ]; then
    echo "[ERROR] bin/helpers/browser.sh not found."
    rm -rf "$TMP_DIR"
    exit 1
fi

BROWSER_SH="$EXTRACT_ROOT/bin/helpers/browser.sh"

# 提取 COMMIT 和 VERSION
COMMIT_ID=$(grep -o 'COMMIT="[a-f0-9]\{40\}"' "$BROWSER_SH" | head -n1 | cut -d'"' -f2)
VERSION=$(grep -o 'VERSION="[0-9.]*"' "$BROWSER_SH" | head -n1 | cut -d'"' -f2)

if [ -z "$COMMIT_ID" ] || [ -z "$VERSION" ]; then
    echo "[ERROR] Failed to extract COMMIT or VERSION from browser.sh"
    head -n 10 "$BROWSER_SH"
    rm -rf "$TMP_DIR"
    exit 1
fi

echo "[INFO] Detected VERSION: $VERSION, COMMIT: $COMMIT_ID"

TARGET_DIR="$BASE_DIR/$COMMIT_ID"
[ -e "$TARGET_DIR" ] && rm -rf "$TARGET_DIR"

mv "$EXTRACT_ROOT" "$TARGET_DIR"
touch "$TARGET_DIR/vscode-remote-lock.$COMMIT_ID"

# 清理
[ "$EXTRACT_ROOT" != "$TMP_DIR" ] && rm -rf "$TMP_DIR" || rmdir "$TMP_DIR"

echo "[SUCCESS] VS Code Server $VERSION ($COMMIT_ID) installed."
