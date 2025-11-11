# Get-OptimalPath.ps1 (Simplified Version)
# Calculate optimal learning path using ACO algorithm

function Get-OptimalPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$LearnerId,
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 5)]
        [double]$SkillLevel = 2.0,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Visual', 'Auditory', 'Kinesthetic', 'Mixed', 'Practical', 'Theoretical')]
        [string]$LearningStyle = 'Mixed',
        
        [Parameter(Mandatory = $false)]
        [string]$StartModule = "PS-Basics",
        
        [Parameter(Mandatory = $false)]
        [string]$TargetModule = "PS-Advanced",
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 20)]
        [int]$MaxPathLength = 10,
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 100)]
        [int]$MaxIterations = 50,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeAnalytics,
        
        [Parameter(Mandatory = $false)]
        [switch]$Detailed
    )
    
    begin {
        if (-not $script:LearningColony) {
            throw "Learning Colony not initialized. Run Start-LearningColony first."
        }
        
        Write-Verbose "Calculating optimal learning path"
    }
    
    process {
        try {
            # Get or create learner
            $learner = $null
            if ($LearnerId) {
                $learner = $script:LearningColony.GetLearner($LearnerId)
                if ($learner) {
                    $SkillLevel = $learner.SkillLevel
                    $LearningStyle = $learner.LearningStyle
                }
            }
            
            if (-not $learner) {
                # Create temporary learner for path calculation
                $learner = [LearnerAnt]::new()
                $learner.LearnerId = "temp_" + [Guid]::NewGuid().ToString("N").Substring(0,8)
                $learner.SkillLevel = $SkillLevel
                $learner.LearningStyle = $LearningStyle
                if ($StartModule) {
                    $learner.CurrentModule = $StartModule
                }
            }
            
            # Find optimal path using ACO algorithm
            Write-Verbose "Running ACO algorithm for learner $($learner.LearnerId)"
            
            $optimalPath = $script:LearningColony.FindOptimalPath($learner, $TargetModule, $MaxIterations)
            
            if (-not $optimalPath -or $optimalPath.Count -eq 0) {
                Write-Warning "No optimal path found for the specified criteria"
                return $null
            }
            
            # Calculate path metrics
            $totalDifficulty = 0
            $totalTime = 0
            $pathModules = @()
            
            foreach ($moduleId in $optimalPath) {
                $module = $script:LearningColony.LearningGraph[$moduleId]
                if ($module) {
                    $totalDifficulty += $module.Difficulty
                    $totalTime += $module.EstimatedTime
                    
                    $pathModules += [PSCustomObject]@{
                        ModuleId = $moduleId
                        Title = $module.Title
                        Difficulty = $module.Difficulty
                        EstimatedTime = $module.EstimatedTime
                        Category = $module.Category
                        Prerequisites = $module.Prerequisites
                    }
                }
            }
            
            # Calculate path strength (average pheromone strength between modules)
            $pathStrength = 0.0
            if ($optimalPath.Count -gt 1) {
                $pheromoneSum = 0.0
                for ($i = 0; $i -lt ($optimalPath.Count - 1); $i++) {
                    $fromModule = $optimalPath[$i]
                    $toModule = $optimalPath[$i + 1]
                    $trailKey = "$fromModule->$toModule"
                    
                    if ($script:LearningColony.PheromoneTrails.ContainsKey($trailKey)) {
                        $pheromoneSum += $script:LearningColony.PheromoneTrails[$trailKey].GetTrailStrength()
                    }
                }
                $pathStrength = $pheromoneSum / ($optimalPath.Count - 1)
            }
            
            # Create result object
            $result = [PSCustomObject]@{
                OptimalPath = $optimalPath
                PathModules = $pathModules
                PathMetrics = @{
                    TotalModules = $optimalPath.Count
                    TotalDifficulty = $totalDifficulty
                    AverageDifficulty = [Math]::Round($totalDifficulty / $optimalPath.Count, 2)
                    TotalEstimatedTime = $totalTime
                    PathStrength = [Math]::Round($pathStrength, 4)
                }
                LearnerProfile = @{
                    SkillLevel = $SkillLevel
                    LearningStyle = $LearningStyle
                    LearnerId = $LearnerId
                }
                CalculatedAt = Get-Date
                Success = $true
            }
            
            # Add detailed analytics if requested
            if ($IncludeAnalytics) {
                $analytics = @{
                    PheromoneStrengths = @()
                    ModuleRecommendationScores = @()
                    AlgorithmParameters = $script:LearningColony.Configuration.ACOParameters
                }
                
                # Get pheromone strengths for path
                for ($i = 0; $i -lt ($optimalPath.Count - 1); $i++) {
                    $fromModule = $optimalPath[$i]
                    $toModule = $optimalPath[$i + 1]
                    $trailKey = "$fromModule->$toModule"
                    
                    if ($script:LearningColony.PheromoneTrails.ContainsKey($trailKey)) {
                        $trail = $script:LearningColony.PheromoneTrails[$trailKey]
                        $analytics.PheromoneStrengths += [PSCustomObject]@{
                            FromModule = $fromModule
                            ToModule = $toModule
                            PheromoneLevel = [Math]::Round($trail.PheromoneLevel, 4)
                            TrailStrength = [Math]::Round($trail.GetTrailStrength(), 4)
                            TraversalCount = $trail.TraversalCount
                            SuccessRate = [Math]::Round($trail.SuccessRate * 100, 1)
                        }
                    }
                }
                
                $result | Add-Member -MemberType NoteProperty -Name Analytics -Value $analytics
            }
            
            # Add detailed module information if requested
            if ($Detailed) {
                $detailedModules = @()
                foreach ($moduleId in $optimalPath) {
                    $module = $script:LearningColony.LearningGraph[$moduleId]
                    if ($module) {
                        $attractiveness = $script:LearningColony.CalculateAttractiveness($moduleId, $learner)
                        
                        $detailedModules += [PSCustomObject]@{
                            ModuleId = $moduleId
                            Title = $module.Title
                            Description = $module.Description
                            Difficulty = $module.Difficulty
                            EstimatedTime = $module.EstimatedTime
                            Category = $module.Category
                            Prerequisites = $module.Prerequisites
                            LearningObjectives = $module.LearningObjectives
                            Tags = $module.Tags
                            Attractiveness = [Math]::Round($attractiveness, 4)
                            StyleMatch = [Math]::Round($script:LearningColony.GetLearningStyleMatch($moduleId, $LearningStyle), 3)
                        }
                    }
                }
                $result.PathModules = $detailedModules
            }
            
            Write-Host "✅ Optimal path calculated: $($optimalPath.Count) modules, estimated time: $totalTime minutes" -ForegroundColor Green
            
            Write-Output $result
        }
        catch {
            Write-Error "Failed to calculate optimal path: $($_.Exception.Message)"
            throw
        }
    }
}

# Create aliases
New-Alias -Name "Get-Path" -Value "Get-OptimalPath" -Force
