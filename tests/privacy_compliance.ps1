$ErrorActionPreference = 'Stop'

$sourceRoot = Join-Path $PSScriptRoot '..\Zhugeio\Classes\ZGCore'
$sourceFiles = Get-ChildItem -Path $sourceRoot -Recurse -Include '*.m', '*.h'
$prohibitedPatterns = @(
    'identifierForVendor',
    'uname\s*\(',
    'CTTelephonyNetworkInfo',
    'CTRadioAccessTechnology',
    'ASIdentifierManager',
    'ATTrackingManager',
    'AAAttribution',
    '\bidfa\b',
    'AdServices',
    'advertisingIdentifier',
    'isAdvertisingTrackingEnabled',
    'api-adservices\.apple\.com',
    'AppTrackingTransparency',
    'AdSupport',
    'SCNetworkReachability',
    'CaptiveNetwork',
    'deviceId',
    'DeviceId',
    '\$idfa',
    '\$net',
    '\$mnet',
    '\$tz',
    '@"tz"'
)

foreach ($pattern in $prohibitedPatterns) {
    $matches = $sourceFiles | Select-String -Pattern $pattern
    if ($matches) {
        $locations = ($matches | ForEach-Object { "$($_.Path):$($_.LineNumber)" }) -join ', '
        throw "Privacy compliance failure: prohibited fingerprinting API '$pattern' found at $locations"
    }
}

$privacyManifest = Join-Path $PSScriptRoot '..\Zhugeio\Resources\PrivacyInfo.xcprivacy'
if (Select-String -Path $privacyManifest -Pattern 'NSPrivacyCollectedDataTypeDeviceID' -Quiet) {
    throw "Privacy compliance failure: $privacyManifest declares collection of a device identifier."
}

Write-Host 'Privacy compliance checks passed.'
