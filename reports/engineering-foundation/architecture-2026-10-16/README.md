# FND-02 — Clean Architecture وDI وgo_router والنتائج

تنفيذ محلي بتاريخ 2026-10-16 بطلب صاحب المنتج. حافظ على التعديلات الموجودة ولم ينفذ commit/push أو نشر أو شراء أو حذف. بطاقة المهمة في [عقد التنفيذ](../../../plans/features/00-execution-contract.md).

## الخطة والتنفيذ الفعلي

1. فصل عرض هوية Google عن adapter المنصة: `Page → GoogleIdentityCubit → GoogleIdentityRepository (domain) → GoogleIdentityRepositoryImpl (data) → GoogleIdentityGateway → GoogleSignInGateway`.
2. أعيد استعمال `GoogleIdentityFailure` كرمز مجال. `Result<T, F>`/`Success`/`Failure` هو نظير Either المختار؛ خطة 01 تسمح Result أو استثناءات مجال، والخطة 12 تمنع نظامين متداخلين بلا حاجة. لا حزمة dartz/fpdart أو طبقات use case تمرير. لا JSON أو Flutter أو Dio أو get_it في domain.
3. repository يمسك الاستثناءات المتوقعة وغير المتوقعة ويعيد إخفاقاً آمناً. Cubit يستهلك Result بنمط exhaustiveness ولا يعرف SDK أو gateway أو implementation. الرسائل العربية في presentation. فشل الاستعادة يعود idle، والإلغاء لا يعرض خطأ، وفشل الخروج يحتفظ بالهوية برسالة آمنة. الطلب المتكرر أثناء العمل مرفوض؛ لا retry تلقائي.
4. `GetIt.asNewInstance()` حاوية خاصة بكل composition root: gateway وrepository lazy singleton، وCubit factory مستقل لكل مالك. resolution محصور في app/di، وباقي الطبقات constructor injection. DB/PDF/player/HTTP لا تُفتح من startup. factories المعاينة في composition root وتفحص سياسة debug/development قبل إنشاء demo data.
5. `MaterialApp.router` يستخدم `AppRouter` مملوكاً مع subscription وrefresh notifier؛ `CitZoneApp` يملك Cubit الهوية طوال تدفق الهوية ويغلقه مع router عند unmount. `BlocProvider.value` يعرض instance المملوك ولا يغلقه مرة ثانية. bootstrap يعيد ضبط حاوية DI. لا استعمال GetIt.instance أو singleton عام.

## المسارات والحدود

- `/` يحيل إلى التدفق الآمن القائم.
- `/sign-in`: شاشة A-S01 القائمة؛ نجاح استعادة/اختيار الهوية يحول إلى `/google-identity`.
- `/google-identity`: صفحة Google الحالية التي تنص على عدم وجود جلسة تطبيق؛ دون هوية يتحول إلى sign-in. تبقى الصفحة أثناء طلب الخروج، وفشل الخروج يبقيها، والنجاح يزيل مسارها من stack.
- `/debug/student` و`/debug/admin` و`/debug/frames/:frame`: محمية في router وفي factories بـdebug/development. إطارات المعاينة تتنقل بـgo_router عبر callback؛ نجاح Google لا يحول أي معاينة إلى محتوى حقيقي.
- الرابط المجهول أو معرف إطار غير صحيح يعيد التدفق الآمن دون اختراع شاشة خطأ. push/pop وحالة الهوية واختبارات إعادة البناء تحافظ على lifecycle.

لا مسار طالب إنتاجي أو إكمال ملف/تعارض جهاز إنتاجياً قبل عقد الجلسة وقراراته. لا تفويض خادمي من redirect، ولا استحقاق من Google. اختبارات الروابط هنا تخص parser والروابط داخل التطبيق؛ لم تهيأ Android App Links أو iOS Universal Links/associated domains أو يُدّعَ اختبار فتحها من خارج التطبيق. لا تغييرات platform لذلك.

التنقل الداخلي القديم لتفاصيل المادة ومعاينة الإدارة ما زال Navigator ضمن المعاينات القائمة؛ لم تُرحّل تلك الميزات أو يُخترع API لأجل routes. fallback التنقل في HasobjyDesignPage باقٍ لاستخدام الصفحة مستقلة في اختبارات التصميم؛ التطبيق الفعلي يحقن callback الخاص بـgo_router.

## الملفات الجديدة — الكود

- [core/errors/result.dart](../../../lib/core/errors/result.dart): Result عام واحد بنوعي القيمة والإخفاق وfold؛ Success(null) في استعادة الحساب يختلف عن Failure.
- [domain/google_identity_failure.dart](../../../lib/features/auth/domain/google_identity_failure.dart): رمز الفشل المعاد استعماله.
- [domain/google_identity_repository.dart](../../../lib/features/auth/domain/google_identity_repository.dart): عقد مستقل عن حزم العرض والمنصة.
- [data/google_identity_repository_impl.dart](../../../lib/features/auth/data/google_identity_repository_impl.dart): حد ترجمة استثناءات gateway إلى Result.
- [presentation/google_identity_messages.dart](../../../lib/features/auth/presentation/google_identity_messages.dart): mapper رسائل المجال الآمنة.
- [app/router/app_routes.dart](../../../lib/app/router/app_routes.dart): ثوابت المسارات.
- [app/router/app_router.dart](../../../lib/app/router/app_router.dart): تركيب المسارات والredirect وملكية refresh.

## الملفات المعدلة — الكود والاختبارات

- [app/di/app_dependencies.dart](../../../lib/app/di/app_dependencies.dart): تركيب scoped عبر get_it، وfactories المعاينة المحمية.
- [app/bootstrap/app_bootstrap.dart](../../../lib/app/bootstrap/app_bootstrap.dart): تحرير الحاوية.
- [app/cit_zone_app.dart](../../../lib/app/cit_zone_app.dart): MaterialApp.router وملكية Cubit/router؛ الشكل والأصول والثيم كما هي.
- [domain/google_identity_gateway.dart](../../../lib/features/auth/domain/google_identity_gateway.dart): فصل رمز الخطأ مع export يحافظ على مستخدمي العقد القائم.
- [presentation/cubit/google_identity_cubit.dart](../../../lib/features/auth/presentation/cubit/google_identity_cubit.dart): استهلاك repository/Result وحفظ الهوية أثناء الخروج.
- [student_preview_page.dart](../../../lib/features/student/presentation/pages/student_preview_page.dart): حقن Cubit factory وإزالة import وإنشاء demo repository من العرض.
- [hasobjy_design_page.dart](../../../lib/features/onboarding/presentation/pages/hasobjy_design_page.dart): callback تنقل دون تغيير الرسم أو المحتوى.
- [اختبارات Google السابقة](../../../test/google_identity_cubit_test.dart)، [معاينة الطالب](../../../test/student_preview_test.dart)، [الوصول](../../../test/accessibility_smoke_test.dart)، [bootstrap](../../../test/app/app_bootstrap_test.dart): تكييف الحقن مع إبقاء التأكيدات السلوكية السابقة.

اختبارات جديدة:

- [عزل DI والتوجيه والروابط والرجوع](../../../test/app/app_router_test.dart).
- [حدود repository ونجاح/فشل/null وغياب تسريب الاستثناء](../../../test/features/auth/google_identity_repository_test.dart).
- [نتائج Cubit والتزامن وفشل الخروج](../../../test/features/auth/google_identity_outcome_cubit_test.dart).
- [gateway اختبار فقط](../../../test/support/fake_google_identity_gateway.dart).
- [رحلة iOS للتوجيه](../../../integration_test/app_navigation_test.dart).

التوثيق المعدل: الخطط 09/12/13، خطة الأساس والهوية وبطاقة المهمة، ENGINEERING_OVERVIEW، والتقرير المتراكم 2026-10-16. لا تعديل pubspec/lock أو SDK أو SQL أو إعداد منصة في هذه الشريحة.

## نتائج التحقق

- `fvm flutter pub get --enforce-lockfile`: ناجح، لا ترقية حزم.
- قبل التنفيذ: [81 اختباراً ناجحاً](baseline-tests.log).
- بعد التنفيذ: [103 اختبارات ناجحة](final-tests.log)، بزيادة 22 اختباراً تغطي النتائج الآمنة وDI والتوجيه. اختبارات التصميم السابقة، ومنها 320/390/600 وRTL/الحقول، ما زالت سليمة.
- [format](format.log): `fvm dart format --output=none --set-exit-if-changed lib test integration_test`، 76 ملفاً، دون تغيير.
- [analyze](analyze.log): `fvm flutter analyze`، لا ملاحظات.
- [تكامل iOS](ios-integration.log): اختباران ناجحان على iPhone 18 Pro / iOS 27 Simulator باستخدام gateway اختبار: دخول → صفحة هوية دون جلسة → معاينة → رجوع عبر platform back → خروج؛ ثم منع رابط الإدارة في config production. بناء Xcode تزايدي 18.2 ثانية، وليس قياس startup.
- `git diff --check` سليم؛ لا data imports في Cubit أو domain أو student preview، ولا get_it خارج app/di.

أثناء التنفيذ صححت اختبارات الحقن لتزويد StudentPreviewPage بالfactory المطلوبة. اختبار push استخدم أولاً routeInformationProvider (يمثل عنوان الأساس عند imperative push بالإعداد الافتراضي للحزمة)، فصحح إلى `router.state` للتحقق من الوجهة الظاهرة مع تأكيد رجوع المنصة. لم تتغير سياسة go_router العالمية ولم يُحذف تأكيد سلوكي سابق أو تُضعف الاختبارات.

## المتبقي والقيود

Android لم يشغل في هذه الشريحة: كان محاكيه متوقفاً والمساحة محدودة، نحو 1.8GiB في البداية و1.7GiB بعد التكامل؛ لا بناء متزامن أو تنظيف. Android API24 وiOS15 وNDK29 وFlutter/FVM3.47.2 ثابتة. لا قياس جهاز 2GB أو ذاكرة/حجم/profile أو مقارنة Figma جديدة؛ الشريحة غير بصرية ولا تدعي مطابقة بكسلية جديدة.

هوية Google الحقيقية وOAuth التفاعلي لم يختبرا هنا؛ لا خادم أو جلسة/revoke/refresh أو ربط جهاز. ApiClient/IoApiClient وتصنيف ApiFailure واختباراته تبقى كما هي؛ لا adapter Dio جديد في هذه الشريحة ولا تحويل HTTP إلى domain قبل وجود عقد مستهلك. لا Drift/secure storage/DRM أو سياسة منتج/مزود جديد. معاينات student/admin لا تصبح ميزات إنتاجية بسبب هذا التنظيم، ولم توحّد عقودها التجريبية القديمة كلها إلى Result.

الخطوة التالية المستقلة: مراجعة النقل وتوافقه قبل تفعيل Dio، ثم ربط repository جلسة حقيقي عند اعتماد API؛ تستخدم الميزات اللاحقة نفس حد Result/domain وحقن constructors دون استخراج طبقات فارغة.
