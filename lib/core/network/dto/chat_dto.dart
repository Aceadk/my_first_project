import 'base_dto.dart';

// ═══════════════════════════════════════════════════════════════════════════
// CONVERSATION DTOs
// ═══════════════════════════════════════════════════════════════════════════

/// Conversation DTO.
class ConversationDto extends BaseDto with DtoMetadata {
  const ConversationDto({
    required this.id,
    required this.matchId,
    this.participants,
    this.lastMessage,
    this.unreadCount,
    this.isPinned,
    this.isMuted,
    this.isBlocked,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String matchId;
  final List<ConversationParticipantDto>? participants;
  final MessageDto? lastMessage;
  final int? unreadCount;
  final bool? isPinned;
  final bool? isMuted;
  final bool? isBlocked;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String? get serverId => id;

  /// Get the other participant (not the current user).
  ConversationParticipantDto? getOtherParticipant(String currentUserId) {
    return participants?.firstWhere(
      (p) => p.userId != currentUserId,
      orElse: () => participants!.first,
    );
  }

  factory ConversationDto.fromJson(Map<String, dynamic> json) {
    return ConversationDto(
      id: json.getString('id') ?? '',
      matchId: json.getString('match_id') ?? '',
      participants: json.getList(
        'participants',
        (e) => ConversationParticipantDto.fromJson(e as Map<String, dynamic>),
      ),
      lastMessage: json.getMap('last_message') != null
          ? MessageDto.fromJson(json.getMap('last_message')!)
          : null,
      unreadCount: json.getInt('unread_count'),
      isPinned: json.getBool('is_pinned'),
      isMuted: json.getBool('is_muted'),
      isBlocked: json.getBool('is_blocked'),
      createdAt: json.getDateTime('created_at'),
      updatedAt: json.getDateTime('updated_at'),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'match_id': matchId,
        if (participants != null)
          'participants': participants!.map((p) => p.toJson()).toList(),
        if (lastMessage != null) 'last_message': lastMessage!.toJson(),
        if (unreadCount != null) 'unread_count': unreadCount,
        if (isPinned != null) 'is_pinned': isPinned,
        if (isMuted != null) 'is_muted': isMuted,
        if (isBlocked != null) 'is_blocked': isBlocked,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };
}

/// Conversation participant DTO.
class ConversationParticipantDto extends BaseDto {
  const ConversationParticipantDto({
    required this.userId,
    this.displayName,
    this.photoUrl,
    this.isOnline,
    this.lastSeen,
    this.isTyping,
  });

  final String userId;
  final String? displayName;
  final String? photoUrl;
  final bool? isOnline;
  final DateTime? lastSeen;
  final bool? isTyping;

  factory ConversationParticipantDto.fromJson(Map<String, dynamic> json) {
    return ConversationParticipantDto(
      userId: json.getString('user_id') ?? '',
      displayName: json.getString('display_name'),
      photoUrl: json.getString('photo_url'),
      isOnline: json.getBool('is_online'),
      lastSeen: json.getDateTime('last_seen'),
      isTyping: json.getBool('is_typing'),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'user_id': userId,
        if (displayName != null) 'display_name': displayName,
        if (photoUrl != null) 'photo_url': photoUrl,
        if (isOnline != null) 'is_online': isOnline,
        if (lastSeen != null) 'last_seen': lastSeen!.toIso8601String(),
        if (isTyping != null) 'is_typing': isTyping,
      };
}

/// Conversations list response.
class ConversationsResponseDto extends BaseDto {
  const ConversationsResponseDto({
    required this.conversations,
    this.totalCount,
    this.hasMore,
    this.nextCursor,
  });

  final List<ConversationDto> conversations;
  final int? totalCount;
  final bool? hasMore;
  final String? nextCursor;

  factory ConversationsResponseDto.fromJson(Map<String, dynamic> json) {
    return ConversationsResponseDto(
      conversations: json.getList(
            'conversations',
            (e) => ConversationDto.fromJson(e as Map<String, dynamic>),
          ) ??
          [],
      totalCount: json.getInt('total_count'),
      hasMore: json.getBool('has_more'),
      nextCursor: json.getString('next_cursor'),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'conversations': conversations.map((c) => c.toJson()).toList(),
        if (totalCount != null) 'total_count': totalCount,
        if (hasMore != null) 'has_more': hasMore,
        if (nextCursor != null) 'next_cursor': nextCursor,
      };
}

// ═══════════════════════════════════════════════════════════════════════════
// MESSAGE DTOs
// ═══════════════════════════════════════════════════════════════════════════

/// Message types.
enum MessageType {
  text,
  image,
  gif,
  audio,
  video,
  location,
  contact,
  system;

  String toJson() => name;

  static MessageType fromJson(String value) {
    return MessageType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MessageType.text,
    );
  }
}

/// Message status.
enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed;

  String toJson() => name;

  static MessageStatus fromJson(String value) {
    return MessageStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MessageStatus.sent,
    );
  }
}

/// Message DTO.
class MessageDto extends BaseDto with DtoMetadata {
  const MessageDto({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.type,
    this.content,
    this.mediaUrl,
    this.thumbnailUrl,
    this.mediaDuration,
    this.mediaSize,
    this.replyTo,
    this.reactions,
    this.status,
    this.readBy,
    this.deletedAt,
    this.editedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final MessageType type;
  final String? content;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final int? mediaDuration;
  final int? mediaSize;
  final MessageDto? replyTo;
  final List<MessageReactionDto>? reactions;
  final MessageStatus? status;
  final List<String>? readBy;
  final DateTime? deletedAt;
  final DateTime? editedAt;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String? get serverId => id;

  /// Check if message is deleted.
  bool get isDeleted => deletedAt != null;

  /// Check if message was edited.
  bool get isEdited => editedAt != null;

  /// Check if message has media.
  bool get hasMedia => mediaUrl != null;

  factory MessageDto.fromJson(Map<String, dynamic> json) {
    return MessageDto(
      id: json.getString('id') ?? '',
      conversationId: json.getString('conversation_id') ?? '',
      senderId: json.getString('sender_id') ?? '',
      type: MessageType.fromJson(json.getString('type') ?? 'text'),
      content: json.getString('content'),
      mediaUrl: json.getString('media_url'),
      thumbnailUrl: json.getString('thumbnail_url'),
      mediaDuration: json.getInt('media_duration'),
      mediaSize: json.getInt('media_size'),
      replyTo: json.getMap('reply_to') != null
          ? MessageDto.fromJson(json.getMap('reply_to')!)
          : null,
      reactions: json.getList(
        'reactions',
        (e) => MessageReactionDto.fromJson(e as Map<String, dynamic>),
      ),
      status: json.getString('status') != null
          ? MessageStatus.fromJson(json.getString('status')!)
          : null,
      readBy: json.getList('read_by', (e) => e.toString()),
      deletedAt: json.getDateTime('deleted_at'),
      editedAt: json.getDateTime('edited_at'),
      createdAt: json.getDateTime('created_at'),
      updatedAt: json.getDateTime('updated_at'),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'conversation_id': conversationId,
        'sender_id': senderId,
        'type': type.toJson(),
        if (content != null) 'content': content,
        if (mediaUrl != null) 'media_url': mediaUrl,
        if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
        if (mediaDuration != null) 'media_duration': mediaDuration,
        if (mediaSize != null) 'media_size': mediaSize,
        if (replyTo != null) 'reply_to': replyTo!.toJson(),
        if (reactions != null)
          'reactions': reactions!.map((r) => r.toJson()).toList(),
        if (status != null) 'status': status!.toJson(),
        if (readBy != null) 'read_by': readBy,
        if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
        if (editedAt != null) 'edited_at': editedAt!.toIso8601String(),
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };
}

/// Message reaction DTO.
class MessageReactionDto extends BaseDto {
  const MessageReactionDto({
    required this.userId,
    required this.emoji,
    this.createdAt,
  });

  final String userId;
  final String emoji;
  final DateTime? createdAt;

  factory MessageReactionDto.fromJson(Map<String, dynamic> json) {
    return MessageReactionDto(
      userId: json.getString('user_id') ?? '',
      emoji: json.getString('emoji') ?? '',
      createdAt: json.getDateTime('created_at'),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'emoji': emoji,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };
}

/// Messages list response.
class MessagesResponseDto extends BaseDto {
  const MessagesResponseDto({
    required this.messages,
    this.hasMore,
    this.nextCursor,
    this.previousCursor,
  });

  final List<MessageDto> messages;
  final bool? hasMore;
  final String? nextCursor;
  final String? previousCursor;

  factory MessagesResponseDto.fromJson(Map<String, dynamic> json) {
    return MessagesResponseDto(
      messages: json.getList(
            'messages',
            (e) => MessageDto.fromJson(e as Map<String, dynamic>),
          ) ??
          [],
      hasMore: json.getBool('has_more'),
      nextCursor: json.getString('next_cursor'),
      previousCursor: json.getString('previous_cursor'),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'messages': messages.map((m) => m.toJson()).toList(),
        if (hasMore != null) 'has_more': hasMore,
        if (nextCursor != null) 'next_cursor': nextCursor,
        if (previousCursor != null) 'previous_cursor': previousCursor,
      };
}

// ═══════════════════════════════════════════════════════════════════════════
// SEND MESSAGE REQUEST
// ═══════════════════════════════════════════════════════════════════════════

/// Send message request DTO.
class SendMessageRequestDto extends BaseDto {
  const SendMessageRequestDto({
    required this.type,
    this.content,
    this.mediaUrl,
    this.thumbnailUrl,
    this.mediaDuration,
    this.replyToId,
    this.clientId,
  });

  final MessageType type;
  final String? content;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final int? mediaDuration;
  final String? replyToId;
  final String? clientId;

  @override
  Map<String, dynamic> toJson() => {
        'type': type.toJson(),
        if (content != null) 'content': content,
        if (mediaUrl != null) 'media_url': mediaUrl,
        if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
        if (mediaDuration != null) 'media_duration': mediaDuration,
        if (replyToId != null) 'reply_to_id': replyToId,
        if (clientId != null) 'client_id': clientId,
      };

  @override
  String? validate() {
    final validator = DtoValidator();

    // Text messages require content
    if (type == MessageType.text) {
      validator.requireNotEmpty(content, 'content');
      if (content != null) {
        validator.require(
          content!.length <= 2000,
          'content',
          'Message must be 2000 characters or less',
        );
      }
    }

    // Media messages require mediaUrl
    if ([
      MessageType.image,
      MessageType.audio,
      MessageType.video,
      MessageType.gif
    ].contains(type)) {
      validator.requireNotEmpty(mediaUrl, 'media_url');
    }

    return validator.build().firstError;
  }

  /// Create a text message request.
  factory SendMessageRequestDto.text(String content,
      {String? replyToId, String? clientId}) {
    return SendMessageRequestDto(
      type: MessageType.text,
      content: content,
      replyToId: replyToId,
      clientId: clientId,
    );
  }

  /// Create an image message request.
  factory SendMessageRequestDto.image(
    String mediaUrl, {
    String? thumbnailUrl,
    String? replyToId,
    String? clientId,
  }) {
    return SendMessageRequestDto(
      type: MessageType.image,
      mediaUrl: mediaUrl,
      thumbnailUrl: thumbnailUrl,
      replyToId: replyToId,
      clientId: clientId,
    );
  }

  /// Create a GIF message request.
  factory SendMessageRequestDto.gif(String mediaUrl, {String? clientId}) {
    return SendMessageRequestDto(
      type: MessageType.gif,
      mediaUrl: mediaUrl,
      clientId: clientId,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TYPING INDICATOR
// ═══════════════════════════════════════════════════════════════════════════

/// Typing indicator DTO.
class TypingIndicatorDto extends BaseDto {
  const TypingIndicatorDto({
    required this.conversationId,
    required this.userId,
    required this.isTyping,
    this.timestamp,
  });

  final String conversationId;
  final String userId;
  final bool isTyping;
  final DateTime? timestamp;

  factory TypingIndicatorDto.fromJson(Map<String, dynamic> json) {
    return TypingIndicatorDto(
      conversationId: json.getString('conversation_id') ?? '',
      userId: json.getString('user_id') ?? '',
      isTyping: json.getBool('is_typing') ?? false,
      timestamp: json.getDateTime('timestamp'),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'conversation_id': conversationId,
        'user_id': userId,
        'is_typing': isTyping,
        if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
      };
}

// ═══════════════════════════════════════════════════════════════════════════
// READ RECEIPT
// ═══════════════════════════════════════════════════════════════════════════

/// Read receipt DTO.
class ReadReceiptDto extends BaseDto {
  const ReadReceiptDto({
    required this.conversationId,
    required this.userId,
    required this.lastReadMessageId,
    this.timestamp,
  });

  final String conversationId;
  final String userId;
  final String lastReadMessageId;
  final DateTime? timestamp;

  factory ReadReceiptDto.fromJson(Map<String, dynamic> json) {
    return ReadReceiptDto(
      conversationId: json.getString('conversation_id') ?? '',
      userId: json.getString('user_id') ?? '',
      lastReadMessageId: json.getString('last_read_message_id') ?? '',
      timestamp: json.getDateTime('timestamp'),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'conversation_id': conversationId,
        'user_id': userId,
        'last_read_message_id': lastReadMessageId,
        if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
      };
}
