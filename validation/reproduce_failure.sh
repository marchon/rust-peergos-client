#!/usr/bin/env bash
# Demonstrates the failure on a tree WITHOUT the fix (e.g. upstream 052c018).
# Copies the validation test into TREE, runs it, and EXPECTS it to fail.
set -u
TREE=${1:?usage: reproduce_failure.sh <tree>}
HERE=$(cd "$(dirname "$0")/.." && pwd)
[ "$HERE" -ef "$TREE" ] || cp "$HERE/crates/peergos-fs/tests/mirror_batid_validation.rs" "$TREE/crates/peergos-fs/tests/"
cd "$TREE"
echo "tree: $TREE @ $(git rev-parse --short HEAD)"
cargo test -q -p peergos-fs --test mirror_batid_validation -- --nocapture 2>&1 | grep -E "mirror id|BatId.sha256|calculate_id|Invalid BAT|test result"
if [ "${PIPESTATUS[0]}" -ne 0 ]; then echo "REPRODUCED: mirror BAT id fails the Java server check"; exit 0
else echo "NOT REPRODUCED: this tree already passes the check"; exit 1; fi
