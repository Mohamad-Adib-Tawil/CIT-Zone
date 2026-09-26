import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/demo_student_repository.dart';
import '../../domain/student_models.dart';
import '../../../auth/domain/google_identity.dart';
import '../cubit/student_catalog_cubit.dart';
import 'student_catalog_page.dart';
import 'student_course_page.dart';
import 'student_downloads_page.dart';
import 'student_home_page.dart';
import 'student_my_courses_page.dart';
import 'student_profile_page.dart';

class StudentPreviewPage extends StatelessWidget {
  const StudentPreviewPage({super.key, this.identity});

  final GoogleIdentity? identity;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StudentCatalogCubit(DemoStudentRepository())..load(),
      child: _StudentShell(identity: identity),
    );
  }
}

enum _StudentSection {
  home('الرئيسية', Icons.home_outlined, Icons.home_rounded),
  catalog('المواد', Icons.menu_book_outlined, Icons.menu_book_rounded),
  myCourses('دوراتي', Icons.auto_stories_outlined, Icons.auto_stories_rounded),
  downloads('تنزيلاتي', Icons.download_outlined, Icons.download_rounded),
  profile('حسابي', Icons.person_outline_rounded, Icons.person_rounded);

  const _StudentSection(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _StudentShell extends StatefulWidget {
  const _StudentShell({this.identity});

  final GoogleIdentity? identity;

  @override
  State<_StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<_StudentShell> {
  _StudentSection _section = _StudentSection.home;

  void _openCourse(StudentCourse course) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StudentCoursePage(course: course),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StudentCatalogCubit, StudentCatalogState>(
      builder: (context, state) {
        if (state is StudentCatalogLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is StudentCatalogFailure) {
          return Scaffold(
            appBar: AppBar(title: const Text('معاينة الطالب')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_rounded, size: 44),
                  const SizedBox(height: 12),
                  const Text('تعذر تحميل بيانات المعاينة'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.read<StudentCatalogCubit>().load(),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            ),
          );
        }

        final ready = state as StudentCatalogReady;
        return LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 600;
            final extended = constraints.maxWidth >= 1024;
            return Scaffold(
              appBar: AppBar(
                title: const Text('CIT Zone · معاينة الطالب'),
                actions: [
                  IconButton(
                    tooltip: 'تحديث المواد النموذجية',
                    onPressed: ready.refreshing
                        ? null
                        : () => context.read<StudentCatalogCubit>().load(),
                    icon: ready.refreshing
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              body: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: Theme.of(context).colorScheme.primary
                        .withValues(alpha: 0.08),
                    child: const Text(
                      'عرض تجريبي · لا حساب ولا اشتراك ولا فيديو حقيقي في هذه المعاينة',
                    ),
                  ),
                  if (ready.error != null)
                    MaterialBanner(
                      content: Text(ready.error!),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              context.read<StudentCatalogCubit>().load(),
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  Expanded(
                    child: compact
                        ? _buildPages(ready.courses)
                        : Row(
                            children: [
                              NavigationRail(
                                extended: extended,
                                minExtendedWidth: 205,
                                labelType: extended
                                    ? NavigationRailLabelType.none
                                    : NavigationRailLabelType.all,
                                selectedIndex: _section.index,
                                onDestinationSelected: (index) => setState(
                                  () =>
                                      _section = _StudentSection.values[index],
                                ),
                                destinations: [
                                  for (final section in _StudentSection.values)
                                    NavigationRailDestination(
                                      icon: Icon(section.icon),
                                      selectedIcon: Icon(section.selectedIcon),
                                      label: Text(section.label),
                                    ),
                                ],
                              ),
                              const VerticalDivider(width: 1),
                              Expanded(child: _buildPages(ready.courses)),
                            ],
                          ),
                  ),
                ],
              ),
              bottomNavigationBar: compact
                  ? NavigationBar(
                      selectedIndex: _section.index,
                      onDestinationSelected: (index) => setState(
                        () => _section = _StudentSection.values[index],
                      ),
                      destinations: [
                        for (final section in _StudentSection.values)
                          NavigationDestination(
                            icon: Icon(section.icon),
                            selectedIcon: Icon(section.selectedIcon),
                            label: section.label,
                          ),
                      ],
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _buildPages(List<StudentCourse> courses) {
    return IndexedStack(
      index: _section.index,
      children: [
        StudentHomePage(
          courses: courses,
          onOpenCatalog: () =>
              setState(() => _section = _StudentSection.catalog),
          onOpenCourse: _openCourse,
        ),
        StudentCatalogPage(courses: courses, onOpenCourse: _openCourse),
        StudentMyCoursesPage(
          onOpenCatalog: () =>
              setState(() => _section = _StudentSection.catalog),
        ),
        const StudentDownloadsPage(),
        StudentProfilePage(identity: widget.identity),
      ],
    );
  }
}
