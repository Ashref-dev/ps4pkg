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

# Installs the latest published release, falling back to the main branch if the
# release download is unavailable.
readonly RELEASE_TARBALL="https://github.com/Ashref-dev/ps4pkg/releases/latest/download/ps4pkg.tar.gz"
readonly BRANCH_TARBALL="https://codeload.github.com/Ashref-dev/ps4pkg/tar.gz/refs/heads/main"
readonly APP_DIR="${PS4PKG_APP_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/ps4pkg/app}"
readonly BIN_DIR="${PS4PKG_BIN_DIR:-$HOME/.local/bin}"
readonly LINK="$BIN_DIR/ps4pkg"

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

command -v brew >/dev/null 2>&1 \
  || fail "Homebrew is required. Install it from https://brew.sh then run this again."

need=()
command -v cmake >/dev/null 2>&1 || need+=("cmake")
brew list zlib >/dev/null 2>&1 || need+=("zlib")
if [ "${#need[@]}" -gt 0 ]; then
  step "Installing: ${need[*]}"
  brew install "${need[@]}" >/dev/null 2>&1 || fail "Could not install: ${need[*]}"
fi
good "Requirements ready"

if [ -f "./ps4pkg" ] && [ -d "./vendor" ]; then
  APP_SRC="$(pwd)"
  good "Using the copy in $APP_SRC"
else
  step "Downloading ps4pkg"
  tmp="$(mktemp -d)" || fail "Cannot create a temporary folder"
  trap 'rm -rf "$tmp"' EXIT
  if ! curl -fsSL "$RELEASE_TARBALL" | tar xz -C "$tmp" 2>/dev/null; then
    curl -fsSL "$BRANCH_TARBALL" | tar xz -C "$tmp" || fail "Download failed"
  fi
  extracted="$(find "$tmp" -maxdepth 1 -type d \( -name 'ps4pkg-*' -o -name 'ps4pkg' \) | head -1)"
  [ -z "$extracted" ] && [ -f "$tmp/ps4pkg" ] && extracted="$tmp"
  [ -n "$extracted" ] || fail "Download looked wrong - no ps4pkg folder inside"
  rm -rf "$APP_DIR"
  mkdir -p "$(dirname "$APP_DIR")" || fail "Cannot create $(dirname "$APP_DIR")"
  mv "$extracted" "$APP_DIR" || fail "Could not install into $APP_DIR"
  APP_SRC="$APP_DIR"
  good "Installed to $APP_DIR"
fi

chmod +x "$APP_SRC/ps4pkg"
mkdir -p "$BIN_DIR" || fail "Cannot create $BIN_DIR"
ln -sf "$APP_SRC/ps4pkg" "$LINK"
good "Command available as $LINK"

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
step "Building the extraction engine (about half a minute)"
printf '\n'
"$LINK" install || fail "Engine build failed. Run 'ps4pkg doctor' to see what is missing."

printf '  %sAll set. Open a new terminal, then:%s\n\n' "$DIM" "$R"
printf '    ps4pkg extract "YourGame.pkg"\n\n'
