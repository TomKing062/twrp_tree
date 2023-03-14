#!/system/bin/sh

load()
{
        mkdir /s
        mkdir /v
        mount -t ext4 -o ro /dev/block/by-name/socko /s
        mount -t ext4 -o ro /dev/block/by-name/vendor /v
        mkdir -p /vendor/lib/modules
        cp /s/*.ko /vendor/lib/modules/
        cp -a /v/firmware /vendor/
        wait 1
        insmod /vendor/lib/modules/synaptics_dsx_td4310.ko
        insmod /vendor/lib/modules/synaptics_td4320_spi_ts.ko
        umount /s
        umount /v
        rmdir /s
        rmdir /v
}

load
wait 1

setprop modules.loaded 1

exit 0
