import 'package:cit_zone/core/localization/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/google_identity.dart';
import '../../../auth/domain/student_registration.dart';
import '../../../auth/domain/student_session_repository.dart';
import '../../../auth/presentation/cubit/google_identity_cubit.dart';
import '../theme/hasobjy_visual_scope.dart';
import 'hasobjy_academic_screens.dart';

typedef _TermState = ({
  StudentTermRegistration? term,
  bool working,
  bool failed,
});

class _TermCubit extends Cubit<_TermState> {
  _TermCubit(this.repository, this.identity)
    : super((term: null, working: false, failed: false));

  final StudentSessionRepository repository;
  final GoogleIdentity identity;

  Future<void> load({String? description}) async {
    if (isClosed || state.working) return;
    final previous = state.term;
    emit((term: previous, working: true, failed: false));
    final result = description == null
        ? await repository.termRegistration(identity)
        : await repository.requestTermChange(identity, description);
    if (isClosed) return;
    emit((
      term: result.getRight().toNullable() ?? previous,
      working: false,
      failed: result.isLeft(),
    ));
  }
}

class StudentNewTermPage extends StatelessWidget {
  const StudentNewTermPage({super.key, required this.repository});

  final StudentSessionRepository repository;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<GoogleIdentityCubit, GoogleIdentityState>(
        builder: (context, auth) {
          final identity = switch (auth) {
            GoogleIdentityReady(
              session: StudentSession(next: StudentNextStep.confirmNewTerm),
            ) =>
              auth.identity,
            GoogleIdentityWorking(
              session: StudentSession(next: StudentNextStep.confirmNewTerm),
            ) =>
              auth.identity,
            _ => null,
          };
          if (identity == null) return const SizedBox.shrink();
          final authCubit = context.read<GoogleIdentityCubit>();
          return BlocProvider(
            key: ValueKey(identity.firebaseUid),
            create: (_) => _TermCubit(repository, identity)..load(),
            child: BlocBuilder<_TermCubit, _TermState>(
              builder: (context, state) {
                final cubit = context.read<_TermCubit>();
                final term = state.term;
                final working = state.working || auth is GoogleIdentityWorking;
                if (term == null) {
                  return Scaffold(
                    body: Center(
                      child: working
                          ? const CircularProgressIndicator()
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('تعذّر تحميل تفاصيل الفصل.'),
                                TextButton(
                                  onPressed: authCubit.revalidateSession,
                                  child: Text(
                                    AppLocalizations.of(context).appStatusRetry,
                                  ),
                                ),
                                TextButton(
                                  onPressed: authCubit.signOut,
                                  child: Text(
                                    AppLocalizations.of(context).signOut,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  );
                }
                final canAct = !working && !term.changePending;
                final light = Theme.of(context).brightness == Brightness.light;
                return HasobjyVisualScope(
                  frameName: light ? 'B-S04-LIGHT' : 'B-S04',
                  child: HasobjyNewTermScreen(
                    term: term,
                    working: working,
                    error: state.failed
                        ? 'تعذّر إرسال طلب التعديل. يمكنك المحاولة مجدداً.'
                        : null,
                    onConfirm: canAct ? authCubit.confirmNewTerm : null,
                    onChangeDetails: canAct
                        ? () => _requestChange(context, cubit)
                        : null,
                  ),
                );
              },
            ),
          );
        },
      );

  Future<void> _requestChange(BuildContext context, _TermCubit cubit) async {
    final description = await showDialog<String>(
      context: context,
      builder: (_) => const _TermChangeDialog(),
    );
    if (description != null && context.mounted) {
      await cubit.load(description: description);
    }
  }
}

class _TermChangeDialog extends StatefulWidget {
  const _TermChangeDialog();

  @override
  State<_TermChangeDialog> createState() => _TermChangeDialogState();
}

class _TermChangeDialogState extends State<_TermChangeDialog> {
  String _description = '';

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('طلب تعديل بيانات الفصل'),
    content: TextField(
      autofocus: true,
      maxLines: 4,
      maxLength: 1000,
      decoration: const InputDecoration(labelText: 'ما الذي تغيّر في بياناتك؟'),
      onChanged: (value) => setState(() => _description = value.trim()),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('إلغاء'),
      ),
      FilledButton(
        onPressed: _description.isEmpty
            ? null
            : () => Navigator.of(context).pop(_description),
        child: const Text('إرسال الطلب'),
      ),
    ],
  );
}
