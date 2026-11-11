# Rebuilds the site list in index.html from sites.json and pushes to GitHub (https://sown-dev.github.io/).
#   .\publish.ps1                  find new Pages sites, rebuild, commit, push
#   .\publish.ps1 -Message "text"  same, with your own commit message
#   .\publish.ps1 -NoDiscover      skip looking for new Pages sites on GitHub
#   .\publish.ps1 -NoPush          rebuild index.html only (preview locally)
param(
    [string]$Message = "Update site",
    [switch]$NoDiscover,
    [switch]$NoPush
)
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
$Owner = 'Sown-Dev'
$Utf8 = New-Object System.Text.UTF8Encoding($false)

# ForEach-Object unrolls the list: Windows PowerShell's ConvertFrom-Json hands back a JSON array as one item.
function Read-Sites { , @(Get-Content sites.json -Raw -Encoding UTF8 | ConvertFrom-Json | ForEach-Object { $_ }) }
function Write-Sites($sites) {
    $json = ConvertTo-Json @($sites) -Depth 4
    [IO.File]::WriteAllText((Join-Path $PSScriptRoot 'sites.json'), $json + "`n", $Utf8)
}

$sites = Read-Sites

# 1. Discover: any of your public repos with GitHub Pages on, that isn't listed yet, and that actually serves a page.
if (-not $NoDiscover) {
    if (Get-Command gh -ErrorAction SilentlyContinue) {
        $known = @($sites | ForEach-Object { $_.path.ToLower() })
        $repos = gh api "users/$Owner/repos?per_page=100" --paginate --jq '.[] | select(.has_pages) | .name'
        $added = $false
        foreach ($repo in $repos) {
            if ($repo -ieq "$Owner.github.io" -or $known -contains $repo.ToLower()) { continue }
            $url = "https://$($Owner.ToLower()).github.io/$repo/"
            try {
                Invoke-WebRequest $url -Method Head -UseBasicParsing | Out-Null
                Write-Host "New site found: $repo ($url)"
                $sites += [pscustomobject]@{ path = $repo; name = $repo; description = '' }
                $added = $true
            } catch {
                Write-Host "Skipping $repo`: Pages is on but $url doesn't load yet"
            }
        }
        if ($added) { Write-Sites $sites }
    } else {
        Write-Host "gh (GitHub CLI) not found: skipping discovery"
    }
}

# 2. Rebuild the list between the markers in index.html.
$items = foreach ($s in $sites) {
    if ($s.hidden) { continue }
    $href = if ($s.url) { $s.url } else { "/$($s.path)/" }
    $name = [Net.WebUtility]::HtmlEncode($(if ($s.name) { $s.name } else { $s.path }))
    $desc = if ($s.description) { "<span class=`"desc`">$([Net.WebUtility]::HtmlEncode($s.description))</span>" } else { '' }
    "        <li><a href=`"$([Net.WebUtility]::HtmlEncode($href))`">$name</a>$desc</li>"
}
$html = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'index.html'), $Utf8)
$pattern = '(?s)(<ul class="sites">).*?(\s*</ul>\s*<!-- /sites -->)'
if ($html -notmatch $pattern) { throw "index.html lost its <ul class=`"sites`"> ... <!-- /sites --> markers" }
$list = ($items -join "`n")
$html = [regex]::Replace($html, $pattern, { param($m) $m.Groups[1].Value + "`n" + $list + $m.Groups[2].Value })
[IO.File]::WriteAllText((Join-Path $PSScriptRoot 'index.html'), $html, $Utf8)
Write-Host "index.html: $(@($items).Count) site(s) listed"

if ($NoPush) { return }

# 3. Commit and push.
git add -A
git diff --cached --quiet
if ($LASTEXITCODE -eq 0) { Write-Host "Nothing changed."; return }
git commit -m $Message
if ($LASTEXITCODE -ne 0) { throw "git commit failed" }
git push origin main
if ($LASTEXITCODE -ne 0) { throw "git push failed" }
Write-Host "Pushed. Live at https://$($Owner.ToLower()).github.io/ in about a minute."
