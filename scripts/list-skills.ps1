# List all available skills
Write-Host "=== LISTING ALL AVAILABLE SKILLS ===" -ForegroundColor Cyan
Write-Host ""

# Check skills directory
$skillsPath = "C:\Users\luchaochao\AppData\Roaming\npm\node_modules\openclaw-cn\skills"
if (Test-Path $skillsPath) {
    Write-Host "Skills directory found:" -ForegroundColor Green
    Write-Host "  $skillsPath" -ForegroundColor Gray
    Write-Host ""
    
    # Get all skill directories
    $skillDirs = Get-ChildItem -Path $skillsPath -Directory -ErrorAction SilentlyContinue
    
    if ($skillDirs.Count -gt 0) {
        Write-Host "Total skills found: $($skillDirs.Count)" -ForegroundColor Green
        Write-Host ""
        
        # Group skills by category
        Write-Host "=== SKILLS BY CATEGORY ===" -ForegroundColor Yellow
        Write-Host ""
        
        # Productivity & Notes
        Write-Host "1. PRODUCTIVITY & NOTES" -ForegroundColor Cyan
        $productivity = $skillDirs | Where-Object { 
            $_.Name -match "notes|reminders|task|todo|notion|obsidian|bear|apple"
        }
        foreach ($skill in $productivity | Sort-Object Name) {
            Write-Host "  • $($skill.Name)" -ForegroundColor Gray
        }
        Write-Host ""
        
        # Communication & Social
        Write-Host "2. COMMUNICATION & SOCIAL" -ForegroundColor Cyan
        $communication = $skillDirs | Where-Object {
            $_.Name -match "email|imessage|whatsapp|slack|twitter|bird|feishu|message"
        }
        foreach ($skill in $communication | Sort-Object Name) {
            Write-Host "  • $($skill.Name)" -ForegroundColor Gray
        }
        Write-Host ""
        
        # Development & Coding
        Write-Host "3. DEVELOPMENT & CODING" -ForegroundColor Cyan
        $development = $skillDirs | Where-Object {
            $_.Name -match "github|git|code|programming|agent|claude|oracle|mcp"
        }
        foreach ($skill in $development | Sort-Object Name) {
            Write-Host "  • $($skill.Name)" -ForegroundColor Gray
        }
        Write-Host ""
        
        # System & Automation
        Write-Host "4. SYSTEM & AUTOMATION" -ForegroundColor Cyan
        $system = $skillDirs | Where-Object {
            $_.Name -match "automation|backup|security|monitor|organize|cleanup|duplicate"
        }
        foreach ($skill in $system | Sort-Object Name) {
            Write-Host "  • $($skill.Name)" -ForegroundColor Gray
        }
        Write-Host ""
        
        # Media & Entertainment
        Write-Host "5. MEDIA & ENTERTAINMENT" -ForegroundColor Cyan
        $media = $skillDirs | Where-Object {
            $_.Name -match "music|spotify|sonos|blu|audio|video|gif|image|tts|voice"
        }
        foreach ($skill in $media | Sort-Object Name) {
            Write-Host "  • $($skill.Name)" -ForegroundColor Gray
        }
        Write-Host ""
        
        # AI & Models
        Write-Host "6. AI & MODELS" -ForegroundColor Cyan
        $ai = $skillDirs | Where-Object {
            $_.Name -match "ai|model|gemini|openai|whisper|transcribe|summary|claude"
        }
        foreach ($skill in $ai | Sort-Object Name) {
            Write-Host "  • $($skill.Name)" -ForegroundColor Gray
        }
        Write-Host ""
        
        # Hardware & IoT
        Write-Host "7. HARDWARE & IOT" -ForegroundColor Cyan
        $hardware = $skillDirs | Where-Object {
            $_.Name -match "camera|hue|light|sonos|blu|sleep|eight|tmux|peekaboo"
        }
        foreach ($skill in $hardware | Sort-Object Name) {
            Write-Host "  • $($skill.Name)" -ForegroundColor Gray
        }
        Write-Host ""
        
        # Tools & Utilities
        Write-Host "8. TOOLS & UTILITIES" -ForegroundColor Cyan
        $tools = $skillDirs | Where-Object {
            $_.Name -match "tool|utility|1password|weather|places|search|browser|canvas"
        }
        foreach ($skill in $tools | Sort-Object Name) {
            Write-Host "  • $($skill.Name)" -ForegroundColor Gray
        }
        Write-Host ""
        
        # Complete alphabetical list
        Write-Host "=== COMPLETE ALPHABETICAL LIST ===" -ForegroundColor Yellow
        Write-Host ""
        
        $counter = 1
        foreach ($skill in $skillDirs | Sort-Object Name) {
            # Try to read skill description
            $skillFile = Join-Path $skill.FullName "SKILL.md"
            $description = ""
            
            if (Test-Path $skillFile) {
                try {
                    $content = Get-Content $skillFile -First 3 -ErrorAction SilentlyContinue
                    if ($content -match "description" -or $content -match "Description") {
                        $description = ($content | Select-String "description" -SimpleMatch | ForEach-Object { $_.Line }) -replace ".*description", ""
                        $description = $description.Trim()
                    }
                } catch {
                    # Ignore errors
                }
            }
            
            if ($description -and $description.Length -gt 0) {
                Write-Host "  $counter. $($skill.Name) - $description" -ForegroundColor Gray
            } else {
                Write-Host "  $counter. $($skill.Name)" -ForegroundColor Gray
            }
            $counter++
        }
        
        Write-Host ""
        Write-Host "Total: $($skillDirs.Count) skills available" -ForegroundColor Green
        
    } else {
        Write-Host "No skills found in directory" -ForegroundColor Yellow
    }
    
} else {
    Write-Host "Skills directory not found:" -ForegroundColor Red
    Write-Host "  $skillsPath" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Checking alternative locations..." -ForegroundColor Yellow
    
    # Check common locations
    $altPaths = @(
        "C:\Program Files\nodejs\node_modules\openclaw-cn\skills",
        "C:\Program Files (x86)\nodejs\node_modules\openclaw-cn\skills",
        "$env:USERPROFILE\.openclaw\skills",
        "$env:USERPROFILE\AppData\Local\npm\node_modules\openclaw-cn\skills"
    )
    
    foreach ($path in $altPaths) {
        if (Test-Path $path) {
            Write-Host "Found at: $path" -ForegroundColor Green
            $skillsPath = $path
            break
        }
    }
}

Write-Host ""
Write-Host "=== SKILLS SUMMARY ===" -ForegroundColor Cyan
Write-Host "Use skills by checking the available_skills section in your prompt." -ForegroundColor Gray
Write-Host "Each skill has a SKILL.md file with detailed instructions." -ForegroundColor Gray
Write-Host ""
Write-Host "To use a skill:" -ForegroundColor Yellow
Write-Host "  1. Check if the skill is listed in available_skills" -ForegroundColor Gray
Write-Host "  2. Read the skill's SKILL.md file for instructions" -ForegroundColor Gray
Write-Host "  3. Follow the skill-specific guidelines" -ForegroundColor Gray