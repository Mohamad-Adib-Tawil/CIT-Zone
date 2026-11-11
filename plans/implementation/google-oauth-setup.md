# إعداد Google عبر Firebase Authentication

## توقيع Android وربط شهادة الرفع — 2026-11-09

أُنشئ مفتاح رفع Android محلي للحزمة `com.devmind.cit.learn`، وسُجّلت بصمتا شهادته SHA-1 وSHA-256 في تطبيق Android المسجل في Firebase `cit-learn-dc483`. بقيت بصمات التطوير المسجلة. حُدّث `android/app/google-services.json` من Firebase وتحققنا من مطابقته للمشروع والحزمة واحتوائه على بصمة OAuth لشهادة الرفع. تهيئة التطبيق الفعلية تستمر عبر `FirebaseOptions` الحالية.

ملف المفتاح في مجلد توقيع خاص خارج المستودع، و`android/key.properties` مستثنى من Git. يحتاج مالك التطبيق إلى حفظ نسخة احتياطية آمنة من المفتاح وكلمة مروره. إذا كان للحزمة سجل رفع سابق في Play، تحقق من مطابقة شهادة الرفع في Play Console. عند تفعيل Play App Signing، أضف بصمات شهادة التوقيع التي يوزّع بها Play التطبيق إلى Firebase قبل اختبار Google من قناة الاختبار الداخلي.

نجح بناء `app-release.aab` للإصدار `1.0.0+1` بحجم 75.3 MB. نجح `jarsigner -verify` وتطابقت بصمتا شهادة الحزمة مع Firebase. أعاد الفحص الحي للإعدادات والجلسة HTTP 500. اختبار دخول Google بحساب فعلي من الحزمة الموزعة وربط جلسة Hasobjy ما زالا مطلوبين. لا توجد هوية توقيع iOS صالحة محلياً.

## الإعداد المعتمد — 2026-10-26

حل اعتماد Google→Firebase→API محل التدفق المباشر التاريخي أدناه. Firebase Auth Google مفعل حياً في cit-learn-dc483، وتحققت IDs للنظامين من Console، وقورنت iOS plist الرسمية المنزلة وAndroid JSON المحلي. التهيئة تستخدم FirebaseOptions صريحة في `lib/features/auth/data/hasobjy_firebase_configuration.dart`، ثم FirebaseAuth.signInWithCredential. لذلك لا نحتاج Google Services Gradle plugin أو نسخ plist إلى Runner لهذا الأسلوب؛ AndroidManifest يملك INTERNET وInfo.plist يملك reversed URL scheme مسبقاً، وبقي Podfile iOS15/minSdk24. Native plugin registrants وPodfile.lock تحدث بأدوات Flutter/CocoaPods عند البناء.

الحزم firebase_core5.1.0 وfirebase_auth7.0.1 أضيفت إلى pubspec/lock. لا Analytics/FCM/Firestore أو Admin key. GoogleSignInConfiguration ما زال يحمل OAuth client IDs العامة؛ Firebase token يختلف عن Google token. الملف الجاهز للعرض لا يحمل أياً منهما، وprepareForBackend ينتج إثباتاً حديثاً مؤقتاً في data ويتحقق من Firebase UID المتوقع قبل/بعد التجديد.

Firebase SDK يدير استعادة جلسة هويته على المنصة؛ reload مطلوب قبل اعتبارها جاهزة. لا تتحول إلى جلسة محتوى أو جهاز Hasobjy. عند الخروج نحاول Firebase وGoogle حتى إن أخفق أحدهما؛ إبطال جلسة API يضاف بعقده لاحقاً.

إعداد Google Cloud/OAuth قائم وGoogle Enabled؛ لا scopes إضافية أو تغيير IAM. بصمات release/Play وشهادة iOS/App Store واختبار حساب حقيقي على جهاز تبقى مطلوبة للإطلاق. [خطة التنفيذ والعقد والباقي](2026-10-26-firebase-google-auth.md).

## سجل الإعداد السابق (تاريخي، استُبدل في26 أكتوبر)


## تحقق حديث — 2026-10-24

قرئت Console الحية للمشروع `cit-learn-dc483`: التطبيقان Android/iOS بالحزمة `com.devmind.cit.learn` وGoogle Enabled. يوجد JSON Android محلي مطابق؛ لا Firebase SDK مهيأ في التطبيق. مزود Google في Console لا يجعل هوية Google جلسة Hasobjy، ولا يفرض تبديل Google ID token إلى Firebase ID token دون عقد Backend.

FCM HTTP v1 Enabled، لكن لا APNs development/production key أو certificate، ولا firebase_core/firebase_messaging أو إعداد منصة push في الكود الحالي. شريحة الإشعارات وملفاتها وقبول release في [خطة النشر P3](2026-10-24-publication-readiness.md). الملاحظات التالية سجل الإعداد المباشر السابق؛ عدم احتياج plist/JSON لذلك التدفق لا ينطبق على تكامل FlutterFire القادم. لم تُختبر جلسة Google release أو شهادة المتجر اليوم.

يستخدم التطبيق حزمة `google_sign_in` مباشرة. سُجلت تطبيقات Android وiOS وفُعّل مزود Google في Firebase project `cit-learn-dc483` بتاريخ 2026-09-26. تُعد معرفات OAuth التالية معرفات عامة للتطبيق وليست أسراراً:

| الاستخدام | OAuth client ID |
| --- | --- |
| الخادم/الجمهور المطلوب لرمز ID token | `637124336690-ckb8c62mu855i8219nfjv5l4pnu9ob4i.apps.googleusercontent.com` |
| تطبيق iOS | `637124336690-q31nv9rdo829dilk6n9d785kvafplhtp.apps.googleusercontent.com` |
| iOS reversed URL scheme | `com.googleusercontent.apps.637124336690-q31nv9rdo829dilk6n9d785kvafplhtp` |

## إعداد المشروع والمنصات

- Android application ID وiOS bundle ID: `com.devmind.cit.learn`.
- أضيفت بصمتا شهادة debug SHA-1 وSHA-256 إلى تطبيق Android المسجل في Firebase. لم تُضف بصمات إصدار المتجر بعد.
- Web client ID مضبوط كقيمة افتراضية في `GoogleSignInConfiguration.serverClientId`، ويمكن تجاوزه عبر `--dart-define=GOOGLE_SERVER_CLIENT_ID=...`.
- iOS client ID مضبوط افتراضياً عبر `--dart-define` الافتراضي في Dart، وreversed URL scheme مضبوط في `ios/Flutter/Debug.xcconfig` و`Release.xcconfig`.
- لا يلزم `google-services.json` أو `GoogleService-Info.plist` في المستودع لأن Flutter يستخدم `google_sign_in` مباشرة ولا يهيئ Firebase SDK. ملفات الإعداد التي تنشئها Firebase ليست مطلوبة لهذا التدفق.

تشغيل Android:

```sh
fvm flutter run -d <android-device>
```

تشغيل iOS:

```sh
fvm flutter run -d <ios-device>
```

## الحدود الأمنية

يطلب التطبيق Google ID token ويتأكد من وجوده في الذاكرة ثم يعرض هوية Google مؤقتة. لا يحفظ الرمز ولا يسجله ولا يمنح دوراً أو جلسة CIT Zone. قبل فتح المحتوى المحمي، يجب أن يتحقق خادم API الخاص من توقيع الرمز و`aud` و`iss` و`exp` و`sub`، ثم ينشئ جلسة التطبيق ويطبق الدور وربط الجهاز الواحد. لا يُستخدم Firebase Auth حالياً كجلسة التطبيق.

يجب تسجيل SHA-1 وSHA-256 لشهادة إصدار الإنتاج في Firebase قبل اختبار نسخة release. إذا كان التوزيع عبر Google Play App Signing، أضف بصمة شهادة Play App Signing كذلك. استخدم [توثيق Firebase الرسمي لإعداد Google Sign-In](https://firebase.google.com/docs/auth/flutter/federated-auth) و[توثيق الحزمة](https://pub.dev/packages/google_sign_in) عند ترقية SDK.
