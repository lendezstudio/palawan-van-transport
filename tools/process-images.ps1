# Converts the supplied client photos in /Images into web-sized JPEGs in /site/assets/img.
# Usage: powershell -ExecutionPolicy Bypass -File tools\process-images.ps1
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Add-Type -ReferencedAssemblies System.Drawing -Path "$PSScriptRoot\ImageKit.cs"
$src = Join-Path $root 'Images'
$out = Join-Path $root 'site\assets\img'

# slug -> source file id (Facebook export filename prefix)
$map = [ordered]@{
  'fleet-blue-sky'        = '491183330'
  'fleet-parking-lot'     = '490975837'
  'fleet-field'           = '488642163'
  'vans-forest-road'      = '498208325'
  'vans-hotel-entrance'   = '498243116'
  'vans-palm-grove'       = '488221619'
  'island-turquoise'      = '484189156'
  'beach-shade'           = '484150547'
  'beach-breakfast'       = '485151638'
  'guests-limestone-cliffs' = '484991163'
  'paddle-boat-blue'      = '485096908'
  'paddle-boat-orange'    = '485157128'
  'group-cave-entrance'   = '485159315'
  'cottage-lunch'         = '485229218'
  'luli-island-welcome'   = '485642357'
  'paddle-boat-river'     = '485686111'
  'guests-karst-shore'    = '485747115'
  'snorkeling'            = '485925478'
  'group-pier'            = '485931127'
  'group-river-beach'     = '486063702'
  'boat-group'            = '486135537'
  'guests-limestone-wall' = '486263477'
  'paddle-boat-turquoise' = '486387420'
  'guests-cliff-beach'    = '486463087'
  'underground-river-sign'= '486504737'
  'group-jetty'           = '486822874'
  'guests-karst-field'    = '487185422'
  'island-boat'           = '487481707'
  'market-stop'           = '488505068'
  'ugong-rock-entrance'   = '482244332'
}
$widths = 640, 1200, 2000
$manifest = @{}
foreach ($slug in $map.Keys) {
  $file = Get-ChildItem $src -Filter "$($map[$slug])_*.jpg" | Select-Object -First 1
  $img = [System.Drawing.Image]::FromFile($file.FullName); $srcW = $img.Width; $srcH = $img.Height; $img.Dispose()
  $sizes = @()
  $set = if ($slug -eq 'fleet-blue-sky') { $widths } else { 640, 1200 }
  foreach ($tw in $set) {
    if ($tw -gt $srcW -and $sizes.Count -gt 0) { continue }
    $ow = [math]::Min($tw, $srcW)
    [void][ImageKit]::ResizeJpeg($file.FullName, (Join-Path $out "$slug-$tw.jpg"), $tw, 76)
    $sizes += $ow
  }
  $manifest[$slug] = @{ w = $srcW; h = $srcH; sizes = $sizes }
  Write-Host "$slug  ${srcW}x${srcH}  -> $($sizes -join ', ')"
}
$manifest | ConvertTo-Json -Depth 4 | Set-Content -Encoding utf8 (Join-Path $root 'src\data\images.json')
