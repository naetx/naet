param (
    $ProjectDir = $null
)

$ProjectDir = [IO.Path]::GetFullPath($ProjectDir)

function  Get-NuGetSource {
    param ( $Key )

    $NuGetConfig =  "$RepoRoot/NuGet.config"
    $XPath = "//packageSources/add[@key='$Key'][1]"
    $SourceUrl = (Select-Xml -Path $NuGetConfig -XPath $XPath).Node.value
    return $SourceUrl
}


$ProjectFileExt = ".csproj"

if (!(Test-Path -Path "$(Join-Path -Path $ProjectDir -ChildPath "*$ProjectFileExt")")) {
    Write-Host -ForegroundColor Red "The '$ProjectFileExt' file not found: $ProjectDir"
    exit
}

try {
    Set-Location $ProjectDir

    $RepoRoot = dotnet msbuild -getProperty:RepoRoot
    $ProjectName =  dotnet msbuild -getProperty:MSBuildProjectName
    $ProjectVersion = dotnet msbuild -getProperty:Version
    $ArtifactsPath=Join-Path -Path $RepoRoot -ChildPath "artifacts"

    dotnet clean
    dotnet pack

    $NuGetKey = (Read-Host "Push to source").Trim()
    if ( "$NuGetKey" -eq "" ){
        Write-Host "Canceled"
        exit
    }

    $NuGetUrl = ( Get-NuGetSource -Key $NuGetKey )
    
    if ( "$NuGetUrl" -eq "" ){
        Write-Host -ForegroundColor Red "NuGet source not found with key '$NuGetKey'"
        exit
    }
    
    $PackageOutputPath = Join-Path -Path  $ArtifactsPath -ChildPath "package/release"
    $ProjectNameVersion = Join-Path -Path $PackageOutputPath -ChildPath "$ProjectName.$ProjectVersion"

    $nupkg = "$ProjectNameVersion.nupkg"
    $snupkg = "$ProjectNameVersion.snupkg"

    if(!(Test-Path -Path $nupkg)) {
        Write-Host -ForegroundColor Red "Unexpected packages output directory." 
        exit
    }
    # The env name of the nuget api key is "<nuget source key>ApiKey"
    $NuGetApiKeyEnvName = "$($NuGetKey)ApiKey"
    $NuGetApiKey = [Environment]::GetEnvironmentVariable($NuGetApiKeyEnvName)

    $pushNupkg = "dotnet nuget push $nupkg -s $NuGetUrl"
    $pushSnupkg = "dotnet nuget push $snupkg -s $NuGetUrl"
    if ("$NuGetApiKey" -ne "") {
        $pushNupkg = "$pushNupkg -k $NuGetApiKey"
        $pushSnupkg = "$pushSnupkg -k $NuGetApiKey"
    }

    if(Invoke-Expression $pushNupkg) {
        Invoke-Expression $pushSnupkg
    }

}
finally {
    Set-Location $PSScriptRoot
}


