# Build in Linux; install through Windows ADB without clearing application data.
[CmdletBinding()]
param(
    [string]$DeviceSerial,
    [string]$AdbPath,
    [switch]$ValidateOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$distro = 'Ubuntu-24.04'
$sourceRoot = $PSScriptRoot

function Invoke-Checked {
    param([string]$Executable, [string[]]$Arguments)
    & $Executable @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed ($LASTEXITCODE): $Executable $($Arguments -join ' ')"
    }
}

function Invoke-Linux {
    param([string]$Script)
    # Base64 avoids PowerShell/WSL native argument quoting and CRLF pitfalls.
    $encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Script.Replace("`r", '')))
    Invoke-Checked 'wsl.exe' @('-d', $distro, '--', 'bash', '-lc', "echo $encoded | base64 -d | bash -euo pipefail")
}

try {
    if (-not (Test-Path -LiteralPath (Join-Path $sourceRoot 'pubspec.yaml'))) {
        throw 'Keep run-fintrack.ps1 in the Flutter repository beside pubspec.yaml.'
    }
    $null = Get-Command wsl.exe -ErrorAction Stop
    $distros = (& wsl.exe --list --verbose | Out-String).Replace([string][char]0, '')
    if ($LASTEXITCODE -ne 0) { throw 'WSL is unavailable. Check: wsl --status' }
    if ($distros -notmatch '(?m)^\s*\*?\s*Ubuntu-24\.04\s+\S+\s+2\s*$') {
        throw 'Ubuntu-24.04 must be installed as WSL2. Check: wsl --list --verbose'
    }
    if (-not $AdbPath) {
        $adbCommand = Get-Command adb.exe -ErrorAction SilentlyContinue
        if ($adbCommand) { $AdbPath = $adbCommand.Source }
        else { $AdbPath = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe' }
    }
    if (-not (Test-Path -LiteralPath $AdbPath -PathType Leaf)) {
        throw 'Windows ADB not found. Supply -AdbPath <path-to-adb.exe>.'
    }
    $deviceOutput = & $AdbPath devices
    if ($LASTEXITCODE -ne 0) { throw 'Windows ADB device discovery failed.' }
    $devices = @($deviceOutput | ForEach-Object {
        if ($_ -match '^(\S+)\s+device\s*$') { $Matches[1] }
    })
    if ($DeviceSerial) {
        if ($DeviceSerial -notin $devices -or $DeviceSerial -notmatch '^emulator-\d+$') {
            throw 'The selected serial must be an online Android emulator listed by adb devices.'
        }
    } else {
        if ($devices.Count -ne 1 -or $devices[0] -notmatch '^emulator-\d+$') {
            throw 'Connect one emulator, or select it explicitly with -DeviceSerial emulator-5554. Check adb devices for offline/unauthorized devices.'
        }
        $DeviceSerial = $devices[0]
    }

    $sourceEncoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($sourceRoot))
    $linuxSetup = @'
fail() { echo "ERROR: $*" >&2; exit 1; }
flutter="$HOME/develop/flutter/bin/flutter"
target="$HOME/fintrack-wsl/frontend"
test -x "$flutter" || fail "Linux Flutter missing: $flutter"
command -v rsync >/dev/null || fail 'Install rsync in Ubuntu first.'
command -v java >/dev/null || fail 'Configure Linux Java (JDK 17 or newer) first.'
sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}}"
test -d "$sdk/platforms" && test -d "$sdk/build-tools" || fail "Linux Android SDK incomplete: $sdk"
export ANDROID_HOME="$sdk" ANDROID_SDK_ROOT="$sdk"
test -f "$target/android/local.properties" || fail 'Existing Linux android/local.properties is required; configure Linux SDK paths first.'
grep -Fqx "sdk.dir=$sdk" "$target/android/local.properties" || fail 'Linux local.properties sdk.dir must match the Linux Android SDK.'
grep -Fqx "flutter.sdk=$HOME/develop/flutter" "$target/android/local.properties" || fail 'Linux local.properties flutter.sdk must point to ~/develop/flutter.'
test -s "$HOME/.android/debug.keystore" || fail 'Existing Linux debug signing key missing. Restore the previously used key; do not generate a replacement.'
command -v keytool >/dev/null || fail 'Linux JDK keytool is missing; configure the existing Java installation.'
keytool -list -keystore "$HOME/.android/debug.keystore" -storepass android -alias androiddebugkey >/dev/null 2>&1 || fail 'Existing debug keystore is not usable with standard Android debug signing. Check the existing signing configuration before building.'
test ! -L "$target" || fail 'Refusing to synchronize into a symlinked working copy.'
test -d "$target" || fail 'Existing Linux working copy not found at ~/fintrack-wsl/frontend.'
'@
    Write-Host "Checking Linux build prerequisites and Windows emulator $DeviceSerial..."
    Invoke-Linux $linuxSetup
    if ($ValidateOnly) {
        $pathCheck = @'
source=$(echo SOURCE_BASE64 | base64 -d | xargs -0 wslpath -u)
test -f "$source/pubspec.yaml" || fail 'Windows Flutter source is not accessible from WSL.'
echo "Source path verified: $source"
'@
        Invoke-Linux ($linuxSetup + "`n" + $pathCheck.Replace('SOURCE_BASE64', $sourceEncoded))
        Write-Host 'Validation passed. No synchronization, build, installation or launch performed.'
        return
    }

    $linuxBuild = @'
source=$(echo SOURCE_BASE64 | base64 -d | xargs -0 wslpath -u)
test -f "$source/pubspec.yaml" || fail 'Windows Flutter source is not accessible from WSL.'
echo 'Synchronizing Flutter source...'
# Excluded paths are also protected from --delete; never use --delete-excluded.
rsync -a --delete-delay --no-owner --no-group --no-perms \
  --exclude='.git/' --exclude='build/' --exclude='.dart_tool/' \
  --exclude='.gradle/' --exclude='.kotlin/' --exclude='.pub-cache/' --exclude='.pub/' \
  --exclude='local.properties' --exclude='key.properties' --exclude='keystore/' \
  --exclude='*.keystore' --exclude='*.jks' --exclude='*.p12' --exclude='*.pem' \
  --exclude='.ssh/' --exclude='.aws/' --exclude='.codex/' --exclude='.agents/' \
  --exclude='*.key' --exclude='*.pfx' --exclude='secrets/' \
  --exclude='.env*' --exclude='credentials*' --exclude='*.apk' --exclude='*.aab' \
  --exclude='.idea/' --exclude='.vscode/' --exclude='*.log' --exclude='*.tmp' \
  --exclude='*report*.html' --exclude='.flutter-plugins*' --exclude='ephemeral/' \
  --exclude='Generated.xcconfig' --exclude='flutter_export_environment.sh' \
  --exclude='android/app/debug/' --exclude='android/app/profile/' --exclude='android/app/release/' \
  "$source/" "$target/"
cd "$target"
# Pub get is incremental and ensures deleted/changed manifests and SDK updates
# never leave stale package resolution behind.
"$flutter" pub get
echo 'Building debug APK with the existing Linux signing configuration...'
"$flutter" build apk --debug --no-pub
test -s build/app/outputs/flutter-apk/app-debug.apk || fail 'Build finished without the expected APK.'
mkdir -p "$source/build/wsl"
cp build/app/outputs/flutter-apk/app-debug.apk "$source/build/wsl/fintrack-debug.apk"
'@
    Invoke-Linux ($linuxSetup + "`n" + $linuxBuild.Replace('SOURCE_BASE64', $sourceEncoded))
    $apk = Join-Path $sourceRoot 'build\wsl\fintrack-debug.apk'
    if (-not (Test-Path -LiteralPath $apk -PathType Leaf)) { throw 'Copied Windows APK is missing.' }
    Write-Host "Installing on $DeviceSerial (existing application data preserved)..."
    $installOutput = & $AdbPath -s $DeviceSerial install -r $apk 2>&1
    $installCode = $LASTEXITCODE
    $installOutput | ForEach-Object { Write-Host $_ }
    if ($installCode -ne 0 -or ($installOutput -join "`n") -notmatch '(?m)^Success\s*$') {
        throw 'Installation failed. For UPDATE_INCOMPATIBLE/signature conflicts, restore the original Linux signing key. No uninstall or data deletion was attempted.'
    }
    $launchOutput = & $AdbPath -s $DeviceSerial shell am start -W -n 'com.mkl.financemanager/.MainActivity' 2>&1
    $launchCode = $LASTEXITCODE
    $launchOutput | ForEach-Object { Write-Host $_ }
    if ($launchCode -ne 0 -or ($launchOutput -join "`n") -notmatch '(?m)^Status: ok\s*$') {
        throw 'APK installed, but launch failed. Check adb shell am start -W -n com.mkl.financemanager/.MainActivity on the selected emulator.'
    }
    Write-Host "FinTrack ready: Linux build OK; install -r OK; launch OK on $DeviceSerial."
} catch {
    Write-Error "FinTrack workflow stopped: $($_.Exception.Message)" -ErrorAction Continue
    exit 1
}
