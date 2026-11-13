import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/student_session_repository.dart';
import '../../../auth/presentation/cubit/google_identity_cubit.dart';
import '../theme/hasobjy_visual_scope.dart';
import 'hasobjy_auth_screens.dart';

class StudentOnboardingPage extends StatelessWidget {
  const StudentOnboardingPage({super.key, required this.step});

  final StudentNextStep step;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<GoogleIdentityCubit, GoogleIdentityState>(
        builder: (context, state) {
          final (identity, session, failure) = switch (state) {
            GoogleIdentityReady() => (
              state.identity,
              state.session,
              state.sessionFailure,
            ),
            GoogleIdentityWorking() => (state.identity, state.session, null),
            _ => (null, null, null),
          };
          if (identity == null || session?.next != step) {
            return const SizedBox.shrink();
          }
          final cubit = context.read<GoogleIdentityCubit>();
          final working = state is GoogleIdentityWorking;
          final courses = session?.usageType == StudentUsageType.courses;
          final frame = switch (step) {
            StudentNextStep.chooseUsageType => 'A-S03',
            StudentNextStep.completeBasicInfo => courses ? 'A-S09' : 'A-S04',
            _ => throw ArgumentError.value(step),
          };
          final light = Theme.of(context).brightness == Brightness.light;
          final error = switch (failure) {
            StudentSessionFailure.invalidBasicInfo =>
              'أدخل اسمك الرسمي بحروف، ورقم موبايل سوري بصيغة 09XXXXXXXX.',
            StudentSessionFailure.phoneTaken =>
              'رقم الهاتف مستخدم في حساب آخر.',
            _ => null,
          };
          return HasobjyVisualScope(
            frameName: light ? '$frame-LIGHT' : frame,
            child: switch (step) {
              StudentNextStep.chooseUsageType => HasobjyUsageTypeScreen(
                onContinue: () =>
                    cubit.chooseUsageType(StudentUsageType.institute),
                onContinueCourses: () =>
                    cubit.chooseUsageType(StudentUsageType.courses),
                onSignOut: cubit.signOut,
                working: working,
                error: error,
              ),
              StudentNextStep.completeBasicInfo => HasobjyBasicInfoScreen(
                identity: identity,
                onContinue: null,
                onSave: cubit.saveBasicInfo,
                onSignOut: cubit.signOut,
                showStepper: !courses,
                continueLabel: courses ? 'ابدأ التعلّم' : null,
                working: working,
                error: error,
              ),
              _ => throw ArgumentError.value(step),
            },
          );
        },
      );
}
