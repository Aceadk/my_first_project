import 'package:crushhour/data/models/chat_settings.dart';
import 'package:crushhour/features/chat/presentation/bloc/match_chat_settings_cubit.dart';
import 'package:crushhour/features/chat/presentation/widgets/chat_match_settings_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders non-premium retention controls', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider(
            create: (_) => MatchChatSettingsCubit(
              matchId: 'match-1',
              initialSettings: const ChatSettings(),
              isPremium: false,
            ),
            child: const ChatMatchSettingsSheet(otherName: 'Alex'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Chat Settings'), findsOneWidget);
    expect(find.text('Conversation with Alex'), findsOneWidget);
    expect(find.text('Currently: 1 hour'), findsOneWidget);
    expect(find.text('Extended retention (24h)'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
  });

  testWidgets('renders premium retention badge without toggle', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider(
            create: (_) => MatchChatSettingsCubit(
              matchId: 'match-2',
              initialSettings: const ChatSettings(),
              isPremium: true,
            ),
            child: const ChatMatchSettingsSheet(otherName: 'Jordan'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Currently: 7 days'), findsOneWidget);
    expect(find.text('Plus: 7 days retention'), findsOneWidget);
    expect(find.byType(Switch), findsNothing);
  });
}
