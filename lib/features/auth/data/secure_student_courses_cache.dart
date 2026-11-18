import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/student_courses_snapshot.dart';
import '../domain/student_learning.dart';
import 'secure_student_snapshot_store.dart';

/// Bounded catalog pages. Cached prices and badges never grant entitlements.
final class SecureStudentCoursesCache {
  SecureStudentCoursesCache(
    FlutterSecureStorage storage,
    String environment,
    this._decode,
  ) : _store = SecureStudentSnapshotStore(
        storage,
        environment,
        'courses',
        _maxBytes,
      );

  static const _maxBytes = 131072;
  static const _capacity = 24;
  final SecureStudentSnapshotStore _store;
  final StudentCourseItem Function(Object?) _decode;
  Future<void> _operations = Future.value();

  // A page write reads and replaces the account index as one ordered operation.
  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = _operations.then((_) => operation());
    _operations = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  Future<List<Map<String, dynamic>>> _entries(String owner) async {
    final json = await _store.read(owner);
    if (json case {'version': 1, 'pages': List pages}
        when pages.length <= _capacity) {
      if (pages.every((item) => item is Map<String, dynamic>)) {
        return pages.cast<Map<String, dynamic>>().toList();
      }
    }
    return [];
  }

  Future<StudentCoursesSnapshot?> read(
    String owner, {
    required bool mine,
    required int page,
  }) => _serialize(() async {
    if (page < 1) return null;
    try {
      final entries = await _entries(owner);
      for (final entry in entries.reversed) {
        if (entry['mine'] != mine || entry['page'] != page) continue;
        if (entry
            case {
              'storedAt': int timestamp,
              'courses': List courses,
              'hasMore': bool hasMore,
            }
            when courses.length <= 20) {
          return (
            data: (
              courses: List<StudentCourseItem>.unmodifiable(
                courses.map(_decode),
              ),
              hasMore: hasMore,
            ),
            storedAt: DateTime.fromMillisecondsSinceEpoch(
              timestamp,
              isUtc: true,
            ),
          );
        }
        return null;
      }
    } catch (_) {
      // Any invalid page is a miss, never a partially decoded catalog.
    }
    return null;
  });

  Future<void> write(
    String owner,
    StudentCoursePageData data, {
    required bool mine,
    required int page,
  }) => _serialize(() async {
    if (page < 1 || data.courses.length > 20) return;
    final entries = await _entries(owner);
    entries.removeWhere(
      (entry) => entry['mine'] == mine && entry['page'] == page,
    );
    final entry = <String, Object?>{
      'mine': mine,
      'page': page,
      'storedAt': DateTime.now().toUtc().millisecondsSinceEpoch,
      'hasMore': data.hasMore,
      'courses': [
        for (final course in data.courses)
          {
            'id': course.id,
            'name': course.name,
            'description': course.description,
            'priceUsd': course.priceUsd,
            'durationDays': course.durationDays,
            'subscribed': course.subscribed,
          },
      ],
    };
    if (utf8
            .encode(
              jsonEncode({
                'version': 1,
                'pages': [entry],
              }),
            )
            .length >
        _maxBytes) {
      await _store.write(owner, {'version': 1, 'pages': entries});
      return;
    }
    entries.add(entry);
    while (entries.length > _capacity) {
      entries.removeAt(0);
    }
    Map<String, Object?> envelope() => {'version': 1, 'pages': entries};
    while (entries.length > 1 &&
        utf8.encode(jsonEncode(envelope())).length > _maxBytes) {
      entries.removeAt(0);
    }
    await _store.write(owner, envelope());
  });

  Future<void> clear(String owner) => _serialize(() => _store.clear(owner));
}
