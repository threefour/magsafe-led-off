# MagSafe LED Off

Turn off the MagSafe charging LED on Apple Silicon Macs.

## Installation

**[Download the latest release](../../releases/latest)**

1. Download the `.command` installer from the latest release.
2. Double-click `Turn_MagSafe_LED_Off_v1.1.command`.
3. Enter your administrator password when requested.

That's it.

The installer configures the Mac so that the MagSafe charging LED stays off. **Charging itself is unaffected.**

## Commands

Run the installer normally to turn the LED off:

Restore normal LED behavior:
./Turn_MagSafe_LED_Off_v1.1.command --on

Uninstall:
./Turn_MagSafe_LED_Off_v1.1.command --uninstall


## Requirements

* Apple Silicon Mac
* MagSafe charging connector with an LED
* A macOS/firmware version that permits third-party MagSafe LED control


## Compatibility

MagSafe LED control depends on Apple’s hardware and firmware.

Some newer firmware versions prevent third-party software from controlling the MagSafe LED. The installer will report an error rather than changing your charging behavior.


## How it works

This project uses ⁠batt by Charlie Chiang for low-level MagSafe LED control.

The installer uses the pinned batt v0.8.0 release and verifies the downloaded binary before installing it.


## Development

The initial implementation was developed with assistance from OpenAI’s ChatGPT.


## License

This installer is released under the MIT License.

The batt project is a separate project with its own license.

Social media icon courtesy of https://www.flaticon.com/en/free-of-the-icons/charger
