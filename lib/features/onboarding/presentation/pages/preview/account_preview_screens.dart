import 'package:flutter/material.dart';

import '../../theme/hasobjy_visual_scope.dart';
import '../../widgets/hasobjy_figma_components.dart';
import '../hasobjy_auth_screens.dart';
import 'preview_widgets.dart';

class AccountPreviewScreen extends StatelessWidget {
  const AccountPreviewScreen({
    super.key,
    required this.frame,
    required this.actions,
  });
  final String frame;
  final PreviewActions actions;
  @override
  Widget build(BuildContext context) {
    if (frame == 'A-S09') {
      return HasobjyBasicInfoScreen(
        identity: null,
        showStepper: false,
        continueLabel: 'ابدأ التعلّم',
        onBack: actions.back,
        onContinue: actions.notice,
      );
    }
    if (frame == 'A-S10') {
      return PreviewScaffold(
        actions: actions,
        gap: 16,
        children: [
          const Spacer(),
          Center(
            child: SizedBox(
              width: 112,
              height: 112,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ColoredBox(color: context.design.selectedSurface),
                  ),
                  Positioned(
                    left: 28,
                    top: 28,
                    child: HasobjySvg(
                      context.designFrame!.assets['imgGlyph']!,
                      width: 24,
                      height: 24,
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    child: HasobjySvg(
                      context.designFrame!.assets['imgChamferTl']!,
                      width: 14,
                      height: 14,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: HasobjySvg(
                      context.designFrame!.assets['imgChamferBr']!,
                      width: 14,
                      height: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          PreviewText(
            'تم إيقاف حسابك',
            style: context.design.title,
            align: TextAlign.center,
          ),
          PreviewText(
            'أوقفت الإدارة هذا الحساب مؤقتاً. تواصل مع الدعم لمعرفة السبب وكيفية إعادة التفعيل.',
            style: context.design.bodyLarge,
            align: TextAlign.center,
          ),
          const Spacer(),
          PreviewButton('التواصل مع الدعم', onTap: () => actions.open('H-02')),
          PreviewButton('تسجيل الخروج', onTap: actions.notice, primary: false),
        ],
      );
    }
    return PreviewScaffold(
      title: 'الشروط والخصوصية',
      actions: actions,
      gap: 16,
      children: [
        PreviewTabs(
          labels: const ['سياسة الخصوصية', 'الشروط والأحكام'],
          selected: 1,
          onSelected: (_) => actions.notice(),
        ),
        PreviewPanel(
          gap: 14,
          children: [
            PreviewText(
              '1. استخدام التطبيق',
              style: context.design.labelSemiBold,
            ),
            const PreviewText(
              'التطبيق مخصّص لطلاب المعاهد التقنية المعلوماتية ولمستخدمي الكورسات. أنت مسؤول عن صحة المعلومات التي تدخلها عند التسجيل.',
            ),
            PreviewText(
              '2. الحساب والجهاز',
              style: context.design.labelSemiBold,
            ),
            const PreviewText(
              'حساب طالب المعهد مرتبط بجهاز واحد فقط. تغيير الجهاز يتم عبر طلب تراجعه إدارة التطبيق.',
            ),
            PreviewText(
              '3. المحتوى والحماية',
              style: context.design.labelSemiBold,
            ),
            const PreviewText(
              'الدروس والملفات محمية ولا يجوز تصويرها أو نسخها أو مشاركتها. مخالفة ذلك قد تؤدي إلى إيقاف الحساب.',
            ),
            PreviewText('4. المدفوعات', style: context.design.labelSemiBold),
            const PreviewText(
              'الأسعار بالدولار الأمريكي، ومدة صلاحية الكورس سنة من تاريخ الشراء ما لم يُذكر غير ذلك.',
            ),
            PreviewText(
              'آخر تحديث: 15 أكتوبر 2026 ·',
              style: context.design.bodySmall.copyWith(
                color: context.design.textSecondary,
              ),
            ),
          ],
        ),
        const Spacer(),
        PreviewButton('فهمت', onTap: actions.back),
      ],
    );
  }
}
