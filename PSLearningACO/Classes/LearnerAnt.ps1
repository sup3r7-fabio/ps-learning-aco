# LearnerAnt Class for PSLearningACO
# Represents an individual learner navigating through the learning modules

class LearnerAnt {
    [string]$LearnerId
    [string]$CurrentModule
    [int]$SkillLevel  # 1-10 scale
    [ValidateSet('Visual', 'Practical', 'Theoretical', 'Mixed')]
    [string]$LearningStyle
    [string[]]$CompletedModules
    [System.Collections.Generic.List[hashtable]]$PerformanceHistory
    [hashtable]$LearningGoals
    [hashtable]$Preferences
    [datetime]$CreatedAt
    [datetime]$LastActive
    
    # Default constructor
    LearnerAnt() {
        $this.PerformanceHistory = [System.Collections.Generic.List[hashtable]]::new()
        $this.CompletedModules = @()
        $this.LearningGoals = @{}
        $this.Preferences = @{}
        $this.SkillLevel = 1
        $this.LearningStyle = 'Mixed'
        $this.CreatedAt = Get-Date
        $this.LastActive = Get-Date
    }
    
    # Constructor with basic parameters
    LearnerAnt([string]$id, [string]$startModule) {
        $this.LearnerId = $id
        $this.CurrentModule = $startModule
        $this.SkillLevel = 1
        $this.LearningStyle = 'Mixed'
        $this.CompletedModules = @()
        $this.PerformanceHistory = [System.Collections.Generic.List[hashtable]]::new()
        $this.LearningGoals = @{}
        $this.Preferences = @{
            MaxSessionTime = 60  # minutes
            PreferredDifficulty = 'Progressive'
            NotificationSettings = @{}
        }
        $this.CreatedAt = Get-Date
        $this.LastActive = Get-Date
    }
    
    # Record performance for a module
    [void] RecordPerformance([string]$moduleId, [double]$score, [int]$completionTime, [int]$attempts) {
        $performance = @{
            ModuleId = $moduleId
            Score = $score
            CompletionTime = $completionTime
            AttemptsNeeded = $attempts
            Timestamp = Get-Date
            Success = $score -ge 70  # 70% threshold for success
            SkillLevelAtTime = $this.SkillLevel
        }
        
        $this.PerformanceHistory.Add($performance)
        $this.LastActive = Get-Date
        
        # Update skill level based on performance
        if ($performance.Success) {
            $skillIncrease = ($score - 70) / 300  # Scale: 70-100 score -> 0-0.1 increase
            $this.SkillLevel = [Math]::Min($this.SkillLevel + $skillIncrease, 10.0)
        } else {
            # Slight decrease for failed attempts
            $this.SkillLevel = [Math]::Max($this.SkillLevel - 0.05, 1.0)
        }
        
        # Round skill level to 2 decimal places
        $this.SkillLevel = [Math]::Round($this.SkillLevel, 2)
    }
    
    # Mark module as completed
    [void] CompleteModule([string]$moduleId) {
        if ($moduleId -notin $this.CompletedModules) {
            $this.CompletedModules += $moduleId
        }
        $this.CurrentModule = $moduleId
        $this.LastActive = Get-Date
    }
    
    # Get average score across all attempts
    [double] GetAverageScore() {
        if ($this.PerformanceHistory.Count -eq 0) { return 0.0 }
        $totalScore = 0.0
        foreach ($performance in $this.PerformanceHistory) {
            $totalScore += $performance.Score
        }
        return $totalScore / $this.PerformanceHistory.Count
    }
    
    # Get success rate
    [double] GetSuccessRate() {
        if ($this.PerformanceHistory.Count -eq 0) { return 0.0 }
        $successCount = 0
        foreach ($performance in $this.PerformanceHistory) {
            if ($performance.Success) { $successCount++ }
        }
        return $successCount / $this.PerformanceHistory.Count
    }
    
    # Get average completion time
    [double] GetAverageCompletionTime() {
        if ($this.PerformanceHistory.Count -eq 0) { return 0.0 }
        $totalTime = 0
        foreach ($performance in $this.PerformanceHistory) {
            $totalTime += $performance.CompletionTime
        }
        return $totalTime / $this.PerformanceHistory.Count
    }
    
    # Get modules available for learning (prerequisites met)
    [string[]] GetAvailableModules([hashtable]$moduleGraph) {
        $available = @()
        foreach ($moduleId in $moduleGraph.Keys) {
            if ($moduleId -notin $this.CompletedModules) {
                $module = $moduleGraph[$moduleId]
                $canAccess = $true
                
                # Check prerequisites
                if ($module.ContainsKey('Prerequisites') -and $module.Prerequisites) {
                    foreach ($prereq in $module.Prerequisites) {
                        if ($prereq -notin $this.CompletedModules) {
                            $canAccess = $false
                            break
                        }
                    }
                }
                
                if ($canAccess) {
                    $available += $moduleId
                }
            }
        }
        return $available
    }
    
    # Get learning progress as percentage
    [double] GetProgressPercentage([hashtable]$moduleGraph) {
        if ($moduleGraph.Count -eq 0) { return 0.0 }
        return ($this.CompletedModules.Count / $moduleGraph.Count) * 100
    }
    
    # Get recommended difficulty based on recent performance
    [int] GetRecommendedDifficulty() {
        if ($this.PerformanceHistory.Count -eq 0) { 
            return [Math]::Max(1, [Math]::Floor($this.SkillLevel))
        }
        
        # Look at last 5 performances
        $recentPerformances = $this.PerformanceHistory | 
            Sort-Object { $_.Timestamp } | 
            Select-Object -Last 5
        
        $averageRecentScore = ($recentPerformances | Measure-Object -Property Score -Average).Average
        $recentSuccessRate = ($recentPerformances | Where-Object Success | Measure-Object).Count / $recentPerformances.Count
        
        # Adjust difficulty based on performance
        $baseDifficulty = [Math]::Floor($this.SkillLevel)
        
        if ($averageRecentScore -gt 85 -and $recentSuccessRate -gt 0.8) {
            # Performing well, can handle higher difficulty
            return [Math]::Min($baseDifficulty + 1, 5)
        } elseif ($averageRecentScore -lt 70 -or $recentSuccessRate -lt 0.5) {
            # Struggling, recommend lower difficulty
            return [Math]::Max($baseDifficulty - 1, 1)
        } else {
            return $baseDifficulty
        }
    }
    
    # Set learning goal
    [void] SetLearningGoal([string]$goalType, [object]$goalValue) {
        $this.LearningGoals[$goalType] = $goalValue
        $this.LastActive = Get-Date
    }
    
    # Check if learning goal is met
    [bool] IsGoalMet([string]$goalType, [hashtable]$moduleGraph) {
        if (-not $this.LearningGoals.ContainsKey($goalType)) { 
            return $false 
        }
        
        switch ($goalType) {
            'TargetModule' {
                return $this.LearningGoals[$goalType] -in $this.CompletedModules
            }
            'SkillLevel' {
                return $this.SkillLevel -ge $this.LearningGoals[$goalType]
            }
            'ModuleCount' {
                return $this.CompletedModules.Count -ge $this.LearningGoals[$goalType]
            }
            'AverageScore' {
                return $this.GetAverageScore() -ge $this.LearningGoals[$goalType]
            }
            default {
                return $false
            }
        }
        
        # Fallback return (this should never be reached)
        return $false
    }
    
    # Convert to hashtable for serialization
    [hashtable] ToHashtable() {
        return @{
            LearnerId = $this.LearnerId
            CurrentModule = $this.CurrentModule
            SkillLevel = $this.SkillLevel
            LearningStyle = $this.LearningStyle
            CompletedModules = $this.CompletedModules
            PerformanceHistory = $this.PerformanceHistory.ToArray()
            LearningGoals = $this.LearningGoals
            Preferences = $this.Preferences
            CreatedAt = $this.CreatedAt
            LastActive = $this.LastActive
            AverageScore = $this.GetAverageScore()
            SuccessRate = $this.GetSuccessRate()
            AverageCompletionTime = $this.GetAverageCompletionTime()
        }
    }
    
    # Create from hashtable (deserialization)
    static [LearnerAnt] FromHashtable([hashtable]$hash) {
        $learner = [LearnerAnt]::new()
        $learner.LearnerId = $hash.LearnerId
        $learner.CurrentModule = $hash.CurrentModule
        $learner.SkillLevel = $hash.SkillLevel
        $learner.LearningStyle = $hash.LearningStyle
        $learner.CompletedModules = $hash.CompletedModules
        $learner.LearningGoals = $hash.LearningGoals
        $learner.Preferences = $hash.Preferences
        $learner.CreatedAt = $hash.CreatedAt
        $learner.LastActive = $hash.LastActive
        
        # Restore performance history
        if ($hash.PerformanceHistory) {
            foreach ($performance in $hash.PerformanceHistory) {
                $learner.PerformanceHistory.Add($performance)
            }
        }
        
        return $learner
    }
    
    # String representation for debugging
    [string] ToString() {
        return "$($this.LearnerId) (Skill: $($this.SkillLevel), Style: $($this.LearningStyle), Completed: $($this.CompletedModules.Count))"
    }
}
