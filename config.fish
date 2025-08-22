if status is-interactive
    eval (/opt/homebrew/bin/brew shellenv)
    fish_add_path /opt/homebrew/bin $HOME/.local/bin

    alias vim=nvim
    alias mylab='ssh homelab'
    alias rsync='rsync -vzP --no-perms --no-owner --no-group'
    alias csync='rsync -vzP --no-perms --no-owner --no-group --bwlimit=1000 --compress-level=9'
    alias ls='ls -rthG'
    alias genpass='python3 ~/genpass.py'

    function caff
    nohup caffeinate -umdt 36000 >/dev/null 2>&1 & disown
    end

    set -g fish_history save
end
