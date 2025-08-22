# 生产环境部署脚本
Write-Host "开始部署生产环境..." -ForegroundColor Green

# 检查环境变量
if (-not $env:SECRET_KEY_BASE) {
    Write-Host "错误: 请设置 SECRET_KEY_BASE 环境变量" -ForegroundColor Red
    Write-Host "运行: mix phx.gen.secret" -ForegroundColor Yellow
    exit 1
}

if (-not $env:DATABASE_URL) {
    Write-Host "错误: 请设置 DATABASE_URL 环境变量" -ForegroundColor Red
    Write-Host "格式: ecto://user:password@host/database" -ForegroundColor Yellow
    Write-Host "示例: ecto://formwang:formwang123@localhost/formwang_prod" -ForegroundColor Yellow
    exit 1
}

# 构建Docker镜像
Write-Host "构建Docker镜像..." -ForegroundColor Yellow
docker-compose build

# 启动服务
Write-Host "启动服务..." -ForegroundColor Yellow
docker-compose up -d

# 等待服务启动
Write-Host "等待服务启动..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

# 运行数据库迁移
Write-Host "运行数据库迁移..." -ForegroundColor Yellow
docker-compose exec web bin/formwang eval "Formwang.Release.migrate"

Write-Host "部署完成！" -ForegroundColor Green
Write-Host "应用已在 http://localhost:4000 运行" -ForegroundColor Cyan