import 'package:flutter_test/flutter_test.dart';

import 'package:crushhour/data/models/message.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/features/chat/presentation/bloc/chat_event.dart';
import 'package:crushhour/features/chat/presentation/bloc/chat_state.dart';

Message _message(String id) => Message(
  id: id,
  matchId: 'match-1',
  fromUserId: 'user-a',
  toUserId: 'user-b',
  content: 'hello',
  type: MessageType.text,
  sentAt: DateTime.utc(2026, 1, 1),
  isRead: false,
  isDeletedForSender: false,
);

void main() {
  group('ChatEvent props/equality', () {
    test('ChatOpened includes all fields including optional photo URL', () {
      final event = ChatOpened(
        'match-1',
        'user-a',
        'user-b',
        otherUserPhotoUrl: 'https://cdn.example.com/photo.jpg',
      );

      expect(event.props, [
        'match-1',
        'user-a',
        'user-b',
        'https://cdn.example.com/photo.jpg',
      ]);
      expect(
        event,
        ChatOpened(
          'match-1',
          'user-a',
          'user-b',
          otherUserPhotoUrl: 'https://cdn.example.com/photo.jpg',
        ),
      );
    });

    test('ChatClosed carries match and current user IDs', () {
      final event = ChatClosed('match-1', 'user-a');
      expect(event.props, ['match-1', 'user-a']);
    });

    test('ChatMessageSent supports default and explicit types', () {
      final defaultType = ChatMessageSent(
        matchId: 'match-1',
        fromUserId: 'user-a',
        toUserId: 'user-b',
        content: 'hi',
      );
      final mediaType = ChatMessageSent(
        matchId: 'match-1',
        fromUserId: 'user-a',
        toUserId: 'user-b',
        content: 'image',
        type: MessageType.image,
      );

      expect(defaultType.type, MessageType.text);
      expect(mediaType.props, [
        'match-1',
        'user-a',
        'user-b',
        'image',
        MessageType.image,
      ]);
    });

    test('ChatMediaSendRequested stores media payload fields', () {
      final event = ChatMediaSendRequested(
        matchId: 'match-1',
        fromUserId: 'user-a',
        toUserId: 'user-b',
        filePath: '/tmp/file.jpg',
        type: MessageType.image,
      );
      expect(event.props, [
        'match-1',
        'user-a',
        'user-b',
        '/tmp/file.jpg',
        MessageType.image,
      ]);
    });

    test('message action request events expose identifiers', () {
      expect(ChatMessageUnsendRequested('match-1', 'msg-1').props, [
        'match-1',
        'msg-1',
      ]);
      expect(
        ChatMessageEditRequested(
          matchId: 'match-1',
          messageId: 'msg-1',
          newContent: 'edited',
        ).props,
        ['match-1', 'msg-1', 'edited'],
      );
      expect(
        ChatMessageDeleteForMeRequested('match-1', 'msg-1', 'user-a').props,
        ['match-1', 'msg-1', 'user-a'],
      );
      expect(
        ChatMessageRetryRequested(matchId: 'match-1', messageId: 'msg-1').props,
        ['match-1', 'msg-1'],
      );
      expect(ChatMessageDiscardRequested(messageId: 'msg-1').props, ['msg-1']);
    });

    test('ChatMessagesUpdated includes message list and subscription plan', () {
      final messages = [_message('1'), _message('2')];
      final event = ChatMessagesUpdated(messages, SubscriptionPlan.plus);

      expect(event.props.first, messages);
      expect(event.props.last, SubscriptionPlan.plus);
    });

    test('typing and presence events expose state', () {
      expect(
        ChatTypingStatusChanged(
          matchId: 'match-1',
          userId: 'user-a',
          isTyping: true,
        ).props,
        ['match-1', 'user-a', true],
      );
      final typingUsers = ChatTypingUsersUpdated(const {'user-a', 'user-b'});
      expect(typingUsers.typingUserIds, containsAll({'user-a', 'user-b'}));
      expect(typingUsers.props.single, containsAll({'user-a', 'user-b'}));
      expect(ChatPresenceUpdated(true).props, [true]);
    });

    test('reaction events expose all required identifiers', () {
      expect(
        ChatReactionAdded(
          matchId: 'match-1',
          messageId: 'msg-1',
          userId: 'user-a',
          emoji: '🔥',
        ).props,
        ['match-1', 'msg-1', 'user-a', '🔥'],
      );
      expect(
        ChatReactionRemoved(
          matchId: 'match-1',
          messageId: 'msg-1',
          userId: 'user-a',
        ).props,
        ['match-1', 'msg-1', 'user-a'],
      );
    });

    test('media toggle and status events expose values', () {
      expect(
        ChatMediaToggleRequested(
          matchId: 'match-1',
          requesterId: 'user-a',
          enabled: false,
        ).props,
        ['match-1', 'user-a', false],
      );
      expect(ChatMediaStatusUpdated(true).props, [true]);
    });

    test('misc chat flow events expose expected props', () {
      expect(ChatUnmatchRequested(matchId: 'match-1', userId: 'user-a').props, [
        'match-1',
        'user-a',
      ]);
      expect(ChatLoadMoreMessagesRequested('match-1').props, ['match-1']);
      final incoming = [_message('incoming-1')];
      expect(ChatNewMessagesReceived(incoming).props.single, incoming);
    });

    test('reset/sub-bloc/e2ee events support equality semantics', () {
      final aggregated = ChatState();
      expect(ChatResetRequested(), ChatResetRequested());
      expect(ChatSubBlocChanged(aggregated), ChatSubBlocChanged(aggregated));
      expect(ChatResetRequested().props, isEmpty);
      expect(ChatSubBlocChanged(aggregated).props, [aggregated]);
      expect(ChatE2eeToggled(true), ChatE2eeToggled(true));
      expect(ChatE2eeToggled(true).props, [true]);
    });
  });
}
