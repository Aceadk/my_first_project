import 'package:crushhour/data/models/message.dart';
import 'package:crushhour/features/chat/presentation/bloc/chat_state.dart';
import 'package:flutter_test/flutter_test.dart';

Message buildMessage({required String id, required DateTime sentAt}) {
  return Message(
    id: id,
    matchId: 'match-1',
    fromUserId: 'user-a',
    toUserId: 'user-b',
    content: 'message $id',
    type: MessageType.text,
    sentAt: sentAt,
    isRead: false,
    isDeletedForSender: false,
  );
}

void main() {
  group('ChatState collection semantics', () {
    test('takes defensive immutable snapshots of collection fields', () {
      final m1 = buildMessage(id: '1', sentAt: DateTime.utc(2026, 1, 1));
      final m2 = buildMessage(id: '2', sentAt: DateTime.utc(2026, 1, 2));
      final messages = <Message>[m1];
      final failedMessages = <String, Message>{'tmp-1': m2};
      final typingUserIds = <String>{'user-a'};

      final state = ChatState(
        messages: messages,
        failedMessages: failedMessages,
        typingUserIds: typingUserIds,
      );

      messages.add(m2);
      failedMessages['tmp-2'] = m1;
      typingUserIds.add('user-b');

      expect(state.messages, [m1]);
      expect(state.failedMessages, {'tmp-1': m2});
      expect(state.typingUserIds, {'user-a'});
      expect(() => state.messages.add(m2), throwsUnsupportedError);
      expect(() => state.failedMessages['tmp-3'] = m1, throwsUnsupportedError);
      expect(() => state.typingUserIds.add('user-z'), throwsUnsupportedError);
    });

    test('equality remains stable for value-equivalent set/map fields', () {
      final m1 = buildMessage(id: '1', sentAt: DateTime.utc(2026, 1, 1));
      final m2 = buildMessage(id: '2', sentAt: DateTime.utc(2026, 1, 2));

      final a = ChatState(
        messages: [m1, m2],
        failedMessages: {'tmp-1': m1, 'tmp-2': m2},
        typingUserIds: const {'user-a', 'user-b'},
      );
      final b = ChatState(
        messages: [m1, m2],
        failedMessages: {'tmp-2': m2, 'tmp-1': m1},
        typingUserIds: const {'user-b', 'user-a'},
      );

      expect(a, b);
    });
  });
}
