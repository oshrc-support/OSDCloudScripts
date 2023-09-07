﻿[CmdletBinding()]
param ()

if (Test-Path "$env:HOMEPATH\Documents\PSTechPulseSettings.json") {
    $Global:PSTechPulseSettings = Get-Content "$env:HOMEPATH\Documents\PSTechPulseSettings.json" | ConvertFrom-Json
}
else {
    Write-Warning "No settings file found, please run Set-PSTechPulseSettings first."
    Break
}

if ($Global:PSTechPulseSettings.auth_code) {
    #$code = $Global:PSTechPulseSettings.auth_code
}
else {
    Write-Warning "No auth code found, please run Get-PSTechPulseAuthCode first."
    Break
}

$Body = @{
    "grant_type" = "authorization_code"
    "code" = $Global:PSTechPulseSettings.auth_code
    "redirect_uri" = $Global:PSTechPulseSettings.redirect_uri
    "client_id" = $Global:PSTechPulseSettings.client_id
    "client_secret" = $Global:PSTechPulseSettings.client_secret
}

try {
    $AccessToken = Invoke-RestMethod -Method Post -Body $Body -Uri $Global:PSTechPulseSettings.access_token_uri -Headers @{'Content-Type' = 'application/x-www-form-urlencoded'} -ErrorAction Stop
}
catch {
    Write-Warning 'Error getting access token. Try running Get-PSTechPulseAuthCode first.'
    throw $_.Exception
}

if ($AccessToken.access_token) {
    $Global:PSTechPulseSettings.access_token = $AccessToken.access_token
    $Global:PSTechPulseSettings | ConvertTo-Json | Out-File "$env:HOMEPATH\Documents\PSTechPulseSettings.json" -Encoding ascii -Force
}
else {
    Write-Warning 'Error getting access_token.'
    throw
}
if ($AccessToken.refresh_token) {
    $Global:PSTechPulseSettings.refresh_token = $AccessToken.refresh_token
    $Global:PSTechPulseSettings | ConvertTo-Json | Out-File "$env:HOMEPATH\Documents\PSTechPulseSettings.json" -Encoding ascii -Force
}
else {
    Write-Warning 'Error getting refresh_token.'
    throw
}