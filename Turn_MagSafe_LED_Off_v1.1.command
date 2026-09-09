#!/bin/bash
#
# MagSafe LED Off
# Turns the MagSafe charging LED off on Apple Silicon MacBooks.
#
# Uses batt v0.8.0, downloaded only from its official GitHub release.
# batt is a separate open-source project by Charlie Chiang.
#
# Usage:
#   Double-click: install/configure LED-off mode
#   ./Turn_MagSafe_LED_Off.command --on
#   ./Turn_MagSafe_LED_Off.command --uninstall
#

set -u

BATT_VERSION="v0.8.0"
BATT_REPO="charlie0129/batt"
BATT_ASSET="batt-${BATT_VERSION}-darwin-arm64.tar.gz"
BATT_URL="https://github.com/${BATT_REPO}/releases/download/${BATT_VERSION}/${BATT_ASSET}"
BATT_API="https://api.github.com/repos/${BATT_REPO}/releases/tags/${BATT_VERSION}"
BATT_PATH="/usr/local/bin/batt"
MARKER="/etc/magsafe-led-off.installed-batt"

say() { printf '%s\n' "$*"; }
die() {
    say
    say "ERROR: $*"
    say
    read -r -p "Press Return to close..."
    exit 1
}
pause() {
    say
    read -r -p "Press Return to close..."
}
usage() {
    cat <<EOF

MagSafe LED Off

Usage:
  Double-click this file, or run it with no argument
      Install/configure MagSafe LED OFF.

  $0 --on
      Return MagSafe LED control to batt's normal charging-state mode.

  $0 --uninstall
      Disable MagSafe LED OFF and remove the batt installation only if
      this installer originally installed batt.

  $0 --help
      Show this help.

EOF
}

export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"

ARCH="$(uname -m)"
if [ "$ARCH" != "arm64" ]; then
    die "This utility requires an Apple Silicon Mac (arm64)."
fi

ACTION="${1:-install}"
case "$ACTION" in
    --help|-h) usage; exit 0 ;;
    --on) ACTION="on" ;;
    --uninstall) ACTION="uninstall" ;;
    install) ;;
    *) usage; die "Unknown option: $1" ;;
esac

find_batt() {
    if [ -x "$BATT_PATH" ]; then
        printf '%s' "$BATT_PATH"
        return 0
    fi
    local found
    found="$(command -v batt 2>/dev/null || true)"
    if [ -n "$found" ] && [ -x "$found" ]; then
        printf '%s' "$found"
        return 0
    fi
    return 1
}

BATT="$(find_batt || true)"

if [ "$ACTION" = "on" ]; then
    [ -n "$BATT" ] || die "batt is not installed."
    say
    say "Restoring normal batt MagSafe LED control..."
    say
    sudo "$BATT" magsafe-led enable \
        || die "Could not restore batt's normal MagSafe LED control."
    say
    say "Done. The MagSafe LED is now controlled according to batt's"
    say "normal charging-state behavior."
    say
    say "Note: this is not a macOS-native system-control switch."
    pause
    exit 0
fi

if [ "$ACTION" = "uninstall" ]; then
    [ -n "$BATT" ] || die "batt is not installed."

    say
    say "Disabling MagSafe LED Off..."
    say
    sudo "$BATT" magsafe-led enable \
        || die "Could not restore batt's normal MagSafe LED control."

    OWNED="no"
    if sudo test -f "$MARKER"; then OWNED="yes"; fi

    if [ "$OWNED" = "yes" ]; then
        say
        say "This installer installed batt, so its daemon will now be removed."
        sudo "$BATT" uninstall \
            || die "Could not uninstall the batt daemon."
        sudo rm -f "$BATT_PATH" \
            || die "Could not remove $BATT_PATH."
        sudo rm -f "$MARKER" 2>/dev/null || true
        say "batt and its daemon have been removed."
    else
        say "Your existing batt installation was left intact."
        say "Only the MagSafe LED setting was changed."
    fi

    say
    say "Done."
    pause
    exit 0
fi

say
say "========================================"
say "       MagSafe LED Off Installer"
say "========================================"
say
say "Apple Silicon detected."
say "Pinned dependency: batt ${BATT_VERSION}"
say

if [ -n "$BATT" ]; then
    VERSION_OUTPUT="$("$BATT" version 2>&1 || true)"
    if ! printf '%s\n' "$VERSION_OUTPUT" | grep -q "Client: ${BATT_VERSION}"; then
        say "An existing batt installation was found:"
        say "  $BATT"
        say
        printf '%s\n' "$VERSION_OUTPUT"
        say
        die "This installer requires batt ${BATT_VERSION}. It will not replace or downgrade an existing batt installation."
    fi
    say "Found batt ${BATT_VERSION}:"
    say "  $BATT"
    say
else
    TMPDIR="$(mktemp -d "${TMPDIR:-/tmp}/magsafe-led-off.XXXXXX")"
    trap 'rm -rf "$TMPDIR"' EXIT INT TERM
    ARCHIVE="$TMPDIR/$BATT_ASSET"
    API_JSON="$TMPDIR/release.json"

    say "Downloading the official batt ${BATT_VERSION} release..."
    say
    curl -fL --proto '=https' --tlsv1.2 \
        -o "$ARCHIVE" "$BATT_URL" \
        || die "Could not download batt ${BATT_VERSION} from GitHub."

    say "Checking the GitHub release digest..."
    curl -fL --proto '=https' --tlsv1.2 \
        -H "Accept: application/vnd.github+json" \
        -H "User-Agent: MagSafe-LED-Off" \
        -o "$API_JSON" "$BATT_API" \
        || die "Could not retrieve the official GitHub release metadata."

    EXPECTED_SHA="$(
        grep -A 20 "\"name\": \"$BATT_ASSET\"" "$API_JSON" |
        grep '"digest":' |
        sed -E 's/.*"digest": "sha256:([0-9a-fA-F]+)".*/\1/' |
        head -n 1
    )"

    [ -n "$EXPECTED_SHA" ] || die "GitHub did not provide a SHA-256 digest for the expected release asset. Installation stopped."

    ACTUAL_SHA="$(shasum -a 256 "$ARCHIVE" | awk '{print $1}')"
    if [ "$ACTUAL_SHA" != "$EXPECTED_SHA" ]; then
        die "SHA-256 verification failed. The downloaded file does not match the GitHub release digest."
    fi
    say "SHA-256 verified."

    mkdir -p "$TMPDIR/extracted"
    tar -xzf "$ARCHIVE" -C "$TMPDIR/extracted" \
        || die "The downloaded batt archive could not be extracted."

    DOWNLOADED_BATT="$TMPDIR/extracted/batt"
    [ -f "$DOWNLOADED_BATT" ] \
        || die "The release archive did not contain the expected batt executable."

    chmod +x "$DOWNLOADED_BATT"
    DOWNLOADED_ARCH="$(file "$DOWNLOADED_BATT")"
    printf '%s\n' "$DOWNLOADED_ARCH"

    case "$DOWNLOADED_ARCH" in
        *"Mach-O 64-bit executable arm64"*) ;;
        *) die "The downloaded batt executable is not an Apple Silicon arm64 binary." ;;
    esac

    DOWNLOADED_VERSION="$("$DOWNLOADED_BATT" version 2>&1 || true)"
    if ! printf '%s\n' "$DOWNLOADED_VERSION" | grep -q "Client: ${BATT_VERSION}"; then
        die "The downloaded executable did not report batt ${BATT_VERSION}."
    fi

    say "Installing batt ${BATT_VERSION} to $BATT_PATH..."
    say "You will be asked for your administrator password."
    say

    sudo mkdir -p /usr/local/bin
    sudo cp "$DOWNLOADED_BATT" "$BATT_PATH"
    sudo chown root:wheel "$BATT_PATH"
    sudo chmod 755 "$BATT_PATH"
    BATT="$BATT_PATH"

    sudo touch "$MARKER"
    sudo chmod 644 "$MARKER"
    say "batt installed."
    say
fi

if ! sudo launchctl print system/cc.chlc.batt >/dev/null 2>&1; then
    say "Installing the batt background daemon..."
    say
    sudo "$BATT" install \
        || die "batt could not install its background daemon."
else
    say "batt daemon is already installed."
fi

say
say "Turning the MagSafe LED OFF..."
say
sudo "$BATT" magsafe-led always-off \
    || die "batt could not enable MagSafe LED always-off mode."

say
say "========================================"
say "          Installation complete"
say "========================================"
say
say "The MagSafe LED is now configured to stay OFF."
say
say "Charging behavior has not been changed."
say
say "To restore normal batt LED behavior:"
say
say "  $0 --on"
say
say "To uninstall this utility:"
say
say "  $0 --uninstall"
say
say "batt ${BATT_VERSION} provides the low-level MagSafe LED control."
say
pause
