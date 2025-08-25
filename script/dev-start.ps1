# 开发环境启动脚本
Write-Host "启动开发环境..." -ForegroundColor Green

# 检查.env.local文件是否存在
if (-not (Test-Path ".env.local")) {
    Write-Host "未找到数据库配置文件，运行数据库设置..." -ForegroundColor Yellow
    .\script\setup-database.ps1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "数据库设置失败，退出" -ForegroundColor Red
        exit 1
    }
}

# 加载数据库配置
Write-Host "加载数据库配置..." -ForegroundColor Yellow
if (Test-Path ".env.local") {
    Get-Content ".env.local" | ForEach-Object {
        if ($_ -match '^export\s+([^=]+)=(.*)$') {
            $name = $matches[1]
            $value = $matches[2] -replace '"', ''
            [Environment]::SetEnvironmentVariable($name, $value, "Process")
        }
    }
    Write-Host "数据库配置加载完成" -ForegroundColor Green
}

# 测试数据库连接
Write-Host "测试数据库连接..." -ForegroundColor Yellow
$env:PGPASSWORD = $env:DB_PASSWORD
$testResult = psql -h $env:DB_HOST -p $env:DB_PORT -U $env:DB_USER -d $env:DB_NAME -c "SELECT 1;" 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "数据库连接成功" -ForegroundColor Green
} else {
    Write-Host "数据库连接失败，请检查配置或运行 .\script\setup-database.ps1" -ForegroundColor Red
    exit 1
}

# 初始化数据库表结构
Write-Host "初始化数据库表结构..." -ForegroundColor Yellow
$env:PGPASSWORD = $env:DB_PASSWORD
$initResult = psql -h $env:DB_HOST -p $env:DB_PORT -U $env:DB_USER -d $env:DB_NAME -f "script\init-database.sql"
if ($LASTEXITCODE -eq 0) {
    Write-Host "数据库表结构初始化成功" -ForegroundColor Green
} else {
    Write-Host "数据库表结构初始化失败" -ForegroundColor Red
    exit 1
}

# 尝试安装依赖（如果Elixir环境正常）
Write-Host "检查Elixir环境..." -ForegroundColor Yellow
try {
    $elixirTest = elixir --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Elixir环境正常，安装依赖..." -ForegroundColor Yellow
        
        # 清理可能的编译问题
        if (Test-Path "_build") { Remove-Item -Recurse -Force "_build" -ErrorAction SilentlyContinue }
        
        # 安装依赖
        mix deps.get 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "依赖安装成功" -ForegroundColor Green
            
            # 安装前端依赖
            Write-Host "安装前端依赖..." -ForegroundColor Yellow
            mix assets.setup 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "前端依赖安装成功" -ForegroundColor Green
            } else {
                Write-Host "前端依赖安装失败，但可以手动处理" -ForegroundColor Yellow
            }
        } else {
            Write-Host "依赖安装失败，可能需要修复Elixir环境" -ForegroundColor Yellow
            Write-Host "运行 .\script\fix-elixir.ps1 或 .\script\reinstall-elixir.ps1" -ForegroundColor Cyan
        }
    } else {
        throw "Elixir版本检查失败"
    }
} catch {
    Write-Host "Elixir环境存在问题，跳过依赖安装" -ForegroundColor Yellow
    Write-Host "运行 .\script\fix-elixir.ps1 或 .\script\reinstall-elixir.ps1 修复" -ForegroundColor Cyan
}

Write-Host "`n开发环境准备完成！" -ForegroundColor Green
Write-Host "数据库已初始化，管理员账户: admin@formwang.com / admin123" -ForegroundColor Cyan
Write-Host "`n启动选项:" -ForegroundColor Yellow
Write-Host "1. 如果Elixir环境正常: mix phx.server" -ForegroundColor White
Write-Host "2. 如果Elixir有问题: 先运行 .\script\fix-elixir.ps1" -ForegroundColor White
Write-Host "3. 重新安装Elixir: .\script\reinstall-elixir.ps1" -ForegroundColor White