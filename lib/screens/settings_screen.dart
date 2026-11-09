import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

TextStyle _headline({
  double size = 18,
  FontWeight weight = FontWeight.w600,
  Color color = AppColors.onSurface,
  double? letterSpacing,
  double? height,
}) {
  return TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontFamilyFallback: const ['NotoSansArabic'],
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
    height: height ?? 24 / 18,
  );
}

TextStyle _body({
  double size = 14,
  FontWeight weight = FontWeight.w400,
  Color color = AppColors.onSurface,
  double? height,
  double? letterSpacing,
}) {
  return TextStyle(
    fontFamily: 'NotoSans',
    fontFamilyFallback: const ['NotoSansArabic'],
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}

TextStyle _mono({
  double size = 11,
  FontWeight weight = FontWeight.w400,
  Color color = AppColors.onSurfaceVariant,
  double? letterSpacing,
  double? height,
}) {
  return TextStyle(
    fontFamily: 'SpaceMono',
    fontFamilyFallback: const ['NotoSansArabic'],
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing ?? 0.08 * size,
    height: height,
  );
}

Widget _iconBox(
  IconData icon, {
  double size = 40,
  double radius = 8,
  double iconSize = 20,
  Color? iconColor,
}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(radius),
    ),
    child: Icon(
      icon,
      size: iconSize,
      color: iconColor ?? AppColors.onSurface,
    ),
  );
}

Widget _rtlIcon(
  BuildContext context,
  IconData icon, {
  double size = 20,
  Color color = AppColors.outline,
}) {
  final isRtl = Directionality.of(context) == TextDirection.rtl;
  return Transform.scale(
    scaleX: isRtl ? -1 : 1,
    child: Icon(
      icon,
      size: size,
      color: color,
      textDirection: TextDirection.ltr,
    ),
  );
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pinLock = true;
  bool _aesEncryption = true;
  bool _showCounts = true;
  bool _compactGrid = false;

  static const _about = _InfoContent(
    title: 'عن Obsidian Vault',
    description:
        'تطبيق Obsidian Vault هو الحل الأمثل لتخزين وإخفاء الذكريات والوثائق الحساسة بأمان معزول تماماً عن الإنترنت، مع معالجة وتشفير محلي صارم 100%. الإصدار 2.4.0.',
    icon: Icons.info_outline,
  );

  static const _privacy = _InfoContent(
    title: 'سياسة الخصوصية الصارمة',
    description:
        'نحن لا نجمع، ولا نخزن، ولا ننقل أي صورة أو بيان يخصك إلى خوادم خارجية. مفاتيح التشفير مولدة محلياً في الرقاقة الآمنة (Secure Enclave) بجهازك فقط.',
    icon: Icons.policy,
  );

  void _showInfo(_InfoContent content) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'إغلاق',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        final isWide = MediaQuery.sizeOf(dialogContext).width >= 640;
        return Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: FadeTransition(
                  opacity: animation,
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment:
                    isWide ? Alignment.center : Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: FadeTransition(
                    opacity: curved,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.95, end: 1).animate(curved),
                      child: _InfoDialog(content: content),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) =>
          child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.surfaceContainerLowest,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.surfaceContainerLowest,
        body: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.only(
                  top: topInset + 64,
                  bottom: bottomInset + 48,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStatusCard(),
                    _buildSecuritySection(),
                    _buildDisplaySection(),
                    _buildInfoSection(),
                    _buildStorageCard(),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
            _buildHeader(topInset),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double topInset) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: EdgeInsets.only(top: topInset),
              color: AppColors.surfaceContainerLowest.withValues(alpha: 0.8),
              child: SizedBox(
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 44,
                            height: 44,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              iconSize: 24,
                              onPressed: () => Navigator.maybePop(context),
                              icon: _rtlIcon(
                                context,
                                Icons.arrow_back,
                                size: 24,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 18,
                              color: AppColors.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IgnorePointer(
                      child: Text(
                        'الإعدادات',
                        style: _headline(letterSpacing: -0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  _iconBox(
                    Icons.verified_user,
                    size: 48,
                    radius: 12,
                    iconSize: 26,
                    iconColor: AppColors.primaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                'الخزنة محمية بالكامل',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _headline(),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ENCRYPTION ENGINE ACTIVE',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _mono(
                            color: AppColors.onSurfaceVariant,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'AES-256',
                style: _mono(
                  color: AppColors.primaryContainer,
                  weight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySection() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHeader('الأمان والحماية', 'SEC_POLICY // 01'),
          _card(
            children: [
              _SettingsToggleRow(
                icon: Icons.lock,
                title: 'قفل التطبيق بكلمة سر',
                subtitle: 'طلب رمز PIN أو البصمة عند فتح التطبيق والخزنة',
                value: _pinLock,
                onChanged: (v) => setState(() => _pinLock = v),
              ),
              _divider(),
              _SettingsToggleRow(
                icon: Icons.enhanced_encryption,
                title: 'تشفير البيانات محلياً',
                subtitle: 'تشفير الصور والوثائق بنظام AES-256 GCM',
                value: _aesEncryption,
                onChanged: (v) => setState(() => _aesEncryption = v),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDisplaySection() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHeader('المظهر والعرض', 'DISPLAY // 02'),
          _card(
            children: [
              Opacity(
                opacity: 0.9,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      _iconBox(Icons.dark_mode),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'الوضع الليلي',
                                  style: _body(
                                    size: 16,
                                    weight: FontWeight.w500,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'دائماً',
                                    style: _body(
                                      size: 11,
                                      weight: FontWeight.w500,
                                      color: AppColors.primaryContainer,
                                      height: 1.33,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'مفعّل دائماً لشاشات OLED الداكنة',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _body(
                                size: 12,
                                color: AppColors.onSurfaceVariant,
                                height: 1.33,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const _VaultToggle(value: true, enabled: false),
                    ],
                  ),
                ),
              ),
              _divider(),
              _SettingsToggleRow(
                icon: Icons.photo_library,
                title: 'عرض عدد الصور',
                subtitle: 'إظهار إجمالي العناصر والوسائط داخل الألبومات',
                value: _showCounts,
                onChanged: (v) => setState(() => _showCounts = v),
              ),
              _divider(),
              _SettingsToggleRow(
                icon: Icons.grid_view,
                title: 'عرض شبكي مضغوط',
                subtitle: 'تقليل المسافات بين الصور لأقصى استعراض',
                value: _compactGrid,
                onChanged: (v) => setState(() => _compactGrid = v),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHeader('معلومات التطبيق والدعم', 'SYS // 03'),
          _card(
            children: [
              _SettingsNavRow(
                icon: Icons.info_outline,
                title: 'عن التطبيق',
                subtitle: 'الإصدار 2.4.0 • Obsidian Vault Gallery',
                onTap: () => _showInfo(_about),
              ),
              _divider(),
              _SettingsNavRow(
                icon: Icons.policy,
                title: 'سياسة الخصوصية',
                subtitle: 'بياناتك مشفرة ومحفوظة على جهازك فقط',
                onTap: () => _showInfo(_privacy),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStorageCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 16, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.storage,
                size: 18,
                color: AppColors.primaryContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'مساحة التخزين المشفرة',
                  style: _body(
                    size: 12,
                    weight: FontWeight.w500,
                    height: 1.33,
                  ),
                ),
              ),
              Text(
                '14.8 GB / 64 GB',
                style: _mono(
                  weight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 6,
              color: AppColors.surfaceContainerHighest,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: FractionallySizedBox(
                  widthFactor: 0.23,
                  heightFactor: 1,
                  child: Container(color: AppColors.primaryContainer),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '1,420 صورة مشفرة',
                style: _mono(color: AppColors.onSurfaceVariant),
              ),
              Text(
                '49.2 GB متبقية',
                style: _mono(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 24, 12, 0),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: const Icon(
              Icons.fingerprint,
              size: 18,
              color: AppColors.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'OBSIDIAN VAULT • v2.4.0 (BUILD 412)',
            textAlign: TextAlign.center,
            style: _mono(
              color: AppColors.onSurfaceVariant,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'جميع الحقوق محفوظة • حماية وتشفير عالي الأمان',
            textAlign: TextAlign.center,
            style: _body(
              size: 12,
              color: AppColors.outline,
              height: 1.33,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, String code) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: _headline(letterSpacing: 0.3)),
          const SizedBox(width: 8),
          Text(code, style: _mono(color: AppColors.outline)),
        ],
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: AppColors.surfaceContainerHighest,
    );
  }
}

class _SettingsToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SettingsToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Row(
        children: [
          _iconBox(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _body(
                    size: 16,
                    weight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _body(
                    size: 12,
                    color: AppColors.onSurfaceVariant,
                    height: 1.33,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _VaultToggle(value: value, onChanged: onChanged),
        ],
      ),
    );

    return InkWell(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      highlightColor: AppColors.surfaceContainerHighest,
      child: row,
    );
  }
}

class _SettingsNavRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsNavRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      highlightColor: AppColors.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Row(
          children: [
            _iconBox(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _body(
                      size: 16,
                      weight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _body(
                      size: 12,
                      color: AppColors.onSurfaceVariant,
                      height: 1.33,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _rtlIcon(context, Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _VaultToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  const _VaultToggle({
    required this.value,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final track = !enabled
        ? AppColors.primaryContainer.withValues(alpha: 0.6)
        : value
            ? AppColors.primaryContainer
            : AppColors.surfaceContainerHighest;
    final knob = !enabled
        ? AppColors.onPrimary.withValues(alpha: 0.9)
        : value
            ? AppColors.onPrimary
            : AppColors.secondary;

    return Semantics(
      toggled: value,
      enabled: enabled,
      child: GestureDetector(
        onTap: enabled && onChanged != null ? () => onChanged!(!value) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: 48,
          height: 28,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: track,
            borderRadius: BorderRadius.circular(999),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: value
                ? (isRtl ? Alignment.centerLeft : Alignment.centerRight)
                : (isRtl ? Alignment.centerRight : Alignment.centerLeft),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: knob,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoContent {
  final String title;
  final String description;
  final IconData icon;

  const _InfoContent({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class _InfoDialog extends StatelessWidget {
  final _InfoContent content;

  const _InfoDialog({required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 384),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _iconBox(
                content.icon,
                size: 32,
                radius: 8,
                iconSize: 20,
                iconColor: AppColors.primaryContainer,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(content.title, style: _headline())),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content.description,
            style: _body(
              size: 14,
              color: AppColors.onSurfaceVariant,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          _ScaleTap(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('تم', style: _headline(color: AppColors.onPrimary)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScaleTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _ScaleTap({required this.child, this.onTap});

  @override
  State<_ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<_ScaleTap> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }
}
