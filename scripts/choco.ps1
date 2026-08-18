function Install-Package {
    param(
        [String]$Package
    )

    choco install $Package -y
}

function Test-Package {
    param(
        [String]$Command
    )

    Invoke-Expression $Command
}
