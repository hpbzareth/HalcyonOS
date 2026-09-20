$runId = 35516771663
$repo = "hpbzareth/HalcyonOS"
$inputUrl = "https://zenlayer.dl.sourceforge.net/project/xiaomi-eu-multilang-miui-roms/xiaomi.eu/HyperOS-STABLE-RELEASES/HyperOS3.0/xiaomi.eu_ANNIBALE_OS3.0.307.0.WPKCNXM_16.zip?viasf=1&fid=98e814cfbfabd219&e=1790000912&st=jGeyDXrv49llbfxfLJrWBg"
$builderName = "Zareth"
$builderId = "632974560"

Write-Host "Monitoring run $runId ..."

while ($true) {
    Start-Sleep -Seconds 30
    
    $statusJson = & "C:\Program Files\GitHub CLI\gh.exe" api repos/$repo/actions/runs/$runId
    if (-not $statusJson) { continue }
    
    $statusObj = $statusJson | ConvertFrom-Json
    $status = $statusObj.status
    $conclusion = $statusObj.conclusion
    
    Write-Host "Current status: $status (Conclusion: $conclusion)"
    
    if ($status -eq "completed") {
        if ($conclusion -eq "failure" -or $conclusion -eq "cancelled") {
            Write-Host "Run failed! Triggering a new run with provided inputs..."
            & "C:\Program Files\GitHub CLI\gh.exe" workflow run build.yml -R $repo -f input_url=$inputUrl -f builder_name=$builderName -f builder_id=$builderId
            Write-Host "New run triggered."
        } else {
            Write-Host "Run succeeded! No action needed."
        }
        break
    }
}
Write-Host "Monitor script finished."
