# markdown-in-ghostty

Cmd-click a `.md` path inside Ghostty and the window splits to the right, rendering the file with [`glow`](https://github.com/charmbracelet/glow) through a small wrapper that lets you toggle between rendered view and your editor.

## Requirements

- macOS
- [Ghostty](https://ghostty.org) 1.3 or later (introduced the AppleScript dictionary)
- [Homebrew](https://brew.sh)

## Install

```sh
./install.sh
```

The first Cmd-click triggers a one-time macOS prompt: *"MarkdownInGhostty wants to control Ghostty"* — click **OK**.

The installer is idempotent; re-run it after editing any source file to apply changes.

## In the split

After `glow` exits you get a prompt:

```
[e] edit   [r] re-render   [q] close   >
```

- **e** opens the file in `$EDITOR` (defaults to `nvim`, then `vi`). After the editor exits, the loop returns to the rendered view, so saved edits appear immediately.
- **r** re-renders without re-opening the editor.
- **q** (or any other key) closes the split.

For a GUI editor that returns immediately (e.g. VS Code), use the blocking form: `export EDITOR="code --wait"`.

## Layout

```
markdown_in_ghostty.applescript    Compiled into MarkdownInGhostty.app
view-md.sh                         The glow + edit loop, bundled into the .app
style.json                         Custom glow theme (extends glamour's "dark")
install.sh                         Idempotent installer
example.md                         Test fixture covering most Markdown features
```

The `.app` lives at `~/Applications/MarkdownInGhostty.app` after install; `view-md.sh` and `style.json` are copied into `Contents/Resources/` so the handler is self-contained.

## How it works

1. `install.sh` installs `glow` and `duti` via Homebrew, compiles `markdown_in_ghostty.applescript` into `~/Applications/MarkdownInGhostty.app`, bundles `view-md.sh` and `style.json` into the app's `Contents/Resources/`, and registers the app via `duti` as the handler for `.md`, `.markdown`, and the `net.daringfireball.markdown` UTI.
2. When you Cmd-click a `.md` path in Ghostty, macOS routes the file open to the handler app.
3. The handler uses Ghostty's native AppleScript dictionary (`split <terminal> direction right with configuration <cfg>`) to create a right-side split in the focused window, with `view-md <file> <style.json>` as the split's initial command.
4. `view-md` runs `glow --pager --style <style.json> --width 100 <file>`, then enters the toggle loop.

Because the script controls the running Ghostty instance via Apple Events, existing tabs and panes are preserved across opens.

## Custom style

`style.json` extends glamour's `dark` style with:

- `code_block.margin: 4` (default is 2) — more vertical breathing room around fenced code.
- `code_block.chroma.background.background_color: "#1d1d1d"` — darker block background for stronger contrast against the page.

Edit `style.json` and re-run `./install.sh` to apply. See the [glamour styles directory](https://github.com/charmbracelet/glamour/tree/master/styles) for the full list of fields you can override.

## Tuning

Edit the source files and re-run `./install.sh`.

| Want to change | Edit | Field |
|---|---|---|
| Render style (dark / light / dracula / pink / custom path) | `view-md.sh` | `glow --style "$style"` argument |
| Line width | `view-md.sh` | `glow --width 100` |
| Split direction | `markdown_in_ghostty.applescript` | `direction right` → `down` / `left` / `up` |
| Editor used by `e` | environment | `export EDITOR=...` |
| Code-block spacing or colors | `style.json` | `code_block.*` |

## Interactive checkboxes

Terminal markdown renderers display `- [ ]` / `- [x]` as styled glyphs but cannot capture clicks — there is no DOM behind the output, only a sequence of cells in the terminal grid. Toggling checkboxes interactively needs a GUI renderer:

- **Obsidian** — click a checkbox in any vault file to toggle it.
- **VS Code Markdown preview** — checkboxes toggle in the preview pane.

The closest terminal-side option is editing the file: press `e` in the view-md prompt, toggle `[ ]` ↔ `[x]` in your editor, save and quit. The view re-renders with the updated state.

## Uninstall

```sh
duti -s com.apple.TextEdit .md       all
duti -s com.apple.TextEdit .markdown all
duti -s com.apple.TextEdit net.daringfireball.markdown all
rm -rf ~/Applications/MarkdownInGhostty.app
```

## Troubleshooting

| Symptom | Fix |
|---|---|
| Cmd-click opens the file in TextEdit (or any other app) | LaunchServices may be holding a cached binding. Run `/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user`, then re-run `./install.sh`. |
| Ghostty comes to the front but no split appears | The script needs at least one Ghostty window open. Open a window first, then Cmd-click again. |
| macOS keeps asking for control permission | System Settings → Privacy & Security → Automation → expand **MarkdownInGhostty** and toggle **Ghostty** on. |
| `glow` not found at runtime | Confirm `/opt/homebrew/bin/glow` exists (`which glow`). On Intel Macs the path is `/usr/local/bin/glow`; set `export GLOW=/usr/local/bin/glow` in your shell rc, or edit `view-md.sh` and re-run `./install.sh`. |
