# Elixir环境修复脚本
Write-Host "检测到Elixir编译器问题，开始修复..." -ForegroundColor Yellow

# 检查Elixir版本
Write-Host "当前Elixir版本:" -ForegroundColor Cyan
elixir --version

# 清理所有编译缓存
Write-Host "清理编译缓存..." -ForegroundColor Yellow
if (Test-Path "_build") {
    Remove-Item -Recurse -Force "_build"
    Write-Host "已删除 _build 目录" -ForegroundColor Green
}

if (Test-Path "deps") {
    Remove-Item -Recurse -Force "deps"
    Write-Host "已删除 deps 目录" -ForegroundColor Green
}

# 清理Mix缓存
Write-Host "清理Mix缓存..." -ForegroundColor Yellow
try {
    mix local.hex --force
    mix local.rebar --force
    Write-Host "Mix工具已重新安装" -ForegroundColor Green
} catch {
    Write-Host "Mix工具重新安装失败: $_" -ForegroundColor Red
}

# 重新获取依赖
Write-Host "重新获取依赖..." -ForegroundColor Yellow
try {
    mix deps.get
    Write-Host "依赖获取成功" -ForegroundColor Green
} catch {
    Write-Host "依赖获取失败: $_" -ForegroundColor Red
    Write-Host "建议重新安装Elixir" -ForegroundColor Yellow
    exit 1
}

# 强制重新编译
Write-Host "强制重新编译..." -ForegroundColor Yellow
try {
    mix compile --force
    Write-Host "编译成功" -ForegroundColor Green
} catch {
    Write-Host "编译失败: $_" -ForegroundColor Red
    Write-Host "可能需要重新安装Elixir/Erlang" -ForegroundColor Yellow
    
    Write-Host "建议解决方案:" -ForegroundColor Cyan
    Write-Host "1. 重新安装Elixir: https://elixir-lang.org/install.html" -ForegroundColor White
    Write-Host "2. 或使用Chocolatey: choco install elixir" -ForegroundColor White
    Write-Host "3. 或使用Scoop: scoop install elixir" -ForegroundColor White
    exit 1
}

Write-Host "Elixir环境修复完成！" -ForegroundColor Green
Write-Host "现在可以运行 'mix phx.server' 启动开发服务器" -ForegroundColor Cyan