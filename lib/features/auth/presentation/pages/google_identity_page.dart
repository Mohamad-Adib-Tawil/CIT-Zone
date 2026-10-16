import 'package:cit_zone/core/localization/generated/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../domain/google_identity.dart';

class GoogleIdentityPage extends StatelessWidget {
  const GoogleIdentityPage({
    super.key,
    required this.identity,
    required this.onSignOut,
    this.onStudentPreview,
    this.error,
  });

  final GoogleIdentity identity;
  final VoidCallback onSignOut;
  final VoidCallback? onStudentPreview;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final name = identity.displayName?.trim().isNotEmpty == true
        ? identity.displayName!.trim()
        : AppLocalizations.of(context).googleAccount;
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).googleIdentity)),
      body: Center(
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
                      Text(name, style: Theme.of(context).textTheme.titleLarge),
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
                        AppLocalizations.of(context).identityPendingDescription,
                      ),
                    ],
                  ),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              if (onStudentPreview != null) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: onStudentPreview,
                  icon: const Icon(Icons.phone_android_rounded),
                  label: Text(AppLocalizations.of(context).studentPreview),
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
    );
  }
}
