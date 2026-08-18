function Install-Package {
    param(
        [String]$Command
    )

    Invoke-Expression $Command
}

function Test-Package {
    param(
        [String]$Command
    )

    Invoke-Expression $Command
}
