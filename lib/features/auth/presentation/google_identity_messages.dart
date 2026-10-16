import 'package:cit_zone/core/localization/generated/app_localizations.dart';

import '../domain/google_identity_failure.dart';

String googleIdentityFailureMessage(
  GoogleIdentityFailure failure,
  AppLocalizations strings,
) => switch (failure) {
  GoogleIdentityFailure.unavailable => strings.googleUnavailable,
  GoogleIdentityFailure.missingToken => strings.googleMissingToken,
  GoogleIdentityFailure.canceled => '',
  GoogleIdentityFailure.unexpected => strings.googleUnexpected,
};
