import 'package:crushhour/core/app_logger.dart';
import 'package:crushhour/data/models/profile_prompt.dart';

List<String> parseLegacyPromptAnswers(dynamic value) {
  if (value is! List) return const <String>[];
  return value
      .whereType<String>()
      .map((answer) => answer.trim())
      .where((answer) => answer.isNotEmpty)
      .toList();
}

List<String> promptAnswersFromProfilePrompts(List<ProfilePrompt> prompts) {
  return prompts
      .map((prompt) => prompt.answer.trim())
      .where((answer) => answer.isNotEmpty)
      .toList();
}

List<ProfilePrompt> profilePromptsFromLegacyAnswers(List<String> answers) {
  return answers
      .where((answer) => answer.trim().isNotEmpty)
      .map(
        (answer) => ProfilePrompt(questionId: 'unknown', answer: answer.trim()),
      )
      .toList();
}

List<ProfilePrompt> parseProfilePrompts(
  dynamic value, {
  List<String> legacyPromptAnswers = const <String>[],
}) {
  final parsed = <ProfilePrompt>[];
  if (value is List) {
    for (final entry in value) {
      if (entry is String) {
        final answer = entry.trim();
        if (answer.isNotEmpty) {
          parsed.add(ProfilePrompt(questionId: 'unknown', answer: answer));
        }
        continue;
      }
      if (entry is Map) {
        try {
          parsed.add(ProfilePrompt.fromJson(Map<String, dynamic>.from(entry)));
        } catch (e) {
          AppLogger.error(
            '[ProfilePromptMigration] Error parsing prompt',
            error: e,
          );
        }
      }
    }
  }
  if (parsed.isNotEmpty) return parsed;
  if (legacyPromptAnswers.isNotEmpty) {
    return profilePromptsFromLegacyAnswers(legacyPromptAnswers);
  }
  return const <ProfilePrompt>[];
}
