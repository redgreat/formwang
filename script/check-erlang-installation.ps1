# Check and diagnose Erlang installation issues
Write-Host "Checking Erlang installation and diagnosing issues..." -ForegroundColor Yellow

# Check Erlang installation paths
Write-Host "`nChecking Erlang installation paths:" -ForegroundColor Cyan
$erlangPaths = @()

# Check common installation locations
$commonPaths = @(
    "C:\Program Files\Erlang",
    "C:\Program Files (x86)\Erlang",
    "$env:USERPROFILE\scoop\apps\erlang",
    "$env:LOCALAPPDATA\Programs\Erlang"
)

foreach ($path in $commonPaths) {
    if (Test-Path $path) {
        $versions = Get-ChildItem $path -Directory -ErrorAction SilentlyContinue
        foreach ($version in $versions) {
            $erlangPaths += $version.FullName
            Write-Host "Found Erlang: $($version.FullName)" -ForegroundColor Green
        }
    }
}

# Check PATH environment variable
Write-Host "`nChecking PATH environment variable:" -ForegroundColor Cyan
$pathEntries = $env:PATH -split ';'
$erlangInPath = $pathEntries | Where-Object { $_ -match 'erlang|erl' }
if ($erlangInPath) {
    foreach ($entry in $erlangInPath) {
        Write-Host "Erlang in PATH: $entry" -ForegroundColor Green
    }
} else {
    Write-Host "No Erlang paths found in PATH" -ForegroundColor Yellow
}

# Check which erl command is being used
Write-Host "`nChecking which erl command is being used:" -ForegroundColor Cyan
try {
    $erlPath = Get-Command erl -ErrorAction Stop
    Write-Host "erl command path: $($erlPath.Source)" -ForegroundColor Green
    
    # Check if the erl.exe file exists and is accessible
    if (Test-Path $erlPath.Source) {
        $fileInfo = Get-Item $erlPath.Source
        Write-Host "File size: $($fileInfo.Length) bytes" -ForegroundColor White
        Write-Host "Last modified: $($fileInfo.LastWriteTime)" -ForegroundColor White
    }
} catch {
    Write-Host "erl command not found in PATH" -ForegroundColor Red
}

# Check Elixir installation
Write-Host "`nChecking Elixir installation:" -ForegroundColor Cyan
try {
    $elixirPath = Get-Command elixir -ErrorAction Stop
    Write-Host "elixir command path: $($elixirPath.Source)" -ForegroundColor Green
} catch {
    Write-Host "elixir command not found in PATH" -ForegroundColor Red
}

# Test basic Erlang functionality
Write-Host "`nTesting basic Erlang functionality:" -ForegroundColor Cyan
try {
    $erlTest = erl -noshell -eval "io:format('Erlang VM is working~n'), halt()." 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Basic Erlang VM test passed" -ForegroundColor Green
    } else {
        Write-Host "✗ Basic Erlang VM test failed" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Basic Erlang VM test exception" -ForegroundColor Red
}

# Test Erlang module loading
Write-Host "`nTesting Erlang module loading:" -ForegroundColor Cyan
try {
    $moduleTest = erl -noshell -eval "code:which(lists), halt()." 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Erlang module loading test passed" -ForegroundColor Green
    } else {
        Write-Host "✗ Erlang module loading test failed" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Erlang module loading test exception" -ForegroundColor Red
}

# Check for v3_core module specifically
Write-Host "`nChecking v3_core module:" -ForegroundColor Cyan
try {
    $v3CoreTest = erl -noshell -eval "code:which(v3_core), halt()." 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ v3_core module found" -ForegroundColor Green
    } else {
        Write-Host "✗ v3_core module not found or corrupted" -ForegroundColor Red
        Write-Host "Error output: $v3CoreTest" -ForegroundColor Yellow
    }
} catch {
    Write-Host "✗ v3_core module test exception" -ForegroundColor Red
}

# Check Erlang installation integrity
Write-Host "`nChecking Erlang installation integrity:" -ForegroundColor Cyan
if ($erlangPaths.Count -gt 0) {
    foreach ($erlangPath in $erlangPaths) {
        Write-Host "Checking $erlangPath" -ForegroundColor White
        
        $libPath = Join-Path $erlangPath "lib"
        if (Test-Path $libPath) {
            $compilerPath = Get-ChildItem $libPath -Filter "compiler-*" -Directory | Select-Object -First 1
            if ($compilerPath) {
                $v3CorePath = Join-Path $compilerPath.FullName "ebin\v3_core.beam"
                if (Test-Path $v3CorePath) {
                    $fileInfo = Get-Item $v3CorePath
                    Write-Host "  v3_core.beam found: $v3CorePath" -ForegroundColor Green
                    Write-Host "  File size: $($fileInfo.Length) bytes" -ForegroundColor White
                    Write-Host "  Last modified: $($fileInfo.LastWriteTime)" -ForegroundColor White
                } else {
                    Write-Host "  v3_core.beam NOT found in $($compilerPath.FullName)\ebin" -ForegroundColor Red
                }
            } else {
                Write-Host "  Compiler directory not found in $libPath" -ForegroundColor Red
            }
        } else {
            Write-Host "  lib directory not found in $erlangPath" -ForegroundColor Red
        }
    }
}

# Recommendations
Write-Host "`nRecommendations:" -ForegroundColor Yellow
if ($erlangPaths.Count -gt 1) {
    Write-Host "1. Multiple Erlang installations detected - consider removing older versions" -ForegroundColor White
}
Write-Host "2. If v3_core module is corrupted, try reinstalling Erlang" -ForegroundColor White
Write-Host "3. Consider using a version manager like asdf or scoop for cleaner installations" -ForegroundColor White
Write-Host "4. Check if antivirus software is interfering with Erlang files" -ForegroundColor White
Write-Host "5. Run as administrator if file permission issues are suspected" -ForegroundColor White

Write-Host "`nDiagnosis completed!" -ForegroundColor Green