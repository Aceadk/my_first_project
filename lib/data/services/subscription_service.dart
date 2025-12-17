import 'package:cloud_functions/cloud_functions.dart';
import '../models/subscription.dart';

class SubscriptionService {
  SubscriptionService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<SubscriptionStatus> syncSubscriptionStatus() async {
    final callable =
        _functions.httpsCallable('syncSubscriptionStatus');
    final result = await callable.call(<String, dynamic>{});
    final data = Map<String, dynamic>.from(result.data as Map);
    final planStr = (data['plan'] as String? ?? 'free').toLowerCase();
    final status = data['status'] as String?;
    final cancelAtPeriodEnd = data['cancelAtPeriodEnd'] == true;
    final periodEndSeconds = data['currentPeriodEnd'] as int?;
    DateTime? nextRenewal;
    if (periodEndSeconds != null) {
      nextRenewal =
          DateTime.fromMillisecondsSinceEpoch(periodEndSeconds * 1000);
    }
    final plan =
        planStr == 'plus' ? SubscriptionPlan.plus : SubscriptionPlan.free;
    return SubscriptionStatus(
      plan: plan,
      status: status,
      nextRenewal: nextRenewal,
      cancelAtPeriodEnd: cancelAtPeriodEnd,
    );
  }
}
