import 'package:flutter/material.dart';

import '../widgets/admin_components.dart';

class CourseEditorPreviewPage extends StatefulWidget {
  const CourseEditorPreviewPage({super.key});

  @override
  State<CourseEditorPreviewPage> createState() =>
      _CourseEditorPreviewPageState();
}

class _CourseEditorPreviewPageState extends State<CourseEditorPreviewPage> {
  final _formKey = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _code = TextEditingController();
  final _instructor = TextEditingController();
  final _description = TextEditingController();
  final _lesson = TextEditingController();
  final List<String> _lessons = [];

  @override
  void dispose() {
    _subject.dispose();
    _code.dispose();
    _instructor.dispose();
    _description.dispose();
    _lesson.dispose();
    super.dispose();
  }

  void _addLesson() {
    final title = _lesson.text.trim();
    if (title.isEmpty) return;
    setState(() {
      _lessons.add(title);
      _lesson.clear();
    });
  }

  void _showPreview() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('معاينة المسودة'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('المادة: ${_subject.text.trim()}'),
              Text('الرمز: ${_code.text.trim()}'),
              Text('الأستاذ: ${_instructor.text.trim()}'),
              Text('عدد الدروس: ${_lessons.length}'),
              const SizedBox(height: 12),
              const Text('هذه معاينة محلية فقط؛ لا تُحفظ المسودة ولا تُنشر.'),
            ],
          ),
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
      appBar: AppBar(title: const Text('معاينة محرر دورة')),
      body: Form(
        key: _formKey,
        child: AdminPageFrame(
          title: 'دورة جديدة',
          subtitle: 'نموذج تفاعلي للتصميم · المدخلات لا تُحفظ',
          children: [
            AdminPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AdminSectionTitle('بيانات المادة والدورة'),
                  TextFormField(
                    controller: _subject,
                    decoration: const InputDecoration(labelText: 'اسم المادة'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'أدخل اسم المادة'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _code,
                    decoration: const InputDecoration(labelText: 'رمز المادة'),
                    textDirection: TextDirection.ltr,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'أدخل رمز المادة'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _instructor,
                    decoration: const InputDecoration(
                      labelText: 'اسم الأستاذ للعرض',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'أدخل اسم الأستاذ'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _description,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'وصف الدورة'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'أدخل وصفاً موجزاً'
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AdminPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AdminSectionTitle('الدروس'),
                  const Text(
                    'الدرس الأول هو المعاينة المجانية. يلزم فيديو جاهز قبل النشر الحقيقي.',
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _lesson,
                          decoration: const InputDecoration(
                            labelText: 'عنوان الدرس',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: _addLesson,
                        tooltip: 'إضافة درس للمعاينة',
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                  for (var index = 0; index < _lessons.length; index++)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(child: Text('${index + 1}')),
                      title: Text(_lessons[index]),
                      subtitle: index == 0
                          ? const Text('الدرس التعريفي المجاني')
                          : null,
                      trailing: IconButton(
                        tooltip: 'إزالة الدرس من المعاينة',
                        onPressed: () =>
                            setState(() => _lessons.removeAt(index)),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const AdminDemoActionNote(
              text: 'الحفظ ورفع الفيديو وفحص الجاهزية والنشر تحتاج إلى API وخدمة وسائط وصلاحيات خادم.',
            ),
            const SizedBox(height: 16),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.icon(
                onPressed: _showPreview,
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('معاينة المسودة'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
