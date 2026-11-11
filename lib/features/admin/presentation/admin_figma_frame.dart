/// Actual administrative frames exposed by the current Figma file.
/// Dashboard frames are intentionally omitted from this Flutter preview.
final class AdminFigmaFrame {
  const AdminFigmaFrame({
    required this.key,
    required this.title,
    required this.pageId,
    required this.darkNodeId,
    required this.lightNodeId,
    required this.section,
  });

  final String key;
  final String title;
  final String pageId;
  final String darkNodeId;
  final String lightNodeId;
  final String section;

  String nodeId({required bool light}) => light ? lightNodeId : darkNodeId;
  String get routeName => key;

  static const all = <AdminFigmaFrame>[
    AdminFigmaFrame(
      key: 'M-A01',
      title: 'دخول الإدارة',
      pageId: '1:6',
      darkNodeId: '96:2',
      lightNodeId: '103:5011',
      section: 'الحساب',
    ),
    AdminFigmaFrame(
      key: 'M-A03',
      title: 'الطلاب',
      pageId: '1:6',
      darkNodeId: '96:199',
      lightNodeId: '103:5108',
      section: 'الطلاب والأجهزة',
    ),
    AdminFigmaFrame(
      key: 'M-A04',
      title: 'طلبات الأجهزة',
      pageId: '1:6',
      darkNodeId: '96:334',
      lightNodeId: '103:5201',
      section: 'الطلاب والأجهزة',
    ),
    AdminFigmaFrame(
      key: 'M-B01',
      title: 'الفصول والامتحانات',
      pageId: '1:6',
      darkNodeId: '96:483',
      lightNodeId: '103:5287',
      section: 'الفصول والمحتوى',
    ),
    AdminFigmaFrame(
      key: 'M-A05',
      title: 'تفاصيل الطالب',
      pageId: '1:6',
      darkNodeId: '102:214',
      lightNodeId: '103:5370',
      section: 'الطلاب والأجهزة',
    ),
    AdminFigmaFrame(
      key: 'M-B02',
      title: 'المحتوى',
      pageId: '1:6',
      darkNodeId: '102:361',
      lightNodeId: '103:5465',
      section: 'الفصول والمحتوى',
    ),
    AdminFigmaFrame(
      key: 'M-B03',
      title: 'النتائج وعلامة النجاح',
      pageId: '1:6',
      darkNodeId: '102:524',
      lightNodeId: '103:5552',
      section: 'الفصول والمحتوى',
    ),
    AdminFigmaFrame(
      key: 'M-C01',
      title: 'الكورسات',
      pageId: '1:6',
      darkNodeId: '102:634',
      lightNodeId: '103:5622',
      section: 'الكورسات والمدفوعات',
    ),
    AdminFigmaFrame(
      key: 'M-C02',
      title: 'المدفوعات والقسائم',
      pageId: '1:6',
      darkNodeId: '103:418',
      lightNodeId: '103:5711',
      section: 'الكورسات والمدفوعات',
    ),
    AdminFigmaFrame(
      key: 'M-D01',
      title: 'الدعم',
      pageId: '1:6',
      darkNodeId: '103:569',
      lightNodeId: '103:5786',
      section: 'التواصل',
    ),
    AdminFigmaFrame(
      key: 'M-D02',
      title: 'الإعلانات',
      pageId: '1:6',
      darkNodeId: '103:690',
      lightNodeId: '103:5854',
      section: 'التواصل',
    ),
    AdminFigmaFrame(
      key: 'M-E01',
      title: 'الإعدادات',
      pageId: '1:6',
      darkNodeId: '103:803',
      lightNodeId: '103:5912',
      section: 'الإدارة',
    ),
    AdminFigmaFrame(
      key: 'M-B04',
      title: 'دروس المادة',
      pageId: '202:171',
      darkNodeId: '202:1225',
      lightNodeId: '202:1571',
      section: 'الفصول والمحتوى',
    ),
    AdminFigmaFrame(
      key: 'M-B05',
      title: 'تعديل درس',
      pageId: '202:171',
      darkNodeId: '203:1316',
      lightNodeId: '203:1573',
      section: 'الفصول والمحتوى',
    ),
    AdminFigmaFrame(
      key: 'M-B06',
      title: 'بنك الأسئلة',
      pageId: '202:171',
      darkNodeId: '203:1830',
      lightNodeId: '203:2208',
      section: 'الفصول والمحتوى',
    ),
    AdminFigmaFrame(
      key: 'M-B07',
      title: 'سؤال برمجي وتجربة Gemini',
      pageId: '202:171',
      darkNodeId: '203:2586',
      lightNodeId: '203:2802',
      section: 'الفصول والمحتوى',
    ),
    AdminFigmaFrame(
      key: 'M-B08',
      title: 'الأقسام والمواد',
      pageId: '202:171',
      darkNodeId: '204:1558',
      lightNodeId: '204:1896',
      section: 'الفصول والمحتوى',
    ),
    AdminFigmaFrame(
      key: 'M-B09',
      title: 'رفع ملف العلامات',
      pageId: '202:171',
      darkNodeId: '204:2234',
      lightNodeId: '204:2510',
      section: 'الفصول والمحتوى',
    ),
    AdminFigmaFrame(
      key: 'M-B10',
      title: 'إغلاق الفصل',
      pageId: '202:171',
      darkNodeId: '204:2786',
      lightNodeId: '204:3034',
      section: 'الفصول والمحتوى',
    ),
    AdminFigmaFrame(
      key: 'M-C03',
      title: 'خطط الاشتراك والأسعار',
      pageId: '202:172',
      darkNodeId: '205:1808',
      lightNodeId: '205:2135',
      section: 'الكورسات والمدفوعات',
    ),
    AdminFigmaFrame(
      key: 'M-C04',
      title: 'الاشتراكات',
      pageId: '202:172',
      darkNodeId: '205:2462',
      lightNodeId: '205:2794',
      section: 'الكورسات والمدفوعات',
    ),
    AdminFigmaFrame(
      key: 'M-C05',
      title: 'سجل المدفوعات',
      pageId: '202:172',
      darkNodeId: '205:3126',
      lightNodeId: '205:3456',
      section: 'الكورسات والمدفوعات',
    ),
    AdminFigmaFrame(
      key: 'M-C06',
      title: 'دفعات القسائم',
      pageId: '202:172',
      darkNodeId: '205:3786',
      lightNodeId: '205:4107',
      section: 'الكورسات والمدفوعات',
    ),
    AdminFigmaFrame(
      key: 'M-C07',
      title: 'محتوى الكورس',
      pageId: '202:172',
      darkNodeId: '205:4428',
      lightNodeId: '205:4753',
      section: 'الكورسات والمدفوعات',
    ),
    AdminFigmaFrame(
      key: 'M-D03',
      title: 'محادثة الدعم',
      pageId: '202:173',
      darkNodeId: '208:1222',
      lightNodeId: '208:1437',
      section: 'التواصل',
    ),
    AdminFigmaFrame(
      key: 'M-D04',
      title: 'قوالب الإشعارات',
      pageId: '202:173',
      darkNodeId: '208:1652',
      lightNodeId: '208:1906',
      section: 'التواصل',
    ),
    AdminFigmaFrame(
      key: 'M-F01',
      title: 'التقارير',
      pageId: '202:173',
      darkNodeId: '208:2160',
      lightNodeId: '208:2417',
      section: 'التقارير والتدقيق',
    ),
    AdminFigmaFrame(
      key: 'M-F02',
      title: 'سجل عمليات الإدارة',
      pageId: '202:173',
      darkNodeId: '208:2674',
      lightNodeId: '208:2960',
      section: 'التقارير والتدقيق',
    ),
    AdminFigmaFrame(
      key: 'M-A06',
      title: 'نشاط الطالب',
      pageId: '202:173',
      darkNodeId: '208:3246',
      lightNodeId: '208:3517',
      section: 'الطلاب والأجهزة',
    ),
    AdminFigmaFrame(
      key: 'M-E02',
      title: 'إضافة مسؤول',
      pageId: '202:173',
      darkNodeId: '208:4254',
      lightNodeId: '208:4475',
      section: 'الإدارة',
    ),
  ];

  static AdminFigmaFrame? fromKey(String key) {
    for (final frame in all) {
      if (frame.key == key) return frame;
    }
    return null;
  }
}

abstract final class AdminFigmaAssets {
  static const darkBackground = 'assets/hasobjy/admin/ba830.svg';
  static const lightBackground = 'assets/hasobjy/admin/e67ae.svg';
  static const darkLogo = 'assets/hasobjy/902ed.svg';
  static const lightLogo = 'assets/hasobjy/admin/77701.svg';

  static const darkNavigation = <String, String>{
    'لوحة التحكم': 'cba16',
    'الطلاب': 'cc25a',
    'طلبات الأجهزة': '68169',
    'الفصول والامتحانات': '25eff',
    'المحتوى': '5238a',
    'الكورسات والمدفوعات': '0583d',
    'الدعم': '0ebba',
    'الإعلانات': 'b15c8',
    'التقارير': '666be',
    'الإعدادات': 'ba0b6',
  };

  static const lightNavigation = <String, String>{
    'لوحة التحكم': '03c2c',
    'الطلاب': '04c03',
    'طلبات الأجهزة': '351f5',
    'الفصول والامتحانات': 'b4228',
    'المحتوى': 'ce630',
    'الكورسات والمدفوعات': '45232',
    'الدعم': 'b4b3f',
    'الإعلانات': 'e643d',
    'التقارير': '1a5c8',
    'الإعدادات': '5286a',
  };
}
