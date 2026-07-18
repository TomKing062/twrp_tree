#!/bin/bash
# patch.sh - Overwrite files from patch/ directory to source root, and backup original files to patch/backup/

set -e

# Get absolute path of the script directory (i.e., prebuilt/sourcecode)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Patch source directory (the patch subdirectory)
PATCH_SRC="$SCRIPT_DIR/patch"

# Source root directory (up 5 levels: sourcecode -> twrp_12 root)
SOURCE_ROOT="$(cd "$SCRIPT_DIR/../../../../.." && pwd)"

# Backup directory (under patch/backup)
BACKUP_DIR="$PATCH_SRC/backup"

echo "=========================================="
echo "Patch source dir: $PATCH_SRC"
echo "Source root dir: $SOURCE_ROOT"
echo "Backup dir: $BACKUP_DIR"
echo "=========================================="

# Check if patch source directory exists
if [ ! -d "$PATCH_SRC" ]; then
    echo "Error: Patch source directory $PATCH_SRC does not exist!"
    exit 1
fi

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Traverse all files under patch/ (excluding backup directory itself)
cd "$PATCH_SRC"
find . -type f -not -path "./backup/*" | while read -r file; do
    # Remove leading "./"
    rel_path="${file#./}"
    target_file="$SOURCE_ROOT/$rel_path"
    backup_file="$BACKUP_DIR/$rel_path"

    # If the file exists in source, backup
    if [ -f "$target_file" ]; then
        mkdir -p "$(dirname "$backup_file")"
        cp "$target_file" "$backup_file"
        echo "Backed up: $rel_path"
    else
        echo "Warning: $rel_path not found in source, will overwrite without backup"
    fi
done

# Copy patch files to source root (overwrite)
echo "Applying patches..."
if command -v rsync &> /dev/null; then
    rsync -av --exclude='backup' "$PATCH_SRC"/ "$SOURCE_ROOT"/
else
    cd "$PATCH_SRC"
    find . -type f -not -path "./backup/*" | while read -r file; do
        rel_path="${file#./}"
        target_file="$SOURCE_ROOT/$rel_path"
        mkdir -p "$(dirname "$target_file")"
        cp "$file" "$target_file"
        echo "Overwrote: $rel_path"
    done
fi

echo "Patch applied successfully."
echo "Original files backed up to $BACKUP_DIR"