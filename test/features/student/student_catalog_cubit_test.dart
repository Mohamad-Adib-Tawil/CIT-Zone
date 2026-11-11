import 'dart:async';

import 'package:cit_zone/core/errors/either.dart';
import 'package:cit_zone/features/student/domain/student_catalog_error.dart';
import 'package:cit_zone/features/student/domain/student_models.dart';
import 'package:cit_zone/features/student/domain/student_repository.dart';
import 'package:cit_zone/features/student/presentation/cubit/student_catalog_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

typedef CatalogResult = Either<StudentCatalogError, List<StudentCourse>>;

void main() {
  test(
    'concurrent loads deduplicate and late completion cannot emit after close',
    () async {
      final pending = Completer<CatalogResult>();
      final repository = _Repository(() => pending.future);
      final cubit = StudentCatalogCubit(repository);
      final loading = cubit.load();
      await cubit.load();
      expect(repository.calls, 1);
      await cubit.close();
      pending.complete(const Right([]));
      await loading;
      await cubit.load();
      expect(repository.calls, 1);
      expect(cubit.state, isA<StudentCatalogLoading>());
    },
  );

  test('failed refresh retains the previous list and retry recovers', () async {
    final repository = _Repository(() async => const Right([_course]));
    final cubit = StudentCatalogCubit(repository);
    addTearDown(cubit.close);
    await cubit.load();
    final pending = Completer<CatalogResult>();
    repository.operation = () => pending.future;
    final refresh = cubit.load();
    final refreshing = cubit.state as StudentCatalogReady;
    expect(refreshing.refreshing, isTrue);
    expect(refreshing.courses.single.id, _course.id);
    pending.complete(const Left(StudentCatalogError.unavailable));
    await refresh;
    final failed = cubit.state as StudentCatalogReady;
    expect(failed.refreshing, isFalse);
    expect(failed.courses.single.id, _course.id);
    expect(failed.error, isNotNull);
    repository.operation = () async => const Right([]);
    await cubit.load();
    final recovered = cubit.state as StudentCatalogReady;
    expect(recovered.courses, isEmpty);
    expect(recovered.error, isNull);
  });

  test('initial failure is typed and a subsequent load recovers', () async {
    final repository = _Repository(
      () async => const Left(StudentCatalogError.unavailable),
    );
    final cubit = StudentCatalogCubit(repository);
    addTearDown(cubit.close);
    await cubit.load();
    expect(
      (cubit.state as StudentCatalogFailure).failure,
      StudentCatalogError.unavailable,
    );
    repository.operation = () async => const Right([]);
    await cubit.load();
    expect((cubit.state as StudentCatalogReady).courses, isEmpty);
  });

  test(
    'a repository cannot mutate a list already published as state',
    () async {
      final courses = [_course];
      final cubit = StudentCatalogCubit(
        _Repository(() async => Right(courses)),
      );
      addTearDown(cubit.close);
      await cubit.load();
      courses.clear();
      final published = (cubit.state as StudentCatalogReady).courses;
      expect(published.single.id, _course.id);
      expect(published.clear, throwsUnsupportedError);
    },
  );
}

const _course = StudentCourse(
  id: 'preview',
  code: 'DEMO',
  title: 'معاينة',
  description: '',
  instructor: '',
  placements: [],
  lessons: [],
);

class _Repository implements StudentRepository {
  _Repository(this.operation);
  Future<CatalogResult> Function() operation;
  int calls = 0;

  @override
  Future<CatalogResult> loadCatalog() {
    calls++;
    return operation();
  }
}
