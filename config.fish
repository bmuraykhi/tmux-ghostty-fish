if status is-interactive
    eval (/opt/homebrew/bin/brew shellenv)
    fish_add_path /opt/homebrew/bin $HOME/.local/bin
    fish_add_path /opt/zig

    set -x ANSIBLE_STRATEGY mitogen_linear
    set -x ANSIBLE_STRATEGY_PLUGINS ~/.ansible/mitogen/ansible_mitogen/plugins/strategy

    set -g fish_history save

    alias vim=nvim
    alias mylab='ssh homelab'
    alias csync='rsync --bwlimit=1000 --zl=9'
    alias ls='ls -rthG'
    alias genpass='python3 ~/genpass.py'
    alias genpw="$HOME/github/pass-gen-rs/target/release/genpw"

    function rsync
        set -l opts -ah --partial --info=progress2 --no-owner --no-group -z
        if test -f "$HOME/.rsync-exclude"
            set -a opts --exclude-from="$HOME/.rsync-exclude"
        end
        command rsync $opts $argv
    end

    function caff
        nohup caffeinate -umdt 36000 >/dev/null 2>&1 & disown
    end

    function __cc_dev_container_name
        set -l slug (basename $PWD | string lower | string replace -ra '[^a-z0-9_.-]+' '-' | string trim --chars=-)
        test -n "$slug"; or set slug workspace
        set -l base cc-dev-$slug
        set -l taken (docker ps -a --format '{{.Names}}' 2>/dev/null)
        set -l n 1
        while contains -- $base-$n $taken
            set n (math $n + 1)
        end
        echo $base-$n
    end

    function cc-dev --description 'Run cc-dev with creds in cwd (isolated: inner DinD, no host socket, no host net)'
        set -l creds $HOME/github/cc-dev/creds
        set -l host_home $HOME
        set -l cname (__cc_dev_container_name)

        docker run -it --rm \
            --name $cname \
            --privileged \
            -v cc-dev-docker-$cname:/var/lib/docker \
            -v $PWD:/workspace \
            -v $creds/.claude:/root/.claude \
            -v $creds/bash-history:/root/.bash-history \
            -v $host_home/.gitconfig-github:/root/.gitconfig:ro \
            --user root \
            cc-dev
    end

    function cc-dev-ports --description 'Like cc-dev but publishes a small range (40000-40019) for exposing work ports to the Mac'
        set -l creds $HOME/github/cc-dev/creds
        set -l host_home $HOME
        set -l cname (__cc_dev_container_name)

        docker run -it --rm \
            --name $cname \
            --privileged \
            -p 40000-40019:40000-40019 \
            -v cc-dev-docker-$cname:/var/lib/docker \
            -v $PWD:/workspace \
            -v $creds/.claude:/root/.claude \
            -v $creds/bash-history:/root/.bash-history \
            -v $host_home/.gitconfig-github:/root/.gitconfig:ro \
            --user root \
            cc-dev
    end

    function cc-dev-build
        docker build -t cc-dev $HOME/github/cc-dev
    end

    function cc-dev-rebuild
        docker build --no-cache --pull -t cc-dev $HOME/github/cc-dev
    end

    function cc-dev-nuke-cache
        docker volume ls -q --filter name='cc-dev-docker-' | xargs -r docker volume rm
    end
end

set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH
