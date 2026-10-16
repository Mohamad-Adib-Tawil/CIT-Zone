import 'package:cit_zone/core/localization/generated/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../../auth/domain/google_identity.dart';
import '../theme/hasobjy_design_tokens.dart';
import '../widgets/hasobjy_figma_components.dart';

class HasobjyWelcomeScreen extends StatelessWidget {
  const HasobjyWelcomeScreen({
    super.key,
    required this.onGoogleSignIn,
    required this.working,
    this.error,
  });

  final VoidCallback? onGoogleSignIn;
  final bool working;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return HasobjyFigmaFrame(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          children: [
            const Spacer(),
            const SizedBox(height: 16),
            const SizedBox(
              width: 104,
              height: 104,
              child: Align(
                alignment: Alignment.topLeft,
                child: HasobjySvg('902ed', width: 96, height: 96),
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 80),
              child: Center(
                child: Text(
                  AppLocalizations.of(context).designWelcomeTitle,
                  textAlign: TextAlign.center,
                  style: HasobjyDesignTokens.display,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 78),
              child: Text(
                AppLocalizations.of(context).designWelcomeDescription,
                textAlign: TextAlign.center,
                style: HasobjyDesignTokens.bodyLarge,
              ),
            ),
            const SizedBox(height: 16),
            const Spacer(),
            const SizedBox(height: 16),
            HasobjyButton(
              label: AppLocalizations.of(context).continueViaGoogle,
              primary: false,
              onPressed: working ? null : onGoogleSignIn,
              icon: const HasobjySvg('96346', width: 24, height: 24),
              cornerLine: '84987',
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).termsConsent,
              textAlign: TextAlign.center,
              style: HasobjyDesignTokens.bodySmall,
            ),
            if (error != null) ...[
              const SizedBox(height: 4),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: HasobjyDesignTokens.bodySmall.copyWith(
                  color: const Color(0xFFFFA6A6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class HasobjyUsageTypeScreen extends StatefulWidget {
  const HasobjyUsageTypeScreen({
    super.key,
    required this.onContinue,
    this.onUnsupportedCoursesOnly,
  });

  final VoidCallback onContinue;
  final VoidCallback? onUnsupportedCoursesOnly;

  @override
  State<HasobjyUsageTypeScreen> createState() => _HasobjyUsageTypeScreenState();
}

class _HasobjyUsageTypeScreenState extends State<HasobjyUsageTypeScreen> {
  bool _institute = true;

  @override
  Widget build(BuildContext context) {
    return HasobjyFigmaFrame(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppLocalizations.of(context).usageQuestion,
              textAlign: TextAlign.right,
              style: HasobjyDesignTokens.title,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).usageExplanation,
              textAlign: TextAlign.right,
              style: HasobjyDesignTokens.bodyMedium,
            ),
            const SizedBox(height: 16),
            HasobjySelectionOption(
              title: AppLocalizations.of(context).instituteStudent,
              subtitle: AppLocalizations.of(context)
                  .instituteStudentDescription,
              iconAsset: '4d691',
              selected: _institute,
              onTap: () => setState(() => _institute = true),
            ),
            const SizedBox(height: 16),
            HasobjySelectionOption(
              title: AppLocalizations.of(context).coursesOnly,
              subtitle: AppLocalizations.of(context).coursesOnlyDescription,
              iconAsset: 'dbeae',
              selected: !_institute,
              onTap: () => setState(() => _institute = false),
            ),
            const SizedBox(height: 16),
            const Spacer(),
            const SizedBox(height: 16),
            HasobjyButton(
              label: AppLocalizations.of(context).continueAction,
              onPressed: _institute
                  ? widget.onContinue
                  : widget.onUnsupportedCoursesOnly,
            ),
          ],
        ),
      ),
    );
  }
}

class HasobjyBasicInfoScreen extends StatefulWidget {
  const HasobjyBasicInfoScreen({
    super.key,
    required this.onContinue,
    required this.identity,
    this.onBack,
  });

  final VoidCallback onContinue;
  final GoogleIdentity? identity;
  final VoidCallback? onBack;

  @override
  State<HasobjyBasicInfoScreen> createState() => _HasobjyBasicInfoScreenState();
}

class _HasobjyBasicInfoScreenState extends State<HasobjyBasicInfoScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HasobjyFigmaFrame(
      appBarTitle: AppLocalizations.of(context).basicInfo,
      onBack: widget.onBack,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const HasobjyStepper(activeBars: 2),
            const SizedBox(height: 16),
            HasobjyFormField(
              label: AppLocalizations.of(context).officialName,
              hint: AppLocalizations.of(context).officialNameHint,
              iconAsset: '0699d',
              helper: AppLocalizations.of(context).officialNameHelper,
              controller: _nameController,
            ),
            const SizedBox(height: 16),
            HasobjyFormField(
              label: AppLocalizations.of(context).phoneNumber,
              hint: '09xx xxx xxx',
              iconAsset: 'bf992',
              mirrorIcon: true,
              helper: AppLocalizations.of(context).phoneHelper,
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 16),
            HasobjyFormField(
              label: AppLocalizations.of(context).emailAddress,
              hint: widget.identity?.email ?? 'name@gmail.com',
              iconAsset: '90d15',
              helper: AppLocalizations.of(context).googleEmailHelper,
              enabled: false,
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 16),
            const Spacer(),
            const SizedBox(height: 16),
            HasobjyButton(
              label: AppLocalizations.of(context).continueAction,
              onPressed: widget.onContinue,
            ),
          ],
        ),
      ),
    );
  }
}
