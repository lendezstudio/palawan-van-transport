# Minimal static file server for previewing /site locally.
# Usage: powershell -ExecutionPolicy Bypass -File tools\serve.ps1 [-Port 8080]   then open http://localhost:8080/
param([int]$Port = 8080)
$root = Join-Path (Split-Path $PSScriptRoot -Parent) 'site'
$types = @{ '.html'='text/html; charset=utf-8'; '.css'='text/css'; '.js'='text/javascript'; '.json'='application/json';
  '.webmanifest'='application/manifest+json'; '.png'='image/png'; '.jpg'='image/jpeg'; '.ico'='image/x-icon';
  '.svg'='image/svg+xml'; '.xml'='application/xml'; '.txt'='text/plain' }
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()
Write-Host "Serving $root at http://localhost:$Port/"
while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  try {
    $path = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath).TrimStart('/')
    $file = Join-Path $root $path
    if ((Test-Path $file -PathType Container)) {
      if (-not $path.EndsWith('/') -and $path -ne '') { $ctx.Response.Redirect("/$path/"); $ctx.Response.Close(); continue }
      $file = Join-Path $file 'index.html'
    }
    $status = 200
    if (-not (Test-Path $file -PathType Leaf)) { $file = Join-Path $root '404.html'; $status = 404 }
    $bytes = [System.IO.File]::ReadAllBytes($file)
    $ext = [System.IO.Path]::GetExtension($file).ToLower()
    $ctx.Response.StatusCode = $status
    $ctx.Response.ContentType = $(if ($types[$ext]) { $types[$ext] } else { 'application/octet-stream' })
    $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
  } catch { $ctx.Response.StatusCode = 500 }
  $ctx.Response.Close()
}
