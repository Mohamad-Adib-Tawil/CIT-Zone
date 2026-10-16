# متابعة الأساس الهندسي — FND-03/04/05

2026-10-16. تنفيذ محلي بعد طلب استكمال المراحل، دون commit/push أو نشر أو شراء أو حذف ملفات مستخدم/SDK. فحصت الشجرة ذات التعديلات السابقة وحفظتها. قرئت مراجع الطلب وخطة الأساس وعقود الهوية والوسائط والتخزين ذات الصلة. البداية نحو1.7GiB، والنهاية نحو1.2GiB. لا بناء متزامن للمنصتين.

## المرحلة 1 — تحقق الموجود

bootstrap/config/composition root وconstructor injection وget_it scoped وResult وgo_router سبق تنفيذها في FND-01/02؛ لم تعاد كتابتها. أعيد pub get بالـlock والتنسيق والتحليل و[103 اختبارات خط أساس](baseline-tests.log)، كلها ناجحة. حافظت على منع معاينات production وغير debug وعلى الفصل بين Google identity وجلسة الخادم. لم يتغير الشكل أو Theme أو الأصول أو ترتيب المحتوى.

## المرحلة 2 — ما نفذ في الشبكة

- أضيف DioApiClient خلف ApiClient دون كشف Dio للميزات. احتفظ IoApiClient واختباراته. بعد نجاح suite توافق مشتركة أصبح Dio التسجيل الافتراضي الكسول في composition root؛ لا يبدأ طلب أو يختلق عنواناً عند startup.
- عقد close صريح، ومهلة كلية تشمل الاتصال والرؤوس والجسم، وإلغاء/close يوقفان stream ويحرران listeners. أصلحت كذلك وصول اتصال Io متأخراً بعد انتهاء الطلب: يجهض المورد عند وصوله ولا يترك request مفتوحاً.
- سياسة مشتركة لـHTTPS واستثناء loopback التطويري، وحصر الأصل والبادئة والمسارات، ومنع redirect، ومعرفات آمنة وJSON object وUTF8 صارم وحد بايتات بعد فك gzip. لا تسجيل body/headers أو رؤوس Authorization/Cookie أو retry/refresh تلقائي.
- ApiFailure يبقى عقد نقل داخل data؛ repository المستقبلي يترجمه إلى Result المجال القائم. لا API إنتاجي أو كتابة حساسة مخترعة.

التحقق: [33 اختباراً للشبكة](network-contract-tests.log)، تشمل اختبارات Io القائمة والتوافق والاتصال المتأخر. بعد DI نجحت [130 اختباراً للمشروع](network-stage-tests.log). اختبارات التوافق تستخدم HTTP loopback فعلياً، ولا تثبت TLS أو خادم staging أو تفويضاً إنتاجياً.

ملفات الشبكة والتركيب:

- جديد: [DioApiClient](../../../lib/core/network/dio_api_client.dart)، [ApiTransportPolicy](../../../lib/core/network/api_transport_policy.dart)، [ApiRequestScope](../../../lib/core/network/api_request_scope.dart).
- معدل: [ApiClient](../../../lib/core/network/api_client.dart)، [IoApiClient](../../../lib/core/network/io_api_client.dart)، [ApiCancellationToken](../../../lib/core/network/api_cancellation_token.dart)، [AppDependencies](../../../lib/app/di/app_dependencies.dart).
- جديد: [اختبارات التوافق](../../../test/core/network/api_client_contract_test.dart)، [دورة حياة Io](../../../test/core/network/io_api_client_lifecycle_test.dart)، [DI للنقل](../../../test/app/api_dependencies_test.dart).

## المرحلة 3 — التوجيه والجلسة

go_router القائم واختبارات روابطه/redirect/الرجوع محفوظة. أعيدت رحلة sign-in → صفحة الهوية → معاينة → platform back → sign-out على iOS. نجح أيضاً حجب رابط معاينة الإدارة في config production. gateway الهوية في الاختبار fake؛ لا OAuth تفاعلي أو جلسة خادم أو استحقاق جديد. مسارات إكمال الملف/الطالب/تعارض الجهاز الإنتاجية ما زالت تتطلب عقد الجلسة وقراراتها. ربط App/Universal Links من خارج التطبيق غير مهيأ؛ لا ادعاء اختباره.

## المرحلة 4 — ما نفذ في التخزين

- SessionSecretStore وSecureSessionSecretStore محصوران بمعرف حساب opaque من الخادم مستقبلاً؛ لا Google email أو إنشاء جلسة محلية. لا تخزين فعلي في تدفق التطبيق الحالي ولا تسجيل في root قبل المستهلك المعتمد. Keychain/Keystore ليسا مخزن DRM في هذه الشريحة.
- Android namespace مستقل، ودون biometric إلزامي أو reset عالمي صامت عند فقد مفتاح. iOS Keychain خاص بالتطبيق وunlocked_this_device ودون sync. الأخطاء تتحول إلى Result آمن ولا fallback ذاكرة عند فشل المنصة.
- Drift بجدول account_page_indices واحد: account_id/cache_key/item_ids_json/cached_at_ms. يحفظ معرفات عناصر فقط، بلا أسماء/علامات/جلسات/رموز/مفاتيح/رخص أو نسخة SQL الخادم. حد الصفحة1000 معرف بطول256 وحد المفتاح256 حدود أمان تقنية أولية، وليست تغيير ترقيم API أو سياسة منتج.
- CacheDatabase يفتح lazy، وonDevice يفوض العمل إلى isolate الخاص بـdrift_flutter. التوليد الفعلي محدود للملف، و[سجله هنا](generation.log). schema1 جديدة؛ اختبرت الإنشاء/الإغلاق/إعادة الفتح، ورفض نسخة مستقبلية غير مدعومة دون محو البيانات. لا ترحيل من إصدار منشور سابق؛ أول upgrade حقيقي يحتاج اختباراً خاصاً حين يوجد.
- AccountLocalData يتحقق من تطابق حساب المخزنين. غياب secret أو فشل قراءته ينظف كاش الحساب دون منح جلسة. clear يحاول المخزنين ويبلغ أي فشل، ولا يدعي معاملة ذرية عبر Keychain/SQLite أو revoke خادم.
- clear يعطل handle الكاش القديم قبل الحذف؛ الكتابة داخل transaction، والقراءة المتأخرة/الكتابة بعد التنظيف لا تعيد بيانات الخروج. جلسة لاحقة تستعمل handle جديداً، والحساب الآخر يبقى معزولاً.

[11 اختبار تخزين ناجحاً](storage-tests.log)، تشمل عزل الحسابات، corruption، missing/lost key، cleanup جزئي، السباق مع كتابة متأخرة، والفتح الكسول/schema. فقد Keystore الحقيقي وbackup restore/reinstall غير مختبرين؛ أخطاء المفتاح اختبرت بالـmock والحذف الصريح.

ملفات التخزين الجديدة:

- [AccountScope](../../../lib/core/storage/account_scope.dart)، [StorageFailure](../../../lib/core/storage/storage_failure.dart)، [AccountCache/CachedPageIndex](../../../lib/core/storage/account_cache.dart)، [AccountLocalData](../../../lib/core/storage/account_local_data.dart).
- [CacheDatabase](../../../lib/core/storage/cache_database.dart)، [الجزء المولد](../../../lib/core/storage/cache_database.g.dart)، [DriftAccountCache](../../../lib/core/storage/drift_account_cache.dart).
- [SessionSecretStore](../../../lib/core/security/session_secret_store.dart)، [SecureSessionSecretStore](../../../lib/core/security/secure_session_secret_store.dart).
- [اختبارات SQLite والعزل والتنظيف](../../../test/core/storage/local_storage_test.dart)، [اختبارات المخزن الآمن](../../../test/core/storage/secure_session_store_test.dart)، [تكامل native والتوجيه](../../../integration_test/foundation_native_test.dart).

تغييرات المنصات الفعلية:

- معدل [AndroidManifest.xml](../../../android/app/src/main/AndroidManifest.xml): allowBackup=false ومرجعا backup/data extraction.
- جديد [backup_rules.xml](../../../android/app/src/main/res/xml/backup_rules.xml) و[data_extraction_rules.xml](../../../android/app/src/main/res/xml/data_extraction_rules.xml): استبعاد بيانات التطبيق من cloud backup وdevice transfer. لا إذن تخزين عام أو biometric.
- جديد [Runner.entitlements](../../../ios/Runner/Runner.entitlements): مجموعة Keychain افتراضية خاصة بالتطبيق، دون مجموعة مشاركة مخصصة. معدل [project.pbxproj](../../../ios/Runner.xcodeproj/project.pbxproj) لربط entitlement بكل إعدادات Runner الثلاثة. لا تغيير min OS أو OAuth أو Pod dependencies.

## المرحلة 5 والوسائط — ما تسمح به القرارات

الشريحة الوظيفية المستقلة الحالية هي Google identity عبر domain/data/Cubit/presentation مع adapter Google الحقيقي في التطبيق، وfake في اختبارات الرحلات. لا ينشأ منها حساب Hasobjy أو جلسة خادم. إضافة كتالوج/دروس رأسياً تحتاج API والنموذج النهائي وتفاصيل D01/D02/D26؛ لم أملأ هذه الفجوة ببيانات fake إنتاجية أو شاشة مخترعة. لا DTO جديد معتمد يستفيد من JSON Serializable/Freezed؛ لم تفرض الحزم بلا حاجة. Drift هو التوليد الجديد الفعلي.

حضرت عقود الوسائط المستقلة المطلوبة، دون تسجيلها في root أو تثبيت SDK:

- [MediaFailure](../../../lib/core/media/media_failure.dart)، [PlaybackRepository/Session](../../../lib/features/playback/domain/playback_repository.dart)، [SinglePlaybackOwner](../../../lib/features/playback/domain/single_playback_owner.dart).
- [ProtectedVideoDownloads](../../../lib/features/downloads/domain/protected_video_downloads.dart): enqueue/pause/resume/delete/status/renewLicense؛ حالة الملف منفصلة عن الرخصة، دون صلاحية مشتقة من DateTime أو ملف موجود.
- [DocumentRepository](../../../lib/features/documents/domain/document_repository.dart): AcademicPdf وViewOnlyCoursePdf وEncryptedCoursePdf أنواع منفصلة؛ export/download الأكاديمي لا يقبل كورساً، والكاش المحمي لا يقبل VIEW_ONLY. لا قارئ أو رسم صفحات منفذ؛ virtualized rendering وإدارة الذاكرة التزام adapter المستقبل.
- [اختبارات مالك المشغل](../../../test/features/playback/single_playback_owner_test.dart): أربعة اختبارات تثبت ترتيب الفتح/الإغلاق، منع موردين متزامنين، الاحتفاظ بمورد فشل إغلاقه لإعادة التنظيف، وتنظيف وصول متأخر بعد dispose. fake عقدي فقط؛ لا بث أو DRM أو تنزيل أو ساعة آمنة مثبتة.

لا URL أو مفتاح أو MP4 أو سياسة جودة/مدة/حدود مفترضة في العقود. PDF الكورس يحتاج تجربة حماية منفصلة عن DRM الفيديو؛ الأكاديمي يبقى قابلاً للتنزيل وفق تحقق الهوية والنشر من الخادم.

## التحقق والأثر على الأجهزة

- `fvm flutter pub get --enforce-lockfile`: ناجح؛ لا dependencies جديدة أو ترقية أو override. Flutter3.47.2 مثبت في FVM.
- [التنسيق](format.log): 100 ملف، 0 تغيير؛ [التحليل](analyze.log): بلا ملاحظات؛ [المجموعة النهائية](final-tests.log): **145 اختباراً ناجحاً** مقابل103 في البداية.
- [iOS integration](ios-integration.log): ثلاثة اختبارات ناجحة على iPhone18Pro/iOS27 Simulator، ومنها كتابة/قراءة/حذف Keychain وفتح SQLite وإغلاقه وإعادة فتحه وعزل الحسابين. مفاتيح الاختبار ذات prefix فريد، وتنظف بيانات الحسابين فقط. أُعيد الاختبار بعد إصلاح handle المتأخر؛ البناء التزايدي الأخير17.5ثانية، ليس زمن startup.
- [Android build](android-build.log): `fvm flutter build apk --debug --target-platform android-arm,android-arm64 --split-per-abi` ناجح، تسلسلياً بعد iOS. [ARM32](arm32-badging.log) و[ARM64](arm64-badging.log): minSdk24/target36 والـABI الصحيح. [الـManifest داخل APK](android-manifest.log) يؤكد backup=false وربط قاعدتي النسخ.
- Android NDK29 للمشروع والمكتبات وiOS15 ثابتة؛ plutil وgit diff --check سليمان. لم يبدأ محاكي Android بسبب المساحة. بناء APK لا يثبت Keystore/backup/restore على Android أو سلاسة2GB أو DRM.
- مراجعة الحجم: APK debug الحالي106.47MiB لـARM32 و128.56MiB لـARM64؛ [تفصيل المدخلات](apk-size-review.json). kernel debug مضغوط نحو31.97MiB، وlibflutter نحو31.61/37.03MiB، وPDFium نحو4.01/6.09MiB، وSQLite نحو1.63/1.65MiB. توجد أيضاً نحو24.32MiB بين حجم الحاوية ومجموع المدخلات المضغوطة؛ لا تُنسب إلى كود ميزة دون قياس مقارن. الأرقام أعلى من التقرير التاريخي بأكثر من5MiB، فسجلت المراجعة؛ لا baseline release مماثل أو حجم متجر. لا إعادة بناء release لضيق المساحة، وتبقى بوابة الحجم والأداء مفتوحة.
- لا قياسات بدء/ذاكرة/شبكة/حرارة أو جهاز2GB؛ الميزانيات في14 أهداف وليست نتائج. لا مقارنة Figma جديدة لأن Widgets لم تتغير؛ مجموعة اختبارات الإطارات والحقول وRTL السابقة ما زالت ناجحة.

## ما يلزم للمتابعة — أدلة وخيارات دون حسم بالتخمين

- D07/D10: اعتماد عقد جلسة الخادم وexchange/refresh/revoke وربط الجهاز، مع جهة API موثوقة واختبارات رفض/تزامن. عندها يحقن المستودع الحقيقي والمخزن الآمن وResult دون تغيير حدود الطبقات. لم يختر العميل لغة خادم أو استضافة.
- D01/D02/D26: بيانات المنهج الفعلية ونموذج دورات المادة وعلاقتها بالدروس قبل DTO/API الكتالوج. المادة وموضعها والكورس المستقل لا تدمج لإكمال شاشة.
- D08/D09/D28: الخياران الموثقان هما مزود DRM مُدار ينجح في مصفوفة الاختبار، أو تكامل منصة/ترخيص مستقل يحققها. لم يختَر SDK/مزود أو يدفع اشتراك. يلزم إثبات البث والأوفلاين والانتهاء بساعة موثوقة على Android/iOS الحقيقيين و2GB/ABI المطلوبين، مع الجودة/التزامن/المدة المعتمدة. لا fallback واضحاً إذا فشلت التجربة.
- PDF الكورس: تنفيذ VIEW_ONLY المتصل أو ENCRYPTED_IN_APP بحسب السياسة المعتمدة وقدرة حماية/انتهاء مثبتة؛ لا اعتبار SQLite/Keychain/pdfrx حماية مكتملة أو تغيير السياسة عند التعذر.
- الاشتراكات والتمارين والتقدم والعلامات والدعم تتبع عقودها وD04/D18/D22/D23/D27؛ لا سياسة مالية أو علامات/متوسط/وقت أسبوعي مخترعة.

الخطوة التالية التي تحتاج مدخلاً خارجياً: عقد جلسة/API وبيانات الكتالوج أو تجربة DRM بأجهزة وخدمة معتمدة. الأجزاء المحلية المستقلة أعلاه نُفذت؛ لا تمثل المراحل الخادمية وميزات الوسائط إنتاجياً مكتملة.
