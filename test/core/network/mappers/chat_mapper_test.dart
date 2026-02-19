import 'package:crushhour/core/network/dto/chat_dto.dart' as dto;
import 'package:crushhour/core/network/mappers/chat_mapper.dart';
import 'package:crushhour/data/models/message.dart' as domain;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatMapper', () {
    final now = DateTime.now();
    final messageDto = dto.MessageDto(
      id: 'msg-1',
      conversationId: 'conv-1',
      senderId: 'user-1',
      type: dto.MessageType.text,
      content: 'Hello World',
      createdAt: now,
      status: dto.MessageStatus.sent,
      reactions: [const dto.MessageReactionDto(userId: 'user-2', emoji: 'aaa')],
    );

    test('messageFromDto maps correctly', () {
      final message = ChatMapper.messageFromDto(messageDto, toUserId: 'user-2');

      expect(message.id, 'msg-1');
      expect(message.matchId, 'conv-1');
      expect(message.fromUserId, 'user-1');
      expect(message.toUserId, 'user-2');
      expect(message.content, 'Hello World');
      expect(message.type, domain.MessageType.text);
      expect(message.reactions['user-2'], 'aaa');
    });

    test('messageToDto maps correctly', () {
      final message = domain.Message(
        id: 'msg-1',
        matchId: 'conv-1',
        fromUserId: 'user-1',
        toUserId: 'user-2',
        content: 'Hello',
        type: domain.MessageType.text,
        sentAt: now,
        isRead: false,
        isDeletedForSender: false,
        isFlagged: false,
        reactions: const {},
      );

      final mappedDto = ChatMapper.messageToDto(message);

      expect(mappedDto.id, 'msg-1');
      expect(mappedDto.senderId, 'user-1');
      expect(mappedDto.content, 'Hello');
      expect(mappedDto.type, dto.MessageType.text);
    });

    test('messageToSendRequest creates correct DTO', () {
      final message = domain.Message(
        id: 'temp',
        matchId: 'c1',
        fromUserId: 'u1',
        toUserId: 'u2',
        content: 'Hi',
        type: domain.MessageType.text,
        sentAt: now,
        isRead: false,
        isDeletedForSender: false,
        isFlagged: false,
        reactions: const {},
      );

      final req = ChatMapper.messageToSendRequest(
        message,
        clientId: 'client-1',
      );

      expect(req.type, dto.MessageType.text);
      expect(req.content, 'Hi');
      expect(req.clientId, 'client-1');
    });

    test('image message mapping handles mediaUrl', () {
      const dtoMsg = dto.MessageDto(
        id: '1',
        conversationId: 'c',
        senderId: 's',
        type: dto.MessageType.image,
        mediaUrl: 'http://pic.com',
      );

      final msg = ChatMapper.messageFromDto(dtoMsg, toUserId: 'u');
      expect(msg.content, 'http://pic.com');
      expect(msg.type, domain.MessageType.image);
    });
  });
}
