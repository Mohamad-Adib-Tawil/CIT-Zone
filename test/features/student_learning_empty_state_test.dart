import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cit_zone/core/errors/either.dart';
import 'package:cit_zone/core/widgets/app_skeleton.dart';
import 'package:cit_zone/core/localization/generated/app_localizations_ar.dart';
import 'package:cit_zone/features/auth/data/google_identity_repository_impl.dart';
import 'package:cit_zone/features/auth/domain/google_identity.dart';
import 'package:cit_zone/features/auth/domain/student_learning.dart';
import 'package:cit_zone/features/auth/domain/student_session_repository.dart';
import 'package:cit_zone/features/auth/presentation/cubit/google_identity_cubit.dart';
import 'package:cit_zone/features/onboarding/presentation/pages/preview/preview_widgets.dart';
import 'package:cit_zone/features/onboarding/presentation/pages/preview/profile_preview_screens.dart';
import 'package:cit_zone/features/onboarding/presentation/pages/student_exercise_prompt.dart';
import 'package:cit_zone/features/onboarding/presentation/pages/student_learning_page.dart';
import 'package:cit_zone/features/onboarding/presentation/widgets/hasobjy_learning_empty_state.dart';
import 'package:cit_zone/features/onboarding/presentation/widgets/hasobjy_figma_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_google_identity_gateway.dart';
import '../support/hasobjy_test_app.dart';

const _notificationTermId = '1fc5f52f-cc90-44af-8573-e99923228115';

void main() {
  setUpAll(loadCairoForTests);

  for (final (size, mode) in [
    (const Size(320, 568), ThemeMode.dark),
    (const Size(390, 844), ThemeMode.light),
    (const Size(390, 844), ThemeMode.dark),
    (const Size(430, 932), ThemeMode.dark),
  ]) {
    testWidgets('renders live empty results at $size in $mode', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repository = _StudentRepository();
      await _openLearning(tester, repository, mode);
      expect(find.byType(AppSkeleton), findsOneWidget);
      expect(find.byType(HasobjyLearningEmptyState), findsNothing);
      await _capture(tester, size, mode, 'home-loading');

      repository.homeResult.complete(
        const Right((
          name: 'طالب اختبار',
          resumeLesson: null,
          subjects: [],
          courses: [],
        )),
      );
      await tester.pumpAndSettle();
      expect(find.text('لا يوجد محتوى لعرضه الآن'), findsOneWidget);
      await _capture(tester, size, mode, 'home');

      await tester.tap(find.text('المواد'));
      await tester.pumpAndSettle();
      expect(find.text('لا توجد مواد متاحة'), findsOneWidget);
      await _capture(tester, size, mode, 'subjects');

      await tester.tap(find.text('الفصول السابقة'));
      await tester.pumpAndSettle();
      expect(find.text('لا توجد مواد متاحة'), findsNothing);
      await tester.tap(find.text('قواعد البيانات'));
      await tester.pumpAndSettle();
      expect(find.text('لا توجد دروس منشورة'), findsOneWidget);
      await _capture(tester, size, mode, 'lessons');

      await tester.tap(find.text('الكورسات'));
      await tester.pumpAndSettle();
      expect(find.text('لا توجد كورسات متاحة'), findsOneWidget);
      await _capture(tester, size, mode, 'courses');
      await tester.tap(find.text('كورساتي'));
      await tester.pumpAndSettle();
      expect(find.text('لا توجد كورسات مشترك بها حالياً'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets(
      'switches exam sessions and reuses the cached schedule in $mode',
      (tester) async {
        const size = Size(390, 844);
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final repository = _StudentRepository()..manySubjects = true;
        await _openLearning(tester, repository, mode);
        repository.homeResult.complete(
          const Right((
            name: 'طالب اختبار',
            resumeLesson: null,
            subjects: [],
            courses: [],
          )),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('المواد'));
        await tester.pumpAndSettle();
        final strings = AppLocalizationsAr();
        await tester.tap(find.text(strings.examSchedule));
        await tester.pumpAndSettle();
        expect(find.text('قواعد البيانات'), findsOneWidget);
        expect(find.textContaining('القاعة غير معيّنة'), findsOneWidget);
        await _capture(tester, size, mode, 'exam-schedule');

        await tester.tap(find.text(strings.supplementaryExams));
        await tester.pumpAndSettle();
        expect(
          find.text('لا توجد امتحانات مجدولة لهذه الدورة.'),
          findsOneWidget,
        );
        await tester.tap(find.text(strings.regularExams));
        await tester.pumpAndSettle();
        expect(find.text('قواعد البيانات'), findsOneWidget);
        expect(repository.examRequests, StudentExamSession.values);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('shows cached home and real lesson metadata in $mode', (
      tester,
    ) async {
      const size = Size(390, 844);
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repository = _StudentRepository(withLessons: true);
      await _openLearning(tester, repository, mode);
      repository.homeResult.complete(
        const Right((
          name: 'طالب اختبار',
          resumeLesson: null,
          subjects: [],
          courses: [],
        )),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('المواد'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('الفصول السابقة'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('قواعد البيانات'));
      await tester.pumpAndSettle();
      expect(find.text('1. مقدمة في قواعد البيانات'), findsOneWidget);
      expect(find.text('18 دقيقة'), findsOneWidget);
      expect(find.text('0 من 0 درساً مكتملة'), findsOneWidget);
      await _capture(tester, size, mode, 'lessons-populated');

      await tester.tap(find.text('الرئيسية'));
      await tester.pump();
      expect(find.text('مرحباً طالب اختبار'), findsOneWidget);
      expect(find.byType(AppSkeleton), findsNothing);
      expect(repository.homeRequests, 1);
      expect(tester.takeException(), isNull);
    });
  }

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets(
      'settings works while the profile request is pending or fails in $mode',
      (tester) async {
        const size = Size(390, 844);
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final repository = _StudentRepository();
        await _openLearning(tester, repository, mode);
        await tester.tap(find.text('الإعدادات'));
        await tester.pumpAndSettle();

        expect(find.text('طالب اختبار'), findsOneWidget);
        expect(find.text('المظهر'), findsOneWidget);
        expect(find.text('تسجيل الخروج'), findsOneWidget);
        expect(find.byType(AppSkeleton), findsNothing);
        expect(repository.profileRequests, 1);
        await _capture(tester, size, mode, 'settings');

        await tester.tap(find.text('ملفي الشخصي'));
        await tester.pump();
        expect(find.byType(AppSkeleton), findsOneWidget);
        expect(repository.profileRequests, 1);
        repository.profileResult.complete(
          const Left(StudentSessionFailure.unavailable),
        );
        await tester.pumpAndSettle();
        expect(find.text('تعذّر تحميل البيانات.'), findsOneWidget);
        await tester.tap(
          find.descendant(
            of: find.byType(HasobjyAppBar),
            matching: find.byType(IconButton),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('تسجيل الخروج'), findsOneWidget);
        await tester.tap(find.text('الجهاز المسجّل'));
        await tester.pumpAndSettle();
        expect(find.text('جهاز الاختبار'), findsOneWidget);
        expect(find.text('Android'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('subject tabs load separately and reuse the cached files', (
    tester,
  ) async {
    final repository = _StudentRepository(withLessons: true);
    await _openLearning(tester, repository, ThemeMode.dark);
    await tester.tap(find.text('المواد'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الفصول السابقة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('قواعد البيانات'));
    await tester.pumpAndSettle();

    expect(repository.fileRequests, 0);
    await tester.tap(find.text('الملفات'));
    await tester.pumpAndSettle();
    expect(find.text('ملف المادة'), findsOneWidget);
    await tester.tap(find.text('التمارين'));
    await tester.pumpAndSettle();
    expect(find.text('لا توجد تمارين منشورة.'), findsOneWidget);
    await tester.tap(find.text('الملفات'));
    await tester.pumpAndSettle();
    expect(find.text('ملف المادة'), findsOneWidget);
    expect(repository.fileRequests, 1);
  });

  testWidgets('subject files and exercises build near the viewport', (
    tester,
  ) async {
    final repository = _StudentRepository()..manyResources = true;
    await _openLearning(tester, repository, ThemeMode.dark);
    await tester.tap(find.text('المواد'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الفصول السابقة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('قواعد البيانات'));
    await tester.pumpAndSettle();

    for (final (tab, last) in [
      ('الملفات', 'الملف 24'),
      ('التمارين', 'التمرين 24'),
    ]) {
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
      final card = find.text(last);
      expect(card, findsNothing);
      await tester.scrollUntilVisible(card, 240);
      await tester.pumpAndSettle();
      expect(card.hitTestable(), findsOneWidget);

      tester.state<ScrollableState>(find.byType(Scrollable)).position.jumpTo(0);
      await tester.pumpAndSettle();
    }
  });

  testWidgets('returning from a lesson restores the subject scroll', (
    tester,
  ) async {
    final repository = _StudentRepository()..manyLessons = true;
    await _openLearning(tester, repository, ThemeMode.dark);
    await tester.tap(find.text('المواد'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الفصول السابقة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('قواعد البيانات'));
    await tester.pumpAndSettle();

    final lesson = find.text('الدرس 12');
    expect(lesson, findsNothing);
    await tester.scrollUntilVisible(lesson, 220);
    await tester.pumpAndSettle();
    final scrollable = find.byType(Scrollable);
    final offset = tester.state<ScrollableState>(scrollable).position.pixels;
    expect(offset, greaterThan(0));

    await tester.tap(lesson);
    await tester.pumpAndSettle();
    expect(repository.lessonRequests, ['lesson-12']);
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();

    expect(tester.state<ScrollableState>(scrollable).position.pixels, offset);
    expect(lesson.hitTestable(), findsOneWidget);
  });

  testWidgets('file reader keeps its page during a network retry', (
    tester,
  ) async {
    final pending =
        Completer<Either<StudentFileViewFailure, StudentFilePage>>();
    final firstPage = Completer<void>();
    final viewer = _FileViewer()
      ..firstPageGate = firstPage.future
      ..nextPage = () => pending.future;
    await _openLearning(
      tester,
      _StudentRepository(withLessons: true)..viewer = viewer,
      ThemeMode.dark,
    );
    await tester.tap(find.text('المواد'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الفصول السابقة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('قواعد البيانات'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الملفات'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ملف المادة'));
    await tester.pump();
    expect(find.byType(AppSkeleton), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    firstPage.complete();
    await tester.pump();
    expect(find.byType(AppSkeleton), findsNothing);
    await tester.pumpAndSettle();

    final next = find.text('التالية');
    await tester.ensureVisible(next);
    await tester.tap(next);
    await tester.pump();
    expect(find.text('صفحة 1 من 2'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    pending.complete(const Left(StudentFileViewFailure.network));
    await tester.pumpAndSettle();
    expect(find.text('صفحة 1 من 2'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Image && widget.image is ResizeImage,
      ),
      findsOneWidget,
    );

    final image = find.byWidgetPredicate(
      (widget) => widget is Image && widget.image is ResizeImage,
    );
    Future<bool?> tracked(ImageProvider provider) async =>
        (await provider.obtainCacheStatus(
          configuration: ImageConfiguration.empty,
        ))?.tracked;
    final firstProvider = tester.widget<Image>(image).image;
    expect(await tracked(firstProvider), isTrue);

    viewer.nextPage = () async =>
        Right((bytes: Uint8List.fromList([1, 2, 3]), totalPages: 2));
    final retry = find.text('إعادة المحاولة');
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(find.text('صفحة 2 من 2'), findsOneWidget);
    expect(find.text('تعذّر عرض صورة الصفحة.'), findsOneWidget);
    expect(await tracked(firstProvider), isFalse);

    viewer.nextPage = () => viewer.page(1);
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(find.text('صفحة 2 من 2'), findsOneWidget);
    expect(retry, findsNothing);

    final secondProvider = tester.widget<Image>(image).image;
    expect(await tracked(secondProvider), isTrue);
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(await tracked(secondProvider), isFalse);
  });

  testWidgets(
    'the file reader bounds image decoding and closes on device denial',
    (tester) async {
      final viewer = _FileViewer();
      final repository = _StudentRepository(withLessons: true)..viewer = viewer;
      final cubit = await _openLearning(tester, repository, ThemeMode.dark);
      await tester.tap(find.text('المواد'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('الفصول السابقة'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('قواعد البيانات'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('الملفات'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ملف المادة'));
      await tester.pumpAndSettle();

      final image = tester.widget<Image>(
        find.byWidgetPredicate(
          (widget) => widget is Image && widget.image is ResizeImage,
        ),
      );
      final provider = image.image as ResizeImage;
      expect(provider.width, lessThanOrEqualTo(1280));
      expect(provider.height, 1920);
      expect(provider.policy, ResizeImagePolicy.fit);

      final next = find.text('التالية');
      await tester.ensureVisible(next);
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(
        (cubit.state as GoogleIdentityReady).session?.next,
        StudentNextStep.deviceUnauthorized,
      );
      expect(viewer.closed, isTrue);
      expect(find.text('عرض فقط'), findsNothing);
    },
  );

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets(
      'shows real resume data even without current materials in $mode',
      (tester) async {
        const size = Size(390, 844);
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final repository = _StudentRepository();
        await _openLearning(tester, repository, mode);
        repository.homeResult.complete(
          const Right((
            name: 'طالب اختبار',
            resumeLesson: (
              lessonId: 'lesson',
              lessonTitle: 'العلاقات بين الجداول',
              subjectId: 'databases',
              subjectName: 'قواعد البيانات',
              positionSeconds: 180,
              durationSeconds: 900,
            ),
            subjects: [],
            courses: [],
          )),
        );
        await tester.pumpAndSettle();
        expect(find.text('متابعة المشاهدة'), findsOneWidget);
        expect(find.text('العلاقات بين الجداول'), findsOneWidget);
        expect(find.text('قواعد البيانات · متبقٍ 12 دقيقة'), findsOneWidget);
        expect(find.byType(HasobjyLearningEmptyState), findsNothing);
        await tester.tap(find.text('العلاقات بين الجداول'));
        await tester.pumpAndSettle();
        expect(find.text('تفاصيل العلاقات بين الجداول'), findsOneWidget);
        expect(find.text('12:40 / 27:00'), findsOneWidget);
        await _capture(tester, size, mode, 'lesson-position');
        await tester.tap(find.text('قيّم هذا الدرس'));
        await tester.pumpAndSettle();
        await tester.tap(find.bySemanticsLabel('4 من 5'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('إرسال التقييم'));
        await tester.pumpAndSettle();
        expect(find.text('شاهد الدرس أولاً قبل تقييمه.'), findsOneWidget);
        await tester.tap(find.text('إرسال التقييم'));
        await tester.pumpAndSettle();
        expect(find.text('تقييمك: 4 من 5'), findsOneWidget);
        await tester.tap(
          find.descendant(
            of: find.byType(HasobjyAppBar),
            matching: find.byType(IconButton),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('متابعة المشاهدة'), findsOneWidget);
        expect(repository.homeRequests, 1);
      },
    );
  }

  testWidgets('a rejected rating closes the modal and learning shell', (
    tester,
  ) async {
    final repository = _StudentRepository()
      ..ratingDenial = StudentSessionFailure.deviceUnauthorized;
    final cubit = await _openLearning(tester, repository, ThemeMode.dark);
    repository.homeResult.complete(
      const Right((
        name: 'طالب اختبار',
        resumeLesson: (
          lessonId: 'lesson',
          lessonTitle: 'درس الاختبار',
          subjectId: 'databases',
          subjectName: 'قواعد البيانات',
          positionSeconds: 180,
          durationSeconds: 900,
        ),
        subjects: [],
        courses: [],
      )),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('درس الاختبار'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('قيّم هذا الدرس'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('4 من 5'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إرسال التقييم'));
    await tester.pumpAndSettle();

    expect(find.text('إرسال التقييم'), findsNothing);
    expect(find.text('تفاصيل العلاقات بين الجداول'), findsNothing);
    expect(
      (cubit.state as GoogleIdentityReady).session?.next,
      StudentNextStep.deviceUnauthorized,
    );
    expect(repository.ratingRequests, 1);
  });

  testWidgets('settings opens subscriptions and browses available courses', (
    tester,
  ) async {
    final repository = _StudentRepository();
    await _openLearning(tester, repository, ThemeMode.dark);
    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('اشتراكاتي'));
    await tester.pumpAndSettle();
    expect(find.text('كورس الاختبار'), findsOneWidget);
    expect(find.text('ينتهي قريباً'), findsOneWidget);
    await tester.tap(find.text('تصفّح الكورسات'));
    await tester.pumpAndSettle();
    expect(find.text('كل الكورسات'), findsOneWidget);
  });

  testWidgets('settings opens the support conversation', (tester) async {
    final repository = _StudentRepository();
    await _openLearning(tester, repository, ThemeMode.dark);
    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('الدعم والتواصل'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الدعم والتواصل'));
    await tester.pumpAndSettle();
    expect(find.text('مشكلة في الدرس'), findsOneWidget);
    await tester.tap(find.text('تذكرة جديدة'));
    await tester.pumpAndSettle();
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(repository.supportReads, 1);
    await tester.tap(find.text('مشكلة في الدرس'));
    await tester.pumpAndSettle();
    expect(find.text('رد فريق الدعم'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'رسالة الطالب');
    await tester.tap(find.text('إرسال الرد'));
    await tester.pumpAndSettle();
    expect(find.text('تعذّر تأكيد إرسال الرد. أعد المحاولة.'), findsOneWidget);
    expect(find.text('رسالة الطالب'), findsOneWidget);
    await tester.tap(find.text('إرسال الرد'));
    await tester.pumpAndSettle();
    expect(find.text('رسالة الطالب'), findsOneWidget);
    expect(repository.replyKeys, hasLength(2));
    expect(repository.replyKeys.first, repository.replyKeys.last);

    repository.pendingSupportPage =
        Completer<Either<StudentSessionFailure, StudentTicketPage>>();
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pump();
    expect(repository.supportReads, 2);
    expect(find.text('مشكلة في الدرس'), findsOneWidget);
    repository.pendingSupportPage!.complete(
      const Left(StudentSessionFailure.unavailable),
    );
    await tester.pumpAndSettle();
    expect(find.text('مشكلة في الدرس'), findsOneWidget);
  });

  testWidgets('creates a support ticket and opens its conversation', (
    tester,
  ) async {
    final repository = _StudentRepository();
    await _openLearning(tester, repository, ThemeMode.dark);
    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('الدعم والتواصل'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الدعم والتواصل'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تذكرة جديدة'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, ' عنوان جديد ');
    await tester.enterText(find.byType(TextField).last, ' تفاصيل جديدة ');
    await tester.ensureVisible(find.text('إرسال التذكرة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إرسال التذكرة'));
    await tester.pumpAndSettle();
    expect(repository.createdTicket, ('عنوان جديد', 'تفاصيل جديدة'));
    expect(find.text('عنوان جديد'), findsOneWidget);
    expect(find.text('رد فريق الدعم'), findsOneWidget);
  });

  testWidgets('leaving an open support thread cancels its pending read', (
    tester,
  ) async {
    final repository = _StudentRepository()
      ..pendingThread =
          Completer<Either<StudentSessionFailure, StudentTicketThread>>();
    await _openLearning(tester, repository, ThemeMode.dark);
    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('الدعم والتواصل'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الدعم والتواصل'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('مشكلة في الدرس'));
    await tester.pump();
    expect(repository.threadReads, 1);
    expect(repository.cancelledThreadReads, 0);

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(repository.cancelledThreadReads, 1);
    repository.pendingThread!.complete(
      const Left(StudentSessionFailure.unavailable),
    );
    repository.pendingThread = null;
    await tester.tap(find.text('مشكلة في الدرس'));
    await tester.pumpAndSettle();
    expect(repository.threadReads, 2);
    expect(find.text('رد فريق الدعم'), findsOneWidget);
  });

  testWidgets('opens the academic exercise from the subject tab', (
    tester,
  ) async {
    final repository = _StudentRepository(withLessons: true)
      ..showExercise = true;
    await _openLearning(tester, repository, ThemeMode.dark);
    await tester.tap(find.text('المواد'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الفصول السابقة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('قواعد البيانات'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('التمارين'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تمرين SQL'));
    await tester.pumpAndSettle();
    expect(find.text('اكتب استعلاماً'), findsOneWidget);
    expect(find.text('SELECT *'), findsOneWidget);
    await tester.ensureVisible(find.text('إرسال للتصحيح'));
    await tester.tap(find.text('إرسال للتصحيح'));
    await tester.pumpAndSettle();
    expect(find.text('85/100'), findsOneWidget);
    expect(find.text('استعلام صحيح'), findsOneWidget);
    await tester.ensureVisible(find.text('العودة إلى التمارين'));
    await tester.tap(find.text('العودة إلى التمارين'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تمرين SQL'));
    await tester.pumpAndSettle();
    expect(find.text('85/100'), findsOneWidget);
    expect(repository.exerciseSubmissions, 1);
    expect(repository.exerciseReads, 1);
  });

  testWidgets('leaving an exercise cancels its unpublished attempt read', (
    tester,
  ) async {
    final pending = Completer<Either<StudentSessionFailure, StudentAttempt?>>();
    var cancelled = false;
    await tester.pumpWidget(
      arabicTestApp(
        Scaffold(
          body: StudentExercisePromptView(
            prompt: const StudentCodingPrompt(
              'تمرين SQL',
              'اكتب استعلاماً',
              'SQL',
              'SELECT *',
            ),
            submit: (key, {code, language, choiceId}) async =>
                const Left(StudentSessionFailure.unavailable),
            readAttempt: (id, whenCanceled) async =>
                const Left(StudentSessionFailure.unavailable),
            latestAttempt: (whenCanceled) {
              unawaited(whenCanceled.then((_) => cancelled = true));
              return pending.future;
            },
            onBack: () {},
          ),
        ),
      ),
    );
    expect(cancelled, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(cancelled, isTrue);
    pending.complete(const Right(null));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('files open while the lesson request remains pending', (
    tester,
  ) async {
    final repository = _StudentRepository()..pendingLessons = Completer();
    await _openLearning(tester, repository, ThemeMode.dark);
    await tester.tap(find.text('المواد'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الفصول السابقة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('قواعد البيانات'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(AppSkeleton), findsOneWidget);
    await tester.tap(find.text('الملفات'));
    await tester.pumpAndSettle();
    expect(find.text('ملف المادة'), findsOneWidget);
    repository.pendingLessons!.complete(const Right([]));
  });

  testWidgets(
    'session revalidation retains the active student tab until rejection',
    (tester) async {
      final repository = _StudentRepository();
      final cubit = await _openLearning(tester, repository, ThemeMode.dark);
      await tester.tap(find.text('المواد'));
      await tester.pumpAndSettle();
      final check = cubit.revalidateSession();
      await tester.pump();
      expect(find.text('الفصل الحالي'), findsOneWidget);
      repository.sessionCheck.complete(
        const Right(
          StudentSession(
            next: StudentNextStep.deviceUnauthorized,
            usageType: StudentUsageType.institute,
          ),
        ),
      );
      await check;
      await tester.pumpAndSettle();
      expect(find.text('الفصل الحالي'), findsNothing);
    },
  );

  testWidgets('a server usage change drops the previous learning scope', (
    tester,
  ) async {
    final repository = _StudentRepository();
    final cubit = await _openLearning(tester, repository, ThemeMode.dark);
    repository.homeResult.complete(
      const Right((
        name: 'طالب اختبار',
        resumeLesson: null,
        subjects: [],
        courses: [],
      )),
    );
    await tester.pumpAndSettle();
    expect(repository.homeRequests, 1);
    await tester.tap(find.text('المواد'));
    await tester.pumpAndSettle();

    final check = cubit.revalidateSession();
    await tester.pump();
    expect(find.text('الفصل الحالي'), findsOneWidget);
    repository.sessionCheck.complete(
      const Right(
        StudentSession(
          next: StudentNextStep.home,
          usageType: StudentUsageType.courses,
        ),
      ),
    );
    await check;
    await tester.pumpAndSettle();

    expect(find.text('الفصل الحالي'), findsNothing);
    expect(find.text('المواد'), findsNothing);
    expect(find.text('مرحباً طالب اختبار'), findsOneWidget);
    expect(repository.homeRequests, 2);
  });

  testWidgets(
    'the visible device refreshes after session acceptance only when stale',
    (tester) async {
      final repository = _StudentRepository();
      var now = DateTime.utc(2026, 11, 16);
      final cubit = await _openLearning(
        tester,
        repository,
        ThemeMode.dark,
        cacheClock: () => now,
      );
      await tester.tap(find.text('الإعدادات'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('الجهاز المسجّل'));
      await tester.pumpAndSettle();
      expect(find.text('جهاز الاختبار'), findsOneWidget);
      expect(repository.deviceRequests, 1);

      final firstCheck = cubit.revalidateSession();
      await tester.pump();
      expect(repository.deviceRequests, 1);
      repository.sessionCheck.complete(
        const Right(
          StudentSession(
            next: StudentNextStep.home,
            usageType: StudentUsageType.institute,
          ),
        ),
      );
      await firstCheck;
      await tester.pumpAndSettle();
      expect(repository.deviceRequests, 1);

      now = now.add(const Duration(seconds: 21));
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      unawaited(
        navigator.push<void>(
          MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('صفحة أخرى')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await cubit.revalidateSession();
      await tester.pumpAndSettle();
      expect(repository.deviceRequests, 1);
      navigator.pop();
      await tester.pumpAndSettle();

      repository.pendingDevice =
          Completer<Either<StudentSessionFailure, StudentDeviceData>>();
      await cubit.revalidateSession();
      await tester.pump();
      expect(repository.deviceRequests, 2);
      expect(repository.profileRequests, 1);
      expect(find.text('جهاز الاختبار'), findsOneWidget);
      expect(find.byType(AppSkeleton), findsNothing);

      repository.pendingDevice!.complete(
        const Right((
          status: StudentDeviceStatus.authorized,
          name: 'الجهاز المحدّث',
          platform: 'ios',
          registeredAt: null,
        )),
      );
      await tester.pumpAndSettle();
      expect(find.text('الجهاز المحدّث'), findsOneWidget);
      expect(find.text('جهاز الاختبار'), findsNothing);
    },
  );

  testWidgets(
    'a device rejection from a content request wins over a late session check',
    (tester) async {
      final repository = _StudentRepository();
      final cubit = await _openLearning(tester, repository, ThemeMode.dark);
      final check = cubit.revalidateSession();
      repository.homeResult.complete(
        const Left(StudentSessionFailure.deviceUnauthorized),
      );
      await tester.pumpAndSettle();
      expect(find.text('المواد'), findsNothing);
      repository.sessionCheck.complete(
        const Right(
          StudentSession(
            next: StudentNextStep.home,
            usageType: StudentUsageType.institute,
          ),
        ),
      );
      await check;
      await tester.pumpAndSettle();
      expect(
        (cubit.state as GoogleIdentityReady).session?.next,
        StudentNextStep.deviceUnauthorized,
      );
      expect(find.text('المواد'), findsNothing);
    },
  );

  testWidgets('returning to the subjects tab restores its scroll position', (
    tester,
  ) async {
    final repository = _StudentRepository()..manySubjects = true;
    await _openLearning(tester, repository, ThemeMode.dark);
    await tester.tap(find.text('المواد'));
    await tester.pumpAndSettle();
    final scrollable = find.byType(Scrollable);
    expect(find.text('قواعد البيانات').evaluate().length, lessThan(19));
    expect(find.text('آخر مادة'), findsNothing);
    await tester.drag(scrollable, const Offset(0, -400));
    await tester.pumpAndSettle();
    final offset = tester.state<ScrollableState>(scrollable).position.pixels;
    expect(offset, greaterThan(0));

    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('المواد'));
    await tester.pumpAndSettle();
    expect(tester.state<ScrollableState>(scrollable).position.pixels, offset);
    await tester.scrollUntilVisible(
      find.text('آخر مادة'),
      350,
      scrollable: scrollable,
    );
    expect(find.text('آخر مادة').hitTestable(), findsOneWidget);
  });

  testWidgets('course cards are lazy and pagination reuses fresh data', (
    tester,
  ) async {
    final repository = _StudentRepository()..manyCourses = true;
    await _openLearning(tester, repository, ThemeMode.dark);
    await tester.tap(find.text('الكورسات'));
    await tester.pumpAndSettle();
    final scrollable = find.byType(Scrollable);
    expect(find.text('كورس 1'), findsOneWidget);
    expect(find.text('كورس 20'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('التالي'),
      400,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    expect(find.text('كورس 20'), findsOneWidget);
    final offset = tester.state<ScrollableState>(scrollable).position.pixels;
    expect(offset, greaterThan(0));
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    expect(find.text('كورس 21'), findsOneWidget);
    expect(tester.state<ScrollableState>(scrollable).position.pixels, 0);

    await tester.tap(find.text('السابق'));
    await tester.pumpAndSettle();
    expect(tester.state<ScrollableState>(scrollable).position.pixels, offset);
    expect(repository.coursePages, [(false, 1), (false, 2)]);
  });

  testWidgets('course content builds lazily and restores its scroll', (
    tester,
  ) async {
    final repository = _StudentRepository()
      ..showCourse = true
      ..longCourse = true;
    await _openLearning(tester, repository, ThemeMode.dark);
    await tester.tap(find.text('الكورسات'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('كورس قواعد البيانات'));
    await tester.pumpAndSettle();

    final last = find.text('درس الكورس 24');
    expect(last, findsNothing);
    await tester.scrollUntilVisible(last, 260);
    await tester.pumpAndSettle();
    final scrollable = find.byType(Scrollable);
    final offset = tester.state<ScrollableState>(scrollable).position.pixels;

    await tester.tap(last);
    await tester.pumpAndSettle();
    expect(repository.lessonRequests, ['course-lesson-24']);
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(last.hitTestable(), findsOneWidget);
    expect(tester.state<ScrollableState>(scrollable).position.pixels, offset);
  });

  testWidgets('course content opens previews and keeps locked lessons closed', (
    tester,
  ) async {
    final repository = _StudentRepository()..showCourse = true;
    await _openLearning(tester, repository, ThemeMode.dark);
    await tester.tap(find.text('الكورسات'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('كورس قواعد البيانات'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('درس مقفل'), 180);
    await tester.pumpAndSettle();
    await tester.tap(find.text('درس مقفل'));
    await tester.pumpAndSettle();
    expect(find.text('محتوى الكورس'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('درس المعاينة'), -180);
    await tester.pumpAndSettle();
    await tester.tap(find.text('درس المعاينة'));
    await tester.pumpAndSettle();
    expect(find.text('تفاصيل العلاقات بين الجداول'), findsOneWidget);
    expect(find.text('12:40 / 27:00'), findsOneWidget);
    repository.lessonDuration = 60;
    repository.lessonPosition = 120;
    await tester.tap(find.text('الدرس التالي'));
    await tester.pumpAndSettle();
    expect(repository.lessonRequests, ['preview', 'course-next']);
    expect(find.text('1:00 / 1:00'), findsOneWidget);
    expect(find.text('الدرس التالي'), findsNothing);
  });

  testWidgets(
    'profile opens published grades without turning pending marks into zero',
    (tester) async {
      final repository = _StudentRepository();
      repository.profileResult.complete(
        const Right((
          name: 'طالب اختبار',
          email: 'student@example.test',
          phone: null,
          department: 'برمجيات',
          year: 2,
        )),
      );
      await _openLearning(tester, repository, ThemeMode.dark);
      await tester.tap(find.text('الإعدادات'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ملفي الشخصي'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('كشف العلامات'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('كشف العلامات'));
      await tester.pumpAndSettle();
      expect(find.text('78.5'), findsOneWidget);
      expect(find.text('85'), findsOneWidget);
      expect(find.text('قيد الإعلان'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
      await tester.tap(find.text('قواعد البيانات'));
      await tester.pumpAndSettle();
      expect(find.text('85/100'), findsOneWidget);
      expect(find.text('ناجح · حد النجاح 60'), findsOneWidget);
      expect(find.text('الفصل الثالث · الدورة العادية'), findsOneWidget);
    },
  );

  testWidgets('the student settings exposes the legal route callback', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var opened = false;
    await _openLearning(
      tester,
      _StudentRepository(),
      ThemeMode.dark,
      onOpenLegal: () => opened = true,
    );
    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();
    final link = find.text('الشروط وسياسة الخصوصية');
    await tester.ensureVisible(link);
    await tester.tap(link);
    expect(opened, isTrue);
  });

  testWidgets('profile saves to the cache and reopens without a GET', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _StudentRepository();
    repository.profileResult.complete(
      const Right((
        name: 'طالب اختبار',
        email: 'student@example.test',
        phone: null,
        department: 'برمجيات',
        year: 2,
      )),
    );
    await _openLearning(tester, repository, ThemeMode.dark);
    repository.homeResult.complete(
      const Right((
        name: 'طالب اختبار',
        resumeLesson: null,
        courses: [(id: 'course', name: 'كورس محفوظ')],
        subjects: [],
      )),
    );
    await tester.pumpAndSettle();
    expect(find.text('مرحباً طالب اختبار'), findsOneWidget);
    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ملفي الشخصي'));
    await tester.pumpAndSettle();

    Future<void> openEditor() async {
      final edit = find.text('تعديل البيانات');
      await tester.ensureVisible(edit);
      await tester.tap(edit);
      await tester.pumpAndSettle();
    }

    Future<void> save() async {
      final button = find.text('حفظ التعديلات');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    await openEditor();
    await save();
    expect(repository.savedNames, isEmpty);
    expect(repository.profileRequests, 1);

    await openEditor();
    await tester.enterText(find.byType(EditableText).first, 'اسم جديد');
    await save();
    expect(repository.savedNames, ['اسم جديد']);
    expect(repository.profileRequests, 1);
    expect(find.text('اسم جديد'), findsNWidgets(2));
    expect(find.text('+963955000002'), findsOneWidget);

    repository.homeResult =
        Completer<Either<StudentSessionFailure, StudentHomeData>>();
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    await tester.tap(find.text('الرئيسية'));
    await tester.pump();
    expect(repository.homeRequests, 2);
    expect(find.text('مرحباً اسم جديد'), findsOneWidget);
    expect(find.text('كورس محفوظ'), findsOneWidget);

    repository.homeResult.complete(
      const Left(StudentSessionFailure.unavailable),
    );
    await tester.pumpAndSettle();
    expect(find.text('مرحباً اسم جديد'), findsOneWidget);
    expect(find.text('كورس محفوظ'), findsOneWidget);
  });

  for (final (failure, next) in [
    (StudentSessionFailure.accountSuspended, StudentNextStep.suspended),
    (
      StudentSessionFailure.deviceUnauthorized,
      StudentNextStep.deviceUnauthorized,
    ),
  ]) {
    testWidgets('profile save removes the learning shell on $failure', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repository = _StudentRepository()..profileSaveFailure = failure;
      repository.profileResult.complete(
        const Right((
          name: 'طالب اختبار',
          email: 'student@example.test',
          phone: null,
          department: null,
          year: null,
        )),
      );
      final cubit = await _openLearning(tester, repository, ThemeMode.dark);
      await tester.tap(find.text('الإعدادات'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ملفي الشخصي'));
      await tester.pumpAndSettle();
      final edit = find.text('تعديل البيانات');
      await tester.ensureVisible(edit);
      await tester.tap(edit);
      await tester.pumpAndSettle();

      final checking = cubit.revalidateSession();
      await tester.enterText(find.byType(EditableText).first, 'اسم جديد');
      final save = find.text('حفظ التعديلات');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.byType(HasobjyEditProfileScreen), findsNothing);
      expect((cubit.state as GoogleIdentityReady).session?.next, next);

      repository.sessionCheck.complete(
        const Right(
          StudentSession(
            next: StudentNextStep.home,
            usageType: StudentUsageType.institute,
          ),
        ),
      );
      await checking;
      await tester.pumpAndSettle();
      expect((cubit.state as GoogleIdentityReady).session?.next, next);
      expect(find.text('الإعدادات'), findsNothing);
    });
  }

  testWidgets('profile refresh preserves edits and updates untouched fields', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    Future<void> render(String name, String phone) => tester.pumpWidget(
      arabicTestApp(
        HasobjyEditProfileScreen(
          actions: PreviewActions(open: (_) {}, notice: () {}, back: () {}),
          profile: (
            name: name,
            email: 'student@example.test',
            phone: phone,
            department: null,
            year: null,
          ),
        ),
      ),
    );
    await render('اسم سابق', '+963944000001');
    final fields = find.byType(EditableText);
    await tester.enterText(fields.first, 'مسودة الطالب');
    await render('اسم من الخادم', '+963955000002');

    expect(
      tester.widget<EditableText>(fields.first).controller.text,
      'مسودة الطالب',
    );
    expect(
      tester.widget<EditableText>(fields.at(1)).controller.text,
      '+963955000002',
    );
  });

  testWidgets('profile opens server-reported weekly study time', (
    tester,
  ) async {
    final repository = _StudentRepository();
    repository.profileResult.complete(
      const Right((
        name: 'طالب اختبار',
        email: 'student@example.test',
        phone: null,
        department: 'برمجيات',
        year: 2,
      )),
    );
    await _openLearning(tester, repository, ThemeMode.dark);
    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ملفي الشخصي'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('وقتي في التطبيق'));
    await tester.tap(find.text('وقتي في التطبيق'));
    await tester.pumpAndSettle();
    expect(find.text('1 س 15 د'), findsOneWidget);
    expect(find.text('نشاطك اليومي'), findsOneWidget);
  });

  testWidgets('the inbox builds lazily and restores its scroll', (
    tester,
  ) async {
    final repository = _StudentRepository()..manyNotifications = true;
    await _openLearning(tester, repository, ThemeMode.dark);
    repository.homeResult.complete(
      const Right((
        name: 'طالب اختبار',
        resumeLesson: null,
        subjects: [],
        courses: [],
      )),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('الإشعارات'));
    await tester.pumpAndSettle();

    final notice = find.text('الإشعار 20');
    expect(notice, findsNothing);
    await tester.scrollUntilVisible(notice, 250);
    await tester.pumpAndSettle();
    final scrollable = find.byType(Scrollable);
    final offset = tester.state<ScrollableState>(scrollable).position.pixels;
    await tester.tap(notice);
    await tester.pumpAndSettle();
    expect(repository.readNotifications, ['notice-20']);
    expect(repository.gradesTermId, _notificationTermId);

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(tester.state<ScrollableState>(scrollable).position.pixels, offset);
    expect(notice.hitTestable(), findsOneWidget);
    expect(repository.notificationRequests, 1);
  });

  testWidgets('opens the inbox and marks an item read after confirmation', (
    tester,
  ) async {
    final repository = _StudentRepository()..unreadCount = 3;
    await _openLearning(tester, repository, ThemeMode.dark);
    repository.homeResult.complete(
      const Right((
        name: 'طالب اختبار',
        resumeLesson: null,
        subjects: [],
        courses: [],
      )),
    );
    await tester.pumpAndSettle();
    expect(find.text('3'), findsOneWidget);
    expect(repository.unreadRequests, 1);
    await tester.tap(find.text('الإشعارات'));
    await tester.pumpAndSettle();
    expect(find.text('إعلان المعهد'), findsOneWidget);
    await tester.tap(find.text('إعلان المعهد'));
    await tester.pumpAndSettle();
    expect(repository.readNotifications, ['notice']);
    expect(find.text('78.5'), findsOneWidget);
    expect(repository.gradesTermId, _notificationTermId);
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('إعلان المعهد'), findsOneWidget);
    expect(repository.notificationRequests, 1);
    await tester.tap(find.text('إعلان المعهد'));
    await tester.pumpAndSettle();
    expect(repository.readNotifications, ['notice']);
    await tester.tap(
      find.descendant(
        of: find.byType(HasobjyAppBar),
        matching: find.byType(IconButton),
      ),
    );
    await tester.pumpAndSettle();
    repository.pendingUnreadCount =
        Completer<Either<StudentSessionFailure, int>>();
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(repository.unreadRequests, 2);
    expect(find.text('2'), findsOneWidget);

    repository.pendingUnreadCount!.complete(const Right(5));
    await tester.pumpAndSettle();
    expect(find.text('2'), findsNothing);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('الإشعارات'), findsOneWidget);
  });

  for (final (size, mode) in [
    (const Size(320, 568), ThemeMode.dark),
    (const Size(390, 844), ThemeMode.dark),
    (const Size(390, 844), ThemeMode.light),
  ]) {
    testWidgets('lays out H-01 at $size in $mode and exits via its tab bar', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repository = _StudentRepository()..unreadCount = 120;
      await _openLearning(tester, repository, mode);
      repository.homeResult.complete(
        const Right((
          name: 'طالب اختبار',
          resumeLesson: null,
          subjects: [],
          courses: [],
        )),
      );
      await tester.pumpAndSettle();
      expect(find.text('99+'), findsOneWidget);
      await _capture(tester, size, mode, 'unread-count-home');
      await tester.tap(find.text('الإشعارات'));
      await tester.pumpAndSettle();
      expect(find.text('إعلان المعهد'), findsOneWidget);
      await _capture(tester, size, mode, 'notification-inbox');
      await tester.tap(find.text('الرئيسية'));
      await tester.pumpAndSettle();
      expect(find.text('إعلان المعهد'), findsNothing);
      expect(find.text('الإشعارات'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('an unread notification can be retried after a failed write', (
    tester,
  ) async {
    final repository = _StudentRepository()..failNotificationRead = true;
    await _openLearning(tester, repository, ThemeMode.dark);
    repository.homeResult.complete(
      const Right((
        name: 'طالب اختبار',
        resumeLesson: null,
        subjects: [],
        courses: [],
      )),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('الإشعارات'));
    await tester.pumpAndSettle();
    final card = find.text('إعلان المعهد');
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(find.text('تعذّر تسجيل الاطلاع. أعد المحاولة.'), findsOneWidget);
    expect(repository.gradesTermId, isNull);

    repository.failNotificationRead = false;
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(repository.gradesTermId, _notificationTermId);
    expect(repository.readNotifications, ['notice', 'notice']);
  });

  testWidgets('opens an exam notification in its supplementary session', (
    tester,
  ) async {
    final repository = _StudentRepository()
      ..manySubjects = true
      ..examNotification = true;
    var now = DateTime.utc(2026, 11, 17);
    await _openLearning(
      tester,
      repository,
      ThemeMode.dark,
      cacheClock: () => now,
    );
    repository.homeResult.complete(
      const Right((
        name: 'طالب اختبار',
        resumeLesson: null,
        subjects: [],
        courses: [],
      )),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('الإشعارات'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إعلان المعهد'));
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (widget) => widget is HasobjySurface && widget.selected,
      ),
      findsOneWidget,
    );
    expect(repository.examRequests, StudentExamSession.values);
    await tester.tap(
      find.descendant(
        of: find.byType(HasobjyAppBar),
        matching: find.byType(IconButton),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('إعلان المعهد'), findsOneWidget);

    await tester.tap(find.text('إعلان المعهد'));
    await tester.pumpAndSettle();
    expect(repository.examRequests, StudentExamSession.values);

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    now = now.add(const Duration(seconds: 21));
    await tester.tap(find.text('إعلان المعهد'));
    await tester.pumpAndSettle();
    expect(repository.examRequests.toSet(), StudentExamSession.values.toSet());
    for (final session in StudentExamSession.values) {
      expect(
        repository.examRequests.where((value) => value == session),
        hasLength(2),
      );
    }
  });

  test(
    'notification destinations reject external, unknown and malformed links',
    () {
      for (final invalid in [
        'https://example.test/grades?termId=$_notificationTermId',
        '//example.test/me/device',
        'orders/123',
        'exams/123',
        'exams/$_notificationTermId?session=regular',
        'grades?termId=%FF',
        'grades?termId=$_notificationTermId&termId=$_notificationTermId',
        'me/device#other',
      ]) {
        expect(StudentNotificationDestination.parse(invalid), isNull);
      }
      expect(
        StudentNotificationDestination.parse('me/device'),
        isA<StudentDeviceNotificationDestination>(),
      );
    },
  );

  testWidgets('a failed read keeps retry and never renders an empty state', (
    tester,
  ) async {
    final repository = _StudentRepository();
    await _openLearning(tester, repository, ThemeMode.light);
    repository.homeResult.complete(
      const Left(StudentSessionFailure.unavailable),
    );
    await tester.pumpAndSettle();
    expect(find.text('تعذّر تحميل البيانات.'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
    expect(find.byType(HasobjyLearningEmptyState), findsNothing);
  });
}

Future<GoogleIdentityCubit> _openLearning(
  WidgetTester tester,
  _StudentRepository repository,
  ThemeMode mode, {
  VoidCallback? onOpenLegal,
  DateTime Function()? cacheClock,
}) async {
  final themeMode = ValueNotifier(mode);
  final cubit = GoogleIdentityCubit(
    GoogleIdentityRepositoryImpl(FakeGoogleIdentityGateway()),
    messages: AppLocalizationsAr(),
    sessions: repository,
  );
  addTearDown(themeMode.dispose);
  addTearDown(cubit.close);
  await cubit.signIn();
  await tester.pumpWidget(
    arabicTestApp(
      Theme(
        data: mode == ThemeMode.dark ? ThemeData.dark() : ThemeData.light(),
        child: BlocProvider.value(
          value: cubit,
          child: RepaintBoundary(
            key: const ValueKey('learning-surface'),
            child: HasobjyReferenceViewport(
              child: StudentLearningPage(
                repository: repository,
                themeMode: themeMode,
                onThemeChanged: (mode) async => themeMode.value = mode,
                onOpenLegal: onOpenLegal,
                cacheClock: cacheClock,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  return cubit;
}

Future<void> _capture(
  WidgetTester tester,
  Size size,
  ThemeMode mode,
  String screen,
) async {
  final output = Platform.environment['HASOBJY_EMPTY_STATE_OUTPUT'];
  if (output == null || size.width != 390) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('learning-surface')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory(output).createSync(recursive: true);
      File('$output/$screen-${mode.name}.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

class _StudentRepository implements StudentSessionRepository {
  _StudentRepository({this.withLessons = false});

  final bool withLessons;
  bool manySubjects = false;
  bool manyLessons = false;
  int homeRequests = 0;
  bool examNotification = false;
  final examRequests = <StudentExamSession>[];

  @override
  Future<Either<StudentSessionFailure, List<StudentExam>>> examSchedule(
    GoogleIdentity identity,
    StudentExamSession session,
  ) async {
    examRequests.add(session);
    final scheduled = examNotification
        ? StudentExamSession.supplementary
        : StudentExamSession.regular;
    if (session != scheduled) return const Right([]);
    return Right([
      (
        id: _notificationTermId,
        subjectId: _subject.id,
        practical: true,
        startsAt: DateTime.utc(2027, 1, 14, 8),
        room: null,
      ),
    ]);
  }

  static const _subject = (
    id: 'databases',
    name: 'قواعد البيانات',
    completed: 0,
    total: 0,
    percent: 0,
  );

  var homeResult = Completer<Either<StudentSessionFailure, StudentHomeData>>();

  @override
  Future<Either<StudentSessionFailure, StudentSession>> start(
    GoogleIdentity identity,
  ) async => const Right(
    StudentSession(
      next: StudentNextStep.home,
      usageType: StudentUsageType.institute,
    ),
  );

  final sessionCheck =
      Completer<Either<StudentSessionFailure, StudentSession>>();

  @override
  Future<Either<StudentSessionFailure, StudentSession>> read(
    GoogleIdentity identity,
  ) => sessionCheck.future;

  @override
  Future<Either<StudentSessionFailure, StudentHomeData>> home(
    GoogleIdentity identity,
  ) {
    homeRequests++;
    return homeResult.future;
  }

  @override
  Future<Either<StudentSessionFailure, List<StudentSubjectItem>>> subjects(
    GoogleIdentity identity, {
    required bool previous,
  }) async => Right(
    manySubjects
        ? [
            ...List.filled(19, _subject),
            (
              id: 'last-subject',
              name: 'آخر مادة',
              completed: 0,
              total: 0,
              percent: 0,
            ),
          ]
        : previous
        ? [_subject]
        : [],
  );

  @override
  Future<Either<StudentSessionFailure, StudentSubjectDetails>> subject(
    GoogleIdentity identity,
    String id,
  ) async => const Right((subject: _subject, subscribed: false));

  Completer<Either<StudentSessionFailure, List<StudentLessonSummary>>>?
  pendingLessons;

  @override
  Future<Either<StudentSessionFailure, List<StudentLessonSummary>>>
  subjectLessons(GoogleIdentity identity, String id) async {
    if (pendingLessons case final pending?) return pending.future;
    return Right([
      if (manyLessons)
        for (var number = 1; number <= 12; number++)
          (
            id: 'lesson-$number',
            title: 'الدرس $number',
            locked: false,
            completed: false,
            position: null,
            durationSeconds: null,
          ),
      if (withLessons)
        (
          id: 'lesson',
          title: 'مقدمة في قواعد البيانات',
          locked: false,
          completed: true,
          position: 1,
          durationSeconds: 1080,
        ),
    ]);
  }

  bool manyCourses = false;
  bool showCourse = false;
  bool longCourse = false;
  final coursePages = <(bool, int)>[];

  @override
  Future<Either<StudentSessionFailure, StudentCoursePageData>> courses(
    GoogleIdentity identity, {
    required bool mine,
    required int page,
  }) async {
    coursePages.add((mine, page));
    if (!manyCourses) {
      return Right((courses: showCourse ? [_testCourse] : [], hasMore: false));
    }
    return Right((
      courses: [
        for (
          var number = page == 1 ? 1 : 21;
          number <= (page == 1 ? 20 : 21);
          number++
        )
          (
            id: 'course-$number',
            name: 'كورس $number',
            description: null,
            priceUsd: '29',
            durationDays: 365,
            subscribed: false,
          ),
      ],
      hasMore: page == 1,
    ));
  }

  static const StudentCourseItem _testCourse = (
    id: 'course',
    name: 'كورس قواعد البيانات',
    description: null,
    priceUsd: '29',
    durationDays: 365,
    subscribed: false,
  );

  @override
  Future<Either<StudentSessionFailure, StudentCourseItem>> course(
    GoogleIdentity identity,
    String id,
  ) async => const Right(_testCourse);

  @override
  Future<Either<StudentSessionFailure, List<StudentCourseContent>>>
  courseContent(GoogleIdentity identity, String id) async => Right([
    (
      id: 'preview',
      title: 'درس المعاينة',
      type: StudentCourseContentType.lesson,
      locked: false,
      isFree: true,
    ),
    (
      id: 'course-next',
      title: 'درس آخر متاح',
      type: StudentCourseContentType.lesson,
      locked: false,
      isFree: false,
    ),
    (
      id: 'locked',
      title: 'درس مقفل',
      type: StudentCourseContentType.lesson,
      locked: true,
      isFree: false,
    ),
    if (longCourse)
      for (var number = 1; number <= 24; number++)
        (
          id: 'course-lesson-$number',
          title: 'درس الكورس $number',
          type: StudentCourseContentType.lesson,
          locked: false,
          isFree: false,
        ),
  ]);

  StudentSessionFailure? profileSaveFailure;
  final savedNames = <String?>[];

  @override
  Future<Either<StudentSessionFailure, StudentProfileData?>> updateProfile(
    GoogleIdentity identity, {
    String? officialName,
    String? phone,
  }) async {
    savedNames.add(officialName);
    if (profileSaveFailure case final failure?) return Left(failure);
    return Right((
      name: officialName ?? 'طالب اختبار',
      email: 'student@example.test',
      phone: '+963955000002',
      department: 'برمجيات',
      year: 2,
    ));
  }

  int profileRequests = 0;
  final profileResult =
      Completer<Either<StudentSessionFailure, StudentProfileData>>();

  @override
  Future<Either<StudentSessionFailure, StudentProfileData>> profile(
    GoogleIdentity identity,
  ) {
    profileRequests++;
    return profileResult.future;
  }

  int deviceRequests = 0;
  Completer<Either<StudentSessionFailure, StudentDeviceData>>? pendingDevice;

  @override
  Future<Either<StudentSessionFailure, StudentDeviceData>> device(
    GoogleIdentity identity,
  ) async {
    deviceRequests++;
    if (pendingDevice case final pending?) return pending.future;
    return const Right((
      status: StudentDeviceStatus.authorized,
      name: 'جهاز الاختبار',
      platform: 'android',
      registeredAt: null,
    ));
  }

  StudentFileViewer? viewer;

  @override
  StudentFileViewer fileViewer(GoogleIdentity identity, String id) => viewer!;

  int fileRequests = 0;

  @override
  Future<Either<StudentSessionFailure, List<StudentSubjectFile>>> subjectFiles(
    GoogleIdentity identity,
    String id,
  ) async {
    fileRequests++;
    return Right([
      if (manyResources)
        for (var number = 1; number <= 24; number++)
          (
            id: 'file-$number',
            title: 'الملف $number',
            pages: 12,
            downloadable: false,
          )
      else
        (id: 'file', title: 'ملف المادة', pages: 12, downloadable: false),
    ]);
  }

  @override
  Future<Either<StudentSessionFailure, List<StudentSubjectExercise>>>
  subjectExercises(GoogleIdentity identity, String id) async => Right([
    if (manyResources)
      for (var number = 1; number <= 24; number++)
        (
          id: 'exercise-$number',
          title: 'التمرين $number',
          state: StudentExerciseState.notAttempted,
          bestScore: null,
        )
    else if (showExercise)
      (
        id: 'exercise',
        title: 'تمرين SQL',
        state: StudentExerciseState.notAttempted,
        bestScore: null,
      ),
  ]);

  bool manyResources = false;
  bool showExercise = false;

  @override
  Future<Either<StudentSessionFailure, StudentExercisePrompt>> exercise(
    GoogleIdentity identity,
    String id,
  ) async => const Right(
    StudentCodingPrompt('تمرين SQL', 'اكتب استعلاماً', 'SQL', 'SELECT *'),
  );

  final lessonRequests = <String>[];
  int? lessonDuration = 1620;
  int lessonPosition = 760;

  @override
  Future<Either<StudentSessionFailure, StudentLessonDetail>> lesson(
    GoogleIdentity identity,
    String id,
  ) async {
    lessonRequests.add(id);
    return Right((
      title: 'تفاصيل العلاقات بين الجداول',
      description: 'وصف الدرس',
      locked: false,
      videoReady: true,
      durationSeconds: lessonDuration,
      positionSeconds: lessonPosition,
      myRating: null,
      nextId: showCourse ? 'unrelated-subject-lesson' : null,
    ));
  }

  @override
  Future<Either<StudentSessionFailure, List<StudentSubscription>>>
  subscriptions(GoogleIdentity identity) async => Right([
    (
      name: 'كورس الاختبار',
      scope: 'course',
      state: StudentSubscriptionState.active,
      startsAt: DateTime.utc(2026, 10),
      expiresAt: DateTime.utc(2026, 11, 17),
      daysLeft: 3,
    ),
  ]);

  static final StudentTicket _testTicket = (
    id: 'ticket',
    subject: 'مشكلة في الدرس',
    status: 'open',
    updatedAt: DateTime.utc(2026, 11, 14),
  );

  int supportReads = 0;
  Completer<Either<StudentSessionFailure, StudentTicketPage>>?
  pendingSupportPage;

  @override
  Future<Either<StudentSessionFailure, StudentTicketPage>> supportTickets(
    GoogleIdentity identity,
    int page,
  ) async {
    supportReads++;
    if (pendingSupportPage case final pending?) return pending.future;
    return Right((tickets: [_testTicket], hasMore: false));
  }

  int threadReads = 0;
  int cancelledThreadReads = 0;
  Completer<Either<StudentSessionFailure, StudentTicketThread>>? pendingThread;

  @override
  Future<Either<StudentSessionFailure, StudentTicketThread>> supportTicket(
    GoogleIdentity identity,
    String id, {
    Future<void>? whenCanceled,
  }) async {
    threadReads++;
    unawaited(whenCanceled?.then((_) => cancelledThreadReads++));
    if (pendingThread case final pending?) return pending.future;
    return Right((
      ticket: _testTicket,
      messages: [
        (
          fromSupport: true,
          body: 'رد فريق الدعم',
          sentAt: _testTicket.updatedAt,
        ),
      ],
    ));
  }

  final replyKeys = <String>[];

  @override
  Future<Either<StudentSessionFailure, StudentTicketReply>>
  replyToSupportTicket(
    GoogleIdentity identity,
    String id,
    String body,
    String idempotencyKey,
  ) async {
    replyKeys.add(idempotencyKey);
    if (replyKeys.length == 1) {
      return const Left(StudentSessionFailure.unavailable);
    }
    return Right((
      ticket: _testTicket,
      message: (fromSupport: false, body: body, sentAt: _testTicket.updatedAt),
    ));
  }

  (String, String)? createdTicket;

  @override
  Future<Either<StudentSessionFailure, StudentTicket>> createSupportTicket(
    GoogleIdentity identity,
    String subject,
    String body,
  ) async {
    createdTicket = (subject, body);
    return Right((
      id: _testTicket.id,
      subject: subject,
      status: _testTicket.status,
      updatedAt: _testTicket.updatedAt,
    ));
  }

  int exerciseSubmissions = 0;
  int exerciseReads = 0;

  @override
  Future<Either<StudentSessionFailure, StudentAttempt?>> latestExerciseAttempt(
    GoogleIdentity identity,
    String exerciseId, {
    Future<void>? whenCanceled,
  }) async => Right(
    exerciseSubmissions == 0
        ? null
        : (
            id: 'attempt',
            status: StudentAttemptStatus.graded,
            score: 85,
            passed: true,
            explanation: 'استعلام صحيح',
            suggestedFix: null,
          ),
  );

  @override
  Future<Either<StudentSessionFailure, StudentAttempt>> submitExercise(
    GoogleIdentity identity,
    String id,
    String key, {
    String? code,
    String? language,
    String? choiceId,
  }) async {
    exerciseSubmissions++;
    expect(code, 'SELECT *');
    expect(language, 'SQL');
    expect(key, isNotEmpty);
    return const Right((
      id: 'attempt',
      status: StudentAttemptStatus.grading,
      score: null,
      passed: null,
      explanation: null,
      suggestedFix: null,
    ));
  }

  @override
  Future<Either<StudentSessionFailure, StudentAttempt>> exerciseAttempt(
    GoogleIdentity identity,
    String id, {
    Future<void>? whenCanceled,
  }) async {
    exerciseReads++;
    return const Right((
      id: 'attempt',
      status: StudentAttemptStatus.graded,
      score: 85,
      passed: true,
      explanation: 'استعلام صحيح',
      suggestedFix: null,
    ));
  }

  int ratingRequests = 0;
  StudentSessionFailure? ratingDenial;

  @override
  Future<Either<StudentSessionFailure, int>> rateLesson(
    GoogleIdentity identity,
    String id,
    int stars,
  ) async {
    ratingRequests++;
    if (ratingDenial case final failure?) return Left(failure);
    if (ratingRequests == 1) {
      return const Left(StudentSessionFailure.lessonNotWatched);
    }
    return Right(stars);
  }

  String? gradesTermId;

  @override
  Future<Either<StudentSessionFailure, StudentGrades>> grades(
    GoogleIdentity identity, {
    String? termId,
  }) async {
    gradesTermId = termId;
    return const Right((
      average: 78.5,
      terms: [
        (
          name: 'الفصل الثالث',
          subjects: [
            (
              id: 'databases',
              name: 'قواعد البيانات',
              theory: 50,
              practical: 35,
              total: 85,
              result: 'passed',
            ),
            (
              id: 'web',
              name: 'تطوير الويب',
              theory: null,
              practical: null,
              total: null,
              result: null,
            ),
          ],
        ),
      ],
    ));
  }

  @override
  Future<Either<StudentSessionFailure, StudentGradeDetail>> subjectGrades(
    GoogleIdentity identity,
    String id,
  ) async => const Right((
    passMark: 60,
    attempts: [
      (
        term: 'الفصل الثالث',
        session: 'regular',
        theory: 50,
        practical: 35,
        total: 85,
        result: 'passed',
      ),
    ],
  ));

  @override
  Future<Either<StudentSessionFailure, StudentStudyTime>> studyTime(
    GoogleIdentity identity,
  ) async => Right((
    totalSeconds: 4500,
    days: [
      for (var index = 0; index < 7; index++)
        (
          date: DateTime.utc(2026, 11, 9 + index),
          seconds: index == 0 ? 4500 : 0,
        ),
    ],
  ));

  final readNotifications = <String>[];
  int notificationRequests = 0;
  bool manyNotifications = false;
  int unreadCount = 0;
  int unreadRequests = 0;
  Completer<Either<StudentSessionFailure, int>>? pendingUnreadCount;

  @override
  Future<Either<StudentSessionFailure, int>> unreadNotificationCount(
    GoogleIdentity identity,
  ) async {
    unreadRequests++;
    if (pendingUnreadCount case final pending?) return pending.future;
    return Right(unreadCount);
  }

  bool failNotificationRead = false;

  @override
  Future<Either<StudentSessionFailure, StudentNotificationPage>> notifications(
    GoogleIdentity identity,
    String? cursor,
  ) async {
    notificationRequests++;
    return Right((
      items: [
        if (manyNotifications)
          for (var number = 1; number <= 20; number++)
            (
              id: 'notice-$number',
              title: 'الإشعار $number',
              body: 'تفاصيل الإعلان',
              createdAt: DateTime.utc(2026, 11, 14),
              read: false,
              destination: const StudentGradesNotificationDestination(
                _notificationTermId,
              ),
            )
        else
          (
            id: 'notice',
            title: 'إعلان المعهد',
            body: 'تفاصيل الإعلان',
            createdAt: DateTime.utc(2026, 11, 14),
            read: false,
            destination: examNotification
                ? StudentNotificationDestination.parse(
                    'exams/$_notificationTermId',
                  )
                : const StudentGradesNotificationDestination(
                    _notificationTermId,
                  ),
          ),
      ],
      nextCursor: null,
    ));
  }

  @override
  Future<Either<StudentSessionFailure, void>> markNotificationRead(
    GoogleIdentity identity,
    String id,
  ) async {
    readNotifications.add(id);
    if (failNotificationRead) {
      return const Left(StudentSessionFailure.unavailable);
    }
    if (unreadCount > 0) unreadCount--;
    return const Right(null);
  }

  @override
  Never noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FileViewer implements StudentFileViewer {
  bool closed = false;
  Future<void>? firstPageGate;
  Future<Either<StudentFileViewFailure, StudentFilePage>> Function()? nextPage;

  @override
  Future<Either<StudentFileViewFailure, StudentFilePage>> page(
    int number,
  ) async {
    if (number != 1) {
      if (nextPage case final load?) return load();
      return const Left(StudentFileViewFailure.deviceUnauthorized);
    }
    if (firstPageGate case final gate?) await gate;
    return Right((
      bytes: base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGNQ8Cn4DwADSAHcl734WwAAAABJRU5ErkJggg==',
      ),
      totalPages: 2,
    ));
  }

  @override
  void close() => closed = true;
}
