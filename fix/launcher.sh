#!/bin/bash
# Fixed launcher: exec the binary pointed to by `current`.
#
# No version picking, no mtime sort, no executable filter. If `current`
# exists, it points at a fully-installed binary by construction — the
# installer only updates `current` after a successful atomic rename + chmod.
set -e
versions_dir="$1"
shift
exec "$versions_dir/current" "$@"
