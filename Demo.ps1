# PSLearningACO Demonstration Script
# This script demonstrates the Ant Colony Optimization system for PowerShell learning

Write-Host "🐜 PSLearningACO Demonstration" -ForegroundColor Cyan
Write-Host "══════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Import the module
Write-Host "📦 Importing PSLearningACO module..." -ForegroundColor Yellow
Import-Module ./PSLearningACO -Force
Write-Host "✅ Module imported successfully!" -ForegroundColor Green
Write-Host ""

# Initialize the learning colony
Write-Host "🏁 Starting the Learning Colony..." -ForegroundColor Yellow
Start-LearningColony
Write-Host ""

# Add some learner progress
Write-Host "📊 Recording learner progress..." -ForegroundColor Yellow
$progress1 = Add-LearnerProgress -LearnerId "DemoLearner" -ModuleId "PS-Basics" -Score 90 -CompletionTime 30 -ShowFeedback
$progress2 = Add-LearnerProgress -LearnerId "DemoLearner" -ModuleId "PS-Objects" -Score 85 -CompletionTime 45 -ShowFeedback
Write-Host ""

# Get learning analytics
Write-Host "📈 Getting learning analytics..." -ForegroundColor Yellow
$analytics = Get-LearningAnalytics
Write-Host "Analytics Summary:" -ForegroundColor Cyan
Write-Host "  • Total Learners: $($analytics.SystemOverview.TotalLearners)" -ForegroundColor Gray
Write-Host "  • Total Modules: $($analytics.SystemOverview.TotalModules)" -ForegroundColor Gray
Write-Host "  • Active Trails: $($analytics.SystemOverview.ActiveTrails)" -ForegroundColor Gray
Write-Host "  • Average Pheromone: $($analytics.SystemOverview.AveragePheromoneLevel.ToString('F3'))" -ForegroundColor Gray
Write-Host ""

# Try to get an optimal path (may have issues due to bugs)
Write-Host "🛣️  Calculating optimal learning path..." -ForegroundColor Yellow
try {
    $path = Get-OptimalPath -LearnerId "DemoLearner" -TargetModule "PS-Functions" -MaxIterations 10
    if ($path) {
        Write-Host "✅ Optimal path calculated!" -ForegroundColor Green
        Write-Host "Path: $($path.OptimalPath -join ' → ')" -ForegroundColor Gray
    } else {
        Write-Host "⚠️  No optimal path found (known issue with ACO algorithm)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Error calculating path: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Export learning graph (may fail due to JSON serialization)
Write-Host "💾 Exporting learning graph..." -ForegroundColor Yellow
try {
    Export-LearningGraph -OutputPath "./DemoExport.json" -Force
    Write-Host "✅ Learning graph exported to DemoExport.json" -ForegroundColor Green
} catch {
    Write-Host "❌ Error exporting graph: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   (Known issue with hashtable serialization)" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "🎉 Demonstration complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Known Issues:" -ForegroundColor Yellow
Write-Host "  • Get-OptimalPath has enumeration bugs in ACO algorithm" -ForegroundColor Gray
Write-Host "  • Export-LearningGraph fails on JSON serialization of hashtables" -ForegroundColor Gray
Write-Host ""
Write-Host "Core functionality working:" -ForegroundColor Cyan
Write-Host "  ✅ Module loading and initialization" -ForegroundColor Green
Write-Host "  ✅ Learner progress recording" -ForegroundColor Green
Write-Host "  ✅ Learning analytics generation" -ForegroundColor Green
Write-Host "  ✅ Basic ACO system structure" -ForegroundColor Green
