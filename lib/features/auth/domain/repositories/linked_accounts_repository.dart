enum LinkedAuthProvider { google, apple }

extension LinkedAuthProviderX on LinkedAuthProvider {
  String get providerId {
    switch (this) {
      case LinkedAuthProvider.google:
        return 'google.com';
      case LinkedAuthProvider.apple:
        return 'apple.com';
    }
  }

  String get displayName {
    switch (this) {
      case LinkedAuthProvider.google:
        return 'Google';
      case LinkedAuthProvider.apple:
        return 'Apple';
    }
  }
}

/// Optional capability for auth repositories that support provider linking.
abstract class LinkedAccountsRepository {
  Future<Set<String>> getLinkedProviderIds();

  Future<void> linkProvider(LinkedAuthProvider provider);

  Future<void> unlinkProvider(LinkedAuthProvider provider);
}
