import 'package:cit_zone/core/localization/generated/app_localizations.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/either.dart';
import '../../../auth/domain/google_identity.dart';
import '../../../auth/domain/student_learning.dart';
import '../../../auth/domain/student_session_repository.dart';
import '../../../auth/presentation/cubit/google_identity_cubit.dart';
import '../theme/hasobjy_visual_scope.dart';
import '../widgets/hasobjy_figma_components.dart';
import '../widgets/hasobjy_learning_empty_state.dart';
import 'preview/preview_widgets.dart';
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
  _LearningTab _tab = _LearningTab.home;
  String? _detail;
  bool _previous = false;
  bool _mine = false;
  int _page = 1;

  void _switchTab(_LearningTab tab) => setState(() {
    _tab = tab;
    _detail = null;
  });

  void _openDetail(_LearningTab tab, String id) => setState(() {
    _tab = tab;
    _detail = id;
  });

  @override
  Widget build(BuildContext context) {
    final repository = widget.repository;
    final identity = widget.identity;
    final light = Theme.of(context).brightness == Brightness.light;
    final detail = _detail;
    final frame = switch (_tab) {
      _LearningTab.home => 'C-01',
      _LearningTab.settings => detail == null ? 'S-01' : 'S-02',
      _LearningTab.subjects => detail == null ? 'C-02' : 'C-03',
      _LearningTab.courses => detail == null ? 'F-01' : 'F-02',
    };
    if (_tab == _LearningTab.settings) {
      return HasobjyVisualScope(
        frameName: light ? '$frame-LIGHT' : frame,
        child: _LiveData<StudentProfileData>(
          key: ValueKey(frame),
          load: () => repository.profile(identity),
          builder: (context, data) => detail == null
              ? ValueListenableBuilder<ThemeMode>(
                  valueListenable: widget.themeMode,
                  builder: (context, mode, _) => HasobjySettingsScreen(
                    actions: _actions,
                    studentName: data.name,
                    onSignOut: context.read<GoogleIdentityCubit>().signOut,
                    navigation: _navigation(),
                  ),
                )
              : HasobjyProfileScreen(actions: _actions, profile: data),
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
              load: () => repository.home(identity),
              builder: (context, data) {
                final coursesOnly = widget.coursesOnly;
                final greeting = PreviewText(
                  'مرحباً ${data.name}',
                  style: context.design.title,
                );
                if (data.courses.isEmpty &&
                    (coursesOnly || data.subjects.isEmpty)) {
                  return _list(
                    [greeting],
                    fill: HasobjyLearningEmptyState.home(
                      coursesOnly: coursesOnly,
                    ),
                  );
                }
                return _list([
                  greeting,
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
                load: () => repository.subjects(identity, previous: _previous),
                builder: (_, subjects) => subjects.isEmpty
                    ? const HasobjyLearningEmptyState.subjects()
                    : _list(_subjectCards(subjects)),
              ),
            ),
            (_LearningTab.subjects, final String id) =>
              _LiveData<StudentSubjectDetails>(
                key: ValueKey(id),
                load: () => repository.subject(identity, id),
                builder: (context, data) {
                  final name = PreviewText(
                    data.subject.name,
                    style: context.design.title,
                  );
                  if (data.lessons.isEmpty) {
                    return _list([
                      name,
                    ], fill: const HasobjyLearningEmptyState.lessons());
                  }
                  return _list([
                    name,
                    PreviewText('تقدّمك في المادة: ${data.subject.percent}٪'),
                    PreviewProgress(
                      data.subject.percent / 100,
                      height: 6,
                      width: 100,
                    ),
                    for (final lesson in data.lessons)
                      PreviewListCard(
                        title: lesson.title,
                        subtitle: lesson.locked
                            ? 'مقفل'
                            : lesson.completed
                            ? 'مكتمل'
                            : null,
                      ),
                  ]);
                },
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
                load: () =>
                    repository.courses(identity, mine: _mine, page: _page),
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

typedef _LiveState<T> = ({
  T? data,
  bool working,
  StudentSessionFailure? failure,
});

class _LiveDataCubit<T> extends Cubit<_LiveState<T>> {
  _LiveDataCubit(this.request)
    : super((data: null, working: false, failure: null));

  final Future<Either<StudentSessionFailure, T>> Function() request;

  Future<void> load() async {
    if (isClosed || state.working) return;
    emit((data: null, working: true, failure: null));
    final result = await request();
    if (isClosed) return;
    emit((
      data: result.getRight().toNullable(),
      working: false,
      failure: result.getLeft().toNullable(),
    ));
  }
}

class _LiveData<T> extends StatelessWidget {
  const _LiveData({super.key, required this.load, required this.builder});

  final Future<Either<StudentSessionFailure, T>> Function() load;
  final Widget Function(BuildContext, T) builder;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => _LiveDataCubit<T>(load)..load(),
    child: BlocBuilder<_LiveDataCubit<T>, _LiveState<T>>(
      builder: (context, state) {
        if (state.working) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.data case final data?) return builder(context, data);
        return Column(
          children: [
            const PreviewText('تعذّر تحميل البيانات.'),
            TextButton(
              onPressed: state.failure == StudentSessionFailure.expired
                  ? context.read<GoogleIdentityCubit>().revalidateSession
                  : context.read<_LiveDataCubit<T>>().load,
              child: Text(AppLocalizations.of(context).appStatusRetry),
            ),
          ],
        );
      },
    ),
  );
}
