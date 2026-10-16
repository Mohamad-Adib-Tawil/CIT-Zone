# قياس الأداء قبل الخادم

المرجع [الخطة14](../../plans/14-low-end-devices.md). الأداة [benchmark_android.py](../../tool/benchmark_android.py) تقيس **إطلاق Android Activity البارد** و**PSS لشاشة المدخل بعد انتظار محدد**، ولا تقيس زمن أول تفاعل Flutter أو الكتالوج أو وقت استجابة API. لا تعتبر TotalTime هدف بدء3ثوانٍ محققاً؛ يحتاج TTI قياساً مستقلاً على البناء والجهاز المرجعيين.

## التشغيل

ثبّت APK الذي تريد قياسه بأوامر FVM المعتادة، ثم حدد serial والجهاز وAPK نفسه صراحة. التوقيع الإنتاجي يبقى شرط البناء الموجود؛ لا تعطله للحصول على رقم. مثال بعد بناء/تثبيت profile على جهاز حقيقي مصرح:

```sh
fvm flutter run --profile -d DEVICE_SERIAL --no-resident
python3 tool/benchmark_android.py \
  --serial DEVICE_SERIAL \
  --package com.devmind.cit.learn \
  --apk build/app/outputs/flutter-apk/app-profile.apk \
  --mode profile --runs 10 --settle-seconds 5 \
  --network 'Describe the actual connection and shaping' \
  --output reports/performance/DEVICE-DATE-profile.json
```

استخدم مسار APK الناتج الفعلي، و`--adb /path/to/adb` إن لم يكن adb في PATH. الأداة لا تبني أو تنزل أدوات أو تثبت APK؛ تقارن بصمة APK المحلية بالمثبتة، وتتحقق من تعارضات debug/release/profile الواضحة. البناء المصرح profile/release ليس attestation؛ وثق أمر البناء ومصدره. split APK installations تحتاج inventory مستقلاً، وترفضها هذه النسخة بدل مقارنة base وحده بحزمة مختلفة.

**الأثر:** الأداة تنفذ force-stop وإعادة فتح للحزمة المحددة لكل عينة؛ لا تستعملها أثناء عملية كتابة. لا clear data أو logout أو حذف ملفات/SDK. تبقى شاشة التطبيق مفتوحة بعد العينة الأخيرة. أغلق أي حالة Google تفاعلية/اختبار integration وأطلق `lib/main.dart` أولاً، ولا تقس test runner بوصفه التطبيق.

## تجربة الأداة على محاكي التطوير

```sh
fvm flutter run -d emulator-5554 --no-resident --no-pub
python3 tool/benchmark_android.py \
  --serial emulator-5554 --package com.devmind.cit.learn \
  --apk build/app/outputs/flutter-apk/app-debug.apk \
  --mode debug --diagnostic --runs 3 --settle-seconds 3 \
  --network 'Emulator default, uncontrolled; no API configured' \
  --output reports/performance/DATE-android-diagnostic.json
```

`--diagnostic` إلزامي للمحاكي/debug أو أقل من10عينات؛ التقرير يسميه diagnostic_only. أي تقرير (حتى مرجعي) يبقى `acceptance_proven=false`؛ أرقام واحدة لا تمنح اعتماد دعم جهاز2GB. لا تستخدم RAM المحاكي بديلاً عن مواصفات جهاز حقيقي.

## ما يسجل وكيف يراجع

- model/API/ABI/RAM ودقة الشاشة ووضع الطاقة، وصمة APK وحجمه وpubspec.lock وFVM وGit HEAD وحالة dirty، ووصف الشبكة اليدوي. serial يختزن SHA256 فقط. لا dumps كاملة أو رموز أو حسابات أو معرف طالب.
- العينات الخام: TotalTime وWaitTime بالـms؛ PSS بالـKiB بعد settle-seconds. Median وp95 nearest-rank بحفظ عدد العينات. افصل build/install عن launch؛ لا تستخدم أزمنة Xcode/Gradle كزمن بدء.
- Status غير ok أو warm launch أو PSS مفقود يفشل ولا يتحول إلى صفر. إذا انقطع الجمع يبقى completed=false والعينات السابقة بلا summary؛ خطأ التهيئة قبل بدء الجمع لا يصنع تقريراً وهمياً. التقرير الموجود لا يكتب فوقه؛ اختر اسماً جديداً.
- لا رفع تلقائياً. راجع التقرير قبل مشاركته؛ وصف network حر، فلا تضع فيه عناوين خاصة أو أسراراً.

## بوابات ما زالت تحتاج بيئة فعلية

1. جهاز Android2GB/ARM32 وAPI24 وجهاز حديث، profile/release، عشر جولات مع ظروف متقاربة وقبل/بعد على الجهاز نفسه؛ نموذج البطارية/الحرارة/الشبكة يسجل يدوياً حتى يثبت مصدر قياسها.
2. TTI فعلي وUI/raster p95 ونسبة الإطارات المتأخرة في سيناريو تمرير كتالوج معتمد؛ PSS بعد استقرار الكتالوج/المشغل/PDF، و20 دورة فتح/إغلاق. الكتالوج الحقيقي والعينات تحتاج API وتصميمها؛ لا تملأ القياسات بميزة fake.
3. iOS15 وجهاز قديم: physical footprint وmemory pressure عبر أدوات Apple. PSS Android لا يتحول إلى footprint iOS، ولم تتوفر أجهزة حقيقية في FND-07.
4. تشغيل/أوفلاين/انتهاء DRM وPDF100صفحة والذاكرة والحرارة والبطارية عند تنفيذ القدرات واعتماد المزود. لا MP4 أو مفتاح ثابت بديل.

أدلة تشغيل الأداة التشخيصية في [تقرير FND-07](../../reports/performance/foundation-2026-10-16/README.md). هذه بوابات قياس وليست سياسة دعم جديدة أو رفع حد النظام.
