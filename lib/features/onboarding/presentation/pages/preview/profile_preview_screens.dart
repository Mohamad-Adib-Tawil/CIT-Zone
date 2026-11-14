import 'package:flutter/material.dart';

import '../../../../../core/errors/either.dart';
import '../../../../auth/domain/student_learning.dart';
import '../../../../auth/domain/student_session_repository.dart';
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
    'S-01' => HasobjySettingsScreen(actions: actions),
    'S-02' => HasobjyProfileScreen(actions: actions),
    'S-03' => HasobjyEditProfileScreen(actions: actions),
    'S-05' => ActivityPreviewScreen(actions: actions),
    _ => _Device(actions: actions),
  };
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.size = 88, this.initial = 'أ'});
  final double size;
  final String initial;
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
            initial,
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

class HasobjySettingsScreen extends StatelessWidget {
  const HasobjySettingsScreen({
    super.key,
    required this.actions,
    this.studentName,
    this.onSignOut,
    this.navigation,
  });
  final PreviewActions actions;
  final String? studentName;
  final VoidCallback? onSignOut;
  final Widget? navigation;
  @override
  Widget build(BuildContext context) => PreviewScaffold(
    actions: actions,
    navigation: studentName == null,
    bottomNavigation: navigation,
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
                      studentName ?? 'أحمد محمد الحلبي',
                      style: context.design.labelSemiBold,
                    ),
                    const SizedBox(height: 4),
                    if (studentName == null)
                      PreviewText(
                        'برمجيات · السنة الثانية · الفصل الثالث',
                        style: context.design.bodySmall,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _Avatar(
                size: 52,
                initial: studentName?.characters.firstOrNull ?? 'أ',
              ),
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
            ('تلقائي', studentName == null ? 'S-01' : 'S-01-SYSTEM'),
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
      if (studentName != null) _row(context, 'ملفي الشخصي', 'S-02'),
      if (studentName == null) ...[
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
      ],
      PreviewButton(
        'تسجيل الخروج',
        onTap: onSignOut ?? actions.notice,
        primary: false,
      ),
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

class HasobjyProfileScreen extends StatelessWidget {
  const HasobjyProfileScreen({super.key, required this.actions, this.profile});

  final PreviewActions actions;
  final StudentProfileData? profile;
  @override
  Widget build(BuildContext context) => PreviewScaffold(
    title: 'ملفي الشخصي',
    actions: actions,
    gap: 16,
    children: [
      Column(
        children: [
          _Avatar(initial: profile?.name.characters.firstOrNull ?? 'أ'),
          const SizedBox(height: 8),
          PreviewText(
            profile?.name ?? 'أحمد محمد الحلبي',
            style: context.design.headingMedium,
          ),
        ],
      ),
      PreviewPanel(
        gap: 12,
        children: [
          for (final row in _rows) ...[
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

  List<(String, String)> get _rows {
    final data = profile;
    if (data == null) {
      return const [
        ('الاسم الرسمي', 'أحمد محمد الحلبي'),
        ('رقم الهاتف', '0991 234 567'),
        ('البريد الإلكتروني', 'ahmad@gmail.com'),
        ('القسم', 'برمجيات'),
        ('السنة الدراسية', 'الثانية'),
        ('الفصل الحالي', 'الثالث · 2026/2027'),
      ];
    }
    return [
      ('الاسم الرسمي', data.name),
      if (data.phone case final phone?) ('رقم الهاتف', phone),
      ('البريد الإلكتروني', data.email),
      if (data.department case final department?) ('القسم', department),
      if (data.year == 1 || data.year == 2)
        ('السنة الدراسية', data.year == 1 ? 'الأولى' : 'الثانية'),
    ];
  }
}

class HasobjyEditProfileScreen extends StatefulWidget {
  const HasobjyEditProfileScreen({
    super.key,
    required this.actions,
    this.profile,
    this.onSave,
  });
  final StudentProfileData? profile;
  final Future<Either<StudentSessionFailure, void>> Function(
    String? name,
    String? phone,
  )?
  onSave;
  final PreviewActions actions;
  @override
  State<HasobjyEditProfileScreen> createState() => _EditProfileState();
}

class _EditProfileState extends State<HasobjyEditProfileScreen> {
  late final name = TextEditingController(
    text: widget.profile?.name ?? 'أحمد محمد الحلبي',
  );
  late final phone = TextEditingController(
    text: widget.profile == null ? '0991 234 567' : widget.profile?.phone,
  );
  bool saving = false;
  StudentSessionFailure? failure;

  Future<void> _save() async {
    final save = widget.onSave;
    final profile = widget.profile;
    if (saving || save == null || profile == null) return;
    final newName = name.text.trim();
    final newPhone = phone.text.trim();
    setState(() {
      saving = true;
      failure = null;
    });
    final result = await save(
      newName == profile.name ? null : newName,
      newPhone == (profile.phone ?? '') ? null : newPhone,
    );
    if (!mounted) return;
    setState(() {
      saving = false;
      failure = result.getLeft().toNullable();
    });
    if (result.isRight()) widget.actions.back();
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PreviewScaffold(
    title: 'تعديل البيانات',
    actions: saving
        ? PreviewActions(open: (_) {}, notice: () {}, back: () {})
        : widget.actions,
    gap: 16,
    children: [
      HasobjyFormField(
        label: 'الاسم الرسمي',
        raised: true,
        hint: widget.profile == null ? 'أحمد محمد الحلبي' : 'الاسم الرسمي',
        enabled: !saving,
        iconAsset: '0699d',
        controller: name,
        helper: 'يظهر في كشف علاماتك وشهاداتك',
      ),
      HasobjyFormField(
        label: 'رقم الهاتف',
        raised: true,
        hint: widget.profile == null ? '0991 234 567' : '09xx xxx xxx',
        enabled: !saving,
        keyboardType: TextInputType.phone,
        iconAsset: 'bf992',
        mirrorIcon: true,
        controller: phone,
        textDirection: TextDirection.ltr,
        helper: 'للتواصل عند الحاجة فقط',
      ),
      HasobjyFormField(
        label: 'البريد الإلكتروني',
        raised: true,
        hint: widget.profile?.email ?? 'ahmad@gmail.com',
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
      if (saving) const LinearProgressIndicator(),
      if (failure case final error?)
        Semantics(
          liveRegion: true,
          child: PreviewText(switch (error) {
            StudentSessionFailure.phoneTaken =>
              'رقم الهاتف مستخدم في حساب آخر.',
            StudentSessionFailure.invalidBasicInfo =>
              'تحقّق من الاسم الرسمي ورقم الهاتف السوري.',
            StudentSessionFailure.expired =>
              'انتهت الجلسة. سجّل الدخول مجدداً.',
            _ => 'تعذّر حفظ التعديلات. أعد المحاولة.',
          }),
        ),
      if (widget.onSave == null)
        PreviewButton(
          'حفظ التعديلات',
          onTap: widget.actions.notice,
          light3D: true,
        )
      else
        HasobjyButton(
          label: 'حفظ التعديلات',
          onPressed: saving ? null : _save,
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
