import 'package:cit_zone/core/localization/generated/app_localizations.dart';
import 'package:cit_zone/core/widgets/app_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/student_session_repository.dart';
import '../cubit/google_identity_cubit.dart';

class StudentSessionPage extends StatelessWidget {
  const StudentSessionPage({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<GoogleIdentityCubit, GoogleIdentityState>(
        builder: (context, state) {
          final cubit = context.read<GoogleIdentityCubit>();
          final messages = AppLocalizations.of(context);
          final ready = state is GoogleIdentityReady ? state : null;
          final message =
              ready?.error ??
              switch (ready?.session?.next) {
                StudentNextStep.suspended => 'الحساب موقوف.',
                StudentNextStep.deviceUnauthorized =>
                  'هذا الجهاز غير مصرّح له.',
                StudentNextStep.completeRegistration =>
                  'يلزم استكمال التسجيل قبل فتح المحتوى.',
                StudentNextStep.confirmNewTerm =>
                  'يلزم تأكيد الفصل قبل فتح المحتوى.',
                StudentNextStep.home => 'محتوى الطالب غير متاح في هذه النسخة.',
                _ => 'تعذّر التحقّق من حالة جلسة الطالب.',
              };
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (state is GoogleIdentityWorking)
                        const AppSkeleton(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            spacing: 12,
                            children: [
                              SkeletonBlock(width: 220, height: 18),
                              SkeletonBlock(width: 144, height: 14),
                            ],
                          ),
                        )
                      else if (ready != null) ...[
                        Text(message, textAlign: TextAlign.center),
                        if (ready.sessionFailure != null && ready.error == null)
                          TextButton(
                            onPressed: cubit.retrySession,
                            child: Text(messages.appStatusRetry),
                          ),
                        TextButton(
                          onPressed: cubit.signOut,
                          child: Text(messages.signOut),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
}
