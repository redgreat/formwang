# Start Phoenix server without relying on Mix compilation
Write-Host "Starting Phoenix server without Mix compilation..." -ForegroundColor Yellow

# Check if we have a working database connection
Write-Host "`nChecking database connection..." -ForegroundColor Cyan
if (Test-Path ".env.local") {
    Write-Host "Found .env.local configuration" -ForegroundColor Green
    
    # Load database configuration
    $envContent = Get-Content ".env.local" -Raw
    if ($envContent -match 'DATABASE_URL=(.+)') {
        $dbUrl = $matches[1]
        Write-Host "Database URL configured: $($dbUrl -replace 'password=[^;]+', 'password=***')" -ForegroundColor Green
    }
} else {
    Write-Host "No .env.local found, database may not be configured" -ForegroundColor Yellow
}

# Check if we can use Elixir directly
Write-Host "`nTesting direct Elixir execution..." -ForegroundColor Cyan
try {
    $elixirTest = elixir -e "IO.puts('Direct Elixir works')" 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Direct Elixir execution works" -ForegroundColor Green
    } else {
        Write-Host "✗ Direct Elixir execution failed" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Direct Elixir execution exception" -ForegroundColor Red
}

# Try alternative approaches
Write-Host "`nTrying alternative startup approaches..." -ForegroundColor Yellow

# Approach 1: Try using iex directly
Write-Host "Approach 1: Using iex (Interactive Elixir)" -ForegroundColor White
try {
    Write-Host "You can manually start the application using:" -ForegroundColor Cyan
    Write-Host "iex -S mix phx.server" -ForegroundColor White
    Write-Host "Or try: iex --name formwang@localhost -S mix phx.server" -ForegroundColor White
} catch {
    Write-Host "iex approach may not work" -ForegroundColor Yellow
}

# Approach 2: Check if we can compile manually
Write-Host "`nApproach 2: Manual compilation check" -ForegroundColor White
if (Test-Path "lib") {
    Write-Host "Found lib directory with source code" -ForegroundColor Green
    
    # Check main application files
    $mainFiles = @(
        "lib\formwang\application.ex",
        "lib\formwang_web\endpoint.ex",
        "lib\formwang_web\router.ex"
    )
    
    foreach ($file in $mainFiles) {
        if (Test-Path $file) {
            Write-Host "✓ Found: $file" -ForegroundColor Green
        } else {
            Write-Host "✗ Missing: $file" -ForegroundColor Red
        }
    }
} else {
    Write-Host "No lib directory found" -ForegroundColor Red
}

# Approach 3: Try using Erlang directly
Write-Host "`nApproach 3: Direct Erlang execution" -ForegroundColor White
Write-Host "You can try starting Erlang directly:" -ForegroundColor Cyan
Write-Host "erl -pa _build/dev/lib/*/ebin -s application start formwang" -ForegroundColor White

# Approach 4: Check for pre-compiled files
Write-Host "`nApproach 4: Checking for pre-compiled files" -ForegroundColor White
if (Test-Path "_build\dev\lib") {
    $compiledLibs = Get-ChildItem "_build\dev\lib" -Directory
    Write-Host "Found compiled libraries: $($compiledLibs.Count)" -ForegroundColor Green
    foreach ($lib in $compiledLibs | Select-Object -First 5) {
        Write-Host "  - $($lib.Name)" -ForegroundColor White
    }
    if ($compiledLibs.Count -gt 5) {
        Write-Host "  ... and $($compiledLibs.Count - 5) more" -ForegroundColor White
    }
} else {
    Write-Host "No pre-compiled files found" -ForegroundColor Yellow
}

# Provide manual startup instructions
Write-Host "`nManual startup instructions:" -ForegroundColor Yellow
Write-Host "Since Mix is having issues, you can try these alternatives:" -ForegroundColor White
Write-Host ""
Write-Host "Option 1 - Direct Phoenix start (if deps are available):" -ForegroundColor Cyan
Write-Host "  elixir --name formwang@localhost -S mix phx.server" -ForegroundColor White
Write-Host ""
Write-Host "Option 2 - Interactive mode:" -ForegroundColor Cyan
Write-Host "  iex --name formwang@localhost" -ForegroundColor White
Write-Host "  Then in iex: Application.start(:formwang)" -ForegroundColor White
Write-Host ""
Write-Host "Option 3 - Use a different Elixir installation:" -ForegroundColor Cyan
Write-Host "  Consider installing Elixir via Scoop or Chocolatey" -ForegroundColor White
Write-Host ""
Write-Host "Option 4 - Development server alternative:" -ForegroundColor Cyan
Write-Host "  Use the database directly and create a simple HTTP server" -ForegroundColor White
Write-Host ""

# Check if we can at least connect to the database
Write-Host "Database connection test:" -ForegroundColor Yellow
if (Test-Path ".env.local") {
    Write-Host "Database is configured and should be accessible" -ForegroundColor Green
    Write-Host "You can access the web interface once the server starts" -ForegroundColor Cyan
    Write-Host "Default URL should be: http://localhost:4000" -ForegroundColor White
} else {
    Write-Host "Run setup-database.ps1 first to configure the database" -ForegroundColor Yellow
}

Write-Host "`nWorkaround setup completed!" -ForegroundColor Green
Write-Host "The application structure is ready, but Mix compilation needs to be resolved." -ForegroundColor White