import 'package:flutter/material.dart';

import '../../domain/admin_models.dart';
import '../widgets/admin_components.dart';

class LessonEditorPreviewPage extends StatefulWidget {
  const LessonEditorPreviewPage({
    super.key,
    required this.course,
    required this.position,
  });

  final AdminCourse course;
  final int position;

  @override
  State<LessonEditorPreviewPage> createState() =>
      _LessonEditorPreviewPageState();
}

class _LessonEditorPreviewPageState extends State<LessonEditorPreviewPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _summary = TextEditingController();
  final _attachment = TextEditingController();
  final List<String> _attachments = [];

  @override
  void dispose() {
    _title.dispose();
    _summary.dispose();
    _attachment.dispose();
    super.dispose();
  }

  void _addAttachmentName() {
    final name = _attachment.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _attachments.add(name);
      _attachment.clear();
    });
  }

  void _preview() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('معاينة بيانات الدرس'),
        content: SingleChildScrollView(
          child: Text(
            'الدورة: ${widget.course.subject}\n'
            'الترتيب: ${widget.position}\n'
            'العنوان: ${_title.text.trim()}\n'
            'الملخص: ${_summary.text.trim()}\n'
            'أسماء المرفقات: ${_attachments.isEmpty ? 'لا يوجد' : _attachments.join('، ')}\n'
            'معاينة مجانية: ${widget.position == 1 ? 'نعم' : 'لا'}\n\n'
            'هذه معاينة محلية؛ لم يُرفع فيديو أو ملف ولم يُحفظ الدرس.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('معاينة محرر درس')),
      body: Form(
        key: _formKey,
        child: AdminPageFrame(
          title: 'درس جديد',
          subtitle: '${widget.course.subject} · موضع ${widget.position}',
          children: [
            AdminPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AdminSectionTitle('بيانات الدرس'),
                  TextFormField(
                    controller: _title,
                    decoration: const InputDecoration(labelText: 'عنوان الدرس'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'أدخل عنوان الدرس'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _summary,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'ملخص الدرس'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'أدخل ملخصاً موجزاً'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('معاينة مجانية'),
                    subtitle: const Text(
                      'الدرس الأول فقط مجاني في خطة النسخة الأولى',
                    ),
                    value: widget.position == 1,
                    onChanged: null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const AdminPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminSectionTitle('الفيديو'),
                  SizedBox(height: 8),
                  Text(
                    'لا يوجد فيديو مرتبط. سيظهر الرفع والمعالجة بعد اختيار مزود الوسائط وربط API.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AdminPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AdminSectionTitle('المرفقات'),
                  const Text(
                    'أضف أسماء ملفات للمعاينة فقط؛ لا تُقرأ ملفات الجهاز.',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _attachment,
                          decoration: const InputDecoration(
                            labelText: 'اسم المرفق',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'إضافة اسم مرفق للمعاينة',
                        onPressed: _addAttachmentName,
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                  for (final name in _attachments)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.attach_file_rounded),
                      title: Text(name),
                      trailing: IconButton(
                        tooltip: 'إزالة اسم المرفق',
                        onPressed: () =>
                            setState(() => _attachments.remove(name)),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const AdminDemoActionNote(
              text: 'حفظ الدرس ورفع الفيديو والمرفقات يحتاجان إلى خادم ومزود وسائط وتحقق صلاحيات.',
            ),
            const SizedBox(height: 16),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.icon(
                onPressed: _preview,
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('معاينة بيانات الدرس'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
