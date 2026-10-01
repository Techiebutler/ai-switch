#!/usr/bin/env bash
# Installs ai-switch (and the claude-switch shortcut) into ~/.local/bin.
#   curl -fsSL https://raw.githubusercontent.com/Techiebutler/ai-switch/main/install.sh | bash
# Override the location with INSTALL_DIR=...
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/Techiebutler/ai-switch/main"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
TARGET="$INSTALL_DIR/ai-switch"

command -v python3 >/dev/null || { echo "python3 is required" >&2; exit 1; }

mkdir -p "$INSTALL_DIR"
curl -fsSL "$REPO_RAW/ai-switch" -o "$TARGET.tmp"
chmod +x "$TARGET.tmp"
mv "$TARGET.tmp" "$TARGET"
# replaces a claude-switch 1.x install with the shortcut
ln -sf ai-switch "$INSTALL_DIR/claude-switch"
echo "installed $("$TARGET" --version) to $TARGET (plus the claude-switch shortcut)"

case ":$PATH:" in
  *":$INSTALL_DIR:"*) ;;
  *)
    echo
    echo "$INSTALL_DIR is not on your PATH. Add this to your shell profile (~/.zshrc or ~/.bashrc):"
    echo "  export PATH=\"$INSTALL_DIR:\$PATH\""
    ;;
esac

echo
echo "Next: log in to a tool, then run: ai-switch <claude|codex|cursor> add <name>"
