# توحيد الاسم الظاهر إلى حاسوبجي Hasobjy — 2026-10-16

## بطاقة التنفيذ

- المسؤول: Mohamad Adib Tawil؛ المنفذ: Codex؛ النوع: تعديل وإعداد تكامل؛ الحالة: منفذ محلياً، والتحقق الجاري موثق أدناه.
- الهدف: توحيد الاسم الظاهر للمستخدم إلى `Hasobjy | حاسوبجي` في تطبيقات الطالب وبيانات المتصفح وواجهات موافقة Google، وفق القرار D25.
- القرار والهوية: لا تغيير إلى Android `applicationId` أو iOS `Bundle ID` أو OAuth client IDs أو SHA fingerprints أو Firebase project ID أو Dart package `cit_zone`. هذه المعرفات تربط التطبيق وخدماته الحالية؛ إعادة إصدارها ليست إعادة تسمية للعرض.
- الهوية والجلسة: يبقى Google مزود إثبات الهوية. لا Firebase Auth provider ولا جلسة/دور من الخادم موجودة في الكود؛ لا تُعامل هوية Google وحدها كتسجيل حساب إنتاجي داخل المنصة.
- الأثر على البيانات/API: غير منطبق؛ لا endpoints أو جداول أو هجرة أو كتابة بيانات مستخدم.
- الملفات المحلية: Android label كان Hasobjy مسبقاً؛ وحّدت iOS/macOS/Linux وWeb metadata، وسمّيت نافذة وبيانات Windows باسم Hasobjy، وحدثت عناوين المشروع والخطة. الحزمة والـbundle identifiers الداخلية باقية.
- الخدمات الخارجية: أُعيدت تسمية Firebase project display name وpublic-facing name وnickname لتطبيقي Android/iOS، واسم التطبيق في Google Auth Platform؛ دون تغيير OAuth clients أو نطاقات/صلاحيات OAuth.
- القبول: تحقق أسماء العرض عبر إعدادات Firebase وGoogle Cloud؛ تطابق package/bundle IDs وبصمات SHA مع OAuth الحالي؛ تشغيل التطبيق واختبار تدفق Google الفعلي إن سمح الجهاز بتسجيل اختبار دون كشف بيانات الاعتماد.
- القيود: حالة العلامة في Google Auth Platform تعرض أن branding تحتاج verification قبل أن تظهر للمستخدمين؛ لا تتوفر وثيقة سياسة خصوصية أو الصفحة العامة المطلوبة للإكمال هنا. تحقق Google الهوية لا يثبت جلسة Hasobjy خادمية؛ API الإنتاجي غير موجود.

## التنفيذ والتحقق

- Firebase وGoogle Cloud: اسم المشروع `Hasobjy` ظاهر في الكونسولين؛ الاسم العام `Hasobjy | حاسوبجي`، ولُقبا Android وiOS حُدّثا. معرف المشروع ومعرفات التطبيق والحزم بقيت كما كانت.
- Google Cloud: صفحة Branding تعرض `Hasobjy | حاسوبجي`، ولم تتغير OAuth client IDs أو النطاقات. الجمهور ما زال External / In production. تظهر بالصفحة ملاحظة أن branding تحتاج تحقق Google قبل اعتماد ظهورها؛ لم تُرسل مراجعة تحقق، ولم تُرفع صورة أو روابط سياسة/شروط غير معتمدة.
- OAuth: عميل Android وعميل iOS وعميل Web في المشروع تطابق قيمها مع إعداد التطبيق. بصمتا SHA-1 وSHA-256 لشهادة debug المحلية تطابقان قيم Firebase المسجلة. يظل Android `applicationId` وiOS `Bundle ID` على `com.devmind.cit.learn`.
- الفحوص: `fvm flutter pub get --enforce-lockfile` نجح؛ `fvm dart format --output=none --set-exit-if-changed lib test` لم يغيّر 101 ملف؛ `fvm flutter analyze` بلا ملاحظات؛ `fvm flutter test` نجح بالكامل (154 اختباراً).
- المنصات: `fvm flutter run --debug -d BF33731D-1A83-49FD-B3EC-76827E45DB3C` بنى وشغّل iOS Simulator على iPhone 18 Pro / iOS 27. تدفق Google الحقيقي رجع بحالة هوية جاهزة، وظهر اسم Hasobjy في واجهة موافقة Google على iOS. لم يُسجل أو يُطبع رمز الهوية.
- Android: `fvm flutter build apk --debug` نجح. تحققنا بـ`aapt` من `applicationId=com.devmind.cit.learn` والاسم `Hasobjy | حاسوبجي` و`minSdk=24`. لا يوجد جهاز Android متاح لتجربة Google التفاعلية في هذه الجلسة؛ إثبات التشغيل التفاعلي على Android ما زال مطلوباً.
- Web: `fvm flutter build web --release` نجح؛ وفحوص `plutil -lint` لملفي iOS/macOS، وJSON للـweb manifest، و`git diff --check` نجحت.

## حد تسجيل الدخول

نجاح Google Sign-In المثبت هنا هو الحصول على هوية Google ورمز ID token على الجهاز؛ الشاشة نفسها توضح أنها بانتظار ربط حساب Hasobjy. لا يوجد `firebase_auth` أو API خادم في التطبيق حالياً، لذلك لم نثبت إنشاء جلسة خادمية أو ملف طالب أو دور أو اشتراك. لا نحتاج تبديل client ID أو fingerprint لتغيير الاسم.
