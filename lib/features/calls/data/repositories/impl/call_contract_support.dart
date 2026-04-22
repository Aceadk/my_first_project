import '../call_repository.dart';

String resolveOtherParticipantId(
  Map<String, dynamic> matchData,
  String currentUserId,
) {
  final rawParticipants =
      matchData['userIds'] ?? matchData['users'] ?? matchData['participants'];
  if (rawParticipants is! List) {
    throw StateError(
      'Match participants are missing from the backend payload.',
    );
  }

  final participantIds = rawParticipants
      .map((value) => value.toString().trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);

  if (!participantIds.contains(currentUserId)) {
    throw StateError('Current user is not a participant in this match.');
  }

  final otherParticipant = participantIds.firstWhere(
    (participantId) => participantId != currentUserId,
    orElse: () => '',
  );
  if (otherParticipant.isEmpty) {
    throw StateError('Could not resolve the remote participant for this call.');
  }

  return otherParticipant;
}

CallSession callSessionFromStartResponse(
  Map<String, dynamic> responseData, {
  required String matchId,
  required bool isVideoCall,
}) {
  final callId =
      responseData['call_id'] as String? ??
      responseData['callId'] as String? ??
      responseData['channel_name'] as String? ??
      responseData['channelName'] as String?;
  if (callId == null || callId.trim().isEmpty) {
    throw StateError('Call start response did not include a call identifier.');
  }

  final channelName =
      responseData['channel_name'] as String? ??
      responseData['channelName'] as String? ??
      callId;
  final localUid =
      responseData['local_uid'] as int? ??
      responseData['localUid'] as int? ??
      0;

  return CallSession(
    matchId: matchId,
    localUid: localUid,
    channelName: channelName,
    isVideoCall: isVideoCall,
  );
}
