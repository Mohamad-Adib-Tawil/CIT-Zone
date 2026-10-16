# دليل المهندس — حاسوبجي / Hasobjy

تحديث 2026-10-16. هذا دليل سريع للمراجع المعتمدة؛ لا يكرر سياسات المنتج أو يحوّل خطة إلى تنفيذ.

## ما المشروع؟

تطبيق تعليمي لطلاب معهد الحاسوب في حلب وكورسات تقنية مستقلة. البرنامج الأكاديمي سنتان وقسمان؛ الكتالوج مفتوح بعد Google، والمسار ترشيح. لكل نوع محتوى سياسة منفصلة: فيديو باشتراك/معاينة، PDF أكاديمي مجاني قابل للتنزيل، PDF كورس محمي. العلامات من مراجعة إدارية بعد OCR، والتقدم الأكاديمي مشتق من الخطة والتمارين لا من وقت الفيديو.

## أين أبدأ؟

- الدور والقيود: [AGENTS](../AGENTS.md) وقواعد `.cursor/rules/`.
- المتطلبات والقصص: [المنتج](../plans/01-product.md)، [Notion الموحّد](../plans/10-notion-requirements.md)، [قرارات المنتج والهندسة](../plans/09-decisions.md).
- بنية Flutter والخادم: [02](../plans/02-architecture.md) و[12](../plans/12-engineering-foundation.md).
- التبعيات وحالة تفعيلها: [13](../plans/13-packages.md)، `pubspec.yaml` و`pubspec.lock`.
- الهواتف القديمة/الضعيفة والقياس: [14](../plans/14-low-end-devices.md).
- الوسائط والتشفير: [05](../plans/05-media-offline.md)، [تشغيل](../plans/features/05-playback-attachments.md)، [أوفلاين](../plans/features/07-offline-downloads.md).
- التصميم: [العقد 11](../plans/11-design-implementation-contract.md)، لا تنفيذ بصري دون إطار فعلي وأدلة مقارنة.
- البيانات: [database](../database/README.md)؛ مصدر SQL/ERD/القاموس موحد التوليد، ولا قاعدة إنتاج متصلة حالياً.
- التنفيذ: [خارطة المراحل](../plans/07-roadmap.md) و[بطاقة المهمة](../plans/features/00-execution-contract.md).

## الحالة التشغيلية

FND-07 جهز أداة قياس Android واختباراتها7/7 ودليلها دون API أو تغيير واجهة؛ قياسات debug/emulator مصنفة تشخيصية فقط. [التقرير](../reports/performance/foundation-2026-10-16/README.md) و[الأوامر](performance/README.md). فتحت صفحة تنسيق Notion ومهمة Flutter عبر Brave وسجلت التسليم؛ لا تغيير لمسار Claude.

FND-06:154 اختباراً و3 تكاملات لكل من Android API36 وiOS27؛ guard قابل للتشغيل لحدود Clean Architecture/DI وCI للتوليد الحتمي والأدلة. فعّل gen_l10n/ARB للعربية في مدخل التطبيق/Google/onboarding (104 نصوص)؛22 صورة متطابقة قبل/بعد. معاينات الطالب/الإدارة القديمة ما زالت تحتاج استخراج نصوصها. لا دليل أداء2GB/DRM أو جلسة خادم. [أحدث تقرير](../reports/engineering-foundation/quality-2026-10-16/README.md).

FND-03/04/05 أكملت النقل المستقل عبر Dio/ApiClient، وجهزت adapters التخزين الآمن وDrift المعزول ومخططه المحلي الأول وعقود الوسائط. لا جلسة خادم أو تنزيل إنتاجي أو SDK DRM. التخزين غير مربوط بتدفق Google، وعقود الوسائط بلا تنفيذ مزود. النتائج الأخيرة: 145 اختباراً و3 تكامل iOS، وبناء Android للـABI المستهدفين؛ بوابات أجهزة 2GB وDRM/backup والاستعادة الفعلية غير منفذة. [التقرير الأخير](../reports/engineering-foundation/transport-storage-2026-10-16/README.md).

FND-02 فعّل تركيباً scoped بـget_it وconstructor injection وgo_router للمسارات القائمة. شريحة هوية Google: `Cubit → GoogleIdentityRepository → GoogleIdentityRepositoryImpl → GoogleIdentityGateway`، وResult typed يفصل نجاح/فشل domain عن استثناء SDK؛ `core/network/ApiFailure` يبقى داخل عقد النقل. لا جلسة خادم من Google ولا شاشات إنتاج جديدة. [حالة التنفيذ والملفات والأدلة](../reports/engineering-foundation/architecture-2026-10-16/README.md).

الموجود معاينات Flutter وهوية Google من جهة العميل وأساس اتصال API. الحزم أضيفت للتحضير؛ ليس هناك تنفيذ إنتاجي لاشتراكات/تنزيل مشفر/خادم. Android 7/API 24 وiOS 15 حدّا البيئة الحاليان؛ اعتماد هاتف معين أو DRM أو أداء منخفض يحتاج اختباراً حقيقياً. لا ترفع النظام أو Flutter تلقائياً عند مشكلة حزمة.

## أوامر العمل

```sh
fvm flutter pub get --enforce-lockfile
fvm dart format --output=none --set-exit-if-changed lib test
fvm flutter analyze
fvm flutter test
fvm flutter build apk --debug --target-platform android-arm,android-arm64 --split-per-abi
fvm flutter build ios --simulator --debug --no-codesign
```

بناء release يحتاج إعداد توقيع المشروع؛ قياس الأداء profile/release على هاتف حقيقي. البناء debug أو simulator لا يثبت DRM أو أمان Keychain أو فهرس تنزيل يعمل؛ التقارير تسجل ما اختبر فعلياً فقط.
