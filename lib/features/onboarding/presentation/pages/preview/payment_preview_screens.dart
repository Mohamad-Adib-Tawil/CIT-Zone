import 'package:flutter/material.dart';

import '../../theme/hasobjy_visual_scope.dart';
import '../../widgets/hasobjy_figma_components.dart';
import 'preview_widgets.dart';

class PaymentPreviewScreen extends StatelessWidget {
  const PaymentPreviewScreen({
    super.key,
    required this.frame,
    required this.actions,
  });
  final String frame;
  final PreviewActions actions;
  @override
  Widget build(BuildContext context) => switch (frame) {
    'F-01' => _courses(context),
    'F-02' => _course(context),
    'F-03' => _Checkout(actions: actions),
    'F-04' => _transfer(context),
    'F-05' => _voucher(context),
    _ => _success(context),
  };
  Widget _courses(BuildContext context) => PreviewScaffold(
    actions: actions,
    navigation: true,
    gap: 12,
    children: [
      PreviewText('الكورسات', style: context.design.title),
      PreviewTabs(
        labels: const ['كورساتي', 'كل الكورسات'],
        selected: 1,
        onSelected: (_) => actions.notice(),
      ),
      for (final row in const [
        ('تطوير تطبيقات Flutter', '12 ساعة · 48 درساً', r'$29'),
        ('أساسيات Python', '8 ساعات · 32 درساً', r'$19'),
        ('Git و GitHub للمبتدئين', '4 ساعات · 16 درساً', r'$9'),
      ])
        GestureDetector(
          onTap: () => actions.open('F-02'),
          child: PreviewPanel(
            height: 108,
            children: [
              Row(
                textDirection: TextDirection.ltr,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PreviewText(
                          row.$1,
                          style: context.design.labelSemiBold,
                        ),
                        const SizedBox(height: 4),
                        PreviewText(row.$2, style: context.design.bodySmall),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            row.$3,
                            textDirection: TextDirection.ltr,
                            style: context.design.labelSemiBold.copyWith(
                              color: context.design.brand,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  PreviewIconTile(
                    label: row.$1,
                    size: 56,
                    fill: context.design.selectedSurface,
                  ),
                ],
              ),
            ],
          ),
        ),
    ],
  );
  Widget _course(BuildContext context) => PreviewScaffold(
    title: 'تفاصيل الكورس',
    actions: actions,
    children: [
      Container(
        height: 150,
        color: context.design.surfaceSubtle,
        alignment: Alignment.center,
        child: PreviewIconTile(
          asset: 'c0735',
          size: 64,
          fill: context.design.brand,
        ),
      ),
      PreviewText('تطوير تطبيقات Flutter', style: context.design.headingMedium),
      const PreviewText(
        'تعلّم بناء تطبيقات Android وiOS من الصفر مع مشاريع عملية.',
      ),
      const PreviewPanel(
        height: 146,
        gap: 8,
        children: [
          PreviewKeyValue('المدة', '12 ساعة', body: true),
          PreviewKeyValue('عدد الدروس', '48 درساً', body: true),
          PreviewKeyValue('صلاحية الوصول', 'سنة من تاريخ الشراء', body: true),
          PreviewKeyValue('الملفات', 'عرض فقط، بدون تحميل', body: true),
        ],
      ),
      const Spacer(),
      Row(
        textDirection: TextDirection.ltr,
        children: [
          Text(r'$29', style: context.design.title),
          const SizedBox(width: 12),
          Expanded(
            child: PreviewButton(
              'اشترِ الآن',
              onTap: () => actions.open('F-03'),
            ),
          ),
        ],
      ),
    ],
  );
  Widget _transfer(BuildContext context) => PreviewScaffold(
    title: 'الدفع عبر ShamCash',
    actions: actions,
    children: [
      PreviewPanel(
        height: 150,
        gap: 10,
        children: [
          PreviewText(
            'خطوات الدفع',
            style: context.design.label.copyWith(
              color: context.design.textMuted,
            ),
          ),
          const PreviewText(
            r'1. حوّل $29 إلى الحساب الموضّح أدناه عبر ShamCash.',
            primary: true,
          ),
          const PreviewText(
            '2. انسخ رقم العملية من إشعار التحويل.',
            primary: true,
          ),
          const PreviewText('3. الصقه في الحقل وأرسل الطلب.', primary: true),
        ],
      ),
      PreviewPanel(
        height: 86,
        gap: 6,
        children: [
          PreviewText(
            'رقم الحساب',
            style: context.design.bodySmall,
            muted: true,
          ),
          Text(
            'a7f3 92c1 5d8e',
            textDirection: TextDirection.ltr,
            style: context.design.headingMedium,
          ),
        ],
      ),
      const PreviewField(
        label: 'رقم العملية',
        hint: 'مثال: 482910365',
        helper: 'يراجع فريقنا الحوالة ويفعّل الكورس خلال دقائق',
      ),
      const Spacer(),
      PreviewButton('إرسال للمراجعة', onTap: actions.notice),
    ],
  );
  Widget _voucher(BuildContext context) => PreviewScaffold(
    title: 'قسيمة شحن',
    actions: actions,
    children: [
      const PreviewText('أدخل رمز القسيمة لتفعيل الكورس مباشرة.'),
      const PreviewField(
        label: 'رمز القسيمة',
        hint: 'XXXX-XXXX-XXXX',
        helper: 'الرمز صالح للاستخدام مرة واحدة',
        direction: TextDirection.ltr,
      ),
      const Spacer(),
      PreviewButton('تفعيل القسيمة', onTap: actions.notice),
    ],
  );
  Widget _success(BuildContext context) => PreviewScaffold(
    actions: actions,
    children: [
      Center(
        child: PreviewIconTile(
          asset: context.designFrame!.assets['imgGlyph'],
          size: 96,
          fill: context.design.selectedSurface,
        ),
      ),
      PreviewText(
        'تم تفعيل الكورس',
        style: context.design.title,
        align: TextAlign.center,
      ),
      const PreviewText(
        'تطوير تطبيقات Flutter متاح الآن حتى 15 أكتوبر 2027.',
        align: TextAlign.center,
      ),
      const PreviewPanel(
        height: 116,
        gap: 8,
        children: [
          PreviewKeyValue('رقم الطلب', '#HS-20481', body: true),
          PreviewKeyValue('المبلغ', r'$29', body: true),
          PreviewKeyValue('الطريقة', 'ShamCash', body: true),
        ],
      ),
      const Spacer(),
      PreviewButton('ابدأ التعلّم', onTap: () => actions.open('C-04')),
      PreviewButton(
        'العودة إلى الكورسات',
        onTap: () => actions.open('F-01'),
        primary: false,
      ),
    ],
  );
}

class _Checkout extends StatefulWidget {
  const _Checkout({required this.actions});
  final PreviewActions actions;
  @override
  State<_Checkout> createState() => _CheckoutState();
}

class _CheckoutState extends State<_Checkout> {
  bool shamCash = true;
  @override
  Widget build(BuildContext context) => PreviewScaffold(
    title: 'إتمام الشراء',
    actions: widget.actions,
    children: [
      PreviewPanel(
        height: 146,
        gap: 8,
        children: [
          PreviewText(
            'ملخص الطلب',
            style: context.design.label.copyWith(
              color: context.design.textMuted,
            ),
          ),
          const PreviewKeyValue('الكورس', 'تطوير تطبيقات Flutter', body: true),
          const PreviewKeyValue('الصلاحية', 'سنة واحدة', body: true),
          const PreviewKeyValue('الإجمالي', r'$29', body: true, emphasis: true),
        ],
      ),
      PreviewText(
        'طريقة الدفع',
        style: context.design.label.copyWith(color: context.design.textMuted),
      ),
      HasobjySelectionOption(
        title: 'ShamCash',
        subtitle: 'حوّل المبلغ ثم أرفق رقم العملية',
        iconAsset: context.designFrame!.assets['imgGlyph']!,
        selected: shamCash,
        onTap: () => setState(() => shamCash = true),
      ),
      HasobjySelectionOption(
        title: 'قسيمة شحن',
        subtitle: 'أدخل رمز القسيمة التي حصلت عليها',
        iconAsset: context.designFrame!.assets['imgGlyph1']!,
        selected: !shamCash,
        onTap: () => setState(() => shamCash = false),
      ),
      const Spacer(),
      PreviewButton(
        'متابعة الدفع',
        onTap: () => widget.actions.open(shamCash ? 'F-04' : 'F-05'),
      ),
    ],
  );
}
