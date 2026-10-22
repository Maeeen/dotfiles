function nbssh --description 'Pick a Netbird peer with fzf and SSH into it'
    set selected (
        netbird status --json \
        | jq -r '.peers.details[] | "\(.fqdn)\t\(.status)"' \
        | column -t -s (printf '\t') \
        | awk '{
            gsub(/Disconnected/, "\033[31m● Disconnected\033[0m")
            gsub(/Connected/,    "\033[32m● Connected\033[0m")
            print
          }' \
        | fzf --ansi
    )

    test -z "$selected"; and return

    set fqdn (echo $selected | awk '{print $1}')
    set title (string replace -r '\.netbird\.cloud$' '' $fqdn)

    kitten @ set-window-title $title 2>/dev/null
    ssh $fqdn
    set -l ssh_status $status
    kitten @ set-window-title 2>/dev/null
    return $ssh_status
end
