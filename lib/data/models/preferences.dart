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
      ];
}
