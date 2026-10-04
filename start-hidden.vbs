' CloudMC Hidden Launcher
' Starts management panel in background (no console window)

Set WshShell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

' Get script directory
scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)

' Start management panel (hidden window) using start-server.bat
WshShell.Run "cmd /c cd /d """ & scriptDir & """ && start-server.bat", 0, False
