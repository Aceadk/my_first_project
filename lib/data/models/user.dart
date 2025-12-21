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
  });

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
      ];
}
