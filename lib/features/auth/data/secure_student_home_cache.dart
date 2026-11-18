import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/student_home_snapshot.dart';
import '../domain/student_learning.dart';
import 'secure_student_snapshot_store.dart';

/// Bounded home metadata only. No raw API payloads, URLs or access decisions.
final class SecureStudentHomeCache {
  SecureStudentHomeCache(
    FlutterSecureStorage storage,
    String environment,
    this._decode,
  ) : _store = SecureStudentSnapshotStore(storage, environment, 'home', 65536);

  final SecureStudentSnapshotStore _store;
  final StudentHomeData Function(Object?) _decode;

  Future<StudentHomeSnapshot?> read(String owner) async {
    try {
      final json = await _store.read(owner);
      if (json case {
        'version': 1,
        'storedAt': int timestamp,
        'data': final data,
      }) {
        return (
          data: _decode(data),
          storedAt: DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true),
        );
      }
    } catch (_) {
      // An unreadable snapshot falls back to the live home request.
    }
    return null;
  }

  Future<void> write(String owner, StudentHomeData data) {
    final resume = data.resumeLesson;
    return _store.write(owner, {
      'version': 1,
      'storedAt': DateTime.now().toUtc().millisecondsSinceEpoch,
      'data': {
        'name': data.name,
        'subjects': [
          for (final item in data.subjects)
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
        'courses': [
          for (final item in data.courses) {'id': item.id, 'name': item.name},
        ],
        'continueWatching': [
          if (resume != null)
            {
              'lessonId': resume.lessonId,
              'lessonTitle': resume.lessonTitle,
              'subjectId': resume.subjectId,
              'subjectName': resume.subjectName,
              'positionSeconds': resume.positionSeconds,
              'durationSeconds': resume.durationSeconds,
            },
        ],
      },
    });
  }

  Future<void> clear(String owner) => _store.clear(owner);
}
