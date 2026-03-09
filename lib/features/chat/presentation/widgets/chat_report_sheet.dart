import 'package:crushhour/core/extensions/localization_extension.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

enum ChatReportReasonOption {
  spamOrScams,
  harassmentOrHate,
  inappropriateContent,
  fakeProfile,
  other,
}

String chatReportReasonCode(ChatReportReasonOption reason) {
  switch (reason) {
    case ChatReportReasonOption.spamOrScams:
      return 'Spam or scams';
    case ChatReportReasonOption.harassmentOrHate:
      return 'Harassment or hate';
    case ChatReportReasonOption.inappropriateContent:
      return 'Inappropriate content';
    case ChatReportReasonOption.fakeProfile:
      return 'Fake profile';
    case ChatReportReasonOption.other:
      return 'Other';
  }
}

String chatReportReasonLabelFor(
  AppLocalizations l10n,
  ChatReportReasonOption reason,
) {
  switch (reason) {
    case ChatReportReasonOption.spamOrScams:
      return l10n.chatReportReasonSpamScams;
    case ChatReportReasonOption.harassmentOrHate:
      return l10n.chatReportReasonHarassmentHate;
    case ChatReportReasonOption.inappropriateContent:
      return l10n.chatReportReasonInappropriateContent;
    case ChatReportReasonOption.fakeProfile:
      return l10n.chatReportReasonFakeProfile;
    case ChatReportReasonOption.other:
      return l10n.chatReportReasonOther;
  }
}

class ChatReportSheetContent extends StatelessWidget {
  const ChatReportSheetContent({
    super.key,
    required this.matchId,
    required this.onReasonSelected,
    required this.onViewGuidelines,
  });

  final String matchId;
  final Future<void> Function(ChatReportReasonOption reason) onReasonSelected;
  final VoidCallback onViewGuidelines;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const reasons = ChatReportReasonOption.values;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          title: Text(
            l10n.reportUser,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${l10n.reportsAreAnonymousAndReviewed} ${l10n.chatReportLastMatch(matchId)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        ...reasons.map(
          (reason) => ListTile(
            title: Text(chatReportReasonLabelFor(l10n, reason)),
            onTap: () => onReasonSelected(reason),
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: onViewGuidelines,
            icon: const Icon(Icons.shield_outlined),
            label: Text(l10n.viewCommunityGuidelines),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}
