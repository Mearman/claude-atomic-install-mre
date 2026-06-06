#!/bin/bash
# Reproduces the fixed pattern: atomic install + current pointer.
#
# 1. Run a clean install for 2.1.166 (sets current → 2.1.166).
# 2. Simulate an interrupted install for 2.1.167 (leaves stub, current unchanged).
# 3. Launch — the launcher reads current and execs 2.1.166 successfully.
set -e
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
versions_dir="$work/versions"
mkdir -p "$versions_dir"

# Clean initial install.
./fix/install.sh "$versions_dir" 2.1.166 bin/claude-fake

# Simulate the new version's install being interrupted.
# A stub gets left at versions/2.1.167, but `current` still points at 2.1.166.
INSTALL_INTERRUPTED=1 ./fix/install.sh "$versions_dir" 2.1.167 bin/claude-fake || true

echo "=== versions dir ==="
ls -la "$versions_dir"
echo
echo "=== current pointer ==="
readlink "$versions_dir/current"
echo
echo "=== launching via current-pointer launcher ==="
./fix/launcher.sh "$versions_dir" 2>&1 || true
echo
echo "=== exit: $? ==="
echo
echo "The stub at 2.1.167 is invisible to the launcher: current still points"
echo "at 2.1.166, which was installed atomically. The interrupted install never"
echo "reached the ln -sfn step, so the pointer didn't move."
