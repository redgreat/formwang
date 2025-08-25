# Multi-version Erlang environment Elixir fix script
Write-Host "Detecting multi-version Erlang environment, starting deep fix..." -ForegroundColor Yellow

# Show current version info
Write-Host "`nCurrent environment info:" -ForegroundColor Cyan
Write-Host "Erlang version:" -ForegroundColor White
erl -version
Write-Host "`nElixir version:" -ForegroundColor White
elixir --version

# Stop all possible Erlang processes
Write-Host "`nStopping all Erlang processes..." -ForegroundColor Yellow
Get-Process | Where-Object {$_.ProcessName -match "erl|beam|epmd"} | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# Clean project build cache
Write-Host "Cleaning project build cache..." -ForegroundColor Yellow
if (Test-Path "_build") {
    Remove-Item -Recurse -Force "_build" -ErrorAction SilentlyContinue
    Write-Host "Deleted _build directory" -ForegroundColor Green
}

if (Test-Path "deps") {
    Remove-Item -Recurse -Force "deps" -ErrorAction SilentlyContinue
    Write-Host "Deleted deps directory" -ForegroundColor Green
}

# Clean Mix build cache
Write-Host "Cleaning Mix build cache..." -ForegroundColor Yellow
$mixHome = $env:MIX_HOME
if (-not $mixHome) {
    $mixHome = "$env:USERPROFILE\.mix"
}

if (Test-Path $mixHome) {
    $archivesPath = Join-Path $mixHome "archives"
    $buildCachePath = Join-Path $mixHome "build_cache"
    
    if (Test-Path $archivesPath) {
        Remove-Item -Recurse -Force $archivesPath -ErrorAction SilentlyContinue
        Write-Host "Cleaned Mix archives" -ForegroundColor Green
    }
    
    if (Test-Path $buildCachePath) {
        Remove-Item -Recurse -Force $buildCachePath -ErrorAction SilentlyContinue
        Write-Host "Cleaned Mix build cache" -ForegroundColor Green
    }
}

# Clean Erlang build cache
Write-Host "Cleaning Erlang build cache..." -ForegroundColor Yellow
$erlangCachePaths = @(
    "$env:USERPROFILE\.erlang",
    "$env:APPDATA\erlang",
    "$env:LOCALAPPDATA\erlang"
)

foreach ($path in $erlangCachePaths) {
    if (Test-Path $path) {
        Remove-Item -Recurse -Force $path -ErrorAction SilentlyContinue
        Write-Host "Cleaned $path" -ForegroundColor Green
    }
}

# Clean temp files
Write-Host "Cleaning temp files..." -ForegroundColor Yellow
$tempPaths = @(
    "$env:TEMP\erlang*",
    "$env:TEMP\elixir*",
    "$env:TEMP\beam*",
    "$env:TEMP\erl_*"
)

foreach ($pattern in $tempPaths) {
    Get-ChildItem -Path $env:TEMP -Filter ($pattern -replace '.*\\', '') -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}

# Reinstall Mix
Write-Host "Reinstalling Mix..." -ForegroundColor Yellow
try {
    mix local.hex --force 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Hex installed successfully" -ForegroundColor Green
    }
    
    mix local.rebar --force 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Rebar installed successfully" -ForegroundColor Green
    }
} catch {
    Write-Host "Mix tools installation failed, but continuing..." -ForegroundColor Yellow
}

# Set environment variables to avoid version conflicts
Write-Host "Setting environment variables..." -ForegroundColor Yellow
$env:ERL_LIBS = ""
$env:ERL_AFLAGS = ""
$env:ELIXIR_ERL_OPTIONS = ""

# Test basic functionality
Write-Host "`nTesting Elixir basic functionality..." -ForegroundColor Yellow
try {
    $testResult = elixir -e "IO.puts('Elixir basic functionality OK')" 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Elixir basic functionality test passed" -ForegroundColor Green
    } else {
        Write-Host "✗ Elixir basic functionality test failed" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Elixir basic functionality test exception" -ForegroundColor Red
}

# Test Mix functionality
Write-Host "Testing Mix functionality..." -ForegroundColor Yellow
try {
    $mixTest = mix help 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Mix functionality test passed" -ForegroundColor Green
    } else {
        Write-Host "✗ Mix functionality test failed" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Mix functionality test exception" -ForegroundColor Red
}

# Try to get dependencies again
Write-Host "`nTrying to get dependencies again..." -ForegroundColor Yellow
try {
    mix deps.get --force 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Dependencies retrieved successfully" -ForegroundColor Green
        
        # Try to compile
        Write-Host "Trying to compile project..." -ForegroundColor Yellow
        mix compile --force 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Project compiled successfully" -ForegroundColor Green
        } else {
            Write-Host "✗ Project compilation failed, but dependencies retrieved" -ForegroundColor Yellow
        }
    } else {
        Write-Host "✗ Dependencies retrieval failed" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Dependencies retrieval exception" -ForegroundColor Red
}

Write-Host "`nFix completed!" -ForegroundColor Green
Write-Host "If problems persist, suggest:" -ForegroundColor Yellow
Write-Host "1. Restart terminal" -ForegroundColor White
Write-Host "2. Check PATH environment variable for Erlang/Elixir paths" -ForegroundColor White
Write-Host "3. Consider using version management tools like asdf" -ForegroundColor White
Write-Host "4. Run mix phx.server to test project startup" -ForegroundColor White