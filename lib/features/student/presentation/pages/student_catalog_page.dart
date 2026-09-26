import 'package:flutter/material.dart';

import '../../domain/student_models.dart';
import '../widgets/student_components.dart';

class StudentCatalogPage extends StatefulWidget {
  const StudentCatalogPage({
    super.key,
    required this.courses,
    required this.onOpenCourse,
  });

  final List<StudentCourse> courses;
  final ValueChanged<StudentCourse> onOpenCourse;

  @override
  State<StudentCatalogPage> createState() => _StudentCatalogPageState();
}

class _StudentCatalogPageState extends State<StudentCatalogPage> {
  String _query = '';
  String _department = 'الكل';
  String _year = 'الكل';
  String _term = 'الكل';

  @override
  Widget build(BuildContext context) {
    final courses = widget.courses.where((course) {
      final search = '${course.title} ${course.code}'.toLowerCase();
      final matchesQuery = search.contains(_query.toLowerCase());
      final matchesPlacement = course.placements.any(
        (placement) =>
            (_department == 'الكل' || placement.department == _department) &&
            (_year == 'الكل' || placement.year == _year) &&
            (_term == 'الكل' || placement.term == _term),
      );
      return matchesQuery && matchesPlacement;
    }).toList();

    return StudentPageFrame(
      title: 'المواد الدراسية',
      subtitle: 'ابحث حسب القسم والسنة والفصل',
      children: [
        TextField(
          decoration: const InputDecoration(
            hintText: 'ابحث عن مادة أو رمزها',
            prefixIcon: Icon(Icons.search_rounded),
          ),
          onChanged: (value) => setState(() => _query = value.trim()),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final department in const ['الكل', 'البرمجيات', 'الشبكات'])
              FilterChip(
                label: Text(department),
                selected: _department == department,
                onSelected: (_) => setState(() => _department = department),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _year,
                decoration: const InputDecoration(labelText: 'السنة'),
                items: const [
                  DropdownMenuItem(value: 'الكل', child: Text('كل السنوات')),
                  DropdownMenuItem(value: 'الأولى', child: Text('الأولى')),
                  DropdownMenuItem(value: 'الثانية', child: Text('الثانية')),
                ],
                onChanged: (value) => setState(() => _year = value ?? 'الكل'),
              ),
            ),
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _term,
                decoration: const InputDecoration(labelText: 'الفصل'),
                items: const [
                  DropdownMenuItem(value: 'الكل', child: Text('كل الفصول')),
                  DropdownMenuItem(value: 'الأول', child: Text('الأول')),
                  DropdownMenuItem(value: 'الثاني', child: Text('الثاني')),
                ],
                onChanged: (value) => setState(() => _term = value ?? 'الكل'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          '${courses.length} مواد نموذجية',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        if (courses.isEmpty)
          const StudentEmptyPanel(
            icon: Icons.search_off_rounded,
            title: 'لا توجد نتائج',
            message: 'غيّر البحث أو القسم أو السنة أو الفصل.',
          )
        else
          for (final course in courses) ...[
            StudentCourseCard(
              course: course,
              onTap: () => widget.onOpenCourse(course),
            ),
            const SizedBox(height: 10),
          ],
        const SizedBox(height: 16),
        const StudentNotice(
          'أسماء المواد والمواضع هنا للتصميم فقط حتى يُعتمد المنهج الرسمي.',
        ),
      ],
    );
  }
}
