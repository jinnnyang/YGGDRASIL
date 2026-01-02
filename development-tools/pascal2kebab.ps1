# 简单实用的 Pascal Case 转 kebab-case 脚本
# 正确处理方法

param(
    [string]$Dir = ".",
    [switch]$Preview
)

# 正确转换函数
function Convert-ToKebab {
    param([string]$text)
    
    # 空值处理
    if ([string]::IsNullOrEmpty($text)) { return $text }
    
    # 方法：使用正则表达式匹配单词边界
    # 匹配：1) 小写字母后的大写字母 2) 数字后的大写字母 3) 大写字母后的大写字母+小写字母
    $pattern = '(?<=[a-z0-9])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])'
    
    # 插入分隔符
    $result = [System.Text.RegularExpressions.Regex]::Replace($text, $pattern, '-')
    
    # 替换空格
    $result = $result -replace '\s+', '-'
    
    # 转换为小写
    $result = $result.ToLower()
    
    # 清理
    $result = $result.Trim('-') -replace '-+', '-'
    
    return $result
}

Write-Host "Pascal Case → kebab-case 转换" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan

# 测试
Write-Host "测试示例：" -ForegroundColor Yellow
$examples = @(
    "Hyperparameter Optimization",
    "CICD Pipeline and Docker",
    "Advanced Features",
    "DeepWiki",
    "MyFileName"
)

foreach ($ex in $examples) {
    $kebab = Convert-ToKebab $ex
    Write-Host "  $ex → $kebab" -ForegroundColor Green
}

Write-Host "`n处理文件..." -ForegroundColor Yellow

# 处理文件
Get-ChildItem -Path $Dir -File | ForEach-Object {
    $name = $_.BaseName
    $ext = $_.Extension
    
    $newName = (Convert-ToKebab $name) + $ext
    
    if ($newName -ne $_.Name) {
        Write-Host "$($_.Name) → $newName" -ForegroundColor Green
        
        if (-not $Preview) {
            try {
                Rename-Item -Path $_.FullName -NewName $newName -ErrorAction Stop
            } catch {
                Write-Host "  错误: $_" -ForegroundColor Red
            }
        }
    }
}

if ($Preview) {
    Write-Host "`n预览模式完成" -ForegroundColor Magenta
} else {
    Write-Host "`n转换完成" -ForegroundColor Green
}

Write-Host "`n使用: .\pascal2kebab.ps1 [-Dir 路径] [-Preview]" -ForegroundColor Cyan
