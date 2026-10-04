' CloudMC 隐藏启动脚本
' 双击此文件可在后台启动管理面板（无控制台窗口）

Set WshShell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

' 获取脚本所在目录
scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)

' 启动管理面板（隐藏窗口）
WshShell.Run "cmd /c cd /d """ & scriptDir & """ && python app.py", 0, False

' 启动守护进程（隐藏窗口）
WshShell.Run "cmd /c cd /d """ & scriptDir & """ && watchdog.bat", 0, False
