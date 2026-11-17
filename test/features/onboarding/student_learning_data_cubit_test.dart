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

  test('a confirmed update takes precedence over a pending read', () async {
    final pending = Completer<Either<StudentSessionFailure, String>>();
    final read = cache.refresh('profile', () => pending.future);

    cache.replace('profile', 'confirmed');
    pending.complete(const Right('old profile'));

    expect((await read).isLeft(), isTrue);
    expect(cache.read<String>('profile'), 'confirmed');
    expect(cache.isFresh('profile'), isTrue);
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

  test('rapid reentry uses stale data until the refresh delay ends', () async {
    await cache.refresh('home', () async => const Right('cached'));
    now = now.add(const Duration(seconds: 21));
    var requests = 0;
    var connected = false;
    Future<Either<StudentSessionFailure, String>> request() async {
      requests++;
      return connected
          ? const Right('updated')
          : const Left(StudentSessionFailure.unavailable);
    }

    final first = StudentLearningDataCubit(cache, 'home', request);
    await first.load();
    await first.close();
    expect(requests, 1);

    connected = true;
    final reopened = StudentLearningDataCubit(cache, 'home', request);
    addTearDown(reopened.close);
    await reopened.load();
    expect(reopened.state.data, 'cached');
    expect(requests, 1);

    now = now.add(const Duration(seconds: 5));
    await reopened.load();
    expect(reopened.state.data, 'updated');
    expect(requests, 2);
  });

  test(
    'manual retries and expired snapshots bypass the refresh delay',
    () async {
      await cache.refresh('home', () async => const Right('cached'));
      now = now.add(const Duration(minutes: 4, seconds: 58));
      var requests = 0;
      final cubit = StudentLearningDataCubit<String>(cache, 'home', () async {
        requests++;
        return const Left(StudentSessionFailure.unavailable);
      });
      addTearDown(cubit.close);
      await cubit.load();
      expect(cubit.state.data, 'cached');
      await cubit.load(force: true);
      expect(requests, 2);

      now = now.add(const Duration(seconds: 2));
      await cubit.load();
      expect(requests, 3);
      expect(cubit.state.data, isNull);
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
    'session restriction discards other cached and in-flight results',
    () async {
      final restrictions = <StudentSessionFailure>[];
      final restrictedCache = StudentLearningCache(
        now: () => now,
        onSessionRestricted: restrictions.add,
      );
      await restrictedCache.refresh(
        'home',
        () async => const Right<StudentSessionFailure, String>('cached'),
      );
      final late = Completer<Either<StudentSessionFailure, String>>();
      final loading = restrictedCache.refresh('grades', () => late.future);
      await restrictedCache.refresh(
        'lesson',
        () async => const Left<StudentSessionFailure, String>(
          StudentSessionFailure.accountSuspended,
        ),
      );
      late.complete(const Right('private result'));
      expect((await loading).isLeft(), isTrue);
      expect(restrictedCache.read<String>('home'), isNull);
      expect(restrictedCache.read<String>('grades'), isNull);
      expect(restrictions, [StudentSessionFailure.accountSuspended]);
    },
  );

  test('an invalidated read can still report a session restriction', () async {
    final restrictions = <StudentSessionFailure>[];
    final cache = StudentLearningCache(onSessionRestricted: restrictions.add);
    final pending = Completer<Either<StudentSessionFailure, String>>();
    final reading = cache.refresh('profile', () => pending.future);
    cache.replace('profile', 'updated');
    pending.complete(const Left(StudentSessionFailure.accountSuspended));

    expect(
      (await reading).match((failure) => failure, (_) => null),
      StudentSessionFailure.accountSuspended,
    );

    expect(restrictions, [StudentSessionFailure.accountSuspended]);
    expect(cache.read<String>('profile'), isNull);
  });

  test('clearing the cache ignores restrictions from old reads', () async {
    final restrictions = <StudentSessionFailure>[];
    final cache = StudentLearningCache(onSessionRestricted: restrictions.add);
    final pending = Completer<Either<StudentSessionFailure, String>>();
    final reading = cache.refresh('profile', () => pending.future);
    cache.clear();
    cache.replace('profile', 'current');
    pending.complete(const Left(StudentSessionFailure.deviceUnauthorized));

    expect((await reading).isLeft(), isTrue);
    expect(restrictions, isEmpty);
    expect(cache.read<String>('profile'), 'current');
  });

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
