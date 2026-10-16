# FND-06 — جودة الأساس قبل API وFigma — 2026-10-16

المسؤول البشري **Mohamad Adib Tawil**؛ الأداة **Codex**؛ نوع المساهمة تنفيذ واختبار. اكتمل نطاق الدفعة المحلي المحدد في بطاقة التنفيذ؛ المشروع الإنتاجي يبقى In Progress. حُفظت تعديلات العمل السابقة ولم ينفذ commit أو push أو نشر أو شراء أو حذف SDK/ملفات المستخدم.

## الفحص والتنسيق

قرئت قواعد المستودع والفريق والمراجع المرتبطة بالأساس والقرارات. صفحة التنسيق `3fb921ef-52a9-8054-914b-f51b7fda3f85` أعادت Notion API 404/object_not_found؛ لذلك لم تقرأ أحدث ملاحظات الطرف الآخر ولم تحدث المهمة الحية. المرجع المحلي docs/TEAM_COORDINATION.md تاريخي فقط؛ لم تتغير نسبة التحليل/SQL/التصميم أو حالات مهام Claude. يلزم لاحقاً نقل هذا التسليم إلى المهمة القائمة عند إتاحة الوصول، دون مهمة مكررة.

بدأ العمل بنحو12GiB متاحة وpub get enforce ناجح و145 اختباراً ناجحاً. فحص Git أظهر تعديلات سابقة كثيرة؛ قائمة الملفات أدناه تخص هذه الدفعة ولا تنسب بقية diff إلى Codex الحالي.

## التنفيذ الفعلي

1. **Android:** شغلت suite foundation_native_test على Pixel_9a_Fast / emulator-5554 / ARM64 / Android16 API36، قبل التغيير وبعده. رحلتان للتوجيه (دخول بهوية اختبار، معاينة، platform back، خروج، ومنع رابط debug في production) واختبار تخزين أصلي واحد. يعيد SQLite الفتح ويفصل حسابي اختبار ويقرأ/يحذف secure storage وينظف الكاش عند حذف المفتاح والخروج. Google gateway مزيف صراحة في هذه الرحلة؛ ليس OAuth تفاعلياً أو جلسة خادم.
2. **حدود البنية:** أداة analyzer AST تفحص import/export/part وكل فروع conditional imports، وتتبع الاعتماديات المحلية العابرة والدوائر. تمنع domain من Flutter والمنصات والطبقات الخارجية، وpresentation من data/SDKs التخزين والنقل/DI، وdata من presentation/app، وcore من features/app. get_it مقصور على app/di. ستة اختبارات تشمل المستودع وfixtures رفض وقبول؛ ليست برهاناً على صحة منطق الأعمال أو تفويض خادم. تحلل المكتبات المحلية وdirectives الخارجية، ولا تفك شجرة كل حزمة pub.
3. **CI:** فحص توليد gen_l10n وbuild_runner يقارن bytes عبر SHA256 ومسارات الملفات بما فيها غير المتتبعة؛ لا يعتمد على git diff وحده. شمل التنسيق integration_test وtool، وأضيف guard مستقل وحفظ log وصور اختبار هذه الجولة عند الفشل لمدة7 أيام. SDK يختار من .fvmrc كما في CI السابق؛ أوامر التطوير محلياً عبر FVM. لم تشغّل GitHub Actions عن بعد ولم يضف iOS job أو محاكي Android إلى CI.
4. **النصوص:** gen_l10n/ARB عربية واحدة، 104 مفاتيح معنونة لمدخل التطبيق وهوية Google وإطارات onboarding الأحد عشر ومكون الرجوع. نفس الكلمات والأسطر والـRTL والأصول والمقاسات؛ 22 صورة widget قبل/بعد متطابقة bytes عند390 و320. رسائل الفشل الآمنة مولدة ومحقونة في Cubit عبر constructor، بلا BuildContext في Cubit/domain. اختيار القسم ونوع الاختبار لا يقارنان بنص مترجم. نصوص fixtures محددة preview في ARB وتبقى مقيدة بمعاينة debug؛ ليست بيانات خادم. معاينات الإدارة/الطالب القديمة ومحتوى demo خارج دفعة الاستخراج هذه.

## الملفات التي أنشأتها أو عدلتها هذه الدفعة

- جديدة: `tool/architecture_rules.dart`، `test/architecture/architecture_test.dart`، `tool/verify_generated.py`، `l10n.yaml`، `lib/core/localization/app_ar.arb` وملفا `generated/app_localizations.dart` و`app_localizations_ar.dart`، `test/core/localization/app_localizations_test.dart`، هذا التقرير وأدلته.
- محدثة: `.github/workflows/flutter-ci.yml`، `pubspec.yaml` وlock، `lib/app/cit_zone_app.dart` و`lib/app/di/app_dependencies.dart`؛ `auth/presentation/google_identity_messages.dart` و`cubit/google_identity_cubit.dart` وصفحتا welcome/google_identity؛ صفحات onboarding الأربع وhasobjy_figma_components؛ test/support/hasobjy_test_app وgoogle_identity_cubit وfeatures/auth/google_identity_outcome_cubit وaccessibility_smoke وhasobjy_design_frames.
- توثيق: plans/features/00-execution-contract و01-foundation، plans/08-quality و13-packages وimplementation/2026-10-16-engineering-foundation، docs/ENGINEERING_OVERVIEW.
- لا تعديل native configuration أو SQL أو المخطط أو سياسة جلسات/وسائط أو ملف CLAUDE.

`intl 0.20.3` أصبح runtime dependency مباشراً لأن gen_l10n يستعمله؛ `analyzer 13.3.0` أصبح dev dependency مباشراً لفحص AST. النسختان كانتا محلولتين في lockfile؛ لا SDK جديد أو تحديث شامل أو مكتبة أصلية إضافية. ملكية أدوات التحليل في tool/test، وملفات النصوص في core/localization؛ لا نظام ترجمة ثانٍ.

## التحقق والأدلة

- [خط الأساس](baseline-tests.log): 145 اختباراً ناجحاً.
- [الاختبارات النهائية](tests.log): 154 ناجحاً، تشمل6 اختبارات بنية و3 توطين جديدة.
- [التحليل](analyze.log): بلا ملاحظات. [التنسيق](format.log): lib/test/integration_test/tool بلا تغيير. [enforce-lockfile](lock.log): نجاح.
- [guard](boundaries.log): نجاح. [التوليد](generated.log):3 ملفات مستقرة؛ [اختبار العبث السلبي](generated-negative.log) رفض تعليقاً مضافاً يدوياً إلى Drift g.dart برمز خروج1، وأعيد الملف كما كان. لا تعديل سلبي متبقٍ.
- [Android قبل](android-baseline.log) و[Android بعد](android-final.log):3/3 نجاح لكل تشغيل، بناء تزايدي24.8 ثم14.6 ثانية. هذه أزمنة بناء وليست startup.
- [iOS](ios.log):3/3 نجاح، iPhone18Pro / iOS27 Simulator، بناء تزايدي25 ثانية. شغلت المنصتان بالتتابع.
- [مسار أدلة CI](ci-artifacts.log):36 اختبار إطارات ناجحاً مع HASOBJY_WIDGET_OUTPUT ومخرجات22 PNG في المسار المخصص؛ الاختبارات جزء من154 وليست36 اختباراً جديداً.
- [تطابق الصور](visual-parity.json):22/22 متطابقة bytes، وbefore-320/before-390 وafter-320/after-390 تحفظ الصور. هذا يثبت عدم التغيير عن baseline الحالي، وليس اعتماد Figma جديداً أو إلغاء فروق التقرير السابق.

فحص أخير:105 ملفات Dart منسقة بلا تغيير،57 رابط توثيق محلي صحيح، وgit diff --check سليم. بقي نحو10GiB متاحاً عند التسليم؛ لم تحذف ملفات مستخدم أو SDK.

## الحدود والخطوة التالية

Android API24 وiOS15 وNDK29 وFVM3.47.2 لم تتغير. تجربة Android الحالية API36 وiOS27، وليست اختبار runtime على API24/iOS15 أو جهاز2GB. لم يقس startup/الذاكرة/release size؛ لا ادعاء أداء من نجاح المحاكي. لا إثبات فقد Keystore/Keychain فعلي أو backup/reinstall أو DRM؛ فقد المفتاح هنا حذف اختبار صريح. لم يعاد بناء ARM32/ARM64 منفصلين لأن native/config لم يتغير، والبناء ضمن الرحلات كافٍ لهذا النطاق.

لا API أو جلسة خادم/استحقاق/دفع/تنزيل DRM إنتاجي. أجزاء الوسائط وFigma غير المتاحة تحتفظ ببواباتها. التالي المستقل: استخراج نصوص المعاينات القديمة بشريحة خاصة، وتجهيز قياس أداء release على جهاز2GB عند توفره؛ ثم أول شريحة وظيفية حين يعتمد API وإطارها الفعلي. وصول Notion مطلوب لمزامنة التسليم فقط، ولا يحول ما سبق إلى إنجاز خادم أو تصميم.

## متابعة الوصول والتنسيق

لاحقاً في2026-10-16 فتحت صفحة التنسيق ومهمةFlutter عبر جلسةBrave وقرئ محتواهما وأضيف تسليمFND-06 وFND-07؛ بقي خطأMCP السابق واقعة تاريخية. [دليل التسليم الجديد](../../../docs/coordination/2026-10-16-foundation-quality-performance.md).
