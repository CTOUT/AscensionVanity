# Quick diagnostic script to examine sourcemore field structure
$url = "https://db.ascension.gg/?items=101.1"
$response = Invoke-WebRequest -Uri $url -UseBasicParsing
$html = $response.Content

# Find the Listview JavaScript data
$listviewStart = $html.IndexOf('new Listview')
if ($listviewStart -eq -1) {
    Write-Host "Could not find Listview initialization" -ForegroundColor Red
    exit
}

# Extract just the data array
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

$dataArrayEnd = $html.IndexOf('],', $dataArrayStart)
if ($dataArrayEnd -eq -1) {
    Write-Host "Could not find data array end, trying simpler pattern..." -ForegroundColor Yellow
    $dataArrayEnd = $html.Length - 1
}

# Get a manageable chunk with first few items
$dataChunk = $html.Substring($dataArrayStart, [Math]::Min(5000, $dataArrayEnd - $dataArrayStart))

Write-Host "First 5000 characters of data array:" -ForegroundColor Cyan
Write-Host $dataChunk

# Try to extract first complete item
$firstItemEnd = $dataChunk.IndexOf('},{')
if ($firstItemEnd -ne -1) {
    $firstItem = $dataChunk.Substring(0, $firstItemEnd + 1)
    Write-Host "`n`nFirst complete item:" -ForegroundColor Green
    Write-Host $firstItem
    
    # Check for sourcemore field
    if ($firstItem -match '"sourcemore":\[([^\]]+)\]') {
        Write-Host "`n`nsourcemore field found:" -ForegroundColor Yellow
        Write-Host $Matches[1]
    } else {
        Write-Host "`n`nNO sourcemore field in first item!" -ForegroundColor Red
    }
    
    # Check for alternate source field
    if ($firstItem -match '"source":\[([^\]]+)\]') {
        Write-Host "`nsource field found instead:" -ForegroundColor Green
        Write-Host $Matches[1]
    }
    
    # Show full item structure for clarity
    Write-Host "`n`nParsing full structure..." -ForegroundColor Cyan
    try {
        $itemObj = $firstItem | ConvertFrom-Json
        Write-Host "Fields present: $($itemObj.PSObject.Properties.Name -join ', ')" -ForegroundColor Cyan
        if ($itemObj.source) {
            Write-Host "source field type: $($itemObj.source.GetType().Name)" -ForegroundColor Yellow
            Write-Host "source field value: $($itemObj.source)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Failed to parse JSON: $_" -ForegroundColor Red
    }
}
