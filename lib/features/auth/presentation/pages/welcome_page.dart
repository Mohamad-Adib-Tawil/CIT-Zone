import 'package:flutter/material.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({
    super.key,
    required this.googleConfigured,
    required this.working,
    required this.onGoogleSignIn,
    this.onStudentPreview,
    this.onAdminPreview,
    this.error,
  });

  final bool googleConfigured;
  final bool working;
  final VoidCallback onGoogleSignIn;
  final VoidCallback? onStudentPreview;
  final VoidCallback? onAdminPreview;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.school_rounded,
                      color: scheme.onPrimary,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'تعلم مواد المعهد\nفي مكان واحد',
                  style: Theme.of(context).textTheme.displaySmall
                      ?.copyWith(fontWeight: FontWeight.w800, height: 1.22),
                ),
                const SizedBox(height: 14),
                Text(
                  'مواد مرتبة حسب قسمك وسنتك وفصلك، ودروس يمكنك العودة إليها بسهولة.',
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 32),
                const _FeatureRow(
                  Icons.account_tree_outlined,
                  'منهج واضح لكل قسم وسنة',
                ),
                const SizedBox(height: 14),
                const _FeatureRow(
                  Icons.play_circle_outline_rounded,
                  'درس تعريفي لكل مادة',
                ),
                const SizedBox(height: 14),
                const _FeatureRow(
                  Icons.download_for_offline_outlined,
                  'تنزيل محمي بعد تفعيل الخدمة',
                ),
                const SizedBox(height: 34),
                FilledButton.icon(
                  onPressed: googleConfigured && !working
                      ? onGoogleSignIn
                      : null,
                  icon: working
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login_rounded),
                  label: const Text('المتابعة باستخدام Google'),
                ),
                const SizedBox(height: 12),
                if (!googleConfigured)
                  Text(
                    'يتطلب تسجيل Google إعداد معرّفات OAuth لهذا التطبيق.',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    error!,
                    style: TextStyle(color: scheme.error),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (onStudentPreview != null) ...[
                  const SizedBox(height: 25),
                  const Divider(),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: onStudentPreview,
                    icon: const Icon(Icons.phone_android_rounded),
                    label: const Text('معاينة واجهة الطالب'),
                  ),
                ],
                if (onAdminPreview != null) ...[
                  const SizedBox(height: 9),
                  TextButton.icon(
                    onPressed: onAdminPreview,
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    label: const Text('معاينة لوحة الإدارة'),
                  ),
                ],
                const SizedBox(height: 28),
                Text(
                  'هوية Google وحدها لا تمنح حساباً أو اشتراكاً داخل CIT Zone حتى يتحقق خادم التطبيق منها.',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow(this.icon, this.title);

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(title)),
      ],
    );
  }
}
