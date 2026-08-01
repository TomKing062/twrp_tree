#!/bin/sh
# Restore files saved by patch.sh.
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DEFAULT_SOURCE_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../../../../.." && pwd)
SOURCE_ROOT=${TWRP_SOURCE:-$DEFAULT_SOURCE_ROOT}
BACKUP_ROOT="$SCRIPT_DIR/original"
MANIFEST="$SCRIPT_DIR/source-files.txt"

[ -d "$SOURCE_ROOT" ] || {
    echo "TWRP source root does not exist: $SOURCE_ROOT" >&2
    exit 1
}
[ -f "$MANIFEST" ] || {
    echo "Missing source manifest: $MANIFEST" >&2
    exit 1
}

# Check that restore is complete before replacing any source file.
while IFS= read -r rel || [ -n "$rel" ]; do
    case "$rel" in
        ''|'#'*) continue ;;
    esac
    [ -f "$SOURCE_ROOT/$rel" ] || {
        echo "Missing source file: $SOURCE_ROOT/$rel" >&2
        exit 1
    }
    [ -f "$BACKUP_ROOT/$rel" ] || {
        echo "Missing original backup: $BACKUP_ROOT/$rel" >&2
        echo "Run patch.sh from a pristine source checkout before attempting restore." >&2
        exit 1
    }
done < "$MANIFEST"

while IFS= read -r rel || [ -n "$rel" ]; do
    case "$rel" in
        ''|'#'*) continue ;;
    esac
    cp -p "$BACKUP_ROOT/$rel" "$SOURCE_ROOT/$rel"
    printf 'restored  %s\n' "$rel"
done < "$MANIFEST"

echo "Original TWRP source files restored."
