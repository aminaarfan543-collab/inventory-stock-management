import 'package:flutter/material.dart';
import '../theme/colors.dart';

class InputField extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool obscureText;
  final bool readOnly;
  final int maxLines;
  final TextInputType keyboardType;
  final Widget? suffix;
  final Widget? prefix;
  final TextCapitalization capitalization;
  final int? maxLength;

  const InputField({
    super.key,
    this.label,
    this.hint,
    this.errorText,
    this.helperText,
    this.controller,
    this.validator,
    this.onChanged,
    this.obscureText = false,
    this.readOnly = false,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.suffix,
    this.prefix,
    this.capitalization = TextCapitalization.none,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
          ],
          TextFormField(
            controller: controller,
            validator: validator,
            onChanged: onChanged,
            obscureText: obscureText,
            readOnly: readOnly,
            maxLines: maxLines,
            maxLength: maxLength,
            keyboardType: keyboardType,
            textCapitalization: capitalization,
            style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              helperText: helperText,
              errorText: errorText,
              suffixIcon: suffix,
              prefixIcon: prefix,
              counterText: '',
            ),
          ),
        ],
      ),
    );
  }
}
