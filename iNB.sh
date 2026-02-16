#!/bin/sh
##Command=wget https://github.com/emilnabil/neoboot-all/raw/refs/heads/main/iNB.sh -O - | /bin/sh
##################################
set -e

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: This script must be run as root!"
    exit 1
fi

if [ -f /etc/apt/apt.conf ] && command -v systemctl >/dev/null 2>&1; then
    OS="DreamOS"
    PKG_MANAGER="apt-get"
    INSTALL_CMD="apt-get install -y"
else
    OS="OpenSource"
    PKG_MANAGER="opkg"
    INSTALL_CMD="opkg install --force-overwrite"
fi

echo "==============================================="
echo "              NeoBoot Installer"
echo "==============================================="
echo "Detected OS: $OS"

install_package() {
    pkg=$1
    echo "Attempting to install $pkg using $PKG_MANAGER..."
    if [ "$PKG_MANAGER" = "apt-get" ]; then
        apt-get update
        $INSTALL_CMD "$pkg"
    elif [ "$PKG_MANAGER" = "opkg" ]; then
        opkg update
        $INSTALL_CMD "$pkg"
    else
        echo "ERROR: No known package manager found!"
        return 1
    fi
}

check_tool() {
    tool=$1
    pkg=${2:-$1}
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "WARNING: $tool not found. Attempting to install..."
        install_package "$pkg" || {
            echo "ERROR: Failed to install $tool. Please install it manually."
            exit 1
        }
    fi
}

check_tool wget
check_tool tar
check_tool curl || true

DOWNLOADER="wget --no-check-certificate --timeout=30"
if ! command -v wget >/dev/null 2>&1 && command -v curl >/dev/null 2>&1; then
    DOWNLOADER="curl -L -k --connect-timeout 30 -o"
fi

if [ -e /.multinfo ]; then
    echo "ERROR: Install NeoBoot only from FLASH image!"
    exit 1
fi

URL="https://github.com/emilnabil/neoboot-all/raw/refs/heads/main/neoboot_9.95.tar.gz"
FILE="/tmp/neoboot_9.95.tar.gz"

echo "Downloading NeoBoot..."

cd /tmp
rm -f "$FILE"

if echo "$DOWNLOADER" | grep -q wget; then
    $DOWNLOADER "$URL" -O "$FILE" || {
        echo "ERROR: Download failed (wget error)!"
        rm -f "$FILE"
        exit 1
    }
elif echo "$DOWNLOADER" | grep -q curl; then
    $DOWNLOADER "$FILE" "$URL" || {
        echo "ERROR: Download failed (curl error)!"
        rm -f "$FILE"
        exit 1
    }
else
    echo "ERROR: No download tool available!"
    exit 1
fi

if [ ! -s "$FILE" ]; then
    echo "ERROR: Downloaded file is missing or empty!"
    rm -f "$FILE"
    exit 1
fi

echo "Extracting package..."

if ! tar -xzf "$FILE" -C /; then
    echo "ERROR: Extraction failed!"
    rm -f "$FILE"
    exit 1
fi

rm -f "$FILE"

echo "NeoBoot installed successfully."

sleep 2

echo "Rebooting system..."

reboot

exit 0


