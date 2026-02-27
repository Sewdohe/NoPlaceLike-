#!/usr/bin/env bash

multiple="$1"
directory="$2"
save="$3"
path="$4"
out="$5"

cmd="/usr/bin/yazi"

# Set appropriate title based on operation
if [ "$save" = "1" ]; then
  TITLE="Save File"
elif [ "$directory" = "1" ]; then
  TITLE="Select Directory"
else
  TITLE="Select File"
fi

# Use ghostty with title
termcmd_array=("ghostty" "--title=$TITLE")

# Function to make the window float
float_window() {
    # Wait a bit for window to appear
    sleep 0.3
    
    # Find the window with our title and make it float
    window_address=$(hyprctl clients -j | jq -r --arg title "$TITLE" '.[] | select(.title == $title) | .address')
    
    if [ -n "$window_address" ]; then
        echo "Found window: $window_address with title: $TITLE"
        hyprctl dispatch togglefloating address:$window_address
        hyprctl dispatch centerwindow address:$window_address
        hyprctl dispatch resizewindowpixel exact 900 700,address:$window_address
    else
        echo "Could not find window with title: $TITLE"
        # Fallback: float the most recent ghostty window
        newest_ghostty=$(hyprctl clients -j | jq -r '.[] | select(.class=="com.mitchellh.ghostty") | .address' | tail -1)
        if [ -n "$newest_ghostty" ]; then
            echo "Floating newest ghostty window: $newest_ghostty"
            hyprctl dispatch togglefloating address:$newest_ghostty
            hyprctl dispatch centerwindow address:$newest_ghostty
            hyprctl dispatch resizewindowpixel exact 900 700,address:$newest_ghostty
        fi
    fi
}

cleanup() {
  if [ -f "$tmpfile" ]; then
    rm -f "$tmpfile" || :
  fi
  if [ "$save" = "1" ] && [ ! -s "$out" ]; then
    rm -f "$path" || :
  fi
}

trap cleanup EXIT HUP INT QUIT ABRT TERM

if [ "$save" = "1" ]; then
  tmpfile=$(mktemp)
  
  cat > "$path" << 'EOFINNER'
xdg-desktop-portal-termfilechooser saving files tutorial
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!                 === WARNING! ===                 !!!
!!! The contents of *whatever* file you open last in !!!
!!! yazi will be *overwritten*!                    !!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
Instructions:
1) Move this file wherever you want.
2) Rename the file if needed.
3) Confirm your selection by opening the file, for
   example by pressing <Enter>.
Notes:
1) This file is provided for your convenience. You can
   only choose this placeholder file otherwise the save operation aborted.
2) If you quit yazi without opening a file, this file
   will be removed and the save operation aborted.
EOFINNER

  # Run ghostty in background, then float it
  "${termcmd_array[@]}" -e "$cmd" --chooser-file="$tmpfile" "$path" &
  ghostty_pid=$!
  float_window
  wait $ghostty_pid
  
elif [ "$directory" = "1" ]; then
  "${termcmd_array[@]}" -e "$cmd" --cwd-file="$out" "$path" &
  ghostty_pid=$!
  float_window
  wait $ghostty_pid
  
elif [ "$multiple" = "1" ]; then
  "${termcmd_array[@]}" -e "$cmd" --chooser-file="$out" "$path" &
  ghostty_pid=$!
  float_window
  wait $ghostty_pid
  
else
  "${termcmd_array[@]}" -e "$cmd" --chooser-file="$out" "$path" &
  ghostty_pid=$!
  float_window
  wait $ghostty_pid
fi

# Handle save file case
if [ "$save" = "1" ] && [ -s "$tmpfile" ]; then
  selected_file=$(head -n 1 "$tmpfile")
  
  if [ -f "$selected_file" ] && grep -qi "^xdg-desktop-portal-termfilechooser saving files tutorial" "$selected_file"; then
    echo "$selected_file" > "$out"
  fi
fi
