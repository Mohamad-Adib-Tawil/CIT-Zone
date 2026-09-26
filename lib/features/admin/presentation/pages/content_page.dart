import 'package:flutter/material.dart';

import '../../domain/admin_models.dart';
import '../widgets/admin_components.dart';

class ContentPage extends StatefulWidget {
  const ContentPage({
    super.key,
    required this.data,
    required this.onOpenCourse,
    required this.onCreateCourse,
  });

  final AdminDashboardData data;
  final ValueChanged<AdminCourse> onOpenCourse;
  final VoidCallback onCreateCourse;

  @override
  State<ContentPage> createState() => _ContentPageState();
}

class _ContentPageState extends State<ContentPage> {
  String _query = '';
  String _department = 'الكل';

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return DefaultTabController(
      length: 3,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1320),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 16 : 28,
                  16,
                  compact ? 16 : 28,
                  8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إدارة المحتوى',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'المواد والدورات والمنهج والوسائط في مكان واحد',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.tonalIcon(
                      onPressed: widget.onCreateCourse,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('معاينة إنشاء دورة'),
                    ),
                    const SizedBox(height: 14),
                    AdminSearchField(
                      hint: 'ابحث عن مادة أو دورة أو ملف',
                      onChanged: (value) =>
                          setState(() => _query = value.trim()),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final department in const [
                          'الكل',
                          'البرمجيات',
                          'الشبكات',
                        ])
                          FilterChip(
                            label: Text(department),
                            selected: _department == department,
                            onSelected: (_) =>
                                setState(() => _department = department),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const TabBar(
                tabs: [
                  Tab(text: 'الدورات'),
                  Tab(text: 'المنهج'),
                  Tab(text: 'الوسائط'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _CourseList(
                      data: widget.data,
                      query: _query,
                      department: _department,
                      onOpen: widget.onOpenCourse,
                    ),
                    _CurriculumList(
                      data: widget.data,
                      query: _query,
                      department: _department,
                    ),
                    _MediaList(
                      data: widget.data,
                      query: _query,
                      department: _department,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseList extends StatelessWidget {
  const _CourseList({
    required this.data,
    required this.query,
    required this.department,
    required this.onOpen,
  });

  final AdminDashboardData data;
  final String query;
  final String department;
  final ValueChanged<AdminCourse> onOpen;

  @override
  Widget build(BuildContext context) {
    final courses = data.courses.where((course) {
      final matchesQuery =
          query.isEmpty ||
          '${course.subject} ${course.code} ${course.instructor}'.contains(
            query,
          );
      final matchesDepartment =
          department == 'الكل' || course.departments.contains(department);
      return matchesQuery && matchesDepartment;
    }).toList();
    if (courses.isEmpty) {
      return const _ListPadding(
        child: AdminEmptyState(
          message: 'لا توجد دورات تطابق البحث. جرّب تغيير المرشحات.',
        ),
      );
    }
    return _ListPadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${courses.length} دورات',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          for (final course in courses) ...[
            _CourseCard(course: course, onTap: () => onOpen(course)),
            const SizedBox(height: 12),
          ],
          const AdminDemoActionNote(
            text: 'إنشاء الدورات ونشرها يحتاجان إلى API إداري وتحقق صلاحيات على الخادم.',
          ),
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course, required this.onTap});

  final AdminCourse course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: compact ? 54 : 68,
                height: compact ? 54 : 68,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          course.subject,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        AdminStatusChip.course(course.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${course.code} · ${course.instructor}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'عدد الدروس: ${course.lessons.length} · ${course.departments.join('، ')}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurriculumList extends StatelessWidget {
  const _CurriculumList({
    required this.data,
    required this.query,
    required this.department,
  });

  final AdminDashboardData data;
  final String query;
  final String department;

  @override
  Widget build(BuildContext context) {
    final placements = data.placements.where((item) {
      return (query.isEmpty || item.subject.contains(query)) &&
          (department == 'الكل' || item.department == department);
    }).toList();
    if (placements.isEmpty) {
      return const _ListPadding(
        child: AdminEmptyState(
          message: 'لا توجد مواد في هذا العرض. غيّر البحث أو القسم.',
        ),
      );
    }
    return _ListPadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${placements.length} مواضع مواد',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          for (final item in placements) ...[
            AdminPanel(
              child: Row(
                children: [
                  Icon(
                    Icons.account_tree_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.subject,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.department} · السنة ${item.year} · الفصل ${item.term}',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          const AdminDemoActionNote(
            text: 'المادة نفسها قد تظهر في أكثر من موضع؛ لا تُنسخ الدورة عند اختلاف القسم أو الفصل.',
          ),
        ],
      ),
    );
  }
}

class _MediaList extends StatelessWidget {
  const _MediaList({
    required this.data,
    required this.query,
    required this.department,
  });

  final AdminDashboardData data;
  final String query;
  final String department;

  @override
  Widget build(BuildContext context) {
    final courseIds = data.courses
        .where(
          (course) =>
              department == 'الكل' || course.departments.contains(department),
        )
        .map((course) => course.subject)
        .toSet();
    final media = data.media.where((item) {
      return (query.isEmpty ||
              '${item.title} ${item.courseTitle}'.contains(query)) &&
          courseIds.contains(item.courseTitle);
    }).toList();
    if (media.isEmpty) {
      return const _ListPadding(
        child: AdminEmptyState(message: 'لا توجد وسائط تطابق البحث.'),
      );
    }
    return _ListPadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${media.length} ملفات',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          for (final item in media) ...[
            AdminPanel(
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.video_file_outlined,
                        color: Theme.of(context).colorScheme.primary,
                        size: 30,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item.courseTitle} · ${item.sizeLabel} · ${adminDate(item.createdAt)}',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      AdminStatusChip.media(item.status),
                    ],
                  ),
                  if (item.status == AdminMediaStatus.processing) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 6),
                    const Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        'المعالجة لدى مزود الفيديو؛ نسبة التقدم غير متاحة.',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          const AdminDemoActionNote(
            text: 'رفع الوسائط وتشغيلها ونشرها يحتاج إلى مزود فيديو وخادم تراخيص معتمدين.',
          ),
        ],
      ),
    );
  }
}

class _ListPadding extends StatelessWidget {
  const _ListPadding({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 28,
        18,
        compact ? 16 : 28,
        32,
      ),
      children: [child],
    );
  }
}
