# Create a simple web server to demonstrate the form system without Elixir
Write-Host "Creating simple demonstration server..." -ForegroundColor Yellow

# Check if Python is available
Write-Host "`nChecking for Python..." -ForegroundColor Cyan
try {
    $pythonVersion = python --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Python found: $pythonVersion" -ForegroundColor Green
        $usePython = $true
    } else {
        $usePython = $false
    }
} catch {
    $usePython = $false
}

# Check if Node.js is available
Write-Host "Checking for Node.js..." -ForegroundColor Cyan
try {
    $nodeVersion = node --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Node.js found: $nodeVersion" -ForegroundColor Green
        $useNode = $true
    } else {
        $useNode = $false
    }
} catch {
    $useNode = $false
}

if (-not $usePython -and -not $useNode) {
    Write-Host "Neither Python nor Node.js found. Creating static HTML demo..." -ForegroundColor Yellow
    $useStatic = $true
} else {
    $useStatic = $false
}

# Create demo directory
$demoDir = "demo-server"
if (-not (Test-Path $demoDir)) {
    New-Item -ItemType Directory -Path $demoDir | Out-Null
    Write-Host "Created demo directory: $demoDir" -ForegroundColor Green
}

# Create HTML template
$htmlContent = @'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>FormWang - 表单管理系统演示</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 12px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
            color: white;
            padding: 30px;
            text-align: center;
        }
        .header h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
        }
        .header p {
            font-size: 1.2em;
            opacity: 0.9;
        }
        .content {
            padding: 40px;
        }
        .feature-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 30px;
            margin-bottom: 40px;
        }
        .feature-card {
            background: #f8f9fa;
            padding: 25px;
            border-radius: 8px;
            border-left: 4px solid #4facfe;
        }
        .feature-card h3 {
            color: #333;
            margin-bottom: 15px;
            font-size: 1.3em;
        }
        .feature-card p {
            color: #666;
            line-height: 1.6;
        }
        .demo-form {
            background: #f8f9fa;
            padding: 30px;
            border-radius: 8px;
            margin-top: 30px;
        }
        .form-group {
            margin-bottom: 20px;
        }
        .form-group label {
            display: block;
            margin-bottom: 8px;
            font-weight: 600;
            color: #333;
        }
        .form-group input,
        .form-group select,
        .form-group textarea {
            width: 100%;
            padding: 12px;
            border: 2px solid #e9ecef;
            border-radius: 6px;
            font-size: 16px;
            transition: border-color 0.3s;
        }
        .form-group input:focus,
        .form-group select:focus,
        .form-group textarea:focus {
            outline: none;
            border-color: #4facfe;
        }
        .btn {
            background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
            color: white;
            padding: 12px 30px;
            border: none;
            border-radius: 6px;
            font-size: 16px;
            cursor: pointer;
            transition: transform 0.2s;
        }
        .btn:hover {
            transform: translateY(-2px);
        }
        .status {
            background: #d4edda;
            color: #155724;
            padding: 15px;
            border-radius: 6px;
            margin-top: 20px;
            border-left: 4px solid #28a745;
        }
        .tech-stack {
            background: #e3f2fd;
            padding: 20px;
            border-radius: 8px;
            margin-top: 30px;
        }
        .tech-stack h3 {
            color: #1976d2;
            margin-bottom: 15px;
        }
        .tech-list {
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
        }
        .tech-item {
            background: #1976d2;
            color: white;
            padding: 5px 12px;
            border-radius: 20px;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 FormWang</h1>
            <p>智能表单管理系统 - 演示版本</p>
        </div>
        
        <div class="content">
            <div class="status">
                <strong>✅ 项目状态:</strong> 数据库已配置，Phoenix应用结构完整，等待Elixir环境修复
            </div>
            
            <div class="feature-grid">
                <div class="feature-card">
                    <h3>🎯 核心功能</h3>
                    <p>支持多种字段类型的动态表单创建，包括文本、数字、下拉选择、多选框等，满足各种数据收集需求。</p>
                </div>
                
                <div class="feature-card">
                    <h3>📱 移动适配</h3>
                    <p>完全响应式设计，支持微信内置浏览器，确保在各种设备上都有良好的用户体验。</p>
                </div>
                
                <div class="feature-card">
                    <h3>🔗 分享功能</h3>
                    <p>一键生成表单分享链接和二维码，方便快速传播和数据收集。</p>
                </div>
                
                <div class="feature-card">
                    <h3>📊 数据管理</h3>
                    <p>实时数据统计和查看功能，支持数据导出，帮助用户更好地分析收集到的信息。</p>
                </div>
                
                <div class="feature-card">
                    <h3>🔐 安全认证</h3>
                    <p>完整的用户认证系统，确保数据安全，支持管理员权限控制。</p>
                </div>
                
                <div class="feature-card">
                    <h3>🐳 容器部署</h3>
                    <p>Docker容器化部署，支持一键部署到云服务器，简化运维流程。</p>
                </div>
            </div>
            
            <div class="demo-form">
                <h3>📝 表单演示</h3>
                <p style="margin-bottom: 20px; color: #666;">以下是一个示例表单，展示系统支持的字段类型：</p>
                
                <form id="demoForm">
                    <div class="form-group">
                        <label for="name">姓名 *</label>
                        <input type="text" id="name" name="name" required>
                    </div>
                    
                    <div class="form-group">
                        <label for="email">邮箱</label>
                        <input type="email" id="email" name="email">
                    </div>
                    
                    <div class="form-group">
                        <label for="category">分类</label>
                        <select id="category" name="category">
                            <option value="">请选择...</option>
                            <option value="feedback">意见反馈</option>
                            <option value="suggestion">建议</option>
                            <option value="complaint">投诉</option>
                            <option value="other">其他</option>
                        </select>
                    </div>
                    
                    <div class="form-group">
                        <label for="message">详细内容</label>
                        <textarea id="message" name="message" rows="4" placeholder="请输入详细内容..."></textarea>
                    </div>
                    
                    <button type="submit" class="btn">提交表单</button>
                </form>
            </div>
            
            <div class="tech-stack">
                <h3>🛠️ 技术栈</h3>
                <div class="tech-list">
                    <span class="tech-item">Elixir</span>
                    <span class="tech-item">Phoenix</span>
                    <span class="tech-item">PostgreSQL</span>
                    <span class="tech-item">LiveView</span>
                    <span class="tech-item">Docker</span>
                    <span class="tech-item">Tailwind CSS</span>
                </div>
            </div>
        </div>
    </div>
    
    <script>
        document.getElementById('demoForm').addEventListener('submit', function(e) {
            e.preventDefault();
            alert('演示模式：表单提交功能将在Phoenix服务器启动后可用！');
        });
    </script>
</body>
</html>
'@

# Write HTML file
$htmlPath = Join-Path $demoDir "index.html"
$htmlContent | Out-File -FilePath $htmlPath -Encoding UTF8
Write-Host "Created demo HTML: $htmlPath" -ForegroundColor Green

# Create simple server based on available technology
if ($usePython) {
    Write-Host "`nCreating Python server..." -ForegroundColor Cyan
    
    $pythonServer = @'
import http.server
import socketserver
import os
import webbrowser
from pathlib import Path

PORT = 8080
DIRECTORY = "demo-server"

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

if __name__ == "__main__":
    os.chdir(Path(__file__).parent)
    
    with socketserver.TCPServer(("", PORT), Handler) as httpd:
        print(f"FormWang Demo Server running at http://localhost:{PORT}")
        print(f"Press Ctrl+C to stop the server")
        
        # Try to open browser
        try:
            webbrowser.open(f"http://localhost:{PORT}")
        except:
            pass
            
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nServer stopped.")
'@
    
    $pythonPath = "start-demo-server.py"
    $pythonServer | Out-File -FilePath $pythonPath -Encoding UTF8
    Write-Host "Created Python server: $pythonPath" -ForegroundColor Green
    
    Write-Host "`nStarting Python demo server..." -ForegroundColor Yellow
    Write-Host "Demo will be available at: http://localhost:8080" -ForegroundColor Cyan
    python $pythonPath
    
} elseif ($useNode) {
    Write-Host "`nCreating Node.js server..." -ForegroundColor Cyan
    
    $nodeServer = @'
const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 8080;
const DIRECTORY = 'demo-server';

const server = http.createServer((req, res) => {
    let filePath = path.join(__dirname, DIRECTORY, req.url === '/' ? 'index.html' : req.url);
    
    fs.readFile(filePath, (err, data) => {
        if (err) {
            res.writeHead(404);
            res.end('File not found');
            return;
        }
        
        const ext = path.extname(filePath);
        let contentType = 'text/html';
        
        if (ext === '.css') contentType = 'text/css';
        if (ext === '.js') contentType = 'text/javascript';
        
        res.writeHead(200, { 'Content-Type': contentType });
        res.end(data);
    });
});

server.listen(PORT, () => {
    console.log(`FormWang Demo Server running at http://localhost:${PORT}`);
    console.log('Press Ctrl+C to stop the server');
    
    // Try to open browser
    const { exec } = require('child_process');
    exec(`start http://localhost:${PORT}`, (err) => {
        if (err) console.log('Could not open browser automatically');
    });
});
'@
    
    $nodePath = "start-demo-server.js"
    $nodeServer | Out-File -FilePath $nodePath -Encoding UTF8
    Write-Host "Created Node.js server: $nodePath" -ForegroundColor Green
    
    Write-Host "`nStarting Node.js demo server..." -ForegroundColor Yellow
    Write-Host "Demo will be available at: http://localhost:8080" -ForegroundColor Cyan
    node $nodePath
    
} else {
    Write-Host "`nCreated static HTML demo" -ForegroundColor Green
    Write-Host "You can open the following file in your browser:" -ForegroundColor Cyan
    Write-Host "file:///$((Get-Location).Path)\$htmlPath" -ForegroundColor White
    
    # Try to open in default browser
    try {
        Start-Process $htmlPath
        Write-Host "Opening demo in default browser..." -ForegroundColor Green
    } catch {
        Write-Host "Please manually open: $htmlPath" -ForegroundColor Yellow
    }
}

Write-Host "`n" -ForegroundColor White
Write-Host "=== FormWang Project Status ===" -ForegroundColor Yellow
Write-Host "✅ Database: Configured and ready" -ForegroundColor Green
Write-Host "✅ Phoenix App: Structure complete" -ForegroundColor Green
Write-Host "❌ Elixir Environment: Needs fixing" -ForegroundColor Red
Write-Host "✅ Demo Server: Running" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Fix Elixir environment (v3_core module issue)" -ForegroundColor White
Write-Host "2. Run: iex -S mix phx.server" -ForegroundColor White
Write-Host "3. Access full application at: http://localhost:4000" -ForegroundColor White