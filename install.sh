#!/usr/bin/env bash
# Installer for markdown-in-ghostty.
# Idempotent — safe to re-run after edits to the AppleScript source.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$HOME/Applications"
APP_PATH="$APP_DIR/MarkdownInGhostty.app"
BUNDLE_ID="dev.local.MarkdownInGhostty"

log() { printf "[install] %s\n" "$1"; }
die() { printf "[install] error: %s\n" "$1" >&2; exit 1; }

# --- preflight ---

[[ "$(uname -s)" == "Darwin" ]] || die "macOS only."

[[ -d /Applications/Ghostty.app ]] || die "Ghostty.app not found in /Applications. Install from https://ghostty.org first."

GHOSTTY_VERSION="$(/Applications/Ghostty.app/Contents/MacOS/ghostty --version | head -1 | awk '{print $2}')"
case "$(printf '%s\n1.3.0\n' "$GHOSTTY_VERSION" | sort -V | head -1)" in
	1.3.0) ;;  # GHOSTTY_VERSION >= 1.3.0
	*)      die "Ghostty 1.3+ required (found $GHOSTTY_VERSION). The AppleScript dictionary was added in 1.3." ;;
esac
log "Ghostty $GHOSTTY_VERSION detected."

command -v brew >/dev/null || die "Homebrew required. Install from https://brew.sh first."

for pkg in glow duti; do
	if ! command -v "$pkg" >/dev/null; then
		log "Installing $pkg via brew..."
		brew install "$pkg"
	fi
done

# --- build the .app ---

mkdir -p "$APP_DIR"
log "Compiling AppleScript to $APP_PATH ..."
rm -rf "$APP_PATH"
osacompile -o "$APP_PATH" "$SCRIPT_DIR/markdown_in_ghostty.applescript"

PLIST="$APP_PATH/Contents/Info.plist"
PB=/usr/libexec/PlistBuddy
$PB -c "Add :CFBundleIdentifier string $BUNDLE_ID" "$PLIST"
$PB -c "Set :CFBundleName MarkdownInGhostty"       "$PLIST"
$PB -c "Add :CFBundleDocumentTypes:0 dict"                                          "$PLIST"
$PB -c "Add :CFBundleDocumentTypes:0:CFBundleTypeName string Markdown File"         "$PLIST"
$PB -c "Add :CFBundleDocumentTypes:0:CFBundleTypeRole string Viewer"                "$PLIST"
$PB -c "Add :CFBundleDocumentTypes:0:LSHandlerRank string Owner"                    "$PLIST"
$PB -c "Add :CFBundleDocumentTypes:0:LSItemContentTypes array"                      "$PLIST"
$PB -c "Add :CFBundleDocumentTypes:0:LSItemContentTypes:0 string net.daringfireball.markdown" "$PLIST"
$PB -c "Add :CFBundleDocumentTypes:0:CFBundleTypeExtensions array"                  "$PLIST"
$PB -c "Add :CFBundleDocumentTypes:0:CFBundleTypeExtensions:0 string md"            "$PLIST"
$PB -c "Add :CFBundleDocumentTypes:0:CFBundleTypeExtensions:1 string markdown"      "$PLIST"

log "Ad-hoc signing the bundle..."
codesign --force --deep --sign - "$APP_PATH" >/dev/null 2>&1

log "Registering with LaunchServices..."
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP_PATH"

log "Setting as default handler for .md, .markdown, net.daringfireball.markdown..."
duti -s "$BUNDLE_ID" .md       all
duti -s "$BUNDLE_ID" .markdown all
duti -s "$BUNDLE_ID" net.daringfireball.markdown all

log "Done. Current handler for .md:"
duti -x md | sed 's/^/         /'

cat <<'EOF'

Test it:
  1. Open any Ghostty terminal.
  2. Print a path to a .md file, e.g.:  echo /Users/$(whoami)/Development/some-file.md
  3. Cmd-click the path. The window splits to the right and renders the file with glow.
  4. Press q to close the split.

First Cmd-click triggers a one-time macOS prompt:
  "MarkdownInGhostty wants to control Ghostty" — click OK.

EOF
