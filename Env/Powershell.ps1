# ===============================
# PowerShell Profile Config (Dev Enhanced)
# ===============================

# ---------- 基本设置 ----------
$OutputEncoding = [Console]::OutputEncoding = [Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

# 仅在未设置时更改执行策略
if ((Get-ExecutionPolicy -Scope CurrentUser) -eq 'Restricted') {
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction SilentlyContinue
}

# ---------- 首先清除可能存在的错误别名 ----------
@('ll', 'la') | ForEach-Object {
    if (Test-Path "alias:$_") {
        Remove-Item "alias:$_" -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path "function:$_") {
        Remove-Item "function:$_" -Force -ErrorAction SilentlyContinue
    }
}

# ---------- 安全创建简单别名 ----------
$simpleAliases = @{
    ls     = 'Get-ChildItem'
    grep   = 'Select-String'
    cat    = 'Get-Content'
    rm     = 'Remove-Item'
    cp     = 'Copy-Item'
    mv     = 'Move-Item'
    which  = 'Get-Command'
    cls    = 'Clear-Host'
}

foreach ($name in $simpleAliases.Keys) {
    # 先移除已存在的别名
    if (Test-Path "alias:$name") {
        Remove-Item "alias:$name" -Force -ErrorAction SilentlyContinue
    }

    # 创建新别名
    Set-Alias -Name $name -Value $simpleAliases[$name] -Scope Global -Force -ErrorAction SilentlyContinue
}

# ---------- 优化 ll 和 la 函数 ----------
function ll {
    <#
    .SYNOPSIS
    列出所有文件和目录（包括隐藏项）
    .DESCRIPTION
    使用 Get-ChildItem -Force 显示所有项目，包括隐藏和系统文件
    .EXAMPLE
    ll
    ll *.txt
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]]$Arguments
    )

    try {
        if ($Arguments) {
            Get-ChildItem -Force @Arguments -ErrorAction Stop
        } else {
            Get-ChildItem -Force -ErrorAction Stop
        }
    } catch {
        Write-Error "错误: $_"
    }
}

function la {
    <#
    .SYNOPSIS
    仅列出隐藏文件和目录
    .DESCRIPTION
    使用 Get-ChildItem -Force -Attributes Hidden 显示所有隐藏项目
    .EXAMPLE
    la
    la *.log
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]]$Arguments
    )

    try {
        # 兼容 PowerShell 5.1 和 7+
        $params = @{
            Force = $true
            ErrorAction = 'Stop'
        }

        # 添加属性过滤器
        $params['Attributes'] = 'Hidden'
        
        if ($Arguments) {
            $params['Path'] = $Arguments
        }

        Get-ChildItem @params
    } catch {
        if ($_.Exception.Message -notlike "*没有与指定条件匹配的项*") {
            Write-Error "错误: $_"
        }
        # 没有隐藏文件时不报错
    }
}

# 智能 vi 别名
if (Get-Command vim -ErrorAction SilentlyContinue) {
    Set-Alias vi vim -Force
} elseif (Get-Command nvim -ErrorAction SilentlyContinue) {
    Set-Alias vi nvim -Force
} elseif (Get-Command code -ErrorAction SilentlyContinue) {
    Set-Alias vi code -Force
} else {
    Set-Alias vi notepad -Force
    Write-Warning "未找到 Vim/VSCode，使用记事本作为替代"
}

# ---------- 模块加载 ----------
if (Get-Module PSReadLine -ListAvailable) {
    Import-Module PSReadLine -ErrorAction SilentlyContinue

    Set-PSReadLineOption -EditMode Windows -ErrorAction SilentlyContinue
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete -ErrorAction SilentlyContinue
    Set-PSReadLineOption -ShowToolTips -ErrorAction SilentlyContinue

    # 有条件地设置预测功能
    $psrlVersion = (Get-Module PSReadLine).Version
    if ($psrlVersion -ge [Version]"2.2.0") {
        Set-PSReadLineOption -PredictionSource HistoryAndPlugin -ErrorAction SilentlyContinue
        Set-PSReadLineOption -PredictionViewStyle ListView -ErrorAction SilentlyContinue
    }
} else {
    Write-Warning "PSReadLine 模块未找到，命令行编辑功能受限"
}

# ---------- 修复的 oh-my-posh 配置 (自动定位主题) ----------
function Initialize-OhMyPosh {
    if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
        Write-Warning "oh-my-posh 未安装，跳过主题设置"
        return $false
    }

    try {
        # 获取 oh-my-posh 模块路径
        $module = Get-Module oh-my-posh -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
        if (-not $module) {
            throw "无法获取 oh-my-posh 模块路径"
        }

        $themeDir = Join-Path $module.ModuleBase "themes"
        $themePath = $null

        # 优先尝试 paradox 主题
        $paradoxTheme = Join-Path $themeDir "paradox.omp.json"
        if (Test-Path $paradoxTheme) {
            $themePath = $paradoxTheme
            Write-Host "✓ 使用 paradox 主题: $themePath" -ForegroundColor Green
        } 
        # 回退到经典主题
        else {
            $classicTheme = Join-Path $themeDir "jandedobbeleer.omp.json"
            if (Test-Path $classicTheme) {
                $themePath = $classicTheme
                Write-Host "⚠ 未找到 paradox 主题，使用经典主题: $themePath" -ForegroundColor Yellow
            }
        }

        # 最后回退到默认主题
        if (-not $themePath) {
            $defaultTheme = Join-Path $themeDir "default.omp.json"
            if (Test-Path $defaultTheme) {
                $themePath = $defaultTheme
                Write-Host "⚠ 使用默认主题: $themePath" -ForegroundColor Yellow
            }
        }

        if (-not $themePath) {
            throw "在模块目录中找不到任何主题文件"
        }

        # 初始化 oh-my-posh
        oh-my-posh init pwsh --config "$themePath" | Invoke-Expression
        return $true

    } catch {
        return $false
    }
}

$ohMyPoshLoaded = $false
try {
    $ohMyPoshLoaded = Initialize-OhMyPosh
} catch {
    Write-Warning "oh-my-posh 错误: $_"
}

# ---------- Git 分支检测 ----------
function Get-GitBranch {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        return $null
    }

    try {
        $gitDir = git rev-parse --git-dir 2>$null
        if (-not $gitDir) { return $null }
        
        $branch = git rev-parse --abbrev-ref HEAD 2>$null
        if ($branch -eq "HEAD") {
            $commit = git rev-parse --short HEAD 2>$null
            return "DETACHED ($commit)"
        }

        return $branch
    } catch {
        return $null
    }
}

# ---------- 优化提示符 - 使用完整时间格式 ----------
function prompt {
    # 使用完整日期时间格式 [2025-12-10 12:26:26]
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $path = (Get-Location).Path

    # 缩写长路径
    $shortPath = if ($path.Length -gt 60) {
        $parts = $path -split '\\'
        if ($parts.Count -gt 3) {
            "$($parts[0])\$($parts[1])\..\$($parts[-2])\$($parts[-1])"
        } else {
            $path.Substring(0, 25) + "..." + $path.Substring($path.Length - 30)
        }
    } else {
        $path
    }

    $gitBranch = ""
    $branch = Get-GitBranch
    if ($branch) {
        $gitBranch = " ($branch)"
    }

    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
    $adminMark = if ($isAdmin) { "#" } else { ">" }

    Write-Host "[$time] $shortPath$gitBranch $adminMark" -ForegroundColor Cyan -NoNewline
    return " "
}

# ---------- 修复的 rrd 相关函数 (特殊字符支持) ----------
function rrd {
    <#
    .SYNOPSIS
    运行 rradb default 命令
    .EXAMPLE
    rrd version
    rrd command with,comma and space
    #>
    param(
        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]]$Arguments
    )

    # 保留原始命令行参数
    $rawArgs = $MyInvocation.Line.Substring($MyInvocation.Line.IndexOf($MyInvocation.InvocationName) + $MyInvocation.InvocationName.Length).Trim()

    # 构建命令
    $cmd = "rradb default $rawArgs"
    Write-Host "[RUN] $cmd" -ForegroundColor Yellow

    try {
        # 使用 PowerShell 的调用操作符执行原始命令
        $expression = "rradb default $rawArgs"
        Invoke-Expression $expression
    } catch {
        Write-Error "执行错误: $_"
    }
}

function rrds {
    <#
    .SYNOPSIS
    运行 rradb default shell 命令
    .EXAMPLE
    rrds help
    rrds echo test,1
    rrds command "with spaces"
    #>
    param(
        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]]$Arguments
    )

    # 保留原始命令行参数
    $rawArgs = $MyInvocation.Line.Substring($MyInvocation.Line.IndexOf($MyInvocation.InvocationName) + $MyInvocation.InvocationName.Length).Trim()

    # 检查危险字符
    if ($rawArgs -match '[;&|`>'']') {
        Write-Error "安全错误：命令包含禁止的字符: $rawArgs"
        return
    }

    # 构建命令
    $cmd = "rradb default shell $rawArgs"
    Write-Host "[RUN] $cmd" -ForegroundColor Yellow

    try {
        $expression = "rradb default shell $rawArgs"
        Invoke-Expression $expression
    } catch {
        Write-Error "执行错误: $_"
    }
}

function rrdp {
    <#
    .SYNOPSIS
    推送文件到设备
    .PARAMETER s
    源文件路径
    .PARAMETER d
    目标路径
    .EXAMPLE
    rrdp config.txt /data/config.txt
    #>
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateScript({
            if (-not (Test-Path $_)) {
                throw "源文件不存在: $_"
            }
            if ((Get-Item $_).PSIsContainer) {
                throw "源路径必须是文件，不能是目录: $_"
            }
            return $true
        })]
        [string]$s,
        
        [Parameter(Mandatory=$true, Position=1)]
        [string]$d
    )

    $cmd = "rradb default push $s $d"
    Write-Host "[RUN] $cmd" -ForegroundColor Yellow

    try {
        & rradb default push $s $d
    } catch {
        Write-Error "执行错误: $_"
    }
}

function rrdsut {
    <#
    .SYNOPSIS
    运行 UART 测试
    .EXAMPLE
    rrdsut --port COM3
    #>
    param(
        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]]$Arguments
    )
    
    # 保留原始命令行参数
    $rawArgs = $MyInvocation.Line.Substring($MyInvocation.Line.IndexOf($MyInvocation.InvocationName) + $MyInvocation.InvocationName.Length).Trim()
    
    $cmd = "rradb default shell uart_test -t $rawArgs"
    Write-Host "[RUN] $cmd" -ForegroundColor Yellow

    try {
        $expression = "rradb default shell uart_test -t $rawArgs"
        Invoke-Expression $expression
    } catch {
        Write-Error "执行错误: $_"
    }
}

# ---------- 加载状态报告 ----------
$features = @()
$features += if (Get-Module PSReadLine) { "PSReadLine" } else { "PSReadLine (未加载)" }
$features += if ($ohMyPoshLoaded) { "oh-my-posh" } else { "oh-my-posh (未加载)" }
$features += if (Get-Command git -ErrorAction SilentlyContinue) { "Git" } else { "Git (未安装)" }
$features += if (Get-Command rradb -ErrorAction SilentlyContinue) { "rradb" } else { "rradb (未安装)" }

# Write-Host "已加载功能: $($features -join ', ')" -ForegroundColor Cyan
