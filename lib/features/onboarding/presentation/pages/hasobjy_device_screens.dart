import 'package:flutter/material.dart';

import '../theme/hasobjy_design_tokens.dart';
import '../widgets/hasobjy_figma_components.dart';

const _previewDeviceName = 'Samsung Galaxy A54 · Android 14';

class HasobjyDeviceConflictScreen extends StatelessWidget {
  const HasobjyDeviceConflictScreen({
    super.key,
    required this.onRequestTransfer,
    required this.onSignOut,
  });

  final VoidCallback onRequestTransfer;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return HasobjyFigmaFrame(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          children: [
            const Spacer(),
            const SizedBox(height: 16),
            const HasobjySvg('68735', width: 112, height: 112),
            const SizedBox(height: 16),
            const Text(
              'هذا الحساب مرتبط بجهاز آخر',
              textAlign: TextAlign.center,
              style: HasobjyDesignTokens.title,
            ),
            const SizedBox(height: 16),
            const Text(
              'يمكن استخدام الحساب على جهاز واحد فقط. لتغيير الجهاز أرسل طلباً للإدارة وسنراجعه في أقرب وقت.',
              textAlign: TextAlign.center,
              style: HasobjyDesignTokens.bodyLarge,
            ),
            const Spacer(),
            const SizedBox(height: 16),
            HasobjyButton(
              label: 'طلب تغيير الجهاز',
              icon: const HasobjySvg('bb08f', width: 24, height: 24),
              onPressed: onRequestTransfer,
            ),
            const SizedBox(height: 16),
            HasobjyButton(
              label: 'تسجيل الخروج',
              primary: false,
              cornerLine: '84987',
              onPressed: onSignOut,
            ),
          ],
        ),
      ),
    );
  }
}

class HasobjyDeviceTransferScreen extends StatefulWidget {
  const HasobjyDeviceTransferScreen({
    super.key,
    required this.onSubmit,
    this.onBack,
  });

  final VoidCallback onSubmit;
  final VoidCallback? onBack;

  @override
  State<HasobjyDeviceTransferScreen> createState() =>
      _HasobjyDeviceTransferScreenState();
}

class _HasobjyDeviceTransferScreenState
    extends State<HasobjyDeviceTransferScreen> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HasobjyFigmaFrame(
      appBarTitle: 'طلب تغيير الجهاز',
      onBack: widget.onBack,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HasobjySurface(
              height: 94,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              cornerLine: '8c8a2',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'الجهاز الجديد',
                    style: HasobjyDesignTokens.bodyMedium.copyWith(
                      color: HasobjyDesignTokens.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      _previewDeviceName,
                      textAlign: TextAlign.right,
                      style: HasobjyDesignTokens.bodyLarge,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            HasobjyFormField(
              label: 'سبب التغيير',
              hint: 'مثال: تغيّر هاتفي أو فُقد الجهاز القديم',
              iconAsset: '4ece2',
              helper: 'سيصل طلبك إلى الإدارة للمراجعة',
              controller: _reasonController,
            ),
            const SizedBox(height: 16),
            const Spacer(),
            const SizedBox(height: 16),
            HasobjyButton(label: 'إرسال الطلب', onPressed: widget.onSubmit),
          ],
        ),
      ),
    );
  }
}

class HasobjyTransferStatusScreen extends StatelessWidget {
  const HasobjyTransferStatusScreen({
    super.key,
    required this.onContactSupport,
    required this.onSignOut,
  });

  final VoidCallback onContactSupport;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return HasobjyFigmaFrame(
      appBarTitle: 'حالة الطلب',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HasobjySurface(
              height: 240,
              padding: const EdgeInsets.all(16),
              cornerTopLeft: '21288',
              cornerBottomRight: 'c95e6',
              cornerLine: '8c8a2',
              child: Column(
                children: [
                  const HasobjySvg('ef6d9', width: 72, height: 72),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: HasobjyDesignTokens.warning,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'قيد المراجعة',
                      style: HasobjyDesignTokens.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'طلبك قيد المراجعة',
                    style: HasobjyDesignTokens.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'أُرسل الطلب اليوم 12:50. سيصلك إشعار فور اتخاذ القرار.',
                    textAlign: TextAlign.center,
                    style: HasobjyDesignTokens.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            HasobjySurface(
              height: 94,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'الجهاز المطلوب',
                    style: HasobjyDesignTokens.bodyMedium.copyWith(
                      color: HasobjyDesignTokens.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      _previewDeviceName,
                      textAlign: TextAlign.right,
                      style: HasobjyDesignTokens.bodyLarge,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Spacer(),
            const SizedBox(height: 16),
            HasobjyButton(
              label: 'التواصل مع الدعم',
              primary: false,
              backgroundColor: HasobjyDesignTokens.selectedSurface,
              cornerLine: '84987',
              textColor: HasobjyDesignTokens.brand,
              icon: const HasobjySvg('bf992', width: 24, height: 24),
              onPressed: onContactSupport,
            ),
            const SizedBox(height: 16),
            HasobjyButton(
              label: 'تسجيل الخروج',
              primary: false,
              cornerLine: '84987',
              onPressed: onSignOut,
            ),
          ],
        ),
      ),
    );
  }
}
