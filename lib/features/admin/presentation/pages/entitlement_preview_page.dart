import 'package:flutter/material.dart';

import '../../domain/admin_models.dart';
import '../widgets/admin_components.dart';

class EntitlementPreviewPage extends StatefulWidget {
  const EntitlementPreviewPage({
    super.key,
    required this.student,
    required this.courses,
  });

  final AdminStudent student;
  final List<AdminCourse> courses;

  @override
  State<EntitlementPreviewPage> createState() => _EntitlementPreviewPageState();
}

class _EntitlementPreviewPageState extends State<EntitlementPreviewPage> {
  final _reason = TextEditingController();
  String? _courseId;
  DateTime? _expiresAt;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 180)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date != null) setState(() => _expiresAt = date);
  }

  void _preview() {
    if (_courseId == null ||
        _expiresAt == null ||
        _reason.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('اختر الدورة وتاريخ الانتهاء وأدخل سبب المنح.'),
        ),
      );
      return;
    }
    final course = widget.courses.firstWhere((item) => item.id == _courseId);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('معاينة منح الوصول'),
        content: Text(
          'الطالب: ${widget.student.name}\n'
          'الدورة: ${course.subject}\n'
          'ينتهي: ${adminDate(_expiresAt!)}\n'
          'السبب: ${_reason.text.trim()}\n\n'
          'هذه معاينة فقط، ولم يُمنح الوصول.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('معاينة منح استحقاق')),
      body: AdminPageFrame(
        title: 'منح وصول',
        subtitle:
            'للطالب ${widget.student.name} · نموذج تصميم لا يحفظ البيانات',
        children: [
          AdminPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _courseId,
                  decoration: const InputDecoration(labelText: 'الدورة'),
                  items: [
                    for (final course in widget.courses)
                      DropdownMenuItem(
                        value: course.id,
                        child: Text(course.subject),
                      ),
                  ],
                  onChanged: (value) => setState(() => _courseId = value),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _chooseDate,
                  icon: const Icon(Icons.event_outlined),
                  label: Text(
                    _expiresAt == null
                        ? 'اختر تاريخ الانتهاء'
                        : 'ينتهي ${adminDate(_expiresAt!)}',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _reason,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'سبب المنح الإداري',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const AdminDemoActionNote(
            text: 'المنح الفعلي يحتاج معاملة خادم ذرية وتدقيقاً ومنع استحقاقات متعارضة.',
          ),
          const SizedBox(height: 16),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.icon(
              onPressed: _preview,
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('معاينة القرار'),
            ),
          ),
        ],
      ),
    );
  }
}
