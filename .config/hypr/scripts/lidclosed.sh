#!/bin/bash
if [ "$(acpi -a)" == "Adapter 0: on-line" ]; then
  for internal in $(hyprctl monitors all -j | jq '.[].name' -r | grep "eDP"); do
    hyprctl keyword "monitor $internal, disable"
  done
fi
