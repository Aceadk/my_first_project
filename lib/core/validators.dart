final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final RegExp _zeroWidthRegex = RegExp(r'[\u200B-\u200D\uFEFF]');

String normalizeEmail(String input) {
  final cleaned = input.trim().replaceAll(_zeroWidthRegex, '');
  return cleaned.toLowerCase();
}

bool looksLikeEmail(String input) {
  final cleaned = normalizeEmail(input);
  return _emailRegex.hasMatch(cleaned);
}
