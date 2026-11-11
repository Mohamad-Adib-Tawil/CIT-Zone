import 'dart:async';

import 'package:flutter/material.dart';

import '../../features/auth/domain/google_identity_gateway.dart';
import '../../core/network/api_client.dart';
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

  @override
  void initState() {
    super.initState();
    _dependencies = AppDependencies(
      configuration: widget.configuration ?? AppConfiguration.fromBuild(),
      googleIdentityGatewayFactory: widget.googleIdentityGatewayFactory,
      apiClientFactory: widget.apiClientFactory,
      mobileAppGateway: widget.mobileAppGateway,
    );
  }

  @override
  Widget build(BuildContext context) => CitZoneApp(dependencies: _dependencies);

  @override
  void dispose() {
    unawaited(_dependencies.dispose());
    super.dispose();
  }
}
