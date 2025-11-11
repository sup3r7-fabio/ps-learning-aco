# AntColony Class for PSLearningACO
# Main engine for the Ant Colony Optimization learning system

class AntColony {
    [hashtable]$Configuration
    [hashtable]$LearningGraph
    [System.Collections.Generic.Dictionary[string, PheromoneTrail]]$PheromoneTrails
    [System.Collections.Generic.List[LearnerAnt]]$Learners
    [string]$DataPath
    [datetime]$CreatedAt
    [datetime]$LastUpdated
    [hashtable]$Statistics
    
    # Default constructor
    AntColony() {
        $this.Configuration = @{}
        $this.LearningGraph = @{}
        $this.PheromoneTrails = [System.Collections.Generic.Dictionary[string, PheromoneTrail]]::new()
        $this.Learners = [System.Collections.Generic.List[LearnerAnt]]::new()
        $this.CreatedAt = Get-Date
        $this.LastUpdated = Get-Date
        $this.Statistics = @{
            TotalPathsGenerated = 0
            TotalLearningEvents = 0
            OptimizationRuns = 0
        }
    }
    
    # Constructor with configuration and data path
    AntColony([hashtable]$config, [string]$dataPath) {
        $this.Configuration = $config
        $this.DataPath = $dataPath
        $this.LearningGraph = @{}
        $this.PheromoneTrails = [System.Collections.Generic.Dictionary[string, PheromoneTrail]]::new()
        $this.Learners = [System.Collections.Generic.List[LearnerAnt]]::new()
        $this.CreatedAt = Get-Date
        $this.LastUpdated = Get-Date
        $this.Statistics = @{
            TotalPathsGenerated = 0
            TotalLearningEvents = 0
            OptimizationRuns = 0
        }
        
        $this.InitializeLearningGraph()
        $this.InitializePheromoneTrails()
    }
    
    # Initialize the learning graph from data files
    [void] InitializeLearningGraph() {
        $defaultModulesPath = Join-Path $this.DataPath "DefaultModules.json"
        if (Test-Path $defaultModulesPath) {
            try {
                $jsonContent = Get-Content $defaultModulesPath -Raw | ConvertFrom-Json
                $this.LearningGraph = @{}
                foreach ($property in $jsonContent.PSObject.Properties) {
                    $this.LearningGraph[$property.Name] = @{}
                    foreach ($moduleProperty in $property.Value.PSObject.Properties) {
                        $this.LearningGraph[$property.Name][$moduleProperty.Name] = $moduleProperty.Value
                    }
                }
            }
            catch {
                Write-Warning "Failed to load modules from $defaultModulesPath. Using default modules."
                $this.CreateDefaultLearningGraph()
            }
        } else {
            $this.CreateDefaultLearningGraph()
        }
    }
    
    # Create default learning modules
    [void] CreateDefaultLearningGraph() {
        $this.LearningGraph = @{
            'PS-Basics' = @{
                Title = 'PowerShell Basics'
                Prerequisites = @()
                Difficulty = 1
                EstimatedTime = 30
                LearningObjectives = @('Variables', 'Basic Commands', 'Help System')
                Tags = @('Beginner', 'Foundation')
            }
            'PS-Objects' = @{
                Title = 'Working with Objects'
                Prerequisites = @('PS-Basics')
                Difficulty = 2
                EstimatedTime = 45
                LearningObjectives = @('Object Properties', 'Methods', 'Pipeline')
                Tags = @('Intermediate', 'Objects')
            }
            'PS-Functions' = @{
                Title = 'PowerShell Functions'
                Prerequisites = @('PS-Objects')
                Difficulty = 3
                EstimatedTime = 60
                LearningObjectives = @('Function Creation', 'Parameters', 'Return Values')
                Tags = @('Intermediate', 'Functions')
            }
            'PS-Modules' = @{
                Title = 'PowerShell Modules'
                Prerequisites = @('PS-Functions')
                Difficulty = 4
                EstimatedTime = 90
                LearningObjectives = @('Module Structure', 'Import/Export', 'Publishing')
                Tags = @('Advanced', 'Modules')
            }
            'PS-Advanced' = @{
                Title = 'Advanced PowerShell'
                Prerequisites = @('PS-Modules')
                Difficulty = 5
                EstimatedTime = 120
                LearningObjectives = @('Classes', 'DSC', 'Workflows')
                Tags = @('Advanced', 'Expert')
            }
            'PS-Scripting' = @{
                Title = 'PowerShell Scripting'
                Prerequisites = @('PS-Functions')
                Difficulty = 3
                EstimatedTime = 75
                LearningObjectives = @('Script Structure', 'Error Handling', 'Best Practices')
                Tags = @('Intermediate', 'Scripting')
            }
            'PS-Remoting' = @{
                Title = 'PowerShell Remoting'
                Prerequisites = @('PS-Advanced')
                Difficulty = 4
                EstimatedTime = 60
                LearningObjectives = @('Remote Sessions', 'Security', 'Workflows')
                Tags = @('Advanced', 'Remoting')
            }
            'PS-Security' = @{
                Title = 'PowerShell Security'
                Prerequisites = @('PS-Scripting')
                Difficulty = 4
                EstimatedTime = 90
                LearningObjectives = @('Execution Policies', 'Code Signing', 'Constrained Language')
                Tags = @('Advanced', 'Security')
            }
        }
    }
    
    # Initialize pheromone trails between all module pairs
    [void] InitializePheromoneTrails() {
        foreach ($fromModule in $this.LearningGraph.Keys) {
            foreach ($toModule in $this.LearningGraph.Keys) {
                if ($fromModule -ne $toModule) {
                    $trailKey = "$fromModule->$toModule"
                    if (-not $this.PheromoneTrails.ContainsKey($trailKey)) {
                        $trail = [PheromoneTrail]::new($fromModule, $toModule)
                        $trail.Difficulty = $this.LearningGraph[$toModule].Difficulty
                        $this.PheromoneTrails[$trailKey] = $trail
                    }
                }
            }
        }
    }
    
    # Find optimal learning path using ACO algorithm
    [string[]] FindOptimalPath([LearnerAnt]$learner, [string]$targetModule, [int]$maxIterations) {
        $bestPath = @()
        $bestScore = 0.0
        $this.Statistics.OptimizationRuns++
        
        Write-Verbose "Starting ACO optimization for learner $($learner.LearnerId) targeting $targetModule"
        
        for ($iteration = 0; $iteration -lt $maxIterations; $iteration++) {
            try {
                $currentPath = $this.ConstructPath($learner, $targetModule)
                if ($currentPath.Count -gt 0) {
                    $pathScore = $this.EvaluatePath($currentPath, $learner)
                    
                    if ($pathScore -gt $bestScore) {
                        $bestScore = $pathScore
                        $bestPath = $currentPath
                        Write-Verbose "New best path found at iteration $iteration with score $bestScore"
                    }
                    
                    # Update pheromones based on path quality
                    $this.UpdatePheromoneTrailsForPath($currentPath, $pathScore)
                }
            }
            catch {
                Write-Warning "Error in ACO iteration $iteration : $($_.Exception.Message)"
            }
        }
        
        $this.Statistics.TotalPathsGenerated++
        $this.LastUpdated = Get-Date
        
        Write-Verbose "ACO optimization completed. Best path: $($bestPath -join ' → ')"
        return $bestPath
    }
    
    # Construct a single path using pheromone-guided selection
    [string[]] ConstructPath([LearnerAnt]$learner, [string]$targetModule) {
        $path = @()
        $currentModule = if ($learner.CurrentModule) { $learner.CurrentModule } else { $targetModule }
        $visited = @($learner.CompletedModules)
        $maxPathLength = 10  # Prevent infinite loops
        
        # If learner is already at target or has completed it, return empty path
        if ($currentModule -eq $targetModule -or $targetModule -in $learner.CompletedModules) {
            return @()
        }
        
        while ($currentModule -ne $targetModule -and $path.Count -lt $maxPathLength) {
            $availableModules = @($learner.GetAvailableModules($this.LearningGraph) | 
                Where-Object { $_ -notin $visited })
            
            if ($availableModules.Count -eq 0) { 
                Write-Verbose "No available modules found, breaking path construction"
                break 
            }
            
            $nextModule = $this.SelectNextModule($currentModule, $availableModules, $learner)
            if (-not $nextModule) {
                Write-Verbose "No next module selected, breaking path construction"
                break
            }
            
            $path += $nextModule
            $visited += $nextModule
            $currentModule = $nextModule
            
            # If we've reached the target, we're done
            if ($currentModule -eq $targetModule) {
                break
            }
        }
        
        return $path
    }
    
    # Select next module using ACO probability calculation
    [string] SelectNextModule([string]$currentModule, [string[]]$availableModules, [LearnerAnt]$learner) {
        if ($availableModules.Count -eq 0) {
            return $null
        }
        
        if ($availableModules.Count -eq 1) {
            return $availableModules[0]
        }
        
        $probabilities = @{}
        $totalWeight = 0.0
        
        foreach ($module in @($availableModules)) {
            $trailKey = "$currentModule->$module"
            $pheromone = 0.5  # Default pheromone level
            
            if ($this.PheromoneTrails.ContainsKey($trailKey)) {
                $pheromone = $this.PheromoneTrails[$trailKey].PheromoneLevel
            }
            
            $attractiveness = $this.CalculateAttractiveness($module, $learner)
            
            # ACO probability calculation with configuration parameters
            $alpha = $this.Configuration.Alpha  # Pheromone importance
            $beta = $this.Configuration.Beta    # Attractiveness importance
            
            $weight = [Math]::Pow($pheromone, $alpha) * [Math]::Pow($attractiveness, $beta)
            $probabilities[$module] = $weight
            $totalWeight += $weight
        }
        
        if ($totalWeight -eq 0) {
            # Fallback: random selection
            return $availableModules[(Get-Random -Maximum $availableModules.Count)]
        }
        
        # Normalize probabilities
        $keys = @($probabilities.Keys)
        foreach ($module in $keys) {
            $probabilities[$module] /= $totalWeight
        }
        
        # Roulette wheel selection
        return $this.RouletteWheelSelection($probabilities)
    }
    
    # Calculate attractiveness of a module for a learner
    [double] CalculateAttractiveness([string]$moduleId, [LearnerAnt]$learner) {
        if (-not $this.LearningGraph.ContainsKey($moduleId)) { return 0.1 }
        
        $module = $this.LearningGraph[$moduleId]
        
        # Skill level matching (prefer modules close to learner's skill level)
        $skillDifference = [Math]::Abs($module.Difficulty - $learner.SkillLevel)
        $skillMatch = [Math]::Max(0.1, 1.0 - ($skillDifference / 5.0))
        
        # Learning style preference
        $styleMatch = $this.GetLearningStyleMatch($moduleId, $learner.LearningStyle)
        
        # Time preference (consider learner's preferred session length)
        $timePreference = 1.0
        if ($learner.Preferences.ContainsKey('MaxSessionTime')) {
            $maxTime = $learner.Preferences.MaxSessionTime
            if ($module.EstimatedTime -le $maxTime) {
                $timePreference = 1.2  # Bonus for fitting in session
            } else {
                $timePreference = 0.8  # Penalty for exceeding session time
            }
        }
        
        # Recent performance influence
        $performanceModifier = 1.0
        $recentPerformance = $learner.PerformanceHistory | 
            Sort-Object { $_.Timestamp } | 
            Select-Object -Last 3
        
        if ($recentPerformance.Count -gt 0) {
            $avgRecentScore = ($recentPerformance | Measure-Object -Property Score -Average).Average
            if ($avgRecentScore -gt 80) {
                $performanceModifier = 1.1  # Confident learner, can handle more
            } elseif ($avgRecentScore -lt 60) {
                $performanceModifier = 0.9  # Struggling learner, prefer easier content
            }
        }
        
        # Combine all factors
        return ($skillMatch * 0.4) + ($styleMatch * 0.2) + ($timePreference * 0.2) + ($performanceModifier * 0.2)
    }
    
    # Get learning style match score
    [double] GetLearningStyleMatch([string]$moduleId, [string]$learningStyle) {
        if (-not $this.LearningGraph.ContainsKey($moduleId)) { 
            return 0.5 
        }
        
        $module = $this.LearningGraph[$moduleId]
        
        # Simple heuristic based on module characteristics
        switch ($learningStyle) {
            'Visual' {
                # Prefer modules with diagrams, visual content
                if ($module.Tags -contains 'Visual' -or $module.Title -match 'GUI|Interface|Design') {
                    return 1.2
                }
                return 0.8
            }
            'Practical' {
                # Prefer hands-on modules
                if ($module.Tags -contains 'HandsOn' -or $module.Title -match 'Practice|Lab|Exercise') {
                    return 1.3
                }
                if ($module.Title -match 'Theory|Concept') {
                    return 0.7
                }
                return 1.0
            }
            'Theoretical' {
                # Prefer conceptual modules
                if ($module.Tags -contains 'Theory' -or $module.Title -match 'Concept|Architecture|Design') {
                    return 1.2
                }
                if ($module.Title -match 'Practice|Lab') {
                    return 0.8
                }
                return 1.0
            }
            'Mixed' {
                return 1.0  # Neutral preference
            }
            default {
                return 0.9
            }
        }
        
        # Fallback return (this should never be reached)
        return 0.9
    }
    
    # Roulette wheel selection algorithm
    [string] RouletteWheelSelection([hashtable]$probabilities) {
        $random = Get-Random -Minimum 0.0 -Maximum 1.0
        $cumulativeProbability = 0.0
        
        foreach ($module in $probabilities.Keys) {
            $cumulativeProbability += $probabilities[$module]
            if ($random -le $cumulativeProbability) {
                return $module
            }
        }
        
        # Fallback to first available module
        return $probabilities.Keys | Select-Object -First 1
    }
    
    # Evaluate the quality of a learning path
    [double] EvaluatePath([string[]]$path, [LearnerAnt]$learner) {
        if ($path.Count -eq 0) { return 0.0 }
        
        $score = 0.0
        $currentSkill = $learner.SkillLevel
        
        foreach ($moduleId in $path) {
            if ($this.LearningGraph.ContainsKey($moduleId)) {
                $module = $this.LearningGraph[$moduleId]
                
                # Skill progression score
                $skillDiff = [Math]::Abs($module.Difficulty - $currentSkill)
                $skillScore = [Math]::Max(0.1, 1.0 - ($skillDiff / 5.0))
                
                # Path efficiency (shorter is better, but not too short)
                $efficiencyScore = 1.0 / (1.0 + ($path.Count * 0.1))
                
                # Prerequisite satisfaction
                $prereqScore = 1.0
                if ($module.Prerequisites) {
                    $satisfiedPrereqs = 0
                    foreach ($prereq in $module.Prerequisites) {
                        if ($prereq -in $learner.CompletedModules) {
                            $satisfiedPrereqs++
                        }
                    }
                    $prereqScore = $satisfiedPrereqs / $module.Prerequisites.Count
                }
                
                $moduleScore = ($skillScore * 0.5) + ($efficiencyScore * 0.2) + ($prereqScore * 0.3)
                $score += $moduleScore
                
                # Update current skill for next iteration
                $currentSkill = [Math]::Min($currentSkill + 0.2, 10.0)
            }
        }
        
        return $score / $path.Count  # Average score per module
    }
    
    # Update pheromone trails based on path performance
    [void] UpdatePheromoneTrailsForPath([string[]]$path, [double]$pathQuality) {
        if ($path.Count -lt 2) { return }
        
        # Apply evaporation to all trails (create copy to avoid enumeration issues)
        $evaporationRate = $this.Configuration.EvaporationRate
        $trailsToEvaporate = $this.PheromoneTrails.Values.ToArray()
        foreach ($trail in $trailsToEvaporate) {
            $trail.Evaporate($evaporationRate)
        }
        
        # Apply reinforcement to trails in the path
        $reinforcement = $pathQuality * $this.Configuration.ReinforcementFactor
        
        for ($i = 0; $i -lt ($path.Count - 1); $i++) {
            $trailKey = "$($path[$i])->$($path[$i + 1])"
            if ($this.PheromoneTrails.ContainsKey($trailKey)) {
                $this.PheromoneTrails[$trailKey].UpdatePheromone($reinforcement)
            }
        }
        
        $this.LastUpdated = Get-Date
    }
    
    # Add or update a learner in the colony
    [void] AddLearner([LearnerAnt]$learner) {
        # Remove existing learner with same ID
        $existingIndex = -1
        for ($i = 0; $i -lt $this.Learners.Count; $i++) {
            if ($this.Learners[$i].LearnerId -eq $learner.LearnerId) {
                $existingIndex = $i
                break
            }
        }
        
        if ($existingIndex -ge 0) {
            $this.Learners[$existingIndex] = $learner
        } else {
            $this.Learners.Add($learner)
        }
        
        $this.LastUpdated = Get-Date
    }
    
    # Get learner by ID
    [LearnerAnt] GetLearner([string]$learnerId) {
        foreach ($learner in $this.Learners) {
            if ($learner.LearnerId -eq $learnerId) {
                return $learner
            }
        }
        return $null
    }
    
    # Record learning event and update pheromones
    [void] RecordLearningEvent([string]$learnerId, [string]$fromModule, [string]$toModule, [double]$score, [int]$completionTime, [bool]$success) {
        $trailKey = "$fromModule->$toModule"
        if ($this.PheromoneTrails.ContainsKey($trailKey)) {
            $this.PheromoneTrails[$trailKey].RecordTraversal($score, $completionTime, $success)
        }
        
        $this.Statistics.TotalLearningEvents++
        $this.LastUpdated = Get-Date
    }
    
    # Get colony statistics
    [hashtable] GetStatistics() {
        $totalPheromone = 0.0
        foreach ($trail in $this.PheromoneTrails.Values) {
            $totalPheromone += ($trail.PheromoneLevel ?? 0.0)
        }
        $averagePheromone = if ($this.PheromoneTrails.Count -gt 0) { 
            $totalPheromone / $this.PheromoneTrails.Count 
        } else { 0 }
        
        $activeTrails = ($this.PheromoneTrails.Values | Where-Object { $_.TraversalCount -gt 0 }).Count
        
        $this.Statistics.TotalLearners = $this.Learners.Count
        $this.Statistics.TotalModules = $this.LearningGraph.Count
        $this.Statistics.TotalPheromoneTrails = $this.PheromoneTrails.Count
        $this.Statistics.ActiveTrails = $activeTrails
        $this.Statistics.AveragePheromoneLevel = $averagePheromone
        $this.Statistics.LastUpdated = $this.LastUpdated
        
        return $this.Statistics
    }
    
    # Export colony data for persistence
    [PSCustomObject] ExportData() {
        return [PSCustomObject]@{
            Configuration = $this.Configuration
            LearningGraph = $this.LearningGraph
            PheromoneTrails = $this.PheromoneTrails.Values | ForEach-Object { $_.ToHashtable() }
            Learners = $this.Learners | ForEach-Object { $_.ToHashtable() }
            Statistics = $this.GetStatistics()
            CreatedAt = $this.CreatedAt.ToString('o')
            LastUpdated = $this.LastUpdated.ToString('o')
        }
    }
    
    # String representation for debugging
    [string] ToString() {
        return "AntColony: $($this.Learners.Count) learners, $($this.LearningGraph.Count) modules, $($this.PheromoneTrails.Count) trails"
    }
}
