import 'dart:async';

import 'package:cit_zone/core/errors/either.dart';
import 'package:cit_zone/features/auth/domain/student_session_repository.dart';
import 'package:cit_zone/features/onboarding/presentation/cubit/student_learning_data_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DateTime now;
  late StudentLearningCache cache;

  setUp(() {
    now = DateTime.utc(2026, 11, 14);
    cache = StudentLearningCache(now: () => now);
  });

  test(
    'returning shows fresh data immediately without a second request',
    () async {
      var requests = 0;
      Future<Either<StudentSessionFailure, String>> load() async {
        requests++;
        return const Right('home');
      }

      final first = StudentLearningDataCubit(cache, 'home', load);
      await first.load();
      await first.close();

      final reopened = StudentLearningDataCubit(cache, 'home', load);
      addTearDown(reopened.close);
      expect(reopened.state.data, 'home');
      await reopened.load();
      expect(requests, 1);
    },
  );

  test(
    'stale data stays visible during one shared refresh and network failure',
    () async {
      await cache.refresh(
        'home',
        () async => const Right<StudentSessionFailure, String>('old'),
      );
      now = now.add(const Duration(seconds: 21));

      var requests = 0;
      final pending = Completer<Either<StudentSessionFailure, String>>();
      Future<Either<StudentSessionFailure, String>> load() {
        requests++;
        return pending.future;
      }

      final first = StudentLearningDataCubit(cache, 'home', load);
      final second = StudentLearningDataCubit(cache, 'home', load);
      addTearDown(first.close);
      addTearDown(second.close);
      final firstLoad = first.load();
      final secondLoad = second.load();
      expect(first.state.data, 'old');
      expect(second.state.data, 'old');
      expect(first.state.working, isTrue);
      expect(requests, 1);
      pending.complete(const Left(StudentSessionFailure.unavailable));
      await Future.wait([firstLoad, secondLoad]);
      expect(first.state.data, 'old');
      expect(second.state.data, 'old');
    },
  );

  test(
    'denial drops the snapshot and expiration clears the session cache',
    () async {
      Future<Either<StudentSessionFailure, String>> success() async =>
          const Right('data');
      await cache.refresh('home', success);
      await cache.refresh('profile', success);

      final cubit = StudentLearningDataCubit(
        cache,
        'profile',
        () async => const Left<StudentSessionFailure, String>(
          StudentSessionFailure.learningDataDenied,
        ),
      );
      addTearDown(cubit.close);
      await cubit.load(force: true);
      expect(cubit.state.data, isNull);
      expect(cache.read<String>('home'), 'data');

      await cache.refresh(
        'subject',
        () async => const Left<StudentSessionFailure, String>(
          StudentSessionFailure.expired,
        ),
      );
      expect(cache.read<String>('home'), isNull);
    },
  );

  test(
    'invalidation prevents an in-flight response from restoring edited data',
    () async {
      final pending = Completer<Either<StudentSessionFailure, String>>();
      final stale = cache.refresh('profile', () => pending.future);
      cache.invalidate('profile');
      await cache.refresh(
        'profile',
        () async => const Right<StudentSessionFailure, String>('updated'),
      );
      pending.complete(const Right('old'));
      expect((await stale).isLeft(), isTrue);
      expect(cache.read<String>('profile'), 'updated');
    },
  );

  test(
    'page keys and cache instances are isolated and entries expire',
    () async {
      const key = ('courses', true, 2);
      await cache.refresh(
        key,
        () async => const Right<StudentSessionFailure, String>('page'),
      );
      expect(cache.read<String>(('courses', false, 2)), isNull);
      expect(cache.read<String>(('courses', true, 1)), isNull);
      expect(StudentLearningCache().read<String>(key), isNull);
      now = now.add(const Duration(minutes: 5));
      expect(cache.read<String>(key), isNull);
    },
  );
}
