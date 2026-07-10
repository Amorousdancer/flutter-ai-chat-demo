import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offer_lab/app.dart';
import 'package:offer_lab/services/practice_store.dart';

void main() {
  setUp(() {
    PracticeStore.instance.clear();
  });

  testWidgets('switches between the main navigation tabs', (tester) async {
    await tester.pumpWidget(const OfferLabApp());

    expect(find.text('OfferLab'), findsOneWidget);
    expect(find.text('已加载 5 个本地练习场景'), findsOneWidget);

    await tester.tap(find.text('记录'));
    await tester.pumpAndSettle();

    expect(find.text('练习记录'), findsOneWidget);
    expect(find.text('最近练习'), findsOneWidget);
    expect(find.text('完成一轮练习后，这里会显示你的历史记录。'), findsOneWidget);

    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();

    expect(find.text('个人中心'), findsOneWidget);
    expect(find.text('我的页面骨架已就绪'), findsOneWidget);
  });

  testWidgets('opens scenario detail and starts a practice session', (
    tester,
  ) async {
    await tester.pumpWidget(const OfferLabApp());

    await tester.tap(find.text('Flutter 开发面试'));
    await tester.pumpAndSettle();

    expect(find.text('练习目标'), findsOneWidget);
    expect(find.text('AI 扮演角色'), findsOneWidget);
    expect(find.text('练习模式'), findsOneWidget);

    await tester.tap(find.text('压力模式'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('start-practice-button')),
      200,
    );
    await tester.tap(find.byKey(const Key('start-practice-button')));
    await tester.pumpAndSettle();

    expect(find.text('压力模式'), findsOneWidget);
    expect(find.text('输入你的回答...'), findsOneWidget);
    expect(find.textContaining('我会用更直接的方式追问你。'), findsOneWidget);
  });

  testWidgets('sends a message and receives a mock ai reply', (tester) async {
    await tester.pumpWidget(const OfferLabApp());

    await tester.tap(find.text('Flutter 开发面试'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('start-practice-button')),
      200,
    );
    await tester.tap(find.byKey(const Key('start-practice-button')));
    await tester.pumpAndSettle();

    final sendButton = tester.widget<FilledButton>(
      find.byKey(const Key('send-button')),
    );
    expect(sendButton.onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('chat-input')),
      '我最近做了一个 Flutter 项目，负责状态管理和性能优化。',
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('send-button')));
    await tester.pump();

    expect(find.text('我最近做了一个 Flutter 项目，负责状态管理和性能优化。'), findsOneWidget);
    expect(find.text('AI 正在输入...'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('AI 正在输入...'), findsNothing);
    expect(find.textContaining('你的回答方向是对的'), findsOneWidget);
  });

  testWidgets('finishes practice and shows feedback in history', (tester) async {
    await tester.pumpWidget(const OfferLabApp());

    await tester.tap(find.text('Flutter 开发面试'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('start-practice-button')),
      200,
    );
    await tester.tap(find.byKey(const Key('start-practice-button')));
    await tester.pumpAndSettle();

    Future<void> sendReply(String text) async {
      await tester.enterText(find.byKey(const Key('chat-input')), text);
      await tester.pump();
      await tester.tap(find.byKey(const Key('send-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
    }

    await sendReply('第一轮回答，介绍项目背景。');
    await sendReply('第二轮回答，说明我具体做了什么。');
    await sendReply('第三轮回答，补充结果和复盘。');

    final finishButton = tester.widget<TextButton>(
      find.byKey(const Key('finish-practice-button')),
    );
    expect(finishButton.onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('finish-practice-button')));
    await tester.pumpAndSettle();

    expect(find.text('练习反馈'), findsOneWidget);
    expect(find.textContaining('分'), findsWidgets);
    expect(find.text('优化回答示例'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('记录'));
    await tester.pumpAndSettle();

    expect(find.text('Flutter 开发面试'), findsOneWidget);
    expect(find.textContaining('整体结构已经建立起来'), findsOneWidget);

    await tester.tap(find.text('Flutter 开发面试'));
    await tester.pumpAndSettle();

    expect(find.text('关键片段'), findsOneWidget);
    expect(find.text('继续改进'), findsOneWidget);
  });
}
