param (
    [string] $sln
)

$ErrorActionPreference = "Stop"

class Project {
    [string]$Name
    [string]$Path
    [string[]]$References
}

function GetProjects {
    param ( [string]$sln )
    $projPaths = dotnet sln "$sln" list | where {$_.EndsWith(".csproj")} 
    
    $slnDir = [System.IO.Path]::GetDirectoryName("$sln")
    $list = [System.Collections.Generic.List[Project]]::new()
    foreach ($path in $projPaths) {
        $path = Join-Path -Path "$slnDir" -ChildPath "$path"
        $isPackable = [System.Convert]::ToBoolean(( dotnet msbuild $path -getProperty:IsPackable ))
        if( !$isPackable ) {
            continue
        }

        $proj = [Project]::new()
        $proj.Name = (Get-Item $path ).BaseName
        $proj.Path = $path
        $list.Add($proj)  
    }

    $names = $list | ForEach-Object {$_.Name}
    foreach( $proj in $list ) {
        $refs = GetPackageReferences -csproj "$($proj.Path)"
        $proj.References =  $refs | Where-Object { $_ -in $names }
    }

    return $list
}

function GetPackageReferences{
    param ( [string]$csproj )
    
    $refs = (Select-Xml -Path $csproj -XPath "//PackageReference")    
    $list = [System.Collections.Generic.List[string]]::new()

    foreach($r in $refs) {
        $list.Add($r.Node.Include)
    }
    
    return $list
}

function CircularReferenceMessage{
    param ( [Project[]]$projects ) 
    
    $sb = [System.Text.StringBuilder]::new()
    $null = $sb.AppendLine("Circular Reference:")
    foreach( $p in $projects ) {
        $null = $sb.AppendLine("$($p.Name):")
        foreach( $r in $p.References) {
            $null = $sb.AppendLine("  -> $($r)")
        }
    }

    return $sb.ToString()
}

function TopologicalSort {
    param ( [Project[]]$projects )

    $sortedNames = [System.Collections.Generic.List[string]]::new()
    $sorted = [System.Collections.Generic.List[Project]]::new() 
    $unsorted = [System.Collections.Generic.List[Project]]::new()    
    $names = [System.Collections.Generic.List[string]]::new()

    foreach( $p in $projects){
        if( $p.Name -in $names ) {
            Write-Error "Duplicate project name '$($p.Name)'."
            exit
        }
        $names.Add($p.Name)

        if ( $p.References.Count -eq 0) {
            $sortedNames.Add($p.Name)
            $sorted.Add($p)
        }else{
            $unsorted.Add($p)
        }        
    }
   
    while( $unsorted.Count -gt 0) {        
        foreach ($p in $unsorted ) {
            $unsortedRef = $p.References | Where-Object { $_ -notin $sortedNames }
            if( $unsortedRef.Count -eq 0 ){
                $sortedNames.Add($p.Name)
                $sorted.Add($p)
            }
        }
        
        $prevNumUnsorted =  $unsorted.Count
        $unsorted = $unsorted | Where-Object { $_.Name -notin $sortedNames }
       
        if ( ( $unsorted.Count -eq $prevNumUnsorted ) -and ( $prevNumUnsorted -gt 0 ) ) {
             Write-Error "$(CircularReferenceMessage -projects $unsorted)"
             exit
        } 
    }

    return $sorted
}

function CleanProject {
    param ([Project]$project)

    dotnet clean "$($project.Path)"

    # Remove package from global cache.
    $globalCacheDir = ("$(dotnet nuget locals global-packages  -l )" -split ' ', 2)[1]    
    if ( (Test-Path -LiteralPath "$globalCacheDir") ) {        
        $packageDir = Join-Path -Path "$($globalCacheDir)" -ChildPath "$($project.Name)"
        if ((Test-Path -LiteralPath  $"$packageDir")) {
            Remove-Item -LiteralPath "$packageDir" -Recurse # -Force
        }
    }
}

function PackProjects {
    param ([Project[]]$projects)

    foreach ( $p in $projects) {
        CleanProject -project $p
        dotnet pack "$($p.Path)"
    }
}

function PackSolutionProjects {
    param ( [string]$sln )

        $sln = GetSolutionFile -sln "$sln"
        $slnProjects = GetProjects -sln "$sln"
        $sortedProjects = TopologicalSort -projects $slnProjects
        PackProjects -projects $sortedProjects
}

function GetSolutionFile {
    param ( [string]$sln ) 

    if ( "$sln" ) {
        if ( !(Test-Path -LiteralPath "$sln") ) {
            Write-Error "The solution file does not exist: '$sln'"
            exit
        }
        return Convert-Path -LiteralPath "$sln"
    }

    $sln = (Get-ChildItem $pwd.Path -Name  -Include *.sln)
    $count = $sln.Count
    if ( $count -eq 0) {
        Write-Error "The folder is not a solution folder: $($pwd.Path)"
        exit
    } elseif ( $count -gt 1 ) {
        Write-Error "Multiple '.sln' files found in folder: $($pwd.Path)"
        exit
    }

    return Convert-Path -LiteralPath "$sln"
}


$SourcePath = $pwd.Path
try{
    PackSolutionProjects -sln "$sln"

} finally {
    Set-Location $SourcePath
}




