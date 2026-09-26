import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/google_identity.dart';
import '../../domain/google_identity_gateway.dart';

sealed class GoogleIdentityState {
  const GoogleIdentityState();
}

class GoogleIdentityIdle extends GoogleIdentityState {
  const GoogleIdentityIdle();
}

class GoogleIdentityWorking extends GoogleIdentityState {
  const GoogleIdentityWorking();
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
  GoogleIdentityCubit(this._gateway) : super(const GoogleIdentityIdle());

  final GoogleIdentityGateway _gateway;

  bool get isConfigured => _gateway.isConfigured;

  Future<void> restore() async {
    if (!isConfigured || state is! GoogleIdentityIdle) return;
    emit(const GoogleIdentityWorking());
    try {
      final identity = await _gateway.restoreIdentity();
      if (isClosed) return;
      emit(
        identity == null
            ? const GoogleIdentityIdle()
            : GoogleIdentityReady(identity),
      );
    } catch (_) {
      if (!isClosed) emit(const GoogleIdentityIdle());
    }
  }

  Future<void> signIn() async {
    if (state is GoogleIdentityWorking || state is GoogleIdentityReady) return;
    emit(const GoogleIdentityWorking());
    try {
      final identity = await _gateway.authenticate();
      if (!isClosed) emit(GoogleIdentityReady(identity));
    } on GoogleIdentityException catch (error) {
      if (isClosed) return;
      if (error.failure == GoogleIdentityFailure.canceled) {
        emit(const GoogleIdentityIdle());
      } else {
        emit(GoogleIdentityError(_messageFor(error.failure)));
      }
    } catch (_) {
      if (!isClosed) {
        emit(
          const GoogleIdentityError('تعذر إكمال تسجيل Google. حاول مجدداً.'),
        );
      }
    }
  }

  Future<void> signOut() async {
    final previous = state;
    if (previous is! GoogleIdentityReady) return;
    emit(const GoogleIdentityWorking());
    try {
      await _gateway.signOut();
      if (!isClosed) emit(const GoogleIdentityIdle());
    } catch (_) {
      if (!isClosed) {
        emit(
          GoogleIdentityReady(
            previous.identity,
            error: 'تعذر تسجيل الخروج من Google. حاول مجدداً.',
          ),
        );
      }
    }
  }

  String _messageFor(GoogleIdentityFailure failure) => switch (failure) {
    GoogleIdentityFailure.unavailable =>
      'تسجيل Google غير مُهيأ لهذا الجهاز. راجع إعدادات OAuth.',
    GoogleIdentityFailure.missingToken =>
      'لم يصل إثبات الهوية المطلوب من Google. حاول مجدداً.',
    GoogleIdentityFailure.canceled => '',
    GoogleIdentityFailure.unexpected => 'تعذر إكمال تسجيل Google. حاول مجدداً.',
  };
}
