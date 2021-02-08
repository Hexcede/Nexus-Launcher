;@Ahk2Exe-ExeName Nexus Launcher.exe
;@Ahk2Exe-SetOrigFilename Nexus Launcher.exe

;@Ahk2Exe-SetMainIcon nexus.ico
;@Ahk2Exe-SetCopyright Hexcede
;@Ahk2Exe-SetName Nexus Embedded Editor Launcher
;@Ahk2Exe-SetDescription Launcher for Nexus Embedded Editor

;; Config ;;
	; Whether or not studio should be linked to the launcher
	global StudioLinked := true
	; Keeps the window on top of the script editor view
	global KeepOnTop := true
	; If the Nexus Embedded Editor server closes, reopen it instead of quitting
	global PersistentServer := true
;; ;;;;;; ;;

#SingleInstance Force
DetectHiddenWindows, On
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
		return True

	UpdateProjectPath()
}

SetGlobal(globalName, value) {
	global
	%globalName% := value
}

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

	CreateMenuToggle("Studio &Linked", "StudioLinked")
	CreateMenuToggle("Nexus &Editor Integration (Watches for activation/deactivation to keep VSCode visible when clicking in Studio, may not be 100% reliable)", "KeepOnTop")
	CreateMenuToggle("&Persistent Server", "PersistentServer")
	CreateMenuButton(projectPath, "PromptSelectProjectDir")

	Menu, Tray, Add
	CreateMenuButton("&Exit", "QuitApp")

	; Menu, Tray, Standard
}
CreateTray()

QuitApp() {
	ExitApp
}

MenuSet(itemName, value) {
	if (value) {
		Menu, Tray, Check, %itemName%
	}
	else {
		Menu, Tray, Uncheck, %itemName%
	}
	SetGlobal(MenuValues[itemName], value)
}
MenuToggle(itemName) {
	valueName := MenuValues[itemName]
	MenuSet(itemName, !%valueName%)
}

global restarting := false
RestartNexusServer() {
	restarting := true

	if (WinExist("ahk_exe NexusEmbeddedVSCode.exe")) {
		KillServer(true)
	}

	Run, NexusEmbeddedVSCode.exe, %projectPath%, Hide UseErrorLevel
	if (ErrorLevel) {
		MsgBox, Couldn't find Nexus Embedded Editor (NexusEmbeddedVSCode.exe)
		ExitApp
	}

	while (!WinExist("ahk_exe NexusEmbeddedVSCode.exe")) {
		Sleep, 30
	}

	restarting := false
}

if (!WinExist("ahk_exe NexusEmbeddedVSCode.exe")) {
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

	RestartNexusServer()
}

StartStudio() {
	if (!WinExist("ahk_exe RobloxStudioBeta.exe")) {
		Run, RobloxStudioModManager.exe, , UseErrorLevel
		if (ErrorLevel) {
			Run, "%LocalAppdata%\Roblox\Versions\RobloxStudioLauncherBeta.exe", , UseErrorLevel
			if (ErrorLevel) {
				MsgBox, Couldn't locate Roblox Studio Mod Manager and vanilla Roblox Studio is not installed
				ExitApp
			}
		}
		
		while (!WinExist("ahk_exe RobloxStudioBeta.exe")) {
			Sleep, 30
		}
	}
	else {
		WinActivate, ahk_exe RobloxStudioBeta.exe
	}
}

OnExit("KillServer")
KillServer(restart:=false) {
	WinKill, ahk_exe NexusEmbeddedVSCode.exe
	if (!restart) {
		if (StudioLinked) {
			WinKill, ahk_exe RobloxStudioBeta.exe
		}
	}
	else {
		while (WinExist("ahk_exe NexusEmbeddedVSCode.exe")) {
			Sleep, 30
		}
	}
}

Main() {
	StartStudio()
	wasActive := false
	loop {
		while (restarting) {
			Sleep, 30
		}

		if (!WinExist("ahk_exe NexusEmbeddedVSCode.exe")) {
			if (!PersistentServer) {
				ExitApp
			}
			else {
				RestartNexusServer()
			}
		}

		; NOTE: This is designed to detect VSCode being selected by Nexus Embedded Editor
		; Nexus instantly updates the activity of the window,
		;  whereas user interaction requires the previous window to be deactivated since the user clicks on the explorer (or Alt+Tabs).
		tryReset := !KeepOnTop
		if (KeepOnTop) {
			roblox := WinActive("ahk_exe RobloxStudioBeta.exe")
			if (roblox) {
				wasActive := true
			}
			else {
				if (wasActive) {
					if (WinActive("ahk_exe code.exe")) {
						if (!isActive) {
							isActive := true
							Winset, Alwaysontop, 1, ahk_exe code.exe
						}
					}
				}
				else {
					tryReset := true
				}
				wasActive := false
			}

			if (!WinActive("ahk_exe code.exe")) {
				if (isActive) {
					; Force an update
					Winset, Alwaysontop, 0, ahk_exe code.exe
					Sleep, 33
					Winset, Alwaysontop, 1, ahk_exe code.exe
				}
			}
		}

		if (tryReset) {
			if (!WinActive("ahk_exe code.exe")) {
				if (isActive) {
					isActive := false
					Winset, Alwaysontop, 0, ahk_exe code.exe
				}
			}
		}

		; if (KeepOnTop) {
		; 	roblox := WinExist("ahk_exe RobloxStudioBeta.exe")
		; 	vscode := WinExist("ahk_exe code.exe")

		; 	windows := 0
		; 	rblx := false

		; 	WinGet, windows, List
		; 	loop windows {
		; 		windowVar := windows%A_Index%
		; 		windowId := %windowVar%

		; 		if (!rblx) {
		; 			if (windowId == roblox) {
		; 				rblx := true
		; 			}
		; 		}
		; 		else {
		; 			if (windowId == vscode) {
		; 				if (!isActive) {
		; 					isActive := true
		; 					Winset, Alwaysontop, 1, ahk_exe code.exe
		; 				}
		; 			}
		; 			else {
		; 				rblx := false
		; 			}
		; 			break
		; 		}
		; 	}

		; 	if (!rblx) {
		; 		if (!WinActive("ahk_exe code.exe")) {
		; 			if (isActive) {
		; 				isActive := false
		; 				Winset, Alwaysontop, 0, ahk_exe code.exe
		; 			}
		; 		}
		; 	}
		; }
		Sleep, 33
	}
}
SetTimer, Main, -1

~LButton::
	if (KeepOnTop) {
		if (isActive) {
			MouseGetPos, lx, ly, win2
			win := WinExist("ahk_exe code.exe")

			if (win == win2) {
				WinGetPos, x, y, w, h, ahk_id %win%
				
				release := 0
				dragged := false
				loop {
					if (release >= 5) {
						break
					}

					WinGetPos, x2, y2, w2, h2, ahk_id %win%
					if (x != x2 || y != y2 || w != w2 || h != h2) {
						; Window was dragged
						dx := x2 - x
						dy := y2 - y
						Click, Up
						; BlockInput, MouseMove
						MouseMove, lx + dx, ly + dx, 0
						WinMove, ahk_id %win%, , x, y, w, h
						dragged := true
					}

					Sleep, 1
					if (dragged || !GetKeyState("LButton", "p")) {
						release := release + 1
					}
					else {
						release := 0
					}
				}
				BlockInput, MouseMoveOff
			}
		}
	}
return