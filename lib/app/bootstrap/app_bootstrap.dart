import 'dart:async';

import 'package:flutter/material.dart';

import '../../features/auth/domain/google_identity_gateway.dart';
import '../cit_zone_app.dart';
import '../config/app_configuration.dart';
import '../di/app_dependencies.dart';

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({
    super.key,
    this.configuration,
    this.googleIdentityGatewayFactory,
  });

  final AppConfiguration? configuration;
  final GoogleIdentityGateway Function()? googleIdentityGatewayFactory;

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
