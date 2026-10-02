# Builds the 1200x630 Open Graph / social preview image from the supplied logo and fleet photo.
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Add-Type -ReferencedAssemblies System.Drawing -Path "$PSScriptRoot\ImageKit.cs"
Add-Type -AssemblyName System.Drawing

$W = 1200; $H = 630; $panel = 540
$c = { param($h) [System.Drawing.ColorTranslator]::FromHtml($h) }
$bmp = New-Object System.Drawing.Bitmap $W, $H
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = 'HighQuality'; $g.InterpolationMode = 'HighQualityBicubic'; $g.TextRenderingHint = 'AntiAliasGridFit'

# photo, cover-cropped into the right side, anchored to the vans (bottom-centre)
$photo = [System.Drawing.Image]::FromFile((Join-Path $root 'Images\491183330_1083500183793814_4908358584598014691_n.jpg'))
$dw = $W - $panel; $scale = [math]::Max($dw / $photo.Width, $H / $photo.Height) * 1.12
$sw = $dw / $scale; $sh = $H / $scale
$sx = ($photo.Width - $sw) / 2; $sy = [math]::Max(0, $photo.Height - $sh - $photo.Height * 0.08)
$g.DrawImage($photo, (New-Object System.Drawing.RectangleF $panel, 0, $dw, $H), (New-Object System.Drawing.RectangleF $sx, $sy, $sw, $sh), 'Pixel')

# sand panel + road line divider
$g.FillRectangle((New-Object System.Drawing.SolidBrush (& $c '#f7f2e7')), 0, 0, $panel, $H)
$g.FillRectangle((New-Object System.Drawing.SolidBrush (& $c '#0c4623')), $panel - 14, 0, 14, $H)
$dash = New-Object System.Drawing.Pen (& $c '#fdbc34'), 4; $dash.DashPattern = @(5, 4)
$g.DrawLine($dash, $panel - 7, 0, $panel - 7, $H)

# logo
$logo = [ImageKit]::CutOutWhite((Join-Path $root 'Images\Palawan Van Tropical Travel Logo.png'), 236, 4)
$lw = 410; $lh = [int]($logo.Height * $lw / $logo.Width); $top = [int](($H - ($lh + 24 + 72)) / 2)
$g.DrawImage($logo, [int](($panel - 14 - $lw) / 2), $top, $lw, $lh)

# service line
$font = New-Object System.Drawing.Font 'Segoe UI Semibold', 21
$fmt = New-Object System.Drawing.StringFormat; $fmt.Alignment = 'Center'
$ink = New-Object System.Drawing.SolidBrush (& $c '#10241a')
$g.DrawString("Shared & private van transfers,`nairport pickups, tours & rentals", $font, $ink, (New-Object System.Drawing.RectangleF 0, ($top + $lh + 24), ($panel - 14), 80), $fmt)

$out = Join-Path $root 'site\assets\img\og-image.jpg'
[ImageKit]::SaveJpeg($bmp, $out, 88)
$g.Dispose(); $bmp.Dispose(); $photo.Dispose(); $logo.Dispose()
Write-Host "wrote $out"
