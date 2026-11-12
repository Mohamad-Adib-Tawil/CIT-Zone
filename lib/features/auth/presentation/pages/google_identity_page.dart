import 'package:cit_zone/core/localization/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../domain/google_identity.dart';

class GoogleIdentityPage extends StatelessWidget {
  const GoogleIdentityPage({
    super.key,
    required this.identity,
    required this.onSignOut,
    this.onFigmaPreview,
    this.error,
  });

  final GoogleIdentity identity;
  final VoidCallback onSignOut;
  final VoidCallback? onFigmaPreview;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final name = identity.displayName?.trim().isNotEmpty == true
        ? identity.displayName!.trim()
        : AppLocalizations.of(context).googleAccount;
    final light = Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(AppLocalizations.of(context).googleIdentity),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/hasobjy/${light ? '6fb9e' : '1c591'}.svg',
              fit: BoxFit.fill,
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 34,
                              child: Text(name.characters.first),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 6),
                            SelectableText(
                              identity.email,
                              textDirection: TextDirection.ltr,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context).identityPendingTitle,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppLocalizations.of(context)
                                  .identityPendingDescription,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    if (onFigmaPreview != null) ...[
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: onFigmaPreview,
                        child: const Text('عرض شاشات Figma — دون خادم'),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: onSignOut,
                      icon: const Icon(Icons.logout_rounded),
                      label: Text(AppLocalizations.of(context).googleSignOut),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
