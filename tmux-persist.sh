#!/usr/bin/env bash
# tmux-persist.sh — minimal manual tmux session save/restore.
#
#   tmux-persist.sh save      # run before a reboot
#   tmux-persist.sh restore   # run after reboot, then `tmux attach`
#
# Saves sessions, windows (names + layout) and each pane's working
# directory. It does NOT restart the programs that were running — panes
# come back as shells in the right directory. Restore into a fresh tmux
# server (i.e. after a reboot, or `tmux kill-server` first).

set -u
save_file="${TMUX_PERSIST_FILE:-$HOME/.tmux/session.save}"
TAB="$(printf '\t')"

save() {
  mkdir -p "$(dirname "$save_file")"
  {
    tmux list-windows -a -F "W${TAB}#{session_name}${TAB}#{window_index}${TAB}#{window_name}${TAB}#{window_layout}"
    tmux list-panes -a -F "P${TAB}#{session_name}${TAB}#{window_index}${TAB}#{pane_index}${TAB}#{pane_current_path}"
  } >"$save_file"
  echo "saved $(grep -c '^W' "$save_file") window(s) to $save_file"
}

restore() {
  [ -f "$save_file" ] || {
    echo "no save file at $save_file" >&2
    exit 1
  }
  seen=" "
  grep '^W' "$save_file" | while IFS="$TAB" read -r _ sess win wname layout; do
    # working directories of this window's panes, in pane order
    paths=$(awk -F"$TAB" -v s="$sess" -v w="$win" \
      '$1=="P" && $2==s && $3==w {print $5}' "$save_file")
    first=$(printf '%s\n' "$paths" | head -n1)
    [ -n "$first" ] || first="$HOME"

    case "$seen" in
    *" $sess "*) tmux new-window -t "$sess:" -n "$wname" -c "$first" ;;
    *)
      tmux new-session -d -s "$sess" -n "$wname" -c "$first"
      seen="$seen$sess "
      ;;
    esac
    tgt="$sess:$(tmux list-windows -t "$sess" -F '#{window_index}' | tail -n1)"

    # recreate the remaining panes in their directories
    printf '%s\n' "$paths" | tail -n +2 | while read -r p; do
      [ -n "$p" ] && tmux split-window -t "$tgt" -c "$p"
    done
    [ -n "$layout" ] && tmux select-layout -t "$tgt" "$layout" 2>/dev/null
    true
  done
  echo "restored from $save_file — run: tmux attach"
}

case "${1:-}" in
save) save ;;
restore) restore ;;
*)
  echo "usage: ${0##*/} {save|restore}" >&2
  exit 2
  ;;
esac
