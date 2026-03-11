# Skill Creator Demonstration
Write-Host "=== SKILL CREATOR DEMONSTRATION ===" -ForegroundColor Cyan
Write-Host "Skill: Skill Creator - Create or update agent skills" -ForegroundColor Gray
Write-Host ""

# Show skill creator documentation
Write-Host "1. SKILL CREATOR OVERVIEW" -ForegroundColor Yellow
Write-Host "   Purpose: Create or update agent skills with scripts, references, and resources" -ForegroundColor Gray
Write-Host "   Trigger: When designing, building, or packaging skills" -ForegroundColor Gray
Write-Host ""

# Show skill structure
Write-Host "2. SKILL STRUCTURE" -ForegroundColor Yellow
Write-Host "   A skill consists of:" -ForegroundColor Gray
Write-Host "   📁 skill-name/" -ForegroundColor Gray
Write-Host "   ├── 📄 SKILL.md          # Skill documentation" -ForegroundColor Gray
Write-Host "   ├── 📁 references/       # Reference files" -ForegroundColor Gray
Write-Host "   ├── 📁 scripts/          # Script files" -ForegroundColor Gray
Write-Host "   └── 📁 resources/        # Resource files" -ForegroundColor Gray
Write-Host ""

# Show SKILL.md template
Write-Host "3. SKILL.MD TEMPLATE" -ForegroundColor Yellow
$skillTemplate = @'
---
name: Skill Name
description: Brief description of what the skill does.
metadata: {"clawdbot":{"emoji":"🔧","requires":{"bins":["tool1","tool2"]}}}
---

# Skill Name

Detailed documentation goes here.

## Usage

```bash
# Example commands
tool1 --option value
tool2 --flag
```

## Examples

1. Example scenario 1
2. Example scenario 2

## References

- [Documentation](https://example.com)
- [GitHub](https://github.com/example)
'@

Write-Host $skillTemplate -ForegroundColor Gray
Write-Host ""

# Demonstrate creating a simple skill
Write-Host "4. CREATING A SIMPLE SKILL" -ForegroundColor Yellow
Write-Host "   Let's create a 'file-counter' skill:" -ForegroundColor Gray
Write-Host ""

$fileCounterSkill = @'
# File Counter Skill

Count files in a directory with various filters.

## Usage

```bash
# Count all files
file-counter --dir /path/to/dir

# Count by extension
file-counter --dir /path/to/dir --ext .txt

# Count by size
file-counter --dir /path/to/dir --min-size 1MB

# Count by date
file-counter --dir /path/to/dir --newer-than 7d
```

## Examples

1. Count all PDF files in Downloads:
   ```bash
   file-counter --dir ~/Downloads --ext .pdf
   ```

2. Count large files (>100MB) in current directory:
   ```bash
   file-counter --dir . --min-size 100MB
   ```

3. Count files modified today:
   ```bash
   file-counter --dir . --newer-than 1d
   ```
'@

Write-Host $fileCounterSkill -ForegroundColor Gray
Write-Host ""

# Show metadata options
Write-Host "5. METADATA OPTIONS" -ForegroundColor Yellow
Write-Host "   Common metadata fields:" -ForegroundColor Gray
Write-Host "   - emoji: Skill icon (e.g., '🔧', '📁', '🔍')" -ForegroundColor Gray
Write-Host "   - requires.bins: Required binaries" -ForegroundColor Gray
Write-Host "   - requires.config: Required configuration" -ForegroundColor Gray
Write-Host "   - install: Installation instructions" -ForegroundColor Gray
Write-Host "   - os: Supported operating systems" -ForegroundColor Gray
Write-Host ""

# Show installation metadata
Write-Host "6. INSTALLATION METADATA" -ForegroundColor Yellow
$installMetadata = @'
"install": [
  {
    "id": "brew",
    "kind": "brew",
    "formula": "tool-name",
    "bins": ["tool"],
    "label": "Install via Homebrew"
  },
  {
    "id": "apt",
    "kind": "apt",
    "package": "tool-name",
    "bins": ["tool"],
    "label": "Install via apt"
  },
  {
    "id": "npm",
    "kind": "node",
    "package": "tool-name",
    "bins": ["tool"],
    "label": "Install via npm"
  }
]
'@

Write-Host $installMetadata -ForegroundColor Gray
Write-Host ""

# Practical example: Creating a skill directory
Write-Host "7. PRACTICAL EXAMPLE" -ForegroundColor Yellow
Write-Host "   Creating a skill directory structure:" -ForegroundColor Gray
Write-Host "   mkdir -p file-counter/{references,scripts,resources}" -ForegroundColor Gray
Write-Host "   touch file-counter/SKILL.md" -ForegroundColor Gray
Write-Host "   echo '#!/bin/bash' > file-counter/scripts/count-files.sh" -ForegroundColor Gray
Write-Host "   chmod +x file-counter/scripts/count-files.sh" -ForegroundColor Gray
Write-Host ""

# Publishing skills
Write-Host "8. PUBLISHING SKILLS" -ForegroundColor Yellow
Write-Host "   Use clawdhub to publish skills:" -ForegroundColor Gray
Write-Host "   clawdhub publish ./file-counter" -ForegroundColor Gray
Write-Host "   clawdhub search file-counter" -ForegroundColor Gray
Write-Host ""

Write-Host "=== SKILL CREATOR DEMO COMPLETE ===" -ForegroundColor Cyan
Write-Host "You can now create your own skills using this structure!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "   1. Design your skill's functionality" -ForegroundColor Gray
Write-Host "   2. Create the directory structure" -ForegroundColor Gray
Write-Host "   3. Write SKILL.md documentation" -ForegroundColor Gray
Write-Host "   4. Add scripts and references" -ForegroundColor Gray
Write-Host "   5. Test the skill locally" -ForegroundColor Gray
Write-Host "   6. Publish with clawdhub" -ForegroundColor Gray