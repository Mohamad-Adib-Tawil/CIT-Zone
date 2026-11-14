import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/either.dart';
import '../../../auth/domain/student_session_repository.dart';

typedef StudentLearningDataState<T> = ({
  T? data,
  bool working,
  StudentSessionFailure? failure,
});

/// Owned by one authenticated learning shell and discarded with that shell.
final class StudentLearningCache {
  StudentLearningCache({DateTime Function()? now}) : _now = now ?? DateTime.now;

  static const _freshness = Duration(seconds: 20);
  static const _lifetime = Duration(minutes: 5);
  static const _capacity = 24;

  final DateTime Function() _now;
  final _entries = <Object, ({Object data, DateTime storedAt})>{};
  final _requests = <Object, ({Object token, Future<Object> result})>{};

  T? read<T extends Object>(Object key) {
    final entry = _entries.remove(key);
    if (entry == null || _now().difference(entry.storedAt) >= _lifetime) {
      return null;
    }
    _entries[key] = entry;
    return entry.data as T;
  }

  bool isFresh(Object key) {
    final entry = _entries[key];
    return entry != null && _now().difference(entry.storedAt) < _freshness;
  }

  void invalidate(Object key) {
    _entries.remove(key);
    _requests.remove(key);
  }

  void clear() {
    _entries.clear();
    _requests.clear();
  }

  Future<Either<StudentSessionFailure, T>> refresh<T extends Object>(
    Object key,
    Future<Either<StudentSessionFailure, T>> Function() request,
  ) async {
    final running = _requests[key];
    if (running != null) {
      return (await running.result) as Either<StudentSessionFailure, T>;
    }

    final revision = Object();
    final pending = Future.sync(request)
        .then(
          (result) {
            if (!identical(_requests[key]?.token, revision)) {
              return Left<StudentSessionFailure, T>(
                StudentSessionFailure.unavailable,
              );
            }
            switch (result) {
              case Right(:final value):
                _entries.remove(key);
                _entries[key] = (data: value, storedAt: _now());
                if (_entries.length > _capacity) {
                  _entries.remove(_entries.keys.first);
                }
              case Left(value: StudentSessionFailure.expired):
                clear();
              case Left(value: StudentSessionFailure.learningDataDenied):
                _entries.remove(key);
              case Left():
                break;
            }
            return result;
          },
          onError: (Object _) {
            return Left<StudentSessionFailure, T>(
              StudentSessionFailure.unavailable,
            );
          },
        )
        .whenComplete(() {
          if (identical(_requests[key]?.token, revision)) _requests.remove(key);
        });
    _requests[key] = (token: revision, result: pending);
    return pending;
  }
}

final class StudentLearningDataCubit<T extends Object>
    extends Cubit<StudentLearningDataState<T>> {
  StudentLearningDataCubit(this._cache, this._key, this._request)
    : super((data: _cache.read<T>(_key), working: false, failure: null));

  final StudentLearningCache _cache;
  final Object _key;
  final Future<Either<StudentSessionFailure, T>> Function() _request;

  Future<void> load({bool force = false}) async {
    if (isClosed || state.working || (!force && _cache.isFresh(_key))) return;
    emit((data: _cache.read<T>(_key), working: true, failure: null));
    final result = await _cache.refresh(_key, _request);
    if (isClosed) return;
    emit(switch (result) {
      Right(:final value) => (data: value, working: false, failure: null),
      Left(:final value) => (
        data: _cache.read<T>(_key),
        working: false,
        failure: value,
      ),
    });
  }
}
