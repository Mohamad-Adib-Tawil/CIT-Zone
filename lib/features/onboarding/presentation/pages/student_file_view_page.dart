import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/either.dart';
import '../../../auth/domain/student_learning.dart';
import '../theme/hasobjy_visual_scope.dart';
import 'preview/preview_widgets.dart';

class StudentFileViewPage extends StatelessWidget {
  const StudentFileViewPage({
    super.key,
    required this.file,
    required this.open,
    required this.actions,
    required this.onRestriction,
  });

  final StudentSubjectFile file;
  final StudentFileViewer Function() open;
  final PreviewActions actions;
  final ValueChanged<StudentFileViewFailure> onRestriction;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => _FilePagesCubit(open(), onRestriction)..load(1),
    child: BlocBuilder<_FilePagesCubit, _PageState>(
      builder: (context, state) {
        final total = state.image?.totalPages ?? file.pages;
        final cubit = context.read<_FilePagesCubit>();
        final loading = state.pending != null;
        return PreviewScaffold(
          title: file.title,
          actions: actions,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                PreviewText(
                  total == null
                      ? 'صفحة ${state.number}'
                      : 'صفحة ${state.number} من $total',
                  style: context.design.bodySmall,
                ),
                previewBadge(context, 'عرض فقط'),
              ],
            ),
            if (state.image case final image?)
              _EphemeralPageImage(
                onRetry: loading || state.retry != null
                    ? null
                    : () => cubit.load(state.number),
                provider: ResizeImage(
                  MemoryImage(image.bytes),
                  width: _decodeWidth(context),
                  height: 1920,
                  policy: ResizeImagePolicy.fit,
                ),
              ),
            if (loading)
              const Center(child: CircularProgressIndicator())
            else if (state.retry case final target?) ...[
              const PreviewText('تعذّر عرض الصفحة.'),
              OutlinedButton(
                onPressed: () => cubit.load(target),
                child: const Text('إعادة المحاولة'),
              ),
            ],
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed:
                        !loading &&
                            state.image != null &&
                            total != null &&
                            state.number < total
                        ? () => cubit.load(state.number + 1)
                        : null,
                    child: const Text('التالية'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: !loading && state.number > 1
                        ? () => cubit.load(state.number - 1)
                        : null,
                    child: const Text('السابقة'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );

  int _decodeWidth(BuildContext context) {
    final width =
        MediaQuery.sizeOf(context).width -
        MediaQuery.paddingOf(context).horizontal;
    final contentWidth = width.clamp(48, 390) - 48;
    return (contentWidth * MediaQuery.devicePixelRatioOf(context))
        .round()
        .clamp(1, 1280);
  }
}

class _EphemeralPageImage extends StatefulWidget {
  const _EphemeralPageImage({required this.provider, required this.onRetry});
  final ImageProvider provider;
  final VoidCallback? onRetry;

  @override
  State<_EphemeralPageImage> createState() => _EphemeralPageImageState();
}

class _EphemeralPageImageState extends State<_EphemeralPageImage> {
  @override
  void didUpdateWidget(_EphemeralPageImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.provider != oldWidget.provider) oldWidget.provider.evict();
  }

  @override
  void dispose() {
    widget.provider.evict();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Image(
    key: ValueKey(widget.provider),
    image: widget.provider,
    fit: BoxFit.contain,
    semanticLabel: 'صورة صفحة المستند',
    errorBuilder: (_, _, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: 14,
      children: [
        const PreviewText('تعذّر عرض صورة الصفحة.'),
        if (widget.onRetry case final retry?)
          OutlinedButton(onPressed: retry, child: const Text('إعادة المحاولة')),
      ],
    ),
  );
}

typedef _PageState = ({
  int number,
  int? pending,
  int? retry,
  StudentFilePage? image,
});

class _FilePagesCubit extends Cubit<_PageState> {
  _FilePagesCubit(this._viewer, this._onRestriction)
    : super((number: 1, pending: null, retry: null, image: null));

  final StudentFileViewer _viewer;
  final ValueChanged<StudentFileViewFailure> _onRestriction;

  Future<void> load(int number) async {
    if (isClosed || state.pending != null) return;
    final previous = state;
    emit((
      number: previous.image == null ? number : previous.number,
      pending: number,
      retry: null,
      image: previous.image,
    ));
    final result = await _viewer.page(number);
    if (isClosed) return;
    switch (result) {
      case Right(:final value):
        emit((number: number, pending: null, retry: null, image: value));
      case Left(value: StudentFileViewFailure.network):
        emit((
          number: state.number,
          pending: null,
          retry: number,
          image: state.image,
        ));
      case Left(:final value):
        emit((number: number, pending: null, retry: number, image: null));
        if (value == StudentFileViewFailure.accountSuspended ||
            value == StudentFileViewFailure.deviceUnauthorized) {
          _onRestriction(value);
        }
    }
  }

  @override
  Future<void> close() {
    _viewer.close();
    return super.close();
  }
}
