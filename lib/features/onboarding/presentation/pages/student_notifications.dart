import 'package:flutter/material.dart';

import '../../../../core/errors/either.dart';
import '../../../auth/domain/student_learning.dart';
import '../../../auth/domain/student_session_repository.dart';
import '../theme/hasobjy_visual_scope.dart';
import 'preview/preview_widgets.dart';

class StudentNotifications extends StatefulWidget {
  const StudentNotifications({
    super.key,
    required this.data,
    required this.onRead,
    required this.onOpen,
    required this.canOpen,
    this.onFirst,
    this.onNext,
  });

  final StudentNotificationPage data;
  final Future<Either<StudentSessionFailure, void>> Function(String) onRead;
  final ValueChanged<StudentNotificationDestination> onOpen;
  final bool Function(StudentNotificationDestination) canOpen;
  final VoidCallback? onFirst;
  final VoidCallback? onNext;

  @override
  State<StudentNotifications> createState() => _StudentNotificationsState();
}

class _StudentNotificationsState extends State<StudentNotifications> {
  final _confirmed = <String>{};
  String? _pendingId;

  Future<void> _open(
    StudentNotification item,
    StudentNotificationDestination? destination,
    bool read,
  ) async {
    if (_pendingId != null) return;
    if (!read) {
      setState(() => _pendingId = item.id);
      final result = await widget.onRead(item.id);
      if (!mounted) return;
      setState(() {
        _pendingId = null;
        if (result.isRight()) _confirmed.add(item.id);
      });
      if (result case Left(:final value)) {
        if (value != StudentSessionFailure.accountSuspended &&
            value != StudentSessionFailure.deviceUnauthorized) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تعذّر تسجيل الاطلاع. أعد المحاولة.')),
          );
        }
        return;
      }
    }
    if (destination != null) widget.onOpen(destination);
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.data.items;
    final rows = items.isEmpty ? 1 : items.length;
    final hasPagination = widget.onFirst != null || widget.onNext != null;
    return SliverList.separated(
      itemCount: rows + (hasPagination ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        if (index == rows) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: widget.onFirst,
                child: const Text('الأحدث'),
              ),
              TextButton(onPressed: widget.onNext, child: const Text('الأقدم')),
            ],
          );
        }
        return items.isEmpty
            ? const PreviewText('لا توجد إشعارات.')
            : _card(items[index]);
      },
    );
  }

  Widget _card(StudentNotification item) {
    final read = item.read || _confirmed.contains(item.id);
    final destination = switch (item.destination) {
      final value? when widget.canOpen(value) => value,
      _ => null,
    };
    final actionable = !read || destination != null;
    final light = context.design.isLight;
    final fill = read
        ? context.design.surfaceSubtle
        : context.design.selectedSurface;
    return Semantics(
      button: actionable,
      enabled: actionable && _pendingId == null,
      hint: read ? 'مقروء' : 'غير مقروء',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: actionable && _pendingId == null
              ? () => _open(item, destination, read)
              : null,
          child: PreviewPanel(
            height: 98,
            children: [
              Row(
                textDirection: TextDirection.rtl,
                spacing: 12,
                children: [
                  if (_pendingId == item.id)
                    SizedBox.square(
                      dimension: 44,
                      child: ColoredBox(
                        color: fill,
                        child: const Center(
                          child: SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                    )
                  else
                    PreviewIconTile(
                      asset: switch ((read, light)) {
                        (true, true) => '06c8c',
                        (false, true) => 'e643d',
                        (true, false) => 'f2880',
                        (false, false) => 'b15c8',
                      },
                      fill: fill,
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 2,
                      children: [
                        PreviewText(
                          item.title,
                          style: context.design.labelSemiBold,
                        ),
                        PreviewText(item.body, style: context.design.bodySmall),
                        PreviewText(
                          MaterialLocalizations.of(context)
                              .formatMediumDate(item.createdAt.toLocal()),
                          style: context.design.bodySmall,
                          muted: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
