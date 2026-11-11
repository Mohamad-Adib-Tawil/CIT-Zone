final class AdminFigmaMetric {
  const AdminFigmaMetric(this.label, this.value);
  final String label;
  final String value;
}

final class AdminFigmaField {
  const AdminFigmaField(this.label, this.value, {this.multiline = false});
  final String label;
  final String value;
  final bool multiline;
}

final class AdminFigmaRecord {
  const AdminFigmaRecord(
    this.title, {
    this.subtitle = '',
    this.values = const [],
    this.status = '',
  });
  final String title;
  final String subtitle;
  final List<String> values;
  final String status;
}

final class AdminFigmaPanelData {
  const AdminFigmaPanelData(
    this.title, {
    this.description = '',
    this.fields = const [],
    this.records = const [],
    this.note = '',
    this.chartValues = const [],
  });
  final String title;
  final String description;
  final List<AdminFigmaField> fields;
  final List<AdminFigmaRecord> records;
  final String note;
  final List<int> chartValues;
}

final class AdminFigmaScreenData {
  const AdminFigmaScreenData({
    this.subtitle = '',
    this.action = '',
    this.metrics = const [],
    this.filters = const [],
    this.panels = const [],
  });
  final String subtitle;
  final String action;
  final List<AdminFigmaMetric> metrics;
  final List<String> filters;
  final List<AdminFigmaPanelData> panels;
}

/// Demo values below are transcribed from the Figma frame context and remain
/// development-only. They are never loaded from or written to a service.
abstract final class AdminFigmaScreenCatalog {
  static const data = <String, AdminFigmaScreenData>{
    'M-A01': AdminFigmaScreenData(
      subtitle: 'سجّل الدخول بحساب Google المصرّح له من الإدارة.',
      action: 'المتابعة عبر Google',
    ),
    'M-A03': AdminFigmaScreenData(
      subtitle: 'إدارة حسابات طلاب المعهد',
      action: 'إضافة طالب',
      filters: ['الحالة: الكل', 'السنة: الكل', 'القسم: الكل'],
      panels: [
        AdminFigmaPanelData(
          'الطلاب',
          records: [
            AdminFigmaRecord(
              'أحمد محمد الحلبي',
              subtitle: 'برمجيات · الثانية · الفصل الثالث',
              values: ['Samsung A54'],
              status: 'نشط',
            ),
            AdminFigmaRecord(
              'ريم خالد العلي',
              subtitle: 'شبكات · الأولى · الفصل الأول',
              values: ['Redmi Note 11'],
              status: 'نشط',
            ),
            AdminFigmaRecord(
              'عمر شيخو',
              subtitle: 'برمجيات · الثانية · الفصل الثالث',
              values: ['iPhone 13'],
              status: 'نشط',
            ),
          ],
        ),
      ],
    ),
    'M-A04': AdminFigmaScreenData(
      subtitle: 'راجع الطلبات واعتمد الجهاز الجديد',
      panels: [
        AdminFigmaPanelData(
          'طلبات تغيير الجهاز',
          records: [
            AdminFigmaRecord(
              'أحمد الحلبي',
              subtitle: 'تغيّر الهاتف · اليوم',
              values: ['Samsung A54', 'Samsung S23'],
              status: 'قيد المراجعة',
            ),
            AdminFigmaRecord(
              'ريم العلي',
              subtitle: 'فُقد الجهاز · أمس',
              values: ['Redmi Note 11', 'Pixel 7'],
              status: 'قيد المراجعة',
            ),
          ],
        ),
      ],
    ),
    'M-B01': AdminFigmaScreenData(
      subtitle: 'التقويم الأكاديمي وجداول الامتحانات',
      action: 'إضافة فصل',
      panels: [
        AdminFigmaPanelData(
          'الفصول',
          records: [
            AdminFigmaRecord(
              'الفصل الثاني',
              subtitle: '2025/2026 · منتهٍ',
              status: 'مغلق',
            ),
            AdminFigmaRecord(
              'الفصل الثالث',
              subtitle: '2026/2027 · حتى 1 يونيو',
              status: 'جارٍ',
            ),
            AdminFigmaRecord(
              'الفصل الرابع',
              subtitle: 'يبدأ 1 فبراير 2027',
              status: 'قادم',
            ),
          ],
        ),
        AdminFigmaPanelData(
          'جدول الامتحانات · الدورة العادية',
          records: [
            AdminFigmaRecord(
              'البرمجة الكائنية',
              subtitle: 'نظري · الأحد 7 يونيو · 09:00',
              values: ['القاعة 3'],
            ),
            AdminFigmaRecord(
              'قواعد البيانات',
              subtitle: 'عملي · الخميس 11 يونيو · 11:00',
              values: ['المخبر 1'],
            ),
          ],
        ),
      ],
    ),
    'M-A05': AdminFigmaScreenData(
      subtitle: 'الطلاب › أحمد الحلبي › تفاصيل الطالب',
      action: 'إيقاف الحساب',
      panels: [
        AdminFigmaPanelData(
          'أحمد محمد الحلبي',
          description: 'برمجيات · السنة الثانية · الفصل الثالث',
          fields: [
            AdminFigmaField('البريد', 'ahmad@gmail.com'),
            AdminFigmaField('الهاتف', '+963 944 000 000'),
            AdminFigmaField('تاريخ التسجيل', '12 سبتمبر 2026'),
            AdminFigmaField('الحالة', 'نشط'),
          ],
        ),
        AdminFigmaPanelData(
          'الجهاز المسجّل',
          fields: [
            AdminFigmaField('الجهاز', 'Samsung A54'),
            AdminFigmaField('نظام التشغيل', 'Android 14'),
            AdminFigmaField('آخر دخول', 'اليوم 09:12'),
            AdminFigmaField('طلبات التغيير', '1 قيد المراجعة'),
          ],
          note: 'إعادة تعيين الجهاز',
        ),
        AdminFigmaPanelData(
          'علامات الفصل الحالي',
          records: [
            AdminFigmaRecord(
              'البرمجة الكائنية',
              values: ['المجموع 68', 'العملي 18'],
              status: 'ناجح',
            ),
            AdminFigmaRecord(
              'قواعد البيانات',
              values: ['المجموع 61', 'العملي 40'],
              status: 'قيد المراجعة',
            ),
          ],
        ),
      ],
    ),
    'M-B02': AdminFigmaScreenData(
      subtitle: 'فيديوهات وملفات PDF وتمارين كل مادة',
      action: 'إضافة مادة',
      filters: ['القسم: الكل', 'السنة: الكل', 'الحالة: الكل'],
      panels: [
        AdminFigmaPanelData(
          'المواد والمحتوى',
          records: [
            AdminFigmaRecord(
              'البرمجة الكائنية',
              subtitle: 'برمجيات · السنة الثانية',
              values: ['فيديو 14', 'PDF 6', 'تمارين 22'],
              status: 'منشورة',
            ),
            AdminFigmaRecord(
              'قواعد البيانات',
              subtitle: 'برمجيات · السنة الثانية',
              values: ['فيديو 11', 'PDF 5', 'تمارين 18'],
              status: 'منشورة',
            ),
          ],
        ),
      ],
    ),
    'M-B03': AdminFigmaScreenData(
      subtitle: 'حدّد علامة النجاح لكل مادة وانشر النتائج',
      action: 'نشر النتائج',
      metrics: [
        AdminFigmaMetric('ناجحون', '212'),
        AdminFigmaMetric('راسبون', '18'),
        AdminFigmaMetric('متوسط', '68'),
      ],
      panels: [
        AdminFigmaPanelData(
          'النتائج وعلامة النجاح',
          records: [
            AdminFigmaRecord(
              'البرمجة الكائنية',
              values: ['علامة النجاح 50', 'متوسط 68', 'ناجحون 212'],
              status: 'منشورة',
            ),
            AdminFigmaRecord(
              'قواعد البيانات',
              values: ['علامة النجاح 60', 'متوسط 61', 'ناجحون 190'],
              status: 'قيد المراجعة',
            ),
            AdminFigmaRecord(
              'هندسة البرمجيات',
              values: ['علامة النجاح —'],
              status: 'لم تُرفع',
            ),
          ],
        ),
      ],
    ),
    'M-C01': AdminFigmaScreenData(
      subtitle: 'صلاحية كل كورس سنة واحدة من تاريخ التفعيل',
      action: 'كورس جديد',
      metrics: [
        AdminFigmaMetric('كورسات منشورة', '12'),
        AdminFigmaMetric('اشتراكات فعّالة', '386'),
        AdminFigmaMetric('إيرادات الشهر', r'$2,430'),
      ],
      panels: [
        AdminFigmaPanelData(
          'الكورسات والأسعار',
          records: [
            AdminFigmaRecord(
              'تطوير تطبيقات Flutter',
              values: [r'$29', '142 مشتركاً', 'سنة'],
              status: 'منشور',
            ),
            AdminFigmaRecord(
              'React للمبتدئين',
              values: [r'$19', '87 مشتركاً', 'سنة'],
              status: 'منشور',
            ),
          ],
        ),
      ],
    ),
    'M-C02': AdminFigmaScreenData(
      subtitle: 'طلبات ShamCash وقسائم الشحن',
      action: 'توليد قسائم',
      panels: [
        AdminFigmaPanelData(
          'طلبات ShamCash بانتظار التأكيد',
          records: [
            AdminFigmaRecord(
              'ريم العلي',
              subtitle: 'Flutter · SC-77412',
              values: [r'$29'],
              status: 'بانتظار التأكيد',
            ),
            AdminFigmaRecord(
              'عمر شيخو',
              subtitle: 'React · SC-77398',
              values: [r'$19'],
              status: 'بانتظار التأكيد',
            ),
          ],
        ),
      ],
    ),
    'M-D01': AdminFigmaScreenData(
      subtitle: 'تذاكر الطلاب والرد عليها',
      panels: [
        AdminFigmaPanelData(
          'تذاكر الدعم',
          records: [
            AdminFigmaRecord(
              'أحمد الحلبي',
              subtitle: 'لا أستطيع تشغيل الدرس 4 · اليوم',
              status: 'قيد المعالجة',
            ),
            AdminFigmaRecord(
              'ريم العلي',
              subtitle: 'مشكلة في الدفع بالقسيمة · أمس',
              status: 'جديدة',
            ),
            AdminFigmaRecord(
              'محمود ديب',
              subtitle: 'تعديل بيانات الملف الشخصي · قبل يومين',
              status: 'مغلقة',
            ),
          ],
        ),
      ],
    ),
    'M-D02': AdminFigmaScreenData(
      subtitle: 'أرسل إشعاراً لكل الطلاب أو لقسم محدد',
      action: 'إرسال الإشعار',
      panels: [
        AdminFigmaPanelData(
          'إشعار جديد',
          fields: [
            AdminFigmaField('عنوان الإشعار', 'مثال: تحديث جدول الامتحانات'),
            AdminFigmaField('نص الإشعار', 'اكتب نص الإشعار', multiline: true),
            AdminFigmaField('المستهدفون', 'كل الطلاب'),
          ],
        ),
        AdminFigmaPanelData(
          'آخر الإشعارات المرسلة',
          records: [
            AdminFigmaRecord(
              'تحديث جدول الامتحانات',
              subtitle: 'كل الطلاب · اليوم',
              values: ['1,248 مستلماً'],
            ),
            AdminFigmaRecord(
              'كورس Flutter الجديد',
              subtitle: 'كل الطلاب · قبل 3 أيام',
              values: ['1,240 مستلماً'],
            ),
          ],
        ),
      ],
    ),
    'M-E01': AdminFigmaScreenData(
      subtitle: 'قواعد التطبيق والإدارة',
      panels: [
        AdminFigmaPanelData(
          'إعدادات النظام',
          fields: [
            AdminFigmaField('علامة النجاح الافتراضية', '50'),
            AdminFigmaField('صلاحية الكورس', 'سنة واحدة'),
            AdminFigmaField('عملة المدفوعات', 'USD'),
            AdminFigmaField('قفل الجهاز الواحد (طلاب المعهد)', 'مفعّل'),
          ],
        ),
        AdminFigmaPanelData(
          'مسؤولو الإدارة',
          records: [
            AdminFigmaRecord(
              'محمد مخملجي',
              subtitle: 'info@devmmnd.com',
              values: ['مدير عام'],
              status: 'نشط',
            ),
            AdminFigmaRecord(
              'مشرف المحتوى',
              subtitle: 'content@devmmnd.com',
              values: ['مشرف'],
              status: 'نشط',
            ),
          ],
        ),
      ],
    ),
    'M-B04': AdminFigmaScreenData(
      subtitle: 'المحتوى › البرمجة الكائنية · الفصل الثالث',
      action: 'إضافة درس',
      metrics: [
        AdminFigmaMetric('الدروس', '14'),
        AdminFigmaMetric('منشورة', '12'),
        AdminFigmaMetric('إجمالي المدة', '9 س 40 د'),
        AdminFigmaMetric('متوسط التقييم', '4.6 / 5'),
      ],
      panels: [
        AdminFigmaPanelData(
          'دروس مادة البرمجة الكائنية',
          records: [
            AdminFigmaRecord(
              'مقدمة في البرمجة الكائنية',
              values: ['42 د', '4.8 / 5', 'مجاني'],
              status: 'منشور',
            ),
            AdminFigmaRecord(
              'الأصناف والكائنات',
              values: ['58 د', '4.7 / 5'],
              status: 'منشور',
            ),
            AdminFigmaRecord(
              'تعدد الأشكال',
              values: ['36 د', 'فيديو جاهز'],
              status: 'منشور',
            ),
          ],
        ),
      ],
    ),
    'M-B05': AdminFigmaScreenData(
      subtitle: 'المحتوى › البرمجة الكائنية › الدروس › تعدد الأشكال',
      action: 'حفظ كمسودة',
      panels: [
        AdminFigmaPanelData(
          'بيانات الدرس',
          fields: [
            AdminFigmaField('عنوان الدرس', 'تعدد الأشكال'),
            AdminFigmaField(
              'وصف الدرس',
              'يشرح الدرس مفهوم تعدد الأشكال في البرمجة الكائنية مع أمثلة عملية على الإلغاء والتحميل الزائد.',
              multiline: true,
            ),
          ],
        ),
        AdminFigmaPanelData(
          'الفيديو',
          description: 'MP4 · حتى 2 GB · يُشفَّر تلقائياً بنظام DRM',
          records: [
            AdminFigmaRecord(
              'polymorphism.mp4',
              subtitle: '412 MB · رفع الملف 68%',
              status: 'جارٍ',
            ),
            AdminFigmaRecord('التشفير بنظام DRM', status: 'بانتظار'),
            AdminFigmaRecord('جاهز للنشر', status: 'بانتظار'),
          ],
        ),
        AdminFigmaPanelData(
          'ملفات PDF المرتبطة بالدرس',
          records: [
            AdminFigmaRecord('أمثلة تعدد الأشكال (PDF)', subtitle: '640 KB'),
          ],
        ),
      ],
    ),
    'M-B06': AdminFigmaScreenData(
      subtitle: 'تمارين وأسئلة كل مادة · اختيار متعدد وأسئلة كود',
      action: 'سؤال جديد',
      filters: [
        'المادة: البرمجة الكائنية',
        'النوع: الكل',
        'الدرس: الكل',
        'الصعوبة: الكل',
      ],
      metrics: [
        AdminFigmaMetric('إجمالي الأسئلة', '86'),
        AdminFigmaMetric('اختيار متعدد', '54'),
        AdminFigmaMetric('أسئلة كود (Gemini)', '32'),
        AdminFigmaMetric('متوسط النجاح', '71%'),
      ],
      panels: [
        AdminFigmaPanelData(
          'بنك الأسئلة',
          records: [
            AdminFigmaRecord(
              'ما نتيجة استدعاء الدالة؟',
              subtitle: 'اختيار متعدد · مقدمة في البرمجة · متوسط',
              values: ['74% نجاح'],
              status: 'منشور',
            ),
            AdminFigmaRecord(
              'أنشئ صنف Student مع التغليف',
              subtitle: 'كود · تعدد الأشكال · متوسط',
              values: ['63% نجاح'],
              status: 'منشور',
            ),
          ],
        ),
      ],
    ),
    'M-B07': AdminFigmaScreenData(
      subtitle: 'بنك الأسئلة › البرمجة الكائنية › سؤال 3',
      action: 'حفظ السؤال',
      panels: [
        AdminFigmaPanelData(
          'نص السؤال والتصحيح',
          fields: [
            AdminFigmaField('نوع السؤال', 'كود (يصحّحه Gemini)'),
            AdminFigmaField('الصعوبة', 'متوسط'),
            AdminFigmaField('الدرجة', '10'),
            AdminFigmaField(
              'نص السؤال',
              'اكتب صنفاً Student يحتوي الخاصية name مع التغليف (private) ودالة getName ثم أنشئ كائناً واطبع اسمه.',
              multiline: true,
            ),
            AdminFigmaField(
              'الإجابة النموذجية',
              'تعريف الصنف واستخدام التغليف ودالة getName وإنشاء كائن وطباعة اسمه.',
              multiline: true,
            ),
            AdminFigmaField(
              'معايير التصحيح',
              'تعريف الصنف بشكل صحيح · استخدام التغليف · دالة getName تعمل · إنشاء كائن وطباعة اسمه',
              multiline: true,
            ),
          ],
        ),
        AdminFigmaPanelData(
          'تجربة التصحيح بـ Gemini',
          fields: [
            AdminFigmaField(
              'إجابة تجريبية من طالب',
              'class Student { public String name; }',
              multiline: true,
            ),
          ],
          note: 'يُرسل الكود إلى Gemini دون حفظه كإجابة فعلية',
        ),
      ],
    ),
    'M-B08': AdminFigmaScreenData(
      subtitle: 'المحتوى › الهيكل الأكاديمي · ربط المواد بالأقسام',
      action: 'إضافة قسم',
      metrics: [
        AdminFigmaMetric('مواد مشتركة', '10'),
        AdminFigmaMetric('إجمالي المواد', '28'),
      ],
      panels: [
        AdminFigmaPanelData(
          'الأقسام',
          records: [
            AdminFigmaRecord('قسم الشبكات', values: ['19 مادة']),
            AdminFigmaRecord('قسم البرمجيات', values: ['19 مادة']),
          ],
        ),
        AdminFigmaPanelData(
          'المواد والمواضع',
          records: [
            AdminFigmaRecord(
              'مبادئ البرمجة',
              subtitle: 'الأولى · الأول',
              values: ['نظري / عملي 70 / 30', 'علامة النجاح 50'],
              status: 'شبكات · برمجيات',
            ),
            AdminFigmaRecord(
              'قواعد البيانات',
              subtitle: 'الثانية · الأول',
              values: ['نظري / عملي 60 / 40', 'علامة النجاح 60'],
              status: 'برمجيات',
            ),
          ],
        ),
      ],
    ),
    'M-B09': AdminFigmaScreenData(
      subtitle: 'النتائج › استيراد علامات الجامعة · الفصل الثالث',
      action: 'اعتماد ونشر',
      panels: [
        AdminFigmaPanelData(
          'مراحل الاستيراد',
          fields: [
            AdminFigmaField('1 · رفع الملف', '✓'),
            AdminFigmaField('2 · مراجعة المطابقة', '3'),
            AdminFigmaField('3 · النشر', 'بانتظار المراجعة'),
          ],
        ),
        AdminFigmaPanelData(
          'grades_term3.xlsx',
          description: '214 KB · رُفع اليوم 09:30 · 7 مواد',
        ),
        AdminFigmaPanelData(
          'ملخص الملف',
          records: [
            AdminFigmaRecord('الأسطر في الملف', values: ['215']),
            AdminFigmaRecord('مطابقة بنجاح', values: ['212']),
            AdminFigmaRecord('تحتاج مراجعة', values: ['3']),
            AdminFigmaRecord('مواد في الملف', values: ['7']),
          ],
        ),
        AdminFigmaPanelData(
          'الأسطر التي تحتاج مراجعة',
          records: [
            AdminFigmaRecord(
              'أحمد م. الحلبي',
              subtitle: 'قواعد البيانات',
              values: ['نظري 52', 'عملي 33'],
              status: 'الاسم يحتاج مطابقة',
            ),
            AdminFigmaRecord(
              'ريم العلي',
              subtitle: 'هندسة البرمجيات',
              values: ['نظري 44', 'عملي —'],
              status: 'علامة العملي مفقودة',
            ),
          ],
        ),
      ],
    ),
    'M-B10': AdminFigmaScreenData(
      subtitle: 'الفصول والامتحانات › إغلاق الفصل ونقل الطلاب',
      action: 'إغلاق الفصل',
      metrics: [
        AdminFigmaMetric('طلاب سيُنقلون للفصل الرابع', '1,196'),
        AdminFigmaMetric('مواد راسبة تبقى مفتوحة', '41'),
        AdminFigmaMetric('اشتراكات ستنتهي', '812'),
        AdminFigmaMetric('إشعارات ستُرسل', '1,248'),
      ],
      panels: [
        AdminFigmaPanelData(
          'ما الذي سيحدث عند الإغلاق',
          records: [
            AdminFigmaRecord(
              'الوصول للمواد المدفوعة الخاصة بهذا الفصل سيُغلق.',
            ),
            AdminFigmaRecord(
              'تبقى المواد الراسبة أو المحمّلة مفتوحة للمراجعة.',
            ),
            AdminFigmaRecord('يُسجَّل الطلاب تلقائياً على الفصل الرابع.'),
            AdminFigmaRecord(
              'يُرسَل إشعار تذكير للطلاب الذين لديهم مواد راسبة.',
            ),
            AdminFigmaRecord('يُفعَّل زر «طباعة كشف علاماتي» لكل الطلاب.'),
          ],
        ),
        AdminFigmaPanelData(
          'قائمة التحقق قبل الإغلاق',
          records: [
            AdminFigmaRecord('نشر نتائج جميع المواد', status: 'مكتمل'),
            AdminFigmaRecord(
              'مراجعة أسطر العلامات المرفوضة (3)',
              status: 'ناقص',
            ),
          ],
          note: 'تاريخ بدء الفصل الرابع · 1 فبراير 2027',
        ),
      ],
    ),
    'M-C03': AdminFigmaScreenData(
      subtitle: 'الكورسات والمدفوعات › الخطط · الأسعار بالدولار الأمريكي',
      action: 'خطة جديدة',
      metrics: [
        AdminFigmaMetric('خطط فعّالة', '6'),
        AdminFigmaMetric('اشتراكات فصل كامل', '812'),
        AdminFigmaMetric('اشتراكات مواد', '241'),
        AdminFigmaMetric('اشتراكات كورسات', '386'),
      ],
      panels: [
        AdminFigmaPanelData(
          'خطط الاشتراك والأسعار',
          records: [
            AdminFigmaRecord(
              'اشتراك الفصل الكامل · الفصل الثالث',
              values: [r'$45', 'حتى نهاية الفصل', '812 مشتركاً'],
              status: 'مفعّلة',
            ),
            AdminFigmaRecord(
              'اشتراك مادة واحدة',
              values: [r'$12', 'حتى نهاية الفصل'],
              status: 'مفعّلة',
            ),
          ],
        ),
      ],
    ),
    'M-C04': AdminFigmaScreenData(
      subtitle: 'كل اشتراكات الطلاب في المواد والكورسات',
      action: 'منح اشتراك',
      filters: ['النوع: الكل', 'الحالة: الكل'],
      metrics: [
        AdminFigmaMetric('اشتراكات فعّالة', '1,017'),
        AdminFigmaMetric('تنتهي خلال 7 أيام', '38'),
        AdminFigmaMetric('ممنوحة يدوياً', '12'),
        AdminFigmaMetric('ملغاة', '21'),
      ],
      panels: [
        AdminFigmaPanelData(
          'الاشتراكات',
          records: [
            AdminFigmaRecord(
              'ريم العلي',
              subtitle: 'تطوير تطبيقات Flutter',
              values: ['بدأ 1 أكتوبر 2026', 'ينتهي 1 أكتوبر 2027'],
              status: 'فعّال',
            ),
            AdminFigmaRecord(
              'أحمد الحلبي',
              subtitle: 'الفصل الكامل · الفصل الثالث',
              values: ['بدأ 10 سبتمبر 2026'],
              status: 'ينتهي قريباً',
            ),
          ],
        ),
      ],
    ),
    'M-C05': AdminFigmaScreenData(
      subtitle: 'كل عمليات الدفع: ShamCash والحوالات اليدوية والقسائم',
      action: 'تصدير CSV',
      filters: ['الفترة: هذا الشهر', 'الحالة: الكل', 'الطريقة: الكل'],
      metrics: [
        AdminFigmaMetric('إيرادات الشهر', r'$2,430'),
        AdminFigmaMetric('عمليات ناجحة', '187'),
        AdminFigmaMetric('بانتظار التأكيد', '2'),
        AdminFigmaMetric('مبالغ مستردّة', r'$58'),
      ],
      panels: [
        AdminFigmaPanelData(
          'سجل المدفوعات',
          records: [
            AdminFigmaRecord(
              'ريم العلي',
              subtitle: 'SC-77412 · تطوير تطبيقات Flutter',
              values: [r'$29', 'اليوم 10:12'],
              status: 'بانتظار التأكيد',
            ),
            AdminFigmaRecord(
              'عمر شيخو',
              subtitle: 'SC-77398 · React',
              values: [r'$19', 'اليوم 09:48'],
              status: 'ناجح',
            ),
          ],
        ),
      ],
    ),
    'M-C06': AdminFigmaScreenData(
      subtitle: 'توليد وطباعة وإبطال قسائم الشحن التي تُباع في المكتبة',
      action: 'توليد دفعة',
      metrics: [
        AdminFigmaMetric('قسائم مستخدمة هذا الشهر', '64'),
        AdminFigmaMetric('قسائم غير مستخدمة', '236'),
        AdminFigmaMetric('قسائم مُبطلة', '3'),
        AdminFigmaMetric('دفعات مطبوعة', '5'),
      ],
      panels: [
        AdminFigmaPanelData(
          'دفعات القسائم المطبوعة',
          records: [
            AdminFigmaRecord(
              'B-005',
              subtitle: 'اشتراك الفصل الكامل',
              values: ['100 قسيمة', '42 مستخدمة'],
              status: 'فعّالة',
            ),
          ],
        ),
      ],
    ),
    'M-C07': AdminFigmaScreenData(
      subtitle: r'الكورسات والمدفوعات › الكورسات › Flutter · $29 · صلاحية سنة',
      action: 'إضافة درس',
      metrics: [
        AdminFigmaMetric('المشتركون', '142'),
        AdminFigmaMetric('الدروس', '24'),
        AdminFigmaMetric('ملفات PDF', '6'),
        AdminFigmaMetric('متوسط التقييم', '4.7 / 5'),
      ],
      panels: [
        AdminFigmaPanelData(
          'محتوى كورس تطوير تطبيقات Flutter',
          records: [
            AdminFigmaRecord(
              'مدخل إلى Flutter',
              values: ['32 د', '4.9 / 5', 'مجاني'],
              status: 'منشور',
            ),
            AdminFigmaRecord(
              'بناء أول واجهة',
              values: ['48 د', '4.7 / 5'],
              status: 'منشور',
            ),
            AdminFigmaRecord(
              'إدارة الحالة',
              values: ['54 د', 'فيديو جاهز'],
              status: 'منشور',
            ),
          ],
        ),
      ],
    ),
    'M-D03': AdminFigmaScreenData(
      subtitle: 'الدعم › أحمد الحلبي · قيد المعالجة',
      action: 'إغلاق التذكرة',
      panels: [
        AdminFigmaPanelData(
          'بيانات الطالب',
          fields: [
            AdminFigmaField('الاسم', 'أحمد محمد الحلبي'),
            AdminFigmaField('الجهاز', 'Samsung A54'),
            AdminFigmaField('القسم · السنة', 'برمجيات · الثانية'),
            AdminFigmaField('الاشتراك', 'الفصل الثالث · فعّال'),
          ],
        ),
        AdminFigmaPanelData(
          'المحادثة',
          records: [
            AdminFigmaRecord(
              'أحمد محمد الحلبي',
              subtitle: 'اليوم 09:40',
              values: [
                'لا أستطيع تشغيل الدرس 4، تظهر لي شاشة سوداء عند الضغط على تشغيل.',
              ],
            ),
            AdminFigmaRecord(
              'الإدارة',
              subtitle: 'اليوم 09:52',
              values: [
                'أهلاً أحمد، هل جرّبت تحديث التطبيق؟ نتحقق من معالجة الفيديو ونعود إليك.',
              ],
            ),
            AdminFigmaRecord(
              'أحمد محمد الحلبي',
              subtitle: 'اليوم 10:05',
              values: ['جرّبت التحديث ولم يتغير شيء.'],
            ),
          ],
        ),
        AdminFigmaPanelData(
          'ردّك',
          fields: [AdminFigmaField('اكتب ردك هنا…', '', multiline: true)],
        ),
      ],
    ),
    'M-D04': AdminFigmaScreenData(
      subtitle: 'قالبان فقط: تنبيه وتذكير · تُستخدم في كل الإشعارات',
      action: 'حفظ القوالب',
      panels: [
        AdminFigmaPanelData(
          'قالب التنبيه',
          fields: [
            AdminFigmaField('العنوان', 'تحديث جدول الامتحانات'),
            AdminFigmaField(
              'النص',
              'تم نشر الجدول الجديد للدورة العادية.',
              multiline: true,
            ),
          ],
        ),
        AdminFigmaPanelData(
          'قالب التذكير',
          fields: [
            AdminFigmaField('العنوان', 'تذكير: قواعد البيانات'),
            AdminFigmaField(
              'النص',
              'موعد الامتحان العملي الخميس 11 يونيو. بالتوفيق!',
              multiline: true,
            ),
          ],
        ),
        AdminFigmaPanelData(
          'الإشعارات التلقائية',
          records: [
            AdminFigmaRecord(
              'قبل يوم من الامتحان (يدوي)',
              values: ['تذكير موعد امتحان'],
              status: 'مفعّل',
            ),
            AdminFigmaRecord(
              'عند بدء الفصل الجديد',
              values: ['تذكير'],
              status: 'مفعّل',
            ),
          ],
        ),
      ],
    ),
    'M-F01': AdminFigmaScreenData(
      subtitle: 'نظرة على الاستخدام والتقييمات والاشتراكات',
      action: 'تصدير',
      filters: ['الاستخدام', 'التقييمات', 'الاشتراكات'],
      metrics: [
        AdminFigmaMetric('إجمالي ساعات الاستخدام', '3,420 س'),
        AdminFigmaMetric('متوسط الطالب أسبوعياً', '2 س 45 د'),
        AdminFigmaMetric('أكثر مادة مشاهدة', 'البرمجة الكائنية'),
        AdminFigmaMetric('أعلى يوم نشاطاً', 'الثلاثاء'),
      ],
      panels: [
        AdminFigmaPanelData(
          'وقت الاستخدام اليومي (ساعات) · هذا الأسبوع',
          chartValues: [174, 118, 143, 190, 150, 162, 128],
        ),
        AdminFigmaPanelData(
          'أكثر الدروس مشاهدة',
          records: [
            AdminFigmaRecord('مقدمة في البرمجة الكائنية'),
            AdminFigmaRecord('الأصناف والكائنات'),
          ],
        ),
      ],
    ),
    'M-F02': AdminFigmaScreenData(
      subtitle: 'الإعدادات › من فعل ماذا ومتى',
      action: 'تصدير CSV',
      filters: ['الفترة: آخر 7 أيام', 'العملية: الكل', 'المسؤول: الكل'],
      panels: [
        AdminFigmaPanelData(
          'سجل عمليات الإدارة · للقراءة فقط',
          records: [
            AdminFigmaRecord(
              'موافقة دفع',
              subtitle: 'محمد مخملجي · اليوم 10:12',
              values: ['SC-77412 · ريم العلي', 'كورس Flutter · 29 دولار'],
            ),
            AdminFigmaRecord(
              'نشر درس',
              subtitle: 'مشرف المحتوى · اليوم 09:48',
              values: ['البرمجة الكائنية · الدرس 3'],
            ),
            AdminFigmaRecord(
              'فك ربط جهاز',
              subtitle: 'محمد مخملجي · أمس',
              values: ['أحمد محمد الحلبي · Samsung A54'],
            ),
          ],
        ),
      ],
    ),
    'M-A06': AdminFigmaScreenData(
      subtitle: 'الطلاب › أحمد الحلبي › وقت الاستخدام والتقييمات',
      action: 'إدارة المواد الراسبة',
      metrics: [
        AdminFigmaMetric('وقت الاستخدام · هذا الأسبوع', '4 س 35 د'),
        AdminFigmaMetric('الأسبوع الماضي', '3 س 50 د'),
        AdminFigmaMetric('دروس مكتملة', '38'),
        AdminFigmaMetric('تقييمات أرسلها', '21'),
      ],
      panels: [
        AdminFigmaPanelData(
          'وقت الاستخدام اليومي · هذا الأسبوع',
          chartValues: [38, 6, 84, 150, 66, 103, 75],
        ),
        AdminFigmaPanelData(
          'آخر تقييماته',
          records: [
            AdminFigmaRecord('الوراثة', values: ['5 / 5']),
            AdminFigmaRecord('الأصناف والكائنات', values: ['4 / 5']),
          ],
        ),
      ],
    ),
    'M-E02': AdminFigmaScreenData(
      subtitle: 'الإعدادات › مسؤولو الإدارة › إضافة',
      action: 'حفظ',
      panels: [
        AdminFigmaPanelData(
          'بيانات المسؤول',
          fields: [
            AdminFigmaField('الاسم', 'مشرف المحتوى'),
            AdminFigmaField(
              'البريد الإلكتروني (حساب Google)',
              'content@devmmnd.com',
            ),
            AdminFigmaField('الدور', 'مشرف محتوى'),
          ],
        ),
        AdminFigmaPanelData(
          'الصلاحيات',
          fields: [
            AdminFigmaField('الطلاب والأجهزة', 'مفعّل'),
            AdminFigmaField('المحتوى والتمارين والعلامات', 'مفعّل'),
            AdminFigmaField('المدفوعات والقسائم والاشتراكات', 'غير مفعّل'),
            AdminFigmaField('الدعم والإعلانات', 'مفعّل'),
            AdminFigmaField('الإعدادات وسجل العمليات', 'غير مفعّل'),
          ],
          note: 'يدخل المسؤول بحساب Google المصرّح فقط، ولا توجد كلمات مرور. يمكن سحب الصلاحية في أي وقت من قائمة المسؤولين.',
        ),
      ],
    ),
  };
}
