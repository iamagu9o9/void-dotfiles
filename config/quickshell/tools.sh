#!/usr/bin/env bash
THEME="$HOME/.config/rofi/menu.rasi"
dir="$HOME/Pictures/Wallpapers"; mkdir -p "$dir"
stamp=$(date +%F_%H-%M-%S)

pick=$(printf '%s\n' \
  "  Screenshot area" \
  "  Screenshot full screen" \
  "  Color picker" \
  "  Record screen (toggle)" \
  "  Text from screen (OCR)" \
  | rofi -dmenu -i -p "Tools" -theme "$THEME")

need() { command -v "$1" >/dev/null || { notify-send "Tools" "Missing: $1"; exit 1; }; }

case "$pick" in
  *"Screenshot area")
    need grim; need slurp
    f="$dir/$stamp.png"; grim -g "$(slurp)" "$f" && wl-copy < "$f" && notify-send "Screenshot saved" "$f" ;;
  *"full screen")
    need grim
    f="$dir/$stamp.png"; grim "$f" && wl-copy < "$f" && notify-send "Screenshot saved" "$f" ;;
  *"Color picker")
    need hyprpicker
    c=$(hyprpicker -a) && notify-send "Color copied" "$c" ;;
  *"Record screen"*)
    need wf-recorder
    if pgrep -x wf-recorder >/dev/null; then
        pkill -INT wf-recorder; notify-send "Recording saved" "$HOME/Videos"
    else
        mkdir -p "$HOME/Videos"
        notify-send "Recording started" "Run Tools again to stop"
        wf-recorder -g "$(slurp)" -f "$HOME/Videos/rec_$stamp.mp4"
    fi ;;
  *"OCR"*)
    need grim; need slurp; need tesseract
    grim -g "$(slurp)" - | tesseract - - 2>/dev/null | wl-copy && notify-send "Text copied" "from the selected area" ;;
esac
