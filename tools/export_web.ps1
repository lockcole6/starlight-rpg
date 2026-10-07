param([string]$Godot = 'C:\Godot\Godot_v4.7-stable_win64_console.exe', [string]$Python = 'python')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $projectRoot
try {
    New-Item -ItemType Directory -Force build | Out-Null
    New-Item -ItemType File -Force build/.gdignore | Out-Null
    & $Python tools/fetch_web_dependencies.py
    if ($LASTEXITCODE -ne 0) { throw 'Webテンプレートの取得に失敗しました。' }
    & $Godot --headless --path . --editor --import --quit
    if ($LASTEXITCODE -ne 0) { throw 'Godotへの取り込みに失敗しました。' }
    New-Item -ItemType Directory -Force build/web | Out-Null
    & $Godot --headless --path . --export-release Web build/web/index.html
    if ($LASTEXITCODE -ne 0) { throw 'Web書き出しに失敗しました。' }
    & $Python tools/finalize_web.py
    if ($LASTEXITCODE -ne 0) { throw 'クレジットのコピーに失敗しました。' }
} finally { Pop-Location }
