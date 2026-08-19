#!/bin/bash
if [ "$(acpi -a)" == "Adapter 0: on-line" ]; then
  for internal in $(hyprctl monitors all -j | jq '.[].name' -r | grep "eDP"); do
    hyprctl eval "hl.monitor({ output = \"$internal\", disabled = true })"
  done
fi
