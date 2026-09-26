import 'student_models.dart';

abstract class StudentRepository {
  Future<List<StudentCourse>> loadCatalog();
}
