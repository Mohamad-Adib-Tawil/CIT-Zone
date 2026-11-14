import 'package:cit_zone/core/localization/generated/app_localizations.dart';
import 'package:flutter/material.dart';

import '../theme/hasobjy_visual_scope.dart';
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
        padding: EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          children: [
            Spacer(),
            SizedBox(height: 16),
            HasobjySvg('68735', width: 112, height: 112),
            SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).deviceConflictTitle,
              textAlign: TextAlign.center,
              style: context.design.title,
            ),
            SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).deviceConflictDescription,
              textAlign: TextAlign.center,
              style: context.design.bodyLarge,
            ),
            SizedBox(height: 16),
            Spacer(),
            SizedBox(height: 16),
            HasobjyButton(
              label: AppLocalizations.of(context).requestDeviceTransfer,
              icon: HasobjySvg('bb08f', width: 24, height: 24),
              onPressed: onRequestTransfer,
            ),
            SizedBox(height: 16),
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
    this.deviceName,
    this.enabled = true,
    this.message,
    this.onSubmitReason,
  });

  final VoidCallback onSubmit;
  final VoidCallback? onBack;
  final String? deviceName;
  final bool enabled;
  final String? message;
  final ValueChanged<String>? onSubmitReason;

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
        padding: EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DeviceSummaryCard(
              label: AppLocalizations.of(context).newDevice,
              emphasized: true,
              deviceName: widget.deviceName,
            ),
            SizedBox(height: 16),
            HasobjyFormField(
              label: AppLocalizations.of(context).transferReason,
              hint: AppLocalizations.of(context).transferReasonHint,
              iconAsset: '4ece2',
              helper: AppLocalizations.of(context).transferReviewHelper,
              controller: _reasonController,
              enabled: widget.enabled,
            ),
            SizedBox(height: 16),
            if (widget.message case final message?)
              Semantics(liveRegion: true, child: Text(message)),
            Spacer(),
            SizedBox(height: 16),
            HasobjyButton(
              label: AppLocalizations.of(context).submitRequest,
              onPressed: !widget.enabled
                  ? null
                  : () {
                      final onSubmitReason = widget.onSubmitReason;
                      if (onSubmitReason == null) {
                        widget.onSubmit();
                      } else {
                        onSubmitReason(_reasonController.text.trim());
                      }
                    },
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
        padding: EdgeInsets.fromLTRB(24, 16, 24, 24),
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
                  Center(child: HasobjySvg('ef6d9', width: 72, height: 72)),
                  SizedBox(height: 12),
                  Center(
                    child: HasobjyBadge(
                      label: AppLocalizations.of(context).underReview,
                      background: context.design.warning,
                      foreground: context.design.warningText,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context).requestUnderReview,
                    textAlign: TextAlign.center,
                    style: context.design.headingMedium,
                  ),
                  SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context).previewRequestSent,
                    textAlign: TextAlign.center,
                    style: context.design.bodyMedium,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            _DeviceSummaryCard(
              label: AppLocalizations.of(context).requestedDevice,
            ),
            SizedBox(height: 16),
            Spacer(),
            SizedBox(height: 16),
            HasobjyButton(
              label: AppLocalizations.of(context).contactSupport,
              primary: false,
              backgroundColor: context.design.selectedSurface,
              cornerLine: '84987',
              textColor: context.design.brand,
              icon: Transform.flip(
                flipX: true,
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: Center(
                    child: HasobjySvg('bf992', width: 21.4062, height: 21.4102),
                  ),
                ),
              ),
              onPressed: onContactSupport,
            ),
            SizedBox(height: 16),
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
  const _DeviceSummaryCard({
    required this.label,
    this.emphasized = false,
    this.deviceName,
  });
  final String label;
  final bool emphasized;
  final String? deviceName;
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
          style: context.design.label.copyWith(color: context.design.textMuted),
        ),
        SizedBox(height: 8),
        Text(
          deviceName ?? _previewDeviceName,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.right,
          style: emphasized
              ? context.design.labelSemiBold
              : context.design.bodyLarge.copyWith(
                  color: context.design.textPrimary,
                ),
        ),
      ],
    ),
  );
}
