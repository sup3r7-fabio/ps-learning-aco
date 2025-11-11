# Add-LearnerProgress.ps1 (Simplified Version)
# Record learner progress and update pheromone trails

function Add-LearnerProgress {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$LearnerId,
        
        [Parameter(Mandatory = $true)]
        [string]$ModuleId,
        
        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 100)]
        [double]$Score,
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 1440)]  # 1 minute to 24 hours
        [int]$CompletionTime = 60,
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 10)]
        [int]$AttemptsNeeded = 1,
        
        [Parameter(Mandatory = $false)]
        [string[]]$DifficultConcepts = @(),
        
        [Parameter(Mandatory = $false)]
        [hashtable]$AdditionalNotes = @{},
        
        [Parameter(Mandatory = $false)]
        [switch]$ShowFeedback
    )
    
    begin {
        if (-not $script:LearningColony) {
            throw "Learning Colony not initialized. Run Start-LearningColony first."
        }
        
        Write-Verbose "Recording progress for learner $LearnerId on module $ModuleId"
    }
    
    process {
        try {
            # Get or create learner
            $learner = $script:LearningColony.GetLearner($LearnerId)
            if (-not $learner) {
                Write-Warning "Learner $LearnerId not found. Creating new learner with default settings."
                $learner = [LearnerAnt]::new()
                $learner.LearnerId = $LearnerId
                $script:LearningColony.AddLearner($learner)
            }
            
            # Validate module exists
            if (-not $script:LearningColony.LearningGraph.ContainsKey($ModuleId)) {
                throw "Module '$ModuleId' not found in learning graph"
            }
            
            $module = $script:LearningColony.LearningGraph[$ModuleId]
            
            # Determine if this is a successful completion
            $success = $Score -ge $script:LearningColony.Configuration.Thresholds.PassingScore
            $wasNewCompletion = $ModuleId -notin $learner.CompletedModules
            
            # Record performance data
            $performance = @{
                ModuleId = $ModuleId
                Score = $Score
                CompletionTime = $CompletionTime
                AttemptsNeeded = $AttemptsNeeded
                Success = $success
                DifficultConcepts = $DifficultConcepts
                Timestamp = Get-Date
                AdditionalNotes = $AdditionalNotes
            }
            
            # Add performance to learner's history
            $learner.RecordPerformance($ModuleId, $Score, $CompletionTime, $AttemptsNeeded)
            
            # Update pheromone trails if successful and from current path
            if ($success -and $learner.CurrentModule) {
                Write-Verbose "Recording learning event from $($learner.CurrentModule) to $ModuleId"
                $script:LearningColony.RecordLearningEvent($LearnerId, $learner.CurrentModule, $ModuleId, $Score, $CompletionTime, $success)
            }
            
            # Update learner's current module
            $learner.CurrentModule = $ModuleId
            $learner.LastActive = Get-Date
            
            # Create progress record for output
            $progressRecord = [PSCustomObject]@{
                LearnerId = $LearnerId
                ModuleId = $ModuleId
                ModuleTitle = $module.Title
                Score = $Score
                CompletionTime = $CompletionTime
                AttemptsNeeded = $AttemptsNeeded
                Success = $success
                WasNewCompletion = $wasNewCompletion
                DifficultConcepts = $DifficultConcepts
                UpdatedSkillLevel = $learner.SkillLevel
                AverageScore = $learner.GetAverageScore()
                SuccessRate = $learner.GetSuccessRate()
                Timestamp = $performance.Timestamp
                NextRecommendations = @("Check available modules using Get-OptimalPath")
            }
            
            # Show feedback if requested
            if ($ShowFeedback) {
                Write-Host ""
                Write-Host "📊 Learning Progress Update" -ForegroundColor Cyan
                Write-Host "═══════════════════════════" -ForegroundColor Cyan
                
                if ($Score -ge 90) {
                    Write-Host "🎉 Outstanding performance on $ModuleId!" -ForegroundColor Green
                } elseif ($Score -ge 80) {
                    Write-Host "🌟 Excellent work on $ModuleId!" -ForegroundColor Yellow
                } elseif ($Score -ge 70) {
                    Write-Host "✅ Good job completing $ModuleId!" -ForegroundColor Cyan
                } else {
                    Write-Host "📚 Keep practicing - you're making progress on $ModuleId!" -ForegroundColor Magenta
                }
                
                Write-Host "   Score: $Score% | Time: $CompletionTime min | Success: $success" -ForegroundColor Gray
                Write-Host ""
            }
            
            Write-Output $progressRecord
        }
        catch {
            Write-Error "Failed to record learner progress: $($_.Exception.Message)"
            throw
        }
    }
}

# Create aliases
New-Alias -Name "Add-Progress" -Value "Add-LearnerProgress" -Force
