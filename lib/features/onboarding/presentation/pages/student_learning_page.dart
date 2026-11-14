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
import '../../../auth/domain/student_session_repository.dart';
import '../../../auth/presentation/cubit/google_identity_cubit.dart';
import '../cubit/student_learning_data_cubit.dart';
import '../theme/hasobjy_visual_scope.dart';
import '../widgets/hasobjy_figma_components.dart';
import '../widgets/hasobjy_learning_empty_state.dart';
import 'preview/preview_widgets.dart';
import 'student_subject_progress.dart';
import 'student_resume_card.dart';
import 'student_file_view_page.dart';
import 'student_subscriptions.dart';
import 'student_support.dart';
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
  });

  final StudentSessionRepository repository;
  final ValueListenable<ThemeMode> themeMode;
  final Future<void> Function(ThemeMode) onThemeChanged;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<GoogleIdentityCubit, GoogleIdentityState>(
        builder: (context, state) {
          if (state case GoogleIdentityReady(
            session: StudentSession(
              next: StudentNextStep.home,
              :final usageType,
            ),
            :final identity,
          )) {
            return _LearningShell(
              key: ValueKey(identity.firebaseUid),
              identity: identity,
              repository: repository,
              themeMode: themeMode,
              onThemeChanged: onThemeChanged,
              coursesOnly: usageType == StudentUsageType.courses,
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
    required this.themeMode,
    required this.onThemeChanged,
  });

  final GoogleIdentity identity;
  final StudentSessionRepository repository;
  final bool coursesOnly;
  final ValueListenable<ThemeMode> themeMode;
  final Future<void> Function(ThemeMode) onThemeChanged;

  @override
  State<_LearningShell> createState() => _LearningShellState();
}

class _LearningShellState extends State<_LearningShell> {
  final _cache = StudentLearningCache();
  _LearningTab _tab = _LearningTab.home;
  String? _detail;
  String? _lessonId;
  StudentSubjectExercise? _exercise;
  StudentSubjectFile? _file;
  String? _downloadingFileId;
  int _subjectTab = 2;
  bool _previous = false;
  bool _mine = false;
  int _page = 1;
  int _supportPage = 1;
  StudentTicket? _ticket;
  bool _creatingTicket = false;

  void _switchTab(_LearningTab tab) => setState(() {
    _tab = tab;
    _detail = null;
  });

  void _openDetail(_LearningTab tab, String id) => setState(() {
    _tab = tab;
    _detail = id;
    _subjectTab = 2;
  });

  @override
  void dispose() {
    _cache.clear();
    super.dispose();
  }

  Future<Either<StudentSessionFailure, void>> _saveProfile(
    String? name,
    String? phone,
  ) async {
    final result = await widget.repository.updateProfile(
      widget.identity,
      officialName: name,
      phone: phone,
    );
    if (result.isRight()) {
      _cache.invalidate('profile');
      _cache.invalidate('home');
    }
    return result;
  }

  Widget _lessonPage(String id, bool light) => HasobjyVisualScope(
    frameName: light ? 'C-04-LIGHT' : 'C-04',
    child: HasobjyFigmaFrame(
      appBarTitle: 'الدرس',
      onBack: () => setState(() => _lessonId = null),
      backgroundLayer: _LearningBackground(frame: 'C-04', light: light),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _LiveData<StudentLessonDetail>(
          key: ValueKey(id),
          cache: _cache,
          cacheKey: ('lesson', id),
          load: () => widget.repository.lesson(widget.identity, id),
          builder: (context, data) => _list([
            PreviewText(data.title, style: context.design.headingMedium),
            if (data.description case final description?
                when description.isNotEmpty)
              PreviewText(description),
            PreviewPanel(
              children: [
                PreviewText(
                  data.locked
                      ? 'هذا الدرس يتطلب اشتراكاً سارياً.'
                      : data.videoReady
                      ? 'تشغيل الفيديو غير متاح في هذه النسخة.'
                      : 'الفيديو قيد المعالجة.',
                ),
              ],
            ),
            if (data.nextId case final next?)
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
          onBack: () => setState(() {
            _creatingTicket = false;
            _supportPage = 1;
            _cache.invalidate(('support', 1));
          }),
          onCreate: (subject, body) => widget.repository.createSupportTicket(
            widget.identity,
            subject,
            body,
          ),
          onCreated: (ticket) => setState(() {
            _creatingTicket = false;
            _supportPage = 1;
            _cache.invalidate(('support', 1));
            _ticket = ticket;
          }),
        ),
      );
    }
    final ticket = _ticket;
    final page = _supportPage;
    final frame = ticket == null ? 'H-02' : 'H-04';
    final actions = PreviewActions(
      open: (_) {},
      notice: () {},
      back: ticket == null
          ? () => _switchTab(_LearningTab.settings)
          : () => setState(() => _ticket = null),
    );
    final threadCache = StudentLearningCache();
    return HasobjyVisualScope(
      frameName: light ? '$frame-LIGHT' : frame,
      child: ticket == null
          ? PreviewScaffold(
              title: 'الدعم والتواصل',
              actions: actions,
              children: [
                PreviewButton(
                  'تذكرة جديدة',
                  onTap: () => setState(() => _creatingTicket = true),
                  light3D: true,
                  iconAsset: light ? 'cf7cc' : null,
                ),
                _LiveData<StudentTicketPage>(
                  key: ValueKey(page),
                  cache: _cache,
                  cacheKey: ('support', page),
                  load: () =>
                      widget.repository.supportTickets(widget.identity, page),
                  builder: (_, data) => StudentSupportList(
                    data: data,
                    onOpen: (ticket) => setState(() => _ticket = ticket),
                    onPrevious: page > 1
                        ? () => setState(() => _supportPage--)
                        : null,
                    onNext: data.hasMore
                        ? () => setState(() => _supportPage++)
                        : null,
                  ),
                ),
              ],
            )
          : PreviewScaffold(
              title: ticket.subject,
              actions: actions,
              children: [
                _LiveData<StudentTicketThread>(
                  cache: threadCache,
                  cacheKey: ticket.id,
                  load: () => widget.repository.supportTicket(
                    widget.identity,
                    ticket.id,
                  ),
                  builder: (_, data) => StudentSupportThread(
                    data: data,
                    onReply: (body, key) async {
                      final result = await widget.repository
                          .replyToSupportTicket(
                            widget.identity,
                            ticket.id,
                            body,
                            key,
                          );
                      if (result.isRight()) {
                        _cache.invalidate(('support', page));
                      }
                      return result;
                    },
                  ),
                ),
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repository = widget.repository;
    final identity = widget.identity;
    final light = Theme.of(context).brightness == Brightness.light;
    if (_exercise case final exercise?) {
      final subjectId = _detail;
      return HasobjyVisualScope(
        frameName: light ? 'C-07-LIGHT' : 'C-07',
        child: PreviewScaffold(
          title: exercise.title,
          actions: PreviewActions(
            back: () => setState(() => _exercise = null),
            open: (_) {},
            notice: () {},
          ),
          children: [
            _LiveData<StudentExercisePrompt>(
              cache: _cache,
              cacheKey: ('exercise', exercise.id),
              load: () => repository.exercise(identity, exercise.id),
              builder: (_, prompt) => StudentExercisePromptView(
                prompt: prompt,
                latestAttempt: () =>
                    repository.latestExerciseAttempt(identity, exercise.id),
                onBack: () => setState(() => _exercise = null),
                submit: (key, {code, language, choiceId}) async {
                  final result = await repository.submitExercise(
                    identity,
                    exercise.id,
                    key,
                    code: code,
                    language: language,
                    choiceId: choiceId,
                  );
                  if (result.isRight()) {
                    _cache.invalidate(('subject-exercises', subjectId));
                  }
                  return result;
                },
                readAttempt: (id) async {
                  final result = await repository.exerciseAttempt(identity, id);
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
          actions: PreviewActions(
            open: (_) {},
            notice: () {},
            back: () => setState(() => _file = null),
          ),
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
    if (_tab == _LearningTab.settings && detail == 'subscriptions') {
      return HasobjyVisualScope(
        frameName: light ? '$frame-LIGHT' : frame,
        child: _LiveData<List<StudentSubscription>>(
          cache: _cache,
          cacheKey: 'subscriptions',
          load: () => repository.subscriptions(identity),
          fallback: (_, placeholder) => StudentUpdateScaffold(
            title: 'اشتراكاتي',
            actions: _actions,
            children: [placeholder],
          ),
          builder: (_, rows) => StudentSubscriptions(
            actions: _actions,
            subscriptions: rows,
            onBrowseCourses: () => setState(() {
              _tab = _LearningTab.courses;
              _detail = null;
              _mine = false;
              _page = 1;
            }),
          ),
        ),
      );
    }
    if (detail == 'device' && _tab == _LearningTab.settings) {
      return HasobjyVisualScope(
        frameName: light ? '$frame-LIGHT' : frame,
        child: PreviewScaffold(
          actions: _actions,
          title: 'الجهاز المسجّل',
          children: [
            _LiveData<StudentDeviceData>(
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
          key: ValueKey(frame),
          cache: _cache,
          cacheKey: 'profile',
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
            'profile' => HasobjyProfileScreen(actions: _actions, profile: data),
            _ => _settings(context, profile: data),
          },
        ),
      );
    }
    return HasobjyVisualScope(
      frameName: light ? '$frame-LIGHT' : frame,
      child: HasobjyFigmaFrame(
        appBarTitle: detail == null
            ? null
            : _tab == _LearningTab.subjects
            ? 'المادة'
            : 'تفاصيل الكورس',
        onBack: detail == null ? null : () => setState(() => _detail = null),
        bottomNavigation: frame == 'F-02' ? null : _navigation(),
        backgroundLayer: frame == 'F-02'
            ? null
            : _LearningBackground(frame: frame, light: light),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: switch ((_tab, detail)) {
            (_LearningTab.settings, _) => const SizedBox.shrink(),
            (_LearningTab.home, _) => _LiveData<StudentHomeData>(
              key: const ValueKey('home'),
              cache: _cache,
              cacheKey: 'home',
              load: () => repository.home(identity),
              builder: (context, data) {
                final coursesOnly = widget.coursesOnly;
                final greeting = PreviewText(
                  'مرحباً ${data.name}',
                  style: context.design.title,
                );
                final resumeLesson = data.resumeLesson;
                if (resumeLesson == null &&
                    data.courses.isEmpty &&
                    (coursesOnly || data.subjects.isEmpty)) {
                  return _list(
                    [greeting],
                    fill: HasobjyLearningEmptyState.home(
                      coursesOnly: coursesOnly,
                    ),
                  );
                }
                return _list([
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
                ]);
              },
            ),
            (_LearningTab.subjects, null) => _list(
              [
                PreviewText('المواد', style: HasobjyPalette(light).title),
                PreviewTabs(
                  key: ValueKey(_previous),
                  labels: const ['الفصول السابقة', 'الفصل الحالي'],
                  selected: _previous ? 0 : 1,
                  onSelected: (index) => setState(() => _previous = index == 0),
                ),
              ],
              fill: _LiveData<List<StudentSubjectItem>>(
                key: ValueKey(_previous),
                cache: _cache,
                cacheKey: ('subjects', previous),
                load: () => repository.subjects(identity, previous: previous),
                builder: (_, subjects) => subjects.isEmpty
                    ? const HasobjyLearningEmptyState.subjects()
                    : _list(_subjectCards(subjects)),
              ),
            ),
            (_LearningTab.subjects, final String id) =>
              _LiveData<StudentSubjectDetails>(
                key: ValueKey(id),
                cache: _cache,
                cacheKey: ('subject', id),
                load: () => repository.subject(identity, id),
                builder: (context, data) => _list([
                  PreviewText(data.subject.name, style: context.design.title),
                  StudentSubjectProgress(subject: data.subject),
                  PreviewTabs(
                    key: ValueKey(_subjectTab),
                    labels: const ['التمارين', 'الملفات', 'الدروس'],
                    selected: _subjectTab,
                    onSelected: (index) => setState(() => _subjectTab = index),
                  ),
                ], fill: _subjectContent(id)),
              ),
            (_LearningTab.courses, null) => _list(
              [
                PreviewText('الكورسات', style: HasobjyPalette(light).title),
                PreviewTabs(
                  key: ValueKey(_mine),
                  labels: const ['كورساتي', 'كل الكورسات'],
                  selected: _mine ? 0 : 1,
                  onSelected: (index) => setState(() {
                    _mine = index == 0;
                    _page = 1;
                  }),
                ),
              ],
              fill: _LiveData<StudentCoursePageData>(
                key: ValueKey((_mine, _page)),
                cache: _cache,
                cacheKey: ('courses', mine, page),
                load: () =>
                    repository.courses(identity, mine: mine, page: page),
                builder: (context, data) {
                  final pagination = _page > 1 || data.hasMore
                      ? _coursePagination(hasMore: data.hasMore)
                      : null;
                  if (data.courses.isEmpty) {
                    return _list(
                      const [],
                      fill: HasobjyLearningEmptyState.courses(
                        mine: _mine,
                        laterPage: _page > 1,
                      ),
                      footer: pagination,
                    );
                  }
                  return _list([
                    for (final course in data.courses)
                      HasobjyCourseCard(
                        title: course.name,
                        subtitle: '${course.durationDays} يوم',
                        price: _courseAccess(course),
                        iconAsset: previewIcon(
                          context,
                          'تطوير تطبيقات Flutter',
                        ),
                        onTap: () =>
                            _openDetail(_LearningTab.courses, course.id),
                      ),
                    ?pagination,
                  ]);
                },
              ),
            ),
            (_LearningTab.courses, final String id) =>
              _LiveData<StudentCourseItem>(
                key: ValueKey(id),
                cache: _cache,
                cacheKey: ('course', id),
                load: () => repository.course(identity, id),
                builder: (context, course) => _list([
                  Container(
                    height: 150,
                    color: context.design.surfaceSubtle,
                    alignment: Alignment.center,
                    child: PreviewIconTile(
                      asset: 'c0735',
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
                      PreviewKeyValue(
                        'صلاحية الوصول',
                        '${course.durationDays} يوم',
                        body: true,
                      ),
                      PreviewKeyValue(
                        'السعر',
                        '${course.priceUsd} USD',
                        body: true,
                      ),
                      if (course.subscribed) const PreviewText('الاشتراك نشط'),
                    ],
                  ),
                ]),
              ),
          },
        ),
      ),
    );
  }

  Future<void> _downloadFile(String subjectId, StudentSubjectFile file) async {
    if (_downloadingFileId != null) return;
    setState(() => _downloadingFileId = file.id);
    try {
      final result = await widget.repository.academicFileDownload(
        widget.identity,
        file.id,
      );
      if (!mounted ||
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
      if (!mounted) return;
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
      if (mounted) setState(() => _downloadingFileId = null);
    }
  }

  Widget _subjectContent(String id) => switch (_subjectTab) {
    0 => _LiveData<List<StudentSubjectExercise>>(
      cache: _cache,
      cacheKey: ('subject-exercises', id),
      load: () => widget.repository.subjectExercises(widget.identity, id),
      builder: (context, exercises) => exercises.isEmpty
          ? const Center(child: PreviewText('لا توجد تمارين منشورة.'))
          : _list([
              for (final exercise in exercises)
                PreviewListCard(
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
            ]),
    ),
    1 => _LiveData<List<StudentSubjectFile>>(
      cache: _cache,
      cacheKey: ('subject-files', id),
      load: () => widget.repository.subjectFiles(widget.identity, id),
      builder: (_, files) => files.isEmpty
          ? const Center(child: PreviewText('لا توجد ملفات منشورة.'))
          : _list([
              for (final file in files)
                PreviewListCard(
                  title: file.title,
                  onTap: file.downloadable
                      ? (_downloadingFileId == null
                            ? () => _downloadFile(id, file)
                            : null)
                      : () => setState(() => _file = file),
                  subtitle: _downloadingFileId == file.id
                      ? 'جارٍ تجهيز رابط التنزيل…'
                      : [
                          if (file.pages case final pages?) '$pages صفحة',
                          if (file.downloadable) 'قابل للتنزيل',
                        ].join(' · '),
                ),
            ]),
    ),
    _ => _LiveData<List<StudentLessonSummary>>(
      cache: _cache,
      cacheKey: ('subject-lessons', id),
      load: () => widget.repository.subjectLessons(widget.identity, id),
      builder: (_, lessons) => lessons.isEmpty
          ? const HasobjyLearningEmptyState.lessons()
          : _list([
              for (final lesson in lessons)
                StudentLessonCard(
                  lesson: lesson,
                  onTap: lesson.id == null
                      ? null
                      : () => setState(() => _lessonId = lesson.id),
                ),
            ]),
    ),
  };

  PreviewActions _profileActions(String? detail) => PreviewActions(
    open: _actions.open,
    notice: _actions.notice,
    back: detail == 'edit-profile'
        ? () => _openDetail(_LearningTab.settings, 'profile')
        : () => _switchTab(_LearningTab.settings),
  );

  Widget _settings(BuildContext context, {StudentProfileData? profile}) =>
      ValueListenableBuilder<ThemeMode>(
        valueListenable: widget.themeMode,
        builder: (context, mode, _) => HasobjySettingsScreen(
          actions: _actions,
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
          _ticket = null;
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
    back: () => _switchTab(_LearningTab.settings),
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

  List<Widget> _subjectCards(List<StudentSubjectItem> subjects) => [
    if (subjects.isEmpty)
      const PreviewText('لا توجد مواد مسجّلة في هذه القائمة.'),
    for (final subject in subjects)
      PreviewListCard(
        title: subject.name,
        subtitle: '${subject.completed} من ${subject.total} درساً مكتملة',
        asset: '38165',
        progress: subject.percent / 100,
        onTap: () => _openDetail(_LearningTab.subjects, subject.id),
      ),
  ];

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

class _LearningBackground extends StatelessWidget {
  const _LearningBackground({required this.frame, required this.light});

  final String frame;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final ornaments = switch ((frame, light)) {
      ('C-02', _) => const [
        ('a12f7', -26.4, 227.6, 44.8),
        ('f1409', 368.67, 180.67, 58.667),
      ],
      ('C-03', _) || ('F-01', true) => const [
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
    required this.builder,
    this.fallback,
  });

  final StudentLearningCache cache;
  final Object cacheKey;

  final Future<Either<StudentSessionFailure, T>> Function() load;
  final Widget Function(BuildContext, T) builder;
  final Widget Function(BuildContext, Widget)? fallback;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => StudentLearningDataCubit<T>(cache, cacheKey, load)..load(),
    child:
        BlocBuilder<StudentLearningDataCubit<T>, StudentLearningDataState<T>>(
          builder: (context, state) {
            if (state.data case final data?) return builder(context, data);
            final placeholder = state.working
                ? const Center(child: CircularProgressIndicator())
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
  );
}
