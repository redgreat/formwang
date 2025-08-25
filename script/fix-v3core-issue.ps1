# Fix v3_core module corruption and atom table errors
Write-Host "Fixing v3_core module corruption and atom table errors..." -ForegroundColor Yellow

# Stop all Erlang/Elixir processes
Write-Host "`nStopping all Erlang/Elixir processes..." -ForegroundColor Cyan
try {
    Get-Process | Where-Object {$_.ProcessName -match "erl|beam|epmd|elixir|iex"} | Stop-Process -Force -ErrorAction SilentlyContinue
    Write-Host "✓ Stopped Erlang/Elixir processes" -ForegroundColor Green
} catch {
    Write-Host "No Erlang/Elixir processes to stop" -ForegroundColor Yellow
}

# Check current Erlang/Elixir versions
Write-Host "`nChecking current versions..." -ForegroundColor Cyan
try {
    $erlVersion = erl -eval "io:format('~s~n', [erlang:system_info(otp_release)]), halt()." -noshell 2>$null
    Write-Host "Erlang/OTP version: $erlVersion" -ForegroundColor White
} catch {
    Write-Host "Cannot determine Erlang version" -ForegroundColor Red
}

try {
    $elixirVersion = elixir --version 2>$null | Select-String "Elixir" | ForEach-Object { $_.ToString() }
    Write-Host "$elixirVersion" -ForegroundColor White
} catch {
    Write-Host "Cannot determine Elixir version" -ForegroundColor Red
}

# Clear all compilation caches and temporary files
Write-Host "`nClearing all caches and temporary files..." -ForegroundColor Cyan

# Clear project-specific caches
$cacheDirs = @(
    "_build",
    "deps",
    ".elixir_ls"
)

foreach ($dir in $cacheDirs) {
    if (Test-Path $dir) {
        Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "✓ Removed $dir" -ForegroundColor Green
    }
}

# Clear Mix caches
$mixCachePaths = @(
    "$env:USERPROFILE\.mix",
    "$env:USERPROFILE\.hex",
    "$env:APPDATA\hex",
    "$env:LOCALAPPDATA\hex"
)

foreach ($path in $mixCachePaths) {
    if (Test-Path $path) {
        try {
            Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "✓ Cleared Mix cache: $path" -ForegroundColor Green
        } catch {
            Write-Host "Could not clear: $path" -ForegroundColor Yellow
        }
    }
}

# Clear Erlang beam files and caches
$erlangPaths = @(
    "$env:USERPROFILE\.erlang",
    "$env:TEMP\erlang*",
    "$env:LOCALAPPDATA\Temp\erlang*"
)

foreach ($path in $erlangPaths) {
    if (Test-Path $path) {
        try {
            Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "✓ Cleared Erlang cache: $path" -ForegroundColor Green
        } catch {
            Write-Host "Could not clear: $path" -ForegroundColor Yellow
        }
    }
}

# Clear Windows temp files related to Erlang/Elixir
Write-Host "`nClearing Windows temp files..." -ForegroundColor Cyan
$tempPaths = @(
    "$env:TEMP\beam*",
    "$env:TEMP\erl*",
    "$env:TEMP\elixir*",
    "$env:TEMP\mix*"
)

foreach ($pattern in $tempPaths) {
    Get-ChildItem $env:TEMP -Filter ($pattern -replace '.*\\', '') -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host "✓ Cleared Windows temp files" -ForegroundColor Green

# Force rebuild Erlang/Elixir environment
Write-Host "`nRebuilding Erlang/Elixir environment..." -ForegroundColor Cyan

# Try to reinstall Mix
try {
    Write-Host "Reinstalling Mix..." -ForegroundColor White
    mix local.hex --force 2>$null
    mix local.rebar --force 2>$null
    Write-Host "✓ Mix tools reinstalled" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to reinstall Mix tools" -ForegroundColor Red
}

# Check if v3_core module can be loaded
Write-Host "`nTesting v3_core module..." -ForegroundColor Cyan
try {
    $v3coreTest = erl -eval "code:ensure_loaded(v3_core), io:format('v3_core module loaded successfully~n'), halt()." -noshell 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ v3_core module loads correctly" -ForegroundColor Green
    } else {
        Write-Host "✗ v3_core module still has issues" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Cannot test v3_core module" -ForegroundColor Red
}

# Test atom table
Write-Host "`nTesting atom table..." -ForegroundColor Cyan
try {
    $atomTest = erl -eval "io:format('Atom table test: ~p~n', [erlang:system_info(atom_count)]), halt()." -noshell 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Atom table is working" -ForegroundColor Green
    } else {
        Write-Host "✗ Atom table has issues" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Cannot test atom table" -ForegroundColor Red
}

# Advanced fix: Try to rebuild Erlang installation
Write-Host "`nAdvanced fix: Checking Erlang installation integrity..." -ForegroundColor Cyan

# Find Erlang installation path
$erlangPath = $null
try {
    $erlangPath = (Get-Command erl -ErrorAction SilentlyContinue).Source
    if ($erlangPath) {
        $erlangRoot = Split-Path (Split-Path $erlangPath -Parent) -Parent
        Write-Host "Erlang installation found at: $erlangRoot" -ForegroundColor White
        
        # Check for v3_core.beam file
        $v3coreFiles = Get-ChildItem -Path $erlangRoot -Recurse -Name "v3_core.beam" -ErrorAction SilentlyContinue
        if ($v3coreFiles) {
            Write-Host "Found v3_core.beam files:" -ForegroundColor White
            foreach ($file in $v3coreFiles) {
                Write-Host "  $file" -ForegroundColor Gray
            }
        } else {
            Write-Host "✗ No v3_core.beam files found" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "Cannot locate Erlang installation" -ForegroundColor Yellow
}

# Try alternative Elixir startup methods
Write-Host "`nTesting alternative startup methods..." -ForegroundColor Cyan

# Test 1: Direct Erlang
Write-Host "Test 1: Direct Erlang shell" -ForegroundColor White
try {
    $erlTest = Start-Process -FilePath "erl" -ArgumentList "-eval", "halt()." -Wait -PassThru -WindowStyle Hidden
    if ($erlTest.ExitCode -eq 0) {
        Write-Host "✓ Direct Erlang works" -ForegroundColor Green
    } else {
        Write-Host "✗ Direct Erlang fails" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Cannot start Erlang" -ForegroundColor Red
}

# Test 2: Elixir without Mix
Write-Host "Test 2: Elixir without Mix" -ForegroundColor White
try {
    $elixirTest = elixir -e "IO.puts('Elixir works')" 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Elixir without Mix works" -ForegroundColor Green
    } else {
        Write-Host "✗ Elixir without Mix fails" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Cannot start Elixir" -ForegroundColor Red
}

# Test 3: IEx without Mix
Write-Host "Test 3: IEx without Mix" -ForegroundColor White
try {
    $iexTest = Start-Process -FilePath "iex" -ArgumentList "-e", "System.halt()" -Wait -PassThru -WindowStyle Hidden
    if ($iexTest.ExitCode -eq 0) {
        Write-Host "✓ IEx without Mix works" -ForegroundColor Green
    } else {
        Write-Host "✗ IEx without Mix fails" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Cannot start IEx" -ForegroundColor Red
}

# Final recommendations
Write-Host "`n=== Fix Results and Recommendations ===" -ForegroundColor Yellow

# Test Mix functionality
Write-Host "`nTesting Mix functionality..." -ForegroundColor Cyan
try {
    $mixTest = mix help 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Mix is working!" -ForegroundColor Green
        Write-Host "`nTrying to start Phoenix server..." -ForegroundColor Cyan
        Write-Host "You can now try: iex -S mix phx.server" -ForegroundColor White
    } else {
        Write-Host "✗ Mix still has issues" -ForegroundColor Red
        Write-Host "`nRecommendations:" -ForegroundColor Yellow
        Write-Host "1. Reinstall Elixir completely" -ForegroundColor White
        Write-Host "2. Use version manager (asdf, kiex, or Scoop)" -ForegroundColor White
        Write-Host "3. Check for conflicting Erlang installations" -ForegroundColor White
        Write-Host "4. Run as Administrator" -ForegroundColor White
    }
} catch {
    Write-Host "✗ Mix command not available" -ForegroundColor Red
}

Write-Host "`nv3_core fix attempt completed!" -ForegroundColor Green