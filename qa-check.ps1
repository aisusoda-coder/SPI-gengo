$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$html = Get-Content "$PSScriptRoot\index.html" -Encoding UTF8 -Raw
$objects = [regex]::Matches(
  $html,
  '\{c:"(?<c>[^"]+)",q:"(?<q>(?:\\.|[^"])*)",o:\[(?<o>.*?)\],a:(?<a>\d+),e:"(?<e>(?:\\.|[^"])*)"',
  'Singleline'
)

$bad = @()
$seen = @{}
foreach ($m in $objects) {
  $q = $m.Groups['q'].Value
  $opts = [regex]::Matches($m.Groups['o'].Value, '"(?:\\.|[^"]*)"').Count
  $a = [int]$m.Groups['a'].Value
  if ($a -ge $opts) { $bad += "正解番号エラー: $($m.Groups['c'].Value) / a=$a / 選択肢=$opts / $q" }
  if ($seen.ContainsKey($q)) { $seen[$q]++ } else { $seen[$q] = 1 }
}

$dups = $seen.GetEnumerator() | Where-Object { $_.Value -gt 1 }
$markers = Select-String -Path "$PSScriptRoot\index.html" -Encoding UTF8 -Pattern '不適|選択肢にない|TODO|FIXME'

Write-Host "parsed fixed objects: $($objects.Count)"
Write-Host "bad answer index: $($bad.Count)"
Write-Host "duplicate question text: $($dups.Count)"
Write-Host "bad marker lines: $($markers.Count)"

if ($bad.Count -or $dups.Count -or $markers.Count) {
  $bad | Select-Object -First 20
  $dups | Select-Object -First 20 | ForEach-Object { "重複: $($_.Key)" }
  $markers | Select-Object -First 20 | ForEach-Object { "要確認: $($_.LineNumber): $($_.Line.Trim())" }
  exit 1
}

Write-Host "QA OK"
