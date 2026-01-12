/// Domain-level exception carrying a code and human-friendly message so UI can
/// render precise states.
class RepositoryException implements Exception {
  RepositoryException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'RepositoryException($code): $message';
}
