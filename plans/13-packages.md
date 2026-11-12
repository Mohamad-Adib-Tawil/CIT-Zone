# 13 — سجل الحزم وخطة تفعيلها

## أيقونة التطبيق — 2026-11-12

`flutter_launcher_icons: ^0.14.4` أداة تطوير لتوليد أيقونات Android وiOS من `branding/hasobjy/app_icon_launcher.png` (1024×1024، مركب من طبقتي Figma `28:402` و`28:403`). طبقتا Android التكيفيتان تستخدمان خلفية التدرج `branding/hasobjy/app_icon_background.png` ومقدمة H في `branding/hasobjy/app_icon_foreground.png`. شاشة الترحيب تعرض إطار اللوغو الأصلي `assets/hasobjy/app_icon.svg`. ملفات التوليد معزولة خارج `assets/` فلا تدخل حزمة Flutter؛ لا تبعية runtime ولا تغيير لمعرفات الحزم أو حد Android API 24. إعادة التوليد: `fvm dart run flutter_launcher_icons`.

## تفعيل هوية Firebase — 2026-10-26

firebase_core للتهيئة الرسمية وfirebase_auth لتبادل Google credential واستعادة مستخدم Firebase وتجديد إثباته والخروج؛ تضافان إلى dependencies في pubspec.yaml، والإعداد كسول في auth/data. google_sign_in يبقى لاختيار الحساب. لا firebase_messaging/Analytics. الصيانة تتطلب اختبارات المنصتين وعقود الهوية وبقاء API24/iOS15، دون overrides. [العقد وخطة القبول](implementation/2026-10-26-firebase-google-auth.md).


تحديث2026-10-26: أضيفت `fpdart: ^1.2.0`، والمحلول المقفل1.2.0. سببها طلب Either الصريح وتوحيد عقود النتائج؛ الاستعمال من `core/errors/either.dart` الذي يصدر Either/Left/Right فقط. رُحّلت جميع عقود Result ومستهلكيها واختباراتها، وحُذف Result المحلي. الحزمة Dart بلا إعداد Native أو مورد في bootstrap؛ تعتمد ترقيتها مستقبلاً اختبار عقود الهوية والتخزين والوسائط والإعدادات والكتالوج وحدود AST. لا تبعية أخرى أو override أو تحديث جماعي. [تقرير الشريحة](../reports/engineering-foundation/architecture-2026-10-26/README.md).

تحديث2026-10-24: اختار المستخدم Firebase project `cit-learn-dc483` للدخول والإشعارات. خدمة FCM لم تعد مجهولة؛ `firebase_core` و`firebase_messaging` مرشحتان لشريحة P3، غير مضافتين وغير مفعّلتين بعد. حددت [خطة النشر](implementation/2026-10-24-publication-readiness.md) ملفات المنصات وAPNs وقيود API24/iOS15 والاختبارات والحجم؛ لا إضافة firebase_auth أو Analytics تلقائياً ولا تغيير نوع رمز الجلسة دون عقد Backend.

2026-10-16. أضيفت الحزم التالية فعلياً إلى `pubspec.yaml`؛ القيد الأدنى في الملف ونسخة الحل الدقيقة في `pubspec.lock`. نجاح حل الاعتماديات لا يعني تنفيذ قدراتها. لا تحديث شامل بـ`--major-versions`؛ كل تحديث يقيس الحد الأدنى للنظام وABI وحجم الإصدار والاختبارات.

## تفعيل الجودة — FND-06

`analyzer 13.3.0` dev dependency مباشر بالنسخة المحلولة سابقاً: تستخدمه tool/architecture_rules.dart لقراءة AST وتتبع import/export/part والفروع المشروطة.6 اختبارات تمنع تراجع حدود domain/data/presentation/DI؛ لا SDK إنتاج إضافياً. Android runtime أصبح مختبراً على محاكي API36 (3 تكاملات)، وتبقى استعادة Keystore والأجهزة الحقيقية بوابات مستقلة. [تقرير الدفعة](../reports/engineering-foundation/quality-2026-10-16/README.md).

## حزم التطبيق

- `shared_preferences` 2.5.6: تخزين محلي غير حساس لاختيار المظهر فقط (`system/light/dark`) عبر `SharedPreferencesAsync`، يحمّل قبل إنشاء `MaterialApp` لتجنب وميض الثيم الافتراضي. لا تحفظ فيه جلسات أو أسرار؛ لا إعداد native يدوي ولا تغيير للحد الأدنى API24/iOS15.

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
## بيئة بناء Android المعتمدة — 2026-11-12

استخدم Flutter 3.47.2 عبر FVM مع Dart 3.13.2 وJDK 17 وAGP 9.1.0 وGradle 9.3.1-bin وKGP 2.4.0. يبقى Flutter plugin loader 1.0.0 وcompileSdk/targetSdk 36 وminSdk 24 وNDK 29.0.14206865. وضع التوافق `android.builtInKotlin=false` و`android.newDsl=false` يبقي فحوص البناء مفعّلة.

أحدث إصدارين منشورين وقت المراجعة هما `firebase_auth 7.0.1` و`firebase_core 5.1.0`. كلاهما يطبق KGP في وضع التوافق، ويحتفظ بالسطر المشروط حتى عند تفعيل Kotlin المدمجة. تحذير Flutter يرصد سطر التطبيق في الملف، لذلك قد يستمر بعد تفعيل Kotlin المدمجة حتى إذا لم ينفذ Gradle ذلك الفرع.

للتحقق من هذه المجموعة على JDK 17:

```sh
fvm install
fvm flutter pub get --enforce-lockfile
fvm flutter build apk --debug --split-per-abi --target-platform android-arm,android-arm64 --no-pub
```

نتيجة 2026-11-12: نجح حل الحزم بالـlockfile وبناء APK منفصل لكل من ARM32 وARM64. أكد فحص الحزمتين معرّف التطبيق `com.devmind.cit.learn` وminSdk 24 وtargetSdk 36. بقي تحذير KGP للإضافتين وتحذير قراءة Android SDK XML ظاهرين أثناء البناء. هذه نتيجة تجميع وفحص APK.

اختبر الترقية في فرع مستقل. ابدأ ببناء المجموعة الحالية، ثم افحص ملفات Gradle المنشورة للحزم وأداة الكشف في إصدار Flutter المرشح. Flutter 3.50 يختبر قالب Android مع AGP 9.3.1 وGradle 9.5.0 وKGP 2.4.20. أي انتقال إلى Kotlin المدمجة يتطلب مراجعة كل إضافات Android وتوافق إصدار Kotlin المدمج مع فحوص Flutter، ثم بناء APK لكل ABI وفحص حد التثبيت وتجربة تسجيل الدخول. احتفظ بمجموعة الإصدارات وملف القفل الحاليين إذا لم تنجح البوابات. تجنب تجاوز فحوص البناء أو تعديل pub cache أو فرض نسخ عبر dependency_overrides.

المصادر: [Flutter 3.47](https://flutter.dev/blog/whats-new-in-flutter-3-47)، [Flutter 3.50](https://flutter.dev/blog/whats-new-in-flutter-3-50)، [دليل Kotlin المدمجة](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers)، [AGP 9.1](https://developer.android.com/build/releases/agp-9-1-0-release-notes)، [Gradle 9.3.1](https://docs.gradle.org/9.3.1/release-notes.html)، [Firebase Auth](https://pub.dev/packages/firebase_auth/versions)، [Firebase Core](https://pub.dev/packages/firebase_core/versions).
