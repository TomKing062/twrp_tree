#!/system/bin/sh
# Remove first-stage logical-partition mappings before fastbootd recreates them.

PATH=/system/bin:/sbin
LOG=/tmp/fastbootd-unmap.log
SLOT_SUFFIX=$(getprop ro.boot.slot_suffix)

[ -n "$SLOT_SUFFIX" ] || SLOT_SUFFIX=_a

echo "Preparing fastbootd for slot $SLOT_SUFFIX" > "$LOG"

for MOUNT_POINT in /system /system_ext /vendor /odm /product /vendor_dlkm /system_dlkm; do
    if grep -q " $MOUNT_POINT " /proc/mounts; then
        echo "Unmounting $MOUNT_POINT" >> "$LOG"
        umount "$MOUNT_POINT" >> "$LOG" 2>&1 || exit 1
    fi
done

for PARTITION in system system_ext vendor odm product vendor_dlkm system_dlkm; do
    NAME="${PARTITION}${SLOT_SUFFIX}"
    if [ -e "/dev/block/mapper/$NAME" ]; then
        echo "Deleting $NAME" >> "$LOG"
        dmctl delete "$NAME" >> "$LOG" 2>&1 || exit 1
    fi
done

exit 0
