function Install-Package {
    param(
        [string]$Package
    )

    winget install --id $Package --silent --accept-package-agreements --accept-source-agreements
}

function Test-Package {
    param(
        [string]$Command
    )

    Invoke-Expression $Command
}
