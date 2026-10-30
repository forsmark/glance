#!/usr/bin/env bash
# Step-by-step test: can the kernel keep a monitor "connected" after its cable is unplugged?
#
# Usage:
#   tools/edid-force-test.sh            run the test
#   tools/edid-force-test.sh reset CON  undo the force on connector CON, for example DP-2
#
# Pick a monitor that does NOT show this terminal. If its picture fails to return,
# you can still read this terminal and undo the change.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="$SCRIPT_DIR/edid-test-results"
LOG="$OUT_DIR/results-$(date +%Y%m%d-%H%M%S).log"

CONNECTOR=""   # for example DP-2
SYS_DIR=""     # /sys/class/drm/cardN-DP-2
DBG_DIR=""     # /sys/kernel/debug/dri/<id>/DP-2
FORCED=0

bold()  { printf '\033[1m%s\033[0m\n' "$*"; }
info()  { printf '  %s\n' "$*"; }
log()   { printf '%s %s\n' "$(date +%T)" "$*" >> "$LOG"; }

pause() {
  printf '\n  Press Enter to continue, or Ctrl-C to stop and undo. '
  read -r _
}

ask_yn() {
  local answer
  while true; do
    printf '  %s [y/n] ' "$1"
    read -r answer
    case "$answer" in
      y|Y) log "Q: $1 -> yes"; return 0 ;;
      n|N) log "Q: $1 -> no";  return 1 ;;
    esac
  done
}

show_status() {
  local status enabled
  status="$(cat "$SYS_DIR/status")"
  enabled="$(cat "$SYS_DIR/enabled")"
  info "Kernel status of $CONNECTOR: $status, $enabled"
  log "status $CONNECTOR: $status, $enabled"
}

find_sys_dir() {
  local match
  match="$(ls -d /sys/class/drm/card*-"$1" 2>/dev/null | head -n1 || true)"
  [[ -n "$match" ]] || { echo "No connector named $1." >&2; exit 1; }
  SYS_DIR="$match"
}

# debugfs names the device by minor number on most kernels, by PCI address on some.
find_dbg_dir() {
  local card minor pci candidate
  card="$(basename "$SYS_DIR" | cut -d- -f1)"
  minor="$(cut -d: -f2 < "/sys/class/drm/$card/dev")"
  pci="$(basename "$(readlink -f "/sys/class/drm/$card/device")")"
  for candidate in "/sys/kernel/debug/dri/$minor" "/sys/kernel/debug/dri/$pci"; do
    if sudo test -e "$candidate/$CONNECTOR/edid_override"; then
      DBG_DIR="$candidate/$CONNECTOR"
      return
    fi
  done
  echo "Cannot find edid_override for $CONNECTOR under /sys/kernel/debug/dri." >&2
  echo "Check that debugfs is mounted: mount | grep debugfs" >&2
  exit 1
}

undo() {
  [[ -n "$SYS_DIR" ]] && echo detect | sudo tee "$SYS_DIR/status" > /dev/null || true
  [[ -n "$DBG_DIR" ]] && echo reset  | sudo tee "$DBG_DIR/edid_override" > /dev/null || true
}

on_exit() {
  if [[ "$FORCED" == 1 ]]; then
    echo
    bold "Undoing the force on $CONNECTOR."
    undo
    log "undo on exit"
  fi
}

kernel_log_since() {
  journalctl -k --since "$1" --no-pager -q 2>/dev/null | grep -iE 'amdgpu|drm|hpd|link|edid' | tail -n 20 || true
}

# --- reset mode -------------------------------------------------------------

if [[ "${1:-}" == "reset" ]]; then
  CONNECTOR="${2:?Usage: $0 reset CONNECTOR}"
  sudo -v
  find_sys_dir "$CONNECTOR"
  find_dbg_dir
  undo
  echo "Undo done for $CONNECTOR."
  exit 0
fi

# --- test -------------------------------------------------------------------

mkdir -p "$OUT_DIR"
trap on_exit EXIT

bold "Step 0: Choose a connector"
info "Connected monitors:"
mapfile -t CONNECTED < <(for c in /sys/class/drm/card*-*; do
  [[ "$(cat "$c/status" 2>/dev/null)" == connected ]] && basename "$c" | cut -d- -f2-
done)
for i in "${!CONNECTED[@]}"; do info "  $((i + 1))) ${CONNECTED[$i]}"; done
echo
info "Choose the monitor that does NOT show this terminal."
printf '  Number: '
read -r choice
[[ "$choice" =~ ^[0-9]+$ && "$choice" -ge 1 && "$choice" -le "${#CONNECTED[@]}" ]] || { echo "Invalid choice." >&2; exit 1; }
CONNECTOR="${CONNECTED[$((choice - 1))]:?Invalid choice}"
find_sys_dir "$CONNECTOR"
log "connector $CONNECTOR ($SYS_DIR), kernel $(uname -r)"

info "This script needs sudo to write to sysfs and debugfs."
sudo -v
find_dbg_dir
info "Using $SYS_DIR"
info "Using $DBG_DIR"
show_status
pause

bold "Step 1: Save the EDID"
EDID_FILE="$OUT_DIR/$CONNECTOR.edid"
cat "$SYS_DIR/edid" > "$EDID_FILE"
size="$(wc -c < "$EDID_FILE")"
[[ "$size" -ge 128 ]] || { echo "EDID is only $size bytes. Is the monitor on?" >&2; exit 1; }
info "Saved $size bytes to $EDID_FILE"
log "edid saved: $size bytes"
pause

bold "Step 2: Give the kernel the saved EDID"
sudo tee "$DBG_DIR/edid_override" < "$EDID_FILE" > /dev/null
FORCED=1
info "The kernel now uses the saved EDID for $CONNECTOR."
log "edid_override written"
pause

bold "Step 3: Force the connector on"
echo on | sudo tee "$SYS_DIR/status" > /dev/null
log "status forced on"
sleep 2
show_status
info "The monitor may flicker once. Your windows should not move."
ask_yn "Is the desktop the same as before?" || info "Note what changed. The test continues."
pause

bold "Step 4: Unplug the monitor cable"
info "Unplug the video cable from $CONNECTOR, at the computer or at the monitor."
info "Do not unplug the power cable."
pause
UNPLUG_TIME="$(date '+%Y-%m-%d %H:%M:%S')"
log "cable unplugged"
info "Waiting 5 seconds for GNOME to react."
sleep 5
show_status
if ask_yn "Did all windows stay where they were?"; then
  STEP4="pass"
else
  STEP4="fail"
fi
log "step 4: $STEP4"
info "Kernel log since unplug:"
kernel_log_since "$UNPLUG_TIME" | sed 's/^/    /'
pause

bold "Step 5: Plug the monitor cable back in"
info "Plug the cable back in."
pause
PLUG_TIME="$(date '+%Y-%m-%d %H:%M:%S')"
log "cable plugged in"
info "Waiting 5 seconds for the link to come up."
sleep 5
show_status
if ask_yn "Does the monitor show a picture?"; then
  STEP5="pass"
else
  info "Trying a retrain: write detect, then on."
  echo detect | sudo tee "$SYS_DIR/status" > /dev/null
  sleep 2
  echo on | sudo tee "$SYS_DIR/status" > /dev/null
  log "retrain attempted"
  sleep 3
  show_status
  if ask_yn "Does the monitor show a picture now?"; then
    STEP5="pass after retrain"
  else
    STEP5="fail"
  fi
fi
log "step 5: $STEP5"
info "Kernel log since plug-in:"
kernel_log_since "$PLUG_TIME" | sed 's/^/    /'
pause

bold "Step 6: Undo"
undo
FORCED=0
log "undo done"
sleep 2
show_status
info "Normal detection is back for $CONNECTOR."

echo
bold "Result"
info "Windows stayed during unplug: $STEP4"
info "Picture returned on plug-in:  $STEP5"
case "$STEP4/$STEP5" in
  pass/pass)                info "The kernel method works. No extra daemon is needed." ;;
  "pass/pass after retrain") info "The kernel method works with a retrain daemon." ;;
  fail/*)                   info "The kernel method does not stop GNOME from moving windows." ;;
  */fail)                   info "Windows stay, but the picture does not return. Check the kernel log." ;;
esac
info "Full log: $LOG"
log "result: unplug=$STEP4 plug=$STEP5"
