# Zephyr Docker Project

## Setup Instructions

### Option 1: Using VS Code Dev Container (Recommended)

1. Clone this repository:
```bash
git clone <your-repository-url>
cd Zephyr_Docker_project
```

2. Open the project in VS Code with Dev Containers extension installed.

3. Click "Reopen in Container" when prompted, or run the "Dev Containers: Reopen in Container" command.
   The image build runs `west init`/`west update`/`west zephyr-export` automatically, so the
   container is ready to build as soon as it starts — no manual west step needed.
   > If you change `west.yml` (new module, revision bump), you must **rebuild** the container
   > (`Dev Containers: Rebuild Container`), not just reopen it, for `west update` to pick up the change.

4. Build the project:
```bash
# Main processor (STM32F413ZG)
./build.sh b_hciu_logotherm_main
```

5. Flash the project:
```bash
./flash.sh b_hciu_logotherm_main
```

See **Flashing** below for JLink connection setup.

---

## Flashing

`flash.sh` uses SEGGER JLink (already installed in the container) and auto-detects
the connection mode on every run:

| Mode | When used | What to do on Windows |
|------|-----------|----------------------|
| **USB** | JLink USB device forwarded into WSL 2 | `usbipd attach --wsl --busid <ID>` |
| **TCP** | No USB device found | Start `JLinkRemoteServer.exe` on Windows |

### Option A — TCP via JLink Remote Server (easiest, no extra install)

1. On your Windows machine, open a terminal and run:
   ```
   "C:\Program Files\SEGGER\JLink_V924a\JLinkRemoteServer.exe"
   ```
   The window shows a **Client connection string** like `ip 192.168.96.1` — that is
   the IP the container will connect to automatically. Leave the window open.

2. **Rebuild the dev container once** so the `--network=host` setting takes effect:
   VS Code → `Ctrl+Shift+P` → *Dev Containers: Rebuild Container*

3. Inside the container, build and flash normally:
   ```bash
   ./build.sh b_hciu_logotherm_main && ./flash.sh b_hciu_logotherm_main
   ```
   The script reads the Windows host IP from `/etc/resolv.conf` automatically.

   > If auto-detection picks the wrong IP, override it once:
   > ```bash
   > JLINK_HOST=192.168.96.1 ./flash.sh b_hciu_logotherm_main
   > ```

### Option B — USB via usbipd-win (fully self-contained, no Windows process needed)

1. Install **usbipd-win** on Windows:
   https://github.com/dorssel/usbipd-win/releases

2. In an **elevated** Windows PowerShell, before each session:
   ```powershell
   usbipd list                        # find the JLink bus ID, e.g. 2-3
   usbipd attach --wsl --busid 2-3    # forward JLink into WSL 2
   ```

3. Rebuild the dev container once (so Docker picks up the USB volume mount):
   VS Code → `Ctrl+Shift+P` → *Dev Containers: Rebuild Container*

4. After that, `./flash.sh` connects directly via USB with no Windows-side steps
   beyond the `usbipd attach` command.

---

### Option 2: Using Docker Directly

1. Clone this repository as above.

2. Build and run the dev container:
```bash
# Note: context is the project root (".") so the Dockerfile can COPY west.yml
docker build -t zephyr-dev -f .devcontainer/Dockerfile .
docker run -it --privileged -v /dev/bus/usb:/dev/bus/usb \
    -v ${PWD}:/workspaces/Zephyr_Docker_project zephyr-dev
```

3. Follow steps 4–5 from Option 1.


