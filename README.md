# markdown-in-ghostty

Cmd-click a `.md` path inside Ghostty and the window splits to the right, rendering the file with [`glow`](https://github.com/charmbracelet/glow). Press `q` to close the split.

## Requirements

- macOS
- [Ghostty](https://ghostty.org) 1.3 or later (introduced the AppleScript dictionary)
- [Homebrew](https://brew.sh)

## Install

```sh
./install.sh
```

The first Cmd-click triggers a one-time macOS prompt: *"MarkdownInGhostty wants to control Ghostty"* — click **OK**. Subsequent clicks are silent.

The installer is idempotent; re-run it after editing `markdown_in_ghostty.applescript` to apply changes.

## How it works

1. `install.sh` installs `glow` and `duti` via Homebrew, compiles `markdown_in_ghostty.applescript` into `~/Applications/MarkdownInGhostty.app`, and registers it via `duti` as the default handler for `.md`, `.markdown`, and the `net.daringfireball.markdown` UTI.
2. When you Cmd-click a `.md` path in Ghostty, macOS routes the file open to the handler app.
3. The handler uses Ghostty's native AppleScript dictionary (`split <terminal> direction right with configuration <cfg>`) to create a right-side split in the focused window, with `glow --pager --style auto --width 100 <file>` as the split's initial command.
4. When `glow` exits, the split closes.

Because the script controls the running Ghostty instance via Apple Events, existing tabs and panes are preserved across opens.

## Tuning

Edit `markdown_in_ghostty.applescript` and re-run `./install.sh`.

- Render style: change `--style auto` to `dracula`, `dark`, `light`, `pink`, or a JSON theme path (see `glow --help`).
- Width: change `--width 100`, or drop the flag to let `glow` auto-detect the split width.
- Direction: change `direction right` to `down`, `left`, or `up`.
- Use a different renderer: replace the `glowCmd` line with any command, e.g. `"/opt/homebrew/bin/bat --language=md --paging=always " & quoted form of filePath`.

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
| `glow` not found at runtime | Confirm `/opt/homebrew/bin/glow` exists (`which glow`). On Intel Macs the path is `/usr/local/bin/glow`; edit the AppleScript and re-run `./install.sh`. |
