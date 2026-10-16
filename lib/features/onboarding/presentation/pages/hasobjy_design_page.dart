import 'package:cit_zone/core/localization/generated/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../../auth/domain/google_identity.dart';
import '../theme/hasobjy_visual_scope.dart';
import 'preview/account_preview_screens.dart';
import 'preview/system_preview_screens.dart';
import 'preview/profile_preview_screens.dart';
import 'preview/payment_preview_screens.dart';
import 'preview/learning_preview_screens.dart';
import 'preview/grades_support_preview_screens.dart';
import 'preview/preview_widgets.dart';
import '../widgets/hasobjy_figma_components.dart';
import 'hasobjy_academic_screens.dart';
import 'hasobjy_auth_screens.dart';
import 'hasobjy_device_screens.dart';

enum HasobjyFrameId {
  aS01('A-S01', '108:23'),
  aS01Light('A-S01-LIGHT', '119:667'),
  aS03('A-S03', '9:15'),
  aS03Light('A-S03-LIGHT', '103:1232'),
  aS04('A-S04', '9:34'),
  aS04Light('A-S04-LIGHT', '103:1241'),
  aS05('A-S05', '9:65'),
  aS05Light('A-S05-LIGHT', '103:1251'),
  aS06('A-S06', '9:81'),
  aS06Light('A-S06-LIGHT', '103:1266'),
  aS07('A-S07', '9:101'),
  aS07Light('A-S07-LIGHT', '103:1280'),
  aS08('A-S08', '65:237'),
  aS08Light('A-S08-LIGHT', '103:1308'),
  aS09('A-S09', '66:629'),
  aS09Light('A-S09-LIGHT', '103:1329'),
  aS10('A-S10', '66:692'),
  aS10Light('A-S10-LIGHT', '103:1338'),
  bS01('B-S01', '10:2'),
  bS01Light('B-S01-LIGHT', '103:2957'),
  bS03('B-S03', '10:40'),
  bS03Light('B-S03-LIGHT', '103:2970'),
  bS04('B-S04', '10:69'),
  bS04Light('B-S04-LIGHT', '103:2996'),
  bS05('B-S05', '10:92'),
  bS05Light('B-S05-LIGHT', '103:3019'),
  bS06('B-S06', '10:115'),
  bS06Light('B-S06-LIGHT', '103:3050'),
  c01('C-01', '69:3'),
  c01Light('C-01-LIGHT', '103:3371'),
  c02('C-02', '69:93'),
  c02Light('C-02-LIGHT', '103:3410'),
  c03('C-03', '69:203'),
  c03Light('C-03-LIGHT', '103:3467'),
  c04('C-04', '69:304'),
  c04Light('C-04-LIGHT', '103:3512'),
  c05('C-05', '73:206'),
  c05Light('C-05-LIGHT', '103:3532'),
  c06('C-06', '73:269'),
  c06Light('C-06-LIGHT', '103:3556'),
  c07('C-07', '73:332'),
  c07Light('C-07-LIGHT', '103:3588'),
  c08('C-08', '73:391'),
  c08Light('C-08-LIGHT', '103:3618'),
  e01('E-01', '91:26'),
  e01Light('E-01-LIGHT', '103:4398'),
  f01('F-01', '80:3'),
  f01Light('F-01-LIGHT', '103:4134'),
  f02('F-02', '80:113'),
  f02Light('F-02-LIGHT', '103:4167'),
  f03('F-03', '80:175'),
  f03Light('F-03-LIGHT', '103:4193'),
  f04('F-04', '80:260'),
  f04Light('F-04-LIGHT', '103:4213'),
  f05('F-05', '80:312'),
  f05Light('F-05-LIGHT', '103:4228'),
  f06('F-06', '80:357'),
  f06Light('F-06-LIGHT', '103:4236'),
  g01('G-01', '85:3'),
  g01Light('G-01-LIGHT', '103:4256'),
  g02('G-02', '85:58'),
  g02Light('G-02-LIGHT', '103:4288'),
  h01('H-01', '85:100'),
  h01Light('H-01-LIGHT', '103:4310'),
  h02('H-02', '85:193'),
  h02Light('H-02-LIGHT', '103:4345'),
  h03('H-03', '85:252'),
  h03Light('H-03-LIGHT', '103:4369'),
  h04('H-04', '85:305'),
  h04Light('H-04-LIGHT', '103:4377'),
  i01('I-01', '91:3'),
  i01Light('I-01-LIGHT', '103:4392'),
  i02('I-02', '91:88'),
  i02Light('I-02-LIGHT', '103:4432'),
  i03('I-03', '91:142'),
  i03Light('I-03-LIGHT', '103:4442'),
  i04('I-04', '91:168'),
  i04Light('I-04-LIGHT', '103:4450'),
  i05('I-05', '91:203'),
  i05Light('I-05-LIGHT', '103:4459'),
  s01('S-01', '68:3'),
  s01Light('S-01-LIGHT', '103:3277'),
  s02('S-02', '68:207'),
  s02Light('S-02-LIGHT', '103:3306'),
  s03('S-03', '68:266'),
  s03Light('S-03-LIGHT', '103:3337'),
  s04('S-04', '68:342'),
  s04Light('S-04-LIGHT', '103:3349');

  const HasobjyFrameId(this.frameName, this.figmaNodeId);

  final String frameName;
  final String figmaNodeId;

  bool get isLight => frameName.endsWith('-LIGHT');
  String get baseName => frameName.replaceAll('-LIGHT', '');
  HasobjyFrameId get dark => fromFrameName(baseName)!;
  HasobjyFrameId withLight(bool light) =>
      fromFrameName('$baseName${light ? "-LIGHT" : ""}')!;

  static HasobjyFrameId? fromFrameName(String name) {
    for (final frame in values) {
      if (frame.frameName == name || frame.figmaNodeId == name) return frame;
    }
    return null;
  }
}

class HasobjyDesignPage extends StatelessWidget {
  const HasobjyDesignPage({
    super.key,
    required this.frameId,
    this.identity,
    this.onGoogleSignIn,
    this.onSignOut,
    this.working = false,
    this.error,
    this.referenceViewport = false,
    this.onOpenFrame,
    this.followSystemTheme = false,
  });

  final HasobjyFrameId frameId;
  final bool followSystemTheme;
  final GoogleIdentity? identity;
  final VoidCallback? onGoogleSignIn;
  final VoidCallback? onSignOut;
  final bool working;
  final String? error;
  final bool referenceViewport;
  final ValueChanged<HasobjyFrameId>? onOpenFrame;

  void _open(BuildContext context, HasobjyFrameId next, {bool? light}) {
    next = next.withLight(light ?? frameId.isLight);
    if (onOpenFrame != null) {
      onOpenFrame!(next);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HasobjyDesignPage(
          frameId: next,
          identity: identity,
          onGoogleSignIn: onGoogleSignIn,
          onSignOut: onSignOut,
          referenceViewport: referenceViewport,
        ),
      ),
    );
  }

  void _showPreviewOnly(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).designPreviewNotice)),
    );
  }

  @override
  Widget build(BuildContext context) {
    void back() => Navigator.of(context).maybePop();
    final effective = followSystemTheme
        ? frameId.withLight(Theme.of(context).brightness == Brightness.light)
        : frameId;
    final actions = PreviewActions(
      open: (name) {
        final explicitDark = name.endsWith('-DARK');
        final next = HasobjyFrameId.fromFrameName(name.replaceAll('-DARK', ''));
        if (next != null) {
          _open(
            context,
            next,
            light: explicitDark
                ? false
                : name.endsWith('-LIGHT')
                ? true
                : effective.isLight,
          );
        }
      },
      notice: () => _showPreviewOnly(context),
      back: back,
    );
    final page = switch (effective.dark) {
      HasobjyFrameId.aS01 => HasobjyWelcomeScreen(
        onGoogleSignIn: onGoogleSignIn,
        working: working,
        error: error,
      ),
      HasobjyFrameId.aS03 => HasobjyUsageTypeScreen(
        onContinue: () => _open(context, HasobjyFrameId.aS04),
        onUnsupportedCoursesOnly: () => _showPreviewOnly(context),
      ),
      HasobjyFrameId.aS04 => HasobjyBasicInfoScreen(
        identity: identity,
        onContinue: () => _open(context, HasobjyFrameId.bS01),
        onBack: back,
      ),
      HasobjyFrameId.aS05 => HasobjyDeviceConflictScreen(
        onRequestTransfer: () => _open(context, HasobjyFrameId.aS06),
        onSignOut: onSignOut ?? back,
      ),
      HasobjyFrameId.aS06 => HasobjyDeviceTransferScreen(
        onSubmit: () {
          _showPreviewOnly(context);
          _open(context, HasobjyFrameId.aS07);
        },
        onBack: back,
      ),
      HasobjyFrameId.aS07 => HasobjyTransferStatusScreen(
        onContactSupport: () => _showPreviewOnly(context),
        onSignOut: onSignOut ?? back,
      ),
      HasobjyFrameId.bS01 => HasobjyAcademicInfoScreen(
        onContinue: () => _open(context, HasobjyFrameId.bS03),
        onBack: back,
      ),
      HasobjyFrameId.bS03 => HasobjyRegistrationSummaryScreen(
        onConfirm: () => _showPreviewOnly(context),
        onEdit: back,
        onBack: back,
      ),
      HasobjyFrameId.bS04 => HasobjyNewTermScreen(
        onConfirm: () => _showPreviewOnly(context),
        onChangeDetails: () => _showPreviewOnly(context),
      ),
      HasobjyFrameId.bS05 => const HasobjyTermStatesScreen(),
      HasobjyFrameId.bS06 => HasobjyExamScheduleScreen(
        onBack: back,
        onUnsupportedSupplementary: () => _showPreviewOnly(context),
      ),
      _ => switch (effective.baseName.substring(0, 1)) {
        'A' => AccountPreviewScreen(
          frame: effective.baseName,
          actions: actions,
        ),
        'S' => ProfilePreviewScreen(
          frame: effective.baseName,
          actions: actions,
        ),
        'C' => LearningPreviewScreen(
          frame: effective.baseName,
          actions: actions,
        ),
        'F' => PaymentPreviewScreen(
          frame: effective.baseName,
          actions: actions,
        ),
        'G' || 'H' => GradesSupportPreviewScreen(
          frame: effective.baseName,
          actions: actions,
        ),
        _ => SystemPreviewScreen(frame: effective.baseName, actions: actions),
      },
    };
    return HasobjyVisualScope(
      frameName: effective.frameName,
      child: referenceViewport ? HasobjyReferenceViewport(child: page) : page,
    );
  }
}
