# Generates transparent logo assets and favicons from the supplied logo PNGs (white backgrounds removed).
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Add-Type -ReferencedAssemblies System.Drawing -Path "$PSScriptRoot\ImageKit.cs"
$img = Join-Path $root 'site\assets\img'; $site = Join-Path $root 'site'

$emb  = [ImageKit]::CutOutWhite((Join-Path $root 'Images\Tropical Coastal Road Van Emblem.png'), 236, 4)
$full = [ImageKit]::CutOutWhite((Join-Path $root 'Images\Palawan Van Tropical Travel Logo.png'), 236, 4)
[ImageKit]::SavePngScaled($emb,  "$img\emblem-160.png", 160)
[ImageKit]::SavePngScaled($full, "$img\logo-full-480.png", 480)

# Favicons: square crop around the van and cliffs so the mark stays readable at 16-48px
$sq = $emb.Clone((New-Object System.Drawing.Rectangle 150, 150, 745, 745), $emb.PixelFormat)
[ImageKit]::SaveIco($sq, "$site\favicon.ico", @(16, 32, 48), 1.0)
foreach ($s in 32, 192, 512) { $b = [ImageKit]::Square($sq, $s, 1.0, $null); $b.Save("$site\favicon-$s.png"); $b.Dispose() }
$sand = [System.Drawing.ColorTranslator]::FromHtml('#f7f2e7')
$b = [ImageKit]::Square($sq, 180, 0.9, $sand);  $b.Save("$site\apple-touch-icon.png"); $b.Dispose()
$b = [ImageKit]::Square($sq, 512, 0.78, $sand); $b.Save("$site\maskable-512.png");     $b.Dispose()
Write-Host 'brand assets written'
