# 13 — سجل الحزم وخطة تفعيلها

2026-10-16. أضيفت الحزم التالية فعلياً إلى `pubspec.yaml`؛ القيد الأدنى في الملف ونسخة الحل الدقيقة في `pubspec.lock`. نجاح حل الاعتماديات لا يعني تنفيذ قدراتها. لا تحديث شامل بـ`--major-versions`؛ كل تحديث يقيس الحد الأدنى للنظام وABI وحجم الإصدار والاختبارات.

## تفعيل الجودة — FND-06

`analyzer 13.3.0` dev dependency مباشر بالنسخة المحلولة سابقاً: تستخدمه tool/architecture_rules.dart لقراءة AST وتتبع import/export/part والفروع المشروطة.6 اختبارات تمنع تراجع حدود domain/data/presentation/DI؛ لا SDK إنتاج إضافياً. Android runtime أصبح مختبراً على محاكي API36 (3 تكاملات)، وتبقى استعادة Keystore والأجهزة الحقيقية بوابات مستقلة. [تقرير الدفعة](../reports/engineering-foundation/quality-2026-10-16/README.md).

## حزم التطبيق

- `flutter_bloc` موجود: Cubit وحالات الشاشة داخل presentation؛ لا حاجة إلى Riverpod/GetX معه.
- `google_sign_in` موجود: اختيار هوية Google خلف `GoogleIdentityGateway`؛ التحقق والجلسة وربط الجهاز من الخادم.
- `flutter_svg` موجود: أصول Figma المحلية، مع قياس كلفة SVG المعقد قبل استعماله في قائمة طويلة.
- `go_router` مفعل في FND-02: `app/router` يملك sign-in/google-identity ومعاينات debug، مع refresh من Cubit وredirect وروابط داخلية واختبارات رجوع. لا routes طالب إنتاجية أو جلسة خادم؛ التنقل الداخلي القديم للإدارة/تفاصيل المادة التجريبية لم يرحّل في هذه الشريحة. ربط App/Universal Links على مستوى النظام لم يهيأ.
- `dio` مفعل في FND-03: `DioApiClient` خلف `ApiClient`، وتسجيل lazy في DI بعد توافقه مع Io في suite موحدة. مهلة كلية وإلغاء/close، قراءة stream محدودة حتى بعد gzip، وتصنيف آمن مشترك؛ لا logging/redirect/retry/refresh أو endpoint افتراضي. اختبارات Io السابقة باقية. لا طلب شبكة عند بدء التطبيق دون مستهلك.
- `get_it` مفعل في FND-02 بناءً على طلب تنفيذ DI: حاوية `GetIt.asNewInstance` خاصة بكل `AppDependencies`؛ بوابة Google وrepository كسولان، وCubit factory. resolution في composition root فقط ثم حقن constructors؛ لا GetIt.instance أو lookup داخل domain/Widget/Cubit. عند unmount يغلق مالك العرض router/subscription وCubit، ويعيد bootstrap ضبط الحاوية دون إنشاء الخدمات الكسولة غير المستعملة. لا `injectable` أو DB/PDF/player في bootstrap.
- `drift` و`drift_flutter`: FND-04 جهز `CacheDatabase`/`DriftAccountCache` بجدول واحد لمعرفات صفحات الحساب فقط، schema 1 وجزء مولد؛ فتح lazy وisolate من drift_flutter على الجهاز. اختبرت الإنشاء/إعادة الفتح ورفض نسخة غير مدعومة دون مسح، وعزل الحسابات وتعطيل handle قديم عند التنظيف. لا جدول رموز/DRM أو نسخة SQL الخادم أو فهرس تنزيل إنتاجي؛ لا تهيئة أو تسجيل في root الحالي.
- `flutter_secure_storage`: FND-04 جهز adapter session secret محصوراً بحساب، دون ربط Google أو حفظ جلسة حقيقية. Android namespace مستقل وresetOnError=false ودون biometric؛ iOS unlocked_this_device ودون sync. أضيف استبعاد backup/data extraction وentitlements. نجحت الكتابة/القراءة/الحذف المعزولة على iOS Simulator، وفقد المفتاح باختبار mock/حذف صريح. Android Keystore وbackup/restore/reinstall والأجهزة الحقيقية بوابات غير مثبتة من البناء.
- `json_annotation` مضاف: DTO في data؛ التوليد عبر `json_serializable`.
- `freezed_annotation` مضاف: حالات/نماذج immutable عند الحاجة، مع مولد `freezed`، وليس فرضاً على كل entity.
- `pdfrx` مضاف: مرشح عرض `features/documents`؛ PDFium أصلي يزيد حجم التطبيق، يقاس على ARM32/ARM64 وiOS قبل اعتماد صفحة إنتاج. لا يشفّر PDF الكورس ولا يمنع استخراجه. لا تحمل مستنداً كاملاً أو ترسم كل صفحاته دفعة واحدة.
- `flutter_localizations` و`intl 0.20.3`: gen_l10n/ARB مفعل في FND-06 للعربية فقط،104 مفاتيح لمدخل التطبيق/Google/onboarding، مع ملفات مولدة وتحقق حتمي في CI. intl أصبح dependency مباشراً بالنسخة الموجودة في lockfile. رسائل Google محقونة في Cubit؛ لا لغة إضافية أو تغيير نص/تصميم. نصوص معاينات الإدارة/الطالب القديمة تحتاج شريحة لاحقة.

## أدوات التطوير

`build_runner`, `json_serializable`, `drift_dev`, `freezed` في dev_dependencies للتوليد عند وجود تعريفات فعلية. `bloc_test` و`mocktail` لاختبار Cubit والعقود. `flutter_test`, `integration_test`, `flutter_lints` تبقى كما هي. هذه الأدوات ليست خدمات تعمل عند فتح التطبيق ولا تُهيأ في bootstrap.

عند أول تعريف مولد، استخدم `fvm dart run build_runner build --delete-conflicting-outputs`، ثم اختبر وأدرج الملفات المولدة المطلوبة في سياسة المستودع. لا تشغل توليداً فارغاً لتسمية الحزمة مفعلة. صلاحيات التشفير/المفاتيح لا تستنتج من DTO.

في FND-04 نفذ توليد محدود للجدول الفعلي بـ`fvm dart run build_runner build --build-filter='lib/core/storage/cache_database.g.dart'`؛ الملف المولد جزء من التسليم. JSON Serializable وFreezed لم يفعّلا لأن عقد API/DTO جديداً لم يعتمد بعد؛ Result والحالات الصغيرة تستعمل sealed classes الحالية.

## ما يؤجل حتى حسم الحاجة

- SDK الفيديو وDRM و`pigeon`: بعد تجربة المزود. لا تضف مشغلين أو مكتبة تنزيل MP4 عامة كحل للفيديو المحمي.
- الإشعارات/مراقبة الأعطال: بعد اختيار الخدمة وتهيئة Android/iOS والخصوصية؛ لا تهيئة Firebase لمجرد أنه موجود في مشروع OAuth.
- حفظ/مشاركة PDF الأكاديمي وQR/رفع صور: اختيار حزمة صغيرة عند بدء الميزة وصلاحياتها. PDF الكورس لا يمر بمسار export.
- لا `workmanager` أو محرك OCR/AI أو مخزن كاش ثانٍ بلا حاجة؛ تنزيلات DRM الخلفية تديرها SDK/واجهات النظام الأصلية.
- لا تستخدم `dependency_overrides` لحل تضارب مولدات بإجبار analyzer غير متوافق. عدّل المجموعة المتوافقة واختبر التوليد عند تفعيله.

## بوابات المنصات

قبل تفعيل secure storage: راجع backup/data extraction في Android، وسياسة Keychain/entitlements للمنتج في iOS؛ لا تفعّل biometric أو طلب إذنه افتراضياً. قبل تفعيل pdfrx: تحقق من native assets/PDFium والحد الأدنى للنظام وABI وإزالة الأصول غير المستخدمة حسب تعليمات الإصدار. قبل Drift: تحقق من SQLite native assets ومسار DB الخاص واستعادتها.

المطلوب الآن تثبيت الاعتماديات والتحقق من البناء؛ ليس حفظ جلسات أو تشغيل PDF/تنزيل حقيقي. أي تغيير منصة لازم للبناء يوثق، أما إجراءات الميزة نفسها فتأتي في شريحتها.

### ضبط NDK للوحدات التابعة

`path_provider_android` التابع لـDrift يجلب JNI أصلياً. طلب JNI قيمة Flutter الافتراضية NDK 28.2، والنسخة المحلية ناقصة ملفات sysroot. ثبت `android/build.gradle.kts` قيمة NDK 29.0.14206865 لوحدات المكتبات عبر `LibraryAndroidComponentsExtension.finalizeDsl` بعد اكتمال إعداد كل مكتبة. لم تعدل `.pub-cache` أو Flutter أو نسخة NDK المثبتة. نجح البناء على ARM32 وARM64، وبقي minSdk=24 وtargetSdk=36 في APK. هذا الضبط خاص بالمشروع ويُراجع إن تطلبت مكتبة مستقبلاً NDK مختلفاً.

## مصادر الحزم

[Bloc](https://pub.dev/packages/flutter_bloc)، [GoRouter](https://pub.dev/packages/go_router)، [Dio](https://pub.dev/packages/dio)، [GetIt](https://pub.dev/packages/get_it)، [Drift](https://pub.dev/packages/drift)، [Drift Flutter](https://pub.dev/packages/drift_flutter)، [Secure Storage](https://pub.dev/packages/flutter_secure_storage)، [Freezed](https://pub.dev/packages/freezed)، [JSON Serializable](https://pub.dev/packages/json_serializable)، [pdfrx](https://pub.dev/packages/pdfrx)، [bloc_test](https://pub.dev/packages/bloc_test). روجعت عند حل المجموعة؛ lockfile هو مرجع النسخ الفعلية لا رقم أحدث في صفحة الويب.
