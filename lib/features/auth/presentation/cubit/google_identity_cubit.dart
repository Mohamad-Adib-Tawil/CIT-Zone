import 'package:cit_zone/core/localization/generated/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../domain/google_identity.dart';
import '../../domain/google_identity_failure.dart';
import '../../domain/google_identity_repository.dart';
import '../google_identity_messages.dart';

sealed class GoogleIdentityState {
  const GoogleIdentityState();
}

class GoogleIdentityIdle extends GoogleIdentityState {
  const GoogleIdentityIdle();
}

class GoogleIdentityWorking extends GoogleIdentityState {
  const GoogleIdentityWorking({this.identity});

  final GoogleIdentity? identity;
}

class GoogleIdentityReady extends GoogleIdentityState {
  const GoogleIdentityReady(this.identity, {this.error});

  final GoogleIdentity identity;
  final String? error;
}

class GoogleIdentityError extends GoogleIdentityState {
  const GoogleIdentityError(this.message);

  final String message;
}

class GoogleIdentityCubit extends Cubit<GoogleIdentityState> {
  GoogleIdentityCubit(this._repository, {required this.messages})
    : super(const GoogleIdentityIdle());

  final AppLocalizations messages;

  final GoogleIdentityRepository _repository;

  bool get isConfigured => _repository.isConfigured;

  Future<void> restore() async {
    if (!isConfigured || state is! GoogleIdentityIdle) return;
    emit(const GoogleIdentityWorking());
    final result = await _repository.restoreIdentity();
    if (isClosed) return;
    emit(switch (result) {
      Success(:final value) when value != null => GoogleIdentityReady(value),
      _ => const GoogleIdentityIdle(),
    });
  }

  Future<void> signIn() async {
    if (state is GoogleIdentityWorking || state is GoogleIdentityReady) return;
    emit(const GoogleIdentityWorking());
    final result = await _repository.signIn();
    if (isClosed) return;
    emit(switch (result) {
      Success(:final value) => GoogleIdentityReady(value),
      Failure(failure: GoogleIdentityFailure.canceled) =>
        const GoogleIdentityIdle(),
      Failure(:final failure) => GoogleIdentityError(
        googleIdentityFailureMessage(failure, messages),
      ),
    });
  }

  Future<void> signOut() async {
    final previous = state;
    if (previous is! GoogleIdentityReady) return;
    emit(GoogleIdentityWorking(identity: previous.identity));
    final result = await _repository.signOut();
    if (isClosed) return;
    emit(switch (result) {
      Success() => const GoogleIdentityIdle(),
      Failure() => GoogleIdentityReady(
        previous.identity,
        error: messages.googleSignOutFailed,
      ),
    });
  }
}
