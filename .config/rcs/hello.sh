#!/usr/bin/env bash

# if $TERM = 'xterm-kitty'
# get basepath of this script, that is being sourced
SCRIPT_DIR=$(dirname "$0")

display_multiline_center() {
    local width=$(tput cols)
    while IFS= read -r line; do
        printf "%$(((width-${#line})/2))s%s\n" "" "$(echo $line | lolcat -f -t -F 0.001)"
    done
}

hi() {
    local msg="$1"
    local color="$2"
    local basepath=$(dirname "$(readlink -f "$0")")
    local img="$SCRIPT_DIR/res/2b.png"

    if [ "$TERM" = "xterm-kitty" ]; then
        kitten icat --place $(tput cols)x$(expr $(echo "$msg" | wc -l) + 5)@0x0 --align right "$img" && echo
    fi

    echo -e "$msg" | display_multiline_center
}

hi """→ Hello, $(whoami) 😼
You do you…""" "green"

alias fastfetch="fastfetch --logo-position right --logo \"$SCRIPT_DIR/res/arcolinux.png\""

unset -f hi display_multiline_center