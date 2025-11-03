<#!
.SYNOPSIS
    Generate anomaly triage reports from validation CSV.
.DESCRIPTION
    Reads data/CreatureId_Anomalies_Report.csv produced by ValidateCreatureIds.ps1
    Classifies rows into:
      vendor_candidates (description or suggestion contains vendor pattern)
      prefix_strip_candidates (extreme,400prefix with no evidence)
      manual_review_highrange (highRange/extreme with evidenceCount=0 and no vendor/prefix classification)
    Outputs three JSON files in data/triage.
.NOTES
    Author: Automation
    Date: 2025-11-01
#>
[CmdletBinding()]
param(
    [string]$ValidationCsv = 'data/CreatureId_Anomalies_Report.csv',
    [string]$OutputFolder = 'data/triage'
)
if (!(Test-Path $ValidationCsv)) { Write-Error "Validation CSV not found: $ValidationCsv"; exit 1 }
if (!(Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder | Out-Null }

$vendorPatterns = @('Argent Quartermaster','Purchased from','Sold by','Requires Exalted','exempt_vendor_candidate','exempt_vendor_phrase')
$prefixStripReasons = @('extreme,400prefix','extreme,400prefix','highRange,400prefix')

$csv = Import-Csv $ValidationCsv
$vendor = @()
$prefixStrip = @()
$manual = @()
foreach ($row in $csv) {
    $reason = $row.Reasons
    $suggestion = $row.Suggestion
    $desc = $row.Description
    $isVendor = $false
    foreach ($pat in $vendorPatterns) { if ($suggestion -like "*$pat*" -or ($desc -and $desc -like "*$pat*")) { $isVendor = $true; break } }
    if ($isVendor) { $vendor += $row; continue }
    if ($reason -like '*400prefix*' -and $row.EvidenceCount -eq '0') { $prefixStrip += $row; continue }
    if ((($reason -like '*highRange*') -or ($reason -like '*extreme*')) -and $row.EvidenceCount -eq '0') { $manual += $row; continue }
}

$vendor | ConvertTo-Json -Depth 4 | Out-File (Join-Path $OutputFolder 'vendor_candidates.json') -Encoding UTF8
$prefixStrip | ConvertTo-Json -Depth 4 | Out-File (Join-Path $OutputFolder 'prefix_strip_candidates.json') -Encoding UTF8
$manual | ConvertTo-Json -Depth 4 | Out-File (Join-Path $OutputFolder 'manual_review_highrange.json') -Encoding UTF8

Write-Host "Triage complete:" -ForegroundColor Cyan
Write-Host "  Vendor candidates: $($vendor.Count)" -ForegroundColor Yellow
Write-Host "  Prefix-strip candidates: $($prefixStrip.Count)" -ForegroundColor Yellow
Write-Host "  Manual review (high/extreme): $($manual.Count)" -ForegroundColor Yellow
