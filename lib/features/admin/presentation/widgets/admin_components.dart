import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/admin_models.dart';

class AdminPageFrame extends StatelessWidget {
  const AdminPageFrame({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.action,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1320),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            compact ? 16 : 28,
            16,
            compact ? 16 : 28,
            28,
          ),
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 14,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                ?action,
              ],
            ),
            const SizedBox(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}

class AdminSectionTitle extends StatelessWidget {
  const AdminSectionTitle(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class AdminPanel extends StatelessWidget {
  const AdminPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(padding: padding, child: child),
    );
  }
}

class AdminSearchField extends StatelessWidget {
  const AdminSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
  });

  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded),
        constraints: const BoxConstraints(maxWidth: 420),
      ),
    );
  }
}

class AdminEmptyState extends StatelessWidget {
  const AdminEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AdminPanel(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            Icon(icon, size: 42, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class AdminStatusChip extends StatelessWidget {
  const AdminStatusChip.course(this.courseStatus, {super.key})
    : mediaStatus = null,
      requestStatus = null;

  const AdminStatusChip.media(this.mediaStatus, {super.key})
    : courseStatus = null,
      requestStatus = null;

  const AdminStatusChip.request(this.requestStatus, {super.key})
    : courseStatus = null,
      mediaStatus = null;

  final AdminCourseStatus? courseStatus;
  final AdminMediaStatus? mediaStatus;
  final AdminRequestStatus? requestStatus;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (label, color, icon) = switch ((
      courseStatus,
      mediaStatus,
      requestStatus,
    )) {
      (AdminCourseStatus.published, _, _) => (
        'منشورة',
        dark ? const Color(0xFF53D1A0) : AppPalette.success,
        Icons.check_circle_outline,
      ),
      (AdminCourseStatus.draft, _, _) => (
        'مسودة',
        dark ? const Color(0xFFFFBE73) : AppPalette.warning,
        Icons.edit_note_rounded,
      ),
      (_, AdminMediaStatus.ready, _) => (
        'جاهز',
        dark ? const Color(0xFF53D1A0) : AppPalette.success,
        Icons.check_circle_outline,
      ),
      (_, AdminMediaStatus.processing, _) => (
        'قيد المعالجة',
        dark ? const Color(0xFFFFBE73) : AppPalette.warning,
        Icons.hourglass_top_rounded,
      ),
      (_, AdminMediaStatus.failed, _) => (
        'فشل',
        dark ? const Color(0xFFFF9B8F) : AppPalette.error,
        Icons.error_outline_rounded,
      ),
      (_, _, AdminRequestStatus.pending) => (
        'بانتظار المراجعة',
        dark ? const Color(0xFFFFBE73) : AppPalette.warning,
        Icons.schedule_rounded,
      ),
      (_, _, AdminRequestStatus.completed) => (
        'مكتمل',
        dark ? const Color(0xFF53D1A0) : AppPalette.success,
        Icons.check_circle_outline,
      ),
      (_, _, AdminRequestStatus.rejected) => (
        'مرفوض',
        dark ? const Color(0xFFFF9B8F) : AppPalette.error,
        Icons.cancel_outlined,
      ),
      _ => (
        'غير معروف',
        Theme.of(context).colorScheme.onSurfaceVariant,
        Icons.help_outline,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? 0.15 : 0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class AdminDemoActionNote extends StatelessWidget {
  const AdminDemoActionNote({
    super.key,
    this.text = 'الإجراءات الحساسة تتطلب ربط الخادم والتحقق من دور الإدارة.',
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return AdminPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

String adminDate(DateTime value) {
  final local = value.toLocal();
  return '${local.year}/${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')}';
}

String adminDateTime(DateTime value) {
  final local = value.toLocal();
  return '${adminDate(value)} · ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}
