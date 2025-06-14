function fish_prompt
    set -l last_status $status
    set -l symbol ' $ '
    set -l color $fish_color_cwd
    if fish_is_root_user
        set symbol ' # '
        set -q fish_color_cwd_root
        and set color $fish_color_cwd_root
    end

    echo -n $USER@$hostname

    set_color $color
    echo -n (prompt_pwd)
    set_color normal

    # If the last command failed, show its exit code
    if test $last_status -ne 0
        set_color red
        echo -n " $last_status"
        set_color normal
    end

    echo -n $symbol
end
