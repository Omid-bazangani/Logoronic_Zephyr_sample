#!/bin/bash
# Flash a pre-built image to the target board via JLink.
#
# Usage:
#   ./flash.sh b_hciu_logotherm_main
#   ./flash.sh b_hciu_logotherm_ble
#
# Connection is chosen automatically:
#   USB  — JLink forwarded into WSL 2 via usbipd-win (see README)
#   TCP  — JLink Remote Server running on the Windows host (see README)
#           This is the recommended fallback when usbipd-win is not set up.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

do_flash() {
    local target="$1"       # e.g. hciu_logotherm_main
    local device="$2"       # e.g. STM32F413ZG
    local speed="$3"        # e.g. 100
    local hex="$SCRIPT_DIR/_build/$target/$target.hex"
    local jlink_script="$SCRIPT_DIR/_build/$target/flash.jlink"

    if [ ! -f "$hex" ]; then
        echo "ERROR: $hex not found — run ./build.sh first."
        exit 1
    fi

    if ! command -v JLinkExe &>/dev/null; then
        echo "ERROR: JLinkExe not found. Rebuild the dev container."
        exit 1
    fi

    # ── Detect connection mode ──────────────────────────────────────────────
    # Prefer USB if the JLink appears on the USB bus, otherwise fall back to
    # TCP via JLink Remote Server on the Windows host.
    #
    # The Windows host IP is auto-detected from /etc/resolv.conf (works when
    # the container uses --network=host and WSL2 sets the nameserver).
    # Override at any time:  JLINK_HOST=192.168.1.x ./flash.sh <target>
    local connection_cmd=""
    if ls /dev/bus/usb/*/*  &>/dev/null 2>&1; then
        echo "-- USB device detected, connecting via USB"
    else
        # Auto-detect Windows host IP
        local jlink_host="${JLINK_HOST:-}"
        if [ -z "$jlink_host" ]; then
            jlink_host=$(grep nameserver /etc/resolv.conf 2>/dev/null \
                         | awk '{print $2}' | grep -v '^10\.255\.' | head -1)
        fi
        if [ -z "$jlink_host" ]; then
            jlink_host="host.docker.internal"
        fi
        echo "-- No USB device found, connecting via TCP to JLink Remote Server at $jlink_host"
        echo "   (override with: JLINK_HOST=<ip> ./flash.sh $1)"
        connection_cmd="ip $jlink_host"
    fi

    # ── Write JLink Commander script ───────────────────────────────────────
    cat > "$jlink_script" <<EOF
${connection_cmd}
si SWD
speed $speed
device $device
connect
h
loadfile "$hex"
r
g
q
EOF

    echo "-- Flashing $target ($device) at $speed kHz..."
    JLinkExe -NoGui 1 -CommandFile "$jlink_script"
    local rc=$?
    if [ $rc -eq 0 ]; then
        echo "-- Flash complete."
    else
        echo ""
        echo "-- Flash failed (exit $rc). If using TCP mode, verify that"
        echo "   JLinkRemoteServer.exe is running on your Windows host."
        echo "   If using USB mode, run: usbipd attach --wsl --busid <ID>"
        echo "   then restart the dev container."
        exit $rc
    fi
}

case "$1" in
    b_hciu_logotherm_main)
        do_flash "hciu_logotherm_main" "STM32F413ZG" "100"
        ;;
    b_hciu_logotherm_ble)
        do_flash "hciu_logotherm_ble" "nRF52833_xxAA" "100"
        ;;
    *)
        echo "Usage: $0 <target>"
        echo "  b_hciu_logotherm_main   -> STM32F413ZG   via JLink SWD 100 kHz"
        echo "  b_hciu_logotherm_ble    -> nRF52833_xxAA via JLink SWD 100 kHz"
        exit 1
        ;;
esac


SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/app" || exit 1
