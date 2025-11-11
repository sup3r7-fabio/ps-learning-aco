<#
.SYNOPSIS
    Retrieve and display learning content for a specific PSLearningACO module.

.DESCRIPTION
    Gets content from the ps-learning-aco-content repository including lessons,
    exercises, quizzes, and solutions. Supports interactive viewing and file export.

.PARAMETER ModuleId
    The module identifier (e.g., "PS-Basics", "PS-Functions", "PS-Objects").
    Must match a module in the content repository.

.PARAMETER ContentType
    Type of content to retrieve:
    - "lesson" - Markdown learning material
    - "exercises" - PowerShell practice exercises
    - "quiz" - JSON quiz questions and answers
    - "solutions" - Complete exercise solutions with explanations
    
.PARAMETER Display
    If specified, displays content in console. Default is to return object.

.PARAMETER OutputPath
    Optional path to export content to a file.

.EXAMPLE
    Get-ModuleContent -ModuleId "PS-Basics" -ContentType "lesson" -Display
    
    Retrieves and displays the PS-Basics lesson material.

.EXAMPLE
    Get-ModuleContent -ModuleId "PS-Functions" -ContentType "exercises"
    
    Retrieves the PS-Functions exercise file as an object.

.EXAMPLE
    Get-ModuleContent -ModuleId "PS-Basics" -ContentType "quiz" -OutputPath "quiz.json"
    
    Exports the PS-Basics quiz to a file.

.NOTES
    This cmdlet requires the ps-learning-aco-content repository to be present.
    Default search path: $env:PSLearningACOContentPath or module directory + "/Content"
    
    Content repository: https://github.com/sup3r7-fabio/ps-learning-aco-content

.LINK
    https://github.com/sup3r7-fabio/ps-learning-aco-content
#>

function Get-ModuleContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleId,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("lesson", "exercises", "quiz", "solutions")]
        [string]$ContentType,
        
        [switch]$Display,
        
        [string]$OutputPath
    )
    
    process {
        try {
            # Determine content base path
            $contentBasePath = $null
            
            # Check environment variable first
            if ($env:PSLearningACOContentPath) {
                $contentBasePath = $env:PSLearningACOContentPath
            }
            # Check relative to module
            elseif (Test-Path (Join-Path -Path $PSScriptRoot -ChildPath "../Content")) {
                $contentBasePath = Join-Path -Path $PSScriptRoot -ChildPath "../Content"
            }
            # Check common locations
            else {
                $possiblePaths = @(
                    "$HOME\ps-learning-aco-content",
                    "$HOME\Documents\ps-learning-aco-content",
                    ".\ps-learning-aco-content",
                    "../ps-learning-aco-content"
                )
                
                foreach ($path in $possiblePaths) {
                    if (Test-Path -Path $path) {
                        $contentBasePath = $path
                        break
                    }
                }
            }
            
            if (-not $contentBasePath) {
                throw "Could not locate ps-learning-aco-content repository. Set `$env:PSLearningACOContentPath environment variable or place content repository in a standard location."
            }
            
            # Build file path based on content type
            $fileName = switch ($ContentType) {
                "lesson"     { "lesson.md" }
                "exercises"  { "exercises.ps1" }
                "quiz"       { "quiz.json" }
                "solutions"  { "solutions.ps1" }
            }
            
            $contentPath = Join-Path -Path $contentBasePath -ChildPath $ModuleId | Join-Path -ChildPath $fileName
            
            # Verify file exists
            if (-not (Test-Path -Path $contentPath)) {
                throw "Content not found: $ModuleId\$fileName at $contentPath"
            }
            
            # Read content
            $content = Get-Content -Path $contentPath -Raw
            
            # Parse based on type
            $result = $null
            switch ($ContentType) {
                "lesson" {
                    $result = @{
                        ModuleId = $ModuleId
                        ContentType = $ContentType
                        FilePath = $contentPath
                        Content = $content
                        Type = "Markdown"
                    }
                }
                "exercises" {
                    $result = @{
                        ModuleId = $ModuleId
                        ContentType = $ContentType
                        FilePath = $contentPath
                        Content = $content
                        Type = "PowerShell"
                    }
                }
                "quiz" {
                    $jsonContent = $content | ConvertFrom-Json
                    $result = @{
                        ModuleId = $ModuleId
                        ContentType = $ContentType
                        FilePath = $contentPath
                        QuizData = $jsonContent
                        TotalQuestions = $jsonContent.totalQuestions
                        PassingScore = $jsonContent.passingScore
                        Type = "JSON"
                    }
                }
                "solutions" {
                    $result = @{
                        ModuleId = $ModuleId
                        ContentType = $ContentType
                        FilePath = $contentPath
                        Content = $content
                        Type = "PowerShell"
                    }
                }
            }
            
            # Export to file if specified
            if ($OutputPath) {
                switch ($ContentType) {
                    "quiz" {
                        $result.QuizData | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
                    }
                    default {
                        $content | Out-File -FilePath $OutputPath -Encoding UTF8
                    }
                }
                Write-Verbose "Content exported to: $OutputPath"
            }
            
            # Display if requested
            if ($Display) {
                switch ($ContentType) {
                    "quiz" {
                        Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
                        Write-Host "║  $($ModuleId) - Quiz Assessment" -ForegroundColor Cyan
                        Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
                        Write-Host ""
                        Write-Host "Module: $($result.QuizData.moduleName)" -ForegroundColor Yellow
                        Write-Host "Description: $($result.QuizData.description)" -ForegroundColor Gray
                        Write-Host "Total Questions: $($result.TotalQuestions)"
                        Write-Host "Passing Score: $($result.PassingScore)%"
                        Write-Host "Time Limit: $($result.QuizData.timeLimit) minutes"
                        Write-Host ""
                        Write-Host "Questions included:" -ForegroundColor Green
                        foreach ($q in $result.QuizData.questions) {
                            $difficulty = $q.difficulty.ToUpper()
                            Write-Host "  [$difficulty] Q$($q.id): $($q.question)" -ForegroundColor Gray
                        }
                    }
                    default {
                        Write-Host $result.Content
                    }
                }
            }
            else {
                # Return object
                [PSCustomObject]$result
            }
        }
        catch {
            Write-Error "Error retrieving module content: $($_.Exception.Message)"
        }
    }
}

Export-ModuleMember -Function Get-ModuleContent
