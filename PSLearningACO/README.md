# PSLearningACO - PowerShell Ant Colony Optimization for Adaptive Learning Paths

A PowerShell module that implements the Ant Colony Optimization (ACO) algorithm to generate optimal, personalized learning paths for skill development. The module tracks learner progress and adaptively recommends the best sequence of modules based on performance and learning style.

## Features

- 🐜 **Ant Colony Optimization Algorithm**: Intelligent pathfinding using pheromone trails and reinforcement learning
- 📊 **Learner Progress Tracking**: Record performance metrics and learning styles
- 📈 **Learning Analytics**: Generate comprehensive statistics on learner performance and path optimization
- 🎯 **Adaptive Path Recommendations**: Get optimal learning sequences based on learner data
- 💾 **Data Export**: Export learning graphs and analytics in multiple formats (JSON)
- ⚙️ **Configurable Parameters**: Customize ACO algorithm parameters (alpha, beta, evaporation rates)

## Installation

### Prerequisites
- PowerShell 5.1 or higher
- Windows, macOS, or Linux

### Quick Start

```powershell
# Clone the repository
git clone https://github.com/sup3r7-fabio/ps-learning-aco.git
cd ps-learning-aco

# Import the module
Import-Module ./PSLearningACO/PSLearningACO.psd1 -Force
```

## Core Concepts

### Ant Colony Optimization (ACO)
The ACO algorithm uses "pheromone trails" between learning modules to determine the best path:
- **Pheromone**: Virtual markers that strengthen paths showing good learner progression
- **Evaporation**: Old paths gradually lose effectiveness over time
- **Reinforcement**: Successful learner paths get stronger pheromone trails
- **Exploration**: New paths are explored probabilistically based on pheromone levels

### Learning Styles
The module supports four learning styles:
- **Visual**: Learn through diagrams, charts, and visual demonstrations
- **Practical**: Learn through hands-on exercises and practice
- **Theoretical**: Learn through concepts and theory
- **Mixed**: Balanced approach across all styles

### Skill Levels
Learners progress through difficulty levels 1-5:
- **Level 1**: Fundamentals
- **Level 2**: Beginner
- **Level 3**: Intermediate
- **Level 4**: Advanced
- **Level 5**: Expert

## Quick Tutorial

### 1. Start a Learning Colony

Initialize the ACO algorithm with your learning modules:

```powershell
# Start a learning colony (ACO system initialization)
$colony = Start-LearningColony -Verbose

# Output:
# ✅ Colony initialized with 15 modules
# ✅ 210 pheromone trails created
```

### 2. Add Learner Progress

Record a learner's performance data:

```powershell
# Create a learner and add progress
$learner = [PSLearningACO.LearnerAnt]::new(
    "DemoLearner",
    "Practical",
    "PS-Basics"
)

# Add performance records
Add-LearnerProgress -Learner $learner `
    -CurrentModule "PS-Basics" `
    -ModuleCompleted $true `
    -PerformanceScore 85 `
    -TimeSpent 45 `
    -Successful $true

Add-LearnerProgress -Learner $learner `
    -CurrentModule "Functions-Intro" `
    -ModuleCompleted $true `
    -PerformanceScore 78 `
    -TimeSpent 60 `
    -Successful $true
```

### 3. Get Learning Analytics

Analyze learner performance and path statistics:

```powershell
# Get analytics for the learner
$analytics = Get-LearningAnalytics -LearnerAnt $learner

# Output:
# LearnerName              : DemoLearner
# LearningStyle            : Practical
# AverageScore             : 81.5
# SuccessRate              : 1.0
# ModulesCompleted         : 2
# AveragePheromoneLevel    : 0.85
```

### 4. Calculate Optimal Learning Path

Get the best recommended sequence of modules:

```powershell
# Find optimal path from current module to target
$optimalPath = Get-OptimalPath `
    -Colony $colony `
    -StartModule "PS-Basics" `
    -TargetModule "PS-Advanced" `
    -LearnerAnt $learner

# Output:
# ModuleSequence : {PS-Basics, Functions-Intro, PS-Advanced}
# TotalDistance  : 3
# PathStrength   : 0.89
# Iterations     : 50
# ConvergenceAge : 2
```

### 5. Export Learning Graph

Export the complete learning data for analysis or backup:

```powershell
# Export learning graph to JSON
Export-LearningGraph `
    -LearnerAnts @($learner) `
    -Colony $colony `
    -OutputPath "./learning_export.json" `
    -Verbose

# Output:
# ✅ Successfully exported learning graph
# File: learning_export.json (74 KB)
```

## Complete End-to-End Example

```powershell
# Import module
Import-Module ./PSLearningACO/PSLearningACO.psd1 -Force

# Initialize the ACO colony
$colony = Start-LearningColony -Verbose

# Create a learner
$learner = [PSLearningACO.LearnerAnt]::new(
    "StudentName",
    "Visual",          # Learning style
    "PS-Basics"        # Starting module
)

# Record progress (simulate learner journey)
$progressData = @(
    @{ Module = "PS-Basics"; Score = 88; TimeSpent = 45; Success = $true },
    @{ Module = "Functions-Intro"; Score = 82; TimeSpent = 60; Success = $true },
    @{ Module = "Variables"; Score = 90; TimeSpent = 30; Success = $true }
)

foreach ($data in $progressData) {
    Add-LearnerProgress -Learner $learner `
        -CurrentModule $data.Module `
        -ModuleCompleted $true `
        -PerformanceScore $data.Score `
        -TimeSpent $data.TimeSpent `
        -Successful $data.Success
}

# Analyze performance
$analytics = Get-LearningAnalytics -LearnerAnt $learner
Write-Host "Student Average Score: $($analytics.AverageScore)"
Write-Host "Success Rate: $($analytics.SuccessRate * 100)%"

# Get recommended path
$recommendedPath = Get-OptimalPath `
    -Colony $colony `
    -StartModule "PS-Basics" `
    -TargetModule "PS-Advanced" `
    -LearnerAnt $learner

Write-Host "Recommended Learning Path:"
$recommendedPath.ModuleSequence | ForEach-Object { Write-Host "  → $_" }

# Export all data
Export-LearningGraph `
    -LearnerAnts @($learner) `
    -Colony $colony `
    -OutputPath "./student_learning_data.json"
```

## Available Cmdlets

### Start-LearningColony
Initialize the ACO learning optimization system.

```powershell
Start-LearningColony [-Verbose]
```

**Returns**: AntColony object with initialized modules and pheromone trails

---

### Add-LearnerProgress
Record a learner's performance on a module.

```powershell
Add-LearnerProgress -Learner <LearnerAnt> `
    -CurrentModule <string> `
    -ModuleCompleted <bool> `
    -PerformanceScore <int> `
    -TimeSpent <int> `
    -Successful <bool>
```

**Parameters**:
- `-Learner`: The LearnerAnt object to update
- `-CurrentModule`: Name of the module being learned
- `-ModuleCompleted`: Whether the module was completed
- `-PerformanceScore`: Score achieved (0-100)
- `-TimeSpent`: Time spent in minutes
- `-Successful`: Whether the learner succeeded

---

### Get-LearningAnalytics
Get detailed analytics for a learner.

```powershell
Get-LearningAnalytics -LearnerAnt <LearnerAnt>
```

**Returns**: PSCustomObject with analytics including:
- `AverageScore`: Mean performance score
- `SuccessRate`: Percentage of successful attempts
- `ModulesCompleted`: Total modules completed
- `AveragePheromoneLevel`: Average trail strength

---

### Get-OptimalPath
Calculate the optimal learning sequence using ACO.

```powershell
Get-OptimalPath -Colony <AntColony> `
    -StartModule <string> `
    -TargetModule <string> `
    -LearnerAnt <LearnerAnt>
```

**Returns**: PSCustomObject with:
- `ModuleSequence`: Recommended module order
- `TotalDistance`: Number of steps
- `PathStrength`: Pheromone strength (0-1)
- `Iterations`: ACO iterations performed

---

### Export-LearningGraph
Export learning data to JSON format.

```powershell
Export-LearningGraph -LearnerAnts <LearnerAnt[]> `
    -Colony <AntColony> `
    -OutputPath <string> `
    [-Force]
```

**Parameters**:
- `-LearnerAnts`: Array of learner objects to export
- `-Colony`: The AntColony to export
- `-OutputPath`: Destination file path
- `-Force`: Overwrite existing file

---

## Configuration

### ACO Parameters

Edit `PSLearningACO/Data/ACOConfig.json` to customize the algorithm:

```json
{
  "Alpha": 1.0,                    // Weight of pheromone influence
  "Beta": 2.0,                     // Weight of distance influence
  "EvaporationRate": 0.1,          // Pheromone evaporation (0-1)
  "InitialPheromone": 1.0,         // Starting pheromone level
  "PheromoneReinforcement": 0.5,   // Strength of successful path reinforcement
  "Iterations": 50,                // ACO iterations per path calculation
  "Q": 100                         // Pheromone deposit factor
}
```

### Learning Modules

Edit `PSLearningACO/Data/DefaultModules.json` to add or modify learning modules:

```json
{
  "ModuleName": "PS-Basics",
  "Difficulty": 1,
  "Prerequisites": [],
  "EstimatedTime": 45,
  "Description": "PowerShell fundamentals"
}
```

## Common Use Cases

### Use Case 1: Personalized Learning Path
```powershell
# Get a path tailored to a specific learner's style and progress
$path = Get-OptimalPath -Colony $colony `
    -StartModule $learner.CurrentModule `
    -TargetModule "PS-Advanced" `
    -LearnerAnt $learner
```

### Use Case 2: Performance Dashboard
```powershell
# Generate performance report
$analytics = Get-LearningAnalytics -LearnerAnt $learner
$analytics | Format-Table -AutoSize
```

### Use Case 3: Batch Learner Tracking
```powershell
# Track multiple learners and export their data
$learners = @($learner1, $learner2, $learner3)
Export-LearningGraph -LearnerAnts $learners -Colony $colony `
    -OutputPath "./cohort_results.json"
```

## Troubleshooting

### Module Import Fails
```powershell
# Ensure you're in the correct directory
cd path/to/ps-learning-aco

# Try with -Force to reload
Import-Module ./PSLearningACO/PSLearningACO.psd1 -Force
```

### LearnerAnt Creation Issues
```powershell
# Verify valid learning style
$validStyles = @("Visual", "Practical", "Theoretical", "Mixed")

# Verify module exists in configuration
$colony.LearningGraph | Get-Member
```

### Path Calculation Returns Empty Results
```powershell
# Ensure start and target modules are different
# Check that modules exist in the learning graph
# Increase -Iterations parameter if needed
```

## Architecture

```
PSLearningACO/
├── Classes/
│   ├── AntColony.ps1         # ACO algorithm orchestration
│   ├── LearnerAnt.ps1        # Learner representation
│   └── PheromoneTrail.ps1    # Pheromone tracking
├── Public/
│   ├── Start-LearningColony.ps1
│   ├── Add-LearnerProgress.ps1
│   ├── Get-LearningAnalytics.ps1
│   ├── Get-OptimalPath.ps1
│   └── Export-LearningGraph.ps1
├── Data/
│   ├── ACOConfig.json        # Algorithm configuration
│   └── DefaultModules.json   # Learning module definitions
└── PSLearningACO.psd1        # Module manifest
```

## Algorithm Details

### ACO Path Finding
1. **Initialize**: Create ants and set pheromone levels
2. **Iteration**: Each ant constructs a path probabilistically
3. **Evaluation**: Score paths based on learner success
4. **Evaporation**: Reduce old pheromone traces
5. **Reinforcement**: Strengthen successful paths
6. **Convergence**: Repeat until best path stabilizes

### Pheromone Calculation
```
Probability = (Pheromone^α × Distance^β) / Sum(all choices)
```

- **α (Alpha)**: Pheromone importance (higher = follow trails more)
- **β (Beta)**: Distance importance (higher = prioritize shorter paths)

## Performance Considerations

- **Small learning graphs** (< 20 modules): Near-instant path calculation
- **Medium graphs** (20-50 modules): < 100ms
- **Large graphs** (50+ modules): 100-500ms depending on iterations
- Adjust `Iterations` in ACOConfig.json to balance speed and accuracy

## Contributing

Contributions are welcome! Areas for enhancement:
- Additional learning style profiles
- Machine learning integration
- Real-time learner tracking
- Web UI interface
- Multi-user support

## License

MIT License - See LICENSE file for details

## Support

For issues, questions, or feature requests:
- GitHub Issues: https://github.com/sup3r7-fabio/ps-learning-aco/issues
- Email: fabio.ostind@sup3r7.onmicrosoft.com

## Changelog

### Version 1.0.0 (November 11, 2025)
- Initial release
- ACO algorithm implementation
- 5 core cmdlets
- JSON export functionality
- Comprehensive bug fixes for enumeration and serialization

---

**Happy Learning! 🚀**
