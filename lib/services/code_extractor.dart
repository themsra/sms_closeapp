class CodeExtractor {
  static String extract(String message) {
    final text = _normalizeDigits(message);

    final keyword = RegExp(
      r'(?:کد|رمز|تایید|تأیید|verification|verify|code|otp)[^0-9A-Za-z]{0,20}([0-9]{4,8})',
      caseSensitive: false,
    );
    final keywordMatch = keyword.firstMatch(text);
    if (keywordMatch != null) return keywordMatch.group(1)!;

    final matches = RegExp(r'(?<!\d)\d{4,8}(?!\d)').allMatches(text);
    final values = <String>[];
    for (final match in matches) {
      final value = match.group(0)!;
      if (!values.contains(value)) values.add(value);
    }
    return values.join(' ');
  }

  static String _normalizeDigits(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      if (rune >= 0x06F0 && rune <= 0x06F9) {
        buffer.writeCharCode(0x30 + rune - 0x06F0);
      } else if (rune >= 0x0660 && rune <= 0x0669) {
        buffer.writeCharCode(0x30 + rune - 0x0660);
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }
}
