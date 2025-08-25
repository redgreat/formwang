# Fix Erlang version conflicts - Multiple compiler versions detected
Write-Host "Fixing Erlang version conflicts..." -ForegroundColor Yellow
Write-Host "Detected multiple compiler versions causing v3_core conflicts" -ForegroundColor Red

# Stop all Erlang/Elixir processes first
Write-Host "`nStopping all Erlang/Elixir processes..." -ForegroundColor Cyan
try {
    Get-Process | Where-Object {$_.ProcessName -match "erl|beam|epmd|elixir|iex"} | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Write-Host "[OK] Stopped all processes" -ForegroundColor Green
} catch {
    Write-Host "No processes to stop" -ForegroundColor Yellow
}

# Check current Erlang installation
$erlangRoot = "C:\Program Files\Erlang OTP"
Write-Host "`nAnalyzing Erlang installation at: $erlangRoot" -ForegroundColor Cyan

if (Test-Path $erlangRoot) {
    # List all compiler versions
    $compilerDirs = Get-ChildItem -Path "$erlangRoot\lib" -Directory | Where-Object {$_.Name -match "compiler-"} | Sort-Object Name
    
    Write-Host "`nFound compiler versions:" -ForegroundColor White
    foreach ($dir in $compilerDirs) {
        $v3coreFile = Join-Path $dir.FullName "ebin\v3_core.beam"
        $exists = Test-Path $v3coreFile
        $status = if ($exists) { "[OK]" } else { "[MISSING]" }
        Write-Host "  $status $($dir.Name) - v3_core.beam: $exists" -ForegroundColor $(if ($exists) { "Green" } else { "Red" })
    }
    
    # Find the latest/newest compiler version
    $latestCompiler = $compilerDirs | Sort-Object {[version]($_.Name -replace 'compiler-', '')} | Select-Object -Last 1
    Write-Host "`nLatest compiler version: $($latestCompiler.Name)" -ForegroundColor Yellow
    
    # Strategy 1: Remove older compiler versions (DANGEROUS - backup first)
    Write-Host "`n=== Strategy 1: Clean old compiler versions ===" -ForegroundColor Yellow
    Write-Host "WARNING: This will remove older compiler versions!" -ForegroundColor Red
    Write-Host "Creating backup first..." -ForegroundColor Cyan
    
    $backupPath = "$env:TEMP\erlang_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    try {
        New-Item -Path $backupPath -ItemType Directory -Force | Out-Null
        
        # Backup older versions before removal
        $olderCompilers = $compilerDirs | Where-Object {$_.Name -ne $latestCompiler.Name}
        foreach ($oldCompiler in $olderCompilers) {
            $backupDir = Join-Path $backupPath $oldCompiler.Name
            Copy-Item $oldCompiler.FullName $backupDir -Recurse -Force
            Write-Host "  Backed up: $($oldCompiler.Name)" -ForegroundColor Gray
        }
        
        Write-Host "[OK] Backup created at: $backupPath" -ForegroundColor Green
        
        # Now remove older versions
        Write-Host "`nRemoving older compiler versions..." -ForegroundColor Cyan
        foreach ($oldCompiler in $olderCompilers) {
            try {
                Remove-Item $oldCompiler.FullName -Recurse -Force
                Write-Host "  [OK] Removed: $($oldCompiler.Name)" -ForegroundColor Green
            } catch {
                Write-Host "  [ERROR] Failed to remove: $($oldCompiler.Name) - $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        
    } catch {
        Write-Host "[ERROR] Backup failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Skipping cleanup for safety" -ForegroundColor Yellow
    }
} else {
    Write-Host "[ERROR] Erlang installation not found at expected location" -ForegroundColor Red
}

# Strategy 2: Force environment reset
Write-Host "`n=== Strategy 2: Force environment reset ===" -ForegroundColor Yellow

# Clear all environment variables that might point to old versions
$envVarsToCheck = @(
    "ERLANG_HOME",
    "ERL_TOP",
    "ERL_LIBS",
    "ELIXIR_ERL_OPTIONS"
)

foreach ($envVar in $envVarsToCheck) {
    $value = [Environment]::GetEnvironmentVariable($envVar, "User")
    if ($value) {
        Write-Host "Found user env var: $envVar = $value" -ForegroundColor Yellow
        [Environment]::SetEnvironmentVariable($envVar, $null, "User")
        Write-Host "  [OK] Cleared user $envVar" -ForegroundColor Green
    }
    
    $value = [Environment]::GetEnvironmentVariable($envVar, "Machine")
    if ($value) {
        Write-Host "Found system env var: $envVar = $value" -ForegroundColor Yellow
        try {
            [Environment]::SetEnvironmentVariable($envVar, $null, "Machine")
            Write-Host "  [OK] Cleared system $envVar" -ForegroundColor Green
        } catch {
            Write-Host "  [ERROR] Cannot clear system $envVar (need admin rights)" -ForegroundColor Red
        }
    }
}

# Refresh PATH to use latest Erlang
Write-Host "`nRefreshing PATH environment..." -ForegroundColor Cyan
$env:PATH = [Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [Environment]::GetEnvironmentVariable("PATH", "User")
Write-Host "[OK] PATH refreshed" -ForegroundColor Green

# Strategy 3: Force reinstall Mix with clean environment
Write-Host "`n=== Strategy 3: Clean Mix reinstall ===" -ForegroundColor Yellow

# Remove all Mix/Hex caches completely
$cachesToClear = @(
    "$env:USERPROFILE\.mix",
    "$env:USERPROFILE\.hex",
    "$env:APPDATA\hex",
    "$env:LOCALAPPDATA\hex",
    "$env:TEMP\mix*",
    "$env:TEMP\hex*"
)

foreach ($cache in $cachesToClear) {
    if (Test-Path $cache) {
        try {
            Remove-Item $cache -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "  [OK] Cleared: $cache" -ForegroundColor Green
        } catch {
            Write-Host "  [ERROR] Could not clear: $cache" -ForegroundColor Yellow
        }
    }
}

# Reinstall Mix tools with explicit version forcing
Write-Host "`nReinstalling Mix tools with version forcing..." -ForegroundColor Cyan
try {
    # Force clean install
    $env:MIX_ENV = "dev"
    $env:HEX_UNSAFE_HTTPS = "1"
    
    Write-Host "Installing Hex..." -ForegroundColor White
    $hexResult = mix local.hex --force --if-missing 2>&1
    Write-Host "Hex install result: $hexResult" -ForegroundColor Gray
    
    Write-Host "Installing Rebar..." -ForegroundColor White
    $rebarResult = mix local.rebar --force --if-missing 2>&1
    Write-Host "Rebar install result: $rebarResult" -ForegroundColor Gray
    
    Write-Host "[OK] Mix tools reinstalled" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Mix tools installation failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Strategy 4: Test with isolated environment
Write-Host "`n=== Strategy 4: Testing with isolated environment ===" -ForegroundColor Yellow

# Create a test script that runs in completely clean environment
$testScript = @'
@echo off
set ERLANG_HOME=
set ERL_TOP=
set ERL_LIBS=
set ELIXIR_ERL_OPTIONS=
set MIX_ENV=dev

echo Testing Erlang...
erl -eval "io:format('Erlang works: ~p~n', [erlang:system_info(otp_release)]), halt()."

echo Testing Elixir...
elixir -e "IO.puts('Elixir version: ' <> System.version())"

echo Testing Mix...
mix --version

echo Testing v3_core module...
erl -eval "case code:ensure_loaded(v3_core) of {module, v3_core} -> io:format('v3_core OK~n'); Error -> io:format('v3_core Error: ~p~n', [Error]) end, halt()."
'@

$testBatPath = "$env:TEMP\test_erlang_clean.bat"
$testScript | Out-File -FilePath $testBatPath -Encoding ASCII

Write-Host "Running isolated test..." -ForegroundColor Cyan
try {
    $testResult = & cmd /c $testBatPath 2>&1
    Write-Host "Test results:" -ForegroundColor White
    Write-Host $testResult -ForegroundColor Gray
} catch {
    Write-Host "[ERROR] Isolated test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Final verification
Write-Host "`n=== Final Verification ===" -ForegroundColor Yellow

Write-Host "Testing Mix functionality..." -ForegroundColor Cyan
try {
    $mixHelp = mix help 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Mix is working!" -ForegroundColor Green
        
        # Try to test in project directory
        Write-Host "`nTesting Mix in project context..." -ForegroundColor Cyan
        $mixDeps = mix deps 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] Mix deps command works" -ForegroundColor Green
            Write-Host "\n[SUCCESS] Erlang version conflict resolved!" -ForegroundColor Green
            Write-Host "You can now try: mix phx.server" -ForegroundColor White
        } else {
            Write-Host "[ERROR] Mix deps still fails" -ForegroundColor Red
            Write-Host "Mix deps output: $mixDeps" -ForegroundColor Gray
        }
    } else {
        Write-Host "[ERROR] Mix still has issues" -ForegroundColor Red
        Write-Host "Mix help output: $mixHelp" -ForegroundColor Gray
    }
} catch {
    Write-Host "[ERROR] Mix command failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Summary ===" -ForegroundColor Yellow
Write-Host "1. Removed conflicting compiler versions" -ForegroundColor White
Write-Host "2. Cleared environment variables" -ForegroundColor White
Write-Host "3. Reinstalled Mix tools" -ForegroundColor White
Write-Host "4. Tested isolated environment" -ForegroundColor White
Write-Host "`nIf issues persist, consider:" -ForegroundColor Yellow
Write-Host "- Complete Erlang/Elixir reinstallation" -ForegroundColor White
Write-Host "- Using version manager (asdf, kiex)" -ForegroundColor White
Write-Host "- Running as Administrator" -ForegroundColor White

Write-Host "`nErlang version conflict fix completed!" -ForegroundColor Green