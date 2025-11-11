# Get-LearningAnalytics.ps1
# Generate analytics and insights from the ACO learning system

function Get-LearningAnalytics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$LearnerId,
        
        [Parameter(Mandatory = $false)]
        [string]$ModuleId,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Overview', 'Performance', 'Pheromones', 'Paths', 'Recommendations', 'Trends')]
        [string]$AnalysisType = 'Overview',
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 100)]
        [int]$TopN = 10,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeVisualization
    )
    
    begin {
        if (-not $script:LearningColony) {
            throw "Learning Colony not initialized. Run Start-LearningColony first."
        }
        
        Write-Verbose "Generating learning analytics: $AnalysisType"
    }
    
    process {
        try {
            $analytics = @{}
            $timestamp = Get-Date
            
            switch ($AnalysisType) {
                'Overview' {
                    Write-Verbose "Generating overview analytics"
                    
                    $analytics = @{
                        SystemOverview = @{
                            TotalLearners = $script:LearningColony.Learners.Count
                            TotalModules = $script:LearningColony.LearningGraph.Count
                            TotalPheromoneTrails = $script:LearningColony.PheromoneTrails.Count
                            AverageSkillLevel = if ($script:LearningColony.Learners.Count -gt 0) {
                                [Math]::Round(($script:LearningColony.Learners | Measure-Object -Property SkillLevel -Average).Average, 2)
                            } else { 0 }
                            SystemStatistics = $script:LearningColony.GetStatistics()
                        }
                        
                        MostPopularModules = $script:LearningColony.Learners | 
                            ForEach-Object { $_.CompletedModules } | 
                            Group-Object | 
                            Sort-Object Count -Descending | 
                            Select-Object -First $TopN @{Name='ModuleId';Expression={$_.Name}}, 
                                                         @{Name='CompletionsCount';Expression={$_.Count}},
                                                         @{Name='PopularityPercentage';Expression={[Math]::Round(($_.Count / $script:LearningColony.Learners.Count) * 100, 1)}}
                        
                        StrongestPheromoneTrails = $script:LearningColony.PheromoneTrails.Values | 
                            Sort-Object PheromoneLevel -Descending | 
                            Select-Object -First $TopN FromModule, ToModule, 
                                                       @{Name='PheromoneStrength';Expression={[Math]::Round($_.PheromoneLevel, 3)}},
                                                       @{Name='SuccessRate';Expression={[Math]::Round($_.SuccessRate * 100, 1)}},
                                                       @{Name='TraversalCount';Expression={$_.TraversalCount}},
                                                       LastUpdated
                        
                        LearnerDistribution = @{
                            BySkillLevel = $script:LearningColony.Learners | 
                                Group-Object { [Math]::Floor($_.SkillLevel) } | 
                                Sort-Object Name | 
                                ForEach-Object {
                                    [PSCustomObject]@{
                                        SkillLevelRange = "$($_.Name)-$([int]$_.Name + 1)"
                                        LearnerCount = $_.Count
                                        Percentage = [Math]::Round(($_.Count / $script:LearningColony.Learners.Count) * 100, 1)
                                    }
                                }
                            
                            ByLearningStyle = $script:LearningColony.Learners | 
                                Group-Object LearningStyle | 
                                Sort-Object Count -Descending | 
                                ForEach-Object {
                                    [PSCustomObject]@{
                                        LearningStyle = $_.Name
                                        LearnerCount = $_.Count
                                        Percentage = [Math]::Round(($_.Count / $script:LearningColony.Learners.Count) * 100, 1)
                                    }
                                }
                        }
                        
                        GeneratedAt = $timestamp
                    }
                }
                
                'Performance' {
                    Write-Verbose "Generating performance analytics"
                    
                    $allPerformance = $script:LearningColony.Learners | ForEach-Object { 
                        if ($_.PerformanceHistory -is [System.Collections.Generic.List[hashtable]]) {
                            $_.PerformanceHistory.ToArray()
                        } else {
                            @()
                        }
                    }
                    
                    # Filter by learner if specified
                    if ($LearnerId) {
                        $learner = $script:LearningColony.GetLearner($LearnerId)
                        if ($learner) {
                            $allPerformance = $learner.PerformanceHistory.ToArray()
                        } else {
                            throw "Learner '$LearnerId' not found"
                        }
                    }
                    
                    # Filter by module if specified
                    if ($ModuleId) {
                        $allPerformance = $allPerformance | Where-Object { $_.ModuleId -eq $ModuleId }
                    }
                    
                    $analytics = @{
                        OverallPerformance = @{
                            TotalAttempts = $allPerformance.Count
                            AverageScore = if ($allPerformance.Count -gt 0) {
                                [Math]::Round(($allPerformance | Measure-Object -Property Score -Average).Average, 2)
                            } else { 0 }
                            SuccessRate = if ($allPerformance.Count -gt 0) {
                                [Math]::Round((($allPerformance | Where-Object Success | Measure-Object).Count / $allPerformance.Count) * 100, 1)
                            } else { 0 }
                            AverageCompletionTime = if ($allPerformance.Count -gt 0) {
                                [Math]::Round(($allPerformance | Measure-Object -Property CompletionTime -Average).Average, 1)
                            } else { 0 }
                        }
                        
                        ModulePerformance = $allPerformance | 
                            Group-Object ModuleId | 
                            Sort-Object { ($_.Group | Measure-Object -Property Score -Average).Average } | 
                            Select-Object -First $TopN | 
                            ForEach-Object {
                                $moduleData = $_.Group
                                [PSCustomObject]@{
                                    ModuleId = $_.Name
                                    ModuleTitle = if ($script:LearningColony.LearningGraph.ContainsKey($_.Name)) { 
                                        $script:LearningColony.LearningGraph[$_.Name].Title 
                                    } else { "Unknown" }
                                    AttemptCount = $moduleData.Count
                                    AverageScore = [Math]::Round(($moduleData | Measure-Object -Property Score -Average).Average, 2)
                                    SuccessRate = [Math]::Round((($moduleData | Where-Object Success | Measure-Object).Count / $moduleData.Count) * 100, 1)
                                    AverageTime = [Math]::Round(($moduleData | Measure-Object -Property CompletionTime -Average).Average, 1)
                                    Difficulty = if ($script:LearningColony.LearningGraph.ContainsKey($_.Name)) { 
                                        $script:LearningColony.LearningGraph[$_.Name].Difficulty 
                                    } else { 0 }
                                }
                            }
                        
                        ScoreDistribution = $allPerformance | 
                            Group-Object { [Math]::Floor($_.Score / 10) * 10 } | 
                            Sort-Object Name | 
                            ForEach-Object {
                                [PSCustomObject]@{
                                    ScoreRange = "$($_.Name)-$([int]$_.Name + 9)%"
                                    AttemptCount = $_.Count
                                    Percentage = [Math]::Round(($_.Count / $allPerformance.Count) * 100, 1)
                                }
                            }
                        
                        GeneratedAt = $timestamp
                        FilteredBy = @{
                            LearnerId = $LearnerId
                            ModuleId = $ModuleId
                        }
                    }
                }
                
                'Pheromones' {
                    Write-Verbose "Generating pheromone analytics"
                    
                    $analytics = @{
                        PheromoneStatistics = @{
                            TotalTrails = $script:LearningColony.PheromoneTrails.Count
                            ActiveTrails = ($script:LearningColony.PheromoneTrails.Values | Where-Object { $_.TraversalCount -gt 0 }).Count
                            AveragePheromoneLevel = [Math]::Round(($script:LearningColony.PheromoneTrails.Values | Measure-Object -Property PheromoneLevel -Average).Average, 4)
                            MaxPheromoneLevel = [Math]::Round(($script:LearningColony.PheromoneTrails.Values | Measure-Object -Property PheromoneLevel -Maximum).Maximum, 4)
                            MinPheromoneLevel = [Math]::Round(($script:LearningColony.PheromoneTrails.Values | Measure-Object -Property PheromoneLevel -Minimum).Minimum, 4)
                        }
                        
                        StrongestTrails = $script:LearningColony.PheromoneTrails.Values | 
                            Where-Object { $_.TraversalCount -gt 0 } |
                            Sort-Object TrailStrength -Descending | 
                            Select-Object -First $TopN FromModule, ToModule, 
                                                       @{Name='PheromoneLevel';Expression={[Math]::Round($_.PheromoneLevel, 4)}},
                                                       @{Name='TrailStrength';Expression={[Math]::Round($_.GetTrailStrength(), 4)}},
                                                       @{Name='SuccessRate';Expression={[Math]::Round($_.SuccessRate * 100, 1)}},
                                                       TraversalCount, LastUpdated
                        
                        WeakestTrails = $script:LearningColony.PheromoneTrails.Values | 
                            Sort-Object PheromoneLevel | 
                            Select-Object -First $TopN FromModule, ToModule, 
                                                       @{Name='PheromoneLevel';Expression={[Math]::Round($_.PheromoneLevel, 4)}},
                                                       @{Name='SuccessRate';Expression={[Math]::Round($_.SuccessRate * 100, 1)}},
                                                       TraversalCount, LastUpdated
                        
                        PheromoneDistribution = $script:LearningColony.PheromoneTrails.Values | 
                            Group-Object { [Math]::Floor($_.PheromoneLevel * 10) / 10 } | 
                            Sort-Object Name | 
                            ForEach-Object {
                                [PSCustomObject]@{
                                    PheromoneRange = "$($_.Name) - $([double]$_.Name + 0.1)"
                                    TrailCount = $_.Count
                                    Percentage = [Math]::Round(($_.Count / $script:LearningColony.PheromoneTrails.Count) * 100, 1)
                                }
                            }
                        
                        GeneratedAt = $timestamp
                    }
                }
                
                'Recommendations' {
                    Write-Verbose "Generating recommendation analytics"
                    
                    if (-not $LearnerId) {
                        throw "LearnerId is required for recommendation analytics"
                    }
                    
                    $learner = $script:LearningColony.GetLearner($LearnerId)
                    if (-not $learner) {
                        throw "Learner '$LearnerId' not found"
                    }
                    
                    $availableModules = $learner.GetAvailableModules($script:LearningColony.LearningGraph)
                    $recommendations = @()
                    
                    foreach ($moduleId in $availableModules) {
                        $attractiveness = $script:LearningColony.CalculateAttractiveness($moduleId, $learner)
                        $module = $script:LearningColony.LearningGraph[$moduleId]
                        
                        $recommendations += [PSCustomObject]@{
                            ModuleId = $moduleId
                            Title = $module.Title
                            Attractiveness = [Math]::Round($attractiveness, 3)
                            Difficulty = $module.Difficulty
                            EstimatedTime = $module.EstimatedTime
                            SkillAlignment = [Math]::Round((1.0 - [Math]::Abs($module.Difficulty - $learner.SkillLevel) / 5.0), 3)
                            StyleMatch = [Math]::Round($script:LearningColony.GetLearningStyleMatch($moduleId, $learner.LearningStyle), 3)
                            Prerequisites = $module.Prerequisites
                            Tags = $module.Tags
                        }
                    }
                    
                    $analytics = @{
                        LearnerProfile = @{
                            LearnerId = $learner.LearnerId
                            SkillLevel = $learner.SkillLevel
                            LearningStyle = $learner.LearningStyle
                            CompletedModules = $learner.CompletedModules.Count
                            AverageScore = [Math]::Round($learner.GetAverageScore(), 2)
                            SuccessRate = [Math]::Round($learner.GetSuccessRate() * 100, 1)
                            RecommendedDifficulty = $learner.GetRecommendedDifficulty()
                        }
                        
                        TopRecommendations = $recommendations | 
                            Sort-Object Attractiveness -Descending | 
                            Select-Object -First $TopN
                        
                        SkillProgressionPath = $recommendations | 
                            Where-Object { $_.Difficulty -le ($learner.SkillLevel + 1) } |
                            Sort-Object Difficulty, Attractiveness -Descending |
                            Select-Object -First 5
                        
                        GeneratedAt = $timestamp
                    }
                }
            }
            
            $result = [PSCustomObject]$analytics
            
            # Add visualization if requested
            if ($IncludeVisualization) {
                Write-Verbose "Adding visualization data"
                $visualization = @{
                    Type = $AnalysisType
                    GeneratedAt = Get-Date
                    Charts = @{
                        Note = "Visualization data prepared for external tools"
                    }
                }
                $result | Add-Member -MemberType NoteProperty -Name Visualization -Value $visualization
            }
            
            Write-Output $result
        }
        catch {
            Write-Error "Failed to generate learning analytics: $($_.Exception.Message)"
            throw
        }
    }
    
}

# Create aliases
New-Alias -Name "Get-Analytics" -Value "Get-LearningAnalytics" -Force
