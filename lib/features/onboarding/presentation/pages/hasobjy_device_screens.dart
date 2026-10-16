import 'package:cit_zone/core/localization/generated/app_localizations.dart';
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
            Text(
              AppLocalizations.of(context).deviceConflictTitle,
              textAlign: TextAlign.center,
              style: HasobjyDesignTokens.title,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).deviceConflictDescription,
              textAlign: TextAlign.center,
              style: HasobjyDesignTokens.bodyLarge,
            ),
            const SizedBox(height: 16),
            const Spacer(),
            const SizedBox(height: 16),
            HasobjyButton(
              label: AppLocalizations.of(context).requestDeviceTransfer,
              icon: const HasobjySvg('bb08f', width: 24, height: 24),
              onPressed: onRequestTransfer,
            ),
            const SizedBox(height: 16),
            HasobjyButton(
              label: AppLocalizations.of(context).signOut,
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
      appBarTitle: AppLocalizations.of(context).requestDeviceTransfer,
      onBack: widget.onBack,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DeviceSummaryCard(
              label: AppLocalizations.of(context).newDevice,
              emphasized: true,
            ),
            const SizedBox(height: 16),
            HasobjyFormField(
              label: AppLocalizations.of(context).transferReason,
              hint: AppLocalizations.of(context).transferReasonHint,
              iconAsset: '4ece2',
              helper: AppLocalizations.of(context).transferReviewHelper,
              controller: _reasonController,
            ),
            const SizedBox(height: 16),
            const Spacer(),
            const SizedBox(height: 16),
            HasobjyButton(
              label: AppLocalizations.of(context).submitRequest,
              onPressed: widget.onSubmit,
            ),
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
      appBarTitle: AppLocalizations.of(context).requestStatus,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HasobjySurface(
              height: 216,
              cornerTopLeft: '21288',
              cornerBottomRight: 'c95e6',
              cornerLine: '8c8a2',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: HasobjySvg('ef6d9', width: 72, height: 72),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: HasobjyBadge(
                      label: AppLocalizations.of(context).underReview,
                      background: HasobjyDesignTokens.warning,
                      foreground: HasobjyDesignTokens.warningText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context).requestUnderReview,
                    textAlign: TextAlign.center,
                    style: HasobjyDesignTokens.headingMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context).previewRequestSent,
                    textAlign: TextAlign.center,
                    style: HasobjyDesignTokens.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _DeviceSummaryCard(
              label: AppLocalizations.of(context).requestedDevice,
            ),
            const SizedBox(height: 16),
            const Spacer(),
            const SizedBox(height: 16),
            HasobjyButton(
              label: AppLocalizations.of(context).contactSupport,
              primary: false,
              backgroundColor: HasobjyDesignTokens.selectedSurface,
              cornerLine: '84987',
              textColor: HasobjyDesignTokens.brand,
              icon: Transform.flip(
                flipX: true,
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: Center(
                    child: HasobjySvg('bf992', width: 21.4062, height: 21.4102),
                  ),
                ),
              ),
              onPressed: onContactSupport,
            ),
            const SizedBox(height: 16),
            HasobjyButton(
              label: AppLocalizations.of(context).signOut,
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

class _DeviceSummaryCard extends StatelessWidget {
  const _DeviceSummaryCard({required this.label, this.emphasized = false});
  final String label;
  final bool emphasized;
  @override
  Widget build(BuildContext context) => HasobjySurface(
    height: emphasized ? 86 : 88,
    cornerLine: '8c8a2',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          textAlign: TextAlign.right,
          style: HasobjyDesignTokens.label.copyWith(
            color: HasobjyDesignTokens.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _previewDeviceName,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.right,
          style: emphasized
              ? HasobjyDesignTokens.labelSemiBold
              : HasobjyDesignTokens.bodyLarge.copyWith(
                  color: HasobjyDesignTokens.textPrimary,
                ),
        ),
      ],
    ),
  );
}
