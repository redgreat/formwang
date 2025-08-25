# 直接数据库初始化脚本（绕过Mix）
Write-Host "直接初始化数据库（绕过Elixir Mix）..." -ForegroundColor Green

# 数据库配置
$DB_HOST = "localhost"
$DB_PORT = "5432"
$DB_NAME = "formwang_dev"
$DB_USER = "formwang"
$DB_PASSWORD = "formwang123"

# 检查PostgreSQL是否可用
Write-Host "检查PostgreSQL连接..." -ForegroundColor Yellow
try {
    $env:PGPASSWORD = $DB_PASSWORD
    $result = psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -c "SELECT version();" 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "PostgreSQL连接成功" -ForegroundColor Green
    } else {
        throw "连接失败"
    }
} catch {
    Write-Host "PostgreSQL连接失败，请确保:" -ForegroundColor Red
    Write-Host "1. PostgreSQL服务正在运行" -ForegroundColor White
    Write-Host "2. 连接参数正确 (host: $DB_HOST, port: $DB_PORT, user: $DB_USER)" -ForegroundColor White
    Write-Host "3. 或者启动Docker数据库: docker-compose -f docker-compose.dev.yml up -d" -ForegroundColor White
    exit 1
}

# 创建数据库
Write-Host "创建数据库 $DB_NAME..." -ForegroundColor Yellow
$env:PGPASSWORD = $DB_PASSWORD
$createResult = psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -c "CREATE DATABASE $DB_NAME;" 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "数据库创建成功" -ForegroundColor Green
} else {
    Write-Host "数据库可能已存在，继续..." -ForegroundColor Yellow
}

# 执行初始化SQL
Write-Host "执行数据库初始化脚本..." -ForegroundColor Yellow
if (Test-Path "init.sql") {
    $env:PGPASSWORD = $DB_PASSWORD
    $initResult = psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f "init.sql"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "数据库初始化成功" -ForegroundColor Green
    } else {
        Write-Host "数据库初始化失败" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "未找到init.sql文件，跳过初始化" -ForegroundColor Yellow
}

# 创建基础表结构（如果init.sql不存在）
Write-Host "创建基础表结构..." -ForegroundColor Yellow
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
VALUES ('admin@formwang.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/VjPyeC9/u', TRUE)
ON CONFLICT (email) DO NOTHING;

SELECT 'Database initialization completed successfully!' as result;
"@

$env:PGPASSWORD = $DB_PASSWORD
$sql | psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME

if ($LASTEXITCODE -eq 0) {
    Write-Host "数据库表结构创建成功" -ForegroundColor Green
    Write-Host "默认管理员账户: admin@formwang.com / admin123" -ForegroundColor Cyan
} else {
    Write-Host "数据库表结构创建失败" -ForegroundColor Red
    exit 1
}

Write-Host "`n数据库初始化完成！" -ForegroundColor Green
Write-Host "数据库信息:" -ForegroundColor Cyan
Write-Host "  主机: ${DB_HOST}:${DB_PORT}" -ForegroundColor White
Write-Host "  数据库: $DB_NAME" -ForegroundColor White
Write-Host "  用户: $DB_USER" -ForegroundColor White
Write-Host "  管理员账户: admin@formwang.com / admin123" -ForegroundColor White