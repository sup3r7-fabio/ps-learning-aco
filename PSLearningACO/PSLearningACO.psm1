# PSLearningACO.psm1
# Root module file for PowerShell Learning ACO System

#Requires -Version 5.1

# Module initialization
Write-Verbose "Loading PSLearningACO module..."

# Script-scoped variables
$script:LearningColony = $null
$script:ModuleRoot = $PSScriptRoot

# Import classes first (order matters for dependencies)
Write-Verbose "Loading PowerShell classes..."

try {
    # Load classes in dependency order
    . "$PSScriptRoot\Classes\PheromoneTrail.ps1"
    . "$PSScriptRoot\Classes\LearnerAnt.ps1"
    . "$PSScriptRoot\Classes\AntColony.ps1"
    
    Write-Verbose "Successfully loaded all PowerShell classes"
}
catch {
    Write-Error "Failed to load PowerShell classes: $($_.Exception.Message)"
    throw
}

# Import private functions
Write-Verbose "Loading private functions..."

$PrivateFunctions = @()
$PrivateFiles = Get-ChildItem -Path "$PSScriptRoot\Private" -Filter "*.ps1" -ErrorAction SilentlyContinue

foreach ($PrivateFile in $PrivateFiles) {
    try {
        . $PrivateFile.FullName
        $PrivateFunctions += $PrivateFile.BaseName
        Write-Verbose "Loaded private function: $($PrivateFile.BaseName)"
    }
    catch {
        Write-Warning "Failed to load private function $($PrivateFile.Name): $($_.Exception.Message)"
    }
}

Write-Verbose "Loaded $($PrivateFunctions.Count) private functions"

# Import public functions
Write-Verbose "Loading public functions..."

$PublicFunctions = @()
$PublicFiles = Get-ChildItem -Path "$PSScriptRoot\Public" -Filter "*.ps1" -ErrorAction SilentlyContinue

foreach ($PublicFile in $PublicFiles) {
    try {
        . $PublicFile.FullName
        $PublicFunctions += $PublicFile.BaseName
        Write-Verbose "Loaded public function: $($PublicFile.BaseName)"
    }
    catch {
        Write-Error "Failed to load public function $($PublicFile.Name): $($_.Exception.Message)"
        throw
    }
}

Write-Verbose "Loaded $($PublicFunctions.Count) public functions: $($PublicFunctions -join ', ')"

# Export only public functions
if ($PublicFunctions.Count -gt 0) {
    Export-ModuleMember -Function $PublicFunctions
}

# Module cleanup when removed
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    Write-Verbose "Cleaning up PSLearningACO module..."
    
    # Clear script variables
    $script:LearningColony = $null
    
    # Remove any custom types if added
    # (Future enhancement: cleanup custom types)
    
    Write-Verbose "PSLearningACO module cleanup completed"
}

# Display module loaded message
Write-Host ""
Write-Host "🐜 PSLearningACO Module Loaded Successfully!" -ForegroundColor Green
Write-Host "══════════════════════════════════════════" -ForegroundColor Green
Write-Host "📚 Ant Colony Optimization for PowerShell Learning" -ForegroundColor Cyan
Write-Host ""
Write-Host "Available Commands:" -ForegroundColor White
Write-Host "  • Start-LearningColony   - Initialize the ACO system" -ForegroundColor Gray
Write-Host "  • Get-OptimalPath        - Find optimal learning paths" -ForegroundColor Gray
Write-Host "  • Add-LearnerProgress    - Record learning performance" -ForegroundColor Gray
Write-Host "  • Get-LearningAnalytics  - View analytics and insights" -ForegroundColor Gray
Write-Host "  • Export-LearningGraph   - Export learning data" -ForegroundColor Gray
Write-Host "  • Get-ModuleContent      - Load lesson/exercise/quiz/solutions" -ForegroundColor Gray
Write-Host ""
Write-Host "Quick Start: Start-LearningColony" -ForegroundColor Yellow
Write-Host "Get Help: Get-Help Start-LearningColony -Examples" -ForegroundColor Yellow
Write-Host "Content Repo: https://github.com/sup3r7-fabio/ps-learning-aco-content" -ForegroundColor Yellow
Write-Host ""
