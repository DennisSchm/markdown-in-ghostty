-- markdown-in-ghostty
-- File-open handler that renders Markdown in a Ghostty split via glow.
-- Set as default app for .md files; Cmd-clicking a .md path in any Ghostty
-- terminal splits the focused window to the right and runs glow there.

on open theFiles
	repeat with f in theFiles
		set filePath to POSIX path of f
		set glowCmd to "/opt/homebrew/bin/glow --pager --style auto --width 100 " & quoted form of filePath
		openInGhostty(glowCmd)
	end repeat
end open

on run
	display dialog "MarkdownInGhostty is a file-open handler.

Set it as the default application for Markdown files; Cmd-clicking a .md path inside any Ghostty terminal will split that window to the right and render the file with glow." buttons {"OK"} default button "OK"
end run

on openInGhostty(theCommand)
	tell application "Ghostty"
		activate
		set cfg to new surface configuration
		set command of cfg to theCommand
		if (count of windows) is 0 then
			new window with configuration cfg
		else
			set frontTerm to focused terminal of selected tab of front window
			split frontTerm direction right with configuration cfg
		end if
	end tell
end openInGhostty
