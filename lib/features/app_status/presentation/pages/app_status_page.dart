import 'package:cit_zone/core/localization/generated/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../../onboarding/presentation/theme/hasobjy_visual_scope.dart';
import '../../../onboarding/presentation/widgets/hasobjy_figma_components.dart';
import '../../../onboarding/presentation/widgets/hasobjy_3d_button.dart';
import '../cubit/app_availability_cubit.dart';
import '../../domain/app_availability.dart';
import '../widgets/app_status_background.dart';

/// Server gate: no preview navigation, demo downloads, or local access grant.
class AppStatusPage extends StatelessWidget {
  const AppStatusPage({
    super.key,
    required this.state,
    required this.onRetry,
    required this.onUpdate,
  });
  final AppAvailabilityState state;
  final VoidCallback onRetry;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final frame = switch (state) {
      AppAvailabilityLoading() => 'I-01',
      AppAvailabilityLoaded(
        availability: AppAvailability(kind: AppAvailabilityKind.maintenance),
      ) =>
        'I-03',
      AppAvailabilityLoaded(
        availability: AppAvailability(kind: AppAvailabilityKind.updateRequired),
      ) =>
        'I-04',
      AppAvailabilityError(failure: AppAvailabilityFailure.network) => 'I-02',
      _ => 'I-05',
    };
    final light = Theme.of(context).brightness == Brightness.light;
    final page = HasobjyVisualScope(
      frameName: light ? '$frame-LIGHT' : frame,
      child: Builder(
        builder: (context) {
          if (frame == 'I-01') {
            return HasobjyFigmaFrame(
              backgroundLayer: AppStatusBackground(frame: frame, light: light),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: HasobjySvg(
                            context.designFrame!.assets['imgH']!,
                            width: 96,
                            height: 96,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.appStatusBrand,
                        style: context.design.title,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.appStatusInstitute,
                        style: context.design.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          final (title, fallback) = switch (frame) {
            'I-02' => (
              l10n.appStatusOfflineTitle,
              l10n.appStatusOfflineMessage,
            ),
            'I-03' => (
              l10n.appStatusMaintenanceTitle,
              l10n.appStatusMaintenanceMessage,
            ),
            'I-04' => (l10n.appStatusUpdateTitle, l10n.appStatusUpdateMessage),
            _ => (l10n.appStatusErrorTitle, l10n.appStatusErrorMessage),
          };
          final current = state;
          final message =
              current is AppAvailabilityLoaded &&
                  current.availability.message.isNotEmpty
              ? current.availability.message
              : fallback;
          return PopScope(
            canPop: false,
            child: HasobjyFigmaFrame(
              backgroundLayer: AppStatusBackground(frame: frame, light: light),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    if (frame != 'I-03') SizedBox(height: light ? 84 : 76),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 112,
                              height: 112,
                              color: context.design.selectedSurface,
                              alignment: Alignment.center,
                              child: HasobjySvg(
                                context.designFrame!.assets['imgGlyph']!,
                                width: 24,
                                height: 24,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              title,
                              style: context.design.title,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              message,
                              style: context.design.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (frame == 'I-04')
                      Hasobjy3DButton(
                        label: l10n.appStatusUpdate,
                        onPressed: onUpdate,
                        icon: const HasobjySvg('93298', width: 24, height: 24),
                      ),
                    if (frame == 'I-02' || frame == 'I-05')
                      Hasobjy3DButton(
                        label: l10n.appStatusRetry,
                        onPressed: onRetry,
                        icon: const HasobjySvg('92416', width: 24, height: 24),
                      ),
                    if (frame != 'I-03') const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    return HasobjyReferenceViewport.isActive(context)
        ? ClipRRect(borderRadius: BorderRadius.circular(44), child: page)
        : page;
  }
}
