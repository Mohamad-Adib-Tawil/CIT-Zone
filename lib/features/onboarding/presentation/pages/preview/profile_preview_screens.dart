import 'package:flutter/material.dart';

import '../../theme/hasobjy_visual_scope.dart';
import '../../widgets/hasobjy_figma_components.dart';
import 'preview_widgets.dart';
import 'activity_preview_screen.dart';

class ProfilePreviewScreen extends StatelessWidget {
  const ProfilePreviewScreen({
    super.key,
    required this.frame,
    required this.actions,
  });
  final String frame;
  final PreviewActions actions;
  @override
  Widget build(BuildContext context) => switch (frame) {
    'S-01' => _Settings(actions: actions),
    'S-02' => _Profile(actions: actions),
    'S-03' => _EditProfile(actions: actions),
    'S-05' => ActivityPreviewScreen(actions: actions),
    _ => _Device(actions: actions),
  };
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.size = 88});
  final double size;
  @override
  Widget build(BuildContext context) => ClipPath(
    clipper: _AvatarChamferClipper(cutSize: size == 52 ? 10 : 18),
    child: SizedBox(
      width: size,
      height: size,
      child: ColoredBox(
        color: context.design.selectedSurface,
        child: Center(
          child: PreviewText(
            'أ',
            style: size == 52 ? context.design.title : context.design.display,
            align: TextAlign.center,
            color: context.design.brand,
          ),
        ),
      ),
    ),
  );
}

class _AvatarChamferClipper extends CustomClipper<Path> {
  const _AvatarChamferClipper({required this.cutSize});
  final double cutSize;

  @override
  Path getClip(Size size) => Path()
    ..moveTo(cutSize, 0)
    ..lineTo(size.width, 0)
    ..lineTo(size.width, size.height - cutSize)
    ..lineTo(size.width - cutSize, size.height)
    ..lineTo(0, size.height)
    ..lineTo(0, cutSize)
    ..close();

  @override
  bool shouldReclip(_AvatarChamferClipper oldClipper) =>
      oldClipper.cutSize != cutSize;
}

class _Settings extends StatelessWidget {
  const _Settings({required this.actions});
  final PreviewActions actions;
  @override
  Widget build(BuildContext context) => PreviewScaffold(
    actions: actions,
    navigation: true,
    gap: 10,
    children: [
      PreviewText('الإعدادات', style: context.design.title),
      PreviewPanel(
        height: 86,
        children: [
          Row(
            textDirection: TextDirection.ltr,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PreviewText(
                      'أحمد محمد الحلبي',
                      style: context.design.labelSemiBold,
                    ),
                    const SizedBox(height: 4),
                    PreviewText(
                      'برمجيات · السنة الثانية · الفصل الثالث',
                      style: context.design.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const _Avatar(size: 52),
            ],
          ),
        ],
      ),
      PreviewText(
        'المظهر',
        style: context.design.label.copyWith(color: context.design.textMuted),
      ),
      Row(
        textDirection: TextDirection.ltr,
        children: [
          for (final item in [
            ('داكن', 'S-01-DARK'),
            ('فاتح', 'S-01-LIGHT'),
            ('تلقائي', 'S-01'),
          ]) ...[
            if (item.$1 != 'داكن') const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () => actions.open(item.$2),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 83),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: actions.selectedAppearance == item.$1
                        ? context.design.selectedSurface
                        : context.design.surface,
                    border: Border.all(
                      color: actions.selectedAppearance == item.$1
                          ? context.design.brand
                          : context.design.border,
                      width: actions.selectedAppearance == item.$1 ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HasobjySvg(
                        previewIcon(context, item.$1)!,
                        width: 24,
                        height: 24,
                      ),
                      const SizedBox(height: 8),
                      PreviewText(
                        item.$1,
                        style: context.design.label,
                        color: actions.selectedAppearance == item.$1
                            ? context.design.textPrimary
                            : context.design.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      PreviewText(
        'الحساب',
        style: context.design.label.copyWith(color: context.design.textMuted),
      ),
      Column(
        children: [
          _row(context, 'ملفي الشخصي', 'S-02'),
          _row(context, 'الجهاز المسجّل', 'S-04'),
          _row(context, 'اشتراكاتي', 'F-07'),
        ],
      ),
      PreviewText(
        'المساعدة',
        style: context.design.label.copyWith(color: context.design.textMuted),
      ),
      Column(
        children: [
          _row(context, 'الدعم والتواصل', 'H-02'),
          _row(context, 'الشروط وسياسة الخصوصية', 'A-S08'),
        ],
      ),
      PreviewButton('تسجيل الخروج', onTap: actions.notice, primary: false),
    ],
  );
  Widget _row(BuildContext context, String title, String destination) =>
      GestureDetector(
        onTap: () => actions.open(destination),
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: context.design.surface,
            border: Border.all(color: context.design.border),
          ),
          child: Row(
            textDirection: TextDirection.ltr,
            children: [
              HasobjySvg('287fc', width: 24, height: 24),
              const SizedBox(width: 12),
              Expanded(
                child: PreviewText(
                  title,
                  style: context.design.bodyMedium.copyWith(
                    height: 20 / 14,
                    color: context.design.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              PreviewIconTile(
                label: title,
                size: 40,
                asset: title == 'اشتراكاتي'
                    ? (context.design.isLight ? '36fd3' : '0583d')
                    : null,
              ),
            ],
          ),
        ),
      );
}

class _Profile extends StatelessWidget {
  const _Profile({required this.actions});
  final PreviewActions actions;
  @override
  Widget build(BuildContext context) => PreviewScaffold(
    title: 'ملفي الشخصي',
    actions: actions,
    gap: 16,
    children: [
      Column(
        children: [
          const _Avatar(),
          const SizedBox(height: 8),
          PreviewText('أحمد محمد الحلبي', style: context.design.headingMedium),
        ],
      ),
      PreviewPanel(
        gap: 12,
        children: [
          for (final row in const [
            ('الاسم الرسمي', 'أحمد محمد الحلبي'),
            ('رقم الهاتف', '0991 234 567'),
            ('البريد الإلكتروني', 'ahmad@gmail.com'),
            ('القسم', 'برمجيات'),
            ('السنة الدراسية', 'الثانية'),
            ('الفصل الحالي', 'الثالث · 2026/2027'),
          ]) ...[
            if (row.$1 != 'الاسم الرسمي')
              Container(height: 1, color: context.design.border),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PreviewText(
                  row.$1,
                  style: context.design.bodySmall,
                  color: context.design.textMuted,
                ),
                const SizedBox(height: 2),
                Text(
                  row.$2,
                  textDirection:
                      row.$1 == 'رقم الهاتف' || row.$1 == 'البريد الإلكتروني'
                      ? TextDirection.ltr
                      : TextDirection.rtl,
                  textAlign:
                      row.$1 == 'رقم الهاتف' || row.$1 == 'البريد الإلكتروني'
                      ? TextAlign.left
                      : TextAlign.right,
                  style: context.design.bodyMedium.copyWith(
                    color: context.design.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      const Spacer(),
      PreviewButton(
        'تعديل البيانات',
        subtle: true,
        onTap: () => actions.open('S-03'),
        primary: false,
      ),
    ],
  );
}

class _EditProfile extends StatefulWidget {
  const _EditProfile({required this.actions});
  final PreviewActions actions;
  @override
  State<_EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<_EditProfile> {
  final name = TextEditingController(text: 'أحمد محمد الحلبي');
  final phone = TextEditingController(text: '0991 234 567');
  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PreviewScaffold(
    title: 'تعديل البيانات',
    actions: widget.actions,
    gap: 16,
    children: [
      HasobjyFormField(
        label: 'الاسم الرسمي',
        raised: true,
        hint: 'أحمد محمد الحلبي',
        iconAsset: '0699d',
        controller: name,
        helper: 'يظهر في كشف علاماتك وشهاداتك',
      ),
      HasobjyFormField(
        label: 'رقم الهاتف',
        raised: true,
        hint: '0991 234 567',
        iconAsset: 'bf992',
        mirrorIcon: true,
        controller: phone,
        textDirection: TextDirection.ltr,
        helper: 'للتواصل عند الحاجة فقط',
      ),
      const HasobjyFormField(
        label: 'البريد الإلكتروني',
        raised: true,
        hint: 'ahmad@gmail.com',
        iconAsset: '90d15',
        enabled: false,
        dimDisabled: false,
        textDirection: TextDirection.ltr,
        helper: 'مأخوذ من حساب Google ولا يمكن تعديله',
      ),
      PreviewPanel(
        height: 70,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HasobjySvg('4ece2', width: 24, height: 24),
              const SizedBox(width: 8),
              Expanded(
                child: PreviewText(
                  'لتغيير القسم أو السنة الدراسية، تواصل مع الإدارة عبر الدعم.',
                  style: context.design.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
      const Spacer(),
      PreviewButton(
        'حفظ التعديلات',
        onTap: widget.actions.notice,
        light3D: true,
      ),
    ],
  );
}

class _Device extends StatelessWidget {
  const _Device({required this.actions});
  final PreviewActions actions;
  @override
  Widget build(BuildContext context) => PreviewScaffold(
    title: 'الجهاز المسجّل',
    actions: actions,
    gap: 16,
    children: [
      PreviewPanel(
        height: 180,
        gap: 12,
        children: [
          Row(
            textDirection: TextDirection.ltr,
            children: [
              previewBadge(context, 'نشط', tone: 'success'),
              const SizedBox(width: 12),
              Expanded(
                child: PreviewText(
                  'Samsung Galaxy A54',
                  style: context.design.labelSemiBold,
                ),
              ),
              const SizedBox(width: 12),
              PreviewIconTile(label: 'Samsung Galaxy A54'),
            ],
          ),
          for (final row in const [
            ('نظام التشغيل', 'Android 14'),
            ('تاريخ التسجيل', '12 أكتوبر 2026'),
            ('آخر استخدام', 'اليوم · 22:10'),
          ])
            PreviewKeyValue(row.$1, row.$2),
        ],
      ),
      PreviewText(
        'يُسمح بجهاز واحد فقط لحساب طالب المعهد. لتغيير الجهاز أرسل طلباً تراجعه الإدارة.',
        style: context.design.bodySmall,
      ),
      const Spacer(),
      PreviewButton(
        'طلب تغيير الجهاز',
        onTap: () => actions.open('A-S06'),
        primary: false,
      ),
    ],
  );
}
