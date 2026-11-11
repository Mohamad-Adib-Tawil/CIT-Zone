# تسليم Google عبر Firebase — 2026-10-26

المسؤول Flutter والتوثيق: Mohamad Adib Tawil مع Codex. Backend: Mohammad Mokhmaljy مع Claude Code. أصل التحليل/التصميم وتعديلات checkout السابقة محفوظة؛ القائمة أدناه تخص هذه الشريحة فقط. لم ينفذ commit/push أو نشر.

## الترتيب والتنفيذ

1. قرئت صفحة التنسيق ومهمة Backend الحية وتذكير25 أكتوبر عبر Brave؛ موصل Notion أعاد404. أضيف اعتماد BE-AUTH-FIREBASE إلى متن المهمة القائمة وقُرئ بعد reload، مع Assignee Mohammad Mokhmaljy وTODO محفوظين. أضيف الاعتماد إلى صفحة التنسيق ومهمة Google في مسار Tawil؛ لا إقرار قراءة Claude أو تنفيذ Backend جديد ظاهر.
2. سجلت الخطة والقرار وبطاقة التنفيذ قبل الكود. Google→FirebaseAuth.signInWithCredential، Firebase reload للاستعادة، التحقق من Google provider والحساب نفسه، ومحاولة signOut لكلا المزودين حتى إن فشل أحدهما.
3. هوية العرض تشمل Google UID وFirebase UID منفصلين والبريد والتحقق والاسم والصورة. given_name/family_name/locale تمرر فقط إن وفرتها Firebase additional Google profile، بحدود أطوال ونطاق مسموح؛ يحتفظ بها في ذاكرة هوية الحساب الحالي فقط، وقد تكون null بعد إعادة تشغيل التطبيق. لا يحتفظ بprofile خام أو يطلب scopes إضافية. لا رموز في المجال أو Cubit أو التوجيه أو قاعدة محلية.
4. FirebaseIdentityProofSource.prepareForBackend يعيد Firebase ID token حديثاً مع profile تلميحي، ويرفض اختلاف Firebase UID قبل/بعد التجديد. DTO مقترح دون endpoint أو response/session مصطنعة. مصدر الإثبات متاح على نفس FirebaseGoogleIdentityGateway المحقون؛ عند تسليم API يحقن المرجع نفسه في مصدر exchange، ولا ينشأ gateway موازٍ أو يمرر token عبر Cubit.
5. أضيفت حقول users محلياً عبر amendments وأعيد توليد schema/ERD/القاموس؛ Backend مسؤول عن migration الفعلي واتساق oauth_identities والتحقق والتزامن ومنح جلسة Hasobjy. المصدر المحلي يستعمل provider_subject وليس google_sub؛ ملاحظة Notion بترحيل google_sub مشروطة بمخطط Backend الحقيقي.

## ملفات جديدة

- lib/features/auth/data/firebase_google_identity_gateway.dart
- lib/features/auth/data/firebase_identity_proof.dart
- lib/features/auth/data/google_oauth_client.dart
- lib/features/auth/data/hasobjy_firebase_configuration.dart
- test/features/auth/firebase_google_identity_gateway_test.dart
- integration_test/firebase_initialization_test.dart
- plans/implementation/2026-10-26-firebase-google-auth.md
- هذا التقرير وسجلات التحقق وأداة فحص SQL المحلية.

## ملفات معدلة في نطاق الشريحة

- lib/features/auth/domain/google_identity.dart وdata/google_sign_in_gateway.dart؛ lib/app/di/app_dependencies.dart يستعمل Firebase gateway.
- pubspec.yaml وpubspec.lock: firebase_core5.1.0 وfirebase_auth7.0.1 والمكتبات التابعة فقط؛ دون overrides أو ترقية جماعية.
- tool/architecture_rules.dart: Firebase SDK ضمن حواجز infrastructure لمنع تسربه للعرض/المجال.
- test/google_identity_cubit_test.dart وtest/app/app_bootstrap_test.dart وtest/support/fake_google_identity_gateway.dart وtest/student_preview_test.dart: معرفات صريحة للهوية الاختبارية.
- ios/Podfile.lock وmacos/Flutter/GeneratedPluginRegistrant.swift وwindows/flutter/generated_plugin_registrant.cc وgenerated_plugins.cmake مخرجات أدوات الحزم. لا تعديل AppDelegate أو MainActivity أو Manifest أو Info.plist ضمن هذه الجولة؛ تغييراتها السابقة محفوظة.
- database/amendments.sql وREADME ثم المخرجات schema.sql/schema-summary.json/data-dictionary.md وerd/A-identity.md/A-identity.mmd/full.mmd.
- plans/04-auth-security.md و09-decisions.md و10-notion-requirements.md و13-packages.md وREADME، وfeatures/README و00-execution-contract و02-identity-devices، وimplementation/google-oauth-setup و2026-10-24-publication-readiness، وdocs/TEAM_COORDINATION.md.

## المنصات والإعداد

إعدادات FirebaseOptions الرسمية مأخوذة من JSON Android المحلي وplist iOS الرسمية، ومطابقة لتطبيقي Console في cit-learn-dc483 وcom.devmind.cit.learn يوم26 أكتوبر. المفاتيح فيها public client configuration وليست Admin credentials. التهيئة الصريحة تجعل إضافة Google Services Gradle plugin أو نسخ plist إلى Runner غير لازمة هنا. Manifest يملك INTERNET، وInfo.plist يملك reversed URL scheme؛ بقي minSdk24 وiOS15. لا FCM/Analytics/Firestore أو IAM/ملكية أو أسرار خدمة أضيفت.

CocoaPods احتاج pod install --repo-update لفهرس محلي قديم؛ حلت Pods بنجاح. ظهر تنبيه profile base config المعتاد (Release.xcconfig يشمل Pods release) وتنبيه إيقاف إصدارات Firebase عبر CocoaPods مستقبلاً؛ لم نغيّر تقنية الحزم أو SDK خارج الشريحة. Android أصدر تحذير KGP المستقبلي لحزم Firebase لكنه بُني بنجاح. لا dependency override أو تعديل cache packages.

## التحقق المنفذ

- fvm flutter pub get --enforce-lockfile: ناجح.
- fvm dart format --output=none --set-exit-if-changed lib test integration_test tool: ناجح.
- fvm flutter analyze: بلا ملاحظات.
- fvm dart run tool/architecture_rules.dart: ناجح.
- python3 tool/verify_generated.py: التوليد الحتمي ناجح.
- python3 -m unittest discover -s test/tool -p '*_test.py' -v:7 ناجحة.
- fvm flutter test --reporter expanded:575 ناجحة بعد آخر تغييرات الهوية، منها14 حالة Firebase (تبادل/استعادة/مزود خاطئ/رمز ناقص/حساب مختلف/إلغاء/خروج جزئي/إعداد قابل لإعادة المحاولة/allowlist profile).
- iOS debug simulator: بناء التطبيق العادي ناجح نهائياً (ios-build-final.log).
- Android debug ARM32 وARM64: بناء نهائي ناجح (android-build-final.log)؛ لا تثبيت جهاز أو قياس2GB أو release.
- integration_test/firebase_initialization_test.dart على iPhone Duo / iOS27.1 simulator:1 ناجح؛ التهيئة الرسمية تعمل دون نسخ plist. لا إنشاء مستخدم أو تغيير حساب أو طباعة رموز في الاختبار.
- SQL الكامل شُغّل في PGlite0.5.12 مع citext:6حقول، فصل المعرفين، UNIQUE لكليهما، CHECK للفراغ، وحسابات قديمة NULL. ليست قاعدة إنتاج أو اختبار تزامن متعدد الاتصالات. لإعادة الفحص: npm install --prefix /tmp/hasobjy-firebase-sql-check @electric-sql/pglite@0.5.12 ثم PGLITE_MODULE_ROOT=/tmp/hasobjy-firebase-sql-check/node_modules/@electric-sql/pglite node reports/firebase-auth-2026-10-26/validate-identity-schema.mjs.

سجلات المحاولات الأولى توثق تصحيح mock tests وفهرس CocoaPods وخطأ linker أثناء البناء الأول؛ النجاح النهائي يحدد من flutter-tests.log وnative-initialization.log وios-build-final.log، ولا تُعد محاولة فاشلة دليلاً على فشل النتيجة النهائية إن نجح البديل الموثق.

## الباقي وحدود القبول

ربط API وحفظ المستخدم إنتاجياً مؤجلان وفق طلب المالك حتى تسليم BE-AUTH-FIREBASE. لا endpoint مخمن أو نجاح backend محلي، ولا جلسة/دور/استحقاق/ربط جهاز من Firebase وحدها. يلزم Backend Admin SDK verifyIdToken/checkRevoked والمشروع/المزود، ثم Google UID موثوق وترحيل ذرّي وعقد الجلسة والجهاز و401/403/409/422/429 وrefresh/logout.

دخولGoogle بحساب فعلي على Android/iOS، بصماتrelease/Play والتوقيع وملكية حساب المنصة وأجهزةAPI24/2GB وiOS15 وprofile/release والحجم/البدء/الذاكرة لم تثبت بهذه الفحوص. لا واجهة عُدلت أو مطابقة Figma جديدة أو DRM أو جاهزية نشر.

[مهمة Backend](https://app.notion.com/p/401921ef52a98069924adeeea40a446a) — [التنسيق](https://app.notion.com/p/3fb921ef52a98054914bf51b7fda3f85) — [مهمة Google](https://app.notion.com/p/3fc921ef52a980469fd2ff5dc8495131).

المراجع الرسمية: [تدفق Google/Firebase](https://firebase.google.com/docs/auth/flutter/federated-auth)، [تحقق الخادم](https://firebase.google.com/docs/auth/admin/verify-id-tokens).

دليل مرئي لتسليم Notion: [الصورة](notion-google-handoff.png). الحالة In Progress بقيت لمهمة Google، وTODO لمهمةBackend؛ لا أُغلقت مهمة الشريك أو ادعي إقراره. بصمة APK النهائي SHA256: f0b560fbf2d1c181f99ded169cb4b88368e0d37d61bf1c763882702fa497bf1e.
