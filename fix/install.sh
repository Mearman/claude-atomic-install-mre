#!/bin/bash
# Fixed installer: atomic install with a current-version pointer.
#
# Stage to a temp path in the same directory, chmod +x on the staged file,
# then rename into the final location (atomic on the same filesystem).
# Update the `current` symlink last — if anything above fails, current
# still points at the previous working version.
#
# This is the pattern used by rustup, mise, asdf, brew, nvm, and the
# npm wrapper in @anthropic-ai/claude-code (see install.cjs / placeBinary).
#
# If INSTALL_INTERRUPTED=1, simulate the install being killed before
# the temp file is written — leaves a stub at the version path but
# never touches `current`.
set -e
versions_dir="$1"
version="$2"
binary="$3"
mkdir -p "$versions_dir"

if [[ "${INSTALL_INTERRUPTED:-0}" == "1" ]]; then
  # Simulate an interrupted install: the native installer starts writing
  # but dies. A stub may or may not exist at the version path — doesn't
  # matter, because `current` is never updated.
  touch "$versions_dir/$version"
  exit 1
fi

# Stage to a temp path (same dir = same filesystem = atomic rename).
tmp="$versions_dir/.${version}.tmp.${RANDOM}"
cp "$binary" "$tmp"
chmod +x "$tmp"
mv -f "$tmp" "$versions_dir/$version"

# Update the pointer last. Half-installed stubs are invisible to the launcher
# because this step only runs after the full write + chmod succeeds.
ln -sfn "$version" "$versions_dir/current"
