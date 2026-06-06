#!/bin/bash
# Simulates a launcher that picks the latest version by mtime.
#
# This is the pattern used in a custom dotfiles wrapper (~/.dotfiles/bin/.local/bin/claude)
# that targets the native installer's layout at ~/.local/share/claude/versions/.
# mtime sort is the wrong signal: a just-touched stub is "newer" than a working
# binary from yesterday.
set -e
versions_dir="$1"
shift
latest=$(ls -1t "$versions_dir" | head -1)
exec "$versions_dir/$latest" "$@"
