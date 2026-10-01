#!/usr/bin/env bash
# Installs claude-switch into ~/.local/bin (override with INSTALL_DIR=...).
#   curl -fsSL https://raw.githubusercontent.com/Techiebutler/claude-switch/main/install.sh | bash
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/Techiebutler/claude-switch/main"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
TARGET="$INSTALL_DIR/claude-switch"

command -v python3 >/dev/null || { echo "python3 is required" >&2; exit 1; }

mkdir -p "$INSTALL_DIR"
curl -fsSL "$REPO_RAW/claude-switch" -o "$TARGET.tmp"
chmod +x "$TARGET.tmp"
mv "$TARGET.tmp" "$TARGET"
echo "installed $("$TARGET" --version) to $TARGET"

case ":$PATH:" in
  *":$INSTALL_DIR:"*) ;;
  *)
    echo
    echo "$INSTALL_DIR is not on your PATH. Add this to your shell profile (~/.zshrc or ~/.bashrc):"
    echo "  export PATH=\"$INSTALL_DIR:\$PATH\""
    ;;
esac

echo
echo "Next: log in to Claude Code, then run: claude-switch add <name>"
