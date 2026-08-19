#!/bin/bash
for internal in $(hyprctl monitors all -j | jq '.[].name' -r | grep "eDP"); do
  hyprctl eval "hl.monitor({ output = \"$internal\", disabled = false })"
done
hyprctl reload
