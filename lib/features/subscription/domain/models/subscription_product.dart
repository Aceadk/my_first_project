import 'package:crushhour/shared/dto/subscription.dart';
import 'package:equatable/equatable.dart';

class SubscriptionProduct extends Equatable {
  const SubscriptionProduct({
    required this.productId,
    required this.tier,
    required this.period,
    required this.title,
    required this.description,
    required this.priceLabel,
    required this.price,
    required this.currencyCode,
    required this.currencySymbol,
  });

  final String productId;
  final SubscriptionTier tier;
  final BillingPeriod period;
  final String title;
  final String description;
  final String priceLabel;
  final double price;
  final String currencyCode;
  final String currencySymbol;

  @override
  List<Object?> get props => [
    productId,
    tier,
    period,
    title,
    description,
    priceLabel,
    price,
    currencyCode,
    currencySymbol,
  ];
}
