#!/system/bin/sh

MISC=/dev/block/by-name/misc

i=0
while [ ! -e "$MISC" ] && [ "$i" -lt 50 ]; do
    sleep 0.1
    i=$((i + 1))
done

if [ ! -e "$MISC" ]; then
    echo "clear_recovery_bcb: misc block device not found" > /dev/kmsg
    exit 0
fi

command="$(dd if="$MISC" bs=32 count=1 2>/dev/null | tr -d '\000')"
case "$command" in
    *fastboot*)
        echo "clear_bcb: keeping bootloader_message for fastbootd" > /dev/kmsg
        exit 0
        ;;
esac

dd if=/dev/zero of="$MISC" bs=1 count=832 conv=notrunc 2>/dev/null
sync
echo "clear_bcb: cleared bootloader_message command/status/recovery" > /dev/kmsg
