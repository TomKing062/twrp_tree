#!/system/bin/sh

PATH=/system/bin:/system/xbin:/sbin:/vendor/bin
LOG=/tmp/recovery-usbfix.log
G=/config/usb_gadget/g1
ADB_FFS=/dev/usb-ffs/adb

log_msg() {
    echo "usbfix: $*" >> "$LOG" 2>/dev/null
}

write_node() {
    node="$1"
    value="$2"
    [ -e "$node" ] || return 1
    old="$(cat "$node" 2>/dev/null)"
    echo "$value" > "$node" 2>>"$LOG"
    rc=$?
    new="$(cat "$node" 2>/dev/null)"
    log_msg "write $node '$value' rc=$rc old='$old' new='$new'"
    return $rc
}

poke_device_role() {
    for node in /sys/class/usb_role/*/role /sys/class/typec/*/data_role /sys/class/typec/*-partner/data_role; do
        write_node "$node" device
    done

    for node in /sys/devices/platform/*usb*/role /sys/devices/platform/*/*usb*/role /sys/devices/platform/soc/*usb*/role /sys/devices/platform/soc/*/*usb*/role; do
        write_node "$node" device
    done

    for node in /sys/devices/platform/*usb*/mode /sys/devices/platform/*/*usb*/mode /sys/devices/platform/soc/*usb*/mode /sys/devices/platform/soc/*/*usb*/mode; do
        write_node "$node" peripheral
    done
}

prepare_adb_gadget() {
    mkdir -p /config
    mount -t configfs none /config 2>/dev/null

    mkdir -p "$G"
    mkdir -p "$G/strings/0x409"
    mkdir -p "$G/configs/b.1"
    mkdir -p "$G/configs/b.1/strings/0x409"
    mkdir -p "$G/functions/ffs.adb"
    mkdir -p "$ADB_FFS"

    SERIAL="$(getprop ro.serialno)"
    [ -z "$SERIAL" ] && SERIAL="$(getprop ro.boot.serialno)"
    [ -z "$SERIAL" ] && SERIAL=0123456789ABCDEF

    MANUFACTURER="$(getprop ro.product.manufacturer)"
    [ -z "$MANUFACTURER" ] && MANUFACTURER=nubia

    PRODUCT="$(getprop ro.product.model)"
    [ -z "$PRODUCT" ] && PRODUCT=P780F01

    echo "" > "$G/UDC" 2>>"$LOG"
    setprop sys.usb.config none

    for link in "$G"/configs/b.1/f1 "$G"/configs/b.1/f2 "$G"/configs/b.1/f3 "$G"/configs/b.1/f4 "$G"/configs/b.1/f5 "$G"/configs/b.1/f6 "$G"/configs/b.1/f7 "$G"/configs/b.1/f8 "$G"/configs/b.1/f9 "$G"/configs/b.1/f10 "$G"/configs/b.1/f11; do
        rm -f "$link" 2>/dev/null
    done

    echo 0x18D1 > "$G/idVendor" 2>/dev/null
    echo 0xD001 > "$G/idProduct" 2>/dev/null
    echo 0x0404 > "$G/bcdDevice" 2>/dev/null
    echo 0 > "$G/bDeviceClass" 2>/dev/null
    echo "$SERIAL" > "$G/strings/0x409/serialnumber" 2>/dev/null
    echo "$MANUFACTURER" > "$G/strings/0x409/manufacturer" 2>/dev/null
    echo "$PRODUCT" > "$G/strings/0x409/product" 2>/dev/null
    echo 120 > "$G/configs/b.1/MaxPower" 2>/dev/null
    echo adb > "$G/configs/b.1/strings/0x409/configuration" 2>/dev/null

    mount -t functionfs adb "$ADB_FFS" -o uid=2000,gid=2000 2>/dev/null
    ln -s "$G/functions/ffs.adb" "$G/configs/b.1/f1" 2>/dev/null

    setprop sys.usb.configfs 1
    setprop service.adb.root 1
    setprop ctl.start adbd
    setprop sys.usb.config adb
}

try_bind() {
    name="$1"
    [ -n "$name" ] || return 1
    [ -e "/sys/class/udc/$name" ] || return 1
    echo "" > "$G/UDC" 2>>"$LOG"
    setprop sys.usb.controller "$name"
    echo "$name" > "$G/UDC" 2>>"$LOG"
    rc=$?
    current="$(cat "$G/UDC" 2>/dev/null)"
    log_msg "bind '$name' rc=$rc current='$current'"
    if [ "$current" = "$name" ]; then
        setprop sys.usb.state adb
        return 0
    fi
    return 1
}

log_state() {
    log_msg "round $1 config=$(getprop sys.usb.config) state=$(getprop sys.usb.state) ffs=$(getprop sys.usb.ffs.ready) ctl=$(getprop sys.usb.controller) adbd=$(getprop init.svc.adbd)"
    log_msg "udc_list=$(ls /sys/class/udc 2>/dev/null) current_udc=$(cat "$G/UDC" 2>/dev/null)"
    log_msg "ffs_nodes=$(ls "$ADB_FFS" 2>/dev/null)"
}

wait_for_ffs() {
    for i in 1 2 3 4 5; do
        [ "$(getprop sys.usb.ffs.ready)" = "1" ] && return 0
        [ -e "$ADB_FFS/ep1" ] && return 0
        sleep 1
    done
    return 1
}

adb_ready() {
    current="$(cat "$G/UDC" 2>/dev/null)"
    [ -n "$current" ] || return 1
    [ "$(getprop sys.usb.state)" = "adb" ] || return 1
    [ "$(getprop init.svc.adbd)" = "running" ] || return 1
    return 0
}

repair_adb() {
    round="$1"
    reason="$2"
    log_msg "repair $round reason='$reason'"
    poke_device_role
    prepare_adb_gadget

    wait_for_ffs

    for candidate in /sys/class/udc/*; do
        [ -e "$candidate" ] || continue
        if try_bind "${candidate##*/}"; then
            log_state "$round-bound"
            return 0
        fi
    done

    return 1
}

log_msg "start adb-monitor"
setenforce 0 2>/dev/null
setprop service.adb.root 1

config="$(getprop sys.usb.config)"
case "$config" in
    mtp|mtp,adb|ptp|ptp,adb|fastboot|sideload)
        log_msg "skip initial repair for config='$config'"
        ;;
    *)
        setprop sys.usb.config adb
        repair_adb initial "service-start"
        ;;
esac

for round in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 \
    21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 \
    41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 \
    61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 \
    81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 \
    101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120; do
    config="$(getprop sys.usb.config)"
    state="$(getprop sys.usb.state)"
    adbd="$(getprop init.svc.adbd)"
    current="$(cat "$G/UDC" 2>/dev/null)"

    case "$config" in
        mtp|mtp,adb|ptp|ptp,adb|fastboot|sideload)
            log_msg "skip $round config='$config'"
            sleep 2
            continue
            ;;
    esac

    if adb_ready && [ "$config" = "adb" ]; then
        case "$round" in
            1|5|10|20|40|80|120) log_state "$round-ok" ;;
        esac
        sleep 2
        continue
    fi

    log_state "$round-before-repair"
    repair_adb "$round" "config=$config state=$state adbd=$adbd current=$current"
    sleep 2
done

log_msg "monitor finished"
dmesg | grep -iE 'usb|dwc|udc|gadget|ffs|adb|typec|extcon' | tail -n 160 >> "$LOG" 2>/dev/null
