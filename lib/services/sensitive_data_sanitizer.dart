class SensitiveDataSanitizer {
  const SensitiveDataSanitizer();

  String sanitize(String rawText) {
    var sanitizedText = rawText;

    sanitizedText = sanitizedText.replaceAllMapped(
      _phonePattern,
      (_) => '[手机号已脱敏]',
    );
    sanitizedText = sanitizedText.replaceAllMapped(
      _idCardPattern,
      (_) => '[身份证号已脱敏]',
    );
    sanitizedText = sanitizedText.replaceAllMapped(
      _emailPattern,
      (_) => '[邮箱已脱敏]',
    );

    for (final keyword in _secretKeywords) {
      sanitizedText = sanitizedText.replaceAll(
        keyword,
        '[敏感信息已脱敏]',
      );
    }

    return sanitizedText;
  }

  static final RegExp _phonePattern = RegExp(r'(?<!\d)1[3-9]\d{9}(?!\d)');
  static final RegExp _idCardPattern = RegExp(
    r'(?<![\dXx])\d{17}[\dXx](?![\dXx])',
  );
  static final RegExp _emailPattern = RegExp(
    r'([A-Za-z0-9._%+-]+)@([A-Za-z0-9.-]+\.[A-Za-z]{2,})',
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
