# Windows 深度净化与免疫工具箱 (Win-Deep-Optimizer)

[![Release](https://img.shields.io/github/v/release/my788525/Win-Deep-Optimizer?color=blue&label=Release)](https://github.com/my788525/Win-Deep-Optimizer/releases)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%20Windows%2011-0078D6)](https://microsoft.com/windows)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

一个专为 Windows 10 与 Windows 11 设计的系统级深度优化与免疫工具。
采用**单文件（`.bat`）交付**，集成了**“微软拼音彻底删除与内核级免疫”**、**“Windows Update 彻底封杀”**、**“22 项系统级 AI 组件深度剥离与内存释放”**、**“C 盘垃圾与系统临时文件深度清理”**，并自带**全功能一键还原中心**。

---

## ✨ 核心功能模块

### 1. 彻底删除自带微软拼音输入法（永久免疫，防锁死）
* **防打字锁死保护**：操作前自动部署纯英文美式键盘（`0804:00000409`），确保无论是否有第三方输入法，电脑都拥有稳定可用的输入环境。
* **内核级布局代换（`Keyboard Layout Substitutes`）**：在系统底层将默认中文布局直接映射为纯美式键盘。解决传统删除方式在更新、锁屏、或新建用户时微软拼音死灰复燃的问题。
* **断开云同步与按需下载**：切断微软账户语言同步，禁用后台静默补齐语言特性的计划任务。

### 2. 彻底封杀 Windows 系统更新
* **切断更新自愈机制**：不仅停用更新服务与更新编排器，更将 Windows 更新医生服务（`WaaSMedicSvc`）锁定并清空其故障重启参数。
* **组策略底层拦截**：注入禁用自动更新策略，屏蔽系统对微软更新服务器的联网检索。
* **禁用唤醒计划任务**：禁用所有在后台偷偷唤醒电脑下载更新的计划任务。

### 3. 彻底删除 Windows AI 全特性（释放后台常驻内存）
全面精简深度绑定的 AI 特性，停止后台预热守护进程，显著降低待机内存与系统资源开销：
* **强杀并清除常驻进程**：终止 Copilot、Recall、AI Fabric Service 等常驻组件。
* **策略级封锁**：关闭全局 Copilot、Recall 快照抓取与索引、AI Actions、以及打字与墨迹数据收集。
* **应用内置 AI 剥离**：关闭 Edge 侧边栏 Copilot（释放多余预热的 `msedgewebview2` 内存）、关闭画图中的 Cocreator 与生成式填充、关闭记事本 AI 润色重写。
* **应用包与组件清理**：卸载系统集成的 Copilot/AI AppX 包，并调用 DISM 接口彻底停用 Recall 可选功能。

### 4. 深度清理 C 盘垃圾与临时文件（新特性）
一键精准扫描并清理常见系统垃圾，安全释放磁盘空间（自动计算并显示释放容量）：
* 清理系统与用户临时目录（`%TEMP%`、`C:\Windows\Temp`）
* 清理 Windows Update 安装包历史下载缓存（`SoftwareDistribution\Download`）
* 清理系统错误报告与崩溃转储文件（WER、Minidump、Memory.dmp）
* 清理传递优化与 Prefetch 预读取缓存
* 清理 DirectX 着色器缓存（D3DSCache）与应用崩溃转储
* 清理 Windows 安装与组件更新日志（CBS、DISM、Panther）
* 自动清空各盘回收站
* 刷新并清理缩略图与图标数据库缓存

### 5. 完整的还原中心（留好后悔药）
* 内置选项 `[6] 还原中心`，支持独立一键恢复微软拼音输入法、重置系统更新为默认状态、或全量解除 AI 策略限制并重新启用功能。

---

## ❓ 常见问题：禁用 Edge Copilot 会影响微信/QQ/Office 吗？

**答：完全不会！**
* 工具**绝不删除系统底层 `Microsoft Edge WebView2 运行时` 核心引擎**。
* 仅关闭 Edge 的 Copilot 侧边栏及后台专门为 AI 预热的常驻进程。
* 微信（阅读文章、小程序、支付弹窗）、QQ、Office 365 等所有依赖 WebView2 的第三方软件均保持 100% 正常运行。

---

## 🚀 使用方法

1. 从 [Releases 页面](https://github.com/my788525/Win-Deep-Optimizer/releases) 下载最新版 **`Win_Deep_Optimizer.bat`**。
2. 直接**双击该批处理文件**（内置单向提权机制，UAC 弹窗点击“是”即可进入菜单，绝不死循环）。
3. 按照菜单数字输入执行：
   * 输入 **`1`**：彻底删除微软拼音并永久免疫
   * 输入 **`2`**：彻底封杀系统更新
   * 输入 **`3`**：彻底清除系统 AI 支持与释放内存
   * 输入 **`4`**：深度清理 C 盘垃圾与临时文件
   * 输入 **`5`**：【一键终极精简】按序执行 1 + 2 + 3 + 4 全部优化（推荐）
   * 输入 **`6`**：进入还原中心（随时可恢复）
   * 输入 **`0`**：退出

---

## 📄 开源许可证

本项目基于 [MIT 许可证](LICENSE) 开源。
