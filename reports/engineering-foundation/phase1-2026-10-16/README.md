# FND-01 — تركيب التطبيق والاعتماديات

2026-10-16، تنفيذ محلي على شجرة تحتوي تعديلات سابقة كثيرة؛ لا commit أو push أو نشر أو حذف ملفات. قرئت مراجع الطلب وخطة الأساس والعقد والتصميم والمتطلبات المعنية. لم تُحمل خطط ميزات أخرى أو تُختَر خدمات خارجية.

## التنفيذ

1. دخل `AppEnvironment` القائم مسار التشغيل عبر `AppConfiguration`؛ بقي API_BASE_URL اختيارياً دون عنوان وهمي، وبقي تحقق HTTPS وأخطاء الإعداد الآمنة كما هو.
2. `AppBootstrap` ينشئ composition root مرة لكل mount؛ الإعداد وfactory ثابتان طوال عمره. تغييرهما يتطلب mount جديداً. لا إنشاء بوابة Google من `build`، ولا انتظار API أو فتح DB/PDFium/player عند startup.
3. `AppDependencies` يملك بوابة Google الكسولة المشتركة داخل التطبيق فقط. لكل استدعاء Cubit مستقل يملكه ويغلقه `BlocProvider`. لا global singleton أو service locator. تهيئة Google الأصلية تبقى داخل gateway عند الاستعادة/الدخول، وهي استعادة الهوية المطلوبة الحالية وليست جلسة خادم.
4. HASOBJY_FRAME ورابط معاينة الطالب يتطلبان debug وdevelopment معاً؛ production/staging وprofile/release لا يفتحان المعاينات. يبقى فحص kDebugMode داخل نقطة الدخول أيضاً. لم تتغير شجرة الصفحات أو مكوناتها أو أصولها أو ترتيب محتواها.

## الملفات الفعلية

جديدة:

- [AppBootstrap](../../../lib/app/bootstrap/app_bootstrap.dart)
- [AppConfiguration](../../../lib/app/config/app_configuration.dart)
- [AppDependencies](../../../lib/app/di/app_dependencies.dart)
- [اختبارات التركيب والملكية والرحلة](../../../test/app/app_bootstrap_test.dart)
- [اختبارات سياسة الإعداد](../../../test/app/app_configuration_test.dart)

معدلة:

- [main.dart](../../../lib/main.dart): تشغيل bootstrap.
- [cit_zone_app.dart](../../../lib/app/cit_zone_app.dart): حقن التركيب وسياسة المعاينات؛ حافظ على تعديل المستخدم السابق الذي يعطل Google غير المهيأ.
- [google_identity_cubit_test.dart](../../../test/google_identity_cubit_test.dart): تشغيل مدخل bootstrap في اختبار OAuth غير المهيأ؛ بقية اختباراته السابقة محفوظة.
- [بطاقة المهمة](../../../plans/features/00-execution-contract.md)، [حالة الأساس](../../../plans/features/01-foundation.md)، [سجل الحزم](../../../plans/13-packages.md)، [التقرير المتراكم](../../../plans/implementation/2026-10-16-engineering-foundation.md)، وهذا المجلد للأدلة.

لم تضف حزم أو مجلدات فارغة أو تهيئة plugins. بقي FVM 3.47.2 وAndroid API 24 وiOS 15 وNDK 29 كما هي. لا تغيير SQL/ERD/API أو ترحيلات أو صلاحيات منصة. تثبيت Dio/Drift/secure storage/router/PDF سابقاً لا يعني تفعيلها هنا. get_it بقي مثبتاً بلا استعمال لعدم حاجة هذا التركيب الصغير إليه.

## التحقق

- `fvm flutter pub get --enforce-lockfile`: ناجح قبل التعديل، دون ترقية.
- خط الأساس: format لـ58 ملفاً دون تغيير، analyze بلا ملاحظات، [62 اختباراً ناجحاً](baseline-tests.log).
- اختبارات مركزة: 25 ناجحة (التركيب والإعداد وGoogle).
- بعد التعديل: `fvm dart format --output=none --set-exit-if-changed lib test`: 63 ملفاً، 0 تغيير؛ `fvm flutter analyze`: لا ملاحظات؛ `fvm flutter test --reporter expanded`: [81 اختباراً ناجحاً](final-tests.log).
- الاختبارات الجديدة تغطي مصفوفة البيئات/debug، غياب API دون fallback، كسولية الإنشاء، عدم مشاركة حالة Cubit، عدم تكرار الاستعادة عند rebuild، إغلاق Cubit أثناء استعادة معلقة، واستعادة هوية injected والخروج دون إتاحة بيانات demo في production. فحص production/non-debug في Widget يعتمد إعداداً محقوناً، وليس بناء release فعلياً.
- أثناء التطوير: أصلح حقل displayName المطلوب في fake الجديد. اختبار B-S06 كشف تجاوز عرض مع خط الاختبارات Ahem؛ حمّل Cairo عبر مساعد الاختبار المعتمد، دون تعديل UI أو إسكات FlutterError. أعيدت المجموعة كاملة بعد الإصلاح.
- `fvm flutter run -d BF33731D-1A83-49FD-B3EC-76827E45DB3C --no-resident --no-pub`: ناجح، iPhone 18 Pro / iOS 27 Simulator؛ بناء Xcode تزايدي 15.9 ثانية ثم مزامنة وإطلاق. [سجل الإطلاق المختصر](ios-launch.log)، [لقطة البداية](ios-launch.png)، وفحصت اللقطة بصرياً. هذه ليست مقارنة Figma أو زمن بدء مقاساً.
- `git diff --check`: ناجح. لم تجر مقارنة تصميم جديدة لأن التغيير غير بصري؛ اختبارات الإطارات السابقة 320/390/600 وحالات الحقول ما زالت ناجحة.

## الحدود والمرحلة التالية

مساحة البداية 1.8GiB، وبعد الاختبارات والإطلاق نحو 1.5GiB. محاكي Android كان متوقفاً؛ لم يُشغّل أو يُبنى Android في هذه المرحلة لتجنب استهلاك المساحة، ولم تحذف SDK/cache أو ملفات مستخدم. لم تجر اختبارات جهاز 2GB أو أداء profile/release أو OAuth تفاعلي؛ استعادة Google واختيارها/خروجها اختبرا بعقد fake في Widget/Cubit، والإطلاق الأصلي يثبت البداية فقط.

لا تغيّر هذه المرحلة قرارات D07/D08/D09/D28 أو D25 لمسار الكورسات فقط. لا جلسة/دور/استحقاق من هوية Google، ولا خادم أو DRM أو حفظ حساس. أثر زمن البدء والذاكرة والحجم غير مقاس؛ لا ادعاء تحسن رقمي أو دعم هاتف ضعيف من المحاكي.

المرحلة التالية: مراجعة عقد ApiClient وIoApiClient واختبارات الإلغاء والمهل وحدود الرد والأخطاء، ثم إثبات توافق أي Dio adapter قبل تبديل النقل. routing/session والتخزين والشريحة الوظيفية لم تنفذ ضمن FND-01؛ لكل منها بطاقة وبوابات مستقلة حسب الطلب.
