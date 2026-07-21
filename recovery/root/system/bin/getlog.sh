#!/sbin/sh

# ========= Target directory =========
BASE=/sdcard/TWRP

# If sdcard is not available, fallback
if [ ! -d /sdcard ]; then
    BASE=/cache/TWRP
fi

mkdir -p $BASE

# ========= Log files =========
DMESG_LOG=$BASE/dmesg_full.txt
LOGCAT_LOG=$BASE/logcat_full.txt
REC_LOG=$BASE/recovery_full.txt
SELF_LOG=$BASE/self_log.txt
MAIN_LOG=$BASE/system_snapshot.txt

echo "==== FULL DUMP START ====" > $SELF_LOG
echo "time: $(date)" >> $SELF_LOG
echo "base=$BASE" >> $SELF_LOG

# ========= Prevent duplicate runs =========
echo $$ > /cache/full_dump.pid 2>/dev/null

# ========= 1. Full dmesg =========
(
    echo "===== DMESG START $(date) ====="
    dmesg -w
) >> $DMESG_LOG 2>> $SELF_LOG &

echo "dmesg pid=$!" >> $SELF_LOG

# ========= 2. Full logcat =========
(
    echo "===== LOGCAT START $(date) ====="
    logcat -b all -v threadtime
) >> $LOGCAT_LOG 2>> $SELF_LOG &

echo "logcat pid=$!" >> $SELF_LOG

# ========= 3. Recovery.log mirror =========
(
    while true; do
        if [ -f /tmp/recovery.log ]; then
            echo "===== recovery.log $(date) ====="
            cat /tmp/recovery.log
        fi
        sleep 3
    done
) >> $REC_LOG 2>> $SELF_LOG &

echo "recovery watcher pid=$!" >> $SELF_LOG

# ========= 4. Main loop (system state snapshots) =========
COUNT=0

while true; do
    COUNT=$((COUNT + 1))

    echo "============================" >> $MAIN_LOG
    echo "loop=$COUNT time=$(date)" >> $MAIN_LOG
    echo "============================" >> $MAIN_LOG

    echo "[mount]" >> $MAIN_LOG
    mount >> $MAIN_LOG 2>> $SELF_LOG

    echo "[ps]" >> $MAIN_LOG
    ps >> $MAIN_LOG 2>> $SELF_LOG

    echo "[getprop]" >> $MAIN_LOG
    getprop >> $MAIN_LOG 2>> $SELF_LOG

    sync
    sleep 5
done