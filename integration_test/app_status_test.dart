import 'package:cit_zone/features/app_status/data/app_config_remote_data_source.dart';

import 'dart:convert';
import 'dart:ui' as ui;

import 'package:cit_zone/core/errors/either.dart';
import 'package:cit_zone/core/network/dio_api_client.dart';
import 'package:cit_zone/features/app_status/data/api_app_availability_repository.dart';
import 'package:cit_zone/features/app_status/data/native_mobile_app_gateway.dart';
import 'package:cit_zone/features/app_status/domain/app_availability.dart';
import 'package:cit_zone/features/app_status/presentation/cubit/app_availability_cubit.dart';
import 'package:cit_zone/features/app_status/presentation/pages/app_status_page.dart';
import 'package:cit_zone/features/onboarding/presentation/widgets/hasobjy_figma_components.dart';
import 'package:cit_zone/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/support/hasobjy_test_app.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final captures = <Map<String, Object>>[];
  binding.reportData = {'captures': captures};

  testWidgets(
    'installed app version and live public config cross native boundary',
    (tester) async {
      const gateway = NativeMobileAppGateway();
      final info = await gateway.readInfo();
      expect(info.version, isNotEmpty);
      AppVersion.parse(info.version);
      final client = DioApiClient(
        Uri.parse('https://hasobjy-system-api.vercel.app/api/v1/'),
      );
      addTearDown(client.close);
      final result = await ApiAppAvailabilityRepository(
        AppConfigRemoteDataSource(client),
        gateway,
      ).check();
      expect(result, isA<Right<AppAvailabilityFailure, AppAvailability>>());
      binding.reportData!['nativePlatform'] = info.platform.name;
      binding.reportData!['installedVersion'] = info.version;
      binding.reportData!['publicConfig'] =
          'successful read, no authentication or writes';
    },
  );

  testWidgets(
    'capture production status screens and verify responsive Arabic layout',
    (tester) async {
      const cases = <String, AppAvailabilityState>{
        'I-01': AppAvailabilityLoading(),
        'I-02': AppAvailabilityError(AppAvailabilityFailure.network),
        'I-03': AppAvailabilityLoaded(
          AppAvailability(AppAvailabilityKind.maintenance),
        ),
        'I-04': AppAvailabilityLoaded(
          AppAvailability(AppAvailabilityKind.updateRequired),
        ),
        'I-05': AppAvailabilityError(AppAvailabilityFailure.invalidResponse),
      };
      await tester.binding.setSurfaceSize(const Size(700, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final width in [390.0, 320.0, 600.0]) {
        for (final light in [false, true]) {
          for (final entry in cases.entries) {
            final key = GlobalKey();
            await tester.pumpWidget(
              arabicTestApp(
                Theme(
                  data: light ? AppTheme.light : AppTheme.dark,
                  child: Center(
                    child: SizedBox(
                      width: width,
                      height: 844,
                      child: MediaQuery(
                        data: MediaQueryData(
                          size: Size(width, 844),
                          textScaler: TextScaler.linear(width == 320 ? 1.5 : 1),
                        ),
                        child: RepaintBoundary(
                          key: key,
                          child: HasobjyReferenceViewport(
                            child: AppStatusPage(
                              state: entry.value,
                              onRetry: () {},
                              onUpdate: () {},
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: '${entry.key} $width light=$light',
            );
            final boundary =
                key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 1);
            final png = await image.toByteData(format: ui.ImageByteFormat.png);
            captures.add({
              'frame': '${entry.key}${light ? '-LIGHT' : ''}',
              'width': width.toInt(),
              'height': 844,
              'png': base64Encode(png!.buffer.asUint8List()),
            });
            image.dispose();
          }
        }
      }
    },
  );
}
