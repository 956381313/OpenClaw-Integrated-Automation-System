# Weather Skill Demo
Write-Host "=== WEATHER SKILL DEMONSTRATION ===" -ForegroundColor Cyan
Write-Host "Skill: Weather Query (no API key needed)" -ForegroundColor Gray
Write-Host "Service: wttr.in" -ForegroundColor Gray
Write-Host ""

# Demo 1: Simple weather for Beijing
Write-Host "1. CURRENT WEATHER - BEIJING" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "https://wttr.in/Beijing?format=3" -UseBasicParsing -ErrorAction Stop
    Write-Host "   Result: $($response.Content.Trim())" -ForegroundColor Green
} catch {
    Write-Host "   Error: $_" -ForegroundColor Red
}
Write-Host ""

# Demo 2: Detailed weather for Shanghai
Write-Host "2. DETAILED WEATHER - SHANGHAI" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "https://wttr.in/Shanghai?format=%l:+%c+%t+%h+%w" -UseBasicParsing -ErrorAction Stop
    Write-Host "   Result: $($response.Content.Trim())" -ForegroundColor Green
    Write-Host "   Format: Location: Condition Temperature Humidity Wind" -ForegroundColor Gray
} catch {
    Write-Host "   Error: $_" -ForegroundColor Red
}
Write-Host ""

# Demo 3: Weather with metric units
Write-Host "3. WEATHER WITH METRIC UNITS - TOKYO" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "https://wttr.in/Tokyo?format=3&m" -UseBasicParsing -ErrorAction Stop
    Write-Host "   Result: $($response.Content.Trim())" -ForegroundColor Green
    Write-Host "   Note: Using metric units (?m parameter)" -ForegroundColor Gray
} catch {
    Write-Host "   Error: $_" -ForegroundColor Red
}
Write-Host ""

# Demo 4: Today's forecast only
Write-Host "4. TODAY'S FORECAST - LONDON" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "https://wttr.in/London?format=3&1" -UseBasicParsing -ErrorAction Stop
    Write-Host "   Result: $($response.Content.Trim())" -ForegroundColor Green
    Write-Host "   Note: Today only (?1 parameter)" -ForegroundColor Gray
} catch {
    Write-Host "   Error: $_" -ForegroundColor Red
}
Write-Host ""

# Demo 5: Custom location with spaces
Write-Host "5. CUSTOM LOCATION - NEW YORK" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "https://wttr.in/New+York?format=3" -UseBasicParsing -ErrorAction Stop
    Write-Host "   Result: $($response.Content.Trim())" -ForegroundColor Green
    Write-Host "   Note: Spaces encoded as +" -ForegroundColor Gray
} catch {
    Write-Host "   Error: $_" -ForegroundColor Red
}
Write-Host ""

# Demo 6: Airport code weather
Write-Host "6. AIRPORT WEATHER - JFK AIRPORT" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "https://wttr.in/JFK?format=3" -UseBasicParsing -ErrorAction Stop
    Write-Host "   Result: $($response.Content.Trim())" -ForegroundColor Green
    Write-Host "   Note: Using airport code JFK" -ForegroundColor Gray
} catch {
    Write-Host "   Error: $_" -ForegroundColor Red
}
Write-Host ""

# Summary of wttr.in format codes
Write-Host "=== WTTR.IN FORMAT CODES ===" -ForegroundColor Cyan
Write-Host "%c - Weather condition (emoji)" -ForegroundColor Gray
Write-Host "%t - Temperature" -ForegroundColor Gray
Write-Host "%h - Humidity" -ForegroundColor Gray
Write-Host "%w - Wind speed and direction" -ForegroundColor Gray
Write-Host "%l - Location name" -ForegroundColor Gray
Write-Host "%m - Moon phase" -ForegroundColor Gray
Write-Host ""

Write-Host "=== WEATHER SKILL USAGE ===" -ForegroundColor Cyan
Write-Host "Basic usage:" -ForegroundColor Yellow
Write-Host "  curl wttr.in/London?format=3" -ForegroundColor Gray
Write-Host ""
Write-Host "Advanced usage:" -ForegroundColor Yellow
Write-Host "  curl wttr.in/London?format=%l:+%c+%t+%h+%w" -ForegroundColor Gray
Write-Host "  curl wttr.in/New+York?format=3&m" -ForegroundColor Gray
Write-Host "  curl wttr.in/JFK?format=3&1" -ForegroundColor Gray
Write-Host ""
Write-Host "Alternative service (JSON):" -ForegroundColor Yellow
Write-Host "  curl https://api.open-meteo.com/v1/forecast?latitude=51.5&longitude=-0.12&current_weather=true" -ForegroundColor Gray
Write-Host ""
Write-Host "Skill demonstration completed!" -ForegroundColor Green