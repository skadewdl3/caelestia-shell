#!/usr/bin/env sh

# Apply a palette-local GTK theme to Swappy without changing the user's global
# GTK settings. The temporary theme lives for exactly as long as the editor.
set -eu

if [ "$#" -ne 13 ]; then
    printf '%s\n' "usage: swappy-wrapper.sh FILE MODE SURFACE SURFACE_CONTAINER SURFACE_CONTAINER_HIGH ON_SURFACE ON_SURFACE_VARIANT PRIMARY ON_PRIMARY SECONDARY_CONTAINER ON_SECONDARY_CONTAINER OUTLINE_VARIANT ERROR" >&2
    exit 2
fi

screenshot=$1
mode=$2
surface=$3
surface_container=$4
surface_container_high=$5
on_surface=$6
on_surface_variant=$7
primary=$8
on_primary=$9
shift 9
secondary_container=$1
on_secondary_container=$2
outline_variant=$3
error=$4

case "$mode" in
    light)
        base_theme=gtk-contained.css
        ;;
    dark)
        base_theme=gtk-contained-dark.css
        ;;
    *)
        printf '%s\n' "swappy-wrapper.sh: mode must be 'light' or 'dark'" >&2
        exit 2
        ;;
esac

theme_root=$(mktemp -d "${TMPDIR:-/tmp}/caelestia-swappy.XXXXXX")
cleanup() {
    rm -f -- "$screenshot"
    rm -r -- "$theme_root"
}
trap cleanup EXIT
trap 'exit 1' HUP INT TERM

theme_dir="$theme_root/themes/Caelestia/gtk-3.0"
mkdir -p "$theme_dir"

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
sed \
    -e "s|@BASE_THEME@|$base_theme|g" \
    -e "s|@SURFACE@|$surface|g" \
    -e "s|@SURFACE_CONTAINER@|$surface_container|g" \
    -e "s|@SURFACE_CONTAINER_HIGH@|$surface_container_high|g" \
    -e "s|@ON_SURFACE@|$on_surface|g" \
    -e "s|@ON_SURFACE_VARIANT@|$on_surface_variant|g" \
    -e "s|@PRIMARY@|$primary|g" \
    -e "s|@ON_PRIMARY@|$on_primary|g" \
    -e "s|@SECONDARY_CONTAINER@|$secondary_container|g" \
    -e "s|@ON_SECONDARY_CONTAINER@|$on_secondary_container|g" \
    -e "s|@OUTLINE_VARIANT@|$outline_variant|g" \
    -e "s|@ERROR@|$error|g" \
    "$script_dir/swappy.css" > "$theme_dir/gtk.css"

data_dirs=${XDG_DATA_DIRS:-/usr/local/share:/usr/share}
ui_adapter="${CAELESTIA_LIB_DIR:-/usr/lib/caelestia}/libcaelestia-swappy-ui.so"
XDG_DATA_DIRS="$theme_root:$data_dirs" \
    GTK_THEME=Caelestia \
    LD_PRELOAD="$ui_adapter${LD_PRELOAD:+:$LD_PRELOAD}" \
    CAELESTIA_SCREENSHOT_PATH="$screenshot" \
    swappy -f "$screenshot"
