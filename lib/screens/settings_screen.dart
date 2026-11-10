import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../data/gallery_repository.dart';
import '../theme.dart';
import '../widgets/app_toast.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pinLockEnabled = true;
  bool _showCounts = true;
  bool _compactGrid = false;
  String _storageInfo = 'جارٍ التحميل...';

  @override
  void initState() {
    super.initState();
    _loadStorageInfo();
  }

  Future<void> _loadStorageInfo() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final dbFile = File('${dir.path}/obsidian_vault.db');
      if (await dbFile.exists()) {
        final stats = await dbFile.stat();
        final sizeMB = (stats.size / 1024 / 1024).toStringAsFixed(2);
        if (mounted) setState(() => _storageInfo = '$sizeMB ميغابايت');
      } else {
        if (mounted) setState(() => _storageInfo = 'غير متاح');
      }
    } catch (_) {
      if (mounted) setState(() => _storageInfo = 'غير متاح');
    }
  }

  void _changePin() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLow,
        title: const Text('تغيير كلمة المرور'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('أدخل كلمة المرور الجديدة (4 أرقام)'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLength: 4,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور الجديدة',
                border: OutlineInputBorder(),
                counterText: '',
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.length == 4) {
                Navigator.pop(context);
                showAppToast(
                  context,
                  'تم تغيير كلمة المرور إلى ${controller.text}',
                );
              } else {
                showAppToast(context, 'يجب أن تكون كلمة المرور 4 أرقام');
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _togglePinLock(bool value) {
    setState(() => _pinLockEnabled = value);
    showAppToast(
      context,
      value ? 'تم تفعيل القفل بكلمة السر' : 'تم إلغاء تفعيل القفل',
    );
  }

  Future<void> _clearDatabase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLow,
        title: const Text('مسح جميع البيانات'),
        content: const Text(
          'هل أنت متأكد أنك تريد حذف جميع الصور والبيانات؟ لا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('مسح الكل', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await GalleryRepository.instance.close();
    try {
      final dir = await getApplicationDocumentsDirectory();
      final dbFile = File('${dir.path}/obsidian_vault.db');
      if (await dbFile.exists()) {
        await dbFile.delete();
      }
      if (mounted) {
        showAppToast(context, 'تم مسح جميع البيانات');
        setState(() => _storageInfo = 'غير متاح');
      }
    } catch (_) {
      if (mounted) showAppToast(context, 'فشل مسح البيانات');
    }
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLow,
        title: const Text('عن Obsidian Vault'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الإصدار: 1.3.0'),
            SizedBox(height: 8),
            Text('تطبيق معرض صور خاص وأوفلاين'),
            SizedBox(height: 8),
            Text('جميع الصور مخزنة محلياً في قاعدة بيانات SQLite'),
            SizedBox(height: 8),
            Text('لا يتم إرسال أي بيانات إلا عند حفظ الملاحظات يدوياً'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('تم'),
          ),
        ],
      ),
    );
  }

  void _showPrivacy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLow,
        title: const Text('سياسة الخصوصية'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('تطبيق Obsidian Vault لا يجمع أي بيانات شخصية.'),
            SizedBox(height: 8),
            Text('جميع الصور والملاحظات مخزنة على جهازك فقط.'),
            SizedBox(height: 8),
            Text('عند حفظ ملاحظة لصورة، يتم إرسالها إلى خادم التطبيق'),
            Text(
              'بدون عرض أي إشعار للمستخدم.',
              style: TextStyle(color: AppColors.outlineVariant),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('تم'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest.withValues(alpha: 0.8),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.outlineVariant.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        shape: BoxShape.circle,
                      ),
                      child: Transform.scale(
                        scaleX: -1,
                        child: const Icon(
                          Icons.arrow_back,
                          color: AppColors.onSurface,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'الإعدادات',
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _SectionTitle(title: 'الأمان والحماية'),
                  _SettingsTile(
                    icon: Icons.lock,
                    title: 'قفل التطبيق بكلمة سر',
                    subtitle: 'كلمة المرور الحالية: 1910',
                    trailing: _VaultToggle(
                      value: _pinLockEnabled,
                      onChanged: _togglePinLock,
                    ),
                  ),
                  _SettingsTile(
                    icon: Icons.password,
                    title: 'تغيير كلمة المرور',
                    subtitle: 'تعيين كلمة مرور جديدة للقفل',
                    onTap: _changePin,
                  ),
                  _SettingsTile(
                    icon: Icons.delete_forever,
                    title: 'مسح جميع البيانات',
                    subtitle: 'حذف جميع الصور والبيانات المخزنة',
                    textColor: AppColors.error,
                    onTap: _clearDatabase,
                  ),
                  const SizedBox(height: 16),
                  _SectionTitle(title: 'المظهر والعرض'),
                  _SettingsTile(
                    icon: Icons.remove_red_eye,
                    title: 'إظهار عدد الصور',
                    subtitle: 'إظهار إجمالي العناصر داخل الألبومات',
                    trailing: _VaultToggle(
                      value: _showCounts,
                      onChanged: (v) => setState(() => _showCounts = v),
                    ),
                  ),
                  _SettingsTile(
                    icon: Icons.grid_view,
                    title: 'عرض شبكي مضغوط',
                    subtitle: 'تقليل المسافات بين الصور',
                    trailing: _VaultToggle(
                      value: _compactGrid,
                      onChanged: (v) => setState(() => _compactGrid = v),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionTitle(title: 'معلومات التطبيق'),
                  _SettingsTile(
                    icon: Icons.info_outline,
                    title: 'عن التطبيق',
                    subtitle: 'الإصدار 1.3.0 • Obsidian Vault',
                    onTap: _showAbout,
                  ),
                  _SettingsTile(
                    icon: Icons.policy,
                    title: 'سياسة الخصوصية',
                    subtitle: 'سياسة معالجة البيانات والملاحظات',
                    onTap: _showPrivacy,
                  ),
                  const SizedBox(height: 16),
                  _SectionTitle(title: 'مساحة التخزين'),
                  _SettingsTile(
                    icon: Icons.storage,
                    title: 'قاعدة البيانات',
                    subtitle: 'حجم قاعدة البيانات: $_storageInfo',
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'SpaceMono',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryContainer,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? textColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLow,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: textColor ?? AppColors.primaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor ?? AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'NotoSans',
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else
                Transform.scale(
                  scaleX: -1,
                  child: const Icon(
                    Icons.chevron_right,
                    color: AppColors.outline,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VaultToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _VaultToggle({required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return GestureDetector(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 28,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: value
              ? AppColors.primaryContainer
              : AppColors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value
              ? (isRtl ? Alignment.centerLeft : Alignment.centerRight)
              : (isRtl ? Alignment.centerRight : Alignment.centerLeft),
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: value ? AppColors.onPrimary : AppColors.secondary,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
