# بطاقة مهمة — توقيع Android للإصدار

- **القسم والخطة:** أساس التطبيق والهوية، `plans/features/01-foundation.md` و`plans/features/02-identity-devices.md`.
- **هدف المستخدم:** لا تُنتج نسخة Android قابلة للتوزيع بمفتاح debug؛ يستخدم صاحب المنتج مفتاح رفع خاصاً، وتُستخرج بصمته لإعداد Google OAuth بعد توفره.
- **داخل النطاق:** إعداد Gradle لتوقيع release من `android/key.properties` المحلي، منع بناء release إذا غابت البيانات، مثال ملف بلا أسرار، توثيق الإعداد. **خارج النطاق:** توليد مفتاح حقيقي، إنشاء حساب Play Console، نشر التطبيق أو تحديد مفتاح توقيع Google Play.
- **القرار:** معرّف Android `com.devmind.cit.learn` موثق في `plans/09-decisions.md`. نوع الخادم وGoogle Cloud Project ID ما زالا معلقين. مفتاح الرفع يملكه صاحب المنتج؛ لا يُنشأ مفتاح إنتاج افتراضي.
- **الأدوار والرفض:** لا أثر في أدوار التطبيق. بناء release يرفض التوقيع بمفتاح debug أو ملف ناقص، ولا يطبع كلمات المرور.
- **الكيانات والقيود:** ملف خصائص محلي بأربعة حقول (`storeFile`, `storePassword`, `keyAlias`, `keyPassword`) ومسار keystore موجود. استمرارية تحديث التطبيق تتطلب حفظ المفتاح؛ لا تتعامل مع debug كشهادة إصدار.
- **عقد API:** لا تغيير في API. عميل Google OAuth Android يحتاج بصمة شهادة التطبيق الموزع؛ تُحدد لاحقاً حسب Play App Signing أو قناة التوزيع.
- **الحالات:** debug يبني، release بلا مفتاح يفشل برسالة إعداد واضحة، release بمفتاح صحيح يبني ويتحقق من التوقيع.
- **الملفات:** `android/app/build.gradle.kts`، `.gitignore`، `android/key.properties.example`، `.github/workflows/flutter-ci.yml`، `plans/implementation/google-oauth-setup.md`، هذه البطاقة. لا تغييرات iOS أو Flutter.
- **الاختبارات:** `flutter pub get --enforce-lockfile`، format/analyze/test، بناء Android debug، محاولة release بلا ملف محلي للتحقق من الرفض، وبناء release بمفتاح تجريبي مؤقت ثم حذف ملفاته. بناء إصدار التوزيع النهائي بمفتاح مالك المنتج ما زال معلقاً.
- **الأداء/المراقبة:** لا أثر في أداء التطبيق؛ أثر في مسار البناء فقط.
- **القبول:** لا يوجد `signingConfigs.debug` في release؛ لا تدخل كلمات مرور أو keystore إلى Git؛ debug مستمر؛ release لا يبنى دون إعداد خاص.

## إعداد صاحب المنتج

1. أنشئ مفتاح رفع Android خاصاً واحفظه خارج المستودع مع نسخة احتياطية آمنة. لا تستخدم مفتاح `~/.android/debug.keystore`.
2. انسخ `android/key.properties.example` إلى `android/key.properties`، واستبدل مسار المفتاح والكلمات السرية والاسم المستعار بالقيم الصحيحة. يُفسر المسار النسبي بدءاً من مجلد `android/`، ويُقبل المسار المطلق.
3. شغّل `fvm flutter build appbundle --release`. إذا غاب حقل أو ملف المفتاح، يفشل Gradle قبل إنشاء الإصدار. ملف الخصائص وملفات `.jks`/`.keystore` داخل `android/` مستثناة من Git.
4. سجل بصمة شهادة الرفع وبصمة Play App Signing التي تصل للمستخدم في إعداد Google OAuth بحسب قناة التوزيع. لا تنسخ كلمات السر إلى أوامر البناء أو الوثائق.

يراجع هذا الإجراء [دليل Flutter لتوقيع Android](https://docs.flutter.dev/deployment/android) و[دليل Android لمفاتيح الرفع والتوزيع](https://developer.android.com/studio/publish/app-signing).
