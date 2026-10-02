# Builds the 1200x630 Open Graph / social preview image: one full-bleed fleet photo,
# a soft green fade at the top, and a centred emblem + business name + one supporting line.
# Everything important sits in the centre so square crops (WhatsApp, Messenger) still work.
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Add-Type -ReferencedAssemblies System.Drawing -Path "$PSScriptRoot\ImageKit.cs"
Add-Type -AssemblyName System.Drawing

$W = 1200; $H = 630
$c = { param($h, $a = 255) $x = [System.Drawing.ColorTranslator]::FromHtml($h); [System.Drawing.Color]::FromArgb($a, $x) }
$bmp = New-Object System.Drawing.Bitmap $W, $H
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = 'HighQuality'; $g.InterpolationMode = 'HighQualityBicubic'; $g.PixelOffsetMode = 'HighQuality'
$g.TextRenderingHint = 'AntiAlias'

# 1. Background photo, scaled to full width; vans placed in the lower third
$photo = [System.Drawing.Image]::FromFile((Join-Path $root 'Images\491183330_1083500183793814_4908358584598014691_n.jpg'))
$scale = $W / $photo.Width
$vansTopSrc = 950; $vansTopDest = 418
$sy = $vansTopSrc - $vansTopDest / $scale
$g.DrawImage($photo, (New-Object System.Drawing.RectangleF 0, 0, $W, $H), (New-Object System.Drawing.RectangleF 0, $sy, $photo.Width, ($H / $scale)), 'Pixel')

# 2. Green fade from the top (text area) to clear over the vans, plus a light bottom edge
$fade = New-Object System.Drawing.Drawing2D.LinearGradientBrush (New-Object System.Drawing.Rectangle 0, 0, $W, $H), (& $c '#062614' 235), (& $c '#062614' 0), 90
$blend = New-Object System.Drawing.Drawing2D.ColorBlend 4
$blend.Colors = @((& $c '#062614' 228), (& $c '#062614' 175), (& $c '#062614' 0), (& $c '#062614' 60))
$blend.Positions = @(0, 0.48, 0.7, 1)
$fade.InterpolationColors = $blend
$g.FillRectangle($fade, 0, 0, $W, $H)

# 3. Emblem, centred
$emb = [ImageKit]::CutOutWhite((Join-Path $root 'Images\Tropical Coastal Road Van Emblem.png'), 236, 4)
$eh = 150; $ew = [int]($emb.Width * $eh / $emb.Height)
$g.DrawImage($emb, [int](($W - $ew) / 2), 30, $ew, $eh)

function Draw-Centered($text, $font, $brush, $y, [double]$tracking = 0) {
  $shadow = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(110, 0, 0, 0))
  $fmt = [System.Drawing.StringFormat]::GenericTypographic
  if ($tracking -eq 0) {
    $textW = $g.MeasureString($text, $font, 2000, $fmt).Width
    $x = ($W - $textW) / 2
    $g.DrawString($text, $font, $shadow, $x + 1.5, $y + 2, $fmt)
    $g.DrawString($text, $font, $brush, $x, $y, $fmt)
  } else {
    # manual letter-spacing for the small caps line
    $widths = $text.ToCharArray() | ForEach-Object { $g.MeasureString([string]$_, $font, 2000, $fmt).Width + $tracking }
    $total = ($widths | Measure-Object -Sum).Sum - $tracking
    $x = ($W - $total) / 2
    for ($i = 0; $i -lt $text.Length; $i++) {
      $g.DrawString([string]$text[$i], $font, $shadow, $x + 1, $y + 1.5, $fmt)
      $g.DrawString([string]$text[$i], $font, $brush, $x, $y, $fmt)
      $x += $widths[$i]
    }
  }
}

$white = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
$sun = New-Object System.Drawing.SolidBrush (& $c '#fdbc34')
$soft = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(235, 255, 255, 255))

# 4. Business name: "Palawan Van" large, "TRANSPORT & TRAVEL SERVICES" tracked below
Draw-Centered 'Palawan Van' (New-Object System.Drawing.Font 'Segoe UI Black', 60, ([System.Drawing.FontStyle]::Regular), 'Pixel') $white 188
Draw-Centered 'TRANSPORT & TRAVEL SERVICES' (New-Object System.Drawing.Font 'Segoe UI Semibold', 23, ([System.Drawing.FontStyle]::Regular), 'Pixel') $sun 270 5.5

# 5. Road-line divider (the site's dashed motif)
$dash = New-Object System.Drawing.Pen (& $c '#fdbc34'), 3
$dash.DashPattern = @(4, 2.6)
# 6 whole dashes: each unit is 3px pen * (4 + 2.6) = 19.8px, minus the trailing gap
$g.DrawLine($dash, ($W / 2) - 55.5, 318, ($W / 2) + 55.5, 318)

# 6. Supporting line
Draw-Centered 'Shared & private van transfers, airport pickups, tours & rentals' (New-Object System.Drawing.Font 'Segoe UI Semibold', 22, ([System.Drawing.FontStyle]::Regular), 'Pixel') $soft 336

$out = Join-Path $root 'site\assets\img\og-palawan-van.jpg'
[ImageKit]::SaveJpeg($bmp, $out, 90)
$g.Dispose(); $bmp.Dispose(); $photo.Dispose(); $emb.Dispose()
Write-Host "wrote $out"
