#!/usr/bin/env bash
# view-md: render a Markdown file with glow, then offer edit / re-render / quit.
# Invoked by MarkdownInGhostty.app inside a Ghostty split.

set -euo pipefail

file="$1"
style="${2:-auto}"
glow="${GLOW:-/opt/homebrew/bin/glow}"

# Resolve the editor: respect $EDITOR, fall back to nvim, then vi.
resolve_editor() {
	if [[ -n "${EDITOR:-}" ]]; then
		printf '%s' "$EDITOR"
	elif command -v nvim >/dev/null; then
		printf 'nvim'
	else
		printf 'vi'
	fi
}

while true; do
	"$glow" --pager --style "$style" --width 100 "$file"
	printf "\n\033[2m[e]\033[0m edit   \033[2m[r]\033[0m re-render   \033[2m[q]\033[0m close   > "
	read -r -n 1 action || action=q
	echo
	case "${action:-q}" in
		e|E) eval "$(resolve_editor)" "$(printf %q "$file")" ;;
		r|R) ;;
		*)   exit 0 ;;
	esac
done
