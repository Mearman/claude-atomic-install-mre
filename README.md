# claude-atomic-install-mre

A minimal reproduction of a bug in the Claude Code native installer where a
partial or interrupted version download leaves a stub that the launcher can't
exec.

## The bug

The Claude Code native installer writes versioned binaries to
`~/.local/share/claude/versions/<version>`. A launcher (shell wrapper, desktop
entry, or internal self-update flow) picks the latest version and `exec`s it.
If the install is interrupted — network drop, killed process, full disk — a stub
file is left at the new version path. The launcher picks the stub and fails:

```
claude: .../versions/2.1.167: Permission denied
claude: exec: .../versions/2.1.167: cannot execute: Undefined error: 0
```

I hit this on macOS on 2026-06-06. The `2.1.167` entry in `versions/` was 0 bytes
with no exec bit; `2.1.166` (the previous working version) was fine.

## Scope: native installer, not npm

The npm package (`@anthropic-ai/claude-code`) does **not** have this bug. Its
`install.cjs` uses a well-designed `placeBinary()` function that hardlinks (or
atomically copies) the platform-specific binary into `bin/claude.exe`, then
`chmodSync(dest, 0o755)` only after the write succeeds. If the write fails, the
old binary (or a restored stub) is left in place. A reader can never see a
half-written, non-executable file.

The native installer is a separate codebase. Its version-write flow is not
visible to us, but the observable effect — a 0-byte, non-executable stub at the
new version path — is consistent with a non-atomic write (open, write, chmod)
without staging or pointer indirection.

This MRE reproduces the *pattern* of failure, not the exact native installer
source (which we don't have).

## How to run

```bash
git clone <this-repo>
cd claude-atomic-install-mre

# Broken pattern: non-atomic install + mtime launcher.
./bug/reproduce.sh

# Fixed pattern: atomic install + current pointer.
./fix/reproduce.sh
```

`bin/claude-fake` is a one-line shell script that prints its version (derived
from its filename). It stands in for the actual Claude binary — the MRE doesn't
need network access or any Anthropic tooling.

## What you'll see

`bug/reproduce.sh` — the launcher picks the stub and exec fails:

```
=== versions dir ===
-rwxr-xr-x  1 user  staff    24  ...  2.1.166   ← working
-rw-r--r--  1 user  staff     0  ...  2.1.167   ← stub from interrupted install

=== launching via mtime-sort launcher ===
.../launcher.sh: line 5: .../2.1.167: Permission denied
exit: 126
```

`fix/reproduce.sh` — same interrupted install, but the launcher uses the
`current` pointer and execs the previous working version:

```
=== versions dir ===
-rwxr-xr-x  1 user  staff    24  ...  2.1.166   ← working
-rw-r--r--  1 user  staff     0  ...  2.1.167   ← stub from interrupted install
lrwxr-xr-x  1 user  staff     7  ...  current -> 2.1.166

=== current pointer ===
2.1.166

=== launching via current-pointer launcher ===
claude-fake v2.1.166
exit: 0
```

The stub is still there in both cases. The difference is whether the launcher
can see it.

## Why the fix works

The pattern is what rustup, mise, asdf, brew, and nvm all do:

1. Stage the new binary to a temp path in the same directory.
2. `chmod +x` the staged file.
3. `rename(2)` into the final version path (atomic on the same filesystem).
4. Update a `current` symlink to point at the new version.

If any step fails, `current` doesn't move and the launcher keeps using the
previous working version. The half-installed stub still exists in the directory
but is structurally invisible to the launcher.

The npm wrapper in `@anthropic-ai/claude-code` already implements this pattern
(see `placeBinary` in `install.cjs`). The native installer should do the same.

## Related

- Windows side of the same root cause: `anthropics/claude-code` #65478 —
  auto-update renames the live binary to `.old` with no atomic fallback, killing
  all concurrent sessions.
- Version locking and concurrent sessions: #65213, #65218.
