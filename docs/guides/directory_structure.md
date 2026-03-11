# Workspace Directory Structure
# Reorganized on: 2026-03-09

## New Structure:

\\\
workspace/
鈹溾攢鈹€ core/                    # Core configuration files
鈹?  鈹溾攢鈹€ identity/           # Identity and user profiles
鈹?  鈹溾攢鈹€ skills/             # Agent skills and capabilities
鈹?  鈹斺攢鈹€ references/         # Reference materials
鈹?鈹溾攢鈹€ docs/                   # Documentation
鈹?  鈹溾攢鈹€ guides/            # How-to guides and tutorials
鈹?  鈹溾攢鈹€ policies/          # Security policies and procedures
鈹?  鈹斺攢鈹€ references/        # Technical references
鈹?鈹溾攢鈹€ scripts/               # Scripts and automation
鈹?  鈹溾攢鈹€ security/         # Security-related scripts
鈹?  鈹溾攢鈹€ utilities/        # Utility scripts
鈹?  鈹斺攢鈹€ maintenance/      # System maintenance scripts
鈹?鈹溾攢鈹€ data/                  # Data files
鈹?  鈹溾攢鈹€ logs/             # Log files
鈹?  鈹溾攢鈹€ backups/          # Backup files
鈹?  鈹斺攢鈹€ temp/             # Temporary files
鈹?鈹溾攢鈹€ projects/              # Project files (if any)
鈹?鈹溾攢鈹€ archive/               # Archived files
鈹?  鈹溾攢鈹€ old-scripts/      # Old script versions
鈹?  鈹斺攢鈹€ deprecated/       # Deprecated files
鈹?鈹斺攢鈹€ [other directories]    # Remaining directories
\\\

## Files Moved:

### Security Files 鈫?scripts\security\
- Security-related scripts and documentation
- Encryption tools
- Security policies

### Implementation Scripts 鈫?scripts\maintenance\
- System organization scripts
- Cleanup and maintenance scripts
- Backup scripts

### Logs 鈫?data\logs\
- Operation logs
- Cleanup logs
- System logs

## Notes:
1. Core configuration files (SOUL.md, USER.md, etc.) remain in workspace root
2. Backup directory contains pre-reorganization backup
3. Old directory structure preserved in backup
4. All moves logged in data\logs\organization\

## Maintenance:
- Regular cleanup of data\temp\
- Archive old files to archive\ directory
- Update this document when structure changes
