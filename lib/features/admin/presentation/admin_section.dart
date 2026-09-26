import 'package:flutter/material.dart';

enum AdminSection {
  overview('الرئيسية', Icons.dashboard_outlined, Icons.dashboard_rounded),
  content('المحتوى', Icons.library_books_outlined, Icons.library_books_rounded),
  students('الطلاب', Icons.people_outline_rounded, Icons.people_rounded),
  requests(
    'الطلبات',
    Icons.phonelink_setup_outlined,
    Icons.phonelink_setup_rounded,
  ),
  audit('السجل', Icons.history_outlined, Icons.history_rounded),
  settings('الإعدادات', Icons.settings_outlined, Icons.settings_rounded),
  more('المزيد', Icons.grid_view_outlined, Icons.grid_view_rounded);

  const AdminSection(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
