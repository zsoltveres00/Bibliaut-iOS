# Merges content/base.json + content/modules/*.json into the app's content.json,
# then bakes docs/play.html from the web template.
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$utf8 = New-Object Text.UTF8Encoding $false

$base = Get-Content "$root\content\base.json" -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable
$base.gifts = Get-Content "$root\content\gifts.json" -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable
$units = @()
foreach ($f in Get-ChildItem "$root\content\modules\*.json" | Sort-Object Name) {
    $u = Get-Content $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable
    $units += $u
}
$content = [ordered]@{ levels = $base.levels; gifts = $base.gifts; icons = $base.icons; units = $units }
$json = $content | ConvertTo-Json -Depth 30 -Compress
[IO.File]::WriteAllText("$root\Bibliaut\Resources\content.json", $json, $utf8)

$t = [IO.File]::ReadAllText("$root\docs\play.template.html", [Text.Encoding]::UTF8)
[IO.File]::WriteAllText("$root\docs\play.html", $t.Replace('__CONTENT__', $json), $utf8)

$q = 0; foreach ($u in $units) { foreach ($s in $u.stations) { $q += $s.qs.Count } }
"content.json: {0} modul, {1} allomas, {2} kerdes, {3} kartya" -f $units.Count, ($units | ForEach-Object { $_.stations.Count } | Measure-Object -Sum).Sum, $q, $base.gifts.Count

