function fish_greeting
    set -lx cols (tput cols)
    if status is-interactive; and test $TERM = xterm-kitty
        set -lx img (status dirname)/res/2b.png
        kitten icat --place $(math "$cols - 1")x5@0x0 --align right $img
        echo
    end
    function echo_center
        set -l out (echo $argv[1] | lolcat -f)
        for line in $out
            set -l length (string length -V "$line")
            set -l padding (math --scale 0 "($cols - $length) / 2")
            echo (string repeat $padding " ") $line
        end
    end
    echo_center """Hello, $(whoami)
You do you…"""
end
