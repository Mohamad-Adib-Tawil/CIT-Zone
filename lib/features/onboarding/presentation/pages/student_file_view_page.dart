import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/student_learning.dart';
import '../theme/hasobjy_visual_scope.dart';
import 'preview/preview_widgets.dart';

class StudentFileViewPage extends StatelessWidget {
  const StudentFileViewPage({
    super.key,
    required this.file,
    required this.open,
    required this.actions,
  });

  final StudentSubjectFile file;
  final StudentFileViewer Function() open;
  final PreviewActions actions;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => _FilePagesCubit(open())..load(1),
    child: BlocBuilder<_FilePagesCubit, _PageState>(
      builder: (context, state) {
        final total = state.image?.totalPages ?? file.pages;
        final cubit = context.read<_FilePagesCubit>();
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
            if (state.loading)
              const Center(child: CircularProgressIndicator())
            else if (state.image case final image?)
              LayoutBuilder(
                builder: (context, size) {
                  final provider = ResizeImage(
                    MemoryImage(image.bytes),
                    width:
                        (size.maxWidth * MediaQuery.devicePixelRatioOf(context))
                            .round()
                            .clamp(1, 1280),
                  );
                  return _EphemeralPageImage(provider: provider);
                },
              )
            else ...[
              const PreviewText('تعذّر عرض الصفحة.'),
              OutlinedButton(
                onPressed: () => cubit.load(state.number),
                child: const Text('إعادة المحاولة'),
              ),
            ],
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed:
                        !state.loading &&
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
                    onPressed: !state.loading && state.number > 1
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
}

class _EphemeralPageImage extends StatefulWidget {
  const _EphemeralPageImage({required this.provider});
  final ImageProvider provider;

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
    image: widget.provider,
    fit: BoxFit.contain,
    semanticLabel: 'صورة صفحة المستند',
    errorBuilder: (_, _, _) => const PreviewText('تعذّر عرض صورة الصفحة.'),
  );
}

typedef _PageState = ({int number, bool loading, StudentFilePage? image});

class _FilePagesCubit extends Cubit<_PageState> {
  _FilePagesCubit(this._viewer)
    : super((number: 1, loading: false, image: null));

  final StudentFileViewer _viewer;

  Future<void> load(int number) async {
    if (isClosed || state.loading) return;
    emit((number: number, loading: true, image: null));
    final result = await _viewer.page(number);
    if (!isClosed) emit((number: number, loading: false, image: result));
  }

  @override
  Future<void> close() {
    _viewer.close();
    return super.close();
  }
}
