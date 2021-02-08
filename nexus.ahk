;@Ahk2Exe-ExeName Nexus Launcher.exe
;@Ahk2Exe-SetOrigFilename Nexus Launcher.exe

;@Ahk2Exe-SetMainIcon nexus.ico
;@Ahk2Exe-SetCopyright Hexcede
;@Ahk2Exe-SetName Nexus Embedded Editor Launcher
;@Ahk2Exe-SetDescription Launcher for Nexus Embedded Editor

;; Default Config ;;
	; Whether or not Vanilla Studio should be displayed when the launcher is opened
	; This is disabled by default since Vanilla Studio is rather bulky and flashes the task bar when its done loading
	; I personally find this very annoying, and RSMM is near instant since it doesn't actually load studio until you tell it to
	global IntrusiveStudioLaunchMode := false

	; Whether or not studio should be linked to the launcher
	global StudioLinked := true
	; Keeps the window on top of the script editor view
	global KeepOnTop := true
	; If the Nexus Embedded Editor server closes, reopen it instead of quitting
	global PersistentServer := true
;; ;;;;;;;;;;;;;; ;;

#WinActivateForce ; Helps with taskbar flash issues
#SingleInstance Force ; Make sure we don't run more than one instance of the launcher
DetectHiddenWindows, On ; We hide the Nexus Server process, and, we need to detect it
; I wish these were defaults
SetWinDelay, -1
SetKeyDelay, -1
SetMouseDelay, -1

global projectPrompt := "Select a project directory for the editor"

global isActive := false
global projectPath = "Select project"
global _projectPath_old = projectPath

UpdateProjectPath() {
	Menu, Tray, Rename, %_projectPath_old%, %projectPath%
	_projectPath_old := projectPath

	RestartNexusServer()
}
PromptSelectProjectDir(defaultDir) {
	if (!defaultDir)
		defaultDir := projectPath
	
	FileSelectFolder, projectPath, *%defaultDir%, 0, %projectPrompt%
	if (ErrorLevel)
		return true

	UpdateProjectPath()
}

; Helper function to set a global by name (Since this currently isn't a built in feature)
SetGlobal(globalName, value) {
	global
	%globalName% := value
}

; Traybar helpers
global MenuValues := {}
CreateMenuToggle(itemName, valueName) {
	SetGlobal(valueName "Text", itemName)

	MenuValues[itemName] := valueName

	Menu, Tray, Add, %itemName%, MenuToggle
	MenuSet(itemName, %valueName%)
}
CreateMenuButton(itemName, callback, isDefault:=false) {
	Menu, Tray, Add, %itemName%, %callback%
	if (isDefault) {
		Menu, Tray, Default, %itemName%
		Menu, Tray, Click, 1
	}
}

CreateTray() {
	Menu, Tray, NoStandard

	CreateMenuButton("Launch &Studio", "StartStudio", true)
	CreateMenuButton("&Restart Nexus Server", "RestartNexusServer")

	Menu, Tray, Add

	CreateMenuToggle("&Close Studio when Nexus Launcher is closed", "StudioLinked")
	CreateMenuToggle("Nexus Editor &Attach Integration", "KeepOnTop")
	CreateMenuToggle("Nexus Server is &Persistent", "PersistentServer")
	CreateMenuButton(projectPath, "PromptSelectProjectDir")

	Menu, Tray, Add
	; Custom Exit button (Since I can only remove all or none of the standard options)
	CreateMenuButton("&Exit", "QuitApp")

	; Add back the standard AutoHotKey buttons
	; Menu, Tray, Standard
}
CreateTray() ; Create the traybar

; For the exit button
QuitApp() {
	ExitApp
}

; Set a checkbox value
MenuSet(itemName, value) {
	if (value) {
		Menu, Tray, Check, %itemName%
	}
	else {
		Menu, Tray, Uncheck, %itemName%
	}
	SetGlobal(MenuValues[itemName], value)
}
; Toggle a checkbox value
MenuToggle(itemName) {
	valueName := MenuValues[itemName]
	MenuSet(itemName, !%valueName%)
}

; Nexus Server helpers
global restarting := false
RestartNexusServer() {
	restarting := true

	; Kill running server
	if (WinExist("ahk_exe NexusEmbeddedVSCode.exe")) {
		KillServer(true)
	}

	; Run the server in the project path
	Run, NexusEmbeddedVSCode.exe, %projectPath%, Hide UseErrorLevel
	if (ErrorLevel) {
		MsgBox, Couldn't find Nexus Embedded Editor (NexusEmbeddedVSCode.exe)
		ExitApp
	}

	; Wait for the server to start
	while (!WinExist("ahk_exe NexusEmbeddedVSCode.exe")) {
		Sleep, 100
	}

	restarting := false
}

if (!WinExist("ahk_exe NexusEmbeddedVSCode.exe")) {
	; Take the path from arguments, or prompt for one
	projectPath := ""
	if (A_Args.length > 0) {
		for i, arg in A_Args {
			projectPath := projectPath arg
		}
		UpdateProjectPath()
	}
	else {
		if (PromptSelectProjectDir(A_WorkingDir)) {
			ExitApp
		}
	}

	; Start the Nexus Server
	RestartNexusServer()
}

; Studio start helpers
StartStudio(itemName:=false) {
	instrusiveLaunchMode := true
	if (!itemName) { ; Not inside of the tray callback, meaning its automatic startup, so don't be intrusive
		; Basically all this does is prevent vanilla studio from showing up, since RSMM is far less bulky
		intrusiveLaunchMode := IntrusiveStudioLaunchMode
	}

	if (!WinExist("ahk_exe RobloxStudioBeta.exe")) {
		Run, RobloxStudioModManager.exe, , UseErrorLevel
		if (ErrorLevel) {
			if (intrusiveLaunchMode) {
				; Launch vanilla studio
				Run, "%LocalAppdata%\Roblox\Versions\RobloxStudioLauncherBeta.exe", , UseErrorLevel
				if (ErrorLevel) {
					MsgBox, Couldn't locate Roblox Studio Mod Manager and vanilla Roblox Studio is not installed
					ExitApp
				}
			}
		}
		
		; Wait for Studio to be opened
		while (!WinExist("ahk_exe RobloxStudioBeta.exe")) {
			Sleep, 30
		}
	}
	else {
		; Activate existing Studio instance
		if (intrusiveLaunchMode) {
			WinActivate, ahk_exe RobloxStudioBeta.exe
		}
	}
}

; Hook for when the script is closed
OnExit("KillServer") ; Make sure that the Nexus Server goes down when the Launcher closes
KillServer(restart:=false) {
	WinKill, ahk_exe NexusEmbeddedVSCode.exe
	if (!restart) {
		; We're doing a full shutdown
		if (StudioLinked) {
			; Kill studio if its running
			WinKill, ahk_exe RobloxStudioBeta.exe
		}
	}
	else {
		; Wait for Nexus Server to close
		while (WinExist("ahk_exe NexusEmbeddedVSCode.exe")) {
			Sleep, 100
		}
	}
}

Main() {
	; Attempt to start studio
	StartStudio()

	; Main loop for various passive checks
	; We don't want to do any CPU intensive checks here
	wasActive := false
	loop {
		; Wait til we're not restarting the Nexus Editor Server
		while (restarting) {
			Sleep, 350
		}

		; Server crashed/closed?
		if (!WinExist("ahk_exe NexusEmbeddedVSCode.exe")) {
			if (!PersistentServer) {
				; Exit if we're not in persistent mode
				ExitApp
			}
			else {
				; Start the server back up
				RestartNexusServer()
			}
		}

		; Get the id of Roblox Studio if its active
		roblox := WinActive("ahk_exe RobloxStudioBeta.exe")

		; NOTE: This is designed to detect VSCode being selected by Nexus Embedded Editor
		; Nexus instantly updates the activity of the window,
		;  whereas user interaction requires the previous window to be deactivated since the user clicks on the explorer (or Alt+Tabs).
		tryReset := !KeepOnTop
		if (KeepOnTop) {
			; Check if Roblox Studio is active
			if (roblox) {
				; Mark that we were just on studio
				wasActive := true
			}
			else {
				; If we were just on studio last time we checked, and now VSCode is visible, it means that Nexus (or some other program) brought VSCode to the top, which is how I detect Attaching

				; The reason that user interaction will never trigger this is because clicking on, for example, the windows explorer focuses it first
				; Every Windows GUI in existance will be focused if you click it (except in potential cases where user input is processed manually through custom APIs, in which case, the GUI program is likely fixed in the background)
				; I can rely on this to tell me if the window was switched to via mouse interaction in pretty much any case
				if (wasActive) {
					if (WinActive("ahk_exe code.exe")) {
						if (!isActive) {
							isActive := true
							; Put VSCode on top of studio and allow defocusing
							Winset, Alwaysontop, 1, ahk_exe code.exe
						}
					}
				}
				else {
					; Make sure that we allow AlwaysOnTop resets if studio isn't active
					tryReset := true
				}
				; Mark that we aren't on studio anymore
				wasActive := false
			}

			; Remove me
			; If VSCode isn't actually active but we're marked as being active, we want to make sure it stays on top
			; This helps with reliability a little, but, pretty soon it hopefully shouldn't be necessary, as its hacky
			; I really don't know why this helps, but, recent improvements have probably made it pointless
			if (!WinActive("ahk_exe code.exe")) {
				if (isActive) {
					; Force an update
					Winset, Alwaysontop, 0, ahk_exe code.exe
					Sleep, 5
					Winset, Alwaysontop, 1, ahk_exe code.exe
				}
			}
		}

		; Try to reset the active state
		if (tryReset) {
			if (!WinActive("ahk_exe code.exe")) {
				if (isActive) {
					; VSCode is hidden and we're active, so, set us to be inactive and allow the window to be unfocused
					; This makes sure that the user can, well, alt tab, or switch windows
					; We don't want the editor to stick to their screen until Nexus Embedded Editor hides the window
					isActive := false
					Winset, Alwaysontop, 0, ahk_exe code.exe
				}
			}
		}

		; If we're not on Roblox, its safe to assume our checks probably don't need to be as fast
		if (roblox) {
			Sleep, 250 - 33
		}

		; Give a little time before trying to check stuff again so we don't eat up CPU
		Sleep, 33 ; ~30 FPS
	}
}
; Start the Main thread instantly
SetTimer, Main, -1

; Editor drag prevention
~LButton::
	if (KeepOnTop) {
		if (isActive) {
			; Get the mouse position
			MouseGetPos, lx, ly, win2
			; Get VSCode's window
			win := WinExist("ahk_exe code.exe")

			if (win == win2) {
				; Get the position of VSCode's window
				WinGetPos, x, y, w, h, ahk_id %win%
				
				release := 0
				dragged := false
				loop {
					if (release >= 5) {
						; Release the loop after 5 ms
						; This gives the loop 5 ms to move VSCode back to its original position
						break
					}

					; Get the current window position and check if its moved
					WinGetPos, x2, y2, w2, h2, ahk_id %win%
					if (x != x2 || y != y2 || w != w2 || h != h2) {
						; Window was dragged
						; Release the button to stop dragging
						Click, Up
						; Move the window back to its original position
						WinMove, ahk_id %win%, , x, y, w, h
						dragged := true ; Mark that the window was dragged
					}

					Sleep, 1
					; If the mouse is released, or the window was dragged (meaning we released the mouse), we know we can release the loop
					if (dragged || !GetKeyState("LButton", "p")) {
						release := release + 1
					}
					else {
						release := 0
					}
				}
			}
		}
	}
return