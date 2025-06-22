#!/bin/bash
for internal in $(hyprctl monitors all -j | jq '.[].name' -r | grep "eDP"); do
  hyprctl keyword monitor "$internal, enable"
done
hyprctl reload
