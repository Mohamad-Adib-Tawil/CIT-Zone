import '../../../../core/errors/either.dart';
import '../../domain/student_catalog_error.dart';

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
  StudentCatalogReady(
    List<StudentCourse> courses, {
    this.refreshing = false,
    this.error,
  }) : courses = List.unmodifiable(courses);

  final List<StudentCourse> courses;
  final bool refreshing;
  final String? error;
}

class StudentCatalogFailure extends StudentCatalogState {
  const StudentCatalogFailure(this.failure);

  final StudentCatalogError failure;
}

class StudentCatalogCubit extends Cubit<StudentCatalogState> {
  StudentCatalogCubit(this._repository) : super(const StudentCatalogLoading());

  final StudentRepository _repository;
  bool _inFlight = false;

  Future<void> load() async {
    if (isClosed || _inFlight) return;
    _inFlight = true;
    final previous = state;
    if (previous case StudentCatalogReady(:final courses)) {
      emit(StudentCatalogReady(courses, refreshing: true));
    } else {
      emit(const StudentCatalogLoading());
    }

    try {
      final result = await _repository.loadCatalog();
      if (isClosed) return;
      emit(switch (result) {
        Right(:final value) => StudentCatalogReady(value),
        Left(value: final failure) => switch (previous) {
          StudentCatalogReady(:final courses) => StudentCatalogReady(
            courses,
            error: 'تعذر تحديث المواد التجريبية. حاول مجدداً.',
          ),
          _ => StudentCatalogFailure(failure),
        },
      });
    } finally {
      _inFlight = false;
    }
  }
}
