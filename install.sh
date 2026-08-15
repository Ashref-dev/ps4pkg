#!/usr/bin/env bash
#
# ps4pkg installer for macOS.
#
#   curl -fsSL https://raw.githubusercontent.com/Ashref-dev/ps4pkg/main/install.sh | bash
#
# Copyright (C) 2026 Achraf Ben Abdallah <https://github.com/Ashref-dev>
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version. See the LICENSE file for the full text.

set -uo pipefail

readonly RAW_URL="https://raw.githubusercontent.com/Ashref-dev/ps4pkg/main/ps4pkg"
readonly BIN_DIR="${PS4PKG_BIN_DIR:-$HOME/.local/bin}"
readonly TARGET="$BIN_DIR/ps4pkg"

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  ON=$'\033[38;5;214m'; DIM=$'\033[38;5;244m'; BAD=$'\033[38;5;203m'
  OK=$'\033[38;5;114m'; R=$'\033[0m'
else
  ON=""; DIM=""; BAD=""; OK=""; R=""
fi

say()  { printf '%s\n' "$*"; }
step() { printf '  %s●%s %s\n' "$ON" "$R" "$*"; }
good() { printf '  %s●%s %s\n' "$OK" "$R" "$*"; }
fail() { printf '\n  %s●%s %s\n\n' "$BAD" "$R" "$*" >&2; exit 1; }

printf '\n  %s● ● ● ●  ps4pkg installer%s\n\n' "$ON" "$R"

[ "$(uname -s)" = "Darwin" ] || fail "This installer is for macOS."

if ! xcode-select -p >/dev/null 2>&1; then
  say "  Apple's command line tools are needed. A dialog will open - click Install,"
  say "  wait for it to finish, then run this installer again."
  xcode-select --install 2>/dev/null
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  fail "Homebrew is required. Install it from https://brew.sh then run this again."
fi

need=()
command -v cmake >/dev/null 2>&1 || need+=("cmake")
brew list zlib >/dev/null 2>&1 || need+=("zlib")
if [ "${#need[@]}" -gt 0 ]; then
  step "Installing: ${need[*]}"
  brew install "${need[@]}" >/dev/null 2>&1 || fail "Could not install: ${need[*]}"
fi
good "Requirements ready"

step "Downloading ps4pkg"
mkdir -p "$BIN_DIR" || fail "Cannot create $BIN_DIR"
if [ -f "./ps4pkg" ] && [ -z "${PS4PKG_FORCE_DOWNLOAD:-}" ]; then
  cp "./ps4pkg" "$TARGET" || fail "Could not copy ps4pkg"
else
  curl -fsSL "$RAW_URL" -o "$TARGET" || fail "Download failed"
fi
chmod +x "$TARGET"
good "Installed to $TARGET"

case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *)
    shell_rc="$HOME/.zshrc"
    [ "${SHELL##*/}" = "bash" ] && shell_rc="$HOME/.bash_profile"
    printf '\nexport PATH="%s:$PATH"\n' "$BIN_DIR" >>"$shell_rc"
    good "Added $BIN_DIR to your PATH in $shell_rc"
    export PATH="$BIN_DIR:$PATH"
    ;;
esac

printf '\n'
step "Building the extraction engine (about a minute)"
printf '\n'
"$TARGET" install || fail "Engine build failed. Run 'ps4pkg doctor' to see what is missing."

printf '  %sAll set. Open a new terminal, then:%s\n\n' "$DIM" "$R"
printf '    ps4pkg extract "YourGame.pkg"\n\n'
