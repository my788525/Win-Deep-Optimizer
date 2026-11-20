# Windows 深度净化与免疫工具箱 (Win-Deep-Optimizer)

[![Release](https://img.shields.io/github/v/release/my788525/Win-Deep-Optimizer?color=blue&label=Release)](https://github.com/my788525/Win-Deep-Optimizer/releases)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%20Windows%2011-0078D6)](https://microsoft.com/windows)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

一个专为 Windows 10 / Windows 11 设计的系统级深度优化与免疫工具。采用**单文件（`.bat`）交付**，集成了**“微软拼音彻底删除与内核级免疫”**、**“Windows Update 彻底封杀”**以及**“对标 RemoveWindowsAI 的 22 项 AI 深度剥离与内存释放”**，并自带全功能的**还原与重新启用中心**。

---

## ✨ 核心特性

### 1. 彻底删除自带微软拼音输入法（永久免疫，防锁死）
* **防打字锁死保护**：操作前自动向系统注入 `0804:00000409`（中文语言区域下的经典纯美式键盘布局），无论是否安装第三方输入法，都绝不会出现“输入法全部丢失导致锁屏无法输密码”的风险。
* **内核级布局代换（`Keyboard Layout Substitutes`）**：在系统内核层面将默认中文布局 `00000804` 直接重定向至纯美式键盘 `00000409`。无论累积更新、新建用户还是系统修复，微软拼音绝不自动回弹。
* **断开云同步与自动补齐**：切断微软账户语言云端同步，禁用语言组件后台静默安装任务（FOD）。

### 2. 彻底封杀 Windows 系统更新
* **破坏自愈修复链条**：不仅将 `wuauserv`（更新服务）、`UsoSvc`（更新编排器）设为禁用，更将最顽固的 `WaaSMedicSvc`（Windows 更新医生服务）设为禁用并清空故障重置机制（`FailureActions`）。
* **组策略阻断**：注入 `NoAutoUpdate=1`、`AUOptions=2`、`SetDisableUXWUAccess=1`，关闭系统联网更新扫描入口。
* **清除唤醒任务**：彻底禁用 UpdateOrchestrator、WaaSMedic 等全部自动唤醒计划任务。

### 3. 彻底删除 Windows AI 全特性（完全对标 RemoveWindowsAI 22 项）
完整移植并汉化开源项目 RemoveWindowsAI 的全部 22 项 AI 特性，立竿见影释放数百兆至上 GB 常驻内存：
1. **强杀后台常驻 AI 进程**（`Copilot.exe`、`WindowsCopilot.exe`、`AIFabricService`、`Recall`、`CoreAI`）
2. **注入系统与用户级 WindowsAI 核心禁用策略**
3. **关闭 Copilot 并隐藏任务栏图标**
4. **彻底禁用 Windows Recall 快照抓取与索引分析**
5. **关闭输入洞察与打字/墨迹隐私数据收集**
6. **禁用 Edge 浏览器 Copilot 侧边栏**（释放后台预热的 `msedgewebview2` 内存）
7. **禁用画图工具中的图像创建器（Cocreator）**
8. **禁用/停用 AI Fabric Service 核心系统服务**
9. **关闭 Windows AI Actions 系统级联动交互**
10. **关闭画图工具中的生成式填充与全部 AI 插件**
11. **禁用语音访问（Voice Access）自动下载 AI 语音模型**
12. **关闭 AI 语音增强（Voice Clarity）与演播室特效**
13. **在系统设置与搜索中禁用联网 AI 建议**
14. **配置策略防止系统自动重新下载 AI 消费者组件**
15. **注入全局与用户层面的 Copilot 策略封锁**
16. **卸载 Copilot 及 AI 相关的 AppX 应用程序包**
17. **调用 DISM 接口永久移除 Recall 可选功能**
18. **扫描并移除 CBS (Component-Based Servicing) 中的底层 AI 组件包**
19. **在系统“设置”中隐藏 AI 组件与 Recall 页面入口**
20. **物理清理 Recall 快照文件与本地 CoreAI 模型缓存**
21. **在记事本中禁用 AI 重写与润色辅助功能**
22. **移除/禁用 WindowsAI 与 Recall 的全部计划任务**

### 4. 完整的还原与重新启用中心（留好后悔药）
* **随时随地，一键还原**：工具箱内置选项 `[5] 还原中心`，支持分别独立恢复微软拼音输入法、恢复系统更新服务默认状态、或全量解除 22 项 AI 策略限制并重新激活 Recall。

---

## ❓ 常见问题：禁用 Edge Copilot 会影响微信/QQ/Office 吗？

**答：完全不会！**
* 本工具**绝没有全局删除或破坏 `Microsoft Edge WebView2 运行时` 核心引擎**。
* 仅仅关闭了 Edge 的 Copilot 侧边栏以及后台偷跑预热的 WebView2 进程。
* 微信（阅读公众号文章、小程序、扫码支付）、QQ、Office 365、Steam 等任何依赖 WebView2 的第三方应用，在需要调用网页时依然**100% 正常运行**。

---

## 🚀 使用方法

1. 从 [Releases 页面](https://github.com/my788525/Win-Deep-Optimizer/releases) 下载最新版的 **`Win_Deep_Optimizer.bat`**。
2. 直接**双击该批处理文件**（内置单向提权机制，弹出 UAC 提权提示时点击“是”即可进入交互界面，绝不死循环）。
3. 按照数字菜单选择操作：
   * 输入 **`1`**：彻底删除微软拼音输入法并免疫
   * 输入 **`2`**：彻底封杀系统更新
   * 输入 **`3`**：彻底清除 22 项 Windows AI 支持
   * 输入 **`4`**：【一键终极精简】按序执行 1 + 2 + 3 全套操作（推荐）
   * 输入 **`5`**：进入还原中心（各功能均可无损恢复）
   * 输入 **`0`**：退出

---

## 📄 开源许可证

本项目基于 [MIT 许可证](LICENSE) 开源。
欢迎提出 Issue 或 Pull Request！
