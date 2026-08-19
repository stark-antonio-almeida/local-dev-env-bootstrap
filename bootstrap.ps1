param(
    [switch]$DryRun,
    [string]$Platform = "windows11",
    [ValidateSet("human", "json")]
    [string]$Output = "human"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$StartedAt = (Get-Date).ToUniversalTime().ToString("o")

$RecipeFile = Join-Path $PSScriptRoot "recipes\packages.json"
$ScriptsRoot = Join-Path $PSScriptRoot "scripts"

$InstalledPackages = [System.Collections.Generic.List[string]]::new()
$SkippedPackages = [System.Collections.Generic.List[string]]::new()
$DryRunPackages = [System.Collections.Generic.List[string]]::new()
$FailedPackages = [System.Collections.Generic.List[string]]::new()
$RunEvents = [System.Collections.Generic.List[object]]::new()

function Write-RunLine {
    param(
        [string]$Message
    )

    if ($Output -eq "human") {
        Write-Host $Message
    }
}

function Add-RunEvent {
    param(
        [string]$PackageName,
        [string]$Phase,
        [string]$Action,
        [string]$Status,
        [string]$Command,
        [string]$OutputText
    )

    $RunEvents.Add([PSCustomObject]@{
            timestamp = (Get-Date).ToUniversalTime().ToString("o")
            package   = $PackageName
            phase     = $Phase
            action    = $Action
            status    = $Status
            command   = $Command
            output    = $OutputText
        }) | Out-Null
}

function Write-CommandOutput {
    param(
        [string[]]$Lines
    )

    if ($Output -ne "human") {
        return
    }

    foreach ($Line in $Lines) {
        if (-not [string]::IsNullOrEmpty($Line)) {
            Write-Host "      | $Line"
        }
    }
}

function Invoke-StructuredOperation {
    param(
        [string]$PackageName,
        [string]$Phase,
        [string]$Action,
        [string]$DisplayCommand,
        [scriptblock]$ScriptBlock,
        [object[]]$Arguments = @(),
        [switch]$SkipOnDryRun,
        [switch]$QuietSuccess
    )

    if ($Output -eq "human") {
        Write-RunLine "    $Phase`: $DisplayCommand"
    }

    if ($DryRun -and $SkipOnDryRun) {
        Write-RunLine "      -> skip (dry-run)"
        Add-RunEvent -PackageName $PackageName -Phase $Phase -Action $Action -Status "dry-run" -Command $DisplayCommand -OutputText ""
        return $true
    }

    $OperationOutput = @()
    $Succeeded = $true
    $NativeExitCode = $null

    try {
        $global:LASTEXITCODE = $null
        $OperationOutput = @(& $ScriptBlock @Arguments 2>&1 | ForEach-Object { "$_" })
        $NativeExitCode = $LASTEXITCODE
        if ($null -ne $NativeExitCode -and $NativeExitCode -ne 0) {
            $Succeeded = $false
        }
    }
    catch {
        $Succeeded = $false
        $OperationOutput += $_.Exception.Message
    }

    if ($Succeeded) {
        if (-not $QuietSuccess) {
            Write-CommandOutput -Lines $OperationOutput
        }
        Add-RunEvent -PackageName $PackageName -Phase $Phase -Action $Action -Status "ok" -Command $DisplayCommand -OutputText ($OperationOutput -join [Environment]::NewLine)
        return $true
    }

    Write-CommandOutput -Lines $OperationOutput
    if ($null -ne $NativeExitCode) {
        Write-RunLine "      -> failed (exit $NativeExitCode)"
    }
    else {
        Write-RunLine "      -> failed"
    }
    Add-RunEvent -PackageName $PackageName -Phase $Phase -Action $Action -Status "failed" -Command $DisplayCommand -OutputText ($OperationOutput -join [Environment]::NewLine)
    return $false
}

function ConvertTo-Hashtable {
    param(
        [Parameter(Mandatory = $true)]
        $InputObject
    )

    if ($null -eq $InputObject) {
        return $null
    }

    if ($InputObject -is [System.Collections.IDictionary]) {
        $Result = @{}
        foreach ($Key in $InputObject.Keys) {
            $Result[$Key] = ConvertTo-Hashtable $InputObject[$Key]
        }
        return $Result
    }

    if ($InputObject -is [System.Collections.IEnumerable] -and -not ($InputObject -is [string])) {
        $Result = @()
        foreach ($Item in $InputObject) {
            $Result += ,(ConvertTo-Hashtable $Item)
        }
        return $Result
    }

    if ($InputObject -is [pscustomobject]) {
        $Result = @{}
        foreach ($Property in $InputObject.PSObject.Properties) {
            $Result[$Property.Name] = ConvertTo-Hashtable $Property.Value
        }
        return $Result
    }

    return $InputObject
}

$RawRecipes = Get-Content $RecipeFile -Raw | ConvertFrom-Json
$Recipes = ConvertTo-Hashtable $RawRecipes

function Import-ManagerScript {
    param(
        [string]$Manager
    )

    $ManagerScript = Join-Path $ScriptsRoot "$Manager.ps1"
    if (-not (Test-Path -LiteralPath $ManagerScript)) {
        throw "Missing manager script: $ManagerScript"
    }

    . $ManagerScript
}

$RunExpression = {
    param([string]$CommandText)
    Invoke-Expression $CommandText
}

$RunValidation = {
    param([string]$CommandText)
    if (Get-Command -Name Test-Package -ErrorAction SilentlyContinue) {
        Test-Package $CommandText
    }
    else {
        Invoke-Expression $CommandText
    }
}

$RunInstall = {
    param([string]$PackageId, [object[]]$PackageFlags)
    Install-Package $PackageId @PackageFlags
}

Write-RunLine "DryRun = $DryRun"
Write-RunLine "Platform = $Platform"
Write-RunLine "Output = $Output"

foreach ($RecipeName in $Recipes.Keys) {

    $Recipe = $Recipes[$RecipeName]

    if (-not $Recipe.ContainsKey($Platform)) {
        continue
    }

    $PlatformRecipe = $Recipe[$Platform]

    Write-RunLine "Cook: [$RecipeName]"

    $Manager = $PlatformRecipe.manager

    Write-RunLine "    pantry: $Manager"

    Import-ManagerScript $Manager

    $ValidationCommands = $PlatformRecipe.validation
    $SkipInstall = $false

    if ($null -ne $ValidationCommands) {
        $ValidationPassed = $true
        foreach ($Command in $ValidationCommands) {
            if (-not (Invoke-StructuredOperation -PackageName $RecipeName -Phase "precheck" -Action "validation" -DisplayCommand $Command -ScriptBlock $RunValidation -Arguments @($Command) -QuietSuccess)) {
                $ValidationPassed = $false
                break
            }
        }

        if ($ValidationPassed) {
            Write-RunLine "    stocked: $RecipeName"
            Add-RunEvent -PackageName $RecipeName -Phase "precheck" -Action "package-skip" -Status "ok" -Command "validation passed" -OutputText ""
            $SkippedPackages.Add($RecipeName)
            $SkipInstall = $true
        }
    }

    if ($SkipInstall) {
        Write-RunLine ""
        continue
    }

    $PackageFailed = $false

    foreach ($Command in @($PlatformRecipe.pre)) {
        if ([string]::IsNullOrWhiteSpace($Command)) {
            continue
        }
        if (-not (Invoke-StructuredOperation -PackageName $RecipeName -Phase "prep" -Action "command" -DisplayCommand $Command -ScriptBlock $RunExpression -Arguments @($Command) -SkipOnDryRun)) {
            $PackageFailed = $true
            break
        }
    }

    if (-not $PackageFailed -and $null -ne $PlatformRecipe.package) {
        $Package = $PlatformRecipe.package

        $Flags = @()

        if ($null -ne $PlatformRecipe.flags) {
            $Flags = @($PlatformRecipe.flags)
        }

        $DisplayInstall = "install $Package"
        if ($Flags.Count -gt 0) {
            $DisplayInstall = "$DisplayInstall $($Flags -join ' ')"
        }

        if (-not (Invoke-StructuredOperation -PackageName $RecipeName -Phase "simmer" -Action "install" -DisplayCommand $DisplayInstall -ScriptBlock $RunInstall -Arguments @($Package, $Flags) -SkipOnDryRun)) {
            $PackageFailed = $true
        }
    }

    if (-not $PackageFailed) {
        foreach ($Command in @($PlatformRecipe.install)) {
            if ([string]::IsNullOrWhiteSpace($Command)) {
                continue
            }
            if (-not (Invoke-StructuredOperation -PackageName $RecipeName -Phase "cook" -Action "command" -DisplayCommand $Command -ScriptBlock $RunExpression -Arguments @($Command) -SkipOnDryRun)) {
                $PackageFailed = $true
                break
            }
        }
    }

    if (-not $PackageFailed) {
        foreach ($Command in @($PlatformRecipe.post)) {
            if ([string]::IsNullOrWhiteSpace($Command)) {
                continue
            }
            if (-not (Invoke-StructuredOperation -PackageName $RecipeName -Phase "season" -Action "command" -DisplayCommand $Command -ScriptBlock $RunExpression -Arguments @($Command) -SkipOnDryRun)) {
                $PackageFailed = $true
                break
            }
        }
    }

    $ValidationPassed = $true
    if (-not $PackageFailed -and $null -ne $ValidationCommands) {

        foreach ($Command in $ValidationCommands) {
            if ($DryRun) {
                Invoke-StructuredOperation -PackageName $RecipeName -Phase "taste" -Action "validation" -DisplayCommand $Command -ScriptBlock $RunValidation -Arguments @($Command) -SkipOnDryRun | Out-Null
            }
            else {
                if (-not (Invoke-StructuredOperation -PackageName $RecipeName -Phase "taste" -Action "validation" -DisplayCommand $Command -ScriptBlock $RunValidation -Arguments @($Command))) {
                    $ValidationPassed = $false
                } 
            }
        }
    }

    if ($DryRun) {
        $DryRunPackages.Add($RecipeName)
    }
    elseif (-not $PackageFailed -and $ValidationPassed) {
        $InstalledPackages.Add($RecipeName)
    }
    else {
        $FailedPackages.Add($RecipeName)
    }

    Write-RunLine ""
}

$FinishedAt = (Get-Date).ToUniversalTime().ToString("o")

if ($Output -eq "human") {
    Write-Host ""
    Write-Host "Summary"
    Write-Host "  Skip     : $($SkippedPackages -join ' ')"
    Write-Host "  Dry Run  : $($DryRunPackages -join ' ')"
    Write-Host "  Installed: $($InstalledPackages -join ' ')"
    Write-Host "  Failed   : $($FailedPackages -join ' ')"
}
else {
    [PSCustomObject]@{
        format_version = 1
        started_at     = $StartedAt
        finished_at    = $FinishedAt
        platform       = $Platform
        dry_run        = [bool]$DryRun
        summary        = [PSCustomObject]@{
            skipped   = @($SkippedPackages)
            dry_run   = @($DryRunPackages)
            installed = @($InstalledPackages)
            failed    = @($FailedPackages)
            counts    = [PSCustomObject]@{
                skipped   = $SkippedPackages.Count
                dry_run   = $DryRunPackages.Count
                installed = $InstalledPackages.Count
                failed    = $FailedPackages.Count
            }
        }
        events         = @($RunEvents)
    } | ConvertTo-Json -Depth 8
}
