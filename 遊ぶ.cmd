@echo off
setlocal
set "STARLIGHT_GODOT=C:\Godot\Godot_v4.7-stable_win64.exe"
if not exist "%STARLIGHT_GODOT%" (
  echo Godot 4.7 was not found. Open project.godot in Godot and press F5.
  pause
  exit /b 1
)
"%STARLIGHT_GODOT%" --path "%~dp0."
