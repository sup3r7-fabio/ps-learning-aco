# Export-LearningGraph.ps1
# Export learning paths and ACO data for visualization and analysis

function Export-LearningGraph {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('JSON', 'XML', 'CSV', 'GraphML', 'DOT', 'YAML')]
        [string]$Format = 'JSON',
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('All', 'Modules', 'Pheromones', 'Learners', 'Paths', 'Analytics')]
        [string[]]$DataTypes = @('All'),
        
        [Parameter(Mandatory = $false)]
        [string]$LearnerId,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeMetadata,
        
        [Parameter(Mandatory = $false)]
        [switch]$Compress,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    begin {
        if (-not $script:LearningColony) {
            throw "Learning Colony not initialized. Run Start-LearningColony first."
        }
        
        # Ensure output directory exists
        $outputDir = Split-Path -Path $OutputPath -Parent
        if ($outputDir -and -not (Test-Path $outputDir)) {
            Write-Verbose "Creating output directory: $outputDir"
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }
        
        # Check if file exists and handle overwrite
        if ((Test-Path $OutputPath) -and -not $Force) {
            throw "Output file already exists. Use -Force to overwrite: $OutputPath"
        }
        
        Write-Verbose "Exporting learning graph to: $OutputPath (Format: $Format)"
    }
    
    process {
        try {
            $exportData = @{
                ExportMetadata = @{
                    ExportedAt = Get-Date
                    ExportedBy = $env:USERNAME
                    Format = $Format
                    DataTypes = $DataTypes
                    SourceSystem = "PSLearningACO"
                    Version = "1.0.0"
                }
            }
            
            # Determine what data to export
            $includeAll = $DataTypes -contains 'All'
            
            # Export modules data
            if ($includeAll -or $DataTypes -contains 'Modules') {
                Write-Verbose "Exporting modules data"
                $exportData.Modules = @{}
                
                foreach ($moduleId in $script:LearningColony.LearningGraph.Keys) {
                    $module = $script:LearningColony.LearningGraph[$moduleId]
                    $exportData.Modules[$moduleId] = @{
                        Title = $module.Title
                        Description = $module.Description
                        Difficulty = $module.Difficulty
                        EstimatedTime = $module.EstimatedTime
                        Prerequisites = $module.Prerequisites
                        LearningObjectives = $module.LearningObjectives
                        Tags = $module.Tags
                        Category = $module.Category
                    }
                    
                    if ($IncludeMetadata) {
                        $moduleStats = $script:LearningColony.GetModuleStatistics($moduleId)
                        $exportData.Modules[$moduleId].Statistics = $moduleStats
                    }
                }
            }
            
            # Export pheromone trails
            if ($includeAll -or $DataTypes -contains 'Pheromones') {
                Write-Verbose "Exporting pheromone trails"
                $exportData.PheromoneTrails = @{}
                
                foreach ($trailKey in $script:LearningColony.PheromoneTrails.Keys) {
                    $trail = $script:LearningColony.PheromoneTrails[$trailKey]
                    $exportData.PheromoneTrails[$trailKey] = @{
                        FromModule = $trail.FromModule
                        ToModule = $trail.ToModule
                        PheromoneLevel = $trail.PheromoneLevel
                        TraversalCount = $trail.TraversalCount
                        SuccessCount = $trail.SuccessCount
                        SuccessRate = $trail.SuccessRate
                        LastUpdated = $trail.LastUpdated
                        TrailStrength = $trail.GetTrailStrength()
                    }
                    
                    if ($IncludeMetadata) {
                        $exportData.PheromoneTrails[$trailKey].TraversalHistory = $trail.TraversalHistory
                    }
                }
            }
            
            # Export learners data
            if ($includeAll -or $DataTypes -contains 'Learners') {
                Write-Verbose "Exporting learners data"
                $exportData.Learners = @{}
                
                $learnersToExport = if ($LearnerId) {
                    $learner = $script:LearningColony.GetLearner($LearnerId)
                    if ($learner) { @($learner) } else { @() }
                } else {
                    $script:LearningColony.Learners
                }
                
                foreach ($learner in $learnersToExport) {
                    $exportData.Learners[$learner.LearnerId] = @{
                        SkillLevel = $learner.SkillLevel
                        LearningStyle = $learner.LearningStyle
                        CompletedModules = $learner.CompletedModules
                        AverageScore = $learner.GetAverageScore()
                        SuccessRate = $learner.GetSuccessRate()
                        TotalAttempts = $learner.PerformanceHistory.Count
                        JoinedAt = $learner.JoinedAt
                        LastActive = $learner.LastActive
                    }
                    
                    if ($IncludeMetadata) {
                        if ($learner.PerformanceHistory -is [System.Collections.Generic.List[hashtable]]) {
                        $exportData.Learners[$learner.LearnerId].PerformanceHistory = $learner.PerformanceHistory.ToArray()
                    } else {
                        $exportData.Learners[$learner.LearnerId].PerformanceHistory = @()
                    }
                        $exportData.Learners[$learner.LearnerId].LearningPath = $learner.GetLearningPath()
                    }
                }
            }
            
            # Export optimal paths
            if ($includeAll -or $DataTypes -contains 'Paths') {
                Write-Verbose "Exporting optimal paths"
                $exportData.OptimalPaths = @{}
                
                $skillLevels = @(1, 2, 3, 4, 5)
                $learningStyles = @('Visual', 'Practical', 'Theoretical', 'Mixed')
                
                foreach ($skillLevel in $skillLevels) {
                    $exportData.OptimalPaths[$skillLevel.ToString()] = @{}
                    
                    foreach ($style in $learningStyles) {
                        $tempLearner = [LearnerAnt]::new()
                        $tempLearner.SkillLevel = $skillLevel
                        $tempLearner.LearningStyle = $style
                        $tempLearner.CurrentModule = "PS-Basics"
                        
                        try {
                            $path = $script:LearningColony.FindOptimalPath($tempLearner, "PS-Advanced", 10)
                            $exportData.OptimalPaths[$skillLevel.ToString()][$style] = @{
                                Path = $path
                                TotalDifficulty = ($path | ForEach-Object { $script:LearningColony.LearningGraph[$_].Difficulty } | Measure-Object -Sum).Sum
                                EstimatedTime = ($path | ForEach-Object { $script:LearningColony.LearningGraph[$_].EstimatedTime } | Measure-Object -Sum).Sum
                                PathStrength = $script:LearningColony.CalculatePathStrength($path)
                            }
                        }
                        catch {
                            Write-Warning "Could not generate path for skill level $skillLevel, style $style"
                        }
                    }
                }
            }
            
            # Export analytics summary
            if ($includeAll -or $DataTypes -contains 'Analytics') {
                Write-Verbose "Exporting analytics summary"
                $exportData.Analytics = @{
                    SystemStatistics = $script:LearningColony.GetStatistics()
                    
                    ModuleStatistics = @{
                        TotalModules = $script:LearningColony.LearningGraph.Count
                        AverageDifficulty = [Math]::Round(($script:LearningColony.LearningGraph.Values.Difficulty | Measure-Object -Average).Average, 2)
                        DifficultyDistribution = $script:LearningColony.LearningGraph.Values | 
                            Group-Object Difficulty | 
                            Sort-Object Name | 
                            ForEach-Object { 
                                [PSCustomObject]@{ 
                                    Difficulty = $_.Name; 
                                    Count = $_.Count; 
                                    Percentage = [Math]::Round(($_.Count / $script:LearningColony.LearningGraph.Count) * 100, 1) 
                                } 
                            }
                        CategoryDistribution = $script:LearningColony.LearningGraph.Values | 
                            Group-Object Category | 
                            Sort-Object Count -Descending | 
                            ForEach-Object { 
                                [PSCustomObject]@{ 
                                    Category = $_.Name; 
                                    Count = $_.Count; 
                                    Percentage = [Math]::Round(($_.Count / $script:LearningColony.LearningGraph.Count) * 100, 1) 
                                } 
                            }
                    }
                    
                    LearnerStatistics = if ($script:LearningColony.Learners.Count -gt 0) {
                        @{
                            TotalLearners = $script:LearningColony.Learners.Count
                            AverageSkillLevel = [Math]::Round(($script:LearningColony.Learners.SkillLevel | Measure-Object -Average).Average, 2)
                            AverageSuccessRate = [Math]::Round(($script:LearningColony.Learners | ForEach-Object { $_.GetSuccessRate() } | Measure-Object -Average).Average * 100, 1)
                            StyleDistribution = $script:LearningColony.Learners | 
                                Group-Object LearningStyle | 
                                Sort-Object Count -Descending | 
                                ForEach-Object { 
                                    [PSCustomObject]@{ 
                                        Style = $_.Name; 
                                        Count = $_.Count; 
                                        Percentage = [Math]::Round(($_.Count / $script:LearningColony.Learners.Count) * 100, 1) 
                                    } 
                                }
                        }
                    } else {
                        @{ TotalLearners = 0 }
                    }
                    
                    PheromoneStatistics = @{
                        TotalTrails = $script:LearningColony.PheromoneTrails.Count
                        ActiveTrails = ($script:LearningColony.PheromoneTrails.Values | Where-Object { $_.TraversalCount -gt 0 }).Count
                        AverageStrength = [Math]::Round(($script:LearningColony.PheromoneTrails.Values | ForEach-Object { $_.GetTrailStrength() } | Measure-Object -Average).Average, 4)
                        TotalTraversals = ($script:LearningColony.PheromoneTrails.Values.TraversalCount | Measure-Object -Sum).Sum
                    }
                }
            }
            
            # Convert to specified format and save
            $outputContent = $null
            
            switch ($Format) {
                'JSON' {
                    Write-Verbose "Converting to JSON format"
                    $outputContent = $exportData | ConvertTo-Json -Depth 10 -Compress:$false
                }
                
                'XML' {
                    Write-Verbose "Converting to XML format"
                    $xmlDoc = New-Object System.Xml.XmlDocument
                    $root = $xmlDoc.CreateElement("LearningGraphExport")
                    $xmlDoc.AppendChild($root) | Out-Null
                    
                    function ConvertTo-XmlElement($obj, $name, $doc, $parent) {
                        $element = $doc.CreateElement($name)
                        
                        if ($obj -is [hashtable] -or $obj -is [System.Collections.Specialized.OrderedDictionary]) {
                            foreach ($key in $obj.Keys) {
                                ConvertTo-XmlElement $obj[$key] $key $doc $element
                            }
                        }
                        elseif ($obj -is [array]) {
                            for ($i = 0; $i -lt $obj.Count; $i++) {
                                ConvertTo-XmlElement $obj[$i] "Item$i" $doc $element
                            }
                        }
                        else {
                            $element.InnerText = [string]$obj
                        }
                        
                        $parent.AppendChild($element) | Out-Null
                    }
                    
                    ConvertTo-XmlElement $exportData "Data" $xmlDoc $root
                    $outputContent = $xmlDoc.OuterXml
                }
                
                'CSV' {
                    Write-Verbose "Converting to CSV format (flattened)"
                    # For CSV, we'll create a flattened view focusing on modules and their relationships
                    $csvData = @()
                    
                    if ($exportData.ContainsKey('Modules') -and $exportData.ContainsKey('PheromoneTrails')) {
                        foreach ($moduleId in $exportData.Modules.Keys) {
                            $module = $exportData.Modules[$moduleId]
                            
                            # Find incoming and outgoing trails
                            $incomingTrails = $exportData.PheromoneTrails.Values | Where-Object { $_.ToModule -eq $moduleId }
                            $outgoingTrails = $exportData.PheromoneTrails.Values | Where-Object { $_.FromModule -eq $moduleId }
                            
                            $csvData += [PSCustomObject]@{
                                ModuleId = $moduleId
                                Title = $module.Title
                                Difficulty = $module.Difficulty
                                EstimatedTime = $module.EstimatedTime
                                Category = $module.Category
                                Prerequisites = ($module.Prerequisites -join ';')
                                Tags = ($module.Tags -join ';')
                                IncomingTrails = $incomingTrails.Count
                                OutgoingTrails = $outgoingTrails.Count
                                AvgIncomingStrength = if ($incomingTrails) { [Math]::Round(($incomingTrails.TrailStrength | Measure-Object -Average).Average, 4) } else { 0 }
                                AvgOutgoingStrength = if ($outgoingTrails) { [Math]::Round(($outgoingTrails.TrailStrength | Measure-Object -Average).Average, 4) } else { 0 }
                            }
                        }
                    }
                    
                    $outputContent = $csvData | ConvertTo-Csv -NoTypeInformation | Out-String
                }
                
                'GraphML' {
                    Write-Verbose "Converting to GraphML format"
                    $graphML = @"
<?xml version="1.0" encoding="UTF-8"?>
<graphml xmlns="http://graphml.graphdrawing.org/xmlns"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://graphml.graphdrawing.org/xmlns
         http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd">
  
  <!-- Data schema -->
  <key id="title" for="node" attr.name="title" attr.type="string"/>
  <key id="difficulty" for="node" attr.name="difficulty" attr.type="int"/>
  <key id="category" for="node" attr.name="category" attr.type="string"/>
  <key id="pheromone" for="edge" attr.name="pheromone" attr.type="double"/>
  <key id="strength" for="edge" attr.name="strength" attr.type="double"/>
  <key id="traversals" for="edge" attr.name="traversals" attr.type="int"/>
  
  <graph id="LearningGraph" edgedefault="directed">
"@
                    
                    # Add nodes
                    if ($exportData.ContainsKey('Modules')) {
                        foreach ($moduleId in $exportData.Modules.Keys) {
                            $module = $exportData.Modules[$moduleId]
                            $graphML += @"
    <node id="$moduleId">
      <data key="title">$([System.Security.SecurityElement]::Escape($module.Title))</data>
      <data key="difficulty">$($module.Difficulty)</data>
      <data key="category">$([System.Security.SecurityElement]::Escape($module.Category))</data>
    </node>
"@
                        }
                    }
                    
                    # Add edges
                    if ($exportData.ContainsKey('PheromoneTrails')) {
                        foreach ($trailKey in $exportData.PheromoneTrails.Keys) {
                            $trail = $exportData.PheromoneTrails[$trailKey]
                            $graphML += @"
    <edge source="$($trail.FromModule)" target="$($trail.ToModule)">
      <data key="pheromone">$($trail.PheromoneLevel)</data>
      <data key="strength">$($trail.TrailStrength)</data>
      <data key="traversals">$($trail.TraversalCount)</data>
    </edge>
"@
                        }
                    }
                    
                    $graphML += @"
  </graph>
</graphml>
"@
                    $outputContent = $graphML
                }
                
                'DOT' {
                    Write-Verbose "Converting to DOT format (Graphviz)"
                    $dot = @"
digraph LearningGraph {
    rankdir=TB;
    node [shape=box, style=rounded];
    edge [fontsize=8];
    
"@
                    
                    # Add nodes
                    if ($exportData.ContainsKey('Modules')) {
                        foreach ($moduleId in $exportData.Modules.Keys) {
                            $module = $exportData.Modules[$moduleId]
                            $color = switch ($module.Difficulty) {
                                1 { "lightgreen" }
                                2 { "yellow" }  
                                3 { "orange" }
                                4 { "red" }
                                5 { "darkred" }
                                default { "gray" }
                            }
                            
                            $label = "$($module.Title)\nDiff: $($module.Difficulty)"
                            $dot += "    `"$moduleId`" [label=`"$label`", fillcolor=$color, style=`"rounded,filled`"];" + [Environment]::NewLine
                        }
                    }
                    
                    # Add edges
                    if ($exportData.ContainsKey('PheromoneTrails')) {
                        foreach ($trailKey in $exportData.PheromoneTrails.Keys) {
                            $trail = $exportData.PheromoneTrails[$trailKey]
                            $weight = [Math]::Max(1, [Math]::Round($trail.TrailStrength * 10, 0))
                            $dot += "    `"$($trail.FromModule)`" -> `"$($trail.ToModule)`" [penwidth=$weight, label=`"$([Math]::Round($trail.PheromoneLevel, 3))`"];" + [Environment]::NewLine
                        }
                    }
                    
                    $dot += "}"
                    $outputContent = $dot
                }
                
                'YAML' {
                    Write-Verbose "Converting to YAML format"
                    # Simple YAML conversion (PowerShell doesn't have native YAML support)
                    function ConvertTo-Yaml($obj, $indent = 0) {
                        $spaces = " " * $indent
                        $result = ""
                        
                        if ($obj -is [hashtable] -or $obj -is [System.Collections.Specialized.OrderedDictionary]) {
                            foreach ($key in $obj.Keys) {
                                $result += "$spaces${key}:" + [Environment]::NewLine
                                $result += ConvertTo-Yaml $obj[$key] ($indent + 2)
                            }
                        }
                        elseif ($obj -is [array]) {
                            foreach ($item in $obj) {
                                $result += "$spaces- " + [Environment]::NewLine
                                $result += ConvertTo-Yaml $item ($indent + 2)
                            }
                        }
                        else {
                            $result += "$spaces$obj" + [Environment]::NewLine
                        }
                        
                        return $result
                    }
                    
                    $outputContent = ConvertTo-Yaml $exportData
                }
            }
            
            # Write to file
            Write-Verbose "Writing output to file: $OutputPath"
            $outputContent | Out-File -FilePath $OutputPath -Encoding UTF8 -Force
            
            # Compress if requested
            if ($Compress) {
                Write-Verbose "Compressing output file"
                $compressedPath = "$OutputPath.zip"
                
                Add-Type -AssemblyName System.IO.Compression.FileSystem
                [System.IO.Compression.ZipFile]::CreateFromDirectory((Split-Path $OutputPath), $compressedPath)
                
                Remove-Item $OutputPath -Force
                $OutputPath = $compressedPath
            }
            
            $result = [PSCustomObject]@{
                OutputPath = $OutputPath
                Format = $Format
                DataTypes = $DataTypes
                FileSize = (Get-Item $OutputPath).Length
                RecordCount = switch ($Format) {
                    'CSV' { $csvData.Count }
                    default { 
                        if ($exportData.ContainsKey('Modules')) { $exportData.Modules.Count }
                        else { "N/A" }
                    }
                }
                ExportedAt = Get-Date
                Success = $true
            }
            
            Write-Output $result
            Write-Host "Successfully exported learning graph to: $OutputPath" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to export learning graph: $($_.Exception.Message)"
            throw
        }
    }
}

# Create aliases
New-Alias -Name "Export-Graph" -Value "Export-LearningGraph" -Force
