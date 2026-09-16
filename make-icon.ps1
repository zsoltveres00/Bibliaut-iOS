param([string]$Out)
Add-Type -AssemblyName System.Drawing
$S = 1024
$bmp = New-Object System.Drawing.Bitmap $S, $S
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

# Background: brand burgundy with a soft vertical gradient
$top = [System.Drawing.Color]::FromArgb(255, 0x6E, 0x34, 0x47)
$bottom = [System.Drawing.Color]::FromArgb(255, 0x4A, 0x20, 0x2F)
$bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    (New-Object System.Drawing.Rectangle 0, 0, $S, $S), $top, $bottom,
    [System.Drawing.Drawing2D.LinearGradientMode]::Vertical)
$g.FillRectangle($bg, 0, 0, $S, $S)

$gold  = [System.Drawing.Color]::FromArgb(255, 0xE0, 0xB5, 0x63)
$cream = [System.Drawing.Color]::FromArgb(255, 0xFB, 0xF6, 0xEC)
$shadow = [System.Drawing.Color]::FromArgb(70, 0, 0, 0)

# Winding path (S-curve) from bottom-left to top-right
[System.Drawing.PointF[]]$pts = @(
    (New-Object System.Drawing.PointF 210, 850),
    (New-Object System.Drawing.PointF 560, 700),
    (New-Object System.Drawing.PointF 320, 470),
    (New-Object System.Drawing.PointF 740, 340),
    (New-Object System.Drawing.PointF 500, 150)
)
$penShadow = New-Object System.Drawing.Pen $shadow, 78
$penShadow.StartCap = 'Round'; $penShadow.EndCap = 'Round'; $penShadow.LineJoin = 'Round'
$g.TranslateTransform(0, 10)
$g.DrawCurve($penShadow, $pts, [single]0.6)
$g.ResetTransform()

$pen = New-Object System.Drawing.Pen $cream, 62
$pen.StartCap = 'Round'; $pen.EndCap = 'Round'; $pen.LineJoin = 'Round'
$g.DrawCurve($pen, $pts, [single]0.6)

# Station nodes along the path
$nodeR = 66
$brGold = New-Object System.Drawing.SolidBrush $gold
$brCream = New-Object System.Drawing.SolidBrush $cream
$brShadow = New-Object System.Drawing.SolidBrush $shadow
foreach ($p in $pts[0..3]) {
    $g.FillEllipse($brShadow, $p.X - $nodeR, $p.Y - $nodeR + 10, 2 * $nodeR, 2 * $nodeR)
    $g.FillEllipse($brCream, $p.X - $nodeR - 8, $p.Y - $nodeR - 8, 2 * $nodeR + 16, 2 * $nodeR + 16)
    $g.FillEllipse($brGold, $p.X - $nodeR, $p.Y - $nodeR, 2 * $nodeR, 2 * $nodeR)
}

# Goal node at the top: bigger gold disc with a cream cross
$t = $pts[4]; $R = 118
$g.FillEllipse($brShadow, $t.X - $R, $t.Y - $R + 12, 2 * $R, 2 * $R)
$g.FillEllipse($brCream, $t.X - $R - 10, $t.Y - $R - 10, 2 * $R + 20, 2 * $R + 20)
$g.FillEllipse($brGold, $t.X - $R, $t.Y - $R, 2 * $R, 2 * $R)
$crossPen = New-Object System.Drawing.Pen $cream, 30
$crossPen.StartCap = 'Round'; $crossPen.EndCap = 'Round'
$g.DrawLine($crossPen, $t.X, $t.Y - 74, $t.X, $t.Y + 74)
$g.DrawLine($crossPen, $t.X - 52, $t.Y - 22, $t.X + 52, $t.Y - 22)

$g.Dispose()
$bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
"saved $Out"
