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
  StudentLearningCache({DateTime Function()? now, this.onSessionRestricted})
    : _now = now ?? DateTime.now;

  final void Function(StudentSessionFailure)? onSessionRestricted;

  static const _freshness = Duration(seconds: 20);
  static const _lifetime = Duration(minutes: 5);
  static const _capacity = 24;
  static const _retryDelay = Duration(seconds: 5);

  final DateTime Function() _now;
  final _entries =
      <
        Object,
        ({
          Object data,
          DateTime storedAt,
          DateTime? retryAfter,
          bool needsRefresh,
        })
      >{};
  final _requests = <Object, ({Object token, Future<Object> result})>{};
  int _sessionRevision = 0;
  int get sessionRevision => _sessionRevision;
  final _restores = <Object, Object>{};

  Future<void> restore<T extends Object>(
    Object key,
    Future<({T data, DateTime storedAt})?> Function() readSnapshot,
  ) async {
    if (read<T>(key) != null) return;
    final token = Object();
    final session = _sessionRevision;
    _restores[key] = token;
    try {
      final snapshot = await readSnapshot().timeout(
        const Duration(milliseconds: 250),
      );
      if (snapshot == null ||
          session != _sessionRevision ||
          !identical(_restores[key], token) ||
          _entries.containsKey(key)) {
        return;
      }
      final age = _now().difference(snapshot.storedAt);
      if (age.isNegative || age >= _lifetime) return;
      _entries[key] = (
        data: snapshot.data,
        storedAt: snapshot.storedAt,
        retryAfter: null,
        needsRefresh: true,
      );
      if (_entries.length > _capacity) _entries.remove(_entries.keys.first);
    } catch (_) {
      // A local cache miss must not block the live request.
    } finally {
      if (identical(_restores[key], token)) _restores.remove(key);
    }
  }

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
    return entry != null &&
        !entry.needsRefresh &&
        _now().difference(entry.storedAt) < _freshness;
  }

  bool shouldRefresh(Object key) {
    final entry = _entries[key];
    if (entry == null) return true;
    final now = _now();
    final age = now.difference(entry.storedAt);
    if (age >= _lifetime) return true;
    if (!entry.needsRefresh && age < _freshness) return false;
    final retryAfter = entry.retryAfter;
    return retryAfter == null || !now.isBefore(retryAfter);
  }

  void _deferRefresh(Object key) {
    final entry = _entries[key];
    if (entry == null) return;
    final now = _now();
    if (now.difference(entry.storedAt) >= _lifetime) return;
    _entries[key] = (
      data: entry.data,
      storedAt: entry.storedAt,
      retryAfter: now.add(_retryDelay),
      needsRefresh: entry.needsRefresh,
    );
  }

  void refreshOnNextRead<T extends Object>(
    Object key, {
    T Function(T)? update,
  }) {
    _requests.remove(key);
    final entry = _entries[key];
    if (entry == null) return;
    _entries[key] = (
      data: update == null ? entry.data : update(entry.data as T),
      storedAt: entry.storedAt,
      retryAfter: null,
      needsRefresh: true,
    );
  }

  void invalidate(Object key) {
    _restores.remove(key);
    _entries.remove(key);
    _requests.remove(key);
  }

  void replace(Object key, Object data) {
    invalidate(key);
    _store(key, data);
  }

  void _store(Object key, Object data) {
    _entries.remove(key);
    _entries[key] = (
      data: data,
      storedAt: _now(),
      retryAfter: null,
      needsRefresh: false,
    );
    if (_entries.length > _capacity) {
      _entries.remove(_entries.keys.first);
    }
  }

  void clear() {
    _sessionRevision++;
    _entries.clear();
    _requests.clear();
    _restores.clear();
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
    final sessionRevision = _sessionRevision;
    final pending = Future.sync(request)
        .then(
          (result) {
            if (result case Left(value: final failure)
                when sessionRevision == _sessionRevision &&
                    (failure == StudentSessionFailure.accountSuspended ||
                        failure == StudentSessionFailure.deviceUnauthorized)) {
              clear();
              onSessionRestricted?.call(failure);
              return result;
            }
            if (result case Left(value: StudentSessionFailure.expired)
                when sessionRevision == _sessionRevision) {
              clear();
              return result;
            }
            if (!identical(_requests[key]?.token, revision)) {
              return Left<StudentSessionFailure, T>(
                StudentSessionFailure.unavailable,
              );
            }
            switch (result) {
              case Right(:final value):
                _store(key, value);
              case Left(value: StudentSessionFailure.learningDataDenied):
                _entries.remove(key);
              case Left(value: StudentSessionFailure.unavailable):
                _deferRefresh(key);
              case Left():
                break;
            }
            return result;
          },
          onError: (Object _) {
            if (identical(_requests[key]?.token, revision)) _deferRefresh(key);
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
  StudentLearningDataCubit(
    this._cache,
    this._key,
    this._request, {
    this.restore,
  }) : super((data: _cache.read<T>(_key), working: false, failure: null));

  final Future<({T data, DateTime storedAt})?> Function()? restore;
  final StudentLearningCache _cache;
  final Object _key;
  final Future<Either<StudentSessionFailure, T>> Function() _request;

  Future<void> load({bool force = false}) async {
    if (isClosed || state.working || (!force && !_cache.shouldRefresh(_key))) {
      return;
    }
    emit((data: _cache.read<T>(_key), working: true, failure: null));
    final revision = _cache.sessionRevision;
    if (restore case final readSnapshot? when state.data == null) {
      await _cache.restore<T>(_key, readSnapshot);
      if (isClosed) return;
      if (revision != _cache.sessionRevision) {
        emit((
          data: null,
          working: false,
          failure: StudentSessionFailure.expired,
        ));
        return;
      }
      emit((data: _cache.read<T>(_key), working: true, failure: null));
    }
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
