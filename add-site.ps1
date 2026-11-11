# Adds (or updates) one entry in sites.json, then publishes.
#   .\add-site.ps1 mysite "My Site" "What it is"
#       -> links https://sown-dev.github.io/mysite/ (a repo named mysite with Pages on)
#   .\add-site.ps1 itch "My games" "On itch.io" -Url https://example.itch.io/
#       -> links any address instead
#   .\add-site.ps1 mysite -Hide      keeps it in sites.json but off the page (publish won't re-add it)
#   .\add-site.ps1 mysite -Remove    removes it from sites.json
#   add -NoPush to only update the files locally
param(
    [Parameter(Mandatory)][string]$Path,
    [string]$Name,
    [string]$Description,
    [string]$Url,
    [switch]$Hide,
    [switch]$Remove,
    [switch]$NoPush
)
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
$Utf8 = New-Object System.Text.UTF8Encoding($false)
$Path = $Path.Trim('/')
# ForEach-Object unrolls the list: Windows PowerShell's ConvertFrom-Json hands back a JSON array as one item.
$sites = @(Get-Content sites.json -Raw -Encoding UTF8 | ConvertFrom-Json | ForEach-Object { $_ })
$existing = $sites | Where-Object { $_.path -ieq $Path } | Select-Object -First 1

if ($Remove) {
    $sites = @($sites | Where-Object { $_.path -ine $Path })
    $what = "Remove $Path from the site list"
} else {
    if (-not $existing) {
        $existing = [pscustomobject]@{ path = $Path; name = $Path; description = '' }
        $sites += $existing
    }
    if ($Name) { $existing.name = $Name }
    if ($PSBoundParameters.ContainsKey('Description')) { $existing.description = $Description }
    if ($Url) { $existing | Add-Member -Force NoteProperty url $Url }
    if ($Hide) { $existing | Add-Member -Force NoteProperty hidden $true }
    elseif ($existing.PSObject.Properties['hidden']) { $existing.PSObject.Properties.Remove('hidden') }
    $what = if ($Hide) { "Hide $Path" } else { "List $($existing.name)" }
}
[IO.File]::WriteAllText((Join-Path $PSScriptRoot 'sites.json'), (ConvertTo-Json @($sites) -Depth 4) + "`n", $Utf8)
Write-Host "sites.json updated: $what"

& (Join-Path $PSScriptRoot 'publish.ps1') -Message $what -NoDiscover -NoPush:$NoPush
