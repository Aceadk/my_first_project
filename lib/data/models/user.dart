import 'package:equatable/equatable.dart';
import 'profile.dart';
import 'subscription.dart';

class CrushUser extends Equatable {
  final String id;
  final String phoneNumber;
  final String? email;
  final Profile? profile;
  final bool isPhoneVerified;
  final bool isIdVerified;
  final SubscriptionPlan plan;

  const CrushUser({
    required this.id,
    required this.phoneNumber,
    this.email,
    this.profile,
    required this.isPhoneVerified,
    required this.isIdVerified,
    required this.plan,
  });

  bool get canChat => isIdVerified;

  CrushUser copyWith({
    String? id,
    String? phoneNumber,
    String? email,
    Profile? profile,
    bool? isPhoneVerified,
    bool? isIdVerified,
    SubscriptionPlan? plan,
  }) {
    return CrushUser(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      profile: profile ?? this.profile,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isIdVerified: isIdVerified ?? this.isIdVerified,
      plan: plan ?? this.plan,
    );
  }

  @override
  List<Object?> get props => [
        id,
        phoneNumber,
        email,
        profile,
        isPhoneVerified,
        isIdVerified,
        plan,
      ];
}
