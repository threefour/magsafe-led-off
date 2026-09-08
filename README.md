# MagSafe LED Off

A tiny installer that turns off the MagSafe charging LED on Apple Silicon Macs.

## What it does

This utility configures the Mac so that the LED on the MagSafe charging connector stays off.

It does **not** disable charging or change battery charging behavior.

## Requirements

- Apple Silicon Mac
- A MagSafe charging connector
- A macOS/firmware version that permits MagSafe LED control

## Installation

1. Download `Turn_MagSafe_LED_Off_Installer.zip`.
2. Unzip it.
3. Double-click `Turn_MagSafe_LED_Off.command`.
4. Enter your administrator password when requested.

The installer installs and configures [`batt`](https://github.com/charlie0129/batt), which provides the low-level MagSafe LED control.

## Compatibility

MagSafe LED control depends on Apple's hardware and firmware.

Newer macOS/firmware versions may restrict third-party control of the MagSafe LED. If the LED cannot be controlled, the installer will report the problem rather than changing charging behavior.

## Credits

This project uses [`batt`](https://github.com/charlie0129/batt) by Charlie Chiang for low-level MagSafe and battery control.

## License

MIT License
