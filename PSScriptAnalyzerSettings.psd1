@{
    ExcludeRules = @(
        # Intentional: user-facing output in interactive dev scripts
        'PSAvoidUsingWriteHost',
        # Intentional: $global:LASTEXITCODE = 0 before native exe calls to reset stale exit codes
        'PSAvoidGlobalVars',
        # Not useful for standalone repository maintenance scripts
        'PSAvoidUsingPositionalParameters',
        # These scripts use concise operational helper names, not exported cmdlets
        'PSUseSingularNouns',
        # Not applicable: these are standalone operational scripts, not reusable cmdlets
        'PSUseShouldProcessForStateChangingFunctions'
    )
}
