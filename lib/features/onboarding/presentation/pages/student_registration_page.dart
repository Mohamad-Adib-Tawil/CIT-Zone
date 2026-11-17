import 'package:cit_zone/core/localization/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../widgets/student_content_skeleton.dart';
import '../../../../core/errors/either.dart';
import '../../../auth/domain/google_identity.dart';
import '../../../auth/domain/student_registration.dart';
import '../../../auth/domain/student_session_repository.dart';
import '../../../auth/presentation/cubit/google_identity_cubit.dart';
import '../theme/hasobjy_visual_scope.dart';
import 'hasobjy_academic_screens.dart';

typedef _RegistrationState = ({
  List<StudentDepartment>? departments,
  StudentRegistrationSummary? summary,
  bool working,
  bool failed,
});

class _RegistrationCubit extends Cubit<_RegistrationState> {
  _RegistrationCubit(this.repository, this.identity)
    : super((departments: null, summary: null, working: false, failed: false));

  final StudentSessionRepository repository;
  final GoogleIdentity identity;

  Future<void> load() async {
    if (state.working) return;
    emit((departments: null, summary: null, working: true, failed: false));
    final departments = await repository.departments(identity);
    final summary = switch (departments) {
      Right(value: final items) when items.isNotEmpty =>
        await repository.registrationSummary(identity),
      _ => const Right<StudentSessionFailure, StudentRegistrationSummary?>(
        null,
      ),
    };
    if (isClosed) return;
    emit((
      departments: summary.isLeft()
          ? null
          : departments.getRight().toNullable(),
      summary: summary.getRight().toNullable(),
      working: false,
      failed: departments.isLeft() || summary.isLeft(),
    ));
  }

  Future<void> save(String departmentId, int year) async {
    if (state.working) return;
    final departments = state.departments;
    emit((
      departments: departments,
      summary: null,
      working: true,
      failed: false,
    ));
    final result = await repository.saveAcademicInfo(
      identity,
      departmentId,
      year,
    );
    if (isClosed) return;
    emit((
      departments: departments,
      summary: result.getRight().toNullable(),
      working: false,
      failed: result.isLeft(),
    ));
  }

  void edit() => emit((
    departments: state.departments,
    summary: null,
    working: false,
    failed: false,
  ));
}

class StudentRegistrationPage extends StatelessWidget {
  const StudentRegistrationPage({super.key, required this.repository});

  final StudentSessionRepository repository;

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<GoogleIdentityCubit, GoogleIdentityState>(
    builder: (context, auth) {
      final identity = switch (auth) {
        GoogleIdentityReady(
          session: StudentSession(next: StudentNextStep.completeRegistration),
        ) =>
          auth.identity,
        GoogleIdentityWorking(
          session: StudentSession(next: StudentNextStep.completeRegistration),
        ) =>
          auth.identity,
        _ => null,
      };
      if (identity == null) return const SizedBox.shrink();
      final authCubit = context.read<GoogleIdentityCubit>();
      return BlocProvider(
        key: ValueKey(identity.firebaseUid),
        create: (_) => _RegistrationCubit(repository, identity)..load(),
        child: BlocBuilder<_RegistrationCubit, _RegistrationState>(
          builder: (context, state) {
            final cubit = context.read<_RegistrationCubit>();
            final light = Theme.of(context).brightness == Brightness.light;
            final summary = state.summary;
            final departments = state.departments;
            final working = state.working || auth is GoogleIdentityWorking;
            if (departments == null || departments.isEmpty) {
              return Scaffold(
                appBar: AppBar(
                  title: Text(AppLocalizations.of(context).academicInfo),
                ),
                body: Center(
                  child: working
                      ? const SingleChildScrollView(
                          padding: EdgeInsets.all(24),
                          child: StudentContentSkeleton(
                            layout: StudentLoadingLayout.form,
                          ),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              state.failed
                                  ? 'تعذّر تحميل بيانات التسجيل.'
                                  : 'لا توجد أقسام متاحة للتسجيل حالياً.',
                            ),
                            TextButton(
                              onPressed: cubit.load,
                              child: Text(
                                AppLocalizations.of(context).appStatusRetry,
                              ),
                            ),
                            TextButton(
                              onPressed: authCubit.signOut,
                              child: Text(AppLocalizations.of(context).signOut),
                            ),
                          ],
                        ),
                ),
              );
            }
            final frame = summary == null ? 'B-S01' : 'B-S03';
            return HasobjyVisualScope(
              frameName: light ? '$frame-LIGHT' : frame,
              child: summary == null
                  ? HasobjyAcademicInfoScreen(
                      departments: departments,
                      onSave: cubit.save,
                      working: working,
                      error: state.failed
                          ? 'تعذّر قراءة أو حفظ بيانات التسجيل. أعد المحاولة.'
                          : null,
                    )
                  : HasobjyRegistrationSummaryScreen(
                      summary: summary,
                      onConfirm: working ? null : authCubit.confirmRegistration,
                      onEdit: working ? null : cubit.edit,
                      working: working,
                    ),
            );
          },
        ),
      );
    },
  );
}
