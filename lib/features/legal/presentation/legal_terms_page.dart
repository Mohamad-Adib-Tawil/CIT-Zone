import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/either.dart';
import '../../onboarding/presentation/pages/preview/preview_widgets.dart';
import '../../onboarding/presentation/theme/hasobjy_visual_scope.dart';
import '../domain/legal_terms_repository.dart';

class LegalTermsPage extends StatefulWidget {
  const LegalTermsPage({
    super.key,
    required this.repository,
    required this.onBack,
    this.initialPrivacy = false,
    this.onOpenPrivacy,
  });

  final LegalTermsRepository repository;
  final VoidCallback onBack;
  final bool initialPrivacy;
  final Future<bool> Function()? onOpenPrivacy;

  @override
  State<LegalTermsPage> createState() => _LegalTermsPageState();
}

class _LegalTermsPageState extends State<LegalTermsPage> {
  late bool _privacy = widget.initialPrivacy;
  bool _openingPrivacy = false;
  bool _privacyOpenFailed = false;
  Future<Either<LegalTermsFailure, LegalTerms?>>? _terms;

  @override
  void initState() {
    super.initState();
    if (!_privacy) _terms = widget.repository.load();
  }

  void _select(int index) => setState(() {
    _privacy = index == 0;
    if (!_privacy) _terms ??= widget.repository.load();
  });

  Future<void> _openPrivacy() async {
    final open = widget.onOpenPrivacy;
    if (open == null || _openingPrivacy) return;
    setState(() {
      _openingPrivacy = true;
      _privacyOpenFailed = false;
    });
    var opened = false;
    try {
      opened = await open();
    } catch (_) {
      // Platform launch can fail even when the URL is valid.
    }
    if (!mounted) return;
    setState(() {
      _openingPrivacy = false;
      _privacyOpenFailed = !opened;
    });
  }

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    return HasobjyVisualScope(
      frameName: light ? 'A-S08-LIGHT' : 'A-S08',
      child: PreviewScaffold(
        title: 'الشروط والخصوصية',
        actions: PreviewActions(
          open: (_) {},
          notice: () {},
          back: widget.onBack,
        ),
        gap: 16,
        children: [
          PreviewTabs(
            labels: const ['سياسة الخصوصية', 'الشروط والأحكام'],
            selected: _privacy ? 0 : 1,
            onSelected: _select,
          ),
          if (_privacy)
            PreviewPanel(
              children: [
                if (widget.onOpenPrivacy == null)
                  const PreviewText('سياسة الخصوصية غير متاحة حالياً.')
                else ...[
                  TextButton(
                    onPressed: _openingPrivacy ? null : _openPrivacy,
                    child: Text(
                      'افتح سياسة الخصوصية في المتصفح',
                      style: HasobjyPalette(light).label,
                    ),
                  ),
                  if (_privacyOpenFailed)
                    Semantics(
                      liveRegion: true,
                      child: const PreviewText(
                        'تعذّر فتح سياسة الخصوصية. أعد المحاولة.',
                      ),
                    ),
                ],
              ],
            )
          else
            FutureBuilder<Either<LegalTermsFailure, LegalTerms?>>(
              future: _terms,
              builder: (context, snapshot) => _termsPanel(context, snapshot),
            ),
          const Spacer(),
          PreviewButton('فهمت', onTap: widget.onBack, light3D: true),
        ],
      ),
    );
  }

  Widget _termsPanel(
    BuildContext context,
    AsyncSnapshot<Either<LegalTermsFailure, LegalTerms?>> snapshot,
  ) {
    return PreviewPanel(
      gap: 14,
      children: snapshot.connectionState == ConnectionState.waiting
          ? [const Center(child: CircularProgressIndicator())]
          : switch (snapshot.data) {
              Right(value: final terms?) => [
                SelectableText(
                  terms.body,
                  style: context.design.bodyMedium,
                  textAlign: TextAlign.start,
                ),
                PreviewText(
                  'آخر تحديث · ${DateFormat.yMMMMd(Localizations.localeOf(context).languageCode).format(terms.publishedAt.toLocal())}',
                  style: context.design.bodySmall,
                  muted: true,
                ),
              ],
              Right() => [const PreviewText('لم تُنشر الشروط والأحكام بعد.')],
              _ => [
                const PreviewText('تعذّر تحميل الشروط والأحكام.'),
                TextButton(
                  onPressed: () => setState(() {
                    _terms = widget.repository.load();
                  }),
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            },
    );
  }
}
