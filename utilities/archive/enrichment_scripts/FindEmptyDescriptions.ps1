# Find remaining items with empty descriptions

$content = Get-Content "AscensionVanity\VanityDB.lua" -Raw

# Pattern to match item entries with empty descriptions
$pattern = '\[(\d+)\]\s*=\s*\{[^\}]*?\["name"\]\s*=\s*"([^"]+)"[^\}]*?\["description"\]\s*=\s*""'

$matches = [regex]::Matches($content, $pattern)

Write-Host "`nFound $($matches.Count) items with empty descriptions:`n" -ForegroundColor Yellow

foreach ($match in $matches) {
    $itemId = $match.Groups[1].Value
    $name = $match.Groups[2].Value
    Write-Host "$itemId`: $name"
}
