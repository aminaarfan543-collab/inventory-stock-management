import 'package:flutter/material.dart';
import '../theme/colors.dart';

class Toast {
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    final bg = isError
        ? AppColors.danger
        : isSuccess
            ? AppColors.success
            : AppColors.info;

    // DEBUG: Console mein error print karein
    if (isError) {
      debugPrint('====================================');
      debugPrint('ERROR: $message');
      debugPrint('====================================');
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: bg,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
  }
}
