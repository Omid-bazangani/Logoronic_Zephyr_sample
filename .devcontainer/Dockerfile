FROM ubuntu:22.04

# Set non-interactive mode for apt
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    openssh-client \
    cmake \
    ninja-build \
    gperf \
    ccache \
    dfu-util \
    device-tree-compiler \
    wget \
    software-properties-common \
    udev \
    xz-utils \
    file \
    make \
    gcc \
    gcc-multilib \
    g++-multilib \
    libsdl2-dev \
    libmagic1 \
    libusb-1.0-0 \
    curl \
    unzip \
    ca-certificates \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Install Python 3.12 via deadsnakes PPA (Zephyr 4.x requires Python >= 3.12)
RUN add-apt-repository -y ppa:deadsnakes/ppa && \
    apt-get update && apt-get install -y --no-install-recommends \
    python3.12 \
    python3.12-venv \
    python3.12-dev \
    && rm -rf /var/lib/apt/lists/* \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1 \
    && update-alternatives --set python3 /usr/bin/python3.12 \
    && curl -sS https://bootstrap.pypa.io/get-pip.py | python3.12

# Install Zephyr's Python dependencies (jsonschema, pyyaml, pykwalify, west,
# pyelftools, python-magic, pylink-square, etc.), pinned to the same Zephyr
# release used by west.yml so the installed versions match what `west update`
# would check out.
ARG ZEPHYR_VERSION=v4.4.0
RUN mkdir -p /tmp/zephyr-requirements && cd /tmp/zephyr-requirements && \
    for f in requirements.txt requirements-base.txt requirements-build-test.txt \
             requirements-run-test.txt requirements-extras.txt requirements-compliance.txt; do \
        curl -fsSLO "https://raw.githubusercontent.com/zephyrproject-rtos/zephyr/${ZEPHYR_VERSION}/scripts/${f}"; \
    done && \
    pip3 install --no-cache-dir -r requirements.txt && \
    cd / && rm -rf /tmp/zephyr-requirements

# Set the Zephyr SDK version (Zephyr 4.4.x requires SDK 1.0.x)
ENV ZEPHYR_SDK_VERSION=1.0.1

# Download and install the minimal Zephyr SDK bundle, then fetch only the arm-zephyr-eabi toolchain
RUN wget -q "https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${ZEPHYR_SDK_VERSION}/zephyr-sdk-${ZEPHYR_SDK_VERSION}_linux-x86_64_minimal.tar.xz" && \
    tar xf zephyr-sdk-${ZEPHYR_SDK_VERSION}_linux-x86_64_minimal.tar.xz -C /opt && \
    rm zephyr-sdk-${ZEPHYR_SDK_VERSION}_linux-x86_64_minimal.tar.xz && \
    /opt/zephyr-sdk-${ZEPHYR_SDK_VERSION}/setup.sh -t arm-zephyr-eabi

# Set environment variables
ENV ZEPHYR_TOOLCHAIN_VARIANT=zephyr
ENV ZEPHYR_SDK_INSTALL_DIR=/opt/zephyr-sdk-${ZEPHYR_SDK_VERSION}

# ── JLink ───────────────────────────────────────────────────────────────────
# Pin a specific version for reproducible builds.
# To upgrade: change JLINK_VERSION and rebuild the container.
# Find releases at: https://www.segger.com/downloads/jlink/
ARG JLINK_VERSION=V796e
RUN apt-get update && \
    wget -q \
    --post-data 'accept_license_agreement=accepted&non_emb_ctr=confirmed' \
    "https://www.segger.com/downloads/jlink/JLink_Linux_${JLINK_VERSION}_x86_64.deb" \
    -O /tmp/JLink_Linux.deb && \
    # Guard: fail loudly if SEGGER served an HTML page instead of a real package.
    file /tmp/JLink_Linux.deb | grep -q 'Debian binary package' && \
    # The .deb's postinst calls udevadm by ABSOLUTE path (/usr/bin/udevadm),
    # which fails in a container with no udev daemon and aborts apt with exit 100.
    # Overwrite that binary with a no-op for the build. Real udev rules aren't
    # usable in a container anyway; USB access comes from --privileged at runtime.
    printf '#!/bin/sh\nexit 0\n' > /usr/bin/udevadm && chmod +x /usr/bin/udevadm && \
    apt-get install -y --no-install-recommends /tmp/JLink_Linux.deb && \
    rm -f /tmp/JLink_Linux.deb && \
    rm -rf /var/lib/apt/lists/*
# ────────────────────────────────────────────────────────────────────────────

WORKDIR /workspaces/Zephyr_Docker_project

# Set up SSH directory with proper permissions
RUN mkdir -p /root/.ssh && \
    touch /root/.ssh/config && \
    echo -e "Host github.com\n\tStrictHostKeyChecking no\n\tIdentityFile /root/.ssh/id_rsa\n" > /root/.ssh/config && \
    chmod 700 /root/.ssh && \
    chmod 600 /root/.ssh/config && \
    chown root:root /root/.ssh/config

# ── West workspace ───────────────────────────────────────────────────────────
# Initialize west once at image-build time so a freshly built container is
# immediately ready to build, with no manual `west init`/`west update` step.
# `zephyr` (no explicit path in west.yml) and the HAL modules (path:
# modules/hal/...) resolve to /workspaces/zephyr and /workspaces/modules,
# which are siblings of this directory — outside the bind mount that
# replaces /workspaces/Zephyr_Docker_project at runtime — so this checkout
# survives container restarts/recreations.
#
# Caveat: this is a snapshot taken from west.yml at build time. If west.yml
# changes (new module, revision bump), the image must be REBUILT — not just
# reopened/restarted — for `west update` to pick up the change.
COPY west.yml .
RUN west init -l . && \
    west update && \
    west zephyr-export
# ────────────────────────────────────────────────────────────────────────────

# Fix Windows (CRLF) line endings on shell scripts in the bind-mounted
# workspace every time the container starts. See entrypoint.sh for details.
ENV WORKSPACE_DIR=/workspaces/Zephyr_Docker_project
COPY .devcontainer/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]