# WSL 环境下 pre-commit 因 Windows PATH 触发报错问题梳理

## 问题现象

在 WSL 环境下执行 `git pushmr origin develop`，流程主体可以成功创建分支和 Merge Request，但最后会出现类似报错：

```sh
.git/hooks/pre-commit: 27: export: Files/Microsoft: bad variable name
```

同类问题也可能出现在普通的 `git commit`、`git commit --amend` 等流程里。

## 直接原因

当前仓库的 hook 文件 [code_tools/git_tool/hooks/pre-commit](/home/zby/Work/But-uart_api/code_tools/git_tool/hooks/pre-commit) 中有如下写法：

```sh
export PATH=$PATH:${EXEDIR}
```

这行在 `/bin/sh` 下没有给变量展开结果加引号。

如果环境变量 `PATH` 中存在带空格的路径，例如：

```text
/mnt/c/Program Files/Microsoft VS Code/bin
```

shell 在执行时会把空格当成分隔符，导致整句被拆成多个词。  
`export` 只接受合法的变量名或 `KEY=VALUE` 形式的参数，因此会把 `Files/Microsoft` 之类的片段当成非法变量名，最终报：

```sh
export: Files/Microsoft: bad variable name
```

## 为什么会和 WSL 有关

这是 WSL 的典型环境兼容问题。

WSL 默认会把 Windows 侧的 PATH 合并进 Linux 的 `$PATH`。因此在 WSL 内部执行 shell 脚本时，环境里往往会混入这些路径：

- `/mnt/c/Program Files/...`
- `/mnt/c/WINDOWS/...`
- `/mnt/c/Program Files/Git/cmd`

这些路径本身对 Linux shell 不是非法的，但一旦脚本里有未加引号的变量展开，尤其是对 `PATH`、`LD_LIBRARY_PATH` 这种冒号分隔变量做拼接时，就很容易触发拆词问题。

## 当前场景下的实际触发链路

1. 在 WSL 中运行 `git pushmr origin develop`
2. `git pushmr` 脚本内部会执行 `git commit --amend`
3. Git 自动触发 `.git/hooks/pre-commit`
4. hook 内执行 `export PATH=$PATH:${EXEDIR}`
5. 因为当前 `$PATH` 含有 `Program Files` 等带空格路径，`/bin/sh` 拆词
6. 报出 `Files/Microsoft: bad variable name`

## 推荐解决方案

### 方案一：从 WSL 配置层面避免 Windows PATH 注入

这是推荐做法，适合以 Linux 开发、编译、git、脚本为主的 WSL 环境。

编辑 `/etc/wsl.conf`：

```ini
[interop]
enabled=true
appendWindowsPath=false
```

说明：

- `enabled=true`：保留从 WSL 启动 Windows 程序的能力
- `appendWindowsPath=false`：不要把 Windows PATH 自动追加到 Linux PATH

然后在 Windows 侧执行：

```powershell
wsl.exe --shutdown
```

重新打开 WSL 后，再检查：

```bash
echo "$PATH" | tr ':' '\n'
```

正常情况下，输出里不应再出现：

- `/mnt/c/Program Files/...`
- `/mnt/c/WINDOWS/...`

### 方案二：临时使用干净的 PATH 运行命令

如果暂时不想改 WSL 全局配置，可以只对单次命令做环境隔离：

```bash
env PATH="$(printf '%s' "$PATH" | tr ':' '\n' | grep -v ' ' | paste -sd ':' -)" git pushmr origin develop
```

这个命令的作用是：

1. 按 `:` 拆分当前 PATH
2. 过滤掉带空格的路径项
3. 重新拼出一个临时 PATH
4. 只对当前这次 `git pushmr` 生效

同样也可以用于普通提交：

```bash
env PATH="$(printf '%s' "$PATH" | tr ':' '\n' | grep -v ' ' | paste -sd ':' -)" git commit
```

### 方案三：临时跳过 hook

如果只是想继续完成一次提交，而不关心本地 hook 执行，可以使用：

```bash
git commit --no-verify
```

但这个办法不适用于 `git pushmr` 内部自动触发的 `git commit --amend`，也不能从根本上解决环境问题，因此不建议作为长期方案。

## 不推荐的做法

- 直接修改仓库内 hook 文件  
  原因：该文件可能属于团队统一工具链，改动后不利于和其他环境保持一致。

- 长期依赖 `--no-verify`  
  原因：会跳过本地检查流程，只适合作为应急手段。

## 验证步骤

### 1. 验证 PATH 是否还受 Windows 注入影响

```bash
echo "$PATH" | tr ':' '\n'
```

重点检查是否还包含：

- `/mnt/c/Program Files/...`
- `/mnt/c/WINDOWS/...`

### 2. 验证 hook 是否还会因 PATH 报错

```bash
sh .git/hooks/pre-commit
```

如果之前的核心报错是：

```sh
export: Files/Microsoft: bad variable name
```

那么在环境处理正确后，这个报错应当消失。

### 3. 验证真实 git 流程

```bash
git pushmr origin develop
```

只要不再出现 `Files/Microsoft: bad variable name`，说明这个问题已经解决。

## 推荐结论

对当前仓库和当前开发方式，最推荐的做法是：

1. 在 WSL 中设置：

```ini
[interop]
enabled=true
appendWindowsPath=false
```

2. 重启 WSL
3. 继续使用原有 git / build / pushmr 流程

这样既保留一定的互操作能力，又能避免 Windows PATH 污染 Linux shell 环境。

## 参考资料

- Microsoft Learn: WSL 配置说明  
  https://learn.microsoft.com/zh-cn/windows/wsl/wsl-config

- Microsoft Learn: WSL config (English)  
  https://learn.microsoft.com/en-us/windows/wsl/wsl-config

- WSL interop technical docs  
  https://wsl.dev/technical-documentation/interop/
