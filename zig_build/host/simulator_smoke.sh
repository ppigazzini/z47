#!/usr/bin/env bash

set -euo pipefail

app_path="${1:?usage: simulator_smoke.sh <app-path> <window-title>}"
window_title="${2:?usage: simulator_smoke.sh <app-path> <window-title>}"

for tool in Xvfb xdpyinfo xdotool import convert identify sha256sum head cut mktemp seq timeout; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "missing required simulator smoke tool: $tool" >&2
    exit 1
  }
done

work_dir="$(mktemp -d "${TMPDIR:-/tmp}/z47-simulator-smoke.XXXXXX")"
xvfb_pid=""
app_pid=""

cleanup() {
  local status=$?

  if [[ -n "$app_pid" ]]; then
    kill "$app_pid" >/dev/null 2>&1 || true
    wait "$app_pid" >/dev/null 2>&1 || true
  fi

  if [[ -n "$xvfb_pid" ]]; then
    kill "$xvfb_pid" >/dev/null 2>&1 || true
    wait "$xvfb_pid" >/dev/null 2>&1 || true
  fi

  if [[ $status -ne 0 ]]; then
    if [[ -f "$work_dir/${window_title}.log" ]]; then
      echo "--- ${window_title} smoke log ---" >&2
      cat "$work_dir/${window_title}.log" >&2
    fi
    if [[ -f "$work_dir/xvfb.log" ]]; then
      echo "--- Xvfb log ---" >&2
      cat "$work_dir/xvfb.log" >&2
    fi
  fi

  rm -rf "$work_dir"
  exit $status
}
trap cleanup EXIT

start_xvfb() {
  local candidate
  local probe

  for candidate in $(seq 200 260); do
    Xvfb ":$candidate" -screen 0 1280x800x24 >"$work_dir/xvfb.log" 2>&1 &
    xvfb_pid=$!
    export DISPLAY=":$candidate"

    for probe in $(seq 1 200); do
      if ! kill -0 "$xvfb_pid" >/dev/null 2>&1; then
        break
      fi

      if timeout 1s xdpyinfo >/dev/null 2>&1; then
        return 0
      fi
    done

    if [[ -n "$xvfb_pid" ]]; then
      kill "$xvfb_pid" >/dev/null 2>&1 || true
      wait "$xvfb_pid" >/dev/null 2>&1 || true
    fi
    xvfb_pid=""
  done

  echo "failed to start Xvfb for simulator smoke" >&2
  return 1
}

wait_for_window() {
  local window_id=""
  local attempt

  for attempt in $(seq 1 400); do
    if ! kill -0 "$app_pid" >/dev/null 2>&1; then
      echo "simulator exited before the window appeared" >&2
      return 1
    fi

    window_id="$(xdotool search --onlyvisible --name "${window_title}" 2>/dev/null | head -n1 || true)"
    if [[ -n "$window_id" ]]; then
      printf '%s\n' "$window_id"
      return 0
    fi

    sleep 0.1
  done

  echo "failed to find simulator window '${window_title}'" >&2
  return 1
}

capture_lcd() {
  local window_id="$1"
  local label="$2"
  local full_png="$work_dir/${label}-full.png"
  local lcd_png="$work_dir/${label}-lcd.png"
  local geometry=""

  geometry="$(xdotool getwindowgeometry --shell "$window_id" 2>/dev/null || true)"
  [[ -n "$geometry" ]] || return 1
  eval "$geometry"

  import -window root -crop "${WIDTH}x${HEIGHT}+${X}+${Y}" "$full_png" >/dev/null 2>&1 || return 1
  convert "$full_png" -crop 400x240+63+72 +repage "$lcd_png" >/dev/null 2>&1 || return 1
  [[ "$(identify -format '%wx%h' "$lcd_png" 2>/dev/null || true)" == "400x240" ]] || return 1
  printf '%s\n' "$lcd_png"
}

lcd_dark_pixels() {
  local lcd_png="$1"

  convert "$lcd_png" \
    -colorspace Gray \
    -threshold 60% \
    -negate \
    -format '%[fx:int(mean*w*h+0.5)]' info:
}

lcd_hash() {
  local lcd_png="$1"
  sha256sum "$lcd_png" | cut -d' ' -f1
}

wait_for_nonflat_lcd() {
  local window_id="$1"
  local label="$2"
  local lcd_png=""
  local dark_pixels=0
  local attempt

  for attempt in $(seq 1 120); do
    if lcd_png="$(capture_lcd "$window_id" "$label")" \
      && dark_pixels="$(lcd_dark_pixels "$lcd_png")" \
      && [[ "$dark_pixels" =~ ^[0-9]+$ ]] \
      && (( dark_pixels > 1000 )); then
      printf '%s\n%s\n' "$lcd_png" "$dark_pixels"
      return 0
    fi

    sleep 0.1
  done

  echo "LCD stayed too flat for '${window_title}'" >&2
  return 1
}

wait_for_lcd_change() {
  local window_id="$1"
  local baseline_hash="$2"
  local label="$3"
  local lcd_png=""
  local current_hash=""
  local dark_pixels=0
  local attempt

  for attempt in $(seq 1 120); do
    if lcd_png="$(capture_lcd "$window_id" "$label")" \
      && current_hash="$(lcd_hash "$lcd_png")" \
      && dark_pixels="$(lcd_dark_pixels "$lcd_png")" \
      && [[ "$current_hash" != "$baseline_hash" ]] \
      && [[ "$dark_pixels" =~ ^[0-9]+$ ]] \
      && (( dark_pixels > 1000 )); then
      printf '%s\n%s\n%s\n' "$lcd_png" "$current_hash" "$dark_pixels"
      return 0
    fi

    sleep 0.1
  done

  echo "LCD did not change after '${label}' for '${window_title}'" >&2
  return 1
}

wait_for_stable_lcd() {
  local window_id="$1"
  local baseline_hash="$2"
  local label="$3"
  local lcd_png=""
  local current_hash=""
  local dark_pixels=0
  local stable_hash=""
  local stable_count=0
  local attempt

  for attempt in $(seq 1 160); do
    if lcd_png="$(capture_lcd "$window_id" "$label")" \
      && current_hash="$(lcd_hash "$lcd_png")" \
      && dark_pixels="$(lcd_dark_pixels "$lcd_png")" \
      && [[ "$dark_pixels" =~ ^[0-9]+$ ]] \
      && (( dark_pixels > 1000 )) \
      && [[ "$current_hash" != "$baseline_hash" ]]; then
      if [[ "$current_hash" == "$stable_hash" ]]; then
        stable_count=$((stable_count + 1))
      else
        stable_hash="$current_hash"
        stable_count=1
      fi

      if (( stable_count >= 3 )); then
        printf '%s\n%s\n%s\n' "$lcd_png" "$current_hash" "$dark_pixels"
        return 0
      fi
    fi

    sleep 0.1
  done

  echo "LCD did not settle after '${label}' for '${window_title}'" >&2
  return 1
}

probe_pointer_input() {
  local window_id="$1"
  local baseline_hash="$2"
  local attempt
  local coords

  for attempt in $(seq 1 3); do
    kill -0 "$app_pid" >/dev/null 2>&1 || return 1

    for coords in "567 125" "567 125" "515 160"; do
      xdotool mousemove --sync --window "$window_id" ${coords% *} ${coords#* }
      xdotool click --window "$window_id" 1

      if wait_for_lcd_change "$window_id" "$baseline_hash" "after-click-${attempt}"; then
        return 0
      fi

      kill -0 "$app_pid" >/dev/null 2>&1 || return 1
      sleep 0.2
    done
  done

  return 1
}

start_xvfb

export GDK_BACKEND=x11
unset WAYLAND_DISPLAY

"$app_path" >"$work_dir/${window_title}.log" 2>&1 &
app_pid=$!

window_id="$(wait_for_window)"

mapfile -t before_info < <(wait_for_nonflat_lcd "$window_id" before)
[[ ${#before_info[@]} -ge 2 ]] || {
  echo "failed to capture initial LCD state for '${window_title}'" >&2
  exit 1
}
before_lcd="${before_info[0]}"
before_dark_pixels="${before_info[1]}"
before_hash="$(lcd_hash "$before_lcd")"

xdotool key --window "$window_id" --clearmodifiers 1
mapfile -t after_key_info < <(wait_for_lcd_change "$window_id" "$before_hash" after-key)
[[ ${#after_key_info[@]} -ge 3 ]] || {
  echo "failed to capture LCD change after keyboard input for '${window_title}'" >&2
  exit 1
}
after_key_hash="${after_key_info[1]}"
after_key_dark_pixels="${after_key_info[2]}"

mapfile -t settled_key_info < <(wait_for_stable_lcd "$window_id" "$before_hash" after-key-settled)
[[ ${#settled_key_info[@]} -ge 3 ]] || {
  echo "failed to capture stable LCD state after keyboard input for '${window_title}'" >&2
  exit 1
}
after_key_hash="${settled_key_info[1]}"
after_key_dark_pixels="${settled_key_info[2]}"

kill -0 "$app_pid" >/dev/null 2>&1 || {
  echo "simulator died after keyboard input" >&2
  exit 1
}

mapfile -t after_click_info < <(probe_pointer_input "$window_id" "$after_key_hash")
[[ ${#after_click_info[@]} -ge 3 ]] || {
  echo "failed to capture LCD change after pointer input for '${window_title}'" >&2
  exit 1
}
after_click_hash="${after_click_info[1]}"
after_click_dark_pixels="${after_click_info[2]}"

kill -0 "$app_pid" >/dev/null 2>&1 || {
  echo "simulator died after pointer input" >&2
  exit 1
}

echo "${window_title}: before_dark_pixels=${before_dark_pixels} after_key_dark_pixels=${after_key_dark_pixels} after_click_dark_pixels=${after_click_dark_pixels}"
echo "${window_title}: before_hash=${before_hash} after_key_hash=${after_key_hash} after_click_hash=${after_click_hash}"