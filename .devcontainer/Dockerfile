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
    python3-pip \
    python3-setuptools \
    python3-wheel \
    python3-dev \
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
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN pip3 install --no-cache-dir \
    west \
    pyelftools \
    python-magic \
    pylink-square

# Set the Zephyr SDK version
ENV ZEPHYR_SDK_VERSION=0.17.0

# Download and install the complete Zephyr SDK
RUN wget -q "https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${ZEPHYR_SDK_VERSION}/zephyr-sdk-${ZEPHYR_SDK_VERSION}_linux-x86_64.tar.xz" && \
    tar xf zephyr-sdk-${ZEPHYR_SDK_VERSION}_linux-x86_64.tar.xz -C /opt && \
    rm zephyr-sdk-${ZEPHYR_SDK_VERSION}_linux-x86_64.tar.xz && \
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

CMD ["/bin/bash"]