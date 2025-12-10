# ===============================
# PowerShell Profile Config (Dev Enhanced)
# ===============================

# ---------- 基本设置 ----------
$OutputEncoding = [Console]::OutputEncoding = [Text.Encoding]::UTF8
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# ---------- Linux 风格别名（安全创建） ----------
$aliases = @{
    ls = 'Get-ChildItem'
    ll = 'Get-ChildItem -Force'
    la = 'Get-ChildItem -Force'
    grep = 'Select-String'
    cat = 'Get-Content'
    rm = 'Remove-Item'
    cp = 'Copy-Item'
    mv = 'Move-Item'
    which = 'Get-Command'
    vi = 'notepad'
    cls = 'Clear-Host'
}

foreach ($name in $aliases.Keys) {
    if (-not (Get-Alias $name -ErrorAction SilentlyContinue)) {
        Set-Alias -Name $name -Value $aliases[$name] -Scope Local
    }
}

# ---------- 模块加载 ----------
Import-Module PSReadLine
# ---------- 编辑行为 ----------
Set-PSReadLineOption -EditMode Windows
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
# ---------- 自动补全与预测 ----------
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -ShowToolTips

# oh-my-posh 美化提示符
$themePath = "$env:POSH_THEMES_PATH\paradox.omp.json"
if (Test-Path $themePath) {
    oh-my-posh init pwsh --config $themePath | Invoke-Expression
}

# ---------- 彩色提示符 + Git 分支 ----------
function prompt {
    # 当前目录
    $path = (Get-Location).Path

    # 当前 Git 分支
    $gitBranch = ""
    if (Test-Path .git) {
        try {
            $branchName = git branch --show-current 2>$null
            if ($branchName) {
                $gitBranch = " ($branchName)"
            }
        } catch {}
    }

    # 时间戳
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # 彩色输出
    Write-Host "[$time] $path$gitBranch >" -ForegroundColor Cyan -NoNewline
    return " "
}

function rrd {
    $cmd = "rradb default $args"
    Write-Host "[RUN] $cmd" -ForegroundColor Yellow
    Invoke-Expression $cmd
}

function rrds {
    # 获取原始命令行
    $rawCommand = $MyInvocation.Line
    # 提取函数名称后的部分
    $commandPattern = [regex]::Escape($MyInvocation.InvocationName)
    $arguments = $rawCommand -replace "^\s*$commandPattern\s+", ""

    # 基本安全检查：禁止命令分隔符
    if ($arguments -match '[;&|>]') {
        Write-Error "命令包含禁止的字符: $arguments"
        return
    }

    $cmd = "rradb default shell $arguments"
    Write-Host "[RUN] $cmd" -ForegroundColor Yellow
    Invoke-Expression $cmd
}

function rrdp {
    param(
        [Parameter(Mandatory=$true)]
        [string]$s,   # 本地源文件路径

        [Parameter(Mandatory=$true)]
        [string]$d    # 远程目标路径
    )

    # 调用原始命令
    $cmd = "rradb default push $s $d"
    Write-Host "[RUN] $cmd" -ForegroundColor Yellow
    Invoke-Expression $cmd
}

function rrdsut {
    $cmd = "rradb default shell uart_test -t $args"
    Write-Host "[RUN] $cmd" -ForegroundColor Yellow
    Invoke-Expression $cmd
}

# ---------- 提示 ----------
Write-Host "PowerShell Enhanced Profile Loaded." -ForegroundColor Green
