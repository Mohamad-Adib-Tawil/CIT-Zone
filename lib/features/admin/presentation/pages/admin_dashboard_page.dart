import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/admin_dashboard_cubit.dart';
import '../widgets/admin_shell.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
      builder: (context, state) {
        return switch (state) {
          AdminDashboardLoading() => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          AdminDashboardFailure() => Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off_rounded, size: 48),
                  const SizedBox(height: 16),
                  const Text('تعذر تحميل لوحة الإدارة'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.read<AdminDashboardCubit>().load(),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            ),
          ),
          AdminDashboardReady(:final data, :final refreshing, :final error) =>
            AdminShell(
              data: data,
              refreshing: refreshing,
              error: error,
              onRefresh: () => context.read<AdminDashboardCubit>().load(),
            ),
        };
      },
    );
  }
}
