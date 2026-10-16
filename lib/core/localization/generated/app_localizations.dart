import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('ar')];

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'Hasobjy | حاسوبجي'**
  String get appTitle;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل Google غير مُهيأ لهذا الجهاز. راجع إعدادات OAuth.'**
  String get googleUnavailable;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'لم يصل إثبات الهوية المطلوب من Google. حاول مجدداً.'**
  String get googleMissingToken;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'تعذر إكمال تسجيل Google. حاول مجدداً.'**
  String get googleUnexpected;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تسجيل الخروج من Google. حاول مجدداً.'**
  String get googleSignOutFailed;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'تعلم مواد المعهد\nفي مكان واحد'**
  String get welcomeHeadline;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'مواد مرتبة حسب قسمك وسنتك وفصلك، ودروس يمكنك العودة إليها بسهولة.'**
  String get welcomeDescription;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'منهج واضح لكل قسم وسنة'**
  String get featureCurriculum;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'درس تعريفي لكل مادة'**
  String get featureIntroLesson;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'تنزيل محمي بعد تفعيل الخدمة'**
  String get featureProtectedDownload;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'المتابعة باستخدام Google'**
  String get continueUsingGoogle;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'يتطلب تسجيل Google إعداد معرّفات OAuth لهذا التطبيق.'**
  String get googleSetupRequired;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'معاينة واجهة الطالب'**
  String get studentPreview;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'معاينة لوحة الإدارة'**
  String get adminPreview;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'هوية Google وحدها لا تمنح حساباً أو اشتراكاً داخل Hasobjy حتى يتحقق خادم التطبيق منها.'**
  String get identityBoundary;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'حساب Google'**
  String get googleAccount;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'هوية Google'**
  String get googleIdentity;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار ربط حساب التطبيق'**
  String get identityPendingTitle;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'تم اختيار حساب Google على هذا الجهاز. لم يتحقق خادم Hasobjy من الهوية بعد، لذلك لا توجد جلسة تطبيق أو صلاحية طالب أو إدارة أو اشتراكات.'**
  String get identityPendingDescription;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'الخروج من Google'**
  String get googleSignOut;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'برمجيات'**
  String get departmentSoftware;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'معلوماتك الأكاديمية'**
  String get academicInfo;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'القسم'**
  String get department;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'مواد البرمجة وتطوير التطبيقات'**
  String get softwareDescription;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'شبكات'**
  String get departmentNetworks;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'مواد الشبكات والأنظمة'**
  String get networksDescription;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'السنة الدراسية'**
  String get academicYear;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'السنة الأولى'**
  String get firstYear;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'الفصل الأول والثاني'**
  String get firstYearTerms;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'السنة الثانية'**
  String get secondYear;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'الفصل الثالث والرابع'**
  String get secondYearTerms;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get continueAction;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد التسجيل'**
  String get confirmEnrollment;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'راجع بياناتك قبل الحفظ'**
  String get reviewBeforeSaving;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الرسمي'**
  String get officialName;

  /// Design preview fixture only; not server data or policy.
  ///
  /// In ar, this message translates to:
  /// **'أحمد محمد الحلبي'**
  String get previewStudentName;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'الفصل الحالي'**
  String get currentTerm;

  /// Design preview fixture only; not server data or policy.
  ///
  /// In ar, this message translates to:
  /// **'الفصل الثالث · 2026/2027'**
  String get previewCurrentTerm;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'سيُسجَّل حسابك على الفصل الجاري، ويمكنك طلب تعديل القسم أو السنة من الدعم لاحقاً.'**
  String get enrollmentExplanation;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد وبدء الاستخدام'**
  String get confirmAndStart;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'تعديل البيانات'**
  String get editDetails;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'فصل جديد'**
  String get newTerm;

  /// Design preview fixture only; not server data or policy.
  ///
  /// In ar, this message translates to:
  /// **'بدأ الفصل الرابع'**
  String get previewNewTermTitle;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'هل ما زلت في القسم والسنة نفسهما؟ نحتاج تأكيدك لتفعيل مواد هذا الفصل.'**
  String get confirmAcademicDetails;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'مدة الفصل'**
  String get termDuration;

  /// Design preview fixture only; not server data or policy.
  ///
  /// In ar, this message translates to:
  /// **'1 فبراير – 15 يونيو 2027'**
  String get previewTermDates;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'نعم، تأكيد التسجيل'**
  String get confirmEnrollmentYes;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'تغيّرت بياناتي'**
  String get detailsChanged;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'حالات رأس الصفحة الأكاديمي'**
  String get academicHeaderStates;

  /// Design preview fixture only; not server data or policy.
  ///
  /// In ar, this message translates to:
  /// **'ينتهي بعد 62 يوماً · الامتحانات تبدأ 1 يونيو'**
  String get previewTermCountdown;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد فصل جارٍ حالياً'**
  String get noCurrentTerm;

  /// Design preview fixture only; not server data or policy.
  ///
  /// In ar, this message translates to:
  /// **'سُجّلت تلقائياً على الفصل القادم الذي يبدأ في 1 فبراير 2027، وسنذكّرك عند بدايته.'**
  String get previewNextTermExplanation;

  /// Design preview fixture only; not server data or policy.
  ///
  /// In ar, this message translates to:
  /// **'انتهى الفصل الثالث'**
  String get previewClosedTermTitle;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'أُغلقت مواد الفصل، وتبقى مفتوحة للمراجعة المواد التي لم تنجح بها فقط.'**
  String get closedTermExplanation;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'مؤجَّل'**
  String get postponed;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'تسجيلك مؤجَّل'**
  String get enrollmentPostponed;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'تواصل مع الدعم لإعادة تفعيل تسجيلك الأكاديمي.'**
  String get reactivateEnrollment;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'جدول الامتحانات'**
  String get examSchedule;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'الدورة التكميلية'**
  String get supplementaryExams;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'الدورة العادية'**
  String get regularExams;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'نظري'**
  String get theoreticalExam;

  /// Design preview fixture only; not server data or policy.
  ///
  /// In ar, this message translates to:
  /// **'البرمجة الكائنية'**
  String get previewOopSubject;

  /// Design preview fixture only; not server data or policy.
  ///
  /// In ar, this message translates to:
  /// **'الأحد 7 يونيو · 09:00 · القاعة 3'**
  String get previewOopExamDate;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'عملي'**
  String get practicalExam;

  /// Design preview fixture only; not server data or policy.
  ///
  /// In ar, this message translates to:
  /// **'قواعد البيانات'**
  String get previewDatabaseSubject;

  /// Design preview fixture only; not server data or policy.
  ///
  /// In ar, this message translates to:
  /// **'الثلاثاء 9 يونيو · 11:00 · المخبر 1'**
  String get previewDatabaseExamDate;

  /// Design preview fixture only; not server data or policy.
  ///
  /// In ar, this message translates to:
  /// **'هندسة البرمجيات'**
  String get previewEngineeringSubject;

  /// Design preview fixture only; not server data or policy.
  ///
  /// In ar, this message translates to:
  /// **'الخميس 11 يونيو · 09:00 · القاعة 2'**
  String get previewEngineeringExamDate;

  /// Design preview fixture only; not server data or policy.
  ///
  /// In ar, this message translates to:
  /// **'تطوير الويب'**
  String get previewWebSubject;

  /// Design preview fixture only; not server data or policy.
  ///
  /// In ar, this message translates to:
  /// **'الأحد 14 يونيو · 10:00 · المخبر 2'**
  String get previewWebExamDate;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'هذا الحساب مرتبط بجهاز آخر'**
  String get deviceConflictTitle;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'يمكن استخدام الحساب على جهاز واحد فقط. لتغيير الجهاز أرسل طلباً للإدارة وسنراجعه في أقرب وقت.'**
  String get deviceConflictDescription;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'طلب تغيير الجهاز'**
  String get requestDeviceTransfer;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get signOut;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'الجهاز الجديد'**
  String get newDevice;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'سبب التغيير'**
  String get transferReason;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'مثال: تغيّر هاتفي أو فُقد الجهاز القديم'**
  String get transferReasonHint;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'سيصل طلبك إلى الإدارة للمراجعة'**
  String get transferReviewHelper;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'إرسال الطلب'**
  String get submitRequest;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'حالة الطلب'**
  String get requestStatus;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'قيد المراجعة'**
  String get underReview;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'طلبك قيد المراجعة'**
  String get requestUnderReview;

  /// Design preview fixture only; not server data or policy.
  ///
  /// In ar, this message translates to:
  /// **'أُرسل الطلب اليوم 12:50. سيصلك إشعار فور اتخاذ القرار.'**
  String get previewRequestSent;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'الجهاز المطلوب'**
  String get requestedDevice;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'التواصل مع الدعم'**
  String get contactSupport;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'مرحباً بك في تطبيق حاسوبجي'**
  String get designWelcomeTitle;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'تطبيق مخصص للحاسوبجيين وأي شخص شغوف يحب أن يطوّر نفسه بكورسات احترافية في مجال البرمجيات وما يندرج تحتها.'**
  String get designWelcomeDescription;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'المتابعة عبر Google'**
  String get continueViaGoogle;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'بالمتابعة فأنت توافق على الشروط والأحكام وسياسة الخصوصية'**
  String get termsConsent;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'كيف ستستخدم التطبيق؟'**
  String get usageQuestion;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'اختر ما يناسبك، ويمكنك تغيير ذلك لاحقاً من الإعدادات'**
  String get usageExplanation;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'طالب في المعهد'**
  String get instituteStudent;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'مواد قسمي وسنتي الدراسية، مع الكورسات الإضافية'**
  String get instituteStudentDescription;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'الكورسات فقط'**
  String get coursesOnly;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'أريد التسجيل في الكورسات البرمجية دون ربط حسابي بالمعهد'**
  String get coursesOnlyDescription;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'معلوماتك الأساسية'**
  String get basicInfo;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الثلاثي كما في الهوية'**
  String get officialNameHint;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'يظهر في كشف علاماتك وشهاداتك'**
  String get officialNameHelper;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف'**
  String get phoneNumber;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'للتواصل عند الحاجة فقط'**
  String get phoneHelper;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get emailAddress;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'مأخوذ من حساب Google ولا يمكن تعديله'**
  String get googleEmailHelper;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'هذه معاينة تصميم؛ لا يتصل التطبيق بخادم أو يحفظ طلباً.'**
  String get designPreviewNotice;

  /// Existing Arabic copy, preserved during foundation extraction.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get backAction;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
