import '../domain/student_models.dart';
import '../domain/student_repository.dart';

/// Sample content for the debug-only UI preview; it is not an approved syllabus.
class DemoStudentRepository implements StudentRepository {
  @override
  Future<List<StudentCourse>> loadCatalog() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return const [
      StudentCourse(
        id: 'sample-programming',
        code: 'DEMO-101',
        title: 'مقدمة البرمجة',
        description:
            'تصور أولي لصفحة المادة: التفكير البرمجي والمفاهيم الأساسية.',
        instructor: 'اسم أستاذ تجريبي',
        placements: [
          StudentPlacement(
            department: 'البرمجيات',
            year: 'الأولى',
            term: 'الأول',
          ),
          StudentPlacement(
            department: 'الشبكات',
            year: 'الأولى',
            term: 'الأول',
          ),
        ],
        lessons: [
          StudentLesson(
            title: 'تعرف على المادة',
            durationMinutes: 8,
            isPreview: true,
            attachmentCount: 0,
          ),
          StudentLesson(
            title: 'المتغيرات وأنواع البيانات',
            durationMinutes: 24,
            isPreview: false,
            attachmentCount: 2,
          ),
        ],
      ),
      StudentCourse(
        id: 'sample-databases',
        code: 'DEMO-204',
        title: 'قواعد البيانات',
        description: 'تصور أولي لنمذجة البيانات والاستعلامات والعلاقات.',
        instructor: 'اسم أستاذ تجريبي',
        placements: [
          StudentPlacement(
            department: 'البرمجيات',
            year: 'الثانية',
            term: 'الأول',
          ),
          StudentPlacement(
            department: 'الشبكات',
            year: 'الثانية',
            term: 'الثاني',
          ),
        ],
        lessons: [
          StudentLesson(
            title: 'ماذا ستتعلم في هذه المادة؟',
            durationMinutes: 7,
            isPreview: true,
            attachmentCount: 0,
          ),
          StudentLesson(
            title: 'الجداول والعلاقات',
            durationMinutes: 28,
            isPreview: false,
            attachmentCount: 1,
          ),
        ],
      ),
      StudentCourse(
        id: 'sample-networks',
        code: 'DEMO-110',
        title: 'أساسيات الشبكات',
        description: 'تصور أولي للشبكات والبروتوكولات الأساسية.',
        instructor: 'اسم أستاذ تجريبي',
        placements: [
          StudentPlacement(
            department: 'الشبكات',
            year: 'الأولى',
            term: 'الثاني',
          ),
        ],
        lessons: [
          StudentLesson(
            title: 'نظرة عامة على المادة',
            durationMinutes: 9,
            isPreview: true,
            attachmentCount: 0,
          ),
        ],
      ),
    ];
  }
}
