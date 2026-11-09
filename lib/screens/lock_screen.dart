import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import '../widgets/pressable_scale.dart';
import 'home_gallery_screen.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with SingleTickerProviderStateMixin {
  static const _correctPin = '1234';

  String _pin = '';
  bool _error = false;
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -14), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -14, end: 14), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 14, end: -10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: 0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onDigit(String digit) {
    if (_pin.length >= 4) return;
    HapticFeedback.selectionClick();
    setState(() {
      _error = false;
      _pin += digit;
    });
    if (_pin.length == 4) {
      Future.delayed(const Duration(milliseconds: 140), _validate);
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void _onFingerprint() {
    HapticFeedback.mediumImpact();
    setState(() {
      _pin = _correctPin;
      _error = false;
    });
    Future.delayed(const Duration(milliseconds: 180), _unlock);
  }

  void _validate() {
    if (!mounted) return;
    if (_pin == _correctPin) {
      _unlock();
      return;
    }
    HapticFeedback.heavyImpact();
    setState(() => _error = true);
    _shakeController.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() {
        _pin = '';
        _error = false;
      });
    });
  }

  void _unlock() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 550),
        pageBuilder: (_, __, ___) => const HomeGalleryScreen(),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 1.03, end: 1).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.85),
                  radius: 1.1,
                  colors: [
                    AppColors.primaryContainer.withValues(alpha: 0.12),
                    AppColors.surfaceContainerLowest,
                  ],
                  stops: const [0, 0.62],
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const _VaultMark(),
                          const SizedBox(height: 22),
                          Container(
                            width: 94,
                            height: 94,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primaryContainer
                                    .withValues(alpha: 0.35),
                                width: 1,
                              ),
                              color: AppColors.surfaceContainerLow
                                  .withValues(alpha: 0.7),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryContainer
                                      .withValues(alpha: 0.08),
                                  blurRadius: 40,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.lock,
                              size: 40,
                              color: AppColors.primaryContainer,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'الخزنة',
                            style: AppTextStyles.displayMobile(),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'أدخل رمز PIN للوصول إلى صورك',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium(
                              AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 26),
                          AnimatedBuilder(
                            animation: _shakeAnimation,
                            builder: (context, child) => Transform.translate(
                              offset: Offset(_shakeAnimation.value, 0),
                              child: child,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(4, (index) {
                                final filled = index < _pin.length;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  width: filled ? 16 : 14,
                                  height: filled ? 16 : 14,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: filled
                                        ? AppColors.primaryContainer
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: _error
                                          ? AppColors.error
                                          : filled
                                              ? AppColors.primaryContainer
                                              : AppColors.outlineVariant,
                                      width: 1.4,
                                    ),
                                    boxShadow: filled
                                        ? [
                                            BoxShadow(
                                              color: AppColors.primaryContainer
                                                  .withValues(alpha: 0.35),
                                              blurRadius: 12,
                                            ),
                                          ]
                                        : null,
                                  ),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(height: 12),
                          AnimatedOpacity(
                            opacity: _error ? 1 : 0,
                            duration: const Duration(milliseconds: 160),
                            child: Text(
                              'رمز غير صحيح، حاول مرة أخرى',
                              style: AppTextStyles.bodySmall(AppColors.error),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _Keypad(
                            onDigit: _onDigit,
                            onBackspace: _onBackspace,
                            onFingerprint: _onFingerprint,
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.verified_user,
                                size: 13,
                                color: AppColors.outline,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'محمي بتشفير AES-256',
                                style: AppTextStyles.labelMonoSmall(
                                  AppColors.outline,
                                ).copyWith(fontSize: 10),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'PIN تجريبي: 1234',
                            style: AppTextStyles.labelMonoSmall(
                              AppColors.outlineVariant,
                            ).copyWith(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _VaultMark extends StatelessWidget {
  const _VaultMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppColors.primaryContainer,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          'OBSIDIAN VAULT',
          style: AppTextStyles.labelMonoSmall(AppColors.onSurfaceVariant)
              .copyWith(letterSpacing: 3, fontSize: 10),
        ),
      ],
    );
  }
}

class _Keypad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onFingerprint;

  const _Keypad({
    required this.onDigit,
    required this.onBackspace,
    required this.onFingerprint,
  });

  @override
  Widget build(BuildContext context) {
    final keys = <Widget>[
      for (var i = 1; i <= 9; i++)
        _KeypadButton(label: '$i', onTap: () => onDigit('$i')),
      _KeypadButton(
        icon: Icons.fingerprint,
        gold: true,
        onTap: onFingerprint,
      ),
      _KeypadButton(label: '0', onTap: () => onDigit('0')),
      _KeypadButton(
        icon: Icons.backspace_outlined,
        muted: true,
        onTap: onBackspace,
      ),
    ];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 292),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 22,
        childAspectRatio: 1,
        children: keys,
      ),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool gold;
  final bool muted;

  const _KeypadButton({
    this.label,
    this.icon,
    required this.onTap,
    this.gold = false,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = gold
        ? AppColors.primaryContainer
        : muted
            ? AppColors.onSurfaceVariant
            : AppColors.onSurface;
    return PressableScale(
      onTap: onTap,
      pressedScale: 0.92,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: gold
              ? AppColors.primaryContainer.withValues(alpha: 0.08)
              : AppColors.surfaceContainerLow.withValues(alpha: 0.7),
          border: Border.all(
            color: gold
                ? AppColors.primaryContainer.withValues(alpha: 0.45)
                : AppColors.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        alignment: Alignment.center,
        child: icon != null
            ? Icon(icon, size: 26, color: color)
            : Text(
                label!,
                style: AppTextStyles.headlineMedium(color).copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
      ),
    );
  }
}
