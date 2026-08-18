param(
    [switch]$DryRun
)
Write-Host "DryRun = $DryRun"
$RecipeFile = "recipes/packages.json"

$Recipes = Get-Content $RecipeFile -Raw | ConvertFrom-Json -AsHashtable

function Invoke-Step {
    param(
        [string]$Command
    )

    if ($DryRun) {
        Write-Host "    do: $Command"
    }
    else {
        Invoke-Expression $Command
    }
}

function Invoke-Steps {
    param(
        [string]$Label,
        $Commands
    )

    if ($null -eq $Commands) {
        return
    }

    foreach ($Command in $Commands) {

        if ($DryRun) {
            Write-Host "    $Label`: $Command"
        }
        else {
            Invoke-Step $Command
        }
    }
}

foreach ($RecipeName in $Recipes.Keys) {

    $Recipe = $Recipes[$RecipeName]

    if (-not $Recipe.ContainsKey("windows11")) {
        continue
    }

    $WindowsRecipe = $Recipe["windows11"]

    Write-Host "Cook: [$RecipeName]"

    $Manager = $WindowsRecipe.manager

    Write-Host "    pantry: $Manager"

    Invoke-Steps "prep" $WindowsRecipe.pre

    if ($null -ne $WindowsRecipe.package) {

        $Package = $WindowsRecipe.package

        $Flags = @()

        if ($null -ne $WindowsRecipe.flags) {
            $Flags = $WindowsRecipe.flags
        }

        if ($DryRun) {

            $FlagText = ($Flags -join " ")

            if ([string]::IsNullOrWhiteSpace($FlagText)) {
       Write-Host "    simmer: $Package"
            }
            else {
                Write-Host "    simmer: $Package $FlagText"
            }
        }
        else {

            . ".\scripts\$Manager.ps1"

            install $Package $Flags
        }
    }

    if ($null -ne $WindowsRecipe.install) {

        Invoke-Steps "cook" $WindowsRecipe.install
    }

    Invoke-Steps "season" $WindowsRecipe.post

    if ($null -ne $WindowsRecipe.validation) {

        foreach ($Command in $WindowsRecipe.validation) {

            if ($DryRun) {
                Write-Host "    taste: $Command"
            }
            else {
                Invoke-Step $Command
            }
        }
    }

    Write-Host ""
}
