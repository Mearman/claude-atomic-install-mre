#!/bin/bash
# Simulates the native installer's non-atomic install.
#
# The real native installer (or its self-update flow) writes the binary
# directly to versions/<version>. If the process is interrupted between
# creating the file and finishing the write (network drop, kill, full disk),
# a stub remains: 0 bytes, no exec bit. The mtime-based launcher picks it
# because it's the newest entry.
set -e
versions_dir="$1"
version="$2"
mkdir -p "$versions_dir"
# Touch creates the stub. No write, no chmod — exactly the state observed at
# ~/.local/share/claude/versions/2.1.167 on 2026-06-06.
touch "$versions_dir/$version"
