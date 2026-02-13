import 'package:crushhour/core/accessibility/semantics_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SemanticsHelper', () {
    test('label and group build semantics widgets with properties', () {
      final labeled = SemanticsHelper.label(
        child: const Text('Hello'),
        label: 'Greeting',
        hint: 'Tap to continue',
        button: true,
        header: true,
        link: true,
      );
      expect(labeled, isA<Semantics>());
      final semantics = labeled as Semantics;
      expect(semantics.properties.label, 'Greeting');
      expect(semantics.properties.hint, 'Tap to continue');
      expect(semantics.properties.button, isTrue);
      expect(semantics.properties.header, isTrue);
      expect(semantics.properties.link, isTrue);

      final grouped = SemanticsHelper.group(
        child: const Text('Group'),
        label: 'Profile section',
        explicitChildNodes: true,
      );
      expect(grouped, isA<Semantics>());
      final groupSemantics = grouped as Semantics;
      expect(groupSemantics.properties.label, 'Profile section');
    });

    test('profileCardLabel includes optional pieces', () {
      final withAll = SemanticsHelper.profileCardLabel(
        name: 'Alex',
        age: 28,
        location: 'Austin',
        bio: 'Loves hiking',
        isVerified: true,
      );
      expect(withAll, contains('Alex, 28 years old'));
      expect(withAll, contains('verified profile'));
      expect(withAll, contains('from Austin'));
      expect(withAll, contains('Bio: Loves hiking'));

      final minimal = SemanticsHelper.profileCardLabel(name: 'Sam', age: 30);
      expect(minimal, 'Sam, 30 years old');
    });

    test('messageLabel formats sender and read status', () {
      final fromMeUnread = SemanticsHelper.messageLabel(
        senderName: 'Taylor',
        content: 'Hey there',
        sentAt: DateTime.now().subtract(const Duration(minutes: 5)),
        isFromMe: true,
      );
      expect(fromMeUnread, startsWith('You said: Hey there'));
      expect(fromMeUnread, contains(', sent'));

      final fromMeRead = SemanticsHelper.messageLabel(
        senderName: 'Taylor',
        content: 'Seen?',
        sentAt: DateTime.now().subtract(const Duration(hours: 2)),
        isFromMe: true,
        isRead: true,
      );
      expect(fromMeRead, contains(', read'));

      final fromOther = SemanticsHelper.messageLabel(
        senderName: 'Taylor',
        content: 'Hi',
        sentAt: DateTime.now().subtract(const Duration(days: 8)),
        isFromMe: false,
      );
      expect(fromOther, startsWith('Taylor said: Hi'));
      expect(fromOther, contains('/'));
    });

    test('matchTileLabel and navItemLabel include dynamic details', () {
      final matchLabel = SemanticsHelper.matchTileLabel(
        name: 'Jordan',
        lastMessage: 'See you soon',
        lastMessageTime: DateTime.now().subtract(const Duration(minutes: 30)),
        unreadCount: 2,
        isOnline: true,
      );
      expect(matchLabel, startsWith('Chat with Jordan'));
      expect(matchLabel, contains('online now'));
      expect(matchLabel, contains('2 unread messages'));
      expect(matchLabel, contains('Last message: See you soon'));

      final nav = SemanticsHelper.navItemLabel(
        title: 'Messages',
        badgeCount: 3,
        isSelected: true,
      );
      expect(nav, 'Messages, 3 new, selected');
    });

    test('swipe action labels are mapped for all actions', () {
      expect(
        SemanticsHelper.swipeActionLabel(SwipeAction.like),
        'Like this profile',
      );
      expect(
        SemanticsHelper.swipeActionLabel(SwipeAction.nope),
        'Pass on this profile',
      );
      expect(
        SemanticsHelper.swipeActionLabel(SwipeAction.superLike),
        'Super like this profile',
      );
      expect(
        SemanticsHelper.swipeActionLabel(SwipeAction.rewind),
        'Undo last swipe',
      );
    });
  });

  group('SemanticWidgetExtension', () {
    test('withSemantics and excludeFromSemantics wrap widgets correctly', () {
      final wrapped = const SizedBox().withSemantics(
        label: 'Avatar',
        hint: 'Profile image',
        image: true,
      );
      expect(wrapped, isA<Semantics>());
      final semantics = wrapped as Semantics;
      expect(semantics.properties.label, 'Avatar');
      expect(semantics.properties.hint, 'Profile image');
      expect(semantics.properties.image, isTrue);

      final excluded = const SizedBox().excludeFromSemantics();
      expect(excluded, isA<ExcludeSemantics>());
    });
  });
}
