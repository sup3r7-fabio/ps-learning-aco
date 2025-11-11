# PheromoneTrail Class for PSLearningACO
# Represents a pheromone trail between two learning modules

class PheromoneTrail {
    [string]$FromModule
    [string]$ToModule
    [double]$PheromoneLevel
    [double]$SuccessRate
    [int]$AverageCompletionTime
    [ValidateRange(1, 5)]
    [int]$Difficulty
    [datetime]$LastUpdated
    [int]$TraversalCount
    [double]$TotalScore
    
    # Default constructor
    PheromoneTrail() {
        $this.PheromoneLevel = 0.5
        $this.SuccessRate = 0.0
        $this.AverageCompletionTime = 0
    $this.Difficulty = 1
        $this.LastUpdated = Get-Date
        $this.TraversalCount = 0
        $this.TotalScore = 0.0
    }
    
    # Constructor with from/to modules
    PheromoneTrail([string]$from, [string]$to) {
        $this.FromModule = $from
        $this.ToModule = $to
        $this.PheromoneLevel = 0.5  # Initial pheromone level
        $this.SuccessRate = 0.0
        $this.AverageCompletionTime = 0
    $this.Difficulty = 1
        $this.LastUpdated = Get-Date
        $this.TraversalCount = 0
        $this.TotalScore = 0.0
    }
    
    # Update pheromone level with reinforcement
    [void] UpdatePheromone([double]$reinforcement) {
        $this.PheromoneLevel += $reinforcement
        $this.LastUpdated = Get-Date
        
        # Ensure pheromone stays within bounds
        if ($this.PheromoneLevel -gt 10.0) { 
            $this.PheromoneLevel = 10.0 
        }
        if ($this.PheromoneLevel -lt 0.01) { 
            $this.PheromoneLevel = 0.01 
        }
    }
    
    # Apply evaporation to pheromone level
    [void] Evaporate([double]$evaporationRate) {
        $this.PheromoneLevel *= (1 - $evaporationRate)
        if ($this.PheromoneLevel -lt 0.01) { 
            $this.PheromoneLevel = 0.01 
        }
    }
    
    # Record a traversal of this trail
    [void] RecordTraversal([double]$score, [int]$completionTime, [bool]$success) {
        $this.TraversalCount++
        $this.TotalScore += $score
        
        # Update average completion time
        if ($this.AverageCompletionTime -eq 0) {
            $this.AverageCompletionTime = $completionTime
        } else {
            $this.AverageCompletionTime = [int](($this.AverageCompletionTime + $completionTime) / 2)
        }
        
        # Update success rate
        $successCount = [int]($this.SuccessRate * ($this.TraversalCount - 1))
        if ($success) { $successCount++ }
        $this.SuccessRate = $successCount / $this.TraversalCount
        
        $this.LastUpdated = Get-Date
    }
    
    # Get average score for this trail
    [double] GetAverageScore() {
        if ($this.TraversalCount -eq 0) { return 0.0 }
        return $this.TotalScore / $this.TraversalCount
    }
    
    # Get trail strength (combination of pheromone and success rate)
    [double] GetTrailStrength() {
        return $this.PheromoneLevel * (1 + $this.SuccessRate)
    }
    
    # Convert to hashtable for serialization
    [hashtable] ToHashtable() {
        return @{
            FromModule = $this.FromModule
            ToModule = $this.ToModule
            PheromoneLevel = $this.PheromoneLevel
            SuccessRate = $this.SuccessRate
            AverageCompletionTime = $this.AverageCompletionTime
            Difficulty = $this.Difficulty
            LastUpdated = $this.LastUpdated
            TraversalCount = $this.TraversalCount
            AverageScore = $this.GetAverageScore()
            TrailStrength = $this.GetTrailStrength()
        }
    }
    
    # Create from hashtable (deserialization)
    static [PheromoneTrail] FromHashtable([hashtable]$hash) {
        $trail = [PheromoneTrail]::new()
        $trail.FromModule = $hash.FromModule
        $trail.ToModule = $hash.ToModule
        $trail.PheromoneLevel = $hash.PheromoneLevel
        $trail.SuccessRate = $hash.SuccessRate
        $trail.AverageCompletionTime = $hash.AverageCompletionTime
        $trail.Difficulty = $hash.Difficulty
        $trail.LastUpdated = $hash.LastUpdated
        $trail.TraversalCount = $hash.TraversalCount
        if ($hash.ContainsKey('TotalScore')) {
            $trail.TotalScore = $hash.TotalScore
        }
        return $trail
    }
    
    # String representation for debugging
    [string] ToString() {
        return "$($this.FromModule) → $($this.ToModule) (φ: $($this.PheromoneLevel.ToString('F3')), SR: $($this.SuccessRate.ToString('P1')))"
    }
}
