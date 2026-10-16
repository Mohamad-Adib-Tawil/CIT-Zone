// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Hasobjy | حاسوبجي';

  @override
  String get googleUnavailable =>
      'تسجيل Google غير مُهيأ لهذا الجهاز. راجع إعدادات OAuth.';

  @override
  String get googleMissingToken =>
      'لم يصل إثبات الهوية المطلوب من Google. حاول مجدداً.';

  @override
  String get googleUnexpected => 'تعذر إكمال تسجيل Google. حاول مجدداً.';

  @override
  String get googleSignOutFailed => 'تعذر تسجيل الخروج من Google. حاول مجدداً.';

  @override
  String get welcomeHeadline => 'تعلم مواد المعهد\nفي مكان واحد';

  @override
  String get welcomeDescription =>
      'مواد مرتبة حسب قسمك وسنتك وفصلك، ودروس يمكنك العودة إليها بسهولة.';

  @override
  String get featureCurriculum => 'منهج واضح لكل قسم وسنة';

  @override
  String get featureIntroLesson => 'درس تعريفي لكل مادة';

  @override
  String get featureProtectedDownload => 'تنزيل محمي بعد تفعيل الخدمة';

  @override
  String get continueUsingGoogle => 'المتابعة باستخدام Google';

  @override
  String get googleSetupRequired =>
      'يتطلب تسجيل Google إعداد معرّفات OAuth لهذا التطبيق.';

  @override
  String get studentPreview => 'معاينة واجهة الطالب';

  @override
  String get adminPreview => 'معاينة لوحة الإدارة';

  @override
  String get identityBoundary =>
      'هوية Google وحدها لا تمنح حساباً أو اشتراكاً داخل Hasobjy حتى يتحقق خادم التطبيق منها.';

  @override
  String get googleAccount => 'حساب Google';

  @override
  String get googleIdentity => 'هوية Google';

  @override
  String get identityPendingTitle => 'بانتظار ربط حساب التطبيق';

  @override
  String get identityPendingDescription =>
      'تم اختيار حساب Google على هذا الجهاز. لم يتحقق خادم Hasobjy من الهوية بعد، لذلك لا توجد جلسة تطبيق أو صلاحية طالب أو إدارة أو اشتراكات.';

  @override
  String get googleSignOut => 'الخروج من Google';

  @override
  String get departmentSoftware => 'برمجيات';

  @override
  String get academicInfo => 'معلوماتك الأكاديمية';

  @override
  String get department => 'القسم';

  @override
  String get softwareDescription => 'مواد البرمجة وتطوير التطبيقات';

  @override
  String get departmentNetworks => 'شبكات';

  @override
  String get networksDescription => 'مواد الشبكات والأنظمة';

  @override
  String get academicYear => 'السنة الدراسية';

  @override
  String get firstYear => 'السنة الأولى';

  @override
  String get firstYearTerms => 'الفصل الأول والثاني';

  @override
  String get secondYear => 'السنة الثانية';

  @override
  String get secondYearTerms => 'الفصل الثالث والرابع';

  @override
  String get continueAction => 'متابعة';

  @override
  String get confirmEnrollment => 'تأكيد التسجيل';

  @override
  String get reviewBeforeSaving => 'راجع بياناتك قبل الحفظ';

  @override
  String get officialName => 'الاسم الرسمي';

  @override
  String get previewStudentName => 'أحمد محمد الحلبي';

  @override
  String get currentTerm => 'الفصل الحالي';

  @override
  String get previewCurrentTerm => 'الفصل الثالث · 2026/2027';

  @override
  String get enrollmentExplanation =>
      'سيُسجَّل حسابك على الفصل الجاري، ويمكنك طلب تعديل القسم أو السنة من الدعم لاحقاً.';

  @override
  String get confirmAndStart => 'تأكيد وبدء الاستخدام';

  @override
  String get editDetails => 'تعديل البيانات';

  @override
  String get newTerm => 'فصل جديد';

  @override
  String get previewNewTermTitle => 'بدأ الفصل الرابع';

  @override
  String get confirmAcademicDetails =>
      'هل ما زلت في القسم والسنة نفسهما؟ نحتاج تأكيدك لتفعيل مواد هذا الفصل.';

  @override
  String get termDuration => 'مدة الفصل';

  @override
  String get previewTermDates => '1 فبراير – 15 يونيو 2027';

  @override
  String get confirmEnrollmentYes => 'نعم، تأكيد التسجيل';

  @override
  String get detailsChanged => 'تغيّرت بياناتي';

  @override
  String get academicHeaderStates => 'حالات رأس الصفحة الأكاديمي';

  @override
  String get previewTermCountdown =>
      'ينتهي بعد 62 يوماً · الامتحانات تبدأ 1 يونيو';

  @override
  String get noCurrentTerm => 'لا يوجد فصل جارٍ حالياً';

  @override
  String get previewNextTermExplanation =>
      'سُجّلت تلقائياً على الفصل القادم الذي يبدأ في 1 فبراير 2027، وسنذكّرك عند بدايته.';

  @override
  String get previewClosedTermTitle => 'انتهى الفصل الثالث';

  @override
  String get closedTermExplanation =>
      'أُغلقت مواد الفصل، وتبقى مفتوحة للمراجعة المواد التي لم تنجح بها فقط.';

  @override
  String get postponed => 'مؤجَّل';

  @override
  String get enrollmentPostponed => 'تسجيلك مؤجَّل';

  @override
  String get reactivateEnrollment =>
      'تواصل مع الدعم لإعادة تفعيل تسجيلك الأكاديمي.';

  @override
  String get examSchedule => 'جدول الامتحانات';

  @override
  String get supplementaryExams => 'الدورة التكميلية';

  @override
  String get regularExams => 'الدورة العادية';

  @override
  String get theoreticalExam => 'نظري';

  @override
  String get previewOopSubject => 'البرمجة الكائنية';

  @override
  String get previewOopExamDate => 'الأحد 7 يونيو · 09:00 · القاعة 3';

  @override
  String get practicalExam => 'عملي';

  @override
  String get previewDatabaseSubject => 'قواعد البيانات';

  @override
  String get previewDatabaseExamDate => 'الثلاثاء 9 يونيو · 11:00 · المخبر 1';

  @override
  String get previewEngineeringSubject => 'هندسة البرمجيات';

  @override
  String get previewEngineeringExamDate => 'الخميس 11 يونيو · 09:00 · القاعة 2';

  @override
  String get previewWebSubject => 'تطوير الويب';

  @override
  String get previewWebExamDate => 'الأحد 14 يونيو · 10:00 · المخبر 2';

  @override
  String get deviceConflictTitle => 'هذا الحساب مرتبط بجهاز آخر';

  @override
  String get deviceConflictDescription =>
      'يمكن استخدام الحساب على جهاز واحد فقط. لتغيير الجهاز أرسل طلباً للإدارة وسنراجعه في أقرب وقت.';

  @override
  String get requestDeviceTransfer => 'طلب تغيير الجهاز';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get newDevice => 'الجهاز الجديد';

  @override
  String get transferReason => 'سبب التغيير';

  @override
  String get transferReasonHint => 'مثال: تغيّر هاتفي أو فُقد الجهاز القديم';

  @override
  String get transferReviewHelper => 'سيصل طلبك إلى الإدارة للمراجعة';

  @override
  String get submitRequest => 'إرسال الطلب';

  @override
  String get requestStatus => 'حالة الطلب';

  @override
  String get underReview => 'قيد المراجعة';

  @override
  String get requestUnderReview => 'طلبك قيد المراجعة';

  @override
  String get previewRequestSent =>
      'أُرسل الطلب اليوم 12:50. سيصلك إشعار فور اتخاذ القرار.';

  @override
  String get requestedDevice => 'الجهاز المطلوب';

  @override
  String get contactSupport => 'التواصل مع الدعم';

  @override
  String get designWelcomeTitle => 'مرحباً بك في تطبيق حاسوبجي';

  @override
  String get designWelcomeDescription =>
      'تطبيق مخصص للحاسوبجيين وأي شخص شغوف يحب أن يطوّر نفسه بكورسات احترافية في مجال البرمجيات وما يندرج تحتها.';

  @override
  String get continueViaGoogle => 'المتابعة عبر Google';

  @override
  String get termsConsent =>
      'بالمتابعة فأنت توافق على الشروط والأحكام وسياسة الخصوصية';

  @override
  String get usageQuestion => 'كيف ستستخدم التطبيق؟';

  @override
  String get usageExplanation =>
      'اختر ما يناسبك، ويمكنك تغيير ذلك لاحقاً من الإعدادات';

  @override
  String get instituteStudent => 'طالب في المعهد';

  @override
  String get instituteStudentDescription =>
      'مواد قسمي وسنتي الدراسية، مع الكورسات الإضافية';

  @override
  String get coursesOnly => 'الكورسات فقط';

  @override
  String get coursesOnlyDescription =>
      'أريد التسجيل في الكورسات البرمجية دون ربط حسابي بالمعهد';

  @override
  String get basicInfo => 'معلوماتك الأساسية';

  @override
  String get officialNameHint => 'الاسم الثلاثي كما في الهوية';

  @override
  String get officialNameHelper => 'يظهر في كشف علاماتك وشهاداتك';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get phoneHelper => 'للتواصل عند الحاجة فقط';

  @override
  String get emailAddress => 'البريد الإلكتروني';

  @override
  String get googleEmailHelper => 'مأخوذ من حساب Google ولا يمكن تعديله';

  @override
  String get designPreviewNotice =>
      'هذه معاينة تصميم؛ لا يتصل التطبيق بخادم أو يحفظ طلباً.';

  @override
  String get backAction => 'رجوع';
}
