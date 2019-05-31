-- This script shows a dialog box that asks for a date and then (1) uses the shell command "touch" (see "man touch" for details) to create an empty html file in save_path with that creation date, then (2) sets the file extension of the file to hidden, then (3) changes the file metadata so that it always opens with TextEdit, then (4) opens the file in TextEdit, and then (5) inserts the creation date into the document body. Apple's Developer Tools must be installed before using this script so that the Rez and SetFile commands are available. The date input format is the format provided by the "Insert Short Date & Time" command in the free OS X service WordService, which can be downloaded from DEVONtechnologies at http://www.devontechnologies.com/products/freeware.html (of course this script could also be modified to handle any other date format). Check the following properties below and make sure they are correct before running the script: property save_path and property resource_fork_path.

-- path where the new file will be saved:
property save_path : "/Volumes/Shared Drive/Nathan/Journal/Uncategorized/"

-- file containing the resource fork to be appended to the new file so that the file always opens in TextEdit; for more info see: https://superuser.com/questions/259248/mac-osx-change-file-association-per-file-on-the-command-line
property resource_fork_path : "/Users/quadcore/.TextEdit.r"

on run
	try
		-- get the name of the active application so that we can go back to it if user cancels
		tell application "System Events"
			set active_app to name of first application process whose frontmost is true
		end tell
		-- use unix "date" command to get the current date & time; put it in dialog box
		set current_date to (do shell script "date \"+%Y/%m/%d, %H:%M:%S %p\"")
		tell application "System Events"
			activate
			set the_date to display dialog "Enter date in format YYYY/MM/DD[,] [h]h:mm:ss [AM/PM]" buttons {"Cancel", "OK"} default button "OK" cancel button "Cancel" default answer (current_date as string) with title "Create File with Specified Creation Date"
		end tell
		-- exit if cancel
		if the button returned of the_date is "OK" then
			set date_original to text returned of the_date
			if "," is in date_original then
				-- remove commas from input
				set date_unparsed to replaceText(date_original, ",", "")
			else
				set date_unparsed to date_original
			end if
			if text -1 of date_unparsed is in {":", " "} then
				-- trim colon or space from end of input date
				repeat until text -1 of date_unparsed is not in {":", " "}
					set date_unparsed to trimLastChar(date_unparsed)
				end repeat
			end if
			if (text -2 thru -1 of date_unparsed) is "AM" then
				set afternoon to false
				-- trim from end of input date
				repeat until text -1 of date_unparsed is not in {"A", "M", "P", " "}
					set date_unparsed to trimLastChar(date_unparsed)
				end repeat
			else if (text -2 thru -1 of date_unparsed) is "PM" then
				set afternoon to true
				-- trim from end of input date
				repeat until text -1 of date_unparsed is not in {"A", "M", "P", " "}
					set date_unparsed to trimLastChar(date_unparsed)
				end repeat
			else
				set afternoon to "unset"
			end if
			set date_parsed to text 1 thru 4 of date_unparsed -- YYYY
			set date_parsed to (date_parsed & (text 6 thru 7 of date_unparsed)) -- MM
			set date_parsed to (date_parsed & (text 9 thru 10 of date_unparsed)) --DD
			if the length of date_unparsed is 19 then
				-- parse double-digit hour hh
				set date_hour to (text 12 thru 13 of date_unparsed)
				if (date_hour as number) is less than 12 then
					if afternoon is true then
						set date_hour to (date_hour + 12)
					end if
				else if (date_hour as number) is 12 then
					if afternoon is false then
						set date_hour to "00" as string
					end if
				end if
				set date_parsed to (date_parsed & date_hour) -- hh
				set date_parsed to (date_parsed & (text 15 thru 16 of date_unparsed)) -- mm
				set date_parsed to (date_parsed & "." & (text 18 thru 19 of date_unparsed)) -- ss
			else if the length of date_unparsed is 18 then
				-- parse single-digit hour h
				set date_hour to (text 12 of date_unparsed)
				if afternoon is true then
					set date_hour to (date_hour + 12)
				else
					set date_hour to ("0" & date_hour)
				end if
				set date_parsed to (date_parsed & date_hour) -- hh
				set date_parsed to (date_parsed & (text 14 thru 15 of date_unparsed)) -- mm
				set date_parsed to (date_parsed & "." & (text 17 thru 18 of date_unparsed)) -- ss
			end if
			set file_name to (date_parsed & ".html")
			set output_file_path to (save_path & file_name)
			set shell_script to "touch -t " & date_parsed & space & quoted form of output_file_path & " ; setFile -a E " & quoted form of output_file_path & " ; Rez " & quoted form of resource_fork_path & " -a -o " & quoted form of output_file_path & " ; open -e " & quoted form of output_file_path -- create a new empty file, hide its file extension, set the file to open always with TextEdit, and then open the file in TextEdit
			do shell script shell_script
			repeat until application "TextEdit" is running
				-- wait until TextEdit is running
				delay 0.2
			end repeat
			tell application "TextEdit"
				repeat until (document (date_parsed as string) exists) or (document (file_name as string) exists)
					-- wait until the document is open
					delay 0.2
				end repeat
				if (document (date_parsed as string) exists) then
					set window_name to date_parsed
				else if (document (file_name as string) exists) then
					set window_name to file_name
				end if
				tell document (window_name as string) to set its text to date_original as string -- insert input date into the file
				set font of text of document (window_name as string) to "Arial"
				activate
			end tell
			tell application "System Events" to tell process "TextEdit" -- workaround for strange font behavior in TextEdit: without this code, the font at the insertion point is TextEdit's default font
				key code 123 -- left arrow
				key code 124 -- right arrow
			end tell
		end if
	on error
		tell application active_app
			activate
		end tell
	end try
end run

on trimLastChar(theText)
	(*
	trimLastChar routine copied from https://stackoverflow.com/questions/32304097/applescript-remove-last-character-in-text-string
	*)
	if length of theText = 0 then
		error "Can't trim empty text." number -1728
	else if length of theText = 1 then
		return ""
	else
		return text 1 thru -2 of theText
	end if
end trimLastChar

on replaceText(someText, oldItem, newItem)
	(*
	replaceText routine copied from https://discussions.apple.com/thread/4588230
	replace all occurrences of oldItem with newItem
	parameters
		someText [text]: the text containing the item(s) to change
		oldItem [text, list of text]: the item to be replaced
		newItem [text]: the item to replace with
	returns [text]: the text with the item(s) replaced
	*)
	set {tempTID, AppleScript's text item delimiters} to {AppleScript's text item delimiters, oldItem}
	try
		set {itemList, AppleScript's text item delimiters} to {text items of someText, newItem}
		set {someText, AppleScript's text item delimiters} to {itemList as text, tempTID}
	on error errorMessage number errorNumber -- oops
		set AppleScript's text item delimiters to tempTID
		error errorMessage number errorNumber -- pass it on
	end try
	return someText
end replaceText
