import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'primary_button.dart';

class ConfirmDialog {
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(title),
        content: Text(message),
        actions: [
          PrimaryButton(
            label: cancelLabel,
            outline: true,
            color: AppColors.textSecondary,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          PrimaryButton(
            label: confirmLabel,
            color: destructive ? AppColors.danger : AppColors.primary,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
