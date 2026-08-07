#!/usr/bin/env sh

set -eu

action=${1:-}
id=${2:-}

case "$action" in
    store)
        cliphist store
        printf 'changed\n'
        ;;
    copy)
        case "$id" in
            '' | *[!0-9]*) exit 2 ;;
        esac
        mime=${3:-text/plain;charset=utf-8}
        cliphist decode "$id" | wl-copy --type "$mime"
        ;;
    delete)
        case "$id" in
            '' | *[!0-9]*) exit 2 ;;
        esac
        printf '%s\n' "$id" | cliphist delete
        ;;
    preview)
        case "$id" in
            '' | *[!0-9]*) exit 2 ;;
        esac
        destination=${3:-}
        [ -n "$destination" ] || exit 2

        mkdir -p "${destination%/*}"
        temporary="${destination}.tmp.$$"
        trap 'rm -f "$temporary"' EXIT HUP INT TERM

        cliphist decode "$id" >"$temporary"
        mv "$temporary" "$destination"
        trap - EXIT HUP INT TERM
        ;;
    *)
        exit 2
        ;;
esac
