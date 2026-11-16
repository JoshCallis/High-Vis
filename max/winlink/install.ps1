# install.ps1 -- build winlink.exe in the VM and run it at login (max/winlink/install.sh runs this).
#   -Revert   stop it, drop the Run entry and the exe
# ASCII only: Windows PowerShell reads a BOM-less file as ANSI.
param([switch]$Revert)
$ErrorActionPreference = 'Stop'
$dir = Join-Path $env:LOCALAPPDATA 'Callis'
$exe = Join-Path $dir 'winlink.exe'
$run = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'

Get-Process winlink -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 300
if ($Revert) {
  Remove-ItemProperty -Path $run -Name 'CallisWinLink' -ErrorAction SilentlyContinue
  Remove-Item $exe -ErrorAction SilentlyContinue
  'reverted'
  exit 0
}

New-Item -ItemType Directory -Force $dir | Out-Null
$fw = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319'
$csc = Join-Path $fw 'csc.exe'
$src = Join-Path $dir 'winlink.cs'
Copy-Item '\\Mac\ClaudeMax\winlink\winlink.cs' $src -Force
& $csc /nologo /optimize+ /target:winexe /out:$exe "/lib:$fw\WPF" `
  /r:UIAutomationClient.dll /r:UIAutomationTypes.dll /r:WindowsBase.dll /r:System.Windows.Forms.dll $src
if ($LASTEXITCODE -ne 0) { throw "csc failed ($LASTEXITCODE)" }

Set-ItemProperty -Path $run -Name 'CallisWinLink' -Value ('"' + $exe + '"')
Start-Process $exe
"installed $exe"
