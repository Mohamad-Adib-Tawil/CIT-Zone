import 'package:cit_zone/core/localization/generated/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/either.dart';
import '../../domain/google_identity.dart';
import '../../domain/google_identity_failure.dart';
import '../../domain/google_identity_repository.dart';
import '../../domain/student_session_repository.dart';
import '../google_identity_messages.dart';

sealed class GoogleIdentityState {
  const GoogleIdentityState();
}

class GoogleIdentityIdle extends GoogleIdentityState {
  const GoogleIdentityIdle();
}

class GoogleIdentityWorking extends GoogleIdentityState {
  const GoogleIdentityWorking({this.identity, this.session});

  final GoogleIdentity? identity;
  final StudentSession? session;
}

class GoogleIdentityReady extends GoogleIdentityState {
  const GoogleIdentityReady(
    this.identity, {
    this.session,
    this.sessionFailure,
    this.error,
  });

  final GoogleIdentity identity;
  final StudentSession? session;
  final StudentSessionFailure? sessionFailure;
  final String? error;
}

class GoogleIdentityError extends GoogleIdentityState {
  const GoogleIdentityError(this.message);

  final String message;
}

class GoogleIdentityCubit extends Cubit<GoogleIdentityState> {
  GoogleIdentityCubit(
    this._repository, {
    required this.messages,
    this._sessions,
  }) : super(const GoogleIdentityIdle());

  final AppLocalizations messages;

  final GoogleIdentityRepository _repository;
  final StudentSessionRepository? _sessions;
  bool _explicitSignIn = false;
  bool _recheckOnCompletion = false;

  bool get requiresStudentSession => _sessions != null;

  bool get isConfigured => _repository.isConfigured;

  Future<void> restore() async {
    if (isClosed || !isConfigured || state is! GoogleIdentityIdle) return;
    emit(const GoogleIdentityWorking());
    final result = await _repository.restoreIdentity();
    if (isClosed) return;
    if (result case Right(value: final identity?)) {
      await _openSession(identity);
    } else {
      emit(const GoogleIdentityIdle());
    }
  }

  Future<void> signIn() async {
    if (isClosed ||
        state is GoogleIdentityWorking ||
        state is GoogleIdentityReady) {
      return;
    }
    emit(const GoogleIdentityWorking());
    final result = await _repository.signIn();
    if (isClosed) return;
    if (result case Right(value: final identity)) {
      _explicitSignIn = true;
      await _openSession(identity);
      return;
    }
    emit(switch (result) {
      Right() => const GoogleIdentityIdle(),
      Left(value: GoogleIdentityFailure.canceled) => const GoogleIdentityIdle(),
      Left(value: final failure) => GoogleIdentityError(
        googleIdentityFailureMessage(failure, messages),
      ),
    });
  }

  Future<void> _openSession(GoogleIdentity identity) async {
    final sessions = _sessions;
    if (sessions == null) {
      emit(GoogleIdentityReady(identity));
      return;
    }
    emit(GoogleIdentityWorking(identity: identity));
    final result = _explicitSignIn
        ? await sessions.start(identity)
        : await sessions.restore(identity);
    _emitSession(identity, result);
  }

  Future<void> retrySession() async {
    final previous = state;
    if (isClosed ||
        previous is! GoogleIdentityReady ||
        previous.sessionFailure == null) {
      return;
    }
    await _openSession(previous.identity);
  }

  Future<void> revalidateSession() async {
    final previous = state;
    final sessions = _sessions;
    if (isClosed || sessions == null) return;
    if (previous is GoogleIdentityWorking && previous.session != null) {
      _recheckOnCompletion = true;
      return;
    }
    if (previous is! GoogleIdentityReady || previous.session == null) return;
    emit(GoogleIdentityWorking(identity: previous.identity));
    _emitSession(previous.identity, await sessions.read(previous.identity));
  }

  Future<void> chooseUsageType(StudentUsageType value) => _submit(
    StudentNextStep.chooseUsageType,
    (sessions, identity) => sessions.setUsageType(identity, value),
  );

  Future<void> saveBasicInfo(String officialName, String phone) => _submit(
    StudentNextStep.completeBasicInfo,
    (sessions, identity) => sessions.setBasicInfo(
      identity,
      officialName: officialName,
      phone: phone,
    ),
  );

  Future<void> confirmRegistration() => _submit(
    StudentNextStep.completeRegistration,
    (sessions, identity) => sessions.confirmRegistration(identity),
  );

  Future<void> confirmNewTerm() => _submit(
    StudentNextStep.confirmNewTerm,
    (sessions, identity) => sessions.confirmNewTerm(identity),
  );

  Future<void> _submit(
    StudentNextStep step,
    Future<Either<StudentSessionFailure, StudentSession>> Function(
      StudentSessionRepository,
      GoogleIdentity,
    )
    save,
  ) async {
    final previous = state;
    final sessions = _sessions;
    if (isClosed ||
        sessions == null ||
        previous is! GoogleIdentityReady ||
        previous.session?.next != step) {
      return;
    }
    final identity = previous.identity;
    emit(GoogleIdentityWorking(identity: identity, session: previous.session));
    var result = await save(sessions, identity);
    if (isClosed) return;
    if (_recheckOnCompletion) {
      _recheckOnCompletion = false;
      result = await sessions.read(identity);
    }
    if (result case Left(value: final failure)
        when failure == StudentSessionFailure.invalidBasicInfo ||
            failure == StudentSessionFailure.phoneTaken) {
      emit(
        GoogleIdentityReady(
          identity,
          session: previous.session,
          sessionFailure: failure,
        ),
      );
    } else {
      _emitSession(identity, result);
    }
  }

  void _emitSession(
    GoogleIdentity identity,
    Either<StudentSessionFailure, StudentSession?> result,
  ) {
    if (isClosed) return;
    emit(switch (result) {
      Right(value: final session?) => GoogleIdentityReady(
        identity,
        session: session,
      ),
      Right() ||
      Left(value: StudentSessionFailure.expired) => const GoogleIdentityIdle(),
      Left(:final value) => GoogleIdentityReady(
        identity,
        sessionFailure: value,
      ),
    });
  }

  Future<void> signOut() async {
    final previous = state;
    if (isClosed || previous is! GoogleIdentityReady) return;
    emit(GoogleIdentityWorking(identity: previous.identity));
    final ended = await _sessions?.end(previous.identity);
    if (isClosed) return;
    if (ended is Left) {
      emit(
        GoogleIdentityReady(
          previous.identity,
          sessionFailure: StudentSessionFailure.unavailable,
          error: messages.googleSignOutFailed,
        ),
      );
      return;
    }
    final result = await _repository.signOut();
    if (isClosed) return;
    emit(switch (result) {
      Right() => const GoogleIdentityIdle(),
      Left() => GoogleIdentityReady(
        previous.identity,
        error: messages.googleSignOutFailed,
      ),
    });
  }
}
