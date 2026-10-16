# تثبيت البنية والحزم وتوافق الأجهزة — 2026-10-16

## أحدث حالة — FND-07

أداة Android cold Activity/PSS جاهزة ومختبرة7/7، مع diagnostic صريح على المحاكي وبيانات APK والجهاز وعينات جزئية آمنة؛3 عينات debug لا تثبت هدف الجهاز الضعيف. لا تغيير Flutter/native/packages؛ خط الأساس المعاد154 اختباراً والتحليل/التنسيق سليمان. فتحت Notion بجلسة Brave وسجلت تسليم الجودة ونطاق القياس في مهمة Flutter القائمة؛ لا تغيير مهام الطرف الآخر. [التقرير](../../reports/performance/foundation-2026-10-16/README.md).

## أحدث حالة — FND-06

نُفذت دفعة الجودة المصرح بها قبل API/Figma:154 اختباراً،3 تكاملات Android API36 و3 iOS27، guard AST وحدود layers/DI، تحقق gen_l10n/Drift ورفض العبث اليدوي، CI artifacts، و104 نصوص ARB في نطاق الأساس الحالي دون تغيير22 صورة قبل/بعد. بقيت حدود API/DRM/الأجهزة الحقيقية ونصوص المعاينات القديمة. [الأدلة والتفصيل](../../reports/engineering-foundation/quality-2026-10-16/README.md). صفحة تنسيق Notion غير متاحة عبر الاتصال404؛ لم تتغير مهام الطرف الآخر. ما يلي حالات تاريخية مؤرخة.

## أحدث حالة — FND-03/04/05

قرئت المراجع وأعيد خط الأساس 103 اختبارات. المرحلة1 وgo_router/Result/DI موجودة مسبقاً وحفظت؛ أضيف Dio متوافق مع Io وسياسة ومهلة/إلغاء/close مشتركة وتسجيل lazy (130 اختباراً عند نهاية النقل). أضيف secure session adapter وكاش Drift لمعرفات الصفحات حسب الحساب وschema1 مولدة وتنظيف/تعطيل handles قديمة، دون توصيلها بـGoogle أو إصدار جلسة. أضيفت عقود وسائط ومالك مشغل واحد بلا SDK أو تنزيل فعلي.

الفحوص النهائية: 145 اختباراً ناجحاً، 100 ملف منسق دون تغيير، analyze بلا ملاحظات، 3 تكامل iOS ناجحة بما فيها Keychain/SQLite وإعادة الفتح. بناء Android ARM32/ARM64 ناجح، وaapt يؤكد minSdk24/target36 وABI وإعدادات backup. iOS15 وNDK29 وFVM3.47.2 ثابتة. Android runtime وKeystore/backup/restore الحقيقي وDRM وأداء2GB غير مثبتة؛ المساحة الأخيرة نحو1.2GiB، دون حذف أو بناء متزامن.

حجم APK debug الجديد 106.47MiB و128.56MiB؛ روجعت مدخلاته وحفظت أرقامها. يزيد عن أرقام التقرير التاريخية بأكثر من5MiB، لكن لا توجد حزمة release مقارنة؛ لا ينسب الفرق كله إلى قدرة جديدة دون baseline قابل للمقارنة، ولا يعد حجم متجر. [التقرير الأخير وروابط الكود والسجلات والقرارات المطلوبة](../../reports/engineering-foundation/transport-storage-2026-10-16/README.md). بقية هذه الوثيقة أدلة تاريخية لا حالة تفعيل حالية لكل الحزم.

## النطاق المنفذ

بناءً على طلب صاحب المنتج: تحديث دور المهندس في AGENTS وقاعدة `.cursor/rules/hasobjy-engineering.mdc`، وتوثيق Feature-first/Cubit والخادم والإدارة المستقلة، وسجل الحزم وحماية الفيديو/PDF وخطة الهواتف الضعيفة. حفظت التعديلات السابقة في الواجهات والخطط وSQL، ولم تُرحّل شاشات أو ينشأ خادم.

## الملفات

- جديدة: `plans/12-engineering-foundation.md`, `plans/13-packages.md`, `plans/14-low-end-devices.md`, `docs/ENGINEERING_OVERVIEW.md` وقاعدة المهندس أعلاه.
- محدثة: `AGENTS.md`, `README.md`, فهارس plans/features، الخطط 02/05/07/08/09 وخطط foundation/playback/offline وعقد المهمة.
- تبعيات: `pubspec.yaml`, `pubspec.lock`, `ios/Podfile.lock`، ومسجلات plugins المولدة لـmacOS/Linux/Windows بعد pub get. بقيت التغييرات السابقة في الملفات نفسها محفوظة.
- Android: minSdk صريح 24 في app؛ NDK 29 للوحدات التابعة بـ`LibraryAndroidComponentsExtension.finalizeDsl` في root build.gradle.kts. لا تغيير Flutter/AGP/Kotlin أو iOS deployment target.

## الحزم

Runtime المضافة: Dio 5.11.1، Drift 2.35.2، drift_flutter 0.3.1، flutter_secure_storage 11.2.0، freezed_annotation 3.1.0، get_it 9.3.0، go_router 18.1.0، json_annotation 4.12.0، pdfrx 2.6.5.

Dev المضافة: bloc_test 10.0.0، build_runner 2.16.1، drift_dev 2.35.1، freezed 4.0.1، json_serializable 6.14.1، mocktail 1.0.5. هذه المجموعة حُلّت مع Flutter 3.47.2/Dart 3.13.2 دون dependency overrides أو ترقية شاملة للحزم القائمة. سجل الملكية ومواضع التفعيل في الخطة 13.

## الفحوص المنفذة

- `fvm flutter pub get` ثم `fvm flutter pub get --enforce-lockfile`: نجاح.
- `fvm dart format --output=none --set-exit-if-changed lib test`: 58 ملفاً، دون تغيير.
- `fvm flutter analyze`: لا ملاحظات.
- `fvm flutter test --reporter compact`: 62 اختباراً ناجحاً.
- `fvm flutter build apk --debug --target-platform android-arm,android-arm64 --split-per-abi`: نجاح ARM32 وARM64.
- `aapt dump badging` لكلا APK: minSdk=24 وtargetSdk=36، وABI مطابق لكل ملف.
- `fvm flutter build ios --simulator --debug --no-codesign`: نجاح Runner.app؛ Podfile وRunner بقيَا iOS 15.
- 132 رابط Markdown محلياً في الملفات المراجعة: موجودة، و`git diff --check` نظيف.

فشل Android أولاً لأن JNI استخدم NDK 28.2 المحلي الناقص لملفات sysroot؛ بعد finalizeDsl استعمل NDK 29 المثبت ونجح. لا تعديلات pub-cache أو SDK، ولا تنزيل NDK جديد. تحذير SDK XML قديم باقٍ ولا يمنع البناء.

## ما لم تثبته المهمة

الحزم مثبتة لكن لم تُرحّل routes/ApiClient ولم تُنشأ DB أو جلسة secure storage أو شاشة PDF. لا فيديو DRM/رخصة أوفلاين أو API إنتاجي منفذ. لم تُجرَ تجربة جهاز حقيقي قديم/2GB أو أمان Keychain/DRM أو قياس أداء release. بناء ARM32 لا يثبت جودة العرض/الترخيص على كل جهاز.

حجما APK debug عند التحقق نحو 74.5MiB لـARM32 و96.6MiB لـARM64؛ ليسا تقدير حجم تنزيل المتجر ولا خط أساس release. بقيت مساحة القرص محدودة بعد البناء؛ لا حذف لملفات المستخدم أو SDK ضمن هذه المهمة. لا commit/push.

الخطوة التالية حسب الخارطة: تجربة DRM/الفك العتادي على أضعف جهاز، وحسم D06/D08/D09/D28، ثم تفعيل قدرات الأساس بشريحة مختبرة لكل قدرة. الميزانيات الرقمية أهداف أولية حتى القياس.

## متابعة التنفيذ — المرحلة 1 / FND-01 (2026-10-16)

**متابعة لاحقة FND-02:** فعّل Clean Architecture عند حد هوية Google (`Cubit → repository → gateway`) وResult typed بنوعي النجاح/الفشل، وget_it scoped وgo_router للتدفق الحالي. لم تعد حالة FND-01 أعلاه/أدناه تعني أن get_it/router غير مفعلين؛ تبقى نتائجها خط أساس تاريخياً. التحقق الجديد: 103 اختبارات ناجحة مقابل 81، analyze سليم، format لـ76 ملفاً بلا تغيير، ورحلتا تكامل iOS ناجحتان ببوابة اختبار. لا جلسة خادم أو OAuth تفاعلي أو Android جديد أو جهاز2GB. [تقرير FND-02 والكود والأدلة](../../reports/engineering-foundation/architecture-2026-10-16/README.md).

بتوجيه صاحب المنتج بالبدء بالأساس المستقل: نفذت bootstrap/config/composition root بحقن بوابة الهوية كسولاً، وربط التحقق من بيئة البناء بالتطبيق، ومنع المعاينات في production أو خارج debug. لا تغيير بصري أو API أو تخزين أو تبعيات أو إعدادات منصة. بقيت تعديلات الشريحة السابقة وتعديلات المستخدم محفوظة.

خط الأساس الحالي أعيد تشغيله: 62 اختباراً ناجحاً، 58 ملفاً منسقاً، analyze بلا ملاحظات. بعد المرحلة: 81 اختباراً ناجحاً، 63 ملفاً منسقاً، analyze بلا ملاحظات. نجح `fvm flutter run --no-resident --no-pub` على iPhone 18 Pro / iOS 27 Simulator مع بناء Xcode تزايدي 15.9 ثانية؛ هذه مدة بناء لا زمن startup. حفظت لقطة البداية، ولم يختبر OAuth تفاعلي أو جلسة خادم. Android لم يُشغّل بسبب مساحة نحو 1.5GiB؛ لا بناء متزامن أو حذف ملفات.

التفصيل والملفات والأوامر والأدلة والبوابات المتبقية في [تقرير المرحلة 1](../../reports/engineering-foundation/phase1-2026-10-16/README.md). المرحلة التالية المستقلة: مراجعة ApiClient/IoApiClient واختبارات التوافق قبل إدخال Dio؛ لا تعني نهاية هذه المرحلة اكتمال أساس الجلسة أو الخادم أو DRM.
