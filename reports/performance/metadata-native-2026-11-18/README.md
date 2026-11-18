# قبول التخزين الأصلي لكاش الطالب — 2026-11-18

المصدر: شجرة العمل فوق `6600dc9` مع تغييرات الكاش المحلية؛ Flutter 3.47.2. الاختبار `integration_test/student_metadata_restart_test.dart` يشغّل مخزني الملف والرئيسية بإعدادات `SecureSessionSecretStore.platformStorage` الفعلية، دون mock. مفاتيح الاختبار وبياناته اصطناعية ومعزولة؛ لا دخول Firebase أو جلسة طالب حية أو اتصال API.

## Android

- المحاكي المعزول `Hasobjy16k`، serial `emulator-5578`، API 36، ARM64، RAM مضبوطة 2GB، و`getconf PAGE_SIZE` أعاد 16384. هذه بيئة محاكي وليست هاتفاً ضعيفاً فعلياً.
- نجحت مرحلة write: حفظ الملف لحسابي اختبار والرئيسية لأحدهما ثم قراءتها عبر إضافة التخزين الأصلية.
- نُفذ `adb shell am force-stop com.devmind.cit.learn`، ولم يعرض `pidof` عملية للتطبيق بعدها. بقي التطبيق مثبتاً؛ لم نستخدم `pm clear` أو uninstall بين المرحلتين.
- نجحت مرحلة read من تشغيل ثانٍ: استعادة البيانات وتواريخ UTC، عزل الحساب وبيئة التخزين، حذف نسخة حساب دون حذف الآخر، وتنظيف مفاتيح الاختبار. [سجل الحفظ](android-write.log) و[سجل القراءة](android-read.log).
- أغلق المحاكي الذي أنشأته هذه الجولة بعد الاختبار. لا تغيير لمحاكي مستخدم آخر.

الأوامر، مع مسار Flutter المثبت في المشروع:

```sh
.fvm/flutter_sdk/bin/flutter test integration_test/student_metadata_restart_test.dart -d emulator-5578 --no-uninstall --dart-define=HASOBJY_METADATA_RESTART_PHASE=write --reporter expanded
adb -s emulator-5578 shell am force-stop com.devmind.cit.learn
adb -s emulator-5578 shell 'pidof com.devmind.cit.learn || true'
.fvm/flutter_sdk/bin/flutter test integration_test/student_metadata_restart_test.dart -d emulator-5578 --no-uninstall --dart-define=HASOBJY_METADATA_RESTART_PHASE=read --reporter expanded
```

المحاولة التشخيصية الأولى دون `--no-uninstall` نجحت في الحفظ وفشلت في الاستعادة: مشغّل Flutter يحذف تطبيق الاختبار افتراضياً بعد نهايته. تحقق `pm path`/`run-as` من غياب الحزمة، ورُوجع خيار uninstall في مصدر Flutter المثبت. أُعيد الاختبار بالخيار الصحيح ونجحت المرحلتان. هذا فشل في إعداد تجربة الاستمرار، ولا يثبت عيباً في التخزين. لا تُستعمل إعادة تثبيت تمسح البيانات كاختبار لإعادة تشغيل التطبيق.

## iOS

- أُنشئ محاكي مؤقت مستقل `HasobjyMetadataAudit` من نوع iPhone 18 Pro، iOS 27.2 build 24B8117، ARM64، UUID `F780F1A1-F1D2-495D-9B5C-4BFE519172A0`. لم يُستخدم محاكي المستخدم المفتوح.
- نجحت مرحلتا write وread باستخدام الإضافة الأصلية وإعدادات Keychain الحالية. انتهت عملية مرحلة write؛ أكد `simctl terminate` عدم وجود عملية ليُنهيها، وأكد `get_app_container` بقاء التطبيق مثبتاً. أعاد تشغيل read البيانات بنجاح، ثم تحقق من العزل والمسح ونظف مفاتيح الاختبار. [سجل الحفظ](ios-write.log) و[سجل القراءة](ios-read.log).
- استُخدم الأمر نفسه أعلاه مع `-d F780F1A1-F1D2-495D-9B5C-4BFE519172A0` وخياري المرحلتين و`--no-uninstall`. بعد التحقق أُغلق محاكي الاختبار المؤقت وأزيل وحده، دون مساس بمحاكي المستخدم.

## حدود القبول

هذا إثبات تكامل مع التخزين الأصلي واستمرار البيانات عبر عمليتين على محاكيي Android وiOS؛ نجحت أربعة تشغيلات، اختبار واحد في كل مرحلة/منصة. لا يثبت رحلة استعادة جلسة خادمية، أو عرض الرئيسية بعد دخول طالب فعلي، أو TTI/سلاسة/ذاكرة هاتف ضعيف، أو سلامة شاملة للتشفير، أو DRM، أو النشر. ظل تحذير FlutterFire/KGP ظاهراً في بناء Android. لم تتغير الحزم أو إعدادات المنصة أو الحد الأدنى للنظام. بصمات المصادر في [source.json](source.json).
