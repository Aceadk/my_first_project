import 'package:cloud_functions/cloud_functions.dart';

class CheckoutService {
  final FirebaseFunctions _functions;

  CheckoutService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  Future<String> createPlusCheckoutSession({
    required String priceId,
    required String successUrl,
    required String cancelUrl,
  }) async {
    final callable = _functions.httpsCallable('createCheckoutSession');
    final result = await callable.call(<String, dynamic>{
      'priceId': priceId,
      'successUrl': successUrl,
      'cancelUrl': cancelUrl,
    });

    final data = result.data as Map<dynamic, dynamic>;
    final url = data['url'] as String?;
    if (url == null) {
      throw Exception('No checkout URL returned.');
    }
    return url;
  }
}
