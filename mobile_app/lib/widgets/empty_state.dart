import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'primary_button.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final String? illustrationPath;

  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onActionPressed,
    this.illustrationPath,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (illustrationPath != null) ...[
              Image.asset(illustrationPath!, height: 150),
              const SizedBox(height: AppSpacing.l),
            ] else ...[
              const Icon(
                Icons.folder_open_outlined,
                size: 80,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: AppSpacing.l),
            ],
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onActionPressed != null) ...[
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: actionLabel!,
                onPressed: onActionPressed!,
                fullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
