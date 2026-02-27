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
$features += if (Get-Command git -ErrorAction SilentlyContinue) { "Git" } else { "Git (未安装)" }
$features += if (Get-Command rradb -ErrorAction SilentlyContinue) { "rradb" } else { "rradb (未安装)" }
