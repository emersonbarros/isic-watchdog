#!/bin/sh
# Instala/atualiza o watchdog no tablet e o inicia sem precisar reiniciar.
set -e
ADB=${ADB:-$HOME/Library/Android/sdk/platform-tools/adb}
cd "$(dirname "$0")"
$ADB push isic_watchdog.sh /data/local/tmp/isic_watchdog.sh
$ADB push 99isic_watchdog /data/local/tmp/99isic_watchdog
$ADB shell "su -c '
    cp /data/local/tmp/isic_watchdog.sh /data/local/isic_watchdog.sh
    chmod 755 /data/local/isic_watchdog.sh
    cp /data/local/tmp/99isic_watchdog /su/su.d/99isic_watchdog
    chmod 700 /su/su.d/99isic_watchdog
    rm /data/local/tmp/isic_watchdog.sh /data/local/tmp/99isic_watchdog
    settings put global stay_on_while_plugged_in 7
    [ -f /data/local/tmp/isic_watchdog/pid ] && kill \$(cat /data/local/tmp/isic_watchdog/pid) 2>/dev/null
    busybox nohup busybox setsid /system/bin/sh /data/local/isic_watchdog.sh < /dev/null > /dev/null 2>&1 &
    sleep 2
'"
echo "Watchdog instalado e rodando."
