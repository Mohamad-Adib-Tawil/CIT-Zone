import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'admin_figma_frame.dart';
import 'admin_figma_screen_data.dart';

typedef OpenAdminFigmaFrame = void Function(AdminFigmaFrame frame, bool light);

class AdminFigmaGalleryPage extends StatelessWidget {
  const AdminFigmaGalleryPage({super.key, required this.onOpenFrame});

  final OpenAdminFigmaFrame onOpenFrame;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('شاشات الإدارة من Figma')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _PreviewNotice(),
            const SizedBox(height: 16),
            for (final section in _sections) ...[
              Text(section, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              for (final frame in AdminFigmaFrame.all.where(
                (item) => item.section == section,
              ))
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '${frame.key} · ${frame.title}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton(
                              onPressed: () => onOpenFrame(frame, false),
                              child: Text('داكن · ${frame.darkNodeId}'),
                            ),
                            OutlinedButton(
                              onPressed: () => onOpenFrame(frame, true),
                              child: Text('فاتح · ${frame.lightNodeId}'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 28),
            const Text(
              'لوحة التحكم والمؤشرات مستثناة من تطبيق الهاتف. المعرض وبقية الشاشات أدوات تطوير ولا تمنح صلاحيات إدارية.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class AdminFigmaPreviewPage extends StatelessWidget {
  const AdminFigmaPreviewPage({
    super.key,
    required this.frame,
    required this.light,
    required this.onOpenFrame,
  });

  final AdminFigmaFrame frame;
  final bool light;
  final OpenAdminFigmaFrame onOpenFrame;

  @override
  Widget build(BuildContext context) {
    final colors = _AdminFigmaColors(light);
    return Theme(
      data: _adminTheme(colors),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: colors.background,
          drawer: _AdminNavigationDrawer(
            frame: frame,
            light: light,
            onOpenFrame: onOpenFrame,
          ),
          appBar: MediaQuery.sizeOf(context).width < 980
              ? AppBar(
                  backgroundColor: colors.surface.withValues(alpha: .94),
                  titleSpacing: 4,
                  title: Row(
                    children: [
                      SvgPicture.asset(
                        light
                            ? AdminFigmaAssets.lightLogo
                            : AdminFigmaAssets.darkLogo,
                        width: 32,
                        height: 32,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('حاسوبجي · الإدارة')),
                      _PreviewBadge(colors: colors),
                    ],
                  ),
                )
              : null,
          body: Stack(
            fit: StackFit.expand,
            children: [
              SvgPicture.asset(
                light
                    ? AdminFigmaAssets.lightBackground
                    : AdminFigmaAssets.darkBackground,
                fit: BoxFit.cover,
              ),
              SafeArea(
                top: MediaQuery.sizeOf(context).width >= 980,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final desktop = constraints.maxWidth >= 980;
                    final body = _AdminFigmaScreenBody(
                      frame: frame,
                      data: AdminFigmaScreenCatalog.data[frame.key]!,
                      colors: colors,
                    );
                    if (!desktop) return body;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 260,
                          child: _AdminSidebar(
                            frame: frame,
                            light: light,
                            colors: colors,
                            onOpenFrame: onOpenFrame,
                          ),
                        ),
                        Expanded(child: body),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminFigmaScreenBody extends StatelessWidget {
  const _AdminFigmaScreenBody({
    required this.frame,
    required this.data,
    required this.colors,
  });

  final AdminFigmaFrame frame;
  final AdminFigmaScreenData data;
  final _AdminFigmaColors colors;

  @override
  Widget build(BuildContext context) {
    if (frame.key == 'M-A01') {
      return _AdminLoginPreview(data: data, colors: colors);
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        frame.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      if (data.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          data.subtitle,
                          style: TextStyle(color: colors.secondary),
                        ),
                      ],
                    ],
                  ),
                ),
                if (data.action.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  _FigmaActionButton(
                    label: data.action,
                    colors: colors,
                    onTap: () => _showPreviewMessage(context),
                  ),
                ],
              ],
            ),
            if (data.filters.isNotEmpty) ...[
              const SizedBox(height: 18),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: data.filters.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => _FilterChip(
                    label: data.filters[index],
                    colors: colors,
                    onTap: () => _showPreviewMessage(context),
                  ),
                ),
              ),
            ],
            if (data.metrics.isNotEmpty) ...[
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 850
                      ? 4
                      : constraints.maxWidth >= 520
                      ? 3
                      : 2;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: data.metrics.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      mainAxisExtent: 82,
                    ),
                    itemBuilder: (context, index) => _MetricCard(
                      metric: data.metrics[index],
                      colors: colors,
                    ),
                  );
                },
              ),
            ],
            for (final panel in data.panels) ...[
              const SizedBox(height: 16),
              _AdminFigmaPanel(panel: panel, colors: colors),
            ],
            const SizedBox(height: 8),
            const _PreviewNotice(compact: true),
          ],
        ),
      ),
    );
  }
}

class _AdminLoginPreview extends StatelessWidget {
  const _AdminLoginPreview({required this.data, required this.colors});
  final AdminFigmaScreenData data;
  final _AdminFigmaColors colors;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 420,
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.fromLTRB(32, 36, 32, 28),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            colors.light
                ? AdminFigmaAssets.lightLogo
                : AdminFigmaAssets.darkLogo,
            width: 72,
            height: 72,
          ),
          const SizedBox(height: 12),
          Text(
            'لوحة إدارة حاسوبجي',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.secondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          _FigmaActionButton(
            label: data.action,
            colors: colors,
            onTap: () => _showPreviewMessage(context),
            expanded: true,
          ),
          const SizedBox(height: 14),
          const _PreviewNotice(compact: true),
        ],
      ),
    ),
  );
}

class _AdminFigmaPanel extends StatelessWidget {
  const _AdminFigmaPanel({required this.panel, required this.colors});
  final AdminFigmaPanelData panel;
  final _AdminFigmaColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: .96),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(panel.title, style: Theme.of(context).textTheme.titleMedium),
          if (panel.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              panel.description,
              style: TextStyle(color: colors.secondary, fontSize: 12),
            ),
          ],
          if (panel.fields.isNotEmpty) ...[
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 900 ? 2 : 1;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final field in panel.fields)
                      SizedBox(
                        width: columns == 1
                            ? constraints.maxWidth
                            : (constraints.maxWidth - 12) / 2,
                        child: _FigmaField(field: field, colors: colors),
                      ),
                  ],
                );
              },
            ),
          ],
          if (panel.records.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (var i = 0; i < panel.records.length; i++) ...[
              if (i > 0) Divider(height: 1, color: colors.border),
              _RecordTile(record: panel.records[i], colors: colors),
            ],
          ],
          if (panel.chartValues.isNotEmpty) ...[
            const SizedBox(height: 16),
            _FigmaBarChart(values: panel.chartValues, colors: colors),
          ],
          if (panel.note.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              panel.note,
              style: TextStyle(color: colors.secondary, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _FigmaField extends StatelessWidget {
  const _FigmaField({required this.field, required this.colors});
  final AdminFigmaField field;
  final _AdminFigmaColors colors;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        field.label,
        style: TextStyle(color: colors.secondary, fontSize: 12),
      ),
      const SizedBox(height: 6),
      Container(
        constraints: BoxConstraints(minHeight: field.multiline ? 76 : 44),
        alignment: AlignmentDirectional.centerStart,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colors.input,
          border: Border.all(color: colors.border),
        ),
        child: Text(
          field.value.isEmpty ? field.label : field.value,
          maxLines: field.multiline ? 5 : 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: field.value.isEmpty ? colors.muted : colors.ink,
            fontSize: 13,
          ),
        ),
      ),
    ],
  );
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record, required this.colors});
  final AdminFigmaRecord record;
  final _AdminFigmaColors colors;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 640;
      final content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  record.title,
                  style: TextStyle(
                    color: colors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (record.status.isNotEmpty) ...[
                const SizedBox(width: 8),
                _StatusLabel(label: record.status, colors: colors),
              ],
            ],
          ),
          if (record.subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              record.subtitle,
              style: TextStyle(color: colors.secondary, fontSize: 12),
            ),
          ],
          if (record.values.isNotEmpty) ...[
            const SizedBox(height: 7),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final value in record.values)
                  Text(
                    value,
                    style: TextStyle(color: colors.secondary, fontSize: 12),
                  ),
              ],
            ),
          ],
        ],
      );
      return Padding(
        padding: EdgeInsets.symmetric(vertical: compact ? 12 : 10),
        child: compact
            ? content
            : Row(
                children: [
                  Expanded(child: content),
                  if (record.status.isNotEmpty) const SizedBox(width: 12),
                ],
              ),
      );
    },
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric, required this.colors});
  final AdminFigmaMetric metric;
  final _AdminFigmaColors colors;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: colors.surface,
      border: Border.all(color: colors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          metric.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: colors.secondary, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          metric.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colors.ink,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ],
    ),
  );
}

class _FigmaBarChart extends StatelessWidget {
  const _FigmaBarChart({required this.values, required this.colors});
  final List<int> values;
  final _AdminFigmaColors colors;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 145,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < values.length; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height:
                        values[i] /
                        values.reduce((a, b) => a > b ? a : b) *
                        112,
                    decoration: BoxDecoration(
                      color: i == 3 ? colors.chartStrong : colors.chart,
                      border: Border.all(color: colors.border),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    const ['ج', 'خ', 'ر', 'ث', 'ن', 'ح', 'س'][i],
                    style: TextStyle(color: colors.secondary, fontSize: 9),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({
    required this.frame,
    required this.light,
    required this.colors,
    required this.onOpenFrame,
  });
  final AdminFigmaFrame frame;
  final bool light;
  final _AdminFigmaColors colors;
  final OpenAdminFigmaFrame onOpenFrame;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: colors.surface,
      border: Border(
        left: BorderSide(color: colors.border),
        right: BorderSide(color: colors.border),
      ),
    ),
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
    child: Column(
      children: [
        Row(
          children: [
            SvgPicture.asset(
              light ? AdminFigmaAssets.lightLogo : AdminFigmaAssets.darkLogo,
              width: 36,
              height: 36,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'حاسوبجي · الإدارة',
                style: TextStyle(
                  color: colors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Expanded(
          child: _NavigationItems(
            frame: frame,
            light: light,
            colors: colors,
            onOpenFrame: onOpenFrame,
          ),
        ),
      ],
    ),
  );
}

class _AdminNavigationDrawer extends StatelessWidget {
  const _AdminNavigationDrawer({
    required this.frame,
    required this.light,
    required this.onOpenFrame,
  });
  final AdminFigmaFrame frame;
  final bool light;
  final OpenAdminFigmaFrame onOpenFrame;

  @override
  Widget build(BuildContext context) {
    final colors = _AdminFigmaColors(light);
    return Drawer(
      backgroundColor: colors.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  SvgPicture.asset(
                    light
                        ? AdminFigmaAssets.lightLogo
                        : AdminFigmaAssets.darkLogo,
                    width: 36,
                    height: 36,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'حاسوبجي · الإدارة',
                    style: TextStyle(
                      color: colors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: _NavigationItems(
                  frame: frame,
                  light: light,
                  colors: colors,
                  onOpenFrame: onOpenFrame,
                ),
              ),
              const _PreviewNotice(compact: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationItems extends StatelessWidget {
  const _NavigationItems({
    required this.frame,
    required this.light,
    required this.colors,
    required this.onOpenFrame,
  });
  final AdminFigmaFrame frame;
  final bool light;
  final _AdminFigmaColors colors;
  final OpenAdminFigmaFrame onOpenFrame;

  static const items = <(String, String, String)>[
    ('لوحة التحكم', 'M-A02', 'لوحة التحكم للويب'),
    ('الطلاب', 'M-A03', ''),
    ('طلبات الأجهزة', 'M-A04', ''),
    ('الفصول والامتحانات', 'M-B01', ''),
    ('المحتوى', 'M-B02', ''),
    ('الكورسات والمدفوعات', 'M-C01', ''),
    ('الدعم', 'M-D01', ''),
    ('الإعلانات', 'M-D02', ''),
    ('التقارير', 'M-F01', ''),
    ('الإعدادات', 'M-E01', ''),
  ];

  @override
  Widget build(BuildContext context) {
    final icons = light
        ? AdminFigmaAssets.lightNavigation
        : AdminFigmaAssets.darkNavigation;
    return ListView(
      children: [
        for (final item in items)
          Builder(
            builder: (context) {
              final selected = frame.section == _sectionFor(item.$2);
              final unavailable = item.$2 == 'M-A02';
              return InkWell(
                onTap: unavailable
                    ? () => _showPreviewMessage(context, item.$3)
                    : () {
                        final target = AdminFigmaFrame.fromKey(item.$2);
                        if (target != null) onOpenFrame(target, light);
                      },
                child: Container(
                  height: 44,
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  color: selected ? colors.selected : Colors.transparent,
                  child: Row(
                    children: [
                      if (icons[item.$1] case final icon?)
                        SvgPicture.asset(
                          'assets/hasobjy/admin/$icon.svg',
                          width: 22,
                          height: 22,
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.$1,
                          style: TextStyle(
                            color: unavailable
                                ? colors.muted
                                : selected
                                ? colors.brand
                                : colors.secondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  String _sectionFor(String key) => switch (key) {
    'M-A03' || 'M-A04' => 'الطلاب والأجهزة',
    'M-B01' || 'M-B02' => 'الفصول والمحتوى',
    'M-C01' => 'الكورسات والمدفوعات',
    'M-D01' || 'M-D02' => 'التواصل',
    'M-F01' => 'التقارير والتدقيق',
    'M-E01' => 'الإدارة',
    _ => '',
  };
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.colors,
    required this.onTap,
  });
  final String label;
  final _AdminFigmaColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
      ),
      child: Text(
        label,
        style: TextStyle(color: colors.secondary, fontSize: 12),
      ),
    ),
  );
}

class _FigmaActionButton extends StatelessWidget {
  const _FigmaActionButton({
    required this.label,
    required this.colors,
    required this.onTap,
    this.expanded = false,
  });
  final String label;
  final _AdminFigmaColors colors;
  final VoidCallback onTap;
  final bool expanded;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: expanded ? double.infinity : null,
    height: 42,
    child: Material(
      color: colors.action,
      child: InkWell(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(border: Border.all(color: colors.brand)),
          child: Text(
            label,
            style: TextStyle(
              color: colors.buttonText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ),
  );
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.label, required this.colors});
  final String label;
  final _AdminFigmaColors colors;

  @override
  Widget build(BuildContext context) {
    final warning =
        label.contains('مراجعة') ||
        label.contains('انتظار') ||
        label.contains('قادم') ||
        label.contains('ناقص');
    final danger =
        label.contains('راسب') ||
        label.contains('مرفوض') ||
        label.contains('فشل');
    final background = danger
        ? colors.dangerBg
        : warning
        ? colors.warningBg
        : colors.successBg;
    final foreground = danger
        ? colors.danger
        : warning
        ? colors.warning
        : colors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: foreground.withValues(alpha: .25)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: foreground, fontSize: 10),
      ),
    );
  }
}

class _PreviewBadge extends StatelessWidget {
  const _PreviewBadge({required this.colors});
  final _AdminFigmaColors colors;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: colors.warningBg,
      border: Border.all(color: colors.warning),
    ),
    child: Text(
      'معاينة',
      style: TextStyle(color: colors.warning, fontSize: 10),
    ),
  );
}

class _PreviewNotice extends StatelessWidget {
  const _PreviewNotice({this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: compact ? 8 : 12,
      vertical: compact ? 6 : 10,
    ),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.tertiaryContainer
          .withValues(alpha: .72),
      border: Border.all(
        color: Theme.of(context).colorScheme.tertiary.withValues(alpha: .5),
      ),
    ),
    child: Text(
      compact
          ? 'معاينة تطوير · لا يوجد اتصال بالخادم'
          : 'بيانات Figma للمعاينة فقط · لا توجد عمليات خادمية متصلة',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onTertiaryContainer,
        fontSize: compact ? 10 : 12,
      ),
    ),
  );
}

class _AdminFigmaColors {
  const _AdminFigmaColors(this.light);
  final bool light;

  Color get background =>
      light ? const Color(0xFFF4FBFF) : const Color(0xFF02112C);
  Color get surface =>
      light ? const Color(0xFFFFFFFF) : const Color(0xFF06224D);
  Color get input => light ? const Color(0xFFF4FBFF) : const Color(0xFF011755);
  Color get ink => light ? const Color(0xFF02112C) : const Color(0xFFFFFFFF);
  Color get secondary =>
      light ? const Color(0xFF3D5A78) : const Color(0xFFD9F1FD);
  Color get muted => light ? const Color(0xFF587A9C) : const Color(0xFF9FC4E6);
  Color get border => light ? const Color(0xFFC5DFF0) : const Color(0xFF1B3F73);
  Color get brand => light ? const Color(0xFF0578B7) : const Color(0xFF67A8DC);
  Color get action => light ? const Color(0xFF011755) : const Color(0xFF0578B7);
  Color get buttonText => Colors.white;
  Color get selected =>
      light ? const Color(0xFFD9F1FD) : const Color(0xFF1B3F73);
  Color get success => const Color(0xFF12713F);
  Color get successBg => const Color(0xFFE8F8EF);
  Color get warning => const Color(0xFF8C5E10);
  Color get warningBg => const Color(0xFFFDF4E1);
  Color get danger => const Color(0xFFA32A2E);
  Color get dangerBg => const Color(0xFFFDECEC);
  Color get chart => light ? const Color(0xFFB5E3F8) : const Color(0xFF1B3F73);
  Color get chartStrong =>
      light ? const Color(0xFF0578B7) : const Color(0xFF67A8DC);
}

ThemeData _adminTheme(_AdminFigmaColors colors) {
  final brightness = colors.light ? Brightness.light : Brightness.dark;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: 'Cairo',
    scaffoldBackgroundColor: colors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: colors.brand,
      brightness: brightness,
      primary: colors.brand,
      onPrimary: Colors.white,
      surface: colors.surface,
      onSurface: colors.ink,
      tertiary: colors.warning,
      tertiaryContainer: colors.warningBg,
      onTertiaryContainer: colors.warning,
    ),
    appBarTheme: AppBarTheme(
      foregroundColor: colors.ink,
      backgroundColor: colors.surface,
    ),
    textTheme: ThemeData(
      brightness: brightness,
      fontFamily: 'Cairo',
    ).textTheme.apply(bodyColor: colors.ink, displayColor: colors.ink),
  );
}

void _showPreviewMessage(BuildContext context, [String? message]) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message ?? 'معاينة فقط: لا يوجد Backend متصل.')),
    );
}

const _sections = <String>[
  'الحساب',
  'الطلاب والأجهزة',
  'الفصول والمحتوى',
  'الكورسات والمدفوعات',
  'التواصل',
  'التقارير والتدقيق',
  'الإدارة',
];
