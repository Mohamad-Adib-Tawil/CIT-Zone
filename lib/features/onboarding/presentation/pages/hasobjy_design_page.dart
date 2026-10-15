import 'package:flutter/material.dart';

import '../../../auth/domain/google_identity.dart';
import 'hasobjy_academic_screens.dart';
import 'hasobjy_auth_screens.dart';
import 'hasobjy_device_screens.dart';

enum HasobjyFrameId {
  aS01('A-S01', '9:2'),
  aS03('A-S03', '9:15'),
  aS04('A-S04', '9:34'),
  aS05('A-S05', '9:65'),
  aS06('A-S06', '9:81'),
  aS07('A-S07', '9:101'),
  bS01('B-S01', '10:2'),
  bS03('B-S03', '10:40'),
  bS04('B-S04', '10:69'),
  bS05('B-S05', '10:92'),
  bS06('B-S06', '10:115');

  const HasobjyFrameId(this.frameName, this.figmaNodeId);

  final String frameName;
  final String figmaNodeId;

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
  });

  final HasobjyFrameId frameId;
  final GoogleIdentity? identity;
  final VoidCallback? onGoogleSignIn;
  final VoidCallback? onSignOut;
  final bool working;
  final String? error;

  void _open(BuildContext context, HasobjyFrameId next) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HasobjyDesignPage(
          frameId: next,
          identity: identity,
          onGoogleSignIn: onGoogleSignIn,
          onSignOut: onSignOut,
        ),
      ),
    );
  }

  void _showPreviewOnly(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('هذه معاينة تصميم؛ لا يتصل التطبيق بخادم أو يحفظ طلباً.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    void back() => Navigator.of(context).maybePop();
    return switch (frameId) {
      HasobjyFrameId.aS01 => HasobjyWelcomeScreen(
        onGoogleSignIn: onGoogleSignIn ?? () {},
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
      HasobjyFrameId.bS06 => HasobjyExamScheduleScreen(onBack: back),
    };
  }
}
