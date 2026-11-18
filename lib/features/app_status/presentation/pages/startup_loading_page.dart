import 'package:flutter/material.dart';

import '../../../../core/localization/generated/app_localizations.dart';
import '../../../onboarding/presentation/pages/hasobjy_auth_screens.dart';
import '../../../onboarding/presentation/theme/hasobjy_visual_scope.dart';

class StartupLoadingPage extends StatelessWidget {
  const StartupLoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    return HasobjyVisualScope(
      frameName: light ? 'A-S01-LIGHT' : 'A-S01',
      child: Semantics(
        label: AppLocalizations.of(context).loadingContent,
        liveRegion: true,
        child: const HasobjyWelcomeScreen(
          onGoogleSignIn: null,
          working: true,
          loading: true,
        ),
      ),
    );
  }
}
