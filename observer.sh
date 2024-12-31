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

# This script is started by user service xfce-display-config-observer, see /usr/lib/systemd/user/xfce-display-config-observer.service

CUSTOM_DPI_CONFIG_PATH=$HOME/.config/xfce4/display-config-observer/dpi
mkdir -p "$CUSTOM_DPI_CONFIG_PATH"

(
    xfconf-query -c displays -m &
    inotifywait -q -r -m -e modify -e create -e delete "$CUSTOM_DPI_CONFIG_PATH" &
) | while read -r; do
    if pgrep -x "xfwm4" > /dev/null; then
        /usr/lib/xfce4/display-config-observer/updater.sh
    fi
done
