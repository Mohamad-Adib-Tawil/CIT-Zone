import 'dart:async';

import 'package:flutter/material.dart';

import '../../features/auth/domain/google_identity_gateway.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/theme_mode_controller.dart';
import '../../features/app_status/domain/app_availability_repository.dart';
import '../cit_zone_app.dart';
import '../config/app_configuration.dart';
import '../di/app_dependencies.dart';

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({
    super.key,
    this.configuration,
    this.googleIdentityGatewayFactory,
    this.apiClientFactory,
    this.mobileAppGateway,
  });

  final AppConfiguration? configuration;
  final GoogleIdentityGateway Function()? googleIdentityGatewayFactory;
  final ApiClient Function()? apiClientFactory;
  final MobileAppGateway? mobileAppGateway;

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  late final AppDependencies _dependencies;
  late final Future<ThemeModeController> _themeController;

  @override
  void initState() {
    super.initState();
    _dependencies = AppDependencies(
      configuration: widget.configuration ?? AppConfiguration.fromBuild(),
      googleIdentityGatewayFactory: widget.googleIdentityGatewayFactory,
      apiClientFactory: widget.apiClientFactory,
      mobileAppGateway: widget.mobileAppGateway,
    );
    _themeController = ThemeModeController.load();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<ThemeModeController>(
    future: _themeController,
    builder: (context, snapshot) {
      final controller = snapshot.data;
      if (controller == null) {
        if (snapshot.hasError) {
          return CitZoneApp(dependencies: _dependencies);
        }
        return const SizedBox.shrink();
      }
      return CitZoneApp(
        dependencies: _dependencies,
        themeModeController: controller,
      );
    },
  );

  @override
  void dispose() {
    unawaited(
      _themeController.then<void>(
        (controller) => controller.dispose(),
        onError: (Object _, StackTrace __) {},
      ),
    );
    unawaited(_dependencies.dispose());
    super.dispose();
  }
}
