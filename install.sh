#!/usr/bin/env bash
# nerv-lock installer: copies the lock screen into your home directory.
#   ./install.sh            install / update
#   ./install.sh --uninstall

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHARE_DIR="$HOME/.local/share/nerv-lock"
BIN_DIR="$HOME/.local/bin"

say()  { printf '\033[1;38;2;255;138;31m[nerv-lock]\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$1"; }

if [[ "${1:-}" == "--uninstall" ]]; then
    rm -rf "$SHARE_DIR" "$BIN_DIR/nerv-lock"
    say "Removed. Remember to point your lock keybind back to hyprlock."
    exit 0
fi

# --- dependency checks (warnings only) ---
command -v qs >/dev/null 2>&1 || warn "Quickshell (qs) not found. Install it: sudo pacman -S quickshell"
command -v hyprlock >/dev/null 2>&1 || warn "hyprlock not found. It provides the PAM file (/etc/pam.d/hyprlock) and is the fallback locker."
[[ -f /etc/pam.d/hyprlock ]] || warn "/etc/pam.d/hyprlock is missing; authentication will not work without it."
fc-list : family | grep -q "Noto Serif CJK JP" || warn "Font 'Noto Serif CJK JP' not found: sudo pacman -S noto-fonts-cjk"
fc-list : family | grep -q "Iosevka Nerd Font Mono" || warn "Font 'Iosevka Nerd Font Mono' not found: sudo pacman -S ttf-iosevka-nerd"

# --- install ---
mkdir -p "$SHARE_DIR" "$BIN_DIR"
cp "$REPO_DIR"/*.qml "$SHARE_DIR/"
install -m 755 "$REPO_DIR/bin/nerv-lock" "$BIN_DIR/nerv-lock"

say "Installed to $SHARE_DIR"
say "Launcher:   $BIN_DIR/nerv-lock"
cat <<EOF

Next steps:
  1. Preview (no real lock, password "eva01", Esc quits):
       NERV_TEST=1 qs -p $SHARE_DIR

  2. Bind it in Hyprland (replace your hyprlock bind):
       hyprland.conf:  bind = SUPER, L, exec, $BIN_DIR/nerv-lock
       hyprland.lua:   hl.bind("SUPER + L", hl.dsp.exec_cmd("$BIN_DIR/nerv-lock"))

  3. Optional, hypridle.conf:
       general { lock_cmd = $BIN_DIR/nerv-lock }

EOF
