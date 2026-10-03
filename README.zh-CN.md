# Hermes Android 简体中文版

本仓库是 [rusty4444/hermes-android](https://github.com/rusty4444/hermes-android) 的简体中文专用 Fork，基于 **v2.1.10（build 2150）**。上游架构、贡献者信息与英文说明保留在 [README.md](README.md)。

## 汉化范围

- 首页、会话、项目、动态、更多，以及设置、连接表单、文件、技能、记忆、定时任务。
- 消息操作、代码块、附件、语音输入、审批、澄清、备份恢复、状态和通知等应用自有文案。
- Material/Cupertino 系统控件使用官方 `flutter_localizations`，固定 `zh_CN`，包括复制、粘贴、全选和日期/时间选择器。
- 术语统一为“项目、会话、动态、配置档（Profile）、置顶、归档、媒体与产物”。

不翻译用户聊天内容、真实项目/文件名、模型名、服务器原始错误、日志和协议字段；分享给模型的内置指令保持原样。外部网页仪表盘也不属于 Android 客户端汉化范围。

## 安装与兼容

本 Fork 的 GitHub Actions 生成 **ARM64 Debug 验证 APK**，包名为 `com.hermesagent.hermes_android.dev`，桌面名称为 **Hermes Agent Dev**。它可与原版并存，但没有原作者的发布签名，**不能覆盖安装原版**。

新应用使用独立的本地数据。可在原版导出加密配置备份，再在中文版导入；不会自动读取原版的登录凭据。Gateway/API/Dashboard 的配置方法与上游相同。

“媒体与产物”“置顶、批量与撤销”“AI 辅助归档”等上游占位功能继续保持禁用，仅说明文字被汉化，不代表服务端已经支持。

## 构建与验证

环境：Flutter **3.44.0**、Java **17**、Android SDK **36**。进入仓库后：

```bash
flutter pub get
flutter analyze --no-pub --fatal-infos
flutter test --no-pub
flutter build apk --debug --target-platform android-arm64 --split-per-abi
```

APK：`build/app/outputs/flutter-apk/app-arm64-v8a-debug.apk`。

[Chinese Android validation](https://github.com/xieyuanqing/hermes-android/actions/workflows/zh-build.yml) 会执行静态分析、全套测试、APK 构建，以及包名、版本号和签名验收；成功后上传构建产物。冒烟与独立回归测试在 `test/zh_cn_localization_smoke_test.dart`、`test/zh_reviewer_regression_test.dart`，覆盖真实应用启动、真实工作区导航、真实损坏数据恢复路径及禁用功能边界。

## 边界

这是中文专用版本，没有运行时语言切换。汉化不修改认证、证书验证、审批、安全限制或 Gateway 协议。自动化检查不能替代真机使用测试；仍需关注具体设备上的字体、键盘和语音服务表现。
