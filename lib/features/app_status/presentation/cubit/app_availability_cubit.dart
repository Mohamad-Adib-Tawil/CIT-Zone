import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/either.dart';
import '../../domain/app_availability.dart';
import '../../domain/app_availability_repository.dart';

sealed class AppAvailabilityState {
  const AppAvailabilityState();
}

final class AppAvailabilityLoading extends AppAvailabilityState {
  const AppAvailabilityLoading();
}

final class AppAvailabilityLoaded extends AppAvailabilityState {
  const AppAvailabilityLoaded(this.availability);
  final AppAvailability availability;
}

final class AppAvailabilityError extends AppAvailabilityState {
  const AppAvailabilityError(this.failure);
  final AppAvailabilityFailure failure;
}

class AppAvailabilityCubit extends Cubit<AppAvailabilityState> {
  AppAvailabilityCubit(this._repository)
    : super(const AppAvailabilityLoading());
  final AppAvailabilityRepository _repository;
  Future<void>? _checking;

  Future<void> check({bool background = false}) {
    if (isClosed) return Future<void>.value();
    return _checking ??= _check(background)
        .whenComplete(() => _checking = null);
  }

  Future<void> _check(bool background) async {
    final available = switch (state) {
      AppAvailabilityLoaded(
        availability: AppAvailability(kind: AppAvailabilityKind.available),
      ) =>
        true,
      _ => false,
    };
    if (!background || !available) emit(const AppAvailabilityLoading());
    final result = await _repository.check();
    if (!isClosed) {
      emit(switch (result) {
        Right(:final value) => AppAvailabilityLoaded(value),
        Left(value: final failure) => AppAvailabilityError(failure),
      });
    }
  }

  Future<bool> openStore() async {
    if (isClosed) return false;
    final current = state;
    if (current is! AppAvailabilityLoaded ||
        current.availability.kind != AppAvailabilityKind.updateRequired) {
      return false;
    }
    final url = current.availability.storeUrl;
    if (url == null || !isAppStoreUrl(url)) return false;
    return _repository.openStore(url);
  }

  @override
  Future<void> close() {
    _repository.cancel();
    return super.close();
  }
}
