import 'package:cloud_functions/cloud_functions.dart';

class PreMatchService {
  final FirebaseFunctions _functions;

  PreMatchService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  Future<void> sendPreMatchMessageRequest({
    required String targetUserId,
    required String content,
  }) async {
    final callable =
        _functions.httpsCallable('sendPreMatchMessageRequest');
    await callable.call(<String, dynamic>{
      'targetUserId': targetUserId,
      'content': content,
    });
  }
}
