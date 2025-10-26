# Analyze source field values across multiple items to understand the pattern

Write-Host "Fetching category page..." -ForegroundColor Cyan
$response = Invoke-WebRequest -Uri "https://db.ascension.gg/?items=101.1" -UseBasicParsing
$html = $response.Content

Write-Host "Parsing JavaScript data..." -ForegroundColor Cyan
$listviewStart = $html.IndexOf('new Listview')
if ($listviewStart -eq -1) {
    Write-Host "Could not find Listview initialization" -ForegroundColor Red
    exit
}

$dataMarker = '"data":'
$dataStart = $html.IndexOf($dataMarker, $listviewStart)
if ($dataStart -eq -1) {
    Write-Host "Could not find data marker" -ForegroundColor Red
    exit
}

$dataArrayStart = $html.IndexOf('[', $dataStart)
if ($dataArrayStart -eq -1) {
    Write-Host "Could not find data array start" -ForegroundColor Red
    exit
}

# Extract a larger chunk of data to get multiple items
$dataChunk = $html.Substring($dataArrayStart, 50000)
$dataArrayEnd = $dataChunk.IndexOf(']},')
if ($dataArrayEnd -ne -1) {
    $dataChunk = $dataChunk.Substring(0, $dataArrayEnd + 1)
}

# Parse the JSON array
try {
    $items = $dataChunk | ConvertFrom-Json
    Write-Host "`nTotal items in sample: $($items.Count)" -ForegroundColor Green
    
    # Analyze source field patterns
    $itemsWithSourcemore = @($items | Where-Object { $_.sourcemore })
    $itemsWithSource = @($items | Where-Object { $_.source -and -not $_.sourcemore })
    
    Write-Host "`nItems with sourcemore field: $($itemsWithSourcemore.Count)" -ForegroundColor Yellow
    Write-Host "Items with source field only: $($itemsWithSource.Count)" -ForegroundColor Yellow
    
    # Collect all unique source code combinations
    $sourceCodeCombinations = @{}
    foreach ($item in $itemsWithSource) {
        $codes = $item.source -join ','
        if (-not $sourceCodeCombinations.ContainsKey($codes)) {
            $sourceCodeCombinations[$codes] = @()
        }
        $sourceCodeCombinations[$codes] += $item.name
    }
    
    Write-Host "`n=== SOURCE CODE PATTERNS ===" -ForegroundColor Cyan
    foreach ($codes in ($sourceCodeCombinations.Keys | Sort-Object)) {
        Write-Host "`nSource codes [$codes]:" -ForegroundColor Green
        Write-Host "  Count: $($sourceCodeCombinations[$codes].Count)"
        Write-Host "  Examples:"
        $sourceCodeCombinations[$codes] | Select-Object -First 3 | ForEach-Object {
            Write-Host "    - $_"
        }
    }
    
    # Show example of sourcemore field for comparison
    if ($itemsWithSourcemore.Count -gt 0) {
        Write-Host "`n=== SOURCEMORE FIELD EXAMPLE ===" -ForegroundColor Cyan
        $example = $itemsWithSourcemore[0]
        Write-Host "Item: $($example.name)"
        Write-Host "sourcemore: $($example.sourcemore | ConvertTo-Json -Compress)"
    }
    
} catch {
    Write-Host "Failed to parse JSON: $_" -ForegroundColor Red
    Write-Host "Data chunk preview:" -ForegroundColor Yellow
    Write-Host $dataChunk.Substring(0, [Math]::Min(1000, $dataChunk.Length))
}
