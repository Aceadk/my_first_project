import 'package:crushhour/design_system/tokens/breakpoints.dart';
import 'package:flutter/widgets.dart';

const Key authUtilityContentConstraintKey = ValueKey<String>(
  'auth_utility_content_constraint',
);

double authUtilityMaxWidthFor(double screenWidth) {
  return DsBreakpoints.responsiveValue<double>(
    screenWidth,
    mobile: double.infinity,
    tablet: 600,
    desktop: 680,
  );
}
