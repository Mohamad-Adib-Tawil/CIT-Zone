import 'package:cit_zone/core/localization/generated/app_localizations.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/errors/either.dart';
import '../../../auth/domain/google_identity.dart';
import '../../../auth/domain/student_learning.dart';
import '../../../auth/domain/student_profile_snapshot.dart';
import '../../../auth/domain/student_home_snapshot.dart';
import '../../../auth/domain/student_subjects_snapshot.dart';
import '../../../auth/domain/student_courses_snapshot.dart';
import '../../../auth/domain/student_session_repository.dart';
import '../../../auth/presentation/cubit/google_identity_cubit.dart';
import '../cubit/student_learning_data_cubit.dart';
import '../theme/hasobjy_visual_scope.dart';
import '../widgets/hasobjy_figma_components.dart';
import '../widgets/hasobjy_learning_empty_state.dart';
import '../widgets/student_content_skeleton.dart';
import 'preview/preview_widgets.dart';
import 'student_subject_progress.dart';
import '../../../lesson_ratings/presentation/widgets/student_lesson_rating.dart';
import 'student_resume_card.dart';
import 'student_lesson_video_status.dart';
import 'student_file_view_page.dart';
import 'student_subscriptions.dart';
import 'student_support.dart';
import 'student_grades.dart';
import 'student_study_time.dart';
import 'student_notifications.dart';
import 'student_exam_schedule.dart';
import 'student_new_ticket.dart';
import 'student_exercise_prompt.dart';
import 'preview/student_update_scaffold.dart';
import 'student_registered_device.dart';
import 'preview/profile_preview_screens.dart';
import 'preview/payment_preview_screens.dart';

enum _LearningTab { home, subjects, courses, settings }

class StudentLearningPage extends StatelessWidget {
  const StudentLearningPage({
    super.key,
    required this.repository,
    required this.themeMode,
    required this.onThemeChanged,
    this.onOpenLegal,
    this.cacheClock,
  });

  final StudentSessionRepository repository;
  final ValueListenable<ThemeMode> themeMode;
  final Future<void> Function(ThemeMode) onThemeChanged;
  final VoidCallback? onOpenLegal;
  final DateTime Function()? cacheClock;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<GoogleIdentityCubit, GoogleIdentityState>(
        builder: (context, state) {
          final (identity, session) = switch (state) {
            GoogleIdentityReady(:final identity, :final session) => (
              identity,
              session,
            ),
            GoogleIdentityWorking(:final identity, :final session) => (
              identity,
              session,
            ),
            _ => (null, null),
          };
          if (identity != null && session?.next == StudentNextStep.home) {
            final coursesOnly = session?.usageType == StudentUsageType.courses;
            return _LearningShell(
              key: ValueKey((identity.firebaseUid, coursesOnly)),
              identity: identity,
              repository: repository,
              themeMode: themeMode,
              onThemeChanged: onThemeChanged,
              onOpenLegal: onOpenLegal,
              cacheClock: cacheClock,
              coursesOnly: coursesOnly,
            );
          }
          return const SizedBox.shrink();
        },
      );
}

class _LearningShell extends StatefulWidget {
  const _LearningShell({
    super.key,
    required this.identity,
    required this.repository,
    required this.coursesOnly,
    this.onOpenLegal,
    this.cacheClock,
    required this.themeMode,
    required this.onThemeChanged,
  });

  final GoogleIdentity identity;
  final StudentSessionRepository repository;
  final bool coursesOnly;
  final VoidCallback? onOpenLegal;
  final DateTime Function()? cacheClock;
  final ValueListenable<ThemeMode> themeMode;
  final Future<void> Function(ThemeMode) onThemeChanged;

  @override
  State<_LearningShell> createState() => _LearningShellState();
}

class _LearningShellState extends State<_LearningShell> {
  static const _unreadNotificationsKey = 'notifications-unread';
  late final _cache = StudentLearningCache(
    now: widget.cacheClock,
    onSessionRestricted: _restrictLearningSession,
  );
  _LearningTab _tab = _LearningTab.home;
  String? _detail;
  String? _lessonId;
  List<StudentCourseContent>? _lessonCourseContent;
  StudentSubjectExercise? _exercise;
  StudentGrade? _selectedGrade;
  StudentSubjectFile? _file;
  StudentExamSession? _examSession;

  Future<Either<StudentSessionFailure, ({StudentExamSession? session})>>
  _resolveExam(String id) async {
    for (final session in StudentExamSession.values) {
      final key = ('exam-schedule', session);
      if (!_cache.isFresh(key)) continue;
      final rows = _cache.read<List<StudentExamRow>>(key);
      if (rows != null && rows.any((row) => row.exam.id == id)) {
        return Right((session: session));
      }
    }

    for (final session in StudentExamSession.values) {
      final key = ('exam-schedule', session);
      final result = await _cache.refresh(key, () => _loadExams(session));
      switch (result) {
        case Left(:final value):
          return Left(value);
        case Right(:final value) when value.any((row) => row.exam.id == id):
          return Right((session: session));
        case Right():
          break;
      }
    }
    return const Right((session: null));
  }

  Future<Either<StudentSessionFailure, List<StudentExamRow>>> _loadExams(
    StudentExamSession session,
  ) async {
    final repository = widget.repository;
    final identity = widget.identity;
    final exams = await repository.examSchedule(identity, session);
    return switch (exams) {
      Left(:final value) => Left(value),
      Right(value: final items) when items.isEmpty => const Right([]),
      Right(value: final items) => await _nameExams(
        items,
        repository,
        identity,
      ),
    };
  }

  Future<Either<StudentSessionFailure, List<StudentExamRow>>> _nameExams(
    List<StudentExam> exams,
    StudentSessionRepository repository,
    GoogleIdentity identity,
  ) async {
    const key = ('subjects', false);
    final cached = _cache.read<List<StudentSubjectItem>>(key);
    final subjects = cached != null && _cache.isFresh(key)
        ? Right<StudentSessionFailure, List<StudentSubjectItem>>(cached)
        : await _cache.refresh(
            key,
            () => repository.subjects(identity, previous: false),
          );
    return subjects.map((items) {
      final names = {for (final item in items) item.id: item.name};
      return [
        for (final exam in exams)
          (exam: exam, subjectName: names[exam.subjectId]),
      ];
    });
  }

  ({String fileId, Completer<void> ended})? _fileDownload;
  final _listPositions = PageStorageBucket();
  int _subjectTab = 2;
  bool _previous = false;
  bool _mine = false;
  int _page = 1;
  bool _showNotifications = false;
  bool _detailOpenedFromHome = false;
  String? _notificationCursor;
  StudentNotificationDestination? _notificationDestination;

  int _supportPage = 1;
  StudentTicket? _ticket;
  Completer<void>? _ticketReadEnded;
  bool _creatingTicket = false;

  void _selectTicket(StudentTicket? ticket) {
    _ticketReadEnded?.complete();
    _ticket = ticket;
    _ticketReadEnded = ticket == null ? null : Completer<void>();
  }

  bool _sessionRestricted = false;

  void _restrictLearningSession(StudentSessionFailure failure) {
    if (!mounted || _sessionRestricted) return;
    _sessionRestricted = true;
    _cancelFileDownload();
    _selectTicket(null);
    _cache.clear();
    context.read<GoogleIdentityCubit>().restrictLearningSession(failure);
  }

  Either<StudentSessionFailure, T> _handleActionResult<T>(
    Either<StudentSessionFailure, T> result,
  ) {
    if (!mounted || _sessionRestricted) {
      return const Left(StudentSessionFailure.unavailable);
    }
    if (result case Left(value: final failure)
        when failure == StudentSessionFailure.accountSuspended ||
            failure == StudentSessionFailure.deviceUnauthorized) {
      _restrictLearningSession(failure);
    }
    return result;
  }

  void _switchTab(_LearningTab tab) => setState(() {
    _cancelFileDownload();
    _selectTicket(null);
    _tab = tab;
    _detail = null;
    _showNotifications = false;
    _notificationDestination = null;
    _detailOpenedFromHome = false;
  });

  void _openDetail(_LearningTab tab, String id) => setState(() {
    _cancelFileDownload();
    _detailOpenedFromHome =
        _tab == _LearningTab.home &&
        !_showNotifications &&
        (tab == _LearningTab.subjects || tab == _LearningTab.courses);
    _tab = tab;
    _detail = id;
    _subjectTab = 2;
  });

  @override
  void dispose() {
    _cancelFileDownload();
    _selectTicket(null);
    _cache.clear();
    super.dispose();
  }

  Future<Either<StudentSessionFailure, void>> _saveProfile(
    String? name,
    String? phone,
  ) async {
    final result = _handleActionResult(
      await widget.repository.updateProfile(
        widget.identity,
        officialName: name,
        phone: phone,
      ),
    );
    if (result case Right(value: final profile?)) {
      _cache.replace('profile', profile);
      _cache.refreshOnNextRead<StudentHomeData>(
        'home',
        update: (home) => (
          name: profile.name,
          resumeLesson: home.resumeLesson,
          subjects: home.subjects,
          courses: home.courses,
        ),
      );
    }
    return result.map((_) {});
  }

  String? _nextLesson(String id, StudentLessonDetail detail) {
    final content = _lessonCourseContent;
    if (content == null) return detail.nextId;
    final index = content.indexWhere(
      (item) => item.type == StudentCourseContentType.lesson && item.id == id,
    );
    if (index < 0) return null;
    for (var next = index + 1; next < content.length; next++) {
      final item = content[next];
      if (item.type == StudentCourseContentType.lesson) {
        return item.locked ? null : item.id;
      }
    }
    return null;
  }

  Widget _lessonPage(String id, bool light) => HasobjyVisualScope(
    frameName: light ? 'C-04-LIGHT' : 'C-04',
    child: HasobjyFigmaFrame(
      appBarTitle: 'الدرس',
      onBack: _back,
      backgroundLayer: _LearningBackground(frame: 'C-04', light: light),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _LiveData<StudentLessonDetail>(
          loadingLayout: StudentLoadingLayout.media,
          key: ValueKey(id),
          cache: _cache,
          cacheKey: ('lesson', id),
          load: () => widget.repository.lesson(widget.identity, id),
          builder: (context, data) => _list([
            StudentLessonVideoStatus(lesson: data),
            PreviewText(data.title, style: context.design.headingMedium),
            if (data.description case final description?
                when description.isNotEmpty)
              PreviewText(description),
            if (!data.locked)
              StudentLessonRating(
                key: ValueKey(id),
                title: data.title,
                initial: data.myRating,
                onRate: (stars) async {
                  final result = _handleActionResult(
                    await widget.repository.rateLesson(
                      widget.identity,
                      id,
                      stars,
                    ),
                  );
                  if (result.isRight()) _cache.invalidate(('lesson', id));
                  return result;
                },
              ),
            if (_nextLesson(id, data) case final next?)
              PreviewButton(
                'الدرس التالي',
                onTap: () => setState(() => _lessonId = next),
              ),
          ]),
        ),
      ),
    ),
  );

  Widget _support(bool light) {
    if (_creatingTicket) {
      return HasobjyVisualScope(
        frameName: light ? 'H-03-LIGHT' : 'H-03',
        child: StudentNewTicket(
          onBack: () => setState(() => _creatingTicket = false),
          onCreate: (subject, body) async => _handleActionResult(
            await widget.repository.createSupportTicket(
              widget.identity,
              subject,
              body,
            ),
          ),
          onCreated: (ticket) => setState(() {
            _creatingTicket = false;
            _supportPage = 1;
            _cache.refreshOnNextRead(('support', 1));
            _selectTicket(ticket);
          }),
        ),
      );
    }
    final ticket = _ticket;
    final readEnded = _ticketReadEnded?.future;
    final page = _supportPage;
    final frame = ticket == null ? 'H-02' : 'H-04';
    final actions = PreviewActions(open: (_) {}, notice: () {}, back: _back!);
    final threadCache = StudentLearningCache(
      onSessionRestricted: _restrictLearningSession,
    );
    return HasobjyVisualScope(
      frameName: light ? '$frame-LIGHT' : frame,
      child: ticket == null
          ? _supportList(page, light, actions)
          : PreviewScaffold(
              title: ticket.subject,
              actions: actions,
              children: [
                _LiveData<StudentTicketThread>(
                  loadingLayout: StudentLoadingLayout.details,
                  cache: threadCache,
                  cacheKey: ticket.id,
                  load: () => widget.repository.supportTicket(
                    widget.identity,
                    ticket.id,
                    whenCanceled: readEnded,
                  ),
                  builder: (_, data) => StudentSupportThread(
                    data: data,
                    onReply: (body, key) async {
                      final result = _handleActionResult(
                        await widget.repository.replyToSupportTicket(
                          widget.identity,
                          ticket.id,
                          body,
                          key,
                        ),
                      );
                      if (result.isRight()) {
                        _cache.refreshOnNextRead(('support', page));
                      }
                      return result;
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _supportList(int page, bool light, PreviewActions actions) {
    final key = ('support', page);
    Widget scaffold(Widget content, {Key? scrollKey}) => PreviewScaffold(
      title: 'الدعم والتواصل',
      scrollKey: scrollKey,
      actions: actions,
      children: [
        PreviewButton(
          'تذكرة جديدة',
          onTap: () => setState(() => _creatingTicket = true),
          light3D: true,
          iconAsset: light ? 'cf7cc' : null,
        ),
        content,
      ],
    );

    return _LiveData<StudentTicketPage>(
      key: ValueKey(page),
      loadingLayout: page == 1
          ? StudentLoadingLayout.list
          : StudentLoadingLayout.nextPage,
      cache: _cache,
      cacheKey: key,
      load: () => widget.repository.supportTickets(widget.identity, page),
      fallback: (_, placeholder) => scaffold(placeholder),
      builder: (_, data) => scaffold(
        StudentSupportList(
          data: data,
          onOpen: (ticket) => setState(() => _selectTicket(ticket)),
          onPrevious: page > 1 ? () => setState(() => _supportPage--) : null,
          onNext: data.hasMore ? () => setState(() => _supportPage++) : null,
        ),
        scrollKey: PageStorageKey(key),
      ),
    );
  }

  VoidCallback? get _back {
    if (_showNotifications) return () => _switchTab(_LearningTab.home);
    if (_exercise != null) return () => setState(() => _exercise = null);
    if (_file != null) return () => setState(() => _file = null);
    if (_lessonId != null) {
      return () => setState(() {
        _lessonId = null;
        _lessonCourseContent = null;
      });
    }
    if (_selectedGrade != null && _detail == 'grades') {
      return () => setState(() => _selectedGrade = null);
    }
    if (_notificationDestination != null) return _returnToNotifications;
    if (_tab == _LearningTab.settings) {
      return switch (_detail) {
        null => null,
        'edit-profile' ||
        'study-time' ||
        'grades' => () => _openDetail(_LearningTab.settings, 'profile'),
        'support' when _creatingTicket => null,
        'support' when _ticket != null => () => setState(
          () => _selectTicket(null),
        ),
        _ => () => _switchTab(_LearningTab.settings),
      };
    }
    if (_detail == null) return null;
    if (_detailOpenedFromHome) return () => _switchTab(_LearningTab.home);
    return () => setState(() {
      _detail = null;
      _cancelFileDownload();
    });
  }

  @override
  Widget build(BuildContext context) {
    final back = _back;
    return PopScope<Object?>(
      canPop: back == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) back?.call();
      },
      child: PageStorage(bucket: _listPositions, child: _buildContent(context)),
    );
  }

  void _openNotificationDestination(
    StudentNotificationDestination destination,
  ) {
    setState(() {
      _showNotifications = false;
      _notificationDestination = destination;
      _selectedGrade = null;
      _examSession = null;
      _tab = destination is StudentExamNotificationDestination
          ? _LearningTab.subjects
          : _LearningTab.settings;
      _detail = switch (destination) {
        StudentExamNotificationDestination() => 'exam-schedule',
        StudentDeviceNotificationDestination() => 'device',
        StudentGradesNotificationDestination() => 'grades',
      };
    });
  }

  void _returnToNotifications() => setState(() {
    _tab = _LearningTab.home;
    _detail = null;
    _notificationDestination = null;
    _showNotifications = true;
  });

  Widget _notificationsEntry(BuildContext context, int count) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: TextButton(
      onPressed: () => setState(() {
        _notificationCursor = null;
        _showNotifications = true;
      }),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          Text(
            'الإشعارات',
            style: context.design.label.copyWith(color: context.design.brand),
          ),
          if (count > 0)
            Semantics(
              label: 'إشعارات غير مقروءة: $count',
              excludeSemantics: true,
              child: HasobjyBadge(
                label: count > 99 ? '99+' : '$count',
                textDirection: TextDirection.ltr,
              ),
            ),
        ],
      ),
    ),
  );

  void _confirmNotificationRead(String? cursor, String id) {
    final key = ('notifications', cursor);
    final page = _cache.read<StudentNotificationPage>(key);
    final wasUnread =
        page?.items.any((item) => item.id == id && !item.read) ?? false;
    _cache.refreshOnNextRead<int>(
      _unreadNotificationsKey,
      update: (count) => wasUnread && count > 0 ? count - 1 : count,
    );
    if (page == null) {
      _cache.invalidate(key);
      return;
    }
    _cache.replace(key, (
      nextCursor: page.nextCursor,
      items: List<StudentNotification>.unmodifiable(
        page.items.map(
          (item) => item.id == id
              ? (
                  id: item.id,
                  title: item.title,
                  body: item.body,
                  createdAt: item.createdAt,
                  read: true,
                  destination: item.destination,
                )
              : item,
        ),
      ),
    ));
  }

  Widget _notificationsPage(bool light) {
    final cursor = _notificationCursor;
    final key = ('notifications', cursor);
    Widget scaffold(Widget content, {Key? scrollKey}) => HasobjyFigmaFrame(
      scrollKey: scrollKey,
      bottomNavigation: _navigation(),
      backgroundLayer: _LearningBackground(frame: 'H-01', light: light),
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 10),
          sliver: SliverToBoxAdapter(child: _InboxTitle()),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          sliver: content,
        ),
      ],
    );
    return HasobjyVisualScope(
      frameName: light ? 'H-01-LIGHT' : 'H-01',
      child: _LiveData<StudentNotificationPage>(
        loadingLayout: cursor == null
            ? StudentLoadingLayout.list
            : StudentLoadingLayout.nextPage,
        key: ValueKey(cursor),
        cache: _cache,
        cacheKey: key,
        load: () => widget.repository.notifications(widget.identity, cursor),
        fallback: (_, placeholder) =>
            scaffold(SliverToBoxAdapter(child: placeholder)),
        builder: (_, data) => scaffold(
          StudentNotifications(
            data: data,
            onOpen: _openNotificationDestination,
            canOpen: (_) => !widget.coursesOnly,
            onRead: (id) async {
              final result = _handleActionResult(
                await widget.repository.markNotificationRead(
                  widget.identity,
                  id,
                ),
              );
              if (result.isRight()) _confirmNotificationRead(cursor, id);
              return result;
            },
            onFirst: cursor == null
                ? null
                : () => setState(() => _notificationCursor = null),
            onNext: data.nextCursor == null
                ? null
                : () => setState(() => _notificationCursor = data.nextCursor),
          ),
          scrollKey: PageStorageKey(key),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final repository = widget.repository;
    final identity = widget.identity;
    final light = Theme.of(context).brightness == Brightness.light;
    if (_showNotifications) return _notificationsPage(light);
    if (_exercise case final exercise?) {
      final subjectId = _detail;
      return HasobjyVisualScope(
        frameName: light ? 'C-07-LIGHT' : 'C-07',
        child: PreviewScaffold(
          title: exercise.title,
          actions: PreviewActions(back: _back!, open: (_) {}, notice: () {}),
          children: [
            _LiveData<StudentExercisePrompt>(
              loadingLayout: StudentLoadingLayout.form,
              cache: _cache,
              cacheKey: ('exercise', exercise.id),
              load: () => repository.exercise(identity, exercise.id),
              builder: (_, prompt) => StudentExercisePromptView(
                prompt: prompt,
                latestAttempt: (whenCanceled) async {
                  final result = _handleActionResult(
                    await repository.latestExerciseAttempt(
                      identity,
                      exercise.id,
                      whenCanceled: whenCanceled,
                    ),
                  );
                  if (result case Right(value: final attempt?)
                      when attempt.status != StudentAttemptStatus.grading) {
                    _cache.invalidate(('subject-exercises', subjectId));
                  }
                  return result;
                },
                onBack: _back!,
                submit: (key, {code, language, choiceId}) async {
                  final result = _handleActionResult(
                    await repository.submitExercise(
                      identity,
                      exercise.id,
                      key,
                      code: code,
                      language: language,
                      choiceId: choiceId,
                    ),
                  );
                  if (result.isRight()) {
                    _cache.invalidate(('subject-exercises', subjectId));
                  }
                  return result;
                },
                readAttempt: (id, whenCanceled) async {
                  final result = _handleActionResult(
                    await repository.exerciseAttempt(
                      identity,
                      id,
                      whenCanceled: whenCanceled,
                    ),
                  );
                  if (result.isRight()) {
                    _cache.invalidate(('subject-exercises', subjectId));
                  }
                  return result;
                },
              ),
            ),
          ],
        ),
      );
    }
    if (_file case final file?) {
      return HasobjyVisualScope(
        frameName: light ? 'C-05-LIGHT' : 'C-05',
        child: StudentFileViewPage(
          file: file,
          open: () => repository.fileViewer(identity, file.id),
          onRestriction: (failure) {
            switch (failure) {
              case StudentFileViewFailure.accountSuspended:
                _restrictLearningSession(
                  StudentSessionFailure.accountSuspended,
                );
              case StudentFileViewFailure.deviceUnauthorized:
                _restrictLearningSession(
                  StudentSessionFailure.deviceUnauthorized,
                );
              case StudentFileViewFailure.network:
              case StudentFileViewFailure.unavailable:
                break;
            }
          },
          actions: PreviewActions(open: (_) {}, notice: () {}, back: _back!),
        ),
      );
    }
    if (_lessonId case final lessonId?) return _lessonPage(lessonId, light);
    final detail = _detail;
    if (_tab == _LearningTab.settings && detail == 'support') {
      return _support(light);
    }
    final previous = _previous;
    final mine = _mine;
    final page = _page;
    final frame = switch (_tab) {
      _LearningTab.home => 'C-01',
      _LearningTab.settings => switch (detail) {
        'edit-profile' => 'S-03',
        'profile' => 'S-02',
        'device' => 'S-04',
        'subscriptions' => 'F-07',
        _ => 'S-01',
      },
      _LearningTab.subjects => detail == null ? 'C-02' : 'C-03',
      _LearningTab.courses => detail == null ? 'F-01' : 'F-02',
    };
    if (_tab == _LearningTab.subjects && detail == 'exam-schedule') {
      return HasobjyVisualScope(
        frameName: light ? 'B-S06-LIGHT' : 'B-S06',
        child: switch (_notificationDestination) {
          StudentExamNotificationDestination(:final id) =>
            _LiveData<({StudentExamSession? session})>(
              loadingLayout: StudentLoadingLayout.schedule,
              key: ValueKey(id),
              cache: _cache,
              cacheKey: ('exam-destination', id),
              load: () => _resolveExam(id),
              fallback: (context, child) => HasobjyFigmaFrame(
                appBarTitle: AppLocalizations.of(context).examSchedule,
                onBack: _returnToNotifications,
                child: child,
              ),
              builder: (_, result) => _examPage(
                _examSession ?? result.session ?? StudentExamSession.regular,
                examId: id,
                missing: result.session == null && _examSession == null,
              ),
            ),
          _ => _examPage(_examSession ?? StudentExamSession.regular),
        },
      );
    }
    if (_tab == _LearningTab.settings && detail == 'study-time') {
      return HasobjyVisualScope(
        frameName: light ? 'S-05-LIGHT' : 'S-05',
        child: StudentUpdateScaffold(
          title: 'وقتي في التطبيق',
          actions: _profileActions('study-time'),
          children: [
            _LiveData<StudentStudyTime>(
              loadingLayout: StudentLoadingLayout.details,
              cache: _cache,
              cacheKey: 'study-time',
              load: () => repository.studyTime(identity),
              builder: (_, data) => StudentStudyTimeView(data: data),
            ),
          ],
        ),
      );
    }
    if (_tab == _LearningTab.settings && detail == 'grades') {
      final termId = switch (_notificationDestination) {
        StudentGradesNotificationDestination(:final termId) => termId,
        _ => null,
      };
      final grade = _selectedGrade;
      final gradeFrame = grade == null ? 'G-01' : 'G-02';
      return HasobjyVisualScope(
        frameName: light ? '$gradeFrame-LIGHT' : gradeFrame,
        child: PreviewScaffold(
          title: grade?.name ?? 'كشف العلامات',
          actions: PreviewActions(open: (_) {}, notice: () {}, back: _back!),
          backgroundLayer: _LearningBackground(frame: 'C-03', light: light),
          children: [
            if (grade == null)
              _LiveData<StudentGrades>(
                loadingLayout: StudentLoadingLayout.list,
                cache: _cache,
                cacheKey: ('grades', termId),
                load: () => repository.grades(identity, termId: termId),
                builder: (_, data) => StudentGradesView(
                  grades: data,
                  onOpen: (grade) => setState(() => _selectedGrade = grade),
                ),
              )
            else
              _LiveData<StudentGradeDetail>(
                loadingLayout: StudentLoadingLayout.details,
                key: ValueKey(grade.id),
                cache: _cache,
                cacheKey: ('subject-grade', grade.id),
                load: () => repository.subjectGrades(identity, grade.id),
                builder: (_, data) => StudentGradeDetailView(detail: data),
              ),
          ],
        ),
      );
    }
    if (_tab == _LearningTab.settings && detail == 'subscriptions') {
      void browseCourses() => setState(() {
        _tab = _LearningTab.courses;
        _detail = null;
        _mine = false;
        _page = 1;
      });

      return HasobjyVisualScope(
        frameName: light ? '$frame-LIGHT' : frame,
        child: _LiveData<List<StudentSubscription>>(
          loadingLayout: StudentLoadingLayout.list,
          cache: _cache,
          cacheKey: 'subscriptions',
          load: () => repository.subscriptions(identity),
          fallback: (_, placeholder) => StudentSubscriptions(
            actions: _actions,
            placeholder: placeholder,
            onBrowseCourses: browseCourses,
          ),
          builder: (_, rows) => StudentSubscriptions(
            actions: _actions,
            subscriptions: rows,
            onBrowseCourses: browseCourses,
          ),
        ),
      );
    }
    if (detail == 'device' && _tab == _LearningTab.settings) {
      return HasobjyVisualScope(
        frameName: light ? '$frame-LIGHT' : frame,
        child: PreviewScaffold(
          actions: _notificationDestination == null
              ? _actions
              : PreviewActions(
                  open: (_) {},
                  notice: () {},
                  back: _returnToNotifications,
                ),
          title: 'الجهاز المسجّل',
          children: [
            _LiveData<StudentDeviceData>(
              loadingLayout: StudentLoadingLayout.details,
              cache: _cache,
              cacheKey: 'device',
              load: () => repository.device(identity),
              builder: (context, data) => StudentRegisteredDevice(device: data),
            ),
          ],
        ),
      );
    }
    if (_tab == _LearningTab.settings) {
      return HasobjyVisualScope(
        frameName: light ? '$frame-LIGHT' : frame,
        child: _LiveData<StudentProfileData>(
          loadingLayout: detail == 'edit-profile'
              ? StudentLoadingLayout.form
              : StudentLoadingLayout.profile,
          key: ValueKey(frame),
          cache: _cache,
          cacheKey: 'profile',
          restore: repository is StudentProfileSnapshotSource
              ? () => (repository as StudentProfileSnapshotSource)
                    .profileSnapshot(identity)
              : null,
          load: () => repository.profile(identity),
          fallback: (context, placeholder) => detail == null
              ? _settings(context)
              : PreviewScaffold(
                  title: detail == 'profile' ? 'ملفي الشخصي' : 'تعديل البيانات',
                  actions: _profileActions(detail),
                  children: [placeholder],
                ),
          builder: (context, data) => switch (detail) {
            'edit-profile' => HasobjyEditProfileScreen(
              actions: _profileActions(detail),
              profile: data,
              onSave: _saveProfile,
            ),
            'profile' => HasobjyProfileScreen(
              actions: _actions,
              profile: data,
              onStudyTime: () =>
                  _openDetail(_LearningTab.settings, 'study-time'),
              onGrades: widget.coursesOnly
                  ? null
                  : () => _openDetail(_LearningTab.settings, 'grades'),
            ),
            _ => _settings(context, profile: data),
          },
        ),
      );
    }
    if (_tab == _LearningTab.subjects) {
      return detail == null
          ? _subjectsPage(light, previous)
          : _subjectPage(detail, light);
    }
    if (_tab == _LearningTab.courses) {
      return detail == null
          ? _coursesPage(light, mine, page)
          : _coursePage(detail, light);
    }
    return _homePage(light);
  }

  Widget _homePage(bool light) {
    final repository = widget.repository;
    final identity = widget.identity;
    Widget scaffold(Widget content, {bool restore = false}) =>
        HasobjyFigmaFrame(
          scrollKey: restore ? const PageStorageKey('home') : null,
          bottomNavigation: _navigation(),
          backgroundLayer: _LearningBackground(frame: 'C-01', light: light),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: content,
          ),
        );
    return HasobjyVisualScope(
      frameName: light ? 'C-01-LIGHT' : 'C-01',
      child: _LiveData<StudentHomeData>(
        loadingLayout: StudentLoadingLayout.home,
        key: const ValueKey('home'),
        cache: _cache,
        cacheKey: 'home',
        restore: repository is StudentHomeSnapshotSource
            ? () => (repository as StudentHomeSnapshotSource).homeSnapshot(
                identity,
              )
            : null,
        load: () => repository.home(identity),
        fallback: (_, placeholder) => scaffold(placeholder),
        builder: (context, data) {
          final coursesOnly = widget.coursesOnly;
          final greeting = PreviewText(
            'مرحباً ${data.name}',
            style: context.design.title,
          );
          final notifications = _LiveData<int>(
            loadingLayout: null,
            cache: _cache,
            cacheKey: _unreadNotificationsKey,
            load: () => repository.unreadNotificationCount(identity),
            builder: (context, count) => _notificationsEntry(context, count),
            fallback: (context, _) => _notificationsEntry(context, 0),
          );
          final resumeLesson = data.resumeLesson;
          if (resumeLesson == null &&
              data.courses.isEmpty &&
              (coursesOnly || data.subjects.isEmpty)) {
            return scaffold(
              _list(
                [greeting, notifications],
                fill: HasobjyLearningEmptyState.home(coursesOnly: coursesOnly),
              ),
              restore: true,
            );
          }
          return scaffold(
            _list([
              notifications,
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 2,
                children: [
                  greeting,
                  PreviewText(
                    'تابع تعلّمك من حيث توقفت',
                    style: context.design.bodySmall,
                  ),
                ],
              ),
              if (resumeLesson != null) ...[
                PreviewText('متابعة المشاهدة', style: context.design.label),
                StudentResumeCard(
                  lesson: resumeLesson,
                  onTap: () =>
                      setState(() => _lessonId = resumeLesson.lessonId),
                ),
              ],
              if (!coursesOnly) ...[
                PreviewText('موادي', style: context.design.label),
                ..._subjectCards(data.subjects),
              ],
              PreviewText('كورساتي', style: context.design.label),
              if (data.courses.isEmpty)
                const PreviewText('لا توجد كورسات مشترك بها حالياً.'),
              for (final course in data.courses)
                PreviewListCard(
                  title: course.name,
                  onTap: () => _openDetail(_LearningTab.courses, course.id),
                ),
            ]),
            restore: true,
          );
        },
      ),
    );
  }

  Widget _coursePage(String id, bool light) {
    Widget scaffold(Widget content, {Key? scrollKey}) => HasobjyFigmaFrame(
      scrollKey: scrollKey,
      appBarTitle: 'تفاصيل الكورس',
      onBack: _back,
      backgroundLayer: _LearningBackground(frame: 'F-02', light: light),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: content,
        ),
      ],
    );
    return HasobjyVisualScope(
      frameName: light ? 'F-02-LIGHT' : 'F-02',
      child: _LiveData<StudentCourseItem>(
        loadingLayout: StudentLoadingLayout.media,
        key: ValueKey(id),
        cache: _cache,
        cacheKey: ('course', id),
        load: () => widget.repository.course(widget.identity, id),
        fallback: (_, placeholder) => scaffold(_paddedSliverBox(placeholder)),
        builder: (context, course) {
          List<Widget> header([List<StudentCourseContent>? items]) => [
            Container(
              height: 150,
              color: context.design.surfaceSubtle,
              alignment: Alignment.center,
              child: PreviewIconTile(
                asset: light ? 'b7b86' : 'c0735',
                size: 64,
                fill: context.design.brand,
              ),
            ),
            PreviewText(course.name, style: context.design.headingMedium),
            if (course.description case final description?
                when description.isNotEmpty)
              PreviewText(description),
            PreviewPanel(
              gap: 8,
              children: [
                if (items != null)
                  PreviewKeyValue(
                    'عدد الدروس',
                    '${items.where((item) => item.type == StudentCourseContentType.lesson).length}',
                    body: true,
                  ),
                PreviewKeyValue(
                  'صلاحية الوصول',
                  '${course.durationDays} يوم',
                  body: true,
                ),
                PreviewKeyValue('السعر', '${course.priceUsd} USD', body: true),
                if (items?.any(
                      (item) => item.type == StudentCourseContentType.file,
                    ) ??
                    false)
                  const PreviewKeyValue(
                    'الملفات',
                    'عرض فقط، بدون تحميل',
                    body: true,
                  ),
                if (course.subscribed) const PreviewText('الاشتراك نشط'),
              ],
            ),
            PreviewText('محتوى الكورس', style: context.design.label),
          ];
          Widget fill(Widget child, [List<StudentCourseContent>? items]) =>
              _paddedSliverBox(_list([...header(items), child]));
          return _LiveData<List<StudentCourseContent>>(
            loadingLayout: StudentLoadingLayout.list,
            key: ValueKey(('course-content', id)),
            cache: _cache,
            cacheKey: ('course-content', id),
            load: () => widget.repository.courseContent(widget.identity, id),
            fallback: (_, placeholder) => scaffold(fill(placeholder)),
            builder: (_, items) => scaffold(
              items.isEmpty
                  ? fill(
                      const PreviewText('لا يوجد محتوى منشور لهذا الكورس.'),
                      items,
                    )
                  : _learningCards(
                      header: header(items),
                      itemCount: items.length,
                      itemBuilder: (_, index) =>
                          _courseContentCard(items[index], items),
                    ),
              scrollKey: PageStorageKey(('course', id)),
            ),
          );
        },
      ),
    );
  }

  Widget _courseContentCard(
    StudentCourseContent item,
    List<StudentCourseContent> content,
  ) {
    final kind = switch (item.type) {
      StudentCourseContentType.lesson => 'درس',
      StudentCourseContentType.file => 'ملف للعرض فقط',
      StudentCourseContentType.exercise => 'تمرين',
    };
    final access = item.locked
        ? 'يتطلب اشتراكاً'
        : item.isFree
        ? 'معاينة'
        : null;
    return PreviewListCard(
      title: item.title,
      subtitle: [kind, ?access].join(' · '),
      onTap: item.locked
          ? null
          : switch (item.type) {
              StudentCourseContentType.lesson => () => setState(() {
                _lessonCourseContent = content;
                _lessonId = item.id;
              }),
              StudentCourseContentType.file => () => setState(
                () => _file = (
                  id: item.id,
                  title: item.title,
                  pages: null,
                  downloadable: false,
                ),
              ),
              StudentCourseContentType.exercise => null,
            },
    );
  }

  Widget _examPage(
    StudentExamSession session, {
    String? examId,
    bool missing = false,
  }) => StudentExamSchedule(
    session: session,
    onBack: _back!,
    onSelect: (value) => setState(() => _examSession = value),
    content: _LiveData<List<StudentExamRow>>(
      loadingLayout: StudentLoadingLayout.schedule,
      key: ValueKey(session),
      cache: _cache,
      cacheKey: ('exam-schedule', session),
      load: () => _loadExams(session),
      builder: (_, rows) =>
          StudentExamRows(rows: rows, selectedId: examId, missing: missing),
    ),
  );

  void _cancelFileDownload() {
    _fileDownload?.ended.complete();
    _fileDownload = null;
  }

  Future<void> _downloadFile(String subjectId, StudentSubjectFile file) async {
    if (_fileDownload != null) return;
    final ended = Completer<void>();
    bool isCurrent() => mounted && identical(_fileDownload?.ended, ended);
    setState(() => _fileDownload = (fileId: file.id, ended: ended));
    try {
      final result = await widget.repository.academicFileDownload(
        widget.identity,
        file.id,
        whenCanceled: ended.future,
      );
      if (!mounted || _sessionRestricted) return;
      switch (result) {
        case Left(value: final failure)
            when failure == StudentSessionFailure.accountSuspended ||
                failure == StudentSessionFailure.deviceUnauthorized:
          _restrictLearningSession(failure);
          return;
        default:
          break;
      }
      if (!isCurrent() ||
          _tab != _LearningTab.subjects ||
          _detail != subjectId ||
          _subjectTab != 1 ||
          _file != null) {
        return;
      }
      if (result case Right(:final value)) {
        try {
          if (await launchUrl(value, mode: LaunchMode.externalApplication)) {
            return;
          }
        } on PlatformException {
          // The platform may have no browser available.
        }
      }
      if (!mounted || !isCurrent()) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.getLeft().toNullable() ==
                    StudentSessionFailure.learningDataDenied
                ? 'تنزيل هذا الملف غير مسموح.'
                : 'تعذّر فتح رابط التنزيل. أعد المحاولة.',
          ),
        ),
      );
    } finally {
      if (isCurrent()) setState(_cancelFileDownload);
    }
  }

  Widget _subjectContent(
    String id,
    List<Widget> header,
    Widget Function(Widget, {Key? scrollKey}) scaffold,
  ) => switch (_subjectTab) {
    0 => _subjectList<StudentSubjectExercise>(
      scaffold: scaffold,
      header: header,
      cacheKey: ('subject-exercises', id),
      load: () => widget.repository.subjectExercises(widget.identity, id),
      empty: const Center(child: PreviewText('لا توجد تمارين منشورة.')),
      card: (context, exercise) => PreviewListCard(
        title: exercise.title,
        onTap: () => setState(() => _exercise = exercise),
        asset: '5c3d1',
        badge: switch (exercise.state) {
          StudentExerciseState.solved => previewBadge(
            context,
            exercise.bestScore == null
                ? 'تم الحل'
                : 'تم الحل · ${exercise.bestScore}/100',
            tone: 'success',
          ),
          StudentExerciseState.grading => previewBadge(
            context,
            'قيد التصحيح',
            tone: 'warning',
          ),
          StudentExerciseState.attempted => previewBadge(
            context,
            'تمت المحاولة',
          ),
          StudentExerciseState.notAttempted => previewBadge(
            context,
            'لم يُحلّ',
          ),
        },
      ),
    ),
    1 => _subjectList<StudentSubjectFile>(
      scaffold: scaffold,
      header: header,
      cacheKey: ('subject-files', id),
      load: () => widget.repository.subjectFiles(widget.identity, id),
      empty: const Center(child: PreviewText('لا توجد ملفات منشورة.')),
      card: (_, file) => PreviewListCard(
        title: file.title,
        onTap: file.downloadable
            ? (_fileDownload == null ? () => _downloadFile(id, file) : null)
            : () => setState(() {
                _cancelFileDownload();
                _file = file;
              }),
        subtitle: _fileDownload?.fileId == file.id
            ? 'جارٍ تجهيز رابط التنزيل…'
            : [
                if (file.pages case final pages?) '$pages صفحة',
                if (file.downloadable) 'قابل للتنزيل',
              ].join(' · '),
      ),
    ),
    _ => _subjectList<StudentLessonSummary>(
      scaffold: scaffold,
      header: header,
      cacheKey: ('subject-lessons', id),
      load: () => widget.repository.subjectLessons(widget.identity, id),
      empty: const HasobjyLearningEmptyState.lessons(),
      card: (_, lesson) => StudentLessonCard(
        lesson: lesson,
        onTap: lesson.id == null
            ? null
            : () => setState(() => _lessonId = lesson.id),
      ),
    ),
  };

  Widget _subjectPage(String id, bool light) {
    Widget scaffold(Widget content, {Key? scrollKey}) => HasobjyFigmaFrame(
      scrollKey: scrollKey,
      appBarTitle: 'المادة',
      onBack: _back,
      bottomNavigation: _navigation(),
      backgroundLayer: _LearningBackground(frame: 'C-03', light: light),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: content,
        ),
      ],
    );
    return HasobjyVisualScope(
      frameName: light ? 'C-03-LIGHT' : 'C-03',
      child: _LiveData<StudentSubjectDetails>(
        loadingLayout: StudentLoadingLayout.details,
        key: ValueKey(id),
        cache: _cache,
        cacheKey: ('subject', id),
        load: () => widget.repository.subject(widget.identity, id),
        fallback: (_, placeholder) => scaffold(_paddedSliverBox(placeholder)),
        builder: (context, data) {
          final header = [
            PreviewText(data.subject.name, style: context.design.title),
            StudentSubjectProgress(subject: data.subject),
            PreviewTabs(
              key: ValueKey(_subjectTab),
              labels: const ['التمارين', 'الملفات', 'الدروس'],
              selected: _subjectTab,
              onSelected: (index) {
                if (index == _subjectTab) return;
                setState(() {
                  _cancelFileDownload();
                  _subjectTab = index;
                });
              },
            ),
          ];
          return _subjectContent(id, header, scaffold);
        },
      ),
    );
  }

  Widget _subjectList<T>({
    required Widget Function(Widget, {Key? scrollKey}) scaffold,
    required List<Widget> header,
    required Object cacheKey,
    required Future<Either<StudentSessionFailure, List<T>>> Function() load,
    required Widget empty,
    required Widget Function(BuildContext, T) card,
  }) {
    Widget fill(Widget content) =>
        _paddedSliverBox(_list(header, fill: content));

    return _LiveData<List<T>>(
      loadingLayout: StudentLoadingLayout.list,
      key: ValueKey(cacheKey),
      cache: _cache,
      cacheKey: cacheKey,
      load: load,
      fallback: (_, placeholder) => scaffold(fill(placeholder)),
      builder: (_, items) => scaffold(
        items.isEmpty
            ? fill(empty)
            : _learningCards(
                header: header,
                itemCount: items.length,
                itemBuilder: (context, index) => card(context, items[index]),
              ),
        scrollKey: PageStorageKey(cacheKey),
      ),
    );
  }

  Widget _learningCards({
    required List<Widget> header,
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
  }) => SliverPadding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    sliver: SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _list(header),
          ),
        ),
        SliverList.separated(
          itemCount: itemCount,
          itemBuilder: itemBuilder,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
        ),
      ],
    ),
  );

  Widget _paddedSliverBox(Widget child) => SliverFillRemaining(
    hasScrollBody: false,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: child,
    ),
  );

  PreviewActions _profileActions(String? detail) => PreviewActions(
    open: _actions.open,
    notice: _actions.notice,
    back: detail == 'edit-profile' || detail == 'study-time'
        ? () => _openDetail(_LearningTab.settings, 'profile')
        : () => _switchTab(_LearningTab.settings),
  );

  Widget _settings(BuildContext context, {StudentProfileData? profile}) =>
      ValueListenableBuilder<ThemeMode>(
        valueListenable: widget.themeMode,
        builder: (context, mode, _) => HasobjySettingsScreen(
          actions: _actions,
          onOpenProfile: () => _openDetail(_LearningTab.settings, 'profile'),
          studentName:
              profile?.name ??
              _cache.read<StudentHomeData>('home')?.name ??
              widget.identity.displayName ??
              'حساب الطالب',
          academicSummary: [
            ?profile?.department,
            if (profile?.year == 1) 'السنة الأولى',
            if (profile?.year == 2) 'السنة الثانية',
          ].join(' · '),
          onSignOut: context.read<GoogleIdentityCubit>().signOut,
          onOpenLegal: widget.onOpenLegal,
          navigation: _navigation(),
          backgroundLayer: _LearningBackground(
            frame: 'S-01',
            light: Theme.of(context).brightness == Brightness.light,
          ),
        ),
      );

  PreviewActions get _actions => PreviewActions(
    open: (destination) {
      switch (destination) {
        case 'C-01':
          _switchTab(_LearningTab.home);
        case 'C-02':
          _switchTab(_LearningTab.subjects);
        case 'F-01':
          _switchTab(_LearningTab.courses);
        case 'S-01':
          _switchTab(_LearningTab.settings);
        case 'S-02':
          _openDetail(_LearningTab.settings, 'profile');
        case 'H-02':
          _supportPage = 1;
          _selectTicket(null);
          _openDetail(_LearningTab.settings, 'support');
        case 'F-07':
          _openDetail(_LearningTab.settings, 'subscriptions');
        case 'S-04':
          _openDetail(_LearningTab.settings, 'device');
        case 'S-03':
          _openDetail(_LearningTab.settings, 'edit-profile');
        case 'S-01-DARK':
          unawaited(widget.onThemeChanged(ThemeMode.dark));
        case 'S-01-LIGHT':
          unawaited(widget.onThemeChanged(ThemeMode.light));
        case 'S-01-SYSTEM':
          unawaited(widget.onThemeChanged(ThemeMode.system));
      }
    },
    notice: () {},
    back: _back ?? () => _switchTab(_LearningTab.settings),
    selectedAppearance: switch (widget.themeMode.value) {
      ThemeMode.dark => 'داكن',
      ThemeMode.light => 'فاتح',
      ThemeMode.system => 'تلقائي',
    },
  );

  Widget _navigation() => PreviewNavigation(
    actions: _actions,
    hiddenDestinations: widget.coursesOnly ? const {'C-02'} : const {},
  );

  Widget _subjectsPage(bool light, bool previous) {
    Widget scaffold(Widget content, {Key? scrollKey}) => HasobjyFigmaFrame(
      scrollKey: scrollKey,
      bottomNavigation: _navigation(),
      backgroundLayer: _LearningBackground(frame: 'C-02', light: light),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
          sliver: SliverToBoxAdapter(
            child: _list([
              PreviewText('المواد', style: HasobjyPalette(light).title),
              TextButton(
                onPressed: () => setState(() => _detail = 'exam-schedule'),
                child: Text(
                  AppLocalizations.of(context).examSchedule,
                  style: HasobjyPalette(light).label
                      .copyWith(color: HasobjyPalette(light).brand),
                ),
              ),
              PreviewTabs(
                key: ValueKey(previous),
                labels: const ['الفصول السابقة', 'الفصل الحالي'],
                selected: previous ? 0 : 1,
                onSelected: (index) => setState(() => _previous = index == 0),
              ),
            ]),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: content,
        ),
      ],
    );
    return HasobjyVisualScope(
      frameName: light ? 'C-02-LIGHT' : 'C-02',
      child: _LiveData<List<StudentSubjectItem>>(
        loadingLayout: StudentLoadingLayout.list,
        key: ValueKey(previous),
        cache: _cache,
        cacheKey: ('subjects', previous),
        restore: widget.repository is StudentSubjectsSnapshotSource
            ? () => (widget.repository as StudentSubjectsSnapshotSource)
                  .subjectsSnapshot(widget.identity, previous: previous)
            : null,
        load: () =>
            widget.repository.subjects(widget.identity, previous: previous),
        fallback: (_, placeholder) =>
            scaffold(SliverToBoxAdapter(child: placeholder)),
        builder: (_, subjects) => scaffold(
          subjects.isEmpty
              ? const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: HasobjyLearningEmptyState.subjects(),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.only(bottom: 16),
                  sliver: SliverList.separated(
                    itemCount: subjects.length,
                    itemBuilder: (_, index) => _subjectCard(subjects[index]),
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                  ),
                ),
          scrollKey: PageStorageKey(('subjects', previous)),
        ),
      ),
    );
  }

  List<Widget> _subjectCards(List<StudentSubjectItem> subjects) => [
    if (subjects.isEmpty)
      const PreviewText('لا توجد مواد مسجّلة في هذه القائمة.'),
    for (final subject in subjects) _subjectCard(subject),
  ];

  Widget _subjectCard(StudentSubjectItem subject) => PreviewListCard(
    title: subject.name,
    subtitle: '${subject.completed} من ${subject.total} درساً مكتملة',
    asset: '38165',
    progress: subject.percent / 100,
    onTap: () => _openDetail(_LearningTab.subjects, subject.id),
  );

  Widget _coursesPage(bool light, bool mine, int page) {
    Widget scaffold(Widget content, {Key? scrollKey}) => HasobjyFigmaFrame(
      scrollKey: scrollKey,
      bottomNavigation: _navigation(),
      backgroundLayer: _LearningBackground(frame: 'F-01', light: light),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
          sliver: SliverToBoxAdapter(
            child: _list([
              PreviewText('الكورسات', style: HasobjyPalette(light).title),
              PreviewTabs(
                key: ValueKey(mine),
                labels: const ['كورساتي', 'كل الكورسات'],
                selected: mine ? 0 : 1,
                onSelected: (index) {
                  final selectedMine = index == 0;
                  if (selectedMine == _mine) return;
                  setState(() {
                    _mine = selectedMine;
                    _page = 1;
                  });
                },
              ),
            ]),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: content,
        ),
      ],
    );
    return HasobjyVisualScope(
      frameName: light ? 'F-01-LIGHT' : 'F-01',
      child: _LiveData<StudentCoursePageData>(
        loadingLayout: page == 1
            ? StudentLoadingLayout.list
            : StudentLoadingLayout.nextPage,
        key: ValueKey((mine, page)),
        cache: _cache,
        cacheKey: ('courses', mine, page),
        restore: widget.repository is StudentCoursesSnapshotSource
            ? () => (widget.repository as StudentCoursesSnapshotSource)
                  .coursesSnapshot(widget.identity, mine: mine, page: page)
            : null,
        load: () =>
            widget.repository.courses(widget.identity, mine: mine, page: page),
        fallback: (_, placeholder) => scaffold(
          SliverToBoxAdapter(child: placeholder),
          scrollKey: ValueKey(('courses', mine, page)),
        ),
        builder: (context, data) {
          final pagination = page > 1 || data.hasMore
              ? _coursePagination(hasMore: data.hasMore)
              : null;
          final content = data.courses.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _list(
                      const [],
                      fill: HasobjyLearningEmptyState.courses(
                        mine: mine,
                        laterPage: page > 1,
                      ),
                      footer: pagination,
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.only(bottom: 16),
                  sliver: SliverMainAxisGroup(
                    slivers: [
                      SliverList.separated(
                        itemCount: data.courses.length,
                        itemBuilder: (context, index) {
                          final course = data.courses[index];
                          return HasobjyCourseCard(
                            title: course.name,
                            subtitle: '${course.durationDays} يوم',
                            price: _courseAccess(course),
                            iconAsset: previewIcon(
                              context,
                              'تطوير تطبيقات Flutter',
                            ),
                            onTap: () =>
                                _openDetail(_LearningTab.courses, course.id),
                          );
                        },
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                      ),
                      if (pagination != null)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: pagination,
                          ),
                        ),
                    ],
                  ),
                );
          return scaffold(
            content,
            scrollKey: page == 1
                ? PageStorageKey(('courses', mine))
                : ValueKey(('courses', mine, page)),
          );
        },
      ),
    );
  }

  String _courseAccess(StudentCourseItem course) =>
      course.subscribed ? 'الاشتراك نشط' : '${course.priceUsd} USD';

  Widget _coursePagination({required bool hasMore}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      TextButton(
        onPressed: _page > 1 ? () => setState(() => _page--) : null,
        child: const Text('السابق'),
      ),
      TextButton(
        onPressed: hasMore ? () => setState(() => _page++) : null,
        child: const Text('التالي'),
      ),
    ],
  );

  Widget _list(List<Widget> children, {Widget? fill, Widget? footer}) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    spacing: 12,
    children: [
      ...children,
      if (fill != null) Expanded(child: fill),
      ?footer,
    ],
  );
}

class _InboxTitle extends StatelessWidget {
  const _InboxTitle();

  @override
  Widget build(BuildContext context) =>
      PreviewText('الإشعارات', style: context.design.title);
}

class _LearningBackground extends StatelessWidget {
  const _LearningBackground({required this.frame, required this.light});

  final String frame;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final ornaments = switch ((frame, light)) {
      ('C-02', _) || ('F-02', false) => const [
        ('a12f7', -26.4, 227.6, 44.8),
        ('f1409', 368.67, 180.67, 58.667),
      ],
      ('F-02', true) => const [
        ('ff7c9', 380.8, 240.8, 38.4),
        ('5a19f', -42.67, 155.33, 69.333),
      ],
      ('C-03', _) || ('F-01', true) || ('H-01', false) => const [
        ('5df30', 364.0, 118.0, 64.0),
        ('ae3b3', -21.2, 280.8, 38.4),
      ],
      _ => const [
        ('6f3f1', -43.33, 122.67, 74.667),
        ('9af13', 381.2, 99.2, 41.6),
      ],
    };
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (_, constraints) => Stack(
          fit: StackFit.expand,
          children: [
            HasobjySvg(light ? '624a4' : 'acb67', fit: BoxFit.fill),
            for (final (asset, x, y, size) in ornaments)
              Positioned(
                left: x > 195 ? constraints.maxWidth - (390 - x) : x,
                top: y,
                child: HasobjySvg(asset, width: size, height: size),
              ),
          ],
        ),
      ),
    );
  }
}

class _LiveData<T extends Object> extends StatelessWidget {
  const _LiveData({
    super.key,
    required this.cache,
    required this.cacheKey,
    required this.load,
    required this.loadingLayout,
    required this.builder,
    this.fallback,
    this.restore,
  });

  final Future<({T data, DateTime storedAt})?> Function()? restore;
  final StudentLearningCache cache;
  final Object cacheKey;

  final Future<Either<StudentSessionFailure, T>> Function() load;
  final StudentLoadingLayout? loadingLayout;
  final Widget Function(BuildContext, T) builder;
  final Widget Function(BuildContext, Widget)? fallback;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        StudentLearningDataCubit<T>(cache, cacheKey, load, restore: restore)
          ..load(),
    child: BlocListener<GoogleIdentityCubit, GoogleIdentityState>(
      listenWhen: (previous, current) =>
          previous is GoogleIdentityWorking &&
          previous.session?.next == StudentNextStep.home &&
          current is GoogleIdentityReady &&
          current.session?.next == StudentNextStep.home &&
          previous.identity?.firebaseUid == current.identity.firebaseUid,
      listener: (context, _) {
        if (ModalRoute.of(context)?.isCurrent == false) return;
        unawaited(context.read<StudentLearningDataCubit<T>>().load());
      },
      child:
          BlocBuilder<StudentLearningDataCubit<T>, StudentLearningDataState<T>>(
            buildWhen: (previous, current) =>
                current.data == null || !identical(previous.data, current.data),
            builder: (context, state) {
              if (state.data case final data?) return builder(context, data);
              final layout = loadingLayout;
              final placeholder = state.working
                  ? (layout == null
                        ? const SizedBox.shrink()
                        : StudentContentSkeleton(layout: layout))
                  : Column(
                      children: [
                        const PreviewText('تعذّر تحميل البيانات.'),
                        TextButton(
                          onPressed:
                              state.failure == StudentSessionFailure.expired
                              ? context
                                    .read<GoogleIdentityCubit>()
                                    .revalidateSession
                              : () => context
                                    .read<StudentLearningDataCubit<T>>()
                                    .load(force: true),
                          child: Text(
                            AppLocalizations.of(context).appStatusRetry,
                          ),
                        ),
                      ],
                    );
              return fallback?.call(context, placeholder) ?? placeholder;
            },
          ),
    ),
  );
}
