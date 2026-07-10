# OfferLab MVP 最小可行技术方案

## 1. 技术选型原则

- 优先复用 Flutter 现有能力，不为 MVP 引入复杂架构。
- 本期以本地数据和本地模拟 AI 回复跑通完整演示闭环。
- 不单独搭建后端、不接数据库、不做登录注册。
- 代码结构保持清晰，后续接入真实 AI API 时只替换服务层。

## 2. 总体方案

MVP 采用 Flutter 单端应用实现：

- 前端：Flutter + Material 组件，负责页面、路由、交互和状态展示。
- 后端：MVP 阶段不部署真实后端，在 App 内用 `MockInterviewService` 模拟 AI 对话和评分。
- 数据源：使用本地 Dart seed 数据，提供场景、角色、预设问题、模拟回复、练习记录。
- 安全模块：在 App 内做最小输入校验、敏感信息提示和空输入拦截。

当前阶段的数据流：

```text
用户操作 -> Flutter 页面 -> 本地 Service -> 本地 seed 数据 -> 页面展示结果
```

后续接真实 AI API 时的数据流：

```text
用户操作 -> Flutter 页面 -> InterviewService -> API Client -> AI 后端 -> 页面展示结果
```

## 3. 模块分工

### 3.1 前端模块

职责：

- 展示首页、场景详情页、聊天页、反馈页、记录页、我的页。
- 处理页面跳转、输入框、按钮点击、底部导航。
- 调用本地服务获取场景、AI 回复、评分结果。
- 维护当前页面内的简单状态。

输入：

- 用户点击、文本输入、页面返回操作。
- 来自服务层的场景列表、聊天消息、反馈结果、练习记录。

输出：

- 页面 UI。
- 用户输入内容。
- 对服务层的调用请求。

### 3.2 后端模块

MVP 阶段的后端是 App 内的本地模拟服务，不单独部署服务器。

职责：

- 根据场景和模式生成 AI 开场问题。
- 根据用户输入返回模拟 AI 回复。
- 在练习结束后生成评分和建议。
- 保存当前运行期间的练习记录。

输入：

- 场景 ID。
- 对话模式。
- 用户消息。
- 当前对话历史。

输出：

- AI 开场问题。
- AI 模拟回复。
- 练习评分。
- 问题分析。
- 优化回答示例。
- 练习记录。

### 3.3 数据源模块

职责：

- 提供 MVP 所需的本地静态数据。
- 管理场景、角色、模式、预设回复、评分模板。

输入：

- 场景 ID。
- 模式 ID。

输出：

- 场景详情。
- AI 角色信息。
- 预设问题。
- 模拟回复模板。
- 反馈模板。

建议本期直接使用 Dart 文件维护数据，例如 `seed_data.dart`。不使用数据库，不引入远程配置。

### 3.4 安全模块

职责：

- 阻止空消息发送。
- 对明显敏感信息做提示，例如手机号、身份证号、公司机密等。
- 限制单条输入长度，避免页面展示异常。
- 说明当前 demo 不会上传用户输入。

输入：

- 用户输入文本。

输出：

- 校验结果。
- 风险提示文案。
- 可发送的安全文本。

## 4. 核心模块输入输出

| 模块 | 输入 | 输出 |
| --- | --- | --- |
| `ScenarioRepository` | 无或场景 ID | 场景列表、场景详情 |
| `MockInterviewService` | 场景 ID、模式、消息历史、用户输入 | AI 回复、反馈结果 |
| `PracticeStore` | 新练习记录、查询请求 | 练习记录列表、记录详情 |
| `InputGuard` | 用户输入文本 | 是否可发送、提示信息、处理后的文本 |
| `HomePage` | 场景列表 | 场景卡片 UI |
| `ScenarioDetailPage` | 场景详情、模式选择 | 开始练习请求 |
| `ChatPage` | 场景、模式、消息列表 | 聊天 UI、用户消息、结束练习请求 |
| `FeedbackPage` | 反馈结果 | 评分、分析、优化回答 UI |
| `PracticeHistoryPage` | 练习记录列表 | 历史记录 UI |
| `ProfilePage` | 练习统计、版本信息 | 我的页面 UI |

## 5. 项目目录建议

```text
offer_lab/
  pubspec.yaml
  lib/
    main.dart
    app.dart
    models/
      scenario.dart
      chat_message.dart
      feedback_result.dart
      practice_record.dart
    data/
      seed_data.dart
      scenario_repository.dart
    services/
      mock_interview_service.dart
      practice_store.dart
      input_guard.dart
    pages/
      main_shell_page.dart
      home_page.dart
      scenario_detail_page.dart
      chat_page.dart
      feedback_page.dart
      practice_history_page.dart
      profile_page.dart
    widgets/
      scenario_card.dart
      mode_selector.dart
      chat_bubble.dart
      score_card.dart
      bottom_nav.dart
  test/
    input_guard_test.dart
```

## 6. 页面路由建议

- `/`：主页面壳，包含底部导航。
- `/scenario`：场景详情页。
- `/chat`：聊天页。
- `/feedback`：反馈结果页。

MVP 可直接使用 Flutter 自带 `Navigator`，不需要引入第三方路由库。

## 7. 状态管理建议

MVP 只使用 Flutter 原生状态管理：

- 页面内临时状态用 `StatefulWidget`。
- 跨页面传参用构造参数或 `Navigator` 参数。
- 练习记录用单例 `PracticeStore` 暂存。

暂不引入 BLoC、Riverpod、Redux 等状态管理库。当前业务规模不需要。

## 8. 本期不做的技术项

- 不搭建 Node、Java、Python 后端服务。
- 不接真实 AI API。
- 不接数据库。
- 不做登录鉴权。
- 不做云端同步。
- 不做复杂分层架构。
- 不做多环境配置。
- 不做埋点和监控。

## 9. 后续扩展方式

当 MVP 验收通过后，可以按以下顺序扩展：

1. 将 `MockInterviewService` 替换为真实 `InterviewApiService`。
2. 增加 API Key 或后端代理服务，避免密钥放在客户端。
3. 将 `PracticeStore` 替换为本地持久化或云端数据库。
4. 增加登录、历史记录同步和个性化训练计划。
5. 增加语音输入、语音播报和简历解析。

## 10. 最小验收闭环

本技术方案只需要支持以下闭环即可视为 MVP 技术完成：

```text
首页选择场景 -> 选择模式 -> 开始聊天 -> 发送消息 -> AI 模拟回复 -> 结束练习 -> 查看反馈 -> 写入练习记录
```

该闭环能覆盖当前需求文档和验收测试场景中的核心要求。
