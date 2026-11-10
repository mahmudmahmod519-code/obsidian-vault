import 'package:flutter/material.dart';

import '../theme.dart';

void showAppToast(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      duration: const Duration(milliseconds: 1800),
      backgroundColor: AppColors.surfaceContainerHigh.withValues(alpha: 0.96),
      elevation: 8,
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 96),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: StadiumBorder(
        side: BorderSide(
          color: AppColors.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      content: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              size: 16,
              color: AppColors.primaryContainer,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelMonoSmall(
                  AppColors.primary,
                ).copyWith(fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
