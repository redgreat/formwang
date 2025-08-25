# Fix Mix environment issues with v3_core module
Write-Host "Fixing Mix environment issues..." -ForegroundColor Yellow

# Display current environment
Write-Host "`nCurrent environment:" -ForegroundColor Cyan
Write-Host "Erlang: $(erl -version 2>&1)" -ForegroundColor White
Write-Host "Elixir: $(elixir --version | Select-String 'Elixir')" -ForegroundColor White

# Stop all Erlang/Elixir processes
Write-Host "`nStopping all Erlang/Elixir processes..." -ForegroundColor Yellow
Get-Process | Where-Object {$_.ProcessName -match "erl|beam|epmd|mix|elixir"} | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3

# Clean all compilation artifacts
Write-Host "Cleaning all compilation artifacts..." -ForegroundColor Yellow
$cleanPaths = @(
    "_build",
    "deps",
    ".elixir_ls",
    "erl_crash.dump"
)

foreach ($path in $cleanPaths) {
    if (Test-Path $path) {
        Remove-Item -Recurse -Force $path -ErrorAction SilentlyContinue
        Write-Host "Removed $path" -ForegroundColor Green
    }
}

# Clean Mix home directory completely
Write-Host "Cleaning Mix home directory..." -ForegroundColor Yellow
$mixHome = if ($env:MIX_HOME) { $env:MIX_HOME } else { "$env:USERPROFILE\.mix" }
if (Test-Path $mixHome) {
    Remove-Item -Recurse -Force $mixHome -ErrorAction SilentlyContinue
    Write-Host "Removed Mix home: $mixHome" -ForegroundColor Green
}

# Clean Hex cache
Write-Host "Cleaning Hex cache..." -ForegroundColor Yellow
$hexHome = if ($env:HEX_HOME) { $env:HEX_HOME } else { "$env:USERPROFILE\.hex" }
if (Test-Path $hexHome) {
    Remove-Item -Recurse -Force $hexHome -ErrorAction SilentlyContinue
    Write-Host "Removed Hex home: $hexHome" -ForegroundColor Green
}

# Set clean environment variables
Write-Host "Setting clean environment variables..." -ForegroundColor Yellow
$env:MIX_ENV = "dev"
$env:MIX_TARGET = "host"
$env:ERL_LIBS = ""
$env:ERL_AFLAGS = ""
$env:ELIXIR_ERL_OPTIONS = ""
$env:MIX_QUIET = ""
$env:MIX_DEBUG = ""

# Force reinstall Mix tools with specific flags
Write-Host "Force reinstalling Mix tools..." -ForegroundColor Yellow

# Install Hex with force and specific options
Write-Host "Installing Hex..." -ForegroundColor White
$hexInstall = Start-Process -FilePath "mix" -ArgumentList "local.hex", "--force", "--if-missing" -Wait -PassThru -NoNewWindow -RedirectStandardError "hex_error.log" -RedirectStandardOutput "hex_output.log"
if ($hexInstall.ExitCode -eq 0) {
    Write-Host "✓ Hex installed successfully" -ForegroundColor Green
} else {
    Write-Host "✗ Hex installation failed" -ForegroundColor Red
    if (Test-Path "hex_error.log") {
        $hexError = Get-Content "hex_error.log" -Raw
        Write-Host "Error: $hexError" -ForegroundColor Red
    }
}

# Install Rebar with force
Write-Host "Installing Rebar..." -ForegroundColor White
$rebarInstall = Start-Process -FilePath "mix" -ArgumentList "local.rebar", "--force", "--if-missing" -Wait -PassThru -NoNewWindow -RedirectStandardError "rebar_error.log" -RedirectStandardOutput "rebar_output.log"
if ($rebarInstall.ExitCode -eq 0) {
    Write-Host "✓ Rebar installed successfully" -ForegroundColor Green
} else {
    Write-Host "✗ Rebar installation failed" -ForegroundColor Red
    if (Test-Path "rebar_error.log") {
        $rebarError = Get-Content "rebar_error.log" -Raw
        Write-Host "Error: $rebarError" -ForegroundColor Red
    }
}

# Clean up log files
Remove-Item "hex_error.log", "hex_output.log", "rebar_error.log", "rebar_output.log" -ErrorAction SilentlyContinue

# Test Mix functionality step by step
Write-Host "`nTesting Mix functionality step by step..." -ForegroundColor Yellow

# Test 1: Mix help
Write-Host "Test 1: Mix help" -ForegroundColor White
$mixHelp = Start-Process -FilePath "mix" -ArgumentList "help" -Wait -PassThru -NoNewWindow -RedirectStandardError "test1_error.log" -RedirectStandardOutput "test1_output.log"
if ($mixHelp.ExitCode -eq 0) {
    Write-Host "✓ Mix help works" -ForegroundColor Green
} else {
    Write-Host "✗ Mix help failed" -ForegroundColor Red
    if (Test-Path "test1_error.log") {
        $error = Get-Content "test1_error.log" -Raw
        Write-Host "Error: $error" -ForegroundColor Red
    }
}

# Test 2: Mix version
Write-Host "Test 2: Mix version" -ForegroundColor White
$mixVersion = Start-Process -FilePath "mix" -ArgumentList "--version" -Wait -PassThru -NoNewWindow -RedirectStandardError "test2_error.log" -RedirectStandardOutput "test2_output.log"
if ($mixVersion.ExitCode -eq 0) {
    Write-Host "✓ Mix version works" -ForegroundColor Green
    if (Test-Path "test2_output.log") {
        $version = Get-Content "test2_output.log" -Raw
        Write-Host "Version: $version" -ForegroundColor White
    }
} else {
    Write-Host "✗ Mix version failed" -ForegroundColor Red
    if (Test-Path "test2_error.log") {
        $error = Get-Content "test2_error.log" -Raw
        Write-Host "Error: $error" -ForegroundColor Red
    }
}

# Test 3: Mix deps.get with minimal output
Write-Host "Test 3: Mix deps.get" -ForegroundColor White
$mixDeps = Start-Process -FilePath "mix" -ArgumentList "deps.get", "--only", "prod" -Wait -PassThru -NoNewWindow -RedirectStandardError "test3_error.log" -RedirectStandardOutput "test3_output.log"
if ($mixDeps.ExitCode -eq 0) {
    Write-Host "✓ Mix deps.get works" -ForegroundColor Green
} else {
    Write-Host "✗ Mix deps.get failed" -ForegroundColor Red
    if (Test-Path "test3_error.log") {
        $error = Get-Content "test3_error.log" -Raw
        Write-Host "Error: $error" -ForegroundColor Red
    }
}

# Clean up test log files
Remove-Item "test1_error.log", "test1_output.log", "test2_error.log", "test2_output.log", "test3_error.log", "test3_output.log" -ErrorAction SilentlyContinue

# Final recommendations
Write-Host "`nFinal status and recommendations:" -ForegroundColor Yellow
if ($mixHelp.ExitCode -eq 0 -and $mixVersion.ExitCode -eq 0) {
    Write-Host "✓ Mix basic functionality is working" -ForegroundColor Green
    if ($mixDeps.ExitCode -eq 0) {
        Write-Host "✓ Mix can handle dependencies" -ForegroundColor Green
        Write-Host "You can now try running: mix phx.server" -ForegroundColor Cyan
    } else {
        Write-Host "⚠ Mix deps.get still has issues, but basic Mix works" -ForegroundColor Yellow
        Write-Host "Try running dependencies installation manually" -ForegroundColor Cyan
    }
} else {
    Write-Host "✗ Mix still has fundamental issues" -ForegroundColor Red
    Write-Host "Consider:" -ForegroundColor Yellow
    Write-Host "1. Reinstalling Elixir completely" -ForegroundColor White
    Write-Host "2. Using a different Elixir version" -ForegroundColor White
    Write-Host "3. Checking for system-level conflicts" -ForegroundColor White
}

Write-Host "`nMix environment fix completed!" -ForegroundColor Green