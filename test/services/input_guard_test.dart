import 'package:flutter_test/flutter_test.dart';
import 'package:offer_lab/services/input_guard.dart';

void main() {
  const guard = InputGuard(maxLength: 20);

  test('blocks empty input', () {
    final result = guard.evaluate('   ');

    expect(result.canSend, isFalse);
    expect(result.level, InputNoticeLevel.none);
    expect(result.message, isNull);
  });

  test('blocks overly long input', () {
    final result = guard.evaluate('这是一段明显超过二十个字数限制的演示回答内容。');

    expect(result.canSend, isFalse);
    expect(result.level, InputNoticeLevel.error);
    expect(result.message, '单次回答请控制在 20 字以内。');
  });

  test('warns about sensitive input without blocking', () {
    final result = guard.evaluate('13812345678 客户名单');

    expect(result.canSend, isTrue);
    expect(result.level, InputNoticeLevel.hint);
    expect(result.message, contains('手机号'));
    expect(result.message, contains('公司敏感信息'));
  });

  test('allows normal input', () {
    final result = guard.evaluate('我负责推进项目上线。');

    expect(result.canSend, isTrue);
    expect(result.level, InputNoticeLevel.none);
    expect(result.message, isNull);
    expect(result.normalizedText, '我负责推进项目上线。');
  });
}
