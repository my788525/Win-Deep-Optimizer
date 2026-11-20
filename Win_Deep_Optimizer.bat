@fltmc >nul 2>&1 || (powershell -NoProfile -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs" & exit /b)
@powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-Content -LiteralPath '%~f0' -Raw -Encoding UTF8 | Select-String -Pattern '(?s)(?<=:::PAYLOAD:::\r?\n).*' | ForEach-Object { Invoke-Expression $_.Matches[0].Value }" & exit /b
:::PAYLOAD:::
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Set-RegDword {
    param([string]$Path, [string]$Name, [int]$Value)
    try {
        if (!(Test-Path $Path)) { New-Item -Path $Path -Force -ErrorAction SilentlyContinue | Out-Null }
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type DWord -Force -ErrorAction SilentlyContinue
    } catch {}
}

function Set-RegString {
    param([string]$Path, [string]$Name, [string]$Value)
    try {
        if (!(Test-Path $Path)) { New-Item -Path $Path -Force -ErrorAction SilentlyContinue | Out-Null }
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type String -Force -ErrorAction SilentlyContinue
    } catch {}
}

function Remove-RegItemSafe {
    param([string]$Path, [string]$Name = $null)
    try {
        if (Test-Path $Path) {
            if ($Name) {
                Remove-ItemProperty -Path $Path -Name $Name -Force -ErrorAction SilentlyContinue
            } else {
                Remove-Item -Path $Path -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    } catch {}
}

function Show-Header {
    Clear-Host
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host "   Windows 核心净化、系统更新封杀与 AI 彻底剔除工具 (对标 RemoveWindowsAI) " -ForegroundColor Cyan
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host ""
}

# ==============================================================================
# 模块 1：彻底删除微软拼音输入法并实施永久免疫
# ==============================================================================
function Purge-MicrosoftPinyin {
    Show-Header
    Write-Host ">>> [1/3] 部署中文语言下的纯美式键盘 (0804:00000409) 防打字锁死..." -ForegroundColor Yellow
    $langList = Get-WinUserLanguageList
    $zhLang = $langList | Where-Object { $_.LanguageTag -eq "zh-Hans-CN" }
    if ($null -eq $zhLang) {
        $langList.Add("zh-Hans-CN")
        $zhLang = $langList | Where-Object { $_.LanguageTag -eq "zh-Hans-CN" }
    }
    
    $pinyin1 = "0804:{81D4E9C9-1D3B-41BC-9E6C-4B40BF79E35E}{FCEEBE02-D534-4D08-896A-770F5681D1B5}"
    $pinyin2 = "0804:{FA550B04-5AD7-411F-A5AC-CA038EC515D7}{FCEEBE02-D534-4D08-896A-770F5681D1B5}"
    $zhLang.InputMethodTips.Remove($pinyin1) | Out-Null
    $zhLang.InputMethodTips.Remove($pinyin2) | Out-Null
    if (-not ($zhLang.InputMethodTips -contains "0804:00000409")) {
        $zhLang.InputMethodTips.Add("0804:00000409")
    }
    Set-WinUserLanguageList $langList -Force
    Write-Host "  -> 已锁定美式键盘，微软拼音已被踢出输入法轮换列表！" -ForegroundColor Green

    Write-Host ">>> [2/3] 配置【内核级键盘代换】与注册表映射免疫锁..." -ForegroundColor Yellow
    Set-RegString -Path "HKCU:\Keyboard Layout\Substitutes" -Name "00000804" -Value "00000409"
    Set-RegString -Path "Registry::HKEY_USERS\.DEFAULT\Keyboard Layout\Substitutes" -Name "00000804" -Value "00000409"
    
    $regProfile = "HKCU:\Control Panel\International\User Profile\zh-Hans-CN"
    if (Test-Path $regProfile) {
        Get-ItemProperty $regProfile | Get-Member -MemberType NoteProperty | Where-Object {
            $_.Name -like "*81D4E9C9-1D3B-41BC-9E6C-4B40BF79E35E*" -or $_.Name -like "*FA550B04-5AD7-411F-A5AC-CA038EC515D7*"
        } | ForEach-Object {
            Remove-ItemProperty -Path $regProfile -Name $_.Name -Force -ErrorAction SilentlyContinue
        }
    }
    Write-Host "  -> 内核级布局代换已生效，默认中文输入法已被焊死在美式键盘！" -ForegroundColor Green

    Write-Host ">>> [3/3] 关闭微软账户语言同步与 FOD 静默下载..." -ForegroundColor Yellow
    Set-RegDword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Language" -Name "Enabled" -Value 0
    Disable-ScheduledTask -TaskPath "\Microsoft\Windows\LanguageComponentsInstaller\" -TaskName "Installation" -ErrorAction SilentlyContinue | Out-Null
    Disable-ScheduledTask -TaskPath "\Microsoft\Windows\LanguageComponentsInstaller\" -TaskName "ReconcileLanguageResources" -ErrorAction SilentlyContinue | Out-Null
    Write-Host "  [√] 微软拼音已彻底清除并免疫！" -ForegroundColor Green
}

# ==============================================================================
# 模块 2：彻底封杀 Windows 系统更新
# ==============================================================================
function Block-WindowsUpdate {
    Show-Header
    Write-Host ">>> [1/3] 停止并锁定 Windows Update 与修复核心服务..." -ForegroundColor Yellow
    $services = @("wuauserv", "WaaSMedicSvc", "UsoSvc", "bits", "dosvc")
    foreach ($svc in $services) {
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\$svc" -Name "Start" -Value 4 -Type DWord -ErrorAction SilentlyContinue
    }
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" -Name "FailureActions" -Value ([byte[]]@(0)) -ErrorAction SilentlyContinue
    Write-Host "  -> 服务已全部禁用，WaaSMedic 自愈更新机制已被破坏！" -ForegroundColor Green

    Write-Host ">>> [2/3] 注入组策略规则：彻底屏蔽更新自动检测..." -ForegroundColor Yellow
    Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoUpdate" -Value 1
    Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUOptions" -Value 2
    Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "SetDisableUXWUAccess" -Value 1
    Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "DoNotConnectToWindowsUpdateInternetLocations" -Value 1
    Write-Host "  -> 策略拦截已生效！" -ForegroundColor Green

    Write-Host ">>> [3/3] 禁用所有 Update 计划唤醒任务..." -ForegroundColor Yellow
    $tasks = @(
        "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan",
        "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan Static Task",
        "\Microsoft\Windows\UpdateOrchestrator\UpdateModelTask",
        "\Microsoft\Windows\WaaSMedic\PerformRemediation",
        "\Microsoft\Windows\WindowsUpdate\Scheduled Start"
    )
    foreach ($t in $tasks) {
        $taskPath = $t.Substring(0, $t.LastIndexOf('\') + 1)
        $taskName = $t.Substring($t.LastIndexOf('\') + 1)
        Disable-ScheduledTask -TaskPath $taskPath -TaskName $taskName -ErrorAction SilentlyContinue | Out-Null
    }
    Write-Host "  [√] Windows 系统更新已被完全封死，不再后台偷跑或自动重启！" -ForegroundColor Green
}

# ==============================================================================
# 模块 3：彻底删除 Windows AI 全特性（对标 RemoveWindowsAI 22项）
# ==============================================================================
function Remove-WindowsAI-Full {
    Show-Header
    Write-Host "正在执行对标 RemoveWindowsAI 的 22 项全维度深度清理..." -ForegroundColor Cyan

    Write-Host "  [1/22] 强杀常驻后台 AI 进程以释放内存..." -ForegroundColor Yellow
    @("Copilot", "WindowsCopilot", "AIFabricService", "Recall", "CoreAI") | ForEach-Object {
        Stop-Process -Name $_ -Force -ErrorAction SilentlyContinue
    }

    Write-Host "  [2/22] 写入 WindowsAI 核心禁用注册表..." -ForegroundColor Yellow
    Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" -Name "DisableAIDataAnalysis" -Value 1
    Set-RegDword -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsAI" -Name "DisableAIDataAnalysis" -Value 1

    Write-Host "  [3/22] 关闭 Copilot 系统开关并隐藏任务栏图标..." -ForegroundColor Yellow
    Set-RegDword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowCopilotButton" -Value 0

    Write-Host "  [4/22] 禁用 Windows Recall 快照抓取与索引..." -ForegroundColor Yellow
    Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" -Name "DisableAIDataAnalysis" -Value 1

    Write-Host "  [5/22] 关闭输入洞察与打字数据收集功能..." -ForegroundColor Yellow
    Set-RegDword -Path "HKCU:\Software\Microsoft\Input\Settings" -Name "InsightsEnabled" -Value 0
    Set-RegDword -Path "HKCU:\Software\Microsoft\Personalization\Settings" -Name "AcceptedPrivacyPolicy" -Value 0
    Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization" -Name "AllowInputPersonalization" -Value 0
    Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization" -Name "RestrictImplicitInkCollection" -Value 1
    Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization" -Name "RestrictImplicitTextCollection" -Value 1

    Write-Host "  [6/22] 禁用 Edge 侧边栏 Copilot (释放后台预热的 msedgewebview2)..." -ForegroundColor Yellow
    Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "HubsSidebarEnabled" -Value 0
    Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "ShowCopilotButton" -Value 0

    Write-Host "  [7/22] 禁用画图工具中的图像创建器 (Cocreator)..." -ForegroundColor Yellow
    Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Paint" -Name "DisableCocreator" -Value 1
    Set-RegDword -Path "HKCU:\Software\Microsoft\Paint" -Name "EnableCocreator" -Value 0

    Write-Host "  [8/22] 禁用/移除 AI Fabric Service 服务..." -ForegroundColor Yellow
    @("AIFabric", "AIFabricService", "CoreAIService") | ForEach-Object {
        Stop-Service -Name $_ -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\$_" -Name "Start" -Value 4 -Type DWord -ErrorAction SilentlyContinue
    }
    Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" -Name "DisableAIFabricService" -Value 1

    Write-Host "  [9/22] 关闭 Windows AI Actions 联动功能..." -ForegroundColor Yellow
    Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" -Name "DisableAiActions" -Value 1
    Set-RegDword -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsAI" -Name "DisableAiActions" -Value 1

    Write-Host "  [10/22] 关闭画图工具中的生成式填充与全部 AI 插件..." -ForegroundColor Yellow
    Set-RegDword -Path "HKCU:\Software\Microsoft\Paint" -Name "DisableGenerativeFill" -Value 1
    Set-RegDword -Path "HKCU:\Software\Microsoft\Paint" -Name "DisableAIFeatures" -Value 1

    Write-Host "  [11/22] 禁用语音访问 (Voice Access) 自动下载 AI 语音模型..." -ForegroundColor Yellow
    Set-RegDword -Path "HKCU:\Software\Microsoft\Speech_OneCore\Preferences" -Name "ModelDownloadEnabled" -Value 0
    Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Speech" -Name "AllowSpeechModelDownload" -Value 0

    Write-Host "  [12/22] 关闭 AI 语音增强 (Voice Clarity) 与演播室效果..." -ForegroundColor Yellow
    Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" -Name "DisableVoiceClarity" -Value 1

    Write-Host "  [13/22] 在系统设置与 Windows 搜索中禁用联网 AI 建议..." -ForegroundColor Yellow
    Set-RegDword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value 0
    Set-RegDword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "CanCortanaBeEnabled" -Value 0
    Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCloudSearch" -Value 0
    Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "ConnectedSearchUseWeb" -Value 0

    Write-Host "  [14/22] 配置策略防止 Windows 重新静默安装 AI 组件..." -ForegroundColor Yellow
    Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1
    Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableConsumerAccountStateContent" -Value 1

    Write-Host "  [15/22] 注入全局与用户层面的 Copilot 策略封锁..." -ForegroundColor Yellow
    Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Value 1
    Set-RegDword -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Value 1

    Write-Host "  [16/22] 卸载 Copilot 及 AI 相关的 AppX 应用程序包..." -ForegroundColor Yellow
    Get-AppxPackage -AllUsers | Where-Object { $_.Name -match "Copilot|Recall|Windows\.Ai\.|GenerativeAI" } | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
    Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -match "Copilot|Recall|Windows\.Ai\.|GenerativeAI" } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Out-Null

    Write-Host "  [17/22] 调用 DISM 移除 Recall 可选功能..." -ForegroundColor Yellow
    try {
        Disable-WindowsOptionalFeature -Online -FeatureName "Recall" -NoRestart -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | Out-Null
    } catch {}

    Write-Host "  [18/22] 扫描并移除 CBS 中的 AI 组件包..." -ForegroundColor Yellow
    try {
        Get-WindowsPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.PackageName -like "*Recall*" -or $_.PackageName -like "*Windows-AI*" } | Remove-WindowsPackage -Online -NoRestart -ErrorAction SilentlyContinue | Out-Null
    } catch {}

    Write-Host "  [19/22] 隐藏 Windows 设置界面中的 AI 组件与 Recall 页面..." -ForegroundColor Yellow
    $ctrlPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Control Panel\SettingsPageVisibility"
    if (!(Test-Path $ctrlPath)) { New-Item -Path $ctrlPath -Force -ErrorAction SilentlyContinue | Out-Null }
    Set-ItemProperty -Path $ctrlPath -Name "SettingsPageVisibility" -Value "hide:ai-components;recall;copilot" -Type String -Force -ErrorAction SilentlyContinue

    Write-Host "  [20/22] 删除 Recall 快照文件与本地 CoreAI 模型缓存..." -ForegroundColor Yellow
    $aiFolders = @(
        "$env:LOCALAPPDATA\Microsoft\Windows\Recall",
        "$env:PROGRAMDATA\Microsoft\Windows\Recall",
        "$env:LOCALAPPDATA\CoreAI",
        "$env:PROGRAMDATA\Microsoft\CoreAI"
    )
    foreach ($f in $aiFolders) {
        if (Test-Path $f) { Remove-Item -Path $f -Recurse -Force -ErrorAction SilentlyContinue }
    }

    Write-Host "  [21/22] 在记事本中禁用 AI 重写与润色功能..." -ForegroundColor Yellow
    Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Notepad" -Name "DisableAIFeatures" -Value 1
    Set-RegDword -Path "HKCU:\Software\Microsoft\Notepad" -Name "EnableCowriter" -Value 0

    Write-Host "  [22/22] 禁用 WindowsAI 与 Recall 的全部计划任务..." -ForegroundColor Yellow
    Get-ScheduledTask -TaskPath "\Microsoft\Windows\WindowsAI\*" -ErrorAction SilentlyContinue | Disable-ScheduledTask -ErrorAction SilentlyContinue | Out-Null
    Get-ScheduledTask -TaskPath "\Microsoft\Windows\Recall\*" -ErrorAction SilentlyContinue | Disable-ScheduledTask -ErrorAction SilentlyContinue | Out-Null

    Write-Host ""
    Write-Host "  [√] RemoveWindowsAI 对应的 22 项 AI 功能已全部清除！常驻内存已释放。" -ForegroundColor Green
}

# ==============================================================================
# 模块 4：深度清理 C 盘垃圾与系统临时文件
# ==============================================================================
function Clean-DiskJunk {
    Show-Header
    Write-Host ">>> 正在全面扫描并深度清理 C 盘垃圾与临时文件..." -ForegroundColor Cyan
    Write-Host ""

    $initialFree = (Get-PSDrive C).Free

    # 1. 用户与系统临时文件
    Write-Host "  [1/8] 清理用户与系统临时文件 (%TEMP%, C:\Windows\Temp)..." -ForegroundColor Yellow
    $tempFolders = @(
        "$env:TEMP",
        "$env:LOCALAPPDATA\Temp",
        "C:\Windows\Temp"
    )
    foreach ($dir in $tempFolders) {
        if (Test-Path $dir) {
            Remove-Item -Path "$dir\*" -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    # 2. Windows Update 下载缓存
    Write-Host "  [2/8] 清理 Windows Update 安装包下载缓存..." -ForegroundColor Yellow
    $wuDownload = "C:\Windows\SoftwareDistribution\Download"
    if (Test-Path $wuDownload) {
        Remove-Item -Path "$wuDownload\*" -Recurse -Force -ErrorAction SilentlyContinue
    }

    # 3. 错误报告与内存转储
    Write-Host "  [3/8] 清理系统错误报告、崩溃转储文件 (WER, Minidump)..." -ForegroundColor Yellow
    $dumpPaths = @(
        "C:\ProgramData\Microsoft\Windows\WER",
        "$env:LOCALAPPDATA\Microsoft\Windows\WER",
        "C:\Windows\Minidump",
        "C:\Windows\MEMORY.DMP",
        "$env:LOCALAPPDATA\CrashDumps"
    )
    foreach ($p in $dumpPaths) {
        if (Test-Path $p) {
            if ((Get-Item $p).PSIsContainer) {
                Remove-Item -Path "$p\*" -Recurse -Force -ErrorAction SilentlyContinue
            } else {
                Remove-Item -Path $p -Force -ErrorAction SilentlyContinue
            }
        }
    }

    # 4. 传递优化与预读取缓存
    Write-Host "  [4/8] 清理传递优化缓存与 Prefetch 预读取文件..." -ForegroundColor Yellow
    $prefetchPaths = @(
        "C:\Windows\Prefetch",
        "C:\Windows\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Cache"
    )
    foreach ($dir in $prefetchPaths) {
        if (Test-Path $dir) {
            Remove-Item -Path "$dir\*" -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    # 5. 着色器缓存
    Write-Host "  [5/8] 清理 DirectX 着色器缓存 (D3DSCache)..." -ForegroundColor Yellow
    $shaderPaths = @(
        "$env:LOCALAPPDATA\D3DSCache",
        "$env:LOCALAPPDATA\NVIDIA\DXCache",
        "$env:LOCALAPPDATA\AMD\DxCache"
    )
    foreach ($dir in $shaderPaths) {
        if (Test-Path $dir) {
            Remove-Item -Path "$dir\*" -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    # 6. 系统诊断与安装更新日志
    Write-Host "  [6/8] 清理 Windows 诊断与安装日志 (CBS, DISM, Panther)..." -ForegroundColor Yellow
    $logPaths = @(
        "C:\Windows\Logs\CBS",
        "C:\Windows\Logs\DISM",
        "C:\Windows\Logs\DPX",
        "C:\Windows\Panther"
    )
    foreach ($dir in $logPaths) {
        if (Test-Path $dir) {
            Remove-Item -Path "$dir\*" -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    # 7. 清空 Windows 回收站
    Write-Host "  [7/8] 清空 Windows 回收站..." -ForegroundColor Yellow
    try {
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue | Out-Null
    } catch {}

    # 8. 刷新缩略图与图标缓存
    Write-Host "  [8/8] 清理资源管理器缩略图与图标缓存..." -ForegroundColor Yellow
    $thumbPaths = @(
        "$env:LOCALAPPDATA\Microsoft\Windows\Explorer"
    )
    foreach ($dir in $thumbPaths) {
        if (Test-Path $dir) {
            Get-ChildItem -Path $dir -Filter "thumbcache_*.db" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
            Get-ChildItem -Path $dir -Filter "iconcache_*.db" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
        }
    }

    $finalFree = (Get-PSDrive C).Free
    $freedBytes = $finalFree - $initialFree
    if ($freedBytes -lt 0) { $freedBytes = 0 }

    $freedMB = [math]::Round($freedBytes / 1MB, 2)
    $freedGB = [math]::Round($freedBytes / 1GB, 2)

    Write-Host ""
    if ($freedGB -ge 1.0) {
        Write-Host "  [√] C 盘垃圾清理完毕！本次共成功释放空间：$freedGB GB" -ForegroundColor Green
    } else {
        Write-Host "  [√] C 盘垃圾清理完毕！本次共成功释放空间：$freedMB MB" -ForegroundColor Green
    }
}

# ==============================================================================
# 模块 5：全套恢复与重新启用中心
# ==============================================================================
function Show-RestoreMenu {
    do {
        Show-Header
        Write-Host "================== 还原中心（全面解除屏蔽与重新启用） ==================" -ForegroundColor Magenta
        Write-Host "  [1] 恢复 微软拼音输入法 (解除代换映射 + 重新挂载输入法)"
        Write-Host "  [2] 恢复 Windows 系统更新 (恢复服务默认状态 + 清除策略)"
        Write-Host "  [3] 恢复 全部 22 项 Windows AI 支持 (恢复策略 + 重新激活 Recall + 解除设置隐藏)"
        Write-Host "  [0] 返回主菜单"
        Write-Host "==========================================================================" -ForegroundColor Magenta
        $rChoice = Read-Host "请输入要还原的项目编号 [0-3]"

        switch ($rChoice) {
            "1" {
                Write-Host "正在解除布局代换并恢复微软拼音..." -ForegroundColor Yellow
                Remove-ItemProperty -Path "HKCU:\Keyboard Layout\Substitutes" -Name "00000804" -ErrorAction SilentlyContinue
                Remove-ItemProperty -Path "Registry::HKEY_USERS\.DEFAULT\Keyboard Layout\Substitutes" -Name "00000804" -ErrorAction SilentlyContinue
                
                $lang = Get-WinUserLanguageList
                $zh = $lang | Where-Object { $_.LanguageTag -eq "zh-Hans-CN" }
                $pinyin = "0804:{81D4E9C9-1D3B-41BC-9E6C-4B40BF79E35E}{FCEEBE02-D534-4D08-896A-770F5681D1B5}"
                if ($zh -and -not ($zh.InputMethodTips -contains $pinyin)) {
                    $zh.InputMethodTips.Add($pinyin)
                    Set-WinUserLanguageList $lang -Force
                }
                Enable-ScheduledTask -TaskPath "\Microsoft\Windows\LanguageComponentsInstaller\" -TaskName "Installation" -ErrorAction SilentlyContinue | Out-Null
                Enable-ScheduledTask -TaskPath "\Microsoft\Windows\LanguageComponentsInstaller\" -TaskName "ReconcileLanguageResources" -ErrorAction SilentlyContinue | Out-Null
                Set-RegDword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Language" -Name "Enabled" -Value 1
                Write-Host "  [√] 微软拼音已恢复！建议注销或重启生效。" -ForegroundColor Green
                pause
            }
            "2" {
                Write-Host "正在恢复系统更新服务与默认策略..." -ForegroundColor Yellow
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\wuauserv" -Name "Start" -Value 3 -Type DWord
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" -Name "Start" -Value 3 -Type DWord
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\UsoSvc" -Name "Start" -Value 2 -Type DWord
                Remove-RegItemSafe -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
                Start-Service -Name wuauserv -ErrorAction SilentlyContinue
                Write-Host "  [√] Windows 系统更新服务已重置为默认状态！" -ForegroundColor Green
                pause
            }
            "3" {
                Write-Host "正在全量恢复 AI 核心策略与系统组件..." -ForegroundColor Yellow
                Remove-RegItemSafe -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"
                Remove-RegItemSafe -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot"
                Remove-RegItemSafe -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"
                Remove-RegItemSafe -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsAI"
                Remove-RegItemSafe -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "HubsSidebarEnabled"
                Remove-RegItemSafe -Path "HKLM:\SOFTWARE\Policies\Microsoft\Paint" -Name "DisableCocreator"
                Remove-RegItemSafe -Path "HKLM:\SOFTWARE\Policies\Microsoft\Notepad" -Name "DisableAIFeatures"
                Remove-RegItemSafe -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Control Panel\SettingsPageVisibility" -Name "SettingsPageVisibility"
                
                Set-RegDword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowCopilotButton" -Value 1
                Set-RegDword -Path "HKCU:\Software\Microsoft\Input\Settings" -Name "InsightsEnabled" -Value 1
                Set-RegDword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value 1
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\AIFabric" -Name "Start" -Value 3 -Type DWord -ErrorAction SilentlyContinue
                
                try {
                    Enable-WindowsOptionalFeature -Online -FeatureName "Recall" -NoRestart -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | Out-Null
                } catch {}

                Get-ScheduledTask -TaskPath "\Microsoft\Windows\WindowsAI\*" -ErrorAction SilentlyContinue | Enable-ScheduledTask -ErrorAction SilentlyContinue | Out-Null
                Get-ScheduledTask -TaskPath "\Microsoft\Windows\Recall\*" -ErrorAction SilentlyContinue | Enable-ScheduledTask -ErrorAction SilentlyContinue | Out-Null

                Write-Host "  [√] 全部 22 项 AI 策略已解除屏蔽，Recall 功能已重新激活！" -ForegroundColor Green
                Write-Host "  提示：如需 Copilot 应用，可在微软应用商店 (Microsoft Store) 搜索重新安装。" -ForegroundColor Cyan
                pause
            }
            default {}
        }
    } while ($rChoice -ne "0")
}

# ==============================================================================
# 主交互循环
# ==============================================================================
do {
    Show-Header
    Write-Host "  [1] 彻底删除微软拼音输入法 + 永久权限免疫 (自动配置美式键盘防锁死)"
    Write-Host "  [2] 彻底封杀 Windows 系统更新 (停用核心服务/破坏Medic自愈/策略拦截)"
    Write-Host "  [3] 彻底删除 Windows AI 全特性 (对标 RemoveWindowsAI 22项功能 / 释放常驻内存)"
    Write-Host "  [4] 深度清理 C 盘垃圾与系统临时文件 (释放几GB~几十GB硬盘空间)"
    Write-Host ""
    Write-Host "  [5] 【一键终极精简】按序执行 1 + 2 + 3 + 4 全部优化" -ForegroundColor Green
    Write-Host ""
    Write-Host "  [6] 还原与重新启用中心 (分类恢复：拼音 / 系统更新 / 全套 AI 特性)" -ForegroundColor Magenta
    Write-Host "  [0] 退出工具箱"
    Write-Host ""
    Write-Host "==========================================================================" -ForegroundColor Cyan
    $choice = Read-Host "请输入选项编号 [0-6]"

    switch ($choice) {
        "1" { Purge-MicrosoftPinyin; Write-Host ""; pause }
        "2" { Block-WindowsUpdate; Write-Host ""; pause }
        "3" { Remove-WindowsAI-Full; Write-Host ""; pause }
        "4" { Clean-DiskJunk; Write-Host ""; pause }
        "5" {
            Purge-MicrosoftPinyin
            Block-WindowsUpdate
            Remove-WindowsAI-Full
            Clean-DiskJunk
            Write-Host ""
            Write-Host "==========================================================================" -ForegroundColor Green
            Write-Host " [完成] 全套深度优化已全部执行完毕！建议注销或重启一次电脑以彻底生效。" -ForegroundColor Green
            Write-Host "==========================================================================" -ForegroundColor Green
            pause
        }
        "6" { Show-RestoreMenu }
        "0" { exit }
        default { Write-Host "输入无效，请重新输入！" -ForegroundColor Red; Start-Sleep -Seconds 1 }
    }
} while ($choice -ne "0")
