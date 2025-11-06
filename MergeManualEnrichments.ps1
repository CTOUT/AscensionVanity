$research = Get-Content data\corrections\ManualResearch.json -Raw | ConvertFrom-Json
$current = Get-Content data\Manual_Enrichments.json -Raw | ConvertFrom-Json

$enrichments = @{}
foreach ($prop in $current.PSObject.Properties) {
    $enrichments[$prop.Name] = $prop.Value
}

$added = 0
foreach ($item in $research) {
    $id = $item.DbItemId.ToString()
    if (-not $enrichments.ContainsKey($id)) {
        # Extract zone from description
        $zone = $null
        if ($item.Description -match 'within\s+([A-Za-z\s'':-]+)$') {
            $zone = $Matches[1].Trim()
        } elseif ($item.Description -match '\((?:possibly|likely)\s+([^)]+)\)') {
            $zone = $Matches[1].Trim()
        }
        
        # Use the Description field directly from ManualResearch.json
        $enrichments[$id] = @{
            description = $item.Description
            zone = $zone
            category = $item.Category
            note = "From ManualResearch.json"
        }
        $added++
        Write-Host "  Added: [$id] $($item.Name)" -ForegroundColor Green
    }
}

$enrichments | ConvertTo-Json -Depth 10 | Out-File data\Manual_Enrichments.json -Encoding UTF8
Write-Host "`n✓ Merged manual research" -ForegroundColor Cyan
Write-Host "  Added: $added entries" -ForegroundColor Green
Write-Host "  Total: $($enrichments.Count) enrichments" -ForegroundColor White
