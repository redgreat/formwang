# Fix Erlang v3_core issue with Administrator privileges
# This script must be run as Administrator

Write-Host "Checking Administrator privileges..." -ForegroundColor Yellow

# Check if running as Administrator
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "[ERROR] This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Please right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    Write-Host "Then navigate to the project directory and run this script again." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "[OK] Running with Administrator privileges" -ForegroundColor Green

# Stop all Erlang/Elixir processes
Write-Host "`nStopping all Erlang/Elixir processes..." -ForegroundColor Cyan
try {
    Get-Process | Where-Object {$_.ProcessName -match "erl|beam|epmd|elixir|iex"} | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
    Write-Host "[OK] Stopped all processes" -ForegroundColor Green
} catch {
    Write-Host "No processes to stop" -ForegroundColor Yellow
}

# Strategy 1: Complete Erlang reinstallation approach
Write-Host "`n=== Strategy 1: Complete Erlang Cleanup ===" -ForegroundColor Yellow

$erlangRoot = "C:\Program Files\Erlang OTP"
if (Test-Path $erlangRoot) {
    Write-Host "Found Erlang installation at: $erlangRoot" -ForegroundColor White
    
    # List current compiler versions
    $compilerDirs = Get-ChildItem -Path "$erlangRoot\lib" -Directory | Where-Object {$_.Name -match "compiler-"} | Sort-Object Name
    Write-Host "`nCurrent compiler versions:" -ForegroundColor White
    foreach ($dir in $compilerDirs) {
        Write-Host "  $($dir.Name)" -ForegroundColor Gray
    }
    
    # Find the latest compiler version
    $latestCompiler = $compilerDirs | Sort-Object {[version]($_.Name -replace 'compiler-', '')} | Select-Object -Last 1
    Write-Host "`nLatest compiler: $($latestCompiler.Name)" -ForegroundColor Yellow
    
    # Remove older compiler versions with admin privileges
    $olderCompilers = $compilerDirs | Where-Object {$_.Name -ne $latestCompiler.Name}
    
    if ($olderCompilers.Count -gt 0) {
        Write-Host "`nRemoving older compiler versions..." -ForegroundColor Cyan
        foreach ($oldCompiler in $olderCompilers) {
            try {
                Write-Host "  Removing: $($oldCompiler.Name)" -ForegroundColor White
                
                # Take ownership first
                takeown /f "$($oldCompiler.FullName)" /r /d y 2>$null | Out-Null
                
                # Grant full control
                icacls "$($oldCompiler.FullName)" /grant administrators:F /t 2>$null | Out-Null
                
                # Remove the directory
                Remove-Item $oldCompiler.FullName -Recurse -Force -ErrorAction Stop
                Write-Host "  [OK] Removed: $($oldCompiler.Name)" -ForegroundColor Green
            } catch {
                Write-Host "  [ERROR] Failed to remove: $($oldCompiler.Name)" -ForegroundColor Red
                Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Gray
            }
        }
    } else {
        Write-Host "No older compiler versions to remove" -ForegroundColor Yellow
    }
}

# Strategy 2: Registry cleanup
Write-Host "`n=== Strategy 2: Registry Cleanup ===" -ForegroundColor Yellow

$registryPaths = @(
    "HKLM:\SOFTWARE\Ericsson\Erlang",
    "HKLM:\SOFTWARE\WOW6432Node\Ericsson\Erlang",
    "HKCU:\SOFTWARE\Ericsson\Erlang"
)

foreach ($regPath in $registryPaths) {
    if (Test-Path $regPath) {
        try {
            Write-Host "Cleaning registry: $regPath" -ForegroundColor White
            Remove-Item $regPath -Recurse -Force -ErrorAction Stop
            Write-Host "  [OK] Cleaned: $regPath" -ForegroundColor Green
        } catch {
            Write-Host "  [ERROR] Could not clean: $regPath" -ForegroundColor Red
        }
    }
}

# Strategy 3: Environment variables cleanup with admin rights
Write-Host "`n=== Strategy 3: System Environment Cleanup ===" -ForegroundColor Yellow

$envVarsToClean = @(
    "ERLANG_HOME",
    "ERL_TOP",
    "ERL_LIBS",
    "ELIXIR_ERL_OPTIONS"
)

foreach ($envVar in $envVarsToClean) {
    # Clean system-wide environment variables
    $systemValue = [Environment]::GetEnvironmentVariable($envVar, "Machine")
    if ($systemValue) {
        Write-Host "Clearing system $envVar = $systemValue" -ForegroundColor White
        [Environment]::SetEnvironmentVariable($envVar, $null, "Machine")
        Write-Host "  [OK] Cleared system $envVar" -ForegroundColor Green
    }
    
    # Clean user environment variables
    $userValue = [Environment]::GetEnvironmentVariable($envVar, "User")
    if ($userValue) {
        Write-Host "Clearing user $envVar = $userValue" -ForegroundColor White
        [Environment]::SetEnvironmentVariable($envVar, $null, "User")
        Write-Host "  [OK] Cleared user $envVar" -ForegroundColor Green
    }
}

# Strategy 4: Clean PATH from old Erlang references
Write-Host "`n=== Strategy 4: PATH Cleanup ===" -ForegroundColor Yellow

$systemPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
$userPath = [Environment]::GetEnvironmentVariable("PATH", "User")

# Remove old Erlang paths
$erlangPathPatterns = @(
    "*Erlang*",
    "*erl*",
    "*Elixir*"
)

# Clean system PATH
if ($systemPath) {
    $newSystemPath = $systemPath
    $pathChanged = $false
    
    foreach ($pattern in $erlangPathPatterns) {
        $pathEntries = $newSystemPath -split ';'
        $filteredEntries = $pathEntries | Where-Object { $_ -notlike $pattern }
        
        if ($filteredEntries.Count -ne $pathEntries.Count) {
            $newSystemPath = $filteredEntries -join ';'
            $pathChanged = $true
        }
    }
    
    if ($pathChanged) {
        [Environment]::SetEnvironmentVariable("PATH", $newSystemPath, "Machine")
        Write-Host "[OK] Cleaned system PATH" -ForegroundColor Green
    }
}

# Strategy 5: Force rebuild with clean environment
Write-Host "`n=== Strategy 5: Clean Environment Test ===" -ForegroundColor Yellow

# Refresh environment
$env:PATH = [Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [Environment]::GetEnvironmentVariable("PATH", "User")

# Test Erlang
Write-Host "Testing Erlang..." -ForegroundColor Cyan
try {
    $erlVersion = erl -eval "io:format('~s~n', [erlang:system_info(otp_release)]), halt()." -noshell 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Erlang works: OTP $erlVersion" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Erlang test failed" -ForegroundColor Red
    }
} catch {
    Write-Host "[ERROR] Cannot run Erlang" -ForegroundColor Red
}

# Test Elixir
Write-Host "Testing Elixir..." -ForegroundColor Cyan
try {
    $elixirTest = elixir -e "IO.puts('Elixir: ' <> System.version())" 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Elixir works" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Elixir test failed" -ForegroundColor Red
    }
} catch {
    Write-Host "[ERROR] Cannot run Elixir" -ForegroundColor Red
}

# Test v3_core module specifically
Write-Host "Testing v3_core module..." -ForegroundColor Cyan
try {
    $v3coreTest = erl -eval "case code:ensure_loaded(v3_core) of {module, v3_core} -> io:format('v3_core loaded successfully~n'); Error -> io:format('v3_core error: ~p~n', [Error]) end, halt()." -noshell 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] v3_core module test passed" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] v3_core module test failed" -ForegroundColor Red
    }
} catch {
    Write-Host "[ERROR] Cannot test v3_core module" -ForegroundColor Red
}

# Clear all caches with admin privileges
Write-Host "`n=== Strategy 6: Complete Cache Cleanup ===" -ForegroundColor Yellow

$cachesToClear = @(
    "$env:USERPROFILE\.mix",
    "$env:USERPROFILE\.hex",
    "$env:APPDATA\hex",
    "$env:LOCALAPPDATA\hex",
    "$env:TEMP\mix*",
    "$env:TEMP\hex*",
    "$env:TEMP\erl*",
    "$env:TEMP\beam*"
)

foreach ($cache in $cachesToClear) {
    if (Test-Path $cache) {
        try {
            takeown /f "$cache" /r /d y 2>$null | Out-Null
            icacls "$cache" /grant administrators:F /t 2>$null | Out-Null
            Remove-Item $cache -Recurse -Force -ErrorAction Stop
            Write-Host "[OK] Cleared: $cache" -ForegroundColor Green
        } catch {
            Write-Host "[ERROR] Could not clear: $cache" -ForegroundColor Yellow
        }
    }
}

# Reinstall Mix tools
Write-Host "`n=== Strategy 7: Mix Tools Reinstall ===" -ForegroundColor Yellow

try {
    Write-Host "Installing Hex..." -ForegroundColor White
    mix local.hex --force 2>$null
    
    Write-Host "Installing Rebar..." -ForegroundColor White
    mix local.rebar --force 2>$null
    
    Write-Host "[OK] Mix tools reinstalled" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Mix tools installation failed" -ForegroundColor Red
}

# Final test
Write-Host "`n=== Final Verification ===" -ForegroundColor Yellow

Write-Host "Testing Mix functionality..." -ForegroundColor Cyan
try {
    $mixHelp = mix help 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Mix is working!" -ForegroundColor Green
        
        # Test in project context
        Write-Host "Testing Mix deps..." -ForegroundColor Cyan
        $mixDeps = mix deps 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[SUCCESS] Mix deps works! v3_core issue resolved!" -ForegroundColor Green
            Write-Host "`nYou can now try:" -ForegroundColor White
            Write-Host "  mix deps.get" -ForegroundColor Yellow
            Write-Host "  mix phx.server" -ForegroundColor Yellow
        } else {
            Write-Host "[ERROR] Mix deps still fails" -ForegroundColor Red
            Write-Host "Output: $mixDeps" -ForegroundColor Gray
        }
    } else {
        Write-Host "[ERROR] Mix still has issues" -ForegroundColor Red
        Write-Host "Output: $mixHelp" -ForegroundColor Gray
    }
} catch {
    Write-Host "[ERROR] Mix command failed" -ForegroundColor Red
}

Write-Host "`n=== Admin Fix Completed ===" -ForegroundColor Green
Write-Host "If issues persist, consider complete Erlang/Elixir reinstallation" -ForegroundColor Yellow
Read-Host "Press Enter to continue"