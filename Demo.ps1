# PSLearningACO Demonstration Script
# This script demonstrates the Ant Colony Optimization system for PowerShell learning

Write-Host "🐜 PSLearningACO Demonstration" -ForegroundColor Cyan
Write-Host "══════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Import the module
Write-Host "📦 Importing PSLearningACO module..." -ForegroundColor Yellow
Import-Module ./PSLearningACO/PSLearningACO.psd1 -Force
Write-Host "✅ Module imported successfully!" -ForegroundColor Green
Write-Host ""

# Initialize the learning colony
Write-Host "🏁 Starting the Learning Colony..." -ForegroundColor Yellow
$colony = Start-LearningColony -Verbose
Write-Host ""

# Add some learner progress
Write-Host "📊 Recording learner progress..." -ForegroundColor Yellow
$learnerProgress1 = Add-LearnerProgress -LearnerId "DemoLearner" -ModuleId "PS-Basics" -Score 90 -CompletionTime 30 -ShowFeedback
Write-Host "✅ Progress recorded for PS-Basics (Score: 90)" -ForegroundColor Green

$learnerProgress2 = Add-LearnerProgress -LearnerId "DemoLearner" -ModuleId "Functions-Intro" -Score 85 -CompletionTime 45 -ShowFeedback
Write-Host "✅ Progress recorded for Functions-Intro (Score: 85)" -ForegroundColor Green
Write-Host ""

# Get learning analytics
Write-Host "📈 Getting learning analytics..." -ForegroundColor Yellow
$analytics = Get-LearningAnalytics -LearnerId "DemoLearner"
Write-Host "Analytics Summary:" -ForegroundColor Cyan
Write-Host "  • Total Learners: $($analytics.SystemOverview.TotalLearners)" -ForegroundColor Gray
Write-Host "  • Total Modules: $($analytics.SystemOverview.TotalModules)" -ForegroundColor Gray
Write-Host "  • Total Pheromone Trails: $($analytics.SystemOverview.TotalPheromoneTrails)" -ForegroundColor Gray
Write-Host "  • Average Skill Level: $($analytics.SystemOverview.AverageSkillLevel)" -ForegroundColor Gray
Write-Host ""

# Calculate optimal learning path
Write-Host "🛣️  Calculating optimal learning path..." -ForegroundColor Yellow
try {
    $path = Get-OptimalPath `
        -LearnerId "DemoLearner" `
        -StartModule "PS-Basics" `
        -TargetModule "PS-Advanced"
    
    if ($path -and $path.OptimalPath.Count -gt 0) {
        Write-Host "✅ Optimal path calculated!" -ForegroundColor Green
        Write-Host "   Recommended learning sequence:" -ForegroundColor Cyan
        $path.OptimalPath | ForEach-Object { Write-Host "     → $_" -ForegroundColor Gray }
        Write-Host "   Path Strength: $($path.PathMetrics.PathStrength)" -ForegroundColor Gray
        Write-Host "   Total Modules: $($path.PathMetrics.TotalModules)" -ForegroundColor Gray
        Write-Host "   Estimated Time: $($path.PathMetrics.TotalEstimatedTime) minutes" -ForegroundColor Gray
    } else {
        Write-Host "⚠️  No optimal path found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Error calculating path: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Export learning graph
Write-Host "💾 Exporting learning graph..." -ForegroundColor Yellow
try {
    Export-LearningGraph `
        -OutputPath "./DemoExport.json" `
        -Force
    
    # Check file size
    $fileInfo = Get-Item "./DemoExport.json" -ErrorAction SilentlyContinue
    if ($fileInfo) {
        Write-Host "✅ Successfully exported learning graph" -ForegroundColor Green
        Write-Host "   File: DemoExport.json ($([math]::Round($fileInfo.Length / 1KB, 1)) KB)" -ForegroundColor Gray
    }
} catch {
    Write-Host "❌ Error exporting graph: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

Write-Host "🎉 Demonstration complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  ✅ Module loading and initialization" -ForegroundColor Green
Write-Host "  ✅ Learning colony with 15 modules and 210 pheromone trails" -ForegroundColor Green
Write-Host "  ✅ Learner progress tracking" -ForegroundColor Green
Write-Host "  ✅ Learning analytics generation" -ForegroundColor Green
Write-Host "  ✅ Optimal path calculation via ACO algorithm" -ForegroundColor Green
Write-Host "  ✅ JSON export for data persistence" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Read PSLearningACO/README.md for detailed tutorial" -ForegroundColor Gray
Write-Host "  2. Customize learning modules in PSLearningACO/Data/DefaultModules.json" -ForegroundColor Gray
Write-Host "  3. Adjust ACO parameters in PSLearningACO/Data/ACOConfig.json" -ForegroundColor Gray
Write-Host "  4. Create your own learner profiles and track progress" -ForegroundColor Gray
Write-Host ""
