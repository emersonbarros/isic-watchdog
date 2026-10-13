# isic-watchdog

Watchdog para manter o app **Intelbras iSIC Lite** (`com.intelbras.isiclite`) sempre aberto e mostrando as câmeras em um tablet Android antigo usado como monitor.

O app às vezes trava e para de exibir o vídeo. Este script roda no próprio tablet (como root) e reinicia o app quando necessário.

## O que ele faz

A cada 30 segundos:

- acorda a tela se estiver apagada;
- reinicia o app se ele não estiver em primeiro plano;
- reinicia o app se a imagem estiver congelada — compara screenshots consecutivos; como o relógio do OSD da câmera muda a cada segundo, imagens idênticas significam vídeo travado;
- faz um reinício preventivo a cada 6 horas.

Após reiniciar, toca no botão de tela cheia se o app abriu em retrato.

## Requisitos

- Tablet Android com root via SuperSU (usa `/su/su.d` para iniciar no boot) e `busybox`.
- Depuração USB habilitada e `adb` no computador (Android Studio / platform-tools).

Testado em Samsung Galaxy Tab 10.1 (`p4wifi`), Android 5.1.1, iSIC Lite 2.4.12.

## Arquivos

| Arquivo | Função |
|---|---|
| `isic_watchdog.sh` | O watchdog. Instalado em `/data/local/isic_watchdog.sh`. |
| `99isic_watchdog` | Script de boot do SuperSU (`/su/su.d`) que inicia o watchdog. |
| `install.sh` | Envia os scripts ao tablet via adb e (re)inicia o watchdog. |

## Instalação

Com o tablet conectado por USB:

```sh
./install.sh
```

Também liga "manter tela ligada enquanto carrega" (`stay_on_while_plugged_in=7`).

## Configuração

Variáveis no topo de `isic_watchdog.sh`:

- `CHECK_INTERVAL` — intervalo entre checagens (s);
- `FROZEN_LIMIT` — checagens seguidas com imagem igual antes de reiniciar;
- `MAX_UPTIME` — reinício preventivo (s);
- `FULLSCREEN_X` / `FULLSCREEN_Y` — posição do botão de tela cheia, em coordenadas de retrato.

Depois de editar, rode `./install.sh` de novo.

## Comandos úteis

```sh
ADB=~/Library/Android/sdk/platform-tools/adb

# log
$ADB shell "su -c 'cat /data/local/tmp/isic_watchdog/watchdog.log'"

# parar
$ADB shell "su -c 'kill \$(cat /data/local/tmp/isic_watchdog/pid)'"
```

## Limitações

- Se o app travar mostrando um spinner animado (imagem muda), não é detectado como congelado; só o reinício preventivo resolve.
- A posição do botão de tela cheia é fixa e pode mudar com atualizações do app.
