import 'package:flutter/material.dart';

import '../theme.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String badge;
  final VoidCallback? onSearch;
  final VoidCallback? onMore;
  final Widget? leading;
  final bool showAvatar;

  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.badge = 'مؤمّن',
    this.onSearch,
    this.onMore,
    this.leading,
    this.showAvatar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          if (leading != null)
            leading!
          else if (showAvatar)
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryContainer.withValues(alpha: 0.15),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.person,
                size: 22,
                color: AppColors.onPrimary,
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      badge,
                      style: AppTextStyles.labelMonoSmall(
                        AppColors.onSurfaceVariant,
                      ).copyWith(fontSize: 10, letterSpacing: 1.2),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headlineMedium(),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall(AppColors.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          if (onSearch != null) ...[
            const SizedBox(width: 6),
            _HeaderAction(icon: Icons.search, onTap: onSearch!),
          ],
          if (onMore != null) ...[
            const SizedBox(width: 6),
            _HeaderAction(icon: Icons.more_horiz, onTap: onMore!),
          ],
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow.withValues(alpha: 0.75),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: AppColors.onSurface),
      ),
    );
  }
}

class HeaderBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const HeaderBackButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow.withValues(alpha: 0.8),
          shape: BoxShape.circle,
        ),
        child: Transform.scale(
          scaleX: Directionality.of(context) == TextDirection.rtl ? -1 : 1,
          child: const Icon(
            Icons.arrow_back,
            size: 20,
            color: AppColors.onSurface,
          ),
        ),
      ),
    );
  }
}
