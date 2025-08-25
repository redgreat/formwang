# 数据库设置和初始化脚本
Write-Host "FormWang 数据库设置向导" -ForegroundColor Green
Write-Host "=========================" -ForegroundColor Green

# 检查Docker Desktop状态
function Test-DockerRunning {
    try {
        $result = docker version 2>$null
        return $LASTEXITCODE -eq 0
    } catch {
        return $false
    }
}

# 检查PostgreSQL服务状态
function Test-PostgreSQLService {
    try {
        $service = Get-Service -Name "postgresql*" -ErrorAction SilentlyContinue
        return $service -and $service.Status -eq "Running"
    } catch {
        return $false
    }
}

# 测试数据库连接
function Test-DatabaseConnection {
    param(
        [string]$DbHost,
        [string]$DbPort,
        [string]$DbUser,
        [string]$DbPassword,
        [string]$DbDatabase = "postgres"
    )
    
    try {
        $env:PGPASSWORD = $DbPassword
        $result = psql -h $DbHost -p $DbPort -U $DbUser -d $DbDatabase -c "SELECT 1;" 2>$null
        return $LASTEXITCODE -eq 0
    } catch {
        return $false
    }
}

Write-Host "检测数据库环境..." -ForegroundColor Yellow

# 检查Docker
$dockerRunning = Test-DockerRunning
if ($dockerRunning) {
    Write-Host "✓ Docker Desktop 正在运行" -ForegroundColor Green
} else {
    Write-Host "✗ Docker Desktop 未运行" -ForegroundColor Red
}

# 检查本地PostgreSQL服务
$pgServiceRunning = Test-PostgreSQLService
if ($pgServiceRunning) {
    Write-Host "✓ 本地PostgreSQL服务正在运行" -ForegroundColor Green
} else {
    Write-Host "✗ 本地PostgreSQL服务未运行" -ForegroundColor Red
}

# 数据库连接配置选项
$configs = @(
    @{
        Name = "Docker数据库 (推荐)"
        Host = "localhost"
        Port = "5432"
        User = "formwang"
        Password = "formwang123"
        Database = "formwang_dev"
        RequiresDocker = $true
    },
    @{
        Name = "本地PostgreSQL (默认配置)"
        Host = "localhost"
        Port = "5432"
        User = "postgres"
        Password = "postgres"
        Database = "formwang_dev"
        RequiresDocker = $false
    }
)

Write-Host "`n可用的数据库配置:" -ForegroundColor Cyan

$availableConfigs = @()
for ($i = 0; $i -lt $configs.Count; $i++) {
    $config = $configs[$i]
    $index = $i + 1
    
    if ($config.RequiresDocker -and -not $dockerRunning) {
        Write-Host "$index. $($config.Name) - 需要启动Docker" -ForegroundColor Yellow
        continue
    }
    
    $connected = Test-DatabaseConnection -DbHost $config.Host -DbPort $config.Port -DbUser $config.User -DbPassword $config.Password
    if ($connected) {
        Write-Host "$index. $($config.Name) - ✓ 可连接" -ForegroundColor Green
        $availableConfigs += @{ Index = $index; Config = $config }
    } else {
        Write-Host "$index. $($config.Name) - ✗ 无法连接" -ForegroundColor Red
    }
}

# 如果没有可用配置，提供设置选项
if ($availableConfigs.Count -eq 0) {
    Write-Host "`n没有找到可用的数据库连接，请选择设置方式:" -ForegroundColor Yellow
    Write-Host "1. 启动Docker数据库 (推荐)" -ForegroundColor White
    Write-Host "2. 手动配置数据库连接" -ForegroundColor White
    Write-Host "3. 安装本地PostgreSQL" -ForegroundColor White
    
    $setupChoice = Read-Host "`n请选择 (1/2/3)"
    
    switch ($setupChoice) {
        "1" {
            if (-not $dockerRunning) {
                Write-Host "请先启动Docker Desktop，然后重新运行此脚本" -ForegroundColor Red
                Write-Host "或者运行: docker-compose -f docker-compose.dev.yml up -d db" -ForegroundColor Yellow
                exit 1
            }
            
            Write-Host "启动Docker数据库..." -ForegroundColor Yellow
            docker-compose -f docker-compose.dev.yml up -d db
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Docker数据库启动成功，等待5秒..." -ForegroundColor Green
                Start-Sleep -Seconds 5
                
                # 重新测试连接
                $dockerConfig = $configs[0]
                $connected = Test-DatabaseConnection -DbHost $dockerConfig.Host -DbPort $dockerConfig.Port -DbUser $dockerConfig.User -DbPassword $dockerConfig.Password
                if ($connected) {
                    $selectedConfig = $dockerConfig
                } else {
                    Write-Host "Docker数据库启动后仍无法连接，请检查配置" -ForegroundColor Red
                    exit 1
                }
            } else {
                Write-Host "Docker数据库启动失败" -ForegroundColor Red
                exit 1
            }
        }
        "2" {
            Write-Host "请手动配置数据库连接参数:" -ForegroundColor Cyan
            $customHost = Read-Host "主机地址 (默认: localhost)"
            $customPort = Read-Host "端口 (默认: 5432)"
            $customUser = Read-Host "用户名"
            $customPassword = Read-Host "密码" -AsSecureString
            $customDatabase = Read-Host "数据库名 (默认: formwang_dev)"
            
            if ([string]::IsNullOrEmpty($customHost)) { $customHost = "localhost" }
            if ([string]::IsNullOrEmpty($customPort)) { $customPort = "5432" }
            if ([string]::IsNullOrEmpty($customDatabase)) { $customDatabase = "formwang_dev" }
            
            $plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($customPassword))
            
            $selectedConfig = @{
                Host = $customHost
                Port = $customPort
                User = $customUser
                Password = $plainPassword
                Database = $customDatabase
            }
            
            $connected = Test-DatabaseConnection -DbHost $selectedConfig.Host -DbPort $selectedConfig.Port -DbUser $selectedConfig.User -DbPassword $selectedConfig.Password
            if (-not $connected) {
                Write-Host "无法连接到指定的数据库，请检查配置" -ForegroundColor Red
                exit 1
            }
        }
        "3" {
            Write-Host "请访问以下链接安装PostgreSQL:" -ForegroundColor Cyan
            Write-Host "https://www.postgresql.org/download/windows/" -ForegroundColor White
            Write-Host "安装完成后重新运行此脚本" -ForegroundColor Yellow
            exit 0
        }
        default {
            Write-Host "无效选择" -ForegroundColor Red
            exit 1
        }
    }
} else {
    # 选择可用的配置
    if ($availableConfigs.Count -eq 1) {
        $selectedConfig = $availableConfigs[0].Config
        Write-Host "`n自动选择: $($selectedConfig.Name)" -ForegroundColor Green
    } else {
        Write-Host "`n请选择要使用的数据库配置:" -ForegroundColor Cyan
        foreach ($item in $availableConfigs) {
            Write-Host "$($item.Index). $($item.Config.Name)" -ForegroundColor White
        }
        
        $choice = Read-Host "`n请选择"
        $selectedItem = $availableConfigs | Where-Object { $_.Index -eq [int]$choice }
        
        if (-not $selectedItem) {
            Write-Host "无效选择" -ForegroundColor Red
            exit 1
        }
        
        $selectedConfig = $selectedItem.Config
    }
}

Write-Host "`n使用数据库配置:" -ForegroundColor Green
Write-Host "主机: $($selectedConfig.Host):$($selectedConfig.Port)" -ForegroundColor White
Write-Host "用户: $($selectedConfig.User)" -ForegroundColor White
Write-Host "数据库: $($selectedConfig.Database)" -ForegroundColor White

# 初始化数据库
Write-Host "`n初始化数据库..." -ForegroundColor Yellow

# 创建数据库（如果不存在）
$env:PGPASSWORD = $selectedConfig.Password
$createResult = psql -h $selectedConfig.Host -p $selectedConfig.Port -U $selectedConfig.User -d postgres -c "CREATE DATABASE $($selectedConfig.Database);" 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "数据库创建成功" -ForegroundColor Green
} else {
    Write-Host "数据库可能已存在，继续..." -ForegroundColor Yellow
}

# 创建表结构
Write-Host "创建表结构..." -ForegroundColor Yellow
$sql = @"
-- 用户表
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    is_admin BOOLEAN DEFAULT FALSE,
    inserted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 表单表
CREATE TABLE IF NOT EXISTS forms (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    user_id INTEGER REFERENCES users(id),
    public_token VARCHAR(255) UNIQUE,
    private_token VARCHAR(255) UNIQUE,
    is_active BOOLEAN DEFAULT TRUE,
    inserted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 字段表
CREATE TABLE IF NOT EXISTS form_fields (
    id SERIAL PRIMARY KEY,
    form_id INTEGER REFERENCES forms(id) ON DELETE CASCADE,
    field_type VARCHAR(50) NOT NULL,
    label VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    is_required BOOLEAN DEFAULT FALSE,
    options JSONB,
    position INTEGER DEFAULT 0,
    inserted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 提交记录表
CREATE TABLE IF NOT EXISTS form_submissions (
    id SERIAL PRIMARY KEY,
    form_id INTEGER REFERENCES forms(id) ON DELETE CASCADE,
    data JSONB NOT NULL,
    ip_address INET,
    user_agent TEXT,
    inserted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_forms_user_id ON forms(user_id);
CREATE INDEX IF NOT EXISTS idx_forms_public_token ON forms(public_token);
CREATE INDEX IF NOT EXISTS idx_forms_private_token ON forms(private_token);
CREATE INDEX IF NOT EXISTS idx_form_fields_form_id ON form_fields(form_id);
CREATE INDEX IF NOT EXISTS idx_form_submissions_form_id ON form_submissions(form_id);
CREATE INDEX IF NOT EXISTS idx_form_submissions_inserted_at ON form_submissions(inserted_at);

-- 插入默认管理员用户（密码: admin123）
INSERT INTO users (email, password_hash, is_admin) 
VALUES ('admin@formwang.com', '\$2b\$12\$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/VjPyeC9/u', TRUE)
ON CONFLICT (email) DO NOTHING;

SELECT 'Database initialization completed successfully!' as result;
"@

$env:PGPASSWORD = $selectedConfig.Password
$sql | psql -h $selectedConfig.Host -p $selectedConfig.Port -U $selectedConfig.User -d $selectedConfig.Database

if ($LASTEXITCODE -eq 0) {
    Write-Host "数据库初始化成功！" -ForegroundColor Green
    Write-Host "`n数据库连接信息:" -ForegroundColor Cyan
    Write-Host "主机: $($selectedConfig.Host):$($selectedConfig.Port)" -ForegroundColor White
    Write-Host "数据库: $($selectedConfig.Database)" -ForegroundColor White
    Write-Host "用户: $($selectedConfig.User)" -ForegroundColor White
    Write-Host "管理员账户: admin@formwang.com / admin123" -ForegroundColor Yellow
    
    # 更新配置文件
    Write-Host "`n更新项目配置文件..." -ForegroundColor Yellow
    $configContent = @"
# Database Configuration
export DATABASE_URL="postgresql://$($selectedConfig.User):$($selectedConfig.Password)@$($selectedConfig.Host):$($selectedConfig.Port)/$($selectedConfig.Database)"
export DB_HOST="$($selectedConfig.Host)"
export DB_PORT="$($selectedConfig.Port)"
export DB_USER="$($selectedConfig.User)"
export DB_PASSWORD="$($selectedConfig.Password)"
export DB_NAME="$($selectedConfig.Database)"
"@
    
    $configContent | Out-File -FilePath ".env.local" -Encoding UTF8
    Write-Host "配置已保存到 .env.local 文件" -ForegroundColor Green
    
    Write-Host "`n数据库设置完成！现在可以启动应用程序了" -ForegroundColor Green
} else {
    Write-Host "数据库初始化失败" -ForegroundColor Red
    exit 1
}