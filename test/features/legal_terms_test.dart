import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cit_zone/core/network/api_cancellation_token.dart';
import 'package:cit_zone/core/network/api_client.dart';
import 'package:cit_zone/core/network/api_failure.dart';
import 'package:cit_zone/core/network/api_request.dart';
import 'package:cit_zone/core/widgets/app_skeleton.dart';
import 'package:cit_zone/features/legal/data/api_legal_terms_repository.dart';
import 'package:cit_zone/features/legal/domain/legal_terms_repository.dart';
import 'package:cit_zone/features/legal/presentation/legal_terms_page.dart';
import 'package:cit_zone/features/onboarding/presentation/widgets/hasobjy_figma_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/hasobjy_test_app.dart';

void main() {
  setUpAll(loadCairoForTests);

  test(
    'decodes only published documents or the exact unpublished sentinel',
    () async {
      final api = _LegalApi();
      final repository = ApiLegalTermsRepository(api);
      expect((await repository.load()).getRight().toNullable(), isNull);
      expect((await repository.load()).isRight(), isTrue);

      api.payload = _published;
      final document = (await repository.load()).getRight().toNullable();
      expect(document?.body, 'النص المنشور من الخادم');
      expect(document?.version, 3);
      expect(document?.publishedAt, DateTime.utc(2026, 11, 16));

      api.payload = {..._published, 'body': ' '};
      expect(
        (await repository.load()).getLeft().toNullable(),
        LegalTermsFailure.invalidResponse,
      );
    },
  );

  testWidgets(
    'configured privacy link opens once and allows retry after failure',
    (tester) async {
      final api = _LegalApi();
      final pending = Completer<bool>();
      var attempts = 0;
      await tester.pumpWidget(
        arabicTestApp(
          LegalTermsPage(
            repository: ApiLegalTermsRepository(api),
            initialPrivacy: true,
            onBack: () {},
            onOpenPrivacy: () {
              attempts++;
              return attempts == 1 ? pending.future : Future.value(true);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final button = find.text('افتح سياسة الخصوصية في المتصفح');
      await tester.tap(button);
      await tester.pump();
      await tester.tap(button);
      expect(attempts, 1);
      pending.complete(false);
      await tester.pumpAndSettle();
      expect(
        find.text('تعذّر فتح سياسة الخصوصية. أعد المحاولة.'),
        findsOneWidget,
      );
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(attempts, 2);
      expect(
        find.text('تعذّر فتح سياسة الخصوصية. أعد المحاولة.'),
        findsNothing,
      );
      expect(api.requests, isEmpty);
    },
  );

  for (final light in [true, false]) {
    testWidgets(
      'renders the published document at the Figma viewport light=$light',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final api = _LegalApi()..payload = _published;
        const surface = ValueKey('legal-surface');
        await tester.pumpWidget(
          arabicTestApp(
            Theme(
              data: light ? ThemeData.light() : ThemeData.dark(),
              child: RepaintBoundary(
                key: surface,
                child: HasobjyReferenceViewport(
                  child: LegalTermsPage(
                    repository: ApiLegalTermsRepository(api),
                    onBack: () {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('النص المنشور من الخادم'), findsOneWidget);
        expect(find.textContaining('آخر تحديث'), findsOneWidget);

        final output = Platform.environment['HASOBJY_LEGAL_OUTPUT'];
        if (output == null) return;
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(surface),
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          try {
            final png = await image.toByteData(format: ui.ImageByteFormat.png);
            Directory(output).createSync(recursive: true);
            File('$output/legal-${light ? 'light' : 'dark'}.png')
                .writeAsBytesSync(png!.buffer.asUint8List());
          } finally {
            image.dispose();
          }
        });
      },
    );
  }

  for (final (size, light) in [
    (const Size(320, 568), false),
    (const Size(390, 844), true),
    (const Size(390, 844), false),
  ]) {
    testWidgets(
      'legal tabs load only terms, retry and close at $size light=$light',
      (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final response = Completer<void>();
        final api = _LegalApi()
          ..offline = true
          ..responseGate = response.future;
        var closed = false;
        await tester.pumpWidget(
          arabicTestApp(
            Theme(
              data: light ? ThemeData.light() : ThemeData.dark(),
              child: LegalTermsPage(
                repository: ApiLegalTermsRepository(api),
                initialPrivacy: true,
                onBack: () => closed = true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('سياسة الخصوصية غير متاحة حالياً.'), findsOneWidget);
        expect(api.requests, isEmpty);

        await tester.tap(find.text('الشروط والأحكام'));
        await tester.pump();
        expect(find.byType(AppSkeleton), findsOneWidget);
        expect(api.requests, hasLength(1));

        response.complete();
        await tester.pump();
        expect(find.byType(AppSkeleton), findsNothing);
        expect(find.text('تعذّر تحميل الشروط والأحكام.'), findsOneWidget);
        api.offline = false;
        await tester.tap(find.text('إعادة المحاولة'));
        await tester.pumpAndSettle();
        expect(find.text('لم تُنشر الشروط والأحكام بعد.'), findsOneWidget);

        await tester.tap(find.text('سياسة الخصوصية'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('الشروط والأحكام'));
        await tester.pumpAndSettle();
        expect(api.requests, hasLength(2));
        await tester.ensureVisible(find.text('فهمت'));
        await tester.tap(find.text('فهمت'));
        expect(closed, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

const _published = {
  'version': 3,
  'body': 'النص المنشور من الخادم',
  'publishedAt': '2026-11-16T00:00:00.000Z',
};

class _LegalApi implements ApiClient {
  final requests = <ApiRequest>[];
  Object? payload = const {'version': 0, 'body': '', 'publishedAt': null};
  bool offline = false;
  Future<void>? responseGate;

  @override
  Future<ApiResponse> send(
    ApiRequest request, {
    ApiCancellationToken? cancellationToken,
  }) async {
    expect(request.method, 'GET');
    expect(request.path, 'legal/terms');
    expect(request.headers, isEmpty);
    requests.add(request);
    if (responseGate case final gate?) await gate;
    if (offline) throw const ApiFailure(ApiFailureKind.network);
    return ApiResponse(
      statusCode: 200,
      json: {'data': payload},
      requestId: 'legal-test',
    );
  }

  @override
  void close() {}
}
