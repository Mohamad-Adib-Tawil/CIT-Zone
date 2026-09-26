import 'admin_models.dart';

abstract interface class AdminRepository {
  Future<AdminDashboardData> loadDashboard();
}
