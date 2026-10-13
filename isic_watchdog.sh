#!/system/bin/sh
# Watchdog do app Intelbras iSIC Lite.
# Roda como root no tablet. A cada CHECK_INTERVAL segundos:
#  - acorda a tela se estiver apagada
#  - reinicia o app se ele nao estiver em primeiro plano
#  - reinicia o app se a imagem estiver congelada (screenshots identicos;
#    o relogio do OSD da camera muda a cada segundo, entao imagem igual = travado)
#  - reinicia o app a cada MAX_UPTIME segundos por precaucao

PKG=com.intelbras.isiclite
CHECK_INTERVAL=30
FROZEN_LIMIT=2          # checagens seguidas com imagem identica antes de reiniciar
MAX_UPTIME=21600        # reinicio preventivo (6h)
LAUNCH_WAIT=15
FULLSCREEN_X=743        # botao tela cheia (coordenadas em retrato)
FULLSCREEN_Y=705
DIR=/data/local/tmp/isic_watchdog
LOG=$DIR/watchdog.log
SHOT=$DIR/shot.raw

mkdir -p $DIR
echo $$ > $DIR/pid

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> $LOG
    if [ $(wc -c < $LOG) -gt 500000 ]; then
        tail -n 2000 $LOG > $LOG.tmp && mv $LOG.tmp $LOG
    fi
}

rotation() {
    dumpsys window | grep -m1 mCurrentRotation | sed 's/.*=//'
}

screen_on() {
    dumpsys power | grep -q 'Display Power: state=ON'
}

app_focused() {
    dumpsys window windows | grep mCurrentFocus | grep -q $PKG
}

start_app() {
    log "reiniciando app: $1"
    am force-stop $PKG
    sleep 2
    monkey -p $PKG -c android.intent.category.LAUNCHER 1 > /dev/null 2>&1
    sleep $LAUNCH_WAIT
    # rotacao 1 ou 3 = retrato, ou seja, ainda nao esta em tela cheia
    case "$(rotation)" in
        1|3) input tap $FULLSCREEN_X $FULLSCREEN_Y; log "tela cheia acionada" ;;
    esac
    STARTED=$(date +%s)
    FROZEN=0
    LAST_HASH=""
}

log "watchdog iniciado (pid $$)"
sleep 5
STARTED=$(date +%s)
FROZEN=0
LAST_HASH=""
app_focused || start_app "app nao estava aberto"

while true; do
    sleep $CHECK_INTERVAL

    if ! screen_on; then
        log "tela apagada, acordando"
        input keyevent 224
        sleep 2
    fi

    if ! app_focused; then
        start_app "app fora do primeiro plano"
        continue
    fi

    if [ $(( $(date +%s) - STARTED )) -ge $MAX_UPTIME ]; then
        start_app "reinicio preventivo"
        continue
    fi

    screencap $SHOT
    HASH=$(md5sum $SHOT | cut -d' ' -f1)
    rm -f $SHOT
    if [ "$HASH" = "$LAST_HASH" ]; then
        FROZEN=$((FROZEN + 1))
        log "imagem igual a anterior ($FROZEN/$FROZEN_LIMIT)"
        if [ $FROZEN -ge $FROZEN_LIMIT ]; then
            start_app "imagem congelada"
            continue
        fi
    else
        FROZEN=0
    fi
    LAST_HASH=$HASH
done
