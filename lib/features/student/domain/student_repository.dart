import '../../../core/errors/either.dart';
import 'student_catalog_error.dart';
import 'student_models.dart';

abstract interface class StudentRepository {
  Future<Either<StudentCatalogError, List<StudentCourse>>> loadCatalog();
}
