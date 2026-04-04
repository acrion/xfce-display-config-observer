#!/bin/bash

# Copyright (c) 2024, 2025 acrion innovations GmbH
# Authors: Stefan Zipproth, s.zipproth@acrion.ch
#
# This file is part of xfce-display-config-observer, see https://github.com/acrion/xfce-display-config-observer
#
# xfce-display-config-observer is free software: you can redistribute it and/or modify
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

# This script is started by user service xfce-display-config-observer, see /usr/lib/systemd/user/xfce-display-config-observer.service

CUSTOM_DPI_CONFIG_PATH=$HOME/.config/xfce4/display-config-observer/dpi
mkdir -p "$CUSTOM_DPI_CONFIG_PATH"

cleanup() {
    kill $(jobs -p) 2>/dev/null
    wait 2>/dev/null
}
trap cleanup EXIT

# Each monitor is wrapped in a restart loop so that if the underlying
# process dies (e.g. xfconfd restart), monitoring resumes automatically.

monitor_xfconf() {
    while true; do
        xfconf-query -c displays -m 2>/dev/null
        sleep 2
    done
}

monitor_dpi_dir() {
    while true; do
        inotifywait -q -r -m -e modify -e create -e delete \
            "$CUSTOM_DPI_CONFIG_PATH" 2>/dev/null
        sleep 2
    done
}

# Safety net: periodic poll in case an event is missed
periodic_poll() {
    while true; do
        sleep 60
        echo "periodic-poll"
    done
}

LAST_RUN=0
DEBOUNCE=2

(monitor_xfconf & monitor_dpi_dir & periodic_poll &) | while read -r _line; do
    NOW=$(date +%s)
    if (( NOW - LAST_RUN >= DEBOUNCE )); then
        if pgrep -x "xfwm4" > /dev/null; then
            /usr/lib/xfce4/display-config-observer/updater.sh
        fi
        LAST_RUN=$NOW
    fi
done
