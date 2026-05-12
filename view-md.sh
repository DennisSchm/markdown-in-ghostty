#!/usr/bin/env bash
# view-md: render a Markdown file with glow inside a tiny pager that exposes
# vim motions and a one-keypress action bar. Invoked by MarkdownInGhostty.app
# inside a Ghostty split. Compatible with macOS's stock bash 3.2.

set -euo pipefail

file="$1"
style="${2:-auto}"
glow="${GLOW:-/opt/homebrew/bin/glow}"

resolve_editor() {
	if [[ -n "${EDITOR:-}" ]]; then
		printf '%s' "$EDITOR"
	elif command -v nvim >/dev/null; then
		printf 'nvim'
	else
		printf 'vi'
	fi
}

render_lines() {
	# CLICOLOR_FORCE=1 makes glow emit ANSI even though stdout is a pipe.
	LINES=()
	local line
	while IFS= read -r line; do
		LINES+=("$line")
	done < <(
		CLICOLOR_FORCE=1 "$glow" --style "$style" --width "$(tput cols)" "$file"
	)
}

draw() {
	local i end
	end=$((TOP + VIEW_H))
	(( end > ${#LINES[@]} )) && end=${#LINES[@]}
	printf '\033[H\033[J'
	for ((i = TOP; i < end; i++)); do
		printf '%s\n' "${LINES[$i]}"
	done
	# Pinned action bar on the last row, inverse video.
	printf '\033[%d;1H\033[7m▸ [e] edit  [r] re-render  [q] close  · j/k/gg/G/space/b\033[0m' \
		"$((VIEW_H + 1))"
}

cleanup() {
	# Show cursor, leave the alternate screen.
	printf '\033[?25h\033[?1049l'
}
trap cleanup EXIT

on_resize() {
	VIEW_H=$(($(tput lines) - 1))
	render_lines
	if (( TOP > ${#LINES[@]} - VIEW_H )); then
		TOP=$((${#LINES[@]} - VIEW_H))
		(( TOP < 0 )) && TOP=0
	fi
	draw
}
trap on_resize WINCH

# Alt-screen so we leave the user's terminal state intact on exit.
printf '\033[?1049h\033[?25l'

while true; do
	render_lines
	TOP=0
	VIEW_H=$(($(tput lines) - 1))
	draw

	while true; do
		IFS= read -r -s -n 1 key || key=
		case "$key" in
			j)
				if (( TOP < ${#LINES[@]} - VIEW_H )); then
					((TOP++)); draw
				fi
				;;
			k)
				if (( TOP > 0 )); then
					((TOP--)); draw
				fi
				;;
			' ')
				TOP=$((TOP + VIEW_H))
				(( TOP > ${#LINES[@]} - VIEW_H )) && TOP=$((${#LINES[@]} - VIEW_H))
				(( TOP < 0 )) && TOP=0
				draw
				;;
			b)
				TOP=$((TOP - VIEW_H))
				(( TOP < 0 )) && TOP=0
				draw
				;;
			G)
				TOP=$((${#LINES[@]} - VIEW_H))
				(( TOP < 0 )) && TOP=0
				draw
				;;
			g)
				IFS= read -r -s -n 1 next || next=
				if [[ "$next" == "g" ]]; then
					TOP=0; draw
				fi
				;;
			e|E)
				cleanup
				eval "$(resolve_editor)" "$(printf %q "$file")"
				printf '\033[?1049h\033[?25l'
				break
				;;
			r|R)
				break
				;;
			q|Q)
				exit 0
				;;
		esac
	done
done
