#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/app" || exit 1

copy_artifacts() {
    local dest="$SCRIPT_DIR/_build/$1"
    mkdir -p "$dest"
    cp build/zephyr/zephyr.hex "$dest/$1.hex"
    cp build/zephyr/zephyr.elf "$dest/$1.elf"
    echo "Artifacts copied to $dest"
}

case "$1" in
    b_hciu_logotherm_ble)
        west build -p always -b hciu_logotherm_ble . && copy_artifacts hciu_logotherm_ble
        ;;
    b_hciu_logotherm_main)
        west build -p always -b hciu_logotherm_main . && copy_artifacts hciu_logotherm_main
        ;;
    *)
        echo "Usage: $0 <target>"
        echo "  b_hciu_logotherm_ble   -> west build -p always -b hciu_logotherm_ble ."
        echo "  b_hciu_logotherm_main  -> west build -p always -b hciu_logotherm_main ."
        exit 1
        ;;
esac
