import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/student_learning.dart';
import '../domain/student_subjects_snapshot.dart';
import 'secure_student_snapshot_store.dart';

final class SecureStudentSubjectsCache {
  SecureStudentSubjectsCache(
    FlutterSecureStorage storage,
    String environment,
    this._decode,
  ) : _current = SecureStudentSnapshotStore(
        storage,
        environment,
        'subjects_current',
        65536,
      ),
      _previous = SecureStudentSnapshotStore(
        storage,
        environment,
        'subjects_previous',
        65536,
      );

  final SecureStudentSnapshotStore _current;
  final SecureStudentSnapshotStore _previous;
  final StudentSubjectItem Function(Object?) _decode;

  SecureStudentSnapshotStore _store(bool previous) =>
      previous ? _previous : _current;

  Future<StudentSubjectsSnapshot?> read(
    String owner, {
    required bool previous,
  }) async {
    try {
      final json = await _store(previous).read(owner);
      if (json case {
        'version': 1,
        'storedAt': int timestamp,
        'data': List items,
      }) {
        return (
          data: List<StudentSubjectItem>.unmodifiable(items.map(_decode)),
          storedAt: DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true),
        );
      }
    } catch (_) {
      // Invalid snapshots fall back to the authorized catalog request.
    }
    return null;
  }

  Future<void> write(
    String owner,
    List<StudentSubjectItem> items, {
    required bool previous,
  }) => _store(previous).write(owner, {
    'version': 1,
    'storedAt': DateTime.now().toUtc().millisecondsSinceEpoch,
    'data': [
      for (final item in items)
        {
          'id': item.id,
          'name': item.name,
          'progress': {
            'completed': item.completed,
            'total': item.total,
            'percent': item.percent,
          },
        },
    ],
  });

  Future<void> clear(String owner) async {
    await Future.wait([_current.clear(owner), _previous.clear(owner)]);
  }
}
