# 开发环境启动脚本
Write-Host "启动开发环境..." -ForegroundColor Green

# 启动数据库
Write-Host "启动PostgreSQL数据库..." -ForegroundColor Yellow
docker-compose -f docker-compose.dev.yml up -d

# 等待数据库启动
Write-Host "等待数据库启动..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# 安装依赖
Write-Host "安装依赖..." -ForegroundColor Yellow
mix deps.get

# 创建数据库
Write-Host "创建数据库..." -ForegroundColor Yellow
mix ecto.create

# 运行迁移
Write-Host "运行数据库迁移..." -ForegroundColor Yellow
mix ecto.migrate

# 安装前端依赖
Write-Host "安装前端依赖..." -ForegroundColor Yellow
mix assets.setup

Write-Host "开发环境准备完成！" -ForegroundColor Green
Write-Host "运行 'mix phx.server' 启动开发服务器" -ForegroundColor Cyan