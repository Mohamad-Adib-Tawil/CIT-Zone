import 'package:cit_zone/core/localization/generated/app_localizations.dart';

import '../../../app_status/presentation/pages/startup_loading_page.dart';

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
          if (state is GoogleIdentityWorking) return const StartupLoadingPage();
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
                      if (ready != null) ...[
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
