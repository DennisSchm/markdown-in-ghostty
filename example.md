# Hello from glow

This is the test fixture for **markdown-in-ghostty**. If you can read this comfortably inside a Ghostty split, your setup is working.

---

## Headings render as banners

### Level three

#### Level four

##### Level five

## Emphasis

*italic*, **bold**, ***bold italic***, ~~strikethrough~~, and `inline code`.

## Code blocks get syntax highlighting

```bash
#!/usr/bin/env bash
set -euo pipefail

for i in 1 2 3; do
  printf "  iteration %d\n" "$i"
done
```

```rust
fn main() {
    let greeting = "Hello, glow";
    println!("{greeting} — rendered in a Ghostty split");
}
```

```applescript
tell application "Ghostty"
    activate
    set frontTerm to focused terminal of selected tab of front window
    set cfg to new surface configuration
    set command of cfg to "/opt/homebrew/bin/glow --pager --style auto"
    split frontTerm direction right with configuration cfg
end tell
```

## Lists

Unordered, with nesting:

- Compile the AppleScript to a `.app` bundle
- Register the bundle via `duti`
  - As `LSHandlerRank = Owner`
  - For both `.md` extension and `net.daringfireball.markdown` UTI
- Sit back

Ordered:

1. macOS routes the file open to the handler
2. The handler calls Ghostty over Apple Events
3. Ghostty splits the current window and runs `glow`

Task list:

- [x] AppleScript handler compiled
- [x] Registered as default for `.md`
- [ ] Decide whether to keep `glow` or experiment with `mdcat`

## Blockquote

> Cmd-clicking a path in a terminal handing off to a GUI handler that re-enters the same terminal over Apple Events is a quietly beautiful loop.

## Table

| Tool     | Role                         | License |
|----------|------------------------------|---------|
| Ghostty  | Terminal emulator            | MIT     |
| glow     | Markdown renderer (terminal) | MIT     |
| duti     | LaunchServices CLI           | MIT     |

## Links

- [Ghostty](https://ghostty.org)
- [glow](https://github.com/charmbracelet/glow)
- [duti](https://github.com/moretension/duti)

---

Press `q` to close the split.
