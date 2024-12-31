#!/usr/bin/env bash

# Copyright (c) 2024, 2025 acrion innovations GmbH
# Authors: Stefan Zipproth, s.zipproth@acrion.ch
#
# This file is part of xfce-display-config-observer, see https://github.com/acrion/xfce-display-config-observer
#
# xfce-display-config-observere is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# xfce-display-config-observer is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with xfce-display-config-observer. If not, see <https://www.gnu.org/licenses/>.

# This script is used by /usr/lib/xfce4/display-config-observer/observer.sh

parse_xfce_primary() {
    local DISPLAYS_FILE=$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/displays.xml

    if [[ -f "$DISPLAYS_FILE" ]]; then
        # Extract the name of the primary display from XFCE’s display configuration.
        # Using xmlstarlet for precise XML parsing, which offers more flexibility
        # than xfconf-query for this specific nested property query.
        xmlstarlet sel -t -v "//property[@name='Default']/property[property[@name='Primary' and @value='true']]/@name" "$DISPLAYS_FILE"
    fi
}

get_physical_size() {
    WIDTH_MM=$(echo "$1" | grep -oP '\d+mm x \d+mm' | cut -d'x' -f1 | grep -oP '\d+')
    HEIGHT_MM=$(echo "$1" | grep -oP '\d+mm x \d+mm' | cut -d'x' -f2 | sed 's/mm//')
    WIDTH_MM=${WIDTH_MM:-0}
    HEIGHT_MM=${HEIGHT_MM:-0}

    DISPLAY_SIZE=$(echo "scale=1; sqrt($WIDTH_MM^2 + $HEIGHT_MM^2) / 25.4" | bc -l)
}

get_pixel_size() {
    DISPLAY_WIDTH=$(echo "$1" | grep -oP '\d+x\d+' | cut -d'x' -f1)
    DISPLAY_HEIGHT=$(echo "$1" | grep -oP '\d+x\d+' | cut -d'x' -f2)
    DISPLAY_WIDTH=${DISPLAY_WIDTH:-0}
    DISPLAY_HEIGHT=${DISPLAY_HEIGHT:-0}
}

# Obtain XFCE’s primary display information. xrandr’s "connected primary" may differ
# from XFCE’s primary display configuration. In some cases, xrandr might show a
# "disconnected primary", while XFCE’s actual primary is a different, connected display.
# We use parse_xfce_primary() to identify XFCE’s designated primary display from displays.xml.
XFCE_PRIMARY="$(parse_xfce_primary)"

if [[ -n "$XFCE_PRIMARY" ]]; then
    # We use XFCE’s designated primary to filter xrandr output and identify the line that
    # contains the geometry of the primary display. This approach ensures we get the correct
    # primary display even when multiple displays are connected or when xrandr’s primary
    # doesn’tmatch XFCE’s configuration.
    XRANDR_INFO=$(xrandr | grep "$XFCE_PRIMARY connected")
else
    # Sometimes XFCE does not designate a primary display even if several displays are connected.
    # Iterate through all connected displays and find the one with the largest size.
    LARGEST_SIZE=-1
    XRANDR_INFO=""
    while read -r line; do
        get_physical_size "$line"
        if (( $(echo "$DISPLAY_SIZE > $LARGEST_SIZE" | bc -l) )); then
            LARGEST_SIZE=$DISPLAY_SIZE
            XRANDR_INFO=$line
        fi
    done < <(xrandr | grep " connected")
fi

get_physical_size "$XRANDR_INFO"
get_pixel_size "$XRANDR_INFO"

CUSTOM_DPI_CONFIG_PATH=$HOME/.config/xfce4/display-config-observer/dpi
mkdir -p "$CUSTOM_DPI_CONFIG_PATH"
DPI_FILE=$(find "$CUSTOM_DPI_CONFIG_PATH" -type f -print -quit)

LOG_FILE="$HOME/.cache/xfce4/display-config-observer/updater.log"
mkdir -p "$(dirname "$LOG_FILE")"

cat <<EOF > "$LOG_FILE"
Connected displays:
$(xrandr | grep " connected")

XFCE_PRIMARY:   $XFCE_PRIMARY
WIDTH_MM:       $WIDTH_MM
HEIGHT_MM:      $HEIGHT_MM
DISPLAY_SIZE:   $DISPLAY_SIZE
DISPLAY_WIDTH:  $DISPLAY_WIDTH
DISPLAY_HEIGHT: $DISPLAY_HEIGHT
DPI_FILE:       $DPI_FILE
EOF

if [[ -n "$DPI_FILE" && -f "$DPI_FILE" ]]; then
    DPI=$(xargs <"$DPI_FILE")
    MIN=102
    MAX=185

    if ! [[ "$DPI" =~ ^[0-9]+$ ]]; then
        if [[ ! $DPI == Error* ]]; then
            echo "Error: '$DPI' is not a number" >"$DPI_FILE" # this triggers xfce-display-config-monitor.sh
        fi
        exit 0
    elif (( DPI < MIN || DPI > MAX )); then
        if [[ ! $DPI == Error* ]]; then
            echo "Error: '$DPI' is not within the acceptable range ($MIN to $MAX)" >"$DPI_FILE" # this triggers xfce-display-config-monitor.sh
        fi
        exit 0
    fi

    echo "DPI from $DPI_FILE: $DPI" >>"$LOG_FILE"
elif [[ -n "$DISPLAY_SIZE" ]] && [[ "$DISPLAY_SIZE" != "0" ]]; then
    DPI=$(echo "sqrt($DISPLAY_WIDTH*$DISPLAY_WIDTH+$DISPLAY_HEIGHT*$DISPLAY_HEIGHT)/$DISPLAY_SIZE" | bc -l | xargs printf "%1.0f\n")
    echo "Calculated DPI: $DPI" >>"$LOG_FILE"
else
    exit 0
fi

xfconf-query -c xsettings -p /Xft/DPI -s "$DPI"
xfconf-query -c xsettings -p /Xfce/LastCustomDPI -s "$DPI"

if [[ "$DISPLAY_HEIGHT" != "0" ]]; then
    DISPLAY_HEIGHT_INCH=$(echo "$DISPLAY_HEIGHT / $DPI" | bc -l)
    # The panel height adapts to the DPI. In addition, it grows a bit as the display increases in physical height (inch).
    PANEL_HEIGHT_FLOAT=$(echo "e(l($DISPLAY_HEIGHT_INCH / 238.13) * 0.44) * $DPI" | bc -l)
    PANEL_HEIGHT=$(printf "%0.f\n" "$PANEL_HEIGHT_FLOAT")

    # Change the size of all XFCE Panels
    PROPERTIES=$(xfconf-query -c xfce4-panel -l)
    for PROPERTY in $PROPERTIES; do
        if [[ "$PROPERTY" == *"/size" ]] && [[ "$PROPERTY" == *"/panels/panel-"* ]]; then
            echo "Changing size of panel $PROPERTY to $PANEL_HEIGHT" >>"$LOG_FILE"
            xfconf-query -c xfce4-panel -p "$PROPERTY" -s "$PANEL_HEIGHT"
        fi
    done
else
    echo "Could not adapt height of the panel, because pixel height of display could not be retrieved from $XRANDR_INFO"
fi
