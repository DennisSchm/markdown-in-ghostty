#!/usr/bin/env bash
# view-md: render a Markdown file with glow inside a tiny pager that exposes
# vim motions and a one-keypress action bar. Invoked by MarkdownInGhostty.app
# inside a Ghostty split. Compatible with macOS's stock bash 3.2.

set -euo pipefail

file="$1"
style="${2:-auto}"
glow="${GLOW:-/opt/homebrew/bin/glow}"
mmdc="${MMDC:-/opt/homebrew/bin/mmdc}"
chafa="${CHAFA:-/opt/homebrew/bin/chafa}"
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/markdown-in-ghostty"
mkdir -p "$cache_dir"

resolve_editor() {
	if [[ -n "${EDITOR:-}" ]]; then
		printf '%s' "$EDITOR"
	elif command -v nvim >/dev/null; then
		printf 'nvim'
	else
		printf 'vi'
	fi
}

# Render one mermaid source block to terminal ANSI art via mmdc + chafa.
# Args: mermaid-src, target-cols, target-rows. Writes ANSI lines to stdout.
render_mermaid_block() {
	local src="$1" cols="$2" rows="$3"
	local hash png tmpdir input
	hash=$(printf '%s' "$src" | shasum | awk '{print $1}')
	png="$cache_dir/${hash}.png"
	if [[ ! -s "$png" ]]; then
		if [[ ! -x "$mmdc" ]]; then
			printf '```mermaid\n%s```\n' "$src"
			return
		fi
		tmpdir=$(mktemp -d)
		input="$tmpdir/input.mmd"
		printf '%s' "$src" > "$input"
		if ! "$mmdc" -i "$input" -o "$png" -t dark -b transparent \
				-w 1600 >/dev/null 2>&1; then
			rm -rf "$tmpdir"
			printf '```mermaid\n%s```\n' "$src"
			return
		fi
		rm -rf "$tmpdir"
	fi
	if [[ -x "$chafa" ]]; then
		# --format symbols keeps output as plain ANSI cells (no kitty/sixel
		# graphics escapes), so each line survives our line-by-line capture.
		# Strip chafa's surrounding cursor-management escapes — we own those.
		"$chafa" --format symbols --symbols block --colors 256 \
			--size "${cols}x${rows}" "$png" 2>/dev/null \
			| sed $'s/\x1b\\[?25[lh]//g'
	else
		printf '```mermaid\n%s```\n' "$src"
	fi
}

# Pipe a markdown buffer through glow, appending each rendered line to LINES.
glow_into_lines() {
	local md_buf="$1" cols="$2" rline
	[[ -z "$md_buf" ]] && return
	while IFS= read -r rline; do
		LINES+=("$rline")
	done < <(
		printf '%s' "$md_buf" |
			CLICOLOR_FORCE=1 "$glow" --style "$style" --width "$cols" -
	)
}

# Walk the file, alternating glow renders of plain markdown and chafa renders
# of ```mermaid blocks. Splicing happens at the line buffer level so glow
# never sees the ANSI art and chafa never sees glow's wrapping.
render_lines() {
	LINES=()
	local cols rows
	cols=$(tput cols)
	rows=$(( $(tput lines) - 4 ))
	(( rows < 12 )) && rows=12

	local in_mermaid=0 buf="" md_buf="" line rline
	while IFS= read -r line; do
		if (( in_mermaid == 0 )); then
			if [[ "$line" =~ ^[[:space:]]*\`\`\`mermaid([[:space:]].*)?$ ]]; then
				glow_into_lines "$md_buf" "$cols"
				md_buf=""
				in_mermaid=1
				buf=""
			else
				md_buf+="$line"$'\n'
			fi
		else
			if [[ "$line" =~ ^[[:space:]]*\`\`\`[[:space:]]*$ ]]; then
				while IFS= read -r rline; do
					LINES+=("$rline")
				done < <(render_mermaid_block "$buf" "$cols" "$rows")
				in_mermaid=0
			else
				buf+="$line"$'\n'
			fi
		fi
	done < "$file"
	glow_into_lines "$md_buf" "$cols"
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
