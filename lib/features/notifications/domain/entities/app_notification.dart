import 'package:equatable/equatable.dart';

/// Types of in-app notifications.
enum NotificationType {
  match,
  message,
  like,
  profileView,
  system,
  boostExpired,
  weeklyPicks,
}

/// A single in-app notification entry.
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.imageUrl,
    this.targetId,
    this.targetRoute,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;

  /// Profile photo or relevant image URL.
  final String? imageUrl;

  /// ID of the related entity (matchId, userId, etc.).
  final String? targetId;

  /// Route to navigate to when tapped.
  final String? targetRoute;

  AppNotification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? body,
    DateTime? createdAt,
    bool? isRead,
    String? imageUrl,
    String? targetId,
    String? targetRoute,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl ?? this.imageUrl,
      targetId: targetId ?? this.targetId,
      targetRoute: targetRoute ?? this.targetRoute,
    );
  }

  @override
  List<Object?> get props => [
    id,
    type,
    title,
    body,
    createdAt,
    isRead,
    imageUrl,
    targetId,
    targetRoute,
  ];
}
