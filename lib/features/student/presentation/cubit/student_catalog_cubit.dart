import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/student_models.dart';
import '../../domain/student_repository.dart';

sealed class StudentCatalogState {
  const StudentCatalogState();
}

class StudentCatalogLoading extends StudentCatalogState {
  const StudentCatalogLoading();
}

class StudentCatalogReady extends StudentCatalogState {
  const StudentCatalogReady(
    this.courses, {
    this.refreshing = false,
    this.error,
  });

  final List<StudentCourse> courses;
  final bool refreshing;
  final String? error;
}

class StudentCatalogFailure extends StudentCatalogState {
  const StudentCatalogFailure();
}

class StudentCatalogCubit extends Cubit<StudentCatalogState> {
  StudentCatalogCubit(this._repository) : super(const StudentCatalogLoading());

  final StudentRepository _repository;
  bool _inFlight = false;

  Future<void> load() async {
    if (_inFlight) return;
    _inFlight = true;
    final previous = state;
    if (previous case StudentCatalogReady(:final courses)) {
      emit(StudentCatalogReady(courses, refreshing: true));
    } else {
      emit(const StudentCatalogLoading());
    }

    try {
      final courses = await _repository.loadCatalog();
      if (!isClosed) emit(StudentCatalogReady(courses));
    } catch (_) {
      if (!isClosed) {
        if (previous case StudentCatalogReady(:final courses)) {
          emit(
            StudentCatalogReady(
              courses,
              error: 'تعذر تحديث المواد التجريبية. حاول مجدداً.',
            ),
          );
        } else {
          emit(const StudentCatalogFailure());
        }
      }
    } finally {
      _inFlight = false;
    }
  }
}
