# Extracts the "Palawan Van / Transport & Travel Services" wordmark from the supplied full logo
# for the horizontal header lockup (emblem + wordmark). Removes the road and swoosh above the lettering.
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Add-Type -ReferencedAssemblies System.Drawing -Path "$PSScriptRoot\ImageKit.cs"
$full = [ImageKit]::CutOutWhite((Join-Path $root 'Images\Palawan Van Tropical Travel Logo.png'), 236, 4)
$y0 = 700
$wm = $full.Clone((New-Object System.Drawing.Rectangle 0, $y0, $full.Width, ($full.Height - $y0)), $full.PixelFormat)
$clear = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)
for ($y = 0; $y -lt 95; $y++) {
  for ($x = 0; $x -lt $wm.Width; $x++) {
    $p = $wm.GetPixel($x, $y); if ($p.A -eq 0) { continue }
    $max = [math]::Max($p.R, [math]::Max($p.G, $p.B)); $min = [math]::Min($p.R, [math]::Min($p.G, $p.B))
    $isGrey = ($max - $min) -lt 40
    $isOrange = $p.R -gt 150 -and $p.R -gt $p.G -and $p.G -gt $p.B -and ($p.R - $p.B) -gt 80
    $kill = ($y -lt 35 -and $x -gt 250) -or ($isOrange -and ($x -gt 250 -or $y -lt 40) -and $x -lt 800) -or ($isGrey -and $y -lt 70 -and $x -gt 250)
    if ($kill) { $wm.SetPixel($x, $y, $clear) }
  }
}
# trim transparent rows/cols
$minY = 0; while ($minY -lt $wm.Height) { $any = $false; for ($x = 0; $x -lt $wm.Width; $x += 2) { if ($wm.GetPixel($x, $minY).A -gt 30) { $any = $true; break } }; if ($any) { break }; $minY++ }
$trim = $wm.Clone((New-Object System.Drawing.Rectangle 0, $minY, $wm.Width, ($wm.Height - $minY)), $wm.PixelFormat)
[ImageKit]::SavePngScaled($trim, (Join-Path $root 'site\assets\img\wordmark-480.png'), 480)
Write-Host "wordmark $($trim.Width)x$($trim.Height)"
