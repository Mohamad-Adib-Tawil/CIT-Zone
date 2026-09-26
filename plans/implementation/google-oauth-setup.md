# إعداد Google Sign-In الفعلي

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
