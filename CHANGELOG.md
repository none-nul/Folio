# Changelog

本文件记录 Folio 每个版本的重要变更，格式遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

发布新版本时，把 `[Unreleased]` 中的内容移到新的版本小节下，`script/release.sh` 会把该小节作为发布说明，并显示在应用内的更新窗口中。

## [Unreleased]

## [1.1.2] - 2026-10-23

### 修复

- 修复安装后一打开就退出：应用的临时签名和内置 Sparkle 的签名不是同一个 Team ID，系统拒绝加载更新组件

## [1.1.1] - 2026-10-23

### 新增

- 阅读器：选中文字后按快捷键再高亮（默认 ⇧⌘H，可在「设置 ▸ 阅读」或欢迎页更改），方便先复制去查资料；对照阅读时同一处会同时标在原文和译文上，译文也可以单独批注
- 阅读器工具栏在窗口变窄（例如分屏）时优先保留批注工具，搜索框先让位

### 变更

- 应用内更新换用新的签名密钥，更新源改为 `none-nul/Folio` 的 Release。已经安装的 1.0.0 需要手动安装这一版 DMG

## [1.0.0] - 2026-10-15

首个公开版本。

### 新增

- 拖入 PDF 后自动识别元数据并创建条目（Zotero 识别服务 + Crossref / arXiv / OpenAlex / DBLP / CVF）
- 内置 PDF 阅读器：标签页、高亮 / 下划线 / 便签 / 文本框 / 手绘批注，批注直接写回 PDF，记住阅读位置
- 保留排版的整篇翻译（pdf2zh_next / BabelDOC），支持 20 多种翻译服务，可对照阅读
- 每个条目一篇 Markdown 笔记，阅读时可把选中文字一键加入笔记
- AI 接入：MCP 服务器与命令行工具 `folio-cli`，可一键配置 Claude Code、Codex、Gemini CLI 等 11 种智能体
- 浏览器插件（Safari、Chrome、Edge、Firefox 等），在论文页面一键保存，支持批量保存
- 两级分组、彩色标签、回收站、全文搜索、阅读状态与星级评分
- 9 种引用格式（含 GB/T 7714-2015），导出 BibTeX / RIS / CSL JSON；从 Zotero 一键导入
- 应用内检查更新：自动下载并在重新启动后完成安装
- 首次启动的欢迎向导：从 Zotero 导入、安装浏览器插件、为 AI 智能体添加 MCP 与技能、配置翻译组件
- 中英双语界面（默认跟随系统语言，可在设置中切换），浏览器插件同样支持英文
- 支持 macOS 14 Sonoma 及以上；在 macOS 26 上使用 Liquid Glass 外观

[Unreleased]: https://github.com/none-nul/Folio/compare/v1.1.2...HEAD
[1.1.2]: https://github.com/none-nul/Folio/releases/tag/v1.1.2
[1.1.1]: https://github.com/none-nul/Folio/releases/tag/v1.1.1
[1.0.0]: https://github.com/Alonemo-Nnqc/Folio/releases/tag/v1.0.0
