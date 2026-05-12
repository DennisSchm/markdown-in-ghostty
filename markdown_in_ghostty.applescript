-- markdown-in-ghostty
-- File-open handler that renders Markdown in a Ghostty split.
-- The split runs view-md (bundled in Contents/Resources/), which renders with
-- glow and lets you toggle between rendered view and your $EDITOR.

on open theFiles
	set bundlePath to POSIX path of (path to me)
	set viewMd to bundlePath & "Contents/Resources/view-md"
	set stylePath to bundlePath & "Contents/Resources/style.json"
	repeat with f in theFiles
		set filePath to POSIX path of f
		set theCmd to quoted form of viewMd & " " & quoted form of filePath & " " & quoted form of stylePath
		openInGhostty(theCmd)
	end repeat
end open

on run
	display dialog "MarkdownInGhostty is a file-open handler.

Set it as the default application for Markdown files; Cmd-clicking a .md path inside any Ghostty terminal will split that window to the right and render the file with glow.

While viewing: press e to open the file in your $EDITOR, r to re-render, q to close the split." buttons {"OK"} default button "OK"
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
