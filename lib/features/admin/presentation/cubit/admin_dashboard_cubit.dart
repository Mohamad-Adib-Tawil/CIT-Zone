import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/admin_models.dart';
import '../../domain/admin_repository.dart';

sealed class AdminDashboardState {
  const AdminDashboardState();
}

class AdminDashboardLoading extends AdminDashboardState {
  const AdminDashboardLoading();
}

class AdminDashboardReady extends AdminDashboardState {
  const AdminDashboardReady(this.data, {this.refreshing = false, this.error});

  final AdminDashboardData data;
  final bool refreshing;
  final String? error;
}

class AdminDashboardFailure extends AdminDashboardState {
  const AdminDashboardFailure();
}

class AdminDashboardCubit extends Cubit<AdminDashboardState> {
  AdminDashboardCubit(this._repository) : super(const AdminDashboardLoading());

  final AdminRepository _repository;
  bool _requestInFlight = false;

  Future<void> load() async {
    if (_requestInFlight) return;
    _requestInFlight = true;
    final previous = state;
    if (previous case AdminDashboardReady(:final data)) {
      emit(AdminDashboardReady(data, refreshing: true));
    } else {
      emit(const AdminDashboardLoading());
    }

    try {
      final data = await _repository.loadDashboard();
      if (!isClosed) emit(AdminDashboardReady(data));
    } catch (_) {
      if (!isClosed) {
        if (previous case AdminDashboardReady(:final data)) {
          emit(
            AdminDashboardReady(
              data,
              error: 'تعذر تحديث البيانات. حاول مجدداً.',
            ),
          );
        } else {
          emit(const AdminDashboardFailure());
        }
      }
    } finally {
      _requestInFlight = false;
    }
  }
}
