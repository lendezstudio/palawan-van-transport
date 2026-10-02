# Static site builder for Palawan Van Transport & Travel Services.
# Assembles src/pages + src/partials + src/layout.html into /site, and generates route pages from src/data/routes.json.
# Usage: powershell -ExecutionPolicy Bypass -File build.ps1
#
# Template syntax
#   {{> name}}                     include src/partials/name.html
#   {{site.key}}                   value from src/data/site.json
#   {{img:slug|sizes|class|lazy}}  responsive <img> for a processed photo (alt from src/data/alt.json)
#   {{srcset:slug}} {{src:slug}}   srcset string / mid-size URL for hand-written <picture> elements
#   {{routes:board}}               popular-routes list built from routes.json
#   {{cur:section}}                becomes aria-current="page" on the active nav item
#   {{root}}                       relative path prefix to the site root (works on any host or subfolder)
$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
$src = Join-Path $here 'src'; $out = Join-Path $here 'site'
$utf8 = New-Object System.Text.UTF8Encoding $false

function Read-Text($p) { [System.IO.File]::ReadAllText($p, [System.Text.Encoding]::UTF8) }
function Write-Text($p, $s) { $d = Split-Path $p -Parent; if (-not (Test-Path $d)) { New-Item -ItemType Directory -Force $d | Out-Null }; [System.IO.File]::WriteAllText($p, $s, $utf8) }
function Enc($s) { [System.Net.WebUtility]::HtmlEncode($s) }
function Replace-Rx($text, $pattern, [scriptblock]$fn) {
  [regex]::Replace($text, $pattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) & $fn $m })
}

$site   = (Read-Text "$src\data\site.json")   | ConvertFrom-Json
$routes = (Read-Text "$src\data\routes.json") | ConvertFrom-Json
$images = (Read-Text "$src\data\images.json") | ConvertFrom-Json
$alts   = (Read-Text "$src\data\alt.json")    | ConvertFrom-Json
$layout = Read-Text "$src\layout.html"
$year = (Get-Date).Year

function Image-Info($slug) {
  $i = $images.$slug; if (-not $i) { throw "Unknown image '$slug'" }
  $max = ($i.sizes | Measure-Object -Maximum).Maximum
  $h = [int][math]::Round($i.h * $max / $i.w)
  $set = ($i.sizes | ForEach-Object { "{{root}}assets/img/$slug-$_.jpg ${_}w" }) -join ', '
  $mid = if ($i.sizes -contains 1200) { 1200 } else { $i.sizes[0] }
  [pscustomobject]@{ w = $max; h = $h; srcset = $set; src = "{{root}}assets/img/$slug-$mid.jpg"; small = "{{root}}assets/img/$slug-$($i.sizes[0]).jpg" }
}

$detailLabels = [ordered]@{
  pickup = 'Pickup point'; dropoff = 'Drop-off area'; departures = 'Departure schedule'; travelTime = 'Estimated travel time'
  sharedFare = 'Shared fare'; privateFare = 'Private fare'; luggage = 'Luggage guidance'
}

function Route-Board {
  $rows = foreach ($r in $routes) {
@"
        <li class="route-row" data-reveal>
          <div class="route-row__line" aria-hidden="true"><span class="stop"></span><span class="road-dash"></span><svg class="icon route-row__van"><use href="#i-van"/></svg><span class="road-dash"></span><span class="stop stop--end"></span></div>
          <h3 class="route-row__title"><a href="{{root}}transfers/$($r.slug)/"><span class="route-row__from">$(Enc $r.origin)</span> <span class="visually-hidden">to</span><span class="route-row__arrow" aria-hidden="true">&rarr;</span> <span class="route-row__to">$(Enc $r.destination)</span></a></h3>
          <p class="route-row__text">$(Enc $r.summary)</p>
          <span class="route-row__cta" aria-hidden="true">Check This Route <svg class="icon"><use href="#i-arrow"/></svg></span>
        </li>
"@
  }
  "<ol class=`"route-board`" role=`"list`">`n$($rows -join "`n")`n      </ol>"
}

function Render($html, $depth, $nav, $absolute) {
  # includes (two passes so partials may include partials)
  for ($pass = 0; $pass -lt 2; $pass++) {
    $html = Replace-Rx $html '\{\{>\s*([\w-]+)\s*\}\}' { param($m) Read-Text "$src\partials\$($m.Groups[1].Value).html" }
  }
  $html = $html.Replace('{{routes:board}}', (Route-Board))
  $html = Replace-Rx $html '\{\{site\.(\w+)\}\}' { param($m) $site.($m.Groups[1].Value) }
  $html = Replace-Rx $html '\{\{img:([^}]+)\}\}' {
    param($m)
    $p = $m.Groups[1].Value.Split('|'); $slug = $p[0]; $info = Image-Info $slug
    $sizes = if ($p.Count -gt 1 -and $p[1]) { $p[1] } else { '100vw' }
    $cls = if ($p.Count -gt 2 -and $p[2]) { " class=`"$($p[2])`"" } else { '' }
    $load = if ($p.Count -gt 3 -and $p[3] -eq 'eager') { ' fetchpriority="high"' } else { ' loading="lazy"' }
    $alt = Enc $alts.$slug
    "<img src=`"$($info.src)`" srcset=`"$($info.srcset)`" sizes=`"$sizes`" width=`"$($info.w)`" height=`"$($info.h)`" alt=`"$alt`"$cls$load decoding=`"async`">"
  }
  $html = Replace-Rx $html '\{\{srcset:([\w-]+)\}\}' { param($m) (Image-Info $m.Groups[1].Value).srcset }
  $html = Replace-Rx $html '\{\{src:([\w-]+)\}\}' { param($m) (Image-Info $m.Groups[1].Value).src }
  $html = Replace-Rx $html '\{\{alt:([\w-]+)\}\}' { param($m) Enc $alts.($m.Groups[1].Value) }
  $html = Replace-Rx $html '\{\{cur:(\w+)\}\}' { param($m) if ($m.Groups[1].Value -eq $nav) { ' aria-current="page"' } else { '' } }
  $html = $html.Replace('{{year}}', "$year")
  # 404 is served at any URL depth, so it links from the absolute site URL (works under a GitHub Pages subfolder)
  $root = if ($absolute) { $site.siteUrl } elseif ($depth -eq 0) { './' } else { '../' * $depth }
  $html = $html.Replace('{{root}}', $root)
  if ($html -match '\{\{[^}]*\}\}') { throw "Unresolved token: $($Matches[0])" }
  $html
}

function Build-Page($meta, $body) {
  $path = $meta.path
  $depth = @($path.Split('/') | Where-Object { $_ }).Count
  if ($path -like '*.html') { $depth -= 1 }
  $html = $layout.Replace('{{content}}', $body)
  $html = $html.Replace('{{title}}', (Enc $meta.title)).Replace('{{description}}', (Enc $meta.description))
  $ogTitle = if ($meta.ogTitle) { $meta.ogTitle } else { $meta.title }
  $ogDesc = if ($meta.ogDescription) { $meta.ogDescription } else { $meta.description }
  $html = $html.Replace('{{ogTitle}}', (Enc $ogTitle)).Replace('{{ogDescription}}', (Enc $ogDesc))
  $html = $html.Replace('{{canonical}}', $site.siteUrl + $path)
  $html = $html.Replace('{{schema}}', $(if ($meta.schema) { $meta.schema } else { '' }))
  $html = $html.Replace('{{bodyClass}}', $(if ($meta.bodyClass) { $meta.bodyClass } else { '' }))
  $html = Render $html $depth $meta.nav ($meta.rootAbsolute -eq 'true')
  $file = if ($path -eq '') { 'index.html' } elseif ($path -like '*.html') { $path } else { "$path" + 'index.html' }
  Write-Text (Join-Path $out $file) $html
  Write-Host "  $file"
}

function Parse-Meta($text) {
  $meta = @{}
  if ($text -match '(?s)^\s*<!--(.*?)-->') {
    foreach ($line in ($Matches[1] -split "`n")) { if ($line -match '^\s*(\w+):\s*(.*?)\s*$') { $meta[$Matches[1]] = $Matches[2] } }
    $text = $text.Substring($text.IndexOf('-->') + 3)
  }
  if (-not $meta.ContainsKey('path')) { $meta.path = '' }
  [pscustomobject]@{ meta = $meta; body = $text }
}

Write-Host 'Building pages'
$sitemap = @()
foreach ($f in Get-ChildItem "$src\pages" -Filter *.html) {
  $p = Parse-Meta (Read-Text $f.FullName)
  if ($p.meta.path -eq '' -and $f.BaseName -ne 'index') { $p.meta.path = "$($f.BaseName)/" }
  if ($f.BaseName -eq 'index') {
    $p.meta.schema = (Read-Text "$src\partials\schema-business.html").Replace('{{canonical}}', $site.siteUrl)
  }
  Build-Page ([pscustomobject]$p.meta) $p.body
  if ($p.meta.path -notlike '*.html') { $sitemap += $p.meta.path }
}

Write-Host 'Building route pages'
$routeTpl = Parse-Meta (Read-Text "$src\templates\route.html")
foreach ($r in $routes) {
  $facts = @(); $confirm = @()
  foreach ($k in $detailLabels.Keys) {
    $v = $r.details.$k
    if ($v) { $facts += "<div class=`"fact`"><dt>$($detailLabels[$k])</dt><dd>$(Enc $v)</dd></div>" }
    else { $confirm += "<li><svg class=`"icon`"><use href=`"#i-check`"/></svg>$($detailLabels[$k])</li>" }
  }
  $others = ($routes | Where-Object { $_.slug -ne $r.slug } | ForEach-Object {
    "<li><a href=`"{{root}}transfers/$($_.slug)/`">$(Enc $_.origin) <span aria-hidden=`"true`">&rarr;</span><span class=`"visually-hidden`">to</span> $(Enc $_.destination)</a></li>" }) -join "`n"
  $vals = @{
    'route.slug' = $r.slug; 'route.origin' = (Enc $r.origin); 'route.destination' = (Enc $r.destination)
    'route.summary' = (Enc $r.summary); 'route.image' = $r.image
    'route.originQ' = [uri]::EscapeDataString($r.origin); 'route.destinationQ' = [uri]::EscapeDataString($r.destination)
    'route.facts' = ($facts -join "`n"); 'route.confirm' = ($confirm -join "`n"); 'route.others' = $others
    'route.confirmClass' = $(if ($confirm.Count -eq 0) { ' hidden' } else { '' })
  }
  $body = $routeTpl.body; $meta = @{}
  foreach ($k in $routeTpl.meta.Keys) { $meta[$k] = $routeTpl.meta[$k] }
  foreach ($k in $vals.Keys) {
    $body = $body.Replace("{{$k}}", $vals[$k])
    foreach ($mk in @($meta.Keys)) { $meta[$mk] = $meta[$mk].Replace("{{$k}}", $r.$($k.Substring(6))) }
  }
  $meta.path = "transfers/$($r.slug)/"
  $crumb = (Read-Text "$src\partials\schema-breadcrumb.html").Replace('{{base}}', $site.siteUrl).Replace('{{name}}', "$($r.origin) to $($r.destination)").Replace('{{url}}', $site.siteUrl + $meta.path)
  $meta.schema = $crumb
  Build-Page ([pscustomobject]$meta) $body
  $sitemap += $meta.path
}

# sitemap + robots
$today = Get-Date -Format 'yyyy-MM-dd'
$urls = ($sitemap | Where-Object { $_ -ne '404.html' } | Sort-Object | ForEach-Object { "  <url><loc>$($site.siteUrl)$_</loc><lastmod>$today</lastmod></url>" }) -join "`n"
Write-Text "$out\sitemap.xml" "<?xml version=`"1.0`" encoding=`"UTF-8`"?>`n<urlset xmlns=`"http://www.sitemaps.org/schemas/sitemap/0.9`">`n$urls`n</urlset>`n"
Write-Text "$out\robots.txt" "User-agent: *`nAllow: /`n`nSitemap: $($site.siteUrl)sitemap.xml`n"
Write-Host 'Done.'
