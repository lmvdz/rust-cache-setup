#Requires -Version 7.5
# Invoke with: & ./scripts/cargo-cached.ps1 build --release
# Remaining arguments pass directly to Cargo. Environment changes are restored.
$mode = if ($env:CARGO_CACHE_MODE) { $env:CARGO_CACHE_MODE } else { 'kache' }
if ($mode -notin @('kache','reapi','none','off','disabled')) { throw "Unknown CARGO_CACHE_MODE='$mode'; use kache, reapi, or none." }
if ($mode -eq 'reapi') {
    if ($env:OS -eq 'Windows_NT') { throw 'cargo-reapi 0.2.0 local cache requires Unix; use kache on Windows.' }
    if (-not $env:CARGO_REAPI_CACHE_DIR) { throw 'Set CARGO_REAPI_CACHE_DIR to a local cache directory.' }
}
$names = @('RUSTC_WRAPPER','RUSTC_WORKSPACE_WRAPPER','CARGO_BUILD_RUSTC_WRAPPER','CARGO_BUILD_RUSTC_WORKSPACE_WRAPPER','CARGO_INCREMENTAL')
$names += @(Get-ChildItem Env:KACHE_* | ForEach-Object Name)
$names += @('KACHE_CONFIG','KACHE_HOST_CONFIG','KACHE_CACHE_DIR','KACHE_RUNTIME_DIR','KACHE_LOCAL_ONLY','KACHE_MAX_SIZE','KACHE_CACHE_EXECUTABLES','KACHE_DISABLED')
$names = @($names | Select-Object -Unique)
$saved = @{}
foreach ($name in $names) { $saved[$name] = [Environment]::GetEnvironmentVariable($name, 'Process') }
$code = 1
try {
    foreach ($name in $names) { [Environment]::SetEnvironmentVariable($name, '', 'Process') }
    # Empty values must be preserved: PowerShell 7.5+ is required.
    $env:CARGO_INCREMENTAL = '0'
    if ($mode -eq 'kache') {
        if (-not (Get-Command kache -ErrorAction SilentlyContinue)) { throw 'Install kache 1.2.2 first (see README).' }
        $kitRoot = Split-Path $PSScriptRoot -Parent
        $base = if ($env:LOCALAPPDATA) { $env:LOCALAPPDATA } elseif ($env:XDG_CACHE_HOME) { $env:XDG_CACHE_HOME } else { Join-Path $HOME '.cache' }
        $cacheRoot = Join-Path $base 'rust-cache-setup'
        $env:KACHE_CONFIG = [IO.Path]::GetFullPath((Join-Path $kitRoot 'configs/.kache.toml.example'))
        $env:KACHE_HOST_CONFIG = [IO.Path]::GetFullPath((Join-Path $kitRoot 'configs/kache-host.toml'))
        $env:KACHE_CACHE_DIR = [IO.Path]::GetFullPath((Join-Path $cacheRoot 'cache'))
        $env:KACHE_RUNTIME_DIR = [IO.Path]::GetFullPath((Join-Path $cacheRoot 'runtime'))
        New-Item -ItemType Directory -Force $env:KACHE_CACHE_DIR,$env:KACHE_RUNTIME_DIR | Out-Null
        $env:KACHE_LOCAL_ONLY='1'; $env:KACHE_MAX_SIZE='4GiB'; $env:KACHE_CACHE_EXECUTABLES='0'; $env:KACHE_DISABLED='0'
        $env:RUSTC_WRAPPER = 'kache'
        $env:CARGO_BUILD_RUSTC_WRAPPER = 'kache'
        & cargo @args
    } elseif ($mode -eq 'reapi') {
        & cargo reapi --backend cache --cache-dir $env:CARGO_REAPI_CACHE_DIR -- @args
    } else { & cargo @args }
    $code = $LASTEXITCODE
} finally {
    foreach ($name in $names) { [Environment]::SetEnvironmentVariable($name, $saved[$name], 'Process') }
}
$global:LASTEXITCODE = $code
