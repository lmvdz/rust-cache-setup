#Requires -Version 7.5
$ErrorActionPreference = 'Stop'
$helper = Join-Path $PSScriptRoot '../scripts/cargo-cached.ps1'
function global:kache { }
function global:cargo {
    $global:captured = @($args)
    $global:wrapper = $env:RUSTC_WRAPPER
    $global:workspaceWrapper = $env:RUSTC_WORKSPACE_WRAPPER
    $global:configWrapper = $env:CARGO_BUILD_RUSTC_WRAPPER
    $global:incremental = $env:CARGO_INCREMENTAL
    $global:localOnly = $env:KACHE_LOCAL_ONLY
    $global:hostConfig = $env:KACHE_HOST_CONFIG
    $global:remoteLeak = $env:KACHE_REMOTE_URL
    $global:LASTEXITCODE = 17
}
function Assert($condition, $message) { if (-not $condition) { throw $message } }
$names = @('CARGO_CACHE_MODE','RUSTC_WRAPPER','RUSTC_WORKSPACE_WRAPPER','CARGO_BUILD_RUSTC_WRAPPER','CARGO_BUILD_RUSTC_WORKSPACE_WRAPPER','CARGO_INCREMENTAL','KACHE_REMOTE_URL','KACHE_LOCAL_ONLY')
$saved = @{}
foreach ($name in $names) { $saved[$name] = [Environment]::GetEnvironmentVariable($name) }
try {
    $env:KACHE_REMOTE_URL='sentinel-private-remote'; $env:KACHE_LOCAL_ONLY='0'
    $env:RUSTC_WRAPPER='old-wrapper'; $env:RUSTC_WORKSPACE_WRAPPER='old-workspace'
    $env:CARGO_BUILD_RUSTC_WRAPPER='old-config'; $env:CARGO_BUILD_RUSTC_WORKSPACE_WRAPPER='old-config-workspace'; $env:CARGO_INCREMENTAL='1'
    foreach ($mode in @('kache','none','off','disabled')) {
        $env:CARGO_CACHE_MODE=$mode
        & $helper test -p 'crate with spaces' -- '--literal'
        Assert ($LASTEXITCODE -eq 17) 'Exit status lost'
        Assert ($captured.Count -eq 4 -and $captured[1] -eq '-p' -and $captured[2] -eq 'crate with spaces' -and $captured[3] -eq '--literal') 'Argument boundaries lost'
        # PowerShell function stubs consume the -- terminator; Bash tests assert it literally.
        Assert ($workspaceWrapper -ceq '') 'Workspace wrapper not suppressed'
        Assert ($incremental -eq '0') 'Incremental not disabled'
        if ($mode -eq 'kache') {
            Assert ($localOnly -eq '1' -and [IO.Path]::IsPathFullyQualified($hostConfig)) 'Local isolation missing'
            Assert ([string]::IsNullOrEmpty($remoteLeak)) 'Inherited remote leaked'
        }
        Assert ($env:KACHE_REMOTE_URL -eq 'sentinel-private-remote' -and $env:KACHE_LOCAL_ONLY -eq '0') 'Kache environment not restored'
        Assert ($wrapper -ceq $(if($mode -eq 'kache'){'kache'}else{''})) 'Wrong compiler wrapper'
        Assert ($configWrapper -ceq $(if($mode -eq 'kache'){'kache'}else{''})) 'Wrong config wrapper'
        Assert ($env:RUSTC_WRAPPER -eq 'old-wrapper' -and $env:CARGO_INCREMENTAL -eq '1') 'Caller environment changed'
    }
    $env:CARGO_CACHE_MODE='bad'
    $failed=$false; try { & $helper check } catch { $failed=$true }
    Assert $failed 'Invalid mode accepted'
    if ($env:OS -eq 'Windows_NT') {
        $env:CARGO_CACHE_MODE='reapi'; $failed=$false
        try { & $helper check } catch { $failed=$true }
        Assert $failed 'Windows reapi accepted'
    }
    Write-Output 'PowerShell helper checks passed.'
} finally {
    foreach ($name in $names) { [Environment]::SetEnvironmentVariable($name,$saved[$name]) }
    Remove-Item Function:global:cargo,Function:global:kache -ErrorAction SilentlyContinue
}
