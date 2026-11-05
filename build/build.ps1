param(
    [string]$AhkRoot = "$env:LOCALAPPDATA\Programs\AutoHotkey",
    [string]$ISCC = "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe",
    [string]$RcEdit = ""
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
if (!$RcEdit) { $RcEdit = Join-Path $root 'tools\rcedit-x64.exe' }
$runtime = Join-Path $AhkRoot 'v2\AutoHotkey64.exe'
$compiler = Join-Path $AhkRoot 'Compiler\Ahk2Exe.exe'
foreach ($tool in @($runtime, $compiler, $ISCC, $RcEdit)) {
    if (!(Test-Path -LiteralPath $tool)) { throw "Build tool not found: $tool" }
}

function Quote-Arg([string]$value) {
    if ($value -match '[\s"]') {
        return '"' + ($value -replace '"', '""') + '"'
    }
    return $value
}

function Invoke-Tool {
    param([string]$Exe, [string[]]$Arguments, [string]$WorkDir = $root)
    $quoted = @()
    foreach ($arg in $Arguments) { $quoted += Quote-Arg $arg }
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $Exe
    $psi.WorkingDirectory = $WorkDir
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.Arguments = [string]::Join(' ', $quoted)
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi
    [void]$process.Start()
    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()
    $process.WaitForExit()
    $text = (($stdout + $stderr) -join "`n").Trim()
    if ($text) { Write-Host $text }
    return $process.ExitCode
}

$ui = Get-Content (Join-Path $root 'src\ui.ahk') -Raw -Encoding UTF8
$installer = Get-Content (Join-Path $PSScriptRoot 'installer.iss') -Raw -Encoding UTF8
$version = [regex]::Match($ui, 'APP_VERSION\s*:=\s*"(\d+\.\d+\.\d+)"').Groups[1].Value
$setupVersion = [regex]::Match($installer, '#define MyAppVersion\s+"([^"]+)"').Groups[1].Value
if (!$version -or $version -ne $setupVersion) { throw 'Application and installer versions must match.' }

$tempExe = Join-Path $PSScriptRoot ('release-' + [guid]::NewGuid().ToString('N') + '.exe')
Push-Location $root
try {
    $rc = Invoke-Tool $runtime @('/ErrorStdOut', '/validate', (Join-Path $root 'layout-switcher.ahk'))
    if ($rc -ne 0) { throw 'Application syntax validation failed.' }
    $resultFile = Join-Path $env:TEMP ('keyswitcher-smoke-' + [guid]::NewGuid().ToString('N') + '.txt')
    try {
        $rc = Invoke-Tool $runtime @('/ErrorStdOut', (Join-Path $root 'test-ui.ahk'), '--smoke', '--result', $resultFile)
        if (Test-Path -LiteralPath $resultFile) {
            Write-Output (Get-Content -LiteralPath $resultFile -Raw)
        }
        if ($rc -ne 0) { throw "UI smoke tests failed (exit code $rc)." }
    } finally {
        if (Test-Path -LiteralPath $resultFile) { Remove-Item -LiteralPath $resultFile }
    }
    $rc = Invoke-Tool $compiler @('/in', (Join-Path $root 'layout-switcher.ahk'), '/out', $tempExe, '/icon', (Join-Path $root 'icon.ico'), '/base', $runtime, '/silent')
    if ($rc -ne 0) { throw 'Ahk2Exe compilation failed.' }
    $rc = Invoke-Tool $RcEdit @($tempExe, '--set-file-version', $version, '--set-product-version', "$version.0", '--set-version-string', 'ProductName', 'AltaiR Key Switcher', '--set-version-string', 'CompanyName', 'AltaiR Studio', '--set-version-string', 'FileDescription', 'AltaiR Key Switcher - RU/EN keyboard layout correction', '--set-version-string', 'OriginalFilename', 'layout-switcher.exe')
    if ($rc -ne 0) { throw 'Version metadata update failed.' }
    $info = (Get-Item -LiteralPath $tempExe).VersionInfo
    if ($info.FileVersion -ne $version) { throw 'Executable version mismatch.' }
    Move-Item -LiteralPath $tempExe -Destination (Join-Path $root 'layout-switcher.exe') -Force
    $rc = Invoke-Tool $ISCC @('/Qp', (Join-Path $PSScriptRoot 'installer.iss')) $PSScriptRoot
    if ($rc -ne 0) { throw 'Installer compilation failed.' }
    $result = Join-Path $root "dist\AltaiR-Key-Switcher-$version-setup.exe"
    if ((Get-Item -LiteralPath $result).VersionInfo.FileVersion.Trim() -ne $version) { throw 'Installer version mismatch.' }
    Get-FileHash -LiteralPath $result -Algorithm SHA256 | Format-List
    Write-Output "Installer ready: $result"
} finally {
    Pop-Location
    if (Test-Path -LiteralPath $tempExe) { Remove-Item -LiteralPath $tempExe }
}
