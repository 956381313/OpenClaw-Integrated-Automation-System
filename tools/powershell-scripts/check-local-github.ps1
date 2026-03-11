# Check for local GitHub services

Write-Host "=== Checking Local GitHub Services ===" -ForegroundColor Cyan

# Common ports for GitHub services
$ports = @(3000, 80, 8080, 5000, 9000, 3001, 3002)

foreach ($port in $ports) {
    $url = "http://localhost:$port"
    try {
        $response = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 2 -ErrorAction Stop
        Write-Host "✅ Port $port: Service running ($url)" -ForegroundColor Green
        Write-Host "   Status: $($response.StatusCode) $($response.StatusDescription)" -ForegroundColor Gray
        
        # Try to get more info
        try {
            $content = Invoke-WebRequest -Uri $url -TimeoutSec 2
            if ($content.Content -match "GitHub|git|repository") {
                Write-Host "   Likely GitHub service" -ForegroundColor Green
            }
        } catch {
            # Ignore content errors
        }
        
    } catch {
        # Service not running on this port
    }
}

# Check for Git services
Write-Host "`n=== Checking Git Services ===" -ForegroundColor Cyan

# Check if git is installed
try {
    $gitVersion = git --version
    Write-Host "✅ Git installed: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Git not installed" -ForegroundColor Red
}

# Check for local Git repositories
Write-Host "`n=== Checking Local Git Repositories ===" -ForegroundColor Cyan

$localRepos = Get-ChildItem -Path "C:\" -Directory -Depth 2 -Filter ".git" -ErrorAction SilentlyContinue | Select-Object -First 5

if ($localRepos) {
    Write-Host "Found local Git repositories:" -ForegroundColor Green
    foreach ($repo in $localRepos) {
        $repoPath = $repo.FullName.Replace("\.git", "")
        Write-Host "  📁 $repoPath" -ForegroundColor Gray
    }
} else {
    Write-Host "No local Git repositories found" -ForegroundColor Yellow
}

# Check for GitHub Desktop
Write-Host "`n=== Checking GitHub Desktop ===" -ForegroundColor Cyan

$ghDesktopPaths = @(
    "$env:LOCALAPPDATA\GitHubDesktop",
    "$env:PROGRAMFILES\GitHub Desktop",
    "$env:PROGRAMFILES(X86)\GitHub Desktop"
)

foreach ($path in $ghDesktopPaths) {
    if (Test-Path $path) {
        Write-Host "✅ GitHub Desktop found: $path" -ForegroundColor Green
    }
}

# Check for GitLab or other Git services
Write-Host "`n=== Checking Other Git Services ===" -ForegroundColor Cyan

$services = Get-Service -ErrorAction SilentlyContinue | Where-Object {
    $_.Name -match "git|github|gitea|gitlab" -or 
    $_.DisplayName -match "git|github|gitea|gitlab"
}

if ($services) {
    Write-Host "Found Git-related services:" -ForegroundColor Green
    foreach ($service in $services) {
        Write-Host "  🛠️ $($service.DisplayName) ($($service.Name)): $($service.Status)" -ForegroundColor Gray
    }
} else {
    Write-Host "No Git-related services found" -ForegroundColor Yellow
}

Write-Host "`n=== Recommendations ===" -ForegroundColor Cyan
Write-Host "1. If you're running GitHub Desktop, it doesn't provide a web interface" -ForegroundColor Gray
Write-Host "2. If you want local Git server, consider:" -ForegroundColor Gray
Write-Host "   - Gitea (lightweight)" -ForegroundColor Gray
Write-Host "   - GitLab CE" -ForegroundColor Gray
Write-Host "   - Bonobo Git Server" -ForegroundColor Gray
Write-Host "3. For backup, you can use local Git repositories without web interface" -ForegroundColor Gray