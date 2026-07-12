enum InputNoticeLevel {
  none,
  hint,
  error,
}

class InputGuardResult {
  const InputGuardResult({
    required this.normalizedText,
    required this.canSend,
    required this.level,
    this.message,
  });

  final String normalizedText;
  final bool canSend;
  final InputNoticeLevel level;
  final String? message;

  bool get hasMessage => message != null;
}

class InputGuard {
  const InputGuard({
    this.maxLength = 280,
  });

  final int maxLength;

  InputGuardResult evaluate(String rawText) {
    final normalizedText = rawText.trim();

    if (normalizedText.isEmpty) {
      return InputGuardResult(
        normalizedText: normalizedText,
        canSend: false,
        level: InputNoticeLevel.none,
      );
    }

    if (normalizedText.length > maxLength) {
      return InputGuardResult(
        normalizedText: normalizedText,
        canSend: false,
        level: InputNoticeLevel.error,
        message: '单次回答请控制在 $maxLength 字以内。',
      );
    }

    final notices = <String>[];
    if (_phonePattern.hasMatch(normalizedText)) {
      notices.add('手机号');
    }
    if (_idCardPattern.hasMatch(normalizedText)) {
      notices.add('身份证号');
    }
    if (_containsSecretKeyword(normalizedText)) {
      notices.add('公司敏感信息');
    }

    if (notices.isNotEmpty) {
      return InputGuardResult(
        normalizedText: normalizedText,
        canSend: true,
        level: InputNoticeLevel.hint,
        message: '检测到${notices.join('、')}，演示时建议改成模糊描述。',
      );
    }

    return InputGuardResult(
      normalizedText: normalizedText,
      canSend: true,
      level: InputNoticeLevel.none,
    );
  }

  bool _containsSecretKeyword(String text) {
    return _secretKeywords.any(text.contains);
  }

  static final RegExp _phonePattern = RegExp(r'(?<!\d)1[3-9]\d{9}(?!\d)');
  static final RegExp _idCardPattern = RegExp(
    r'(?<![\dXx])\d{17}[\dXx](?![\dXx])',
  );

  static const List<String> _secretKeywords = [
    '商业机密',
    '保密协议',
    '客户名单',
    '未公开财务',
    '内部数据',
    '薪资表',
    'confidential',
  ];
}
