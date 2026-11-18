import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/student_learning.dart';
import '../domain/student_profile_snapshot.dart';
import 'secure_student_snapshot_store.dart';

/// Small, encrypted account metadata. Storage failure is always a cache miss.
final class SecureStudentProfileCache {
  SecureStudentProfileCache(FlutterSecureStorage storage, String environment)
    : _store = SecureStudentSnapshotStore(
        storage,
        environment,
        'profile',
        8192,
      );

  final SecureStudentSnapshotStore _store;

  Future<StudentProfileSnapshot?> read(String owner) async {
    try {
      final json = await _store.read(owner);
      if (json case {
        'version': 1,
        'storedAt': int timestamp,
        'name': String name,
        'email': String email,
        'phone': String? phone,
        'department': String? department,
        'year': int? year,
      }) {
        if (name.length > 512 ||
            email.length > 512 ||
            (phone?.length ?? 0) > 128 ||
            (department?.length ?? 0) > 512 ||
            (year != null && year != 1 && year != 2)) {
          return null;
        }
        return (
          data: (
            name: name,
            email: email,
            phone: phone,
            department: department,
            year: year,
          ),
          storedAt: DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true),
        );
      }
    } catch (_) {
      // Cached data must not prevent a live profile request.
    }
    return null;
  }

  Future<void> write(String owner, StudentProfileData data) =>
      _store.write(owner, {
        'version': 1,
        'storedAt': DateTime.now().toUtc().millisecondsSinceEpoch,
        'name': data.name,
        'email': data.email,
        'phone': data.phone,
        'department': data.department,
        'year': data.year,
      });

  Future<void> clear(String owner) => _store.clear(owner);
}
