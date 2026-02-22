import 'package:crushhour/core/network/dto/chat_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConversationDto', () {
    test('fromJson parses participants and last message', () {
      final dto = ConversationDto.fromJson(<String, dynamic>{
        'id': 'c1',
        'match_id': 'm1',
        'participants': <Map<String, dynamic>>[
          <String, dynamic>{'user_id': 'u1', 'display_name': 'A'},
          <String, dynamic>{'user_id': 'u2', 'display_name': 'B'},
        ],
        'last_message': <String, dynamic>{
          'id': 'msg-1',
          'conversation_id': 'c1',
          'sender_id': 'u2',
          'type': 'text',
          'content': 'hello',
        },
        'unread_count': 3,
        'is_pinned': true,
        'is_muted': false,
        'is_blocked': false,
        'created_at': '2026-02-21T10:00:00.000Z',
        'updated_at': '2026-02-21T11:00:00.000Z',
      });

      expect(dto.id, 'c1');
      expect(dto.serverId, 'c1');
      expect(dto.matchId, 'm1');
      expect(dto.participants, hasLength(2));
      expect(dto.lastMessage?.id, 'msg-1');
      expect(dto.unreadCount, 3);
      expect(dto.isPinned, isTrue);
      expect(dto.createdAt, isNotNull);
      expect(dto.updatedAt, isNotNull);
    });

    test('toJson serializes optional fields when present', () {
      final dto = ConversationDto(
        id: 'c1',
        matchId: 'm1',
        participants: const <ConversationParticipantDto>[
          ConversationParticipantDto(userId: 'u1', displayName: 'A'),
        ],
        lastMessage: const MessageDto(
          id: 'msg',
          conversationId: 'c1',
          senderId: 'u1',
          type: MessageType.text,
        ),
        unreadCount: 1,
        isPinned: true,
        isMuted: false,
        isBlocked: false,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
      );

      final json = dto.toJson();
      expect(json['id'], 'c1');
      expect(json['match_id'], 'm1');
      expect(json['participants'], hasLength(1));
      expect(json['last_message'], isA<Map<String, dynamic>>());
      expect(json['unread_count'], 1);
      expect(json['is_pinned'], isTrue);
      expect(json['created_at'], isNotNull);
      expect(json['updated_at'], isNotNull);
    });

    test('getOtherParticipant handles matching and fallback paths', () {
      const dto = ConversationDto(
        id: 'c1',
        matchId: 'm1',
        participants: <ConversationParticipantDto>[
          ConversationParticipantDto(userId: 'u1'),
          ConversationParticipantDto(userId: 'u2'),
        ],
      );

      expect(dto.getOtherParticipant('u1')?.userId, 'u2');
      expect(dto.getOtherParticipant('u2')?.userId, 'u1');
      expect(dto.getOtherParticipant('unknown')?.userId, 'u1');

      const onlyCurrent = ConversationDto(
        id: 'c2',
        matchId: 'm2',
        participants: <ConversationParticipantDto>[
          ConversationParticipantDto(userId: 'u1'),
        ],
      );
      expect(onlyCurrent.getOtherParticipant('u1')?.userId, 'u1');
    });

    test('getOtherParticipant returns null when participants are absent', () {
      const dto = ConversationDto(id: 'c1', matchId: 'm1');
      expect(dto.getOtherParticipant('u1'), isNull);
    });
  });

  group('ConversationParticipantDto and response wrappers', () {
    test('ConversationParticipantDto from/to json', () {
      final dto = ConversationParticipantDto.fromJson(<String, dynamic>{
        'user_id': 'u1',
        'display_name': 'User 1',
        'photo_url': 'https://example.com/u1.jpg',
        'is_online': true,
        'last_seen': '2026-02-21T09:00:00.000Z',
        'is_typing': false,
      });

      expect(dto.userId, 'u1');
      expect(dto.displayName, 'User 1');
      expect(dto.photoUrl, 'https://example.com/u1.jpg');
      expect(dto.isOnline, isTrue);
      expect(dto.lastSeen, isNotNull);
      expect(dto.isTyping, isFalse);

      final json = dto.toJson();
      expect(json['user_id'], 'u1');
      expect(json['display_name'], 'User 1');
      expect(json['photo_url'], 'https://example.com/u1.jpg');
      expect(json['is_online'], isTrue);
      expect(json['last_seen'], isNotNull);
      expect(json['is_typing'], isFalse);
    });

    test('ConversationsResponseDto from/to json with defaults', () {
      final parsed = ConversationsResponseDto.fromJson(<String, dynamic>{
        'conversations': <Map<String, dynamic>>[
          <String, dynamic>{'id': 'c1', 'match_id': 'm1'},
        ],
        'total_count': 10,
        'has_more': true,
        'next_cursor': 'next-1',
      });

      expect(parsed.conversations, hasLength(1));
      expect(parsed.totalCount, 10);
      expect(parsed.hasMore, isTrue);
      expect(parsed.nextCursor, 'next-1');

      final defaults = ConversationsResponseDto.fromJson(<String, dynamic>{});
      expect(defaults.conversations, isEmpty);

      final json = parsed.toJson();
      expect(json['conversations'], hasLength(1));
      expect(json['total_count'], 10);
      expect(json['has_more'], isTrue);
      expect(json['next_cursor'], 'next-1');
    });
  });

  group('Message enums', () {
    test('MessageType toJson/fromJson and fallback branch', () {
      expect(MessageType.image.toJson(), 'image');
      expect(MessageType.fromJson('video'), MessageType.video);
      expect(MessageType.fromJson('unknown'), MessageType.text);
    });

    test('MessageStatus toJson/fromJson and fallback branch', () {
      expect(MessageStatus.read.toJson(), 'read');
      expect(MessageStatus.fromJson('failed'), MessageStatus.failed);
      expect(MessageStatus.fromJson('unknown'), MessageStatus.sent);
    });
  });

  group('MessageDto and related DTOs', () {
    test('fromJson parses nested reply/reactions/status/readBy and flags', () {
      final dto = MessageDto.fromJson(<String, dynamic>{
        'id': 'msg-2',
        'conversation_id': 'c1',
        'sender_id': 'u1',
        'type': 'image',
        'content': 'caption',
        'media_url': 'https://example.com/image.jpg',
        'thumbnail_url': 'https://example.com/thumb.jpg',
        'media_duration': 12,
        'media_size': 2048,
        'reply_to': <String, dynamic>{
          'id': 'msg-1',
          'conversation_id': 'c1',
          'sender_id': 'u2',
          'type': 'text',
          'content': 'parent',
        },
        'reactions': <Map<String, dynamic>>[
          <String, dynamic>{
            'user_id': 'u2',
            'emoji': '🔥',
            'created_at': '2026-02-21T09:00:00.000Z',
          },
        ],
        'status': 'read',
        'read_by': <String>['u1', 'u2'],
        'deleted_at': '2026-02-21T10:00:00.000Z',
        'edited_at': '2026-02-21T11:00:00.000Z',
        'created_at': '2026-02-21T08:00:00.000Z',
        'updated_at': '2026-02-21T12:00:00.000Z',
      });

      expect(dto.id, 'msg-2');
      expect(dto.serverId, 'msg-2');
      expect(dto.type, MessageType.image);
      expect(dto.mediaUrl, isNotNull);
      expect(dto.replyTo?.id, 'msg-1');
      expect(dto.reactions, hasLength(1));
      expect(dto.status, MessageStatus.read);
      expect(dto.readBy, <String>['u1', 'u2']);
      expect(dto.isDeleted, isTrue);
      expect(dto.isEdited, isTrue);
      expect(dto.hasMedia, isTrue);

      final json = dto.toJson();
      expect(json['reactions'], hasLength(1));
      expect(json['reply_to'], isA<Map<String, dynamic>>());
    });

    test('toJson serializes optional message fields', () {
      final dto = MessageDto(
        id: 'msg-2',
        conversationId: 'c1',
        senderId: 'u1',
        type: MessageType.text,
        content: 'hello',
        status: MessageStatus.sent,
        createdAt: DateTime(2026, 1, 1),
      );

      final json = dto.toJson();
      expect(json['id'], 'msg-2');
      expect(json['conversation_id'], 'c1');
      expect(json['sender_id'], 'u1');
      expect(json['type'], 'text');
      expect(json['content'], 'hello');
      expect(json['status'], 'sent');
      expect(json['created_at'], isNotNull);
    });

    test('MessageReactionDto and MessagesResponseDto from/to json', () {
      final reaction = MessageReactionDto.fromJson(<String, dynamic>{
        'user_id': 'u2',
        'emoji': '👍',
        'created_at': '2026-02-21T09:00:00.000Z',
      });
      expect(reaction.userId, 'u2');
      expect(reaction.emoji, '👍');
      expect(reaction.toJson()['created_at'], isNotNull);

      final response = MessagesResponseDto.fromJson(<String, dynamic>{
        'messages': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'msg-1',
            'conversation_id': 'c1',
            'sender_id': 'u1',
            'type': 'text',
          },
        ],
        'has_more': true,
        'next_cursor': 'next',
        'previous_cursor': 'prev',
      });
      expect(response.messages, hasLength(1));
      expect(response.hasMore, isTrue);
      expect(response.nextCursor, 'next');
      expect(response.previousCursor, 'prev');

      final empty = MessagesResponseDto.fromJson(<String, dynamic>{});
      expect(empty.messages, isEmpty);

      final json = response.toJson();
      expect(json['messages'], hasLength(1));
      expect(json['has_more'], isTrue);
      expect(json['next_cursor'], 'next');
      expect(json['previous_cursor'], 'prev');
    });
  });

  group('SendMessageRequestDto', () {
    test('toJson includes only populated fields', () {
      const dto = SendMessageRequestDto(
        type: MessageType.video,
        content: 'caption',
        mediaUrl: 'https://example.com/video.mp4',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        mediaDuration: 20,
        replyToId: 'msg-1',
        clientId: 'client-1',
      );

      final json = dto.toJson();
      expect(json['type'], 'video');
      expect(json['content'], 'caption');
      expect(json['media_url'], 'https://example.com/video.mp4');
      expect(json['thumbnail_url'], 'https://example.com/thumb.jpg');
      expect(json['media_duration'], 20);
      expect(json['reply_to_id'], 'msg-1');
      expect(json['client_id'], 'client-1');
    });

    test('validate covers text length and media requirements', () {
      final emptyText = SendMessageRequestDto.text('');
      final veryLongText = SendMessageRequestDto.text('a' * 2001);
      final validText = SendMessageRequestDto.text('hello');
      const invalidImage = SendMessageRequestDto(type: MessageType.image);
      const invalidGif = SendMessageRequestDto(type: MessageType.gif);
      const invalidAudio = SendMessageRequestDto(type: MessageType.audio);
      const invalidVideo = SendMessageRequestDto(type: MessageType.video);
      const validMedia = SendMessageRequestDto(
        type: MessageType.image,
        mediaUrl: 'https://example.com/image.jpg',
      );

      expect(emptyText.validate(), isNotNull);
      expect(veryLongText.validate(), contains('2000'));
      expect(validText.validate(), isNull);
      expect(invalidImage.validate(), isNotNull);
      expect(invalidGif.validate(), isNotNull);
      expect(invalidAudio.validate(), isNotNull);
      expect(invalidVideo.validate(), isNotNull);
      expect(validMedia.validate(), isNull);
    });

    test('text/image/gif factories set expected fields', () {
      final text = SendMessageRequestDto.text(
        'hello',
        replyToId: 'msg-1',
        clientId: 'client-1',
      );
      expect(text.type, MessageType.text);
      expect(text.content, 'hello');
      expect(text.replyToId, 'msg-1');
      expect(text.clientId, 'client-1');

      final image = SendMessageRequestDto.image(
        'https://example.com/image.jpg',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        replyToId: 'msg-1',
        clientId: 'client-2',
      );
      expect(image.type, MessageType.image);
      expect(image.mediaUrl, 'https://example.com/image.jpg');
      expect(image.thumbnailUrl, 'https://example.com/thumb.jpg');
      expect(image.replyToId, 'msg-1');
      expect(image.clientId, 'client-2');

      final gif = SendMessageRequestDto.gif(
        'https://example.com/anim.gif',
        clientId: 'client-3',
      );
      expect(gif.type, MessageType.gif);
      expect(gif.mediaUrl, 'https://example.com/anim.gif');
      expect(gif.clientId, 'client-3');
    });
  });

  group('TypingIndicatorDto and ReadReceiptDto', () {
    test('TypingIndicatorDto from/to json', () {
      final dto = TypingIndicatorDto.fromJson(<String, dynamic>{
        'conversation_id': 'c1',
        'user_id': 'u1',
        'is_typing': true,
        'timestamp': '2026-02-21T12:00:00.000Z',
      });

      expect(dto.conversationId, 'c1');
      expect(dto.userId, 'u1');
      expect(dto.isTyping, isTrue);
      expect(dto.timestamp, isNotNull);

      expect(dto.toJson(), <String, dynamic>{
        'conversation_id': 'c1',
        'user_id': 'u1',
        'is_typing': true,
        'timestamp': dto.timestamp!.toIso8601String(),
      });
    });

    test('ReadReceiptDto from/to json', () {
      final dto = ReadReceiptDto.fromJson(<String, dynamic>{
        'conversation_id': 'c1',
        'user_id': 'u1',
        'last_read_message_id': 'msg-9',
        'timestamp': '2026-02-21T12:00:00.000Z',
      });

      expect(dto.conversationId, 'c1');
      expect(dto.userId, 'u1');
      expect(dto.lastReadMessageId, 'msg-9');
      expect(dto.timestamp, isNotNull);

      expect(dto.toJson(), <String, dynamic>{
        'conversation_id': 'c1',
        'user_id': 'u1',
        'last_read_message_id': 'msg-9',
        'timestamp': dto.timestamp!.toIso8601String(),
      });
    });
  });
}
