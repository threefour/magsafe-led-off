#!/bin/bash
#
# MagSafe LED Off for Apple Silicon Macs
#
# Double-click this file in Finder to install.
# It installs the open-source "batt" helper and configures its
# MagSafe LED control to force the LED off.
#
# IMPORTANT:
# - This changes the MagSafe LED only. It does not set a charge limit.
# - macOS 27 / 20xxx firmware may prevent third-party software from
#   controlling the LED.
#

set -u

BATT_INSTALL_URL="https://github.com/charlie0129/batt/raw/master/hack/install.sh"

printf "\n"
printf "========================================\n"
printf "   MagSafe LED Off Installer\n"
printf "========================================\n\n"

# Must be Apple Silicon.
ARCH="$(uname -m)"
if [ "$ARCH" != "arm64" ]; then
    echo "This Mac reports architecture: $ARCH"
    echo "This installer is intended for Apple Silicon Macs."
    echo
    read -r -p "Press Return to close..."
    exit 1
fi

echo "Apple Silicon detected."

# Require macOS.
OS_MAJOR="$(sw_vers -productVersion | awk -F. '{print $1}')"
OS_VERSION="$(sw_vers -productVersion)"
echo "macOS $OS_VERSION detected."
echo

# Warn about the current known firmware limitation.
if [ "$OS_MAJOR" -ge 27 ]; then
    echo "WARNING:"
    echo "Your macOS version is 27 or newer."
    echo "Current versions of batt report that direct MagSafe LED control"
    echo "is unavailable on macOS 27 / 20xxx firmware."
    echo
    echo "The installer will continue, but the LED may not respond."
    echo
fi

# Check for curl.
if ! command -v curl >/dev/null 2>&1; then
    echo "ERROR: curl is not available on this Mac."
    read -r -p "Press Return to close..."
    exit 1
fi

# Check whether batt is already installed.
BATT=""
for candidate in \
    "$(command -v batt 2>/dev/null || true)" \
    "/usr/local/bin/batt" \
    "/opt/homebrew/bin/batt"
do
    if [ -n "$candidate" ] && [ -x "$candidate" ]; then
        BATT="$candidate"
        break
    fi
done

if [ -n "$BATT" ]; then
    echo "Found batt at:"
    echo "  $BATT"
    echo
else
    echo "Installing batt..."
    echo "You will be asked for your Mac administrator password."
    echo

    # Download and execute the project's official installation script.
    if ! /bin/bash -c "$(curl -fsSL "$BATT_INSTALL_URL")"; then
        echo
        echo "ERROR: batt installation failed."
        echo
        echo "You can install it manually from:"
        echo "https://github.com/charlie0129/batt"
        echo
        read -r -p "Press Return to close..."
        exit 1
    fi

    # Locate the newly installed binary.
    for candidate in \
        "$(command -v batt 2>/dev/null || true)" \
        "/usr/local/bin/batt" \
        "/opt/homebrew/bin/batt"
    do
        if [ -n "$candidate" ] && [ -x "$candidate" ]; then
            BATT="$candidate"
            break
        fi
    done
fi

if [ -z "$BATT" ]; then
    echo
    echo "ERROR: batt was installed, but its executable could not be found."
    echo "Open a new Terminal window and run: which batt"
    echo
    read -r -p "Press Return to close..."
    exit 1
fi

echo
echo "Installing/refreshing the batt background daemon..."
if ! sudo "$BATT" install; then
    echo
    echo "ERROR: Could not install the batt daemon."
    read -r -p "Press Return to close..."
    exit 1
fi

echo
echo "Configuring the MagSafe LED to stay OFF..."
if ! sudo "$BATT" magsafe-led always-off; then
    echo
    echo "ERROR: batt could not enable always-off mode."
    echo
    echo "This commonly means that this macOS/firmware version does not"
    echo "permit third-party MagSafe LED control."
    echo
    read -r -p "Press Return to close..."
    exit 1
fi

echo
echo "========================================"
echo "   Done"
echo "========================================"
echo
echo "The MagSafe LED is configured to stay off."
echo
echo "Charging behavior has NOT been limited or disabled."
echo
echo "To turn the LED control off later, run:"
echo
echo "  sudo \"$BATT\" magsafe-led disable"
echo
echo "To remove batt completely, run:"
echo
echo "  sudo \"$BATT\" uninstall"
echo
echo "If the LED still lights briefly when you reconnect MagSafe,"
echo "that is the Mac's firmware setting it before macOS can intervene."
echo
read -r -p "Press Return to close..."
