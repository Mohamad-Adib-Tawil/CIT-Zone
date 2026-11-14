import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cit_zone/core/errors/either.dart';
import 'package:cit_zone/core/localization/generated/app_localizations_ar.dart';
import 'package:cit_zone/features/auth/data/google_identity_repository_impl.dart';
import 'package:cit_zone/features/auth/domain/google_identity.dart';
import 'package:cit_zone/features/auth/domain/student_learning.dart';
import 'package:cit_zone/features/auth/domain/student_session_repository.dart';
import 'package:cit_zone/features/auth/presentation/cubit/google_identity_cubit.dart';
import 'package:cit_zone/features/onboarding/presentation/pages/student_learning_page.dart';
import 'package:cit_zone/features/onboarding/presentation/widgets/hasobjy_learning_empty_state.dart';
import 'package:cit_zone/features/onboarding/presentation/widgets/hasobjy_figma_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_google_identity_gateway.dart';
import '../support/hasobjy_test_app.dart';

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
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(HasobjyLearningEmptyState), findsNothing);

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
      expect(find.byType(CircularProgressIndicator), findsNothing);
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
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(repository.profileRequests, 1);
        await _capture(tester, size, mode, 'settings');

        await tester.tap(find.text('ملفي الشخصي'));
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
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

  testWidgets('shows real resume data even without current materials', (
    tester,
  ) async {
    final repository = _StudentRepository();
    await _openLearning(tester, repository, ThemeMode.dark);
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
    await tester.tap(
      find.descendant(
        of: find.byType(HasobjyAppBar),
        matching: find.byType(IconButton),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('متابعة المشاهدة'), findsOneWidget);
    expect(repository.homeRequests, 1);
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
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.text('الملفات'));
    await tester.pumpAndSettle();
    expect(find.text('ملف المادة'), findsOneWidget);
    repository.pendingLessons!.complete(const Right([]));
  });

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

Future<void> _openLearning(
  WidgetTester tester,
  _StudentRepository repository,
  ThemeMode mode,
) async {
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
              ),
            ),
          ),
        ),
      ),
    ),
  );
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
  int homeRequests = 0;
  static const _subject = (
    id: 'databases',
    name: 'قواعد البيانات',
    completed: 0,
    total: 0,
    percent: 0,
  );

  final homeResult =
      Completer<Either<StudentSessionFailure, StudentHomeData>>();

  @override
  Future<Either<StudentSessionFailure, StudentSession>> start(
    GoogleIdentity identity,
  ) async => const Right(
    StudentSession(
      next: StudentNextStep.home,
      usageType: StudentUsageType.institute,
    ),
  );

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
  }) async => Right(previous ? [_subject] : []);

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

  @override
  Future<Either<StudentSessionFailure, StudentCoursePageData>> courses(
    GoogleIdentity identity, {
    required bool mine,
    required int page,
  }) async => const Right((courses: [], hasMore: false));

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

  @override
  Future<Either<StudentSessionFailure, StudentDeviceData>> device(
    GoogleIdentity identity,
  ) async => const Right((
    status: StudentDeviceStatus.authorized,
    name: 'جهاز الاختبار',
    platform: 'android',
    registeredAt: null,
  ));

  int fileRequests = 0;

  @override
  Future<Either<StudentSessionFailure, List<StudentSubjectFile>>> subjectFiles(
    GoogleIdentity identity,
    String id,
  ) async {
    fileRequests++;
    return const Right([
      (id: 'file', title: 'ملف المادة', pages: 12, downloadable: false),
    ]);
  }

  @override
  Future<Either<StudentSessionFailure, List<StudentSubjectExercise>>>
  subjectExercises(GoogleIdentity identity, String id) async => Right([
    if (showExercise)
      (
        id: 'exercise',
        title: 'تمرين SQL',
        state: StudentExerciseState.notAttempted,
        bestScore: null,
      ),
  ]);

  bool showExercise = false;

  @override
  Future<Either<StudentSessionFailure, StudentExercisePrompt>> exercise(
    GoogleIdentity identity,
    String id,
  ) async => const Right(
    StudentCodingPrompt('تمرين SQL', 'اكتب استعلاماً', 'SQL', 'SELECT *'),
  );

  @override
  Future<Either<StudentSessionFailure, StudentLessonDetail>> lesson(
    GoogleIdentity identity,
    String id,
  ) async => const Right((
    title: 'تفاصيل العلاقات بين الجداول',
    description: 'وصف الدرس',
    locked: false,
    videoReady: true,
    nextId: null,
  ));

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

  @override
  Future<Either<StudentSessionFailure, StudentTicketPage>> supportTickets(
    GoogleIdentity identity,
    int page,
  ) async => Right((tickets: [_testTicket], hasMore: false));

  @override
  Future<Either<StudentSessionFailure, StudentTicketThread>> supportTicket(
    GoogleIdentity identity,
    String id,
  ) async => Right((
    ticket: _testTicket,
    messages: [
      (fromSupport: true, body: 'رد فريق الدعم', sentAt: _testTicket.updatedAt),
    ],
  ));

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

  @override
  Future<Either<StudentSessionFailure, StudentAttempt?>> latestExerciseAttempt(
    GoogleIdentity identity,
    String exerciseId,
  ) async => Right(
    exerciseSubmissions == 0
        ? null
        : (
            id: 'attempt',
            status: StudentAttemptStatus.grading,
            score: null,
            passed: null,
            explanation: null,
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
    String id,
  ) async => const Right((
    id: 'attempt',
    status: StudentAttemptStatus.graded,
    score: 85,
    passed: true,
    explanation: 'استعلام صحيح',
    suggestedFix: null,
  ));

  @override
  Never noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
