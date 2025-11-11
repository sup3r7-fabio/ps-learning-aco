# Start-LearningColony.ps1
# Initialize the PowerShell Learning ACO System

function Start-LearningColony {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ConfigurationPath = "$PSScriptRoot\..\Data\ACOConfig.json",
        
        [Parameter(Mandatory = $false)]
        [string]$DataPath = "$PSScriptRoot\..\Data",
        
        [Parameter(Mandatory = $false)]
        [switch]$Reset,
        
        [Parameter(Mandatory = $false)]
        [switch]$PassThru
    )
    
    begin {
        Write-Verbose "Initializing PowerShell Learning ACO System"
    }
    
    process {
        try {
            # Load configuration
            if (Test-Path $ConfigurationPath) {
                Write-Verbose "Loading configuration from: $ConfigurationPath"
                $configJson = Get-Content $ConfigurationPath -Raw | ConvertFrom-Json
                $config = @{}
                foreach ($property in $configJson.PSObject.Properties) {
                    $config[$property.Name] = $property.Value
                }
            } else {
                Write-Verbose "Using default ACO configuration"
                $config = @{
                    Alpha = 1.0                    # Pheromone importance
                    Beta = 2.0                     # Attractiveness importance
                    EvaporationRate = 0.1          # Pheromone evaporation
                    ReinforcementFactor = 1.0      # Pheromone reinforcement
                    MaxIterations = 100            # Max ACO iterations
                    ConvergenceThreshold = 0.01    # Convergence detection
                }
            }
            
            # Reset existing colony if requested
            if ($Reset -and $script:LearningColony) {
                Write-Verbose "Resetting existing learning colony"
                $script:LearningColony = $null
            }
            
            # Initialize the ant colony
            Write-Verbose "Creating new AntColony instance"
            $colony = [AntColony]::new($config, $DataPath)
            
            # Store in script scope for other functions to use
            $script:LearningColony = $colony
            
            # Display initialization results
            $stats = $colony.GetStatistics()
            Write-Host "✅ PowerShell Learning ACO Colony initialized successfully!" -ForegroundColor Green
            Write-Host "📊 Loaded $($stats.TotalModules) learning modules" -ForegroundColor Cyan
            Write-Host "🔗 Created $($stats.TotalPheromoneTrails) pheromone trails" -ForegroundColor Cyan
            Write-Host "🐜 Ready to optimize learning paths!" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "📋 Available modules:" -ForegroundColor White
            foreach ($moduleId in $colony.LearningGraph.Keys) {
                $module = $colony.LearningGraph[$moduleId]
                $difficulty = '★' * $module.Difficulty + '☆' * (5 - $module.Difficulty)
                Write-Host "   • $moduleId - $($module.Title) [$difficulty]" -ForegroundColor Gray
            }
            
            if ($PassThru) {
                return $colony
            }
        }
        catch {
            Write-Error "Failed to initialize Learning Colony: $($_.Exception.Message)"
            throw
        }
    }
}

# Create aliases
New-Alias -Name "Start-ACO" -Value "Start-LearningColony" -Force
