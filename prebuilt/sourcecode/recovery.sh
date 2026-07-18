#!/bin/bash
# recovery.sh - Restore original files from patch/backup directory

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCH_SRC="$SCRIPT_DIR/patch"
BACKUP_DIR="$PATCH_SRC/backup"
SOURCE_ROOT="$(cd "$SCRIPT_DIR/../../../../.." && pwd)"

if [ ! -d "$BACKUP_DIR" ]; then
    echo "Error: Backup directory $BACKUP_DIR does not exist, cannot restore."
    exit 1
fi

echo "=========================================="
echo "Restoring from backup: $BACKUP_DIR"
echo "Target source root: $SOURCE_ROOT"
echo "=========================================="

cd "$BACKUP_DIR"
find . -type f | while read -r file; do
    rel_path="${file#./}"
    target_file="$SOURCE_ROOT/$rel_path"
    backup_file="$BACKUP_DIR/$rel_path"

    if [ -f "$backup_file" ]; then
        mkdir -p "$(dirname "$target_file")"
        cp "$backup_file" "$target_file"
        echo "Restored: $rel_path"
    else
        echo "Warning: Backup file $backup_file does not exist, skipping"
    fi
done

echo "Restore completed."
# Optional: delete backup directory (uncomment next line to auto-clean)
# rm -rf "$BACKUP_DIR"