import 'package:cit_zone/features/auth/data/hasobjy_firebase_configuration.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('native Firebase initializes with the registered mobile app', (
    tester,
  ) async {
    final auth = await HasobjyFirebaseConfiguration.initializeAuth();
    expect(auth.app.options.projectId, 'cit-learn-dc483');
    expect(
      auth.app.options.appId,
      HasobjyFirebaseConfiguration.currentPlatform.appId,
    );
    // No sign-in, token output, user creation or mutation of existing accounts.
  });
}
