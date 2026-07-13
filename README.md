# OfferLab

OfferLab 是一个 Flutter AI 面试与职场沟通陪练 Demo。
用户可以从内置场景进入对话练习，选择不同对话模式，完成后查看评分、优化建议和历史记录。

## 功能

- 5 个内置练习场景
- 3 种对话模式：支持型、压力型、深挖型
- AI 流式回复
- 练习结束后的评分、摘要、优缺点、优化回答
- 练习历史与个人统计
- 基础输入校验与敏感信息提示/脱敏
- 后端不可用时自动回退到本地模拟回复

## 技术栈

- Flutter / Material 3
- Dart
- `http`
- `sqlite3`
- 可选本地 Dart API 服务

## 本地运行

1. 安装依赖

```bash
flutter pub get
```

2. 启动后端（可选，但接真 AI 时需要）

PowerShell:

```powershell
$env:DEEPSEEK_API_KEY="你的API_KEY"
dart run server/main.dart
```

3. 启动 Flutter App

```bash
flutter run
```

如果要跑 Web：

```bash
flutter run -d chrome
```

## 配置

客户端默认连接 `http://127.0.0.1:8787`。
如果后端地址不同，启动 App 时加：

```bash
flutter run --dart-define=OFFERLAB_API_BASE_URL=http://你的地址:8787
```

后端支持这些环境变量：

- `DEEPSEEK_API_KEY`：必填
- `DEEPSEEK_BASE_URL`：默认 `https://api.deepseek.com/anthropic`
- `DEEPSEEK_MODEL`：默认 `deepseek-v4-pro`
- `OFFERLAB_API_HOST`：默认 `127.0.0.1`
- `OFFERLAB_API_PORT`：默认 `8787`

## 数据

- 练习记录保存在后端本地 SQLite
- 默认路径：`server/data/offerlab.db`

## 测试

```bash
flutter test
```

## 说明

- App 即使没有后端也能跑，AI 回复会自动降级到本地模拟
- 当前项目定位是可演示的 MVP，不包含登录、支付、云同步
