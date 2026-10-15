import 'package:flutter/material.dart';

import '../../../auth/domain/google_identity.dart';
import '../theme/hasobjy_design_tokens.dart';
import '../widgets/hasobjy_figma_components.dart';

class HasobjyWelcomeScreen extends StatelessWidget {
  const HasobjyWelcomeScreen({
    super.key,
    required this.onGoogleSignIn,
    required this.working,
    this.error,
  });

  final VoidCallback onGoogleSignIn;
  final bool working;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return HasobjyFigmaFrame(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          children: [
            const Spacer(),
            const SizedBox(height: 16),
            const HasobjySvg('902ed', width: 104, height: 104),
            const SizedBox(height: 16),
            const SizedBox(
              height: 80,
              child: Center(
                child: Text(
                  'مرحباً بك في حاسوبجي سيستم',
                  textAlign: TextAlign.center,
                  style: HasobjyDesignTokens.display,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(
              height: 78,
              child: Text(
                'دروس مسجّلة وملفات PDF وتمارين لطلاب المعهد التقني للحاسوب، وكورسات برمجية لكل من يرغب بالتعلّم',
                textAlign: TextAlign.center,
                style: HasobjyDesignTokens.bodyLarge,
              ),
            ),
            const Spacer(),
            const SizedBox(height: 16),
            HasobjyButton(
              label: 'المتابعة عبر Google',
              onPressed: working ? null : onGoogleSignIn,
              icon: const HasobjySvg('96346', width: 24, height: 24),
              cornerLine: '84987',
            ),
            const SizedBox(height: 16),
            const Text(
              'بالمتابعة فأنت توافق على الشروط والأحكام وسياسة الخصوصية',
              textAlign: TextAlign.center,
              style: HasobjyDesignTokens.bodySmall,
            ),
            if (error != null) ...[
              const SizedBox(height: 4),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: HasobjyDesignTokens.bodySmall.copyWith(
                  color: const Color(0xFFFFA6A6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class HasobjyUsageTypeScreen extends StatefulWidget {
  const HasobjyUsageTypeScreen({
    super.key,
    required this.onContinue,
    this.onUnsupportedCoursesOnly,
  });

  final VoidCallback onContinue;
  final VoidCallback? onUnsupportedCoursesOnly;

  @override
  State<HasobjyUsageTypeScreen> createState() => _HasobjyUsageTypeScreenState();
}

class _HasobjyUsageTypeScreenState extends State<HasobjyUsageTypeScreen> {
  bool _institute = true;

  @override
  Widget build(BuildContext context) {
    return HasobjyFigmaFrame(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'كيف ستستخدم التطبيق؟',
              textAlign: TextAlign.end,
              style: HasobjyDesignTokens.title,
            ),
            const SizedBox(height: 16),
            const Text(
              'اختر ما يناسبك، ويمكنك تغيير ذلك لاحقاً من الإعدادات',
              textAlign: TextAlign.end,
              style: HasobjyDesignTokens.bodyMedium,
            ),
            const SizedBox(height: 16),
            _UsageOption(
              title: 'طالب في المعهد',
              subtitle: 'مواد قسمي وسنتي الدراسية، مع الكورسات الإضافية',
              iconAsset: '4d691',
              selected: _institute,
              onTap: () => setState(() => _institute = true),
            ),
            const SizedBox(height: 16),
            _UsageOption(
              title: 'الكورسات فقط',
              subtitle:
                  'أريد التسجيل في الكورسات البرمجية دون ربط حسابي بالمعهد',
              iconAsset: 'dbeae',
              selected: !_institute,
              onTap: () => setState(() => _institute = false),
            ),
            const SizedBox(height: 16),
            const Spacer(),
            const SizedBox(height: 16),
            HasobjyButton(
              label: 'متابعة',
              onPressed: _institute
                  ? widget.onContinue
                  : widget.onUnsupportedCoursesOnly,
            ),
          ],
        ),
      ),
    );
  }
}

class _UsageOption extends StatelessWidget {
  const _UsageOption({
    required this.title,
    required this.subtitle,
    required this.iconAsset,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String iconAsset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: HasobjySurface(
        height: 130,
        selected: selected,
        border: selected
            ? HasobjyDesignTokens.brand
            : HasobjyDesignTokens.border,
        cornerTopLeft: selected ? '21288' : 'b043f',
        cornerBottomRight: selected ? 'c95e6' : '03567',
        cornerLine: selected ? '416c4' : '8c8a2',
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            HasobjySvg(selected ? '0fd39' : 'cb103', width: 22, height: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.end,
                    style: HasobjyDesignTokens.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    textAlign: TextAlign.end,
                    style: HasobjyDesignTokens.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 44,
              height: 44,
              color: HasobjyDesignTokens.surfaceSubtle,
              padding: const EdgeInsets.all(10),
              child: HasobjySvg(iconAsset, width: 24, height: 24),
            ),
          ],
        ),
      ),
    );
  }
}

class HasobjyBasicInfoScreen extends StatefulWidget {
  const HasobjyBasicInfoScreen({
    super.key,
    required this.onContinue,
    required this.identity,
    this.onBack,
  });

  final VoidCallback onContinue;
  final GoogleIdentity? identity;
  final VoidCallback? onBack;

  @override
  State<HasobjyBasicInfoScreen> createState() => _HasobjyBasicInfoScreenState();
}

class _HasobjyBasicInfoScreenState extends State<HasobjyBasicInfoScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HasobjyFigmaFrame(
      appBarTitle: 'معلوماتك الأساسية',
      onBack: widget.onBack,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const HasobjyStepper(activeBars: 2),
            const SizedBox(height: 16),
            HasobjyFormField(
              label: 'الاسم الرسمي',
              hint: 'الاسم الثلاثي كما في الهوية',
              iconAsset: '0699d',
              helper: 'يظهر في كشف علاماتك وشهاداتك',
              controller: _nameController,
            ),
            const SizedBox(height: 16),
            HasobjyFormField(
              label: 'رقم الهاتف',
              hint: '09xx xxx xxx',
              iconAsset: 'bf992',
              helper: 'للتواصل عند الحاجة فقط',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 16),
            HasobjyFormField(
              label: 'البريد الإلكتروني',
              hint: widget.identity?.email ?? 'name@gmail.com',
              iconAsset: '90d15',
              helper: 'مأخوذ من حساب Google ولا يمكن تعديله',
              enabled: false,
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 16),
            const Spacer(),
            const SizedBox(height: 16),
            HasobjyButton(label: 'متابعة', onPressed: widget.onContinue),
          ],
        ),
      ),
    );
  }
}
