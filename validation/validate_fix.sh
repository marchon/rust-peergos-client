#!/usr/bin/env bash
# Validates the resolution on a tree WITH the fix (fix/mirror-batid-sha256).
# Copies the validation test into TREE, runs it, and EXPECTS it to pass.
set -u
TREE=${1:?usage: validate_fix.sh <tree>}
HERE=$(cd "$(dirname "$0")/.." && pwd)
[ "$HERE" -ef "$TREE" ] || cp "$HERE/crates/peergos-fs/tests/mirror_batid_validation.rs" "$TREE/crates/peergos-fs/tests/"
cd "$TREE"
echo "tree: $TREE @ $(git rev-parse --short HEAD)"
cargo test -q -p peergos-fs --test mirror_batid_validation -- --nocapture 2>&1 | grep -E "mirror id|BatId.sha256|calculate_id|Invalid BAT|test result"
if [ "${PIPESTATUS[0]}" -eq 0 ]; then echo "RESOLVED: mirror BAT id passes the Java server check"; exit 0
else echo "FAILED: mirror BAT id still fails the check"; exit 1; fi
