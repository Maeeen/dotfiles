function nbexec --description 'SSH to all connected Netbird peers matching a pattern and run a command'
    if test (count $argv) -lt 2
        echo "Usage: nbexec <fqdn-pattern> <command...>" >&2
        return 1
    end

    set pattern $argv[1]
    set cmd (string join ' ' $argv[2..])

    set peers (netbird status --json | jq -r --arg pat "$pattern" '
        .peers.details[]
        | select(.status == "Connected")
        | select(.fqdn | test($pat))
        | .fqdn
    ')

    if test -z "$peers"
        echo "No connected peers match pattern: $pattern" >&2
        return 1
    end

    for peer in $peers
        set output (ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 $peer $cmd 2>&1)
        set code $status
        echo "$peer: $output ($code)"
    end
end
