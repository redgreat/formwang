# Elixir完全重新安装脚本
Write-Host "Elixir环境存在严重问题，需要完全重新安装" -ForegroundColor Red
Write-Host "这是由于v3_core模块损坏导致的编译器问题" -ForegroundColor Yellow

Write-Host "`n解决方案选项:" -ForegroundColor Cyan
Write-Host "1. 使用Chocolatey重新安装 (推荐)" -ForegroundColor White
Write-Host "2. 使用Scoop重新安装" -ForegroundColor White
Write-Host "3. 手动下载安装" -ForegroundColor White

$choice = Read-Host "`n请选择安装方式 (1/2/3)"

switch ($choice) {
    "1" {
        Write-Host "使用Chocolatey重新安装Elixir..." -ForegroundColor Yellow
        
        # 检查Chocolatey是否安装
        if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
            Write-Host "Chocolatey未安装，正在安装..." -ForegroundColor Yellow
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        }
        
        # 卸载现有Elixir
        Write-Host "卸载现有Elixir..." -ForegroundColor Yellow
        choco uninstall elixir -y
        
        # 重新安装Elixir
        Write-Host "重新安装Elixir..." -ForegroundColor Yellow
        choco install elixir -y
    }
    "2" {
        Write-Host "使用Scoop重新安装Elixir..." -ForegroundColor Yellow
        
        # 检查Scoop是否安装
        if (!(Get-Command scoop -ErrorAction SilentlyContinue)) {
            Write-Host "Scoop未安装，正在安装..." -ForegroundColor Yellow
            Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
            irm get.scoop.sh | iex
        }
        
        # 卸载现有Elixir
        Write-Host "卸载现有Elixir..." -ForegroundColor Yellow
        scoop uninstall elixir
        
        # 重新安装Elixir
        Write-Host "重新安装Elixir..." -ForegroundColor Yellow
        scoop install elixir
    }
    "3" {
        Write-Host "请手动执行以下步骤:" -ForegroundColor Cyan
        Write-Host "1. 访问 https://elixir-lang.org/install.html#windows" -ForegroundColor White
        Write-Host "2. 下载Windows安装包" -ForegroundColor White
        Write-Host "3. 卸载当前Elixir版本" -ForegroundColor White
        Write-Host "4. 安装新版本" -ForegroundColor White
        Write-Host "5. 重启PowerShell" -ForegroundColor White
        Write-Host "6. 运行 elixir --version 验证安装" -ForegroundColor White
        exit 0
    }
    default {
        Write-Host "无效选择，退出" -ForegroundColor Red
        exit 1
    }
}

# 验证安装
Write-Host "`n验证Elixir安装..." -ForegroundColor Yellow
try {
    $version = elixir --version
    Write-Host "Elixir安装成功:" -ForegroundColor Green
    Write-Host $version -ForegroundColor White
} catch {
    Write-Host "Elixir安装失败，请手动安装" -ForegroundColor Red
    exit 1
}

# 重新初始化项目
Write-Host "`n重新初始化项目..." -ForegroundColor Yellow

# 清理旧文件
if (Test-Path "_build") { Remove-Item -Recurse -Force "_build" }
if (Test-Path "deps") { Remove-Item -Recurse -Force "deps" }

# 重新安装Mix工具
mix local.hex --force
mix local.rebar --force

# 获取依赖
mix deps.get

# 编译项目
mix compile

Write-Host "`nElixir重新安装完成！" -ForegroundColor Green
Write-Host "现在可以运行项目了" -ForegroundColor Cyan