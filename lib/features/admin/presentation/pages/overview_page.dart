import 'package:flutter/material.dart';

import '../../domain/admin_models.dart';
import '../admin_section.dart';
import '../widgets/admin_components.dart';

class OverviewPage extends StatelessWidget {
  const OverviewPage({
    super.key,
    required this.data,
    required this.onNavigate,
    required this.onOpenCourse,
    required this.onRefresh,
    required this.refreshing,
  });

  final AdminDashboardData data;
  final ValueChanged<AdminSection> onNavigate;
  final ValueChanged<AdminCourse> onOpenCourse;
  final VoidCallback onRefresh;
  final bool refreshing;

  @override
  Widget build(BuildContext context) {
    return AdminPageFrame(
      title: 'لوحة الإدارة',
      subtitle: 'إليك ما يحدث في منصة CIT Zone اليوم',
      action: OutlinedButton.icon(
        onPressed: refreshing ? null : onRefresh,
        icon: refreshing
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.refresh_rounded),
        label: const Text('تحديث البيانات'),
      ),
      children: [
        Text(
          'آخر تحديث: ${adminDateTime(data.asOf)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final columns = width >= 1040
                ? 4
                : width >= 340
                ? 2
                : 1;
            final cardWidth = (width - (columns - 1) * 12) / columns;
            final metrics = [
              _Metric(
                'الدورات المنشورة',
                data.publishedCourseCount,
                Icons.auto_stories_rounded,
                AdminSection.content,
              ),
              _Metric(
                'المسودات',
                data.draftCourseCount,
                Icons.edit_note_rounded,
                AdminSection.content,
              ),
              _Metric(
                'وسائط قيد المعالجة',
                data.processingMediaCount,
                Icons.video_library_outlined,
                AdminSection.content,
              ),
              _Metric(
                'طلبات نقل معلقة',
                data.pendingRequestCount,
                Icons.phonelink_setup_rounded,
                AdminSection.requests,
              ),
            ];
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final metric in metrics)
                  SizedBox(
                    width: cardWidth,
                    child: _MetricCard(
                      metric: metric,
                      onTap: () => onNavigate(metric.target),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 28),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 920;
            final attention = _AttentionPanel(
              items: data.attention,
              onTap: (item) {
                if (item.target == AdminAttentionTarget.course) {
                  for (final course in data.courses) {
                    if (course.id == item.targetId) {
                      onOpenCourse(course);
                      return;
                    }
                  }
                }
                onNavigate(
                  item.target == AdminAttentionTarget.deviceRequests
                      ? AdminSection.requests
                      : AdminSection.content,
                );
              },
            );
            final secondary = Column(
              children: [
                _QuickActions(onNavigate: onNavigate),
                const SizedBox(height: 18),
                _ActivityPanel(activities: data.activities),
              ],
            );
            if (!wide) {
              return Column(
                children: [attention, const SizedBox(height: 18), secondary],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: attention),
                const SizedBox(width: 18),
                Expanded(flex: 4, child: secondary),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Metric {
  const _Metric(this.title, this.value, this.icon, this.target);

  final String title;
  final int value;
  final IconData icon;
  final AdminSection target;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric, required this.onTap});

  final _Metric metric;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: scheme.primary.withValues(alpha: 0.1),
                child: Icon(metric.icon, color: scheme.primary),
              ),
              const SizedBox(height: 18),
              Text(
                '${metric.value}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                metric.title,
                maxLines: 2,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'العدد الحالي',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttentionPanel extends StatelessWidget {
  const _AttentionPanel({required this.items, required this.onTap});

  final List<AdminAttentionItem> items;
  final ValueChanged<AdminAttentionItem> onTap;

  @override
  Widget build(BuildContext context) {
    return AdminPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionTitle('يحتاج إلى إجراء'),
          if (items.isEmpty)
            const Text('لا توجد مهام تحتاج إلى مراجعة حالياً.')
          else
            for (var index = 0; index < items.length; index++) ...[
              if (index > 0) const Divider(height: 18),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.error
                      .withValues(alpha: 0.1),
                  child: Icon(
                    items[index].target == AdminAttentionTarget.deviceRequests
                        ? Icons.phonelink_setup_rounded
                        : Icons.priority_high_rounded,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                title: Text(items[index].title, maxLines: 2),
                subtitle: Text(items[index].details, maxLines: 2),
                trailing: const Icon(Icons.chevron_left_rounded),
                onTap: () => onTap(items[index]),
              ),
            ],
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onNavigate});

  final ValueChanged<AdminSection> onNavigate;

  @override
  Widget build(BuildContext context) {
    return AdminPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionTitle('وصول سريع'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => onNavigate(AdminSection.content),
                icon: const Icon(Icons.library_books_outlined),
                label: const Text('إدارة المحتوى'),
              ),
              OutlinedButton.icon(
                onPressed: () => onNavigate(AdminSection.students),
                icon: const Icon(Icons.people_outline_rounded),
                label: const Text('الطلاب'),
              ),
              OutlinedButton.icon(
                onPressed: () => onNavigate(AdminSection.requests),
                icon: const Icon(Icons.phonelink_setup_rounded),
                label: const Text('طلبات الأجهزة'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityPanel extends StatelessWidget {
  const _ActivityPanel({required this.activities});

  final List<AdminActivity> activities;

  @override
  Widget build(BuildContext context) {
    return AdminPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionTitle('النشاط الأخير'),
          if (activities.isEmpty)
            const Text('لا يوجد نشاط مسجل بعد.')
          else
            for (final activity in activities) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.title,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            adminDateTime(activity.occurredAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
        ],
      ),
    );
  }
}
