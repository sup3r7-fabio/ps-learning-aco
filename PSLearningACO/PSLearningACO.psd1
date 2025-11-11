@{
    RootModule = 'PSLearningACO.psm1'
    ModuleVersion = '0.0.1'
    GUID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author = 'Fabio Ostlind'
    CompanyName = 'Sup3r7 AB'
    Copyright = '(c) 2025. All rights reserved.'
    Description = 'Ant Colony Optimization system for adaptive PowerShell learning paths. Uses pheromone-guided algorithms to recommend optimal learning sequences based on collective learner intelligence.'
    
    PowerShellVersion = '5.1'
    DotNetFrameworkVersion = '4.7.2'
    
    RequiredModules = @()
    RequiredAssemblies = @()
    
    # Functions to export from this module
    FunctionsToExport = @(
        'Start-LearningColony',
        'Get-OptimalPath',
        'Update-PheromoneTrails',
        'Add-LearnerProgress',
        'Get-LearningAnalytics',
        'Export-LearningGraph',
        'Set-ACOConfiguration',
        'Get-ACOConfiguration',
        'Reset-LearningColony',
        'Import-LearningModules'
    )
    
    # Cmdlets to export from this module
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module
    AliasesToExport = @(
        'Start-ACO', 
        'Get-Path', 
        'Add-Progress',
        'Get-Analytics',
        'Export-Graph'
    )
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module
            Tags = @('ACO', 'Learning', 'AI', 'Optimization', 'Education', 'PowerShell', 'Training', 'Adaptive', 'Pheromone', 'AntColony')
            
            # A URL to the license for this module
            LicenseUri = ''
            
            # A URL to the main website for this project
            ProjectUri = ''
            
            # A URL to an icon representing this module
            IconUri = ''
            
            # Release notes of this module
            ReleaseNotes = @'
Initial release of PowerShell ACO Learning System v1.0.0

Features:
- Ant Colony Optimization algorithm for learning path recommendation
- Pheromone-guided adaptive learning system
- Comprehensive analytics and reporting
- PowerShell native implementation with class-based architecture
- Export capabilities for learning graphs and analytics
- Configurable ACO parameters for optimization
- Support for multiple learning styles and skill levels
- Real-time performance tracking and path optimization

This module demonstrates advanced PowerShell concepts including:
- Custom PowerShell classes
- Complex data structures and algorithms
- Pipeline integration
- Advanced parameter handling
- Comprehensive error handling and logging
'@
        }
    }
}
