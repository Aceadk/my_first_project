import 'package:equatable/equatable.dart';

/// A date plan that can be shared with trusted contacts for safety.
class DatePlan extends Equatable {
  const DatePlan({
    required this.id,
    required this.userId,
    required this.matchId,
    required this.matchName,
    this.matchPhotoUrl,
    required this.dateTime,
    required this.location,
    this.locationAddress,
    this.locationLatitude,
    this.locationLongitude,
    this.notes,
    required this.sharedWith,
    required this.createdAt,
    this.checkInTime,
    this.checkedInAt,
    this.status = DatePlanStatus.scheduled,
  });

  /// Unique identifier for this date plan.
  final String id;

  /// User ID who created the plan.
  final String userId;

  /// Match/date's user ID.
  final String matchId;

  /// Match's display name.
  final String matchName;

  /// Match's photo URL.
  final String? matchPhotoUrl;

  /// Scheduled date and time.
  final DateTime dateTime;

  /// Location name (e.g., "Starbucks Downtown").
  final String location;

  /// Full address of the location.
  final String? locationAddress;

  /// Location latitude.
  final double? locationLatitude;

  /// Location longitude.
  final double? locationLongitude;

  /// Additional notes about the date.
  final String? notes;

  /// List of contacts this plan is shared with.
  final List<EmergencyContact> sharedWith;

  /// When the plan was created.
  final DateTime createdAt;

  /// Expected check-in time (usually 1-2 hours after date starts).
  final DateTime? checkInTime;

  /// When the user checked in as safe.
  final DateTime? checkedInAt;

  /// Current status of the date plan.
  final DatePlanStatus status;

  /// Check if the date is upcoming.
  bool get isUpcoming =>
      status == DatePlanStatus.scheduled && dateTime.isAfter(DateTime.now());

  /// Check if check-in is overdue.
  bool get isCheckInOverdue {
    if (checkInTime == null || checkedInAt != null) return false;
    return DateTime.now().isAfter(checkInTime!);
  }

  /// Check if user has checked in.
  bool get hasCheckedIn => checkedInAt != null;

  /// Get time until date.
  Duration get timeUntilDate => dateTime.difference(DateTime.now());

  /// Get formatted date string.
  String get formattedDate {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final dateDay = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (dateDay == DateTime(now.year, now.month, now.day)) {
      return 'Today';
    } else if (dateDay == tomorrow) {
      return 'Tomorrow';
    } else {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    }
  }

  /// Get formatted time string.
  String get formattedTime {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  DatePlan copyWith({
    String? id,
    String? userId,
    String? matchId,
    String? matchName,
    String? matchPhotoUrl,
    DateTime? dateTime,
    String? location,
    String? locationAddress,
    double? locationLatitude,
    double? locationLongitude,
    String? notes,
    List<EmergencyContact>? sharedWith,
    DateTime? createdAt,
    DateTime? checkInTime,
    DateTime? checkedInAt,
    DatePlanStatus? status,
  }) {
    return DatePlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      matchId: matchId ?? this.matchId,
      matchName: matchName ?? this.matchName,
      matchPhotoUrl: matchPhotoUrl ?? this.matchPhotoUrl,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      locationAddress: locationAddress ?? this.locationAddress,
      locationLatitude: locationLatitude ?? this.locationLatitude,
      locationLongitude: locationLongitude ?? this.locationLongitude,
      notes: notes ?? this.notes,
      sharedWith: sharedWith ?? this.sharedWith,
      createdAt: createdAt ?? this.createdAt,
      checkInTime: checkInTime ?? this.checkInTime,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'matchId': matchId,
      'matchName': matchName,
      'matchPhotoUrl': matchPhotoUrl,
      'dateTime': dateTime.toIso8601String(),
      'location': location,
      'locationAddress': locationAddress,
      'locationLatitude': locationLatitude,
      'locationLongitude': locationLongitude,
      'notes': notes,
      'sharedWith': sharedWith.map((c) => c.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'checkInTime': checkInTime?.toIso8601String(),
      'checkedInAt': checkedInAt?.toIso8601String(),
      'status': status.name,
    };
  }

  factory DatePlan.fromJson(Map<String, dynamic> json) {
    return DatePlan(
      id: json['id'] as String,
      userId: json['userId'] as String,
      matchId: json['matchId'] as String,
      matchName: json['matchName'] as String,
      matchPhotoUrl: json['matchPhotoUrl'] as String?,
      dateTime: DateTime.parse(json['dateTime'] as String),
      location: json['location'] as String,
      locationAddress: json['locationAddress'] as String?,
      locationLatitude: (json['locationLatitude'] as num?)?.toDouble(),
      locationLongitude: (json['locationLongitude'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      sharedWith: (json['sharedWith'] as List<dynamic>)
          .map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      checkInTime: json['checkInTime'] != null
          ? DateTime.parse(json['checkInTime'] as String)
          : null,
      checkedInAt: json['checkedInAt'] != null
          ? DateTime.parse(json['checkedInAt'] as String)
          : null,
      status: DatePlanStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DatePlanStatus.scheduled,
      ),
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        matchId,
        matchName,
        matchPhotoUrl,
        dateTime,
        location,
        locationAddress,
        locationLatitude,
        locationLongitude,
        notes,
        sharedWith,
        createdAt,
        checkInTime,
        checkedInAt,
        status,
      ];
}

/// Status of a date plan.
enum DatePlanStatus {
  scheduled,
  ongoing,
  completed,
  cancelled,
  emergency,
}

/// An emergency contact for sharing date details.
class EmergencyContact extends Equatable {
  const EmergencyContact({
    required this.name,
    required this.phone,
    this.email,
    this.relationship,
    this.notifyBySms = true,
    this.notifyByEmail = false,
  });

  final String name;
  final String phone;
  final String? email;
  final String? relationship;
  final bool notifyBySms;
  final bool notifyByEmail;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'relationship': relationship,
      'notifyBySms': notifyBySms,
      'notifyByEmail': notifyByEmail,
    };
  }

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      relationship: json['relationship'] as String?,
      notifyBySms: json['notifyBySms'] as bool? ?? true,
      notifyByEmail: json['notifyByEmail'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        name,
        phone,
        email,
        relationship,
        notifyBySms,
        notifyByEmail,
      ];
}
