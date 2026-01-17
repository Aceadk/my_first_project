import 'package:equatable/equatable.dart';
import 'profile.dart';
import 'subscription.dart';

class CrushUser extends Equatable {
  final String id;
  final String phoneNumber;
  final String? email;
  final String? username;
  final bool isEmailVerified;
  final Profile? profile;
  final bool isPhoneVerified;
  final bool isIdVerified;
  final SubscriptionPlan plan;
  final bool hasAcceptedTerms;

  const CrushUser({
    required this.id,
    required this.phoneNumber,
    this.email,
    this.username,
    required this.isEmailVerified,
    this.profile,
    required this.isPhoneVerified,
    required this.isIdVerified,
    required this.plan,
    this.hasAcceptedTerms = false,
  });

  /// User can swipe if EITHER email OR phone is verified (not both required)
  bool get isAccountVerified => isEmailVerified || isPhoneVerified;

  bool get canChat => isIdVerified;

  CrushUser copyWith({
    String? id,
    String? phoneNumber,
    String? email,
    String? username,
    bool? isEmailVerified,
    Profile? profile,
    bool? isPhoneVerified,
    bool? isIdVerified,
    SubscriptionPlan? plan,
    bool? hasAcceptedTerms,
  }) {
    return CrushUser(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      username: username ?? this.username,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      profile: profile ?? this.profile,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isIdVerified: isIdVerified ?? this.isIdVerified,
      plan: plan ?? this.plan,
      hasAcceptedTerms: hasAcceptedTerms ?? this.hasAcceptedTerms,
    );
  }

  @override
  List<Object?> get props => [
        id,
        phoneNumber,
        email,
        username,
        isEmailVerified,
        profile,
        isPhoneVerified,
        isIdVerified,
        plan,
        hasAcceptedTerms,
      ];
}
