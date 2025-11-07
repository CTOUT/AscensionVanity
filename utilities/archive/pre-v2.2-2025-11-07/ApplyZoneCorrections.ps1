# Apply Zone Corrections
# Fixes critical zone errors found during validation

$ErrorActionPreference = 'Stop'

$masterPath = 'data/MasterFullValidated.json'
$correctionsPath = 'data/corrections/ZoneCorrections_Nov5.json'
$outputPath = 'data/MasterFullValidated_ZoneCorrected.json'

Write-Host "`n=== APPLYING ZONE CORRECTIONS ===" -ForegroundColor Cyan

# Load data
$data = Get-Content $masterPath -Raw | ConvertFrom-Json
$corrections = Get-Content $correctionsPath -Raw | ConvertFrom-Json

Write-Host "Loaded $($data.Count) items from master" -ForegroundColor Gray

# Apply corrections
$corrected = 0
foreach ($prop in $corrections.PSObject.Properties) {
    $creatureId = [int]$prop.Name
    $correction = $prop.Value
    
    $item = $data | Where-Object { $_.CreatureId -eq $creatureId }
    
    if ($item) {
        Write-Host "`n✓ Correcting Creature $creatureId : $($item.Name)" -ForegroundColor Green
        Write-Host "  Old Description: $($item.Description)" -ForegroundColor DarkGray
        Write-Host "  New Description: $($correction.description)" -ForegroundColor Cyan
        Write-Host "  Old Zone: $($item.zone)" -ForegroundColor DarkGray
        Write-Host "  New Zone: $($correction.zone)" -ForegroundColor Cyan
        
        # Apply corrections
        $item | Add-Member -NotePropertyName "Description" -NotePropertyValue $correction.description -Force
        $item | Add-Member -NotePropertyName "zone" -NotePropertyValue $correction.zone -Force
        if ($correction.subzone) {
            $item | Add-Member -NotePropertyName "subzone" -NotePropertyValue $correction.subzone -Force
        }
        
        $corrected++
    } else {
        Write-Host "✗ Creature $creatureId not found in database" -ForegroundColor Red
    }
}

Write-Host "`n=== SUMMARY ===" -ForegroundColor Cyan
Write-Host "  Corrections applied: $corrected" -ForegroundColor Green

# Save
$data | ConvertTo-Json -Depth 10 | Out-File $outputPath -Encoding UTF8
Write-Host "`nSaved to: $outputPath" -ForegroundColor Green

Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "  1. Review: $outputPath"
Write-Host "  2. Copy: Copy-Item '$outputPath' '$masterPath' -Force"
Write-Host "  3. Re-run: .\utilities\EnrichZoneData.ps1"
Write-Host "  4. Regenerate: .\utilities\GenerateVanityDB_Master.ps1"
Write-Host "  5. Deploy: .\DeployAddon.ps1"

Write-Host "`n========================================`n" -ForegroundColor Cyan
