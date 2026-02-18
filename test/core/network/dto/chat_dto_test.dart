import 'package:crushhour/core/network/dto/chat_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MessageDto', () {
    const messageId = 'msg-1';
    final now = DateTime.now();

    final validMessageJson = {
      'id': messageId,
      'conversation_id': 'conv-1',
      'sender_id': 'user-1',
      'type': 'text',
      'content': 'Hello',
      'created_at': now.toIso8601String(),
    };

    test('fromJson creates correct instance', () {
      final dto = MessageDto.fromJson(validMessageJson);

      expect(dto.id, messageId);
      expect(dto.conversationId, 'conv-1');
      expect(dto.type, MessageType.text);
      expect(dto.content, 'Hello');
    });

    test('toJson returns correct map', () {
      final dto = MessageDto.fromJson(validMessageJson);
      final json = dto.toJson();

      expect(json['id'], messageId);
      expect(json['type'], 'text');
    });

    test('hasMedia returns correct value', () {
      final textDto = MessageDto.fromJson(validMessageJson);
      expect(textDto.hasMedia, false);

      const mediaDto = MessageDto(
        id: '2',
        conversationId: 'c',
        senderId: 's',
        type: MessageType.image,
        mediaUrl: 'http://image.com',
      );
      expect(mediaDto.hasMedia, true);
    });
  });

  group('ConversationDto', () {
    test('fromJson handles participants correctly', () {
      final json = {
        'id': 'c1',
        'match_id': 'm1',
        'participants': [
          {'user_id': 'u1', 'display_name': 'A'},
          {'user_id': 'u2', 'display_name': 'B'},
        ],
      };

      final dto = ConversationDto.fromJson(json);
      expect(dto.participants?.length, 2);
      expect(dto.participants?.first.userId, 'u1');
    });

    test('getOtherParticipant returns correct user', () {
      const dto = ConversationDto(
        id: 'c1',
        matchId: 'm1',
        participants: [
          ConversationParticipantDto(userId: 'u1'),
          ConversationParticipantDto(userId: 'u2'),
        ],
      );

      expect(dto.getOtherParticipant('u1')?.userId, 'u2');
      expect(dto.getOtherParticipant('u2')?.userId, 'u1');
    });
  });

  group('SendMessageRequestDto', () {
    test('validate enforces content for text messages', () {
      final req = SendMessageRequestDto.text('');
      expect(req.validate(), isNotNull);
    });

    test('validate enforces mediaUrl for image messages', () {
      final req = SendMessageRequestDto.image('');
      expect(req.validate(), isNotNull);
    });

    test('validate returns null for valid text message', () {
      final req = SendMessageRequestDto.text('Hello');
      expect(req.validate(), isNull);
    });
  });
}
