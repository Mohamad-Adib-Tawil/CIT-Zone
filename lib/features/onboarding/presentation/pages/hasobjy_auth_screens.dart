import 'package:cit_zone/core/localization/generated/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../../auth/domain/google_identity.dart';
import '../theme/hasobjy_visual_scope.dart';
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
        padding: EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          children: [
            Spacer(),
            SizedBox(height: 16),
            SizedBox(
              width: 150,
              height: 150,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: -19.38,
                    top: -.255,
                    width: 195.188,
                    height: 186.688,
                    child: Image.asset('assets/hasobjy/e2776.png'),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: 80),
              child: Center(
                child: Text(
                  AppLocalizations.of(context).designWelcomeTitle,
                  textAlign: TextAlign.center,
                  style: context.design.display,
                ),
              ),
            ),
            SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: 78),
              child: Text(
                AppLocalizations.of(context).designWelcomeDescription,
                textAlign: TextAlign.center,
                style: context.design.bodyLarge,
              ),
            ),
            SizedBox(height: 16),
            Spacer(),
            SizedBox(height: 16),
            HasobjyButton(
              label: AppLocalizations.of(context).continueViaGoogle,
              primary: false,
              onPressed: working ? null : onGoogleSignIn,
              icon: HasobjySvg('96346', width: 24, height: 24),
              cornerLine: '84987',
            ),
            SizedBox(height: 16),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'بالمتابعة فأنت توافق على '),
                  TextSpan(
                    text: 'الشروط والأحكام',
                    style: TextStyle(
                      color: context.design.brand,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const TextSpan(text: ' و'),
                  TextSpan(
                    text: 'سياسة الخصوصية',
                    style: TextStyle(
                      color: context.design.brand,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              style: context.design.bodySmall,
            ),
            if (error != null) ...[
              SizedBox(height: 4),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: context.design.bodySmall.copyWith(
                  color: Color(0xFFFFA6A6),
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
        padding: EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppLocalizations.of(context).usageQuestion,
              textAlign: TextAlign.right,
              style: context.design.title,
            ),
            SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).usageExplanation,
              textAlign: TextAlign.right,
              style: context.design.bodyMedium,
            ),
            SizedBox(height: 16),
            HasobjySelectionOption(
              title: AppLocalizations.of(context).instituteStudent,
              subtitle: AppLocalizations.of(context)
                  .instituteStudentDescription,
              iconAsset: '4d691',
              selected: _institute,
              onTap: () => setState(() => _institute = true),
            ),
            SizedBox(height: 16),
            HasobjySelectionOption(
              title: AppLocalizations.of(context).coursesOnly,
              subtitle: AppLocalizations.of(context).coursesOnlyDescription,
              iconAsset: 'dbeae',
              selected: !_institute,
              onTap: () => setState(() => _institute = false),
            ),
            SizedBox(height: 16),
            Spacer(),
            SizedBox(height: 16),
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
    this.showStepper = true,
    this.continueLabel,
  });

  final VoidCallback onContinue;
  final GoogleIdentity? identity;
  final VoidCallback? onBack;
  final bool showStepper;
  final String? continueLabel;

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
        padding: EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showStepper) ...[
              HasobjyStepper(activeBars: 2),
              SizedBox(height: 16),
            ],
            HasobjyFormField(
              label: AppLocalizations.of(context).officialName,
              hint: AppLocalizations.of(context).officialNameHint,
              iconAsset: '0699d',
              helper: AppLocalizations.of(context).officialNameHelper,
              controller: _nameController,
            ),
            SizedBox(height: 16),
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
            SizedBox(height: 16),
            HasobjyFormField(
              label: AppLocalizations.of(context).emailAddress,
              hint: widget.identity?.email ?? 'name@gmail.com',
              iconAsset: '90d15',
              helper: AppLocalizations.of(context).googleEmailHelper,
              enabled: false,
              textDirection: TextDirection.ltr,
            ),
            SizedBox(height: 16),
            Spacer(),
            SizedBox(height: 16),
            HasobjyButton(
              label:
                  widget.continueLabel ??
                  AppLocalizations.of(context).continueAction,
              onPressed: widget.onContinue,
            ),
          ],
        ),
      ),
    );
  }
}
