#!/bin/sh
# Apply the Hyper7s TWRP 14 source overlay without losing the caller's base files.
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DEFAULT_SOURCE_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../../../../.." && pwd)
SOURCE_ROOT=${TWRP_SOURCE:-$DEFAULT_SOURCE_ROOT}
PATCH_ROOT="$SCRIPT_DIR/files"
BACKUP_ROOT="$SCRIPT_DIR/original"
MANIFEST="$SCRIPT_DIR/source-files.txt"
MODE=apply
FORCE=0

usage() {
    cat <<'EOF'
Usage: ./patch.sh [--check] [--force]

Environment:
  TWRP_SOURCE=/path/to/twrp-14  Override the detected TWRP source root.

Options:
  --check  Show whether every source file is patched, original, or locally changed.
  --force  Replace locally changed files after their original backup exists.
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --check) MODE=check ;;
        --force) FORCE=1 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

[ -d "$SOURCE_ROOT" ] || {
    echo "TWRP source root does not exist: $SOURCE_ROOT" >&2
    exit 1
}
[ -f "$MANIFEST" ] || {
    echo "Missing source manifest: $MANIFEST" >&2
    exit 1
}

check_files() {
    status=0
    while IFS= read -r rel || [ -n "$rel" ]; do
        case "$rel" in
            ''|'#'*) continue ;;
        esac
        target="$SOURCE_ROOT/$rel"
        patched="$PATCH_ROOT/$rel"
        backup="$BACKUP_ROOT/$rel"
        if [ ! -f "$target" ]; then
            printf 'missing  %s\n' "$rel"
            status=1
        elif [ ! -f "$patched" ]; then
            printf 'package-missing  %s\n' "$rel"
            status=1
        elif cmp -s "$target" "$patched"; then
            printf 'patched  %s\n' "$rel"
        elif [ -f "$backup" ] && cmp -s "$target" "$backup"; then
            printf 'original  %s\n' "$rel"
            status=1
        else
            printf 'locally-changed  %s\n' "$rel"
            status=1
        fi
    done < "$MANIFEST"
    return "$status"
}

if [ "$MODE" = check ]; then
    check_files
    exit $?
fi

# Validate all inputs before writing the first backup or source file.
while IFS= read -r rel || [ -n "$rel" ]; do
    case "$rel" in
        ''|'#'*) continue ;;
    esac
    [ -f "$SOURCE_ROOT/$rel" ] || {
        echo "Missing source file: $SOURCE_ROOT/$rel" >&2
        exit 1
    }
    [ -f "$PATCH_ROOT/$rel" ] || {
        echo "Missing packaged file: $PATCH_ROOT/$rel" >&2
        exit 1
    }
done < "$MANIFEST"

while IFS= read -r rel || [ -n "$rel" ]; do
    case "$rel" in
        ''|'#'*) continue ;;
    esac
    target="$SOURCE_ROOT/$rel"
    patched="$PATCH_ROOT/$rel"
    backup="$BACKUP_ROOT/$rel"

    if [ ! -f "$backup" ]; then
        if cmp -s "$target" "$patched"; then
            echo "Refusing to create a backup from an already patched file: $rel" >&2
            echo "Restore a pristine source checkout first, or provide the original file in $backup." >&2
            exit 1
        fi
        mkdir -p "$(dirname -- "$backup")"
        cp -p "$target" "$backup"
        printf 'backed up  %s\n' "$rel"
    fi

    if cmp -s "$target" "$patched"; then
        printf 'unchanged  %s\n' "$rel"
        continue
    fi

    if ! cmp -s "$target" "$backup" && [ "$FORCE" -ne 1 ]; then
        echo "Refusing to overwrite a locally changed file: $rel" >&2
        echo "Review it first, or rerun with --force." >&2
        exit 1
    fi

    cp -p "$patched" "$target"
    printf 'patched  %s\n' "$rel"
done < "$MANIFEST"

echo "Hyper7s source overlay applied. Run ./recovery.sh to restore the saved originals."
