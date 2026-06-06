#!/bin/bash
# Reproduces the broken pattern: non-atomic install + mtime launcher.
#
# 1. Seed a working old version.
# 2. Run the broken install (leaves a 0-byte stub).
# 3. Launch — the mtime launcher picks the stub and exec fails.
set -e
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
versions_dir="$work/versions"
mkdir -p "$versions_dir"

# Seed an old working version.
cp bin/claude-fake "$versions_dir/2.1.166"
chmod +x "$versions_dir/2.1.166"
sleep 1 # ensure the stub has a newer mtime

# Run the broken install for the new version.
./bug/install.sh "$versions_dir" 2.1.167

echo "=== versions dir ==="
ls -la "$versions_dir"
echo
echo "=== launching via mtime-sort launcher ==="
set +e
./bug/launcher.sh "$versions_dir" 2>&1
rc=$?
set -e
echo "=== exit: $rc ==="
echo
echo "The launcher picked 2.1.167 (newest by mtime) but it's a 0-byte stub"
echo "with no exec bit. exec fails with Permission denied / cannot execute."
exit $rc
