# 世界杯战报 macOS 小组件

一个原生 SwiftUI + WidgetKit 项目，在 macOS 桌面和菜单栏展示世界杯实时比分、最新战报与即将开赛的比赛。

## 功能

- 小、中、大三种桌面组件
- 菜单栏实时比分与比赛列表
- 中文球队名、国旗、球场和分组信息
- 根据比赛状态自动调整刷新频率
- 使用 [football-data.org](https://www.football-data.org/) 获取比赛数据
- 内置 AI Skill，可帮助快速换主题、改布局或生成同款

## 环境要求

- macOS 14 或更高版本
- Xcode
- 一个免费的 football-data.org API Token
- 可选：[XcodeGen](https://github.com/yonaskolb/XcodeGen)，仅在修改 `project.yml` 后需要

## 开始使用

1. 克隆仓库并进入目录。
2. 复制本地配置：

   ```bash
   cp Config.local.xcconfig.example Config.local.xcconfig
   ```

3. 打开 `Config.local.xcconfig`，填入自己的 API Token。该文件已被 Git 忽略。
4. 打开 `WorldCupWidget.xcodeproj`，选择 `WorldCupWidget` scheme 并运行。
5. 在 macOS 桌面右键选择“编辑小组件”，搜索“世界杯战报”并添加。

如果修改了 `project.yml`，先运行：

```bash
xcodegen generate
```

## 用 AI 制作同款

仓库包含 `.agents/skills/world-cup-widget-builder`。在支持项目 Skill 的 AI 编程工具中打开本仓库，然后说：

> 使用 world-cup-widget-builder，把它改成蓝白配色，并让大号组件显示六场比赛。

Skill 会引导 AI 找到正确文件、保护 API Token、重新生成项目并进行构建验证。

## 发布给普通用户

本地编译适合个人使用和开发者测试。若要让其他人直接下载并打开，需要使用 Apple Developer ID 对 App 签名，并完成 Apple 公证。否则 macOS 可能显示“无法验证开发者”。

## 数据与商标

比赛数据由 football-data.org 提供，实际覆盖范围、刷新频率和额度取决于其服务计划。世界杯、FIFA 名称及相关标志属于各自权利人；公开分发前请确认图像和商标授权。

## License

代码采用 MIT License。第三方数据、字体、图片和商标不包含在该授权内。
