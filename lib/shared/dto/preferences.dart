import 'package:equatable/equatable.dart';

class DiscoveryPreferences extends Equatable {
  final int minAge;
  final int maxAge;
  final double maxDistanceKm;
  final List<String> showMeGenders;
  final bool showMyDistance;
  final bool showMyAge;
  final bool hideFromDiscovery;
  final bool incognitoMode;
  final String country;
  final String city;

  /// Passport mode allows Plus subscribers to see people from anywhere
  /// regardless of distance. When enabled, distance filters are ignored.
  final bool passportModeEnabled;

  /// Location override for Passport mode (e.g., "Paris, France").
  /// When set, user appears in that location for discovery.
  final String? passportLocation;

  /// Latitude for passport location.
  final double? passportLatitude;

  /// Longitude for passport location.
  final double? passportLongitude;

  /// Whether the local deck (within 220km) has been exhausted.
  /// When true, users can see people beyond 220km even without Plus.
  final bool localDeckExhausted;

  const DiscoveryPreferences({
    required this.minAge,
    required this.maxAge,
    required this.maxDistanceKm,
    required this.showMeGenders,
    required this.showMyDistance,
    required this.showMyAge,
    required this.hideFromDiscovery,
    required this.incognitoMode,
    required this.country,
    required this.city,
    this.passportModeEnabled = false,
    this.passportLocation,
    this.passportLatitude,
    this.passportLongitude,
    this.localDeckExhausted = false,
  });

  DiscoveryPreferences copyWith({
    int? minAge,
    int? maxAge,
    double? maxDistanceKm,
    List<String>? showMeGenders,
    bool? showMyDistance,
    bool? showMyAge,
    bool? hideFromDiscovery,
    bool? incognitoMode,
    String? country,
    String? city,
    bool? passportModeEnabled,
    String? passportLocation,
    double? passportLatitude,
    double? passportLongitude,
    bool? localDeckExhausted,
  }) {
    return DiscoveryPreferences(
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
      showMeGenders: showMeGenders ?? this.showMeGenders,
      showMyDistance: showMyDistance ?? this.showMyDistance,
      showMyAge: showMyAge ?? this.showMyAge,
      hideFromDiscovery: hideFromDiscovery ?? this.hideFromDiscovery,
      incognitoMode: incognitoMode ?? this.incognitoMode,
      country: country ?? this.country,
      city: city ?? this.city,
      passportModeEnabled: passportModeEnabled ?? this.passportModeEnabled,
      passportLocation: passportLocation ?? this.passportLocation,
      passportLatitude: passportLatitude ?? this.passportLatitude,
      passportLongitude: passportLongitude ?? this.passportLongitude,
      localDeckExhausted: localDeckExhausted ?? this.localDeckExhausted,
    );
  }

  @override
  List<Object?> get props => [
        minAge,
        maxAge,
        maxDistanceKm,
        showMeGenders,
        showMyDistance,
        showMyAge,
        hideFromDiscovery,
        incognitoMode,
        country,
        city,
        passportModeEnabled,
        passportLocation,
        passportLatitude,
        passportLongitude,
        localDeckExhausted,
      ];
}
