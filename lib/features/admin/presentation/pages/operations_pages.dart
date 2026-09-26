import 'package:flutter/material.dart';

import '../../domain/admin_models.dart';
import '../admin_section.dart';
import '../widgets/admin_components.dart';

class MorePage extends StatelessWidget {
  const MorePage({
    super.key,
    required this.onNavigate,
    required this.pendingRequests,
  });

  final ValueChanged<AdminSection> onNavigate;
  final int pendingRequests;

  @override
  Widget build(BuildContext context) {
    return AdminPageFrame(
      title: 'المزيد',
      subtitle: 'طلبات الأجهزة وسجل العمليات والإعدادات',
      children: [
        _MoreTile(
          title: 'طلبات نقل الأجهزة',
          subtitle: '$pendingRequests طلبات تحتاج مراجعة',
          icon: Icons.phonelink_setup_rounded,
          onTap: () => onNavigate(AdminSection.requests),
        ),
        const SizedBox(height: 10),
        _MoreTile(
          title: 'سجل الإجراءات',
          subtitle: 'اطلع على النشاط الإداري',
          icon: Icons.history_rounded,
          onTap: () => onNavigate(AdminSection.audit),
        ),
        const SizedBox(height: 10),
        _MoreTile(
          title: 'الإعدادات',
          subtitle: 'معلومات التطبيق ولوحة الإدارة',
          icon: Icons.settings_outlined,
          onTap: () => onNavigate(AdminSection.settings),
        ),
      ],
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_left_rounded),
        onTap: onTap,
      ),
    );
  }
}

class RequestsPage extends StatelessWidget {
  const RequestsPage({
    super.key,
    required this.requests,
    required this.onOpenRequest,
  });

  final List<AdminDeviceRequest> requests;
  final ValueChanged<AdminDeviceRequest> onOpenRequest;

  @override
  Widget build(BuildContext context) {
    return AdminPageFrame(
      title: 'طلبات نقل الأجهزة',
      subtitle: 'راجع كل طلب وأثره قبل اتخاذ القرار',
      children: [
        if (requests.isEmpty)
          const AdminEmptyState(message: 'لا توجد طلبات نقل أجهزة.')
        else
          for (final request in requests) ...[
            Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: const Icon(Icons.phonelink_setup_rounded),
                title: Text(request.studentName),
                subtitle: Text(
                  '${request.reason} · ${adminDateTime(request.createdAt)}',
                ),
                trailing: AdminStatusChip.request(request.status),
                onTap: () => onOpenRequest(request),
              ),
            ),
            const SizedBox(height: 10),
          ],
        const SizedBox(height: 14),
        const AdminDemoActionNote(),
      ],
    );
  }
}

class RequestDetailsPage extends StatelessWidget {
  const RequestDetailsPage({super.key, required this.request});

  final AdminDeviceRequest request;

  void _showDecisionPreview(BuildContext context, {required bool approve}) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(approve ? 'معاينة قبول الطلب' : 'معاينة رفض الطلب'),
        content: Text(
          approve
              ? 'سيُنقل حق استخدام الحساب إلى جهاز الطالب الجديد بعد تحقق الخادم. قد تبقى رخص المشاهدة دون اتصال على الجهاز السابق حتى تنتهي صلاحيتها.\n\nهذه معاينة فقط، ولم يُقبل الطلب.'
              : 'سيبقى الجهاز الحالي مرتبطاً بالحساب، ويجب إبلاغ الطالب بسبب الرفض عند تنفيذ القرار الحقيقي.\n\nهذه معاينة فقط، ولم يُرفض الطلب.',
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
      appBar: AppBar(title: const Text('تفاصيل طلب الجهاز')),
      body: AdminPageFrame(
        title: request.studentName,
        subtitle: 'طلب بتاريخ ${adminDateTime(request.createdAt)}',
        children: [
          AdminPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminStatusChip.request(request.status),
                const SizedBox(height: 14),
                Text(
                  'سبب الطلب: ${request.reason}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 14),
                const Text(
                  'عند نقل الجهاز سيُمنع إصدار جلسات وروابط تشغيل جديدة للجهاز السابق. قد تبقى رخص أوفلاين القديمة صالحة حتى انتهاء مدتها.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (request.status == AdminRequestStatus.pending) ...[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => _showDecisionPreview(context, approve: true),
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('معاينة قبول'),
                ),
                OutlinedButton.icon(
                  onPressed: () =>
                      _showDecisionPreview(context, approve: false),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('معاينة رفض'),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          const AdminDemoActionNote(
            text: 'القرار النهائي غير متاح في العرض التجريبي حتى يتحقق الخادم من الهوية وسياسة النقل ويسجل الإجراء.',
          ),
        ],
      ),
    );
  }
}

class AuditPage extends StatelessWidget {
  const AuditPage({super.key, required this.activities});

  final List<AdminActivity> activities;

  @override
  Widget build(BuildContext context) {
    return AdminPageFrame(
      title: 'سجل الإجراءات',
      subtitle: 'عرض فقط · جميع العمليات الإدارية المسجلة',
      children: [
        if (activities.isEmpty)
          const AdminEmptyState(message: 'لا يوجد نشاط إداري بعد.')
        else
          for (final activity in activities) ...[
            AdminPanel(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history_rounded),
                title: Text(activity.title),
                subtitle: Text(
                  '${activity.details}\n${activity.actor} · ${adminDateTime(activity.occurredAt)}',
                ),
                isThreeLine: true,
              ),
            ),
            const SizedBox(height: 10),
          ],
        const SizedBox(height: 12),
        const AdminDemoActionNote(
          text: 'السجل الحقيقي يجب أن يأتي من الخادم ويمنع تغييره من التطبيق.',
        ),
      ],
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminPageFrame(
      title: 'الإعدادات',
      subtitle: 'معلومات لوحة إدارة CIT Zone',
      children: [
        AdminPanel(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.person_outline_rounded),
                title: Text('حساب الإدارة'),
                subtitle: Text('يظهر بعد ربط خدمة الهوية'),
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.language_rounded),
                title: Text('اللغة'),
                subtitle: Text('العربية'),
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.info_outline_rounded),
                title: Text('حالة النسخة'),
                subtitle: Text('عرض تجريبي للتصميم'),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        AdminDemoActionNote(
          text: 'تسجيل الخروج وإدارة صلاحيات المسؤول ستُضاف عند ربط خدمة الهوية والخادم.',
        ),
      ],
    );
  }
}
