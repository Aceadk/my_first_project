import 'package:flutter/material.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/utils/accessibility.dart';

void showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

void showSuccessSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        // success/mint is a light token: the default white snackbar text only
        // reaches 2.16:1 on it, so use an accessible dark foreground (9.72:1).
        content: Text(
          message,
          style: TextStyle(
            color: DsAccessibility.accessibleTextColor(DsColors.success),
          ),
        ),
        backgroundColor: DsColors.success,
      ),
    );
}
