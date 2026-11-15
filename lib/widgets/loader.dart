import 'package:flutter/material.dart';
import '../theme/colors.dart';

class Loader extends StatelessWidget {
  final String? message;
  final bool fullscreen;
  final double size;

  const Loader({
    super.key,
    this.message,
    this.fullscreen = false,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: size,
          width: size,
          child: const CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            message!,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ],
    );

    if (fullscreen) {
      return Container(
        color: AppColors.background,
        child: Center(child: content),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(child: content),
    );
  }
}
