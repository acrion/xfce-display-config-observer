# xfce-display-config-observer

`xfce-display-config-observer` is a systemd user service for XFCE-based Linux distributions, particularly [Ditana GNU/Linux](https://ditana.org). The service continuously monitors display configuration changes and automatically adjusts the font DPI to align with the primary display’s DPI. Additionally, it dynamically adjusts the height of the XFCE panel based on the physical height of the primary display.

## Features
- **Automatic Font DPI Adjustment:** The service continuously monitors the connected displays and updates the font DPI to match the actual DPI of the primary display, ensuring readability and visual consistency.
- **Dynamic XFCE Panel Height Adjustment:** The height of the XFCE panel adjusts based on the primary display’s DPI and physical height, optimizing the panel size on larger screens.
- **VM Compatibility:** For virtual machines, where automatic detection of the host display’s DPI may not be available, the service supports manual DPI configuration. To override the DPI value, place a file with an arbitrary name in the directory `$HOME/.config/xfce4/display-config-observer/dpi`, containing a single number that represents the DPI value. The service monitors this directory for any such file.

## Installation
`xfce-display-config-observer` is included in the Ditana GNU/Linux repository and compatible with other Arch-based distributions running XFCE.

## Usage
To enable and start the service for your user, use:

```bash
systemctl --user enable --now xfce-display-config-observer.service
```

The service operates as a user-level service, in alignment with XFCE’s user-specific DPI settings, though the physical properties of the display are consistent across users.

## Best Practices
The service is designed to automatically align font DPI with the physical DPI of connected displays. For optimal results, it is recommended to adjust font sizes directly in XFCE settings if needed rather than modifying the DPI manually. This manual DPI override is intended primarily for virtual machines. If you require an override on a physical machine, please open a [GitHub issue](https://github.com/acrion/xfce-display-config-observer/issues/new) detailing your use case.

## Robustness and Adaptability
The service seamlessly handles events such as display reconnections or resolution adjustments. Whether a new display is connected or a resolution changes, `xfce-display-config-observer` monitors these events and updates the configuration accordingly.
