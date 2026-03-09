import 'package:crushhour/features/calls/presentation/screens/call_screen.dart'
    as call_screen;
import 'package:crushhour/features/chat/presentation/screens/chat_screen.dart'
    as chat_screen;
import 'package:crushhour/features/profile/presentation/screens/other_user_profile_screen.dart'
    as profile_screen;
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'security report reason mappings keep stable codes and localized labels',
    (tester) async {
      AppLocalizations? l10n;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en', 'XA'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      await tester.pumpAndSettle();
      final localizations = l10n;
      expect(localizations, isNotNull);

      expect(
        chat_screen.chatReportReasonCode(
          chat_screen.ChatReportReasonOption.spamOrScams,
        ),
        'Spam or scams',
      );
      expect(
        chat_screen.chatReportReasonCode(
          chat_screen.ChatReportReasonOption.harassmentOrHate,
        ),
        'Harassment or hate',
      );
      expect(
        chat_screen.chatReportReasonCode(
          chat_screen.ChatReportReasonOption.inappropriateContent,
        ),
        'Inappropriate content',
      );
      expect(
        chat_screen.chatReportReasonCode(
          chat_screen.ChatReportReasonOption.fakeProfile,
        ),
        'Fake profile',
      );
      expect(
        chat_screen.chatReportReasonCode(
          chat_screen.ChatReportReasonOption.other,
        ),
        'Other',
      );

      expect(
        call_screen.callReportReasonCode(
          call_screen.CallReportReasonOption.spamOrScams,
        ),
        'Spam or scams',
      );
      expect(
        call_screen.callReportReasonCode(
          call_screen.CallReportReasonOption.harassmentOrHate,
        ),
        'Harassment or hate',
      );
      expect(
        call_screen.callReportReasonCode(
          call_screen.CallReportReasonOption.inappropriateContent,
        ),
        'Inappropriate content',
      );
      expect(
        call_screen.callReportReasonCode(
          call_screen.CallReportReasonOption.fakeProfile,
        ),
        'Fake profile',
      );
      expect(
        call_screen.callReportReasonCode(
          call_screen.CallReportReasonOption.other,
        ),
        'Other',
      );

      expect(
        profile_screen.profileReportReasonCode(
          profile_screen.ProfileReportReasonOption.inappropriatePhotos,
        ),
        'Inappropriate photos',
      );
      expect(
        profile_screen.profileReportReasonCode(
          profile_screen.ProfileReportReasonOption.fakeProfile,
        ),
        'Fake profile',
      );
      expect(
        profile_screen.profileReportReasonCode(
          profile_screen.ProfileReportReasonOption.harassment,
        ),
        'Harassment',
      );
      expect(
        profile_screen.profileReportReasonCode(
          profile_screen.ProfileReportReasonOption.scamOrSpam,
        ),
        'Scam or spam',
      );
      expect(
        profile_screen.profileReportReasonCode(
          profile_screen.ProfileReportReasonOption.underageUser,
        ),
        'Underage user',
      );
      expect(
        profile_screen.profileReportReasonCode(
          profile_screen.ProfileReportReasonOption.other,
        ),
        'Other',
      );

      expect(
        chat_screen.chatReportReasonLabelFor(
          localizations!,
          chat_screen.ChatReportReasonOption.spamOrScams,
        ),
        'Spam or scams xxxx',
      );
      expect(
        call_screen.callReportReasonLabelFor(
          localizations,
          call_screen.CallReportReasonOption.harassmentOrHate,
        ),
        'Harassment or hate xxxx',
      );
      expect(
        profile_screen.profileReportReasonLabelFor(
          localizations,
          profile_screen.ProfileReportReasonOption.inappropriatePhotos,
        ),
        'Inappropriate photos xxxx',
      );
      expect(
        profile_screen.profileReportReasonLabelFor(
          localizations,
          profile_screen.ProfileReportReasonOption.scamOrSpam,
        ),
        'Scam or spam xxxx',
      );
      expect(
        profile_screen.profileReportReasonLabelFor(
          localizations,
          profile_screen.ProfileReportReasonOption.underageUser,
        ),
        'Underage user xxxx',
      );
    },
  );
}
