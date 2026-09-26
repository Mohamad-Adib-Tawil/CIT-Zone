import 'package:flutter/material.dart';

import '../../domain/admin_models.dart';
import '../admin_section.dart';
import '../pages/content_page.dart';
import '../pages/course_editor_preview_page.dart';
import '../pages/course_details_page.dart';
import '../pages/operations_pages.dart';
import '../pages/overview_page.dart';
import '../pages/students_page.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({
    super.key,
    required this.data,
    required this.onRefresh,
    required this.refreshing,
    this.error,
  });

  final AdminDashboardData data;
  final VoidCallback onRefresh;
  final bool refreshing;
  final String? error;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  AdminSection _section = AdminSection.overview;

  static const _railSections = [
    AdminSection.overview,
    AdminSection.content,
    AdminSection.students,
    AdminSection.requests,
    AdminSection.audit,
    AdminSection.settings,
  ];

  static const _bottomSections = [
    AdminSection.overview,
    AdminSection.content,
    AdminSection.students,
    AdminSection.more,
  ];

  void _navigate(AdminSection section) => setState(() => _section = section);

  void _openCourse(AdminCourse course) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CourseDetailsPage(course: course),
      ),
    );
  }

  void _openStudent(AdminStudent student) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            StudentDetailsPage(student: student, courses: widget.data.courses),
      ),
    );
  }

  void _createCourse() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CourseEditorPreviewPage()),
    );
  }

  void _openRequest(AdminDeviceRequest request) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RequestDetailsPage(request: request),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 600;
        final extended = constraints.maxWidth >= 1024;
        final selected = !compact && _section == AdminSection.more
            ? AdminSection.settings
            : _section;
        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 68,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.school_rounded,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'CIT Zone',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'تحديث البيانات',
                onPressed: widget.refreshing ? null : widget.onRefresh,
                icon: widget.refreshing
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 16, start: 4),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Theme.of(context).colorScheme.primary
                      .withValues(alpha: 0.12),
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
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
                child: Row(
                  children: [
                    Icon(
                      Icons.science_outlined,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'عرض تجريبي للتصميم · البيانات غير حقيقية ولا تُحفظ التعديلات',
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.error != null)
                MaterialBanner(
                  content: Text(widget.error!),
                  actions: [
                    TextButton(
                      onPressed: widget.onRefresh,
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              Expanded(
                child: compact
                    ? _buildPage(selected)
                    : Row(
                        children: [
                          NavigationRail(
                            extended: extended,
                            minExtendedWidth: 216,
                            labelType: extended
                                ? NavigationRailLabelType.none
                                : NavigationRailLabelType.all,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .surface,
                            selectedIndex: _railSections.indexOf(selected),
                            onDestinationSelected: (index) =>
                                _navigate(_railSections[index]),
                            destinations: [
                              for (final section in _railSections)
                                NavigationRailDestination(
                                  icon: Icon(section.icon),
                                  selectedIcon: Icon(section.selectedIcon),
                                  label: Text(section.label),
                                ),
                            ],
                          ),
                          const VerticalDivider(width: 1),
                          Expanded(child: _buildPage(selected)),
                        ],
                      ),
              ),
            ],
          ),
          bottomNavigationBar: compact
              ? NavigationBar(
                  selectedIndex: _bottomIndex(selected),
                  onDestinationSelected: (index) =>
                      _navigate(_bottomSections[index]),
                  destinations: [
                    for (final section in _bottomSections)
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
  }

  int _bottomIndex(AdminSection section) {
    final direct = _bottomSections.indexOf(section);
    return direct < 0 ? 3 : direct;
  }

  Widget _buildPage(AdminSection section) {
    return switch (section) {
      AdminSection.overview => OverviewPage(
        data: widget.data,
        onNavigate: _navigate,
        onOpenCourse: _openCourse,
        onRefresh: widget.onRefresh,
        refreshing: widget.refreshing,
      ),
      AdminSection.content => ContentPage(
        data: widget.data,
        onOpenCourse: _openCourse,
        onCreateCourse: _createCourse,
      ),
      AdminSection.students => StudentsPage(
        data: widget.data,
        onOpenStudent: _openStudent,
      ),
      AdminSection.requests => RequestsPage(
        requests: widget.data.deviceRequests,
        onOpenRequest: _openRequest,
      ),
      AdminSection.audit => AuditPage(activities: widget.data.activities),
      AdminSection.settings => const SettingsPage(),
      AdminSection.more => MorePage(
        onNavigate: _navigate,
        pendingRequests: widget.data.pendingRequestCount,
      ),
    };
  }
}
