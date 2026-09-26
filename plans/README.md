# خطط CIT Zone

هذه الوثائق هي مواصفات بدء التنفيذ لتطبيق تعليمي لطلاب معهد الحاسوب. توجد الآن معاينتا طالب وإدارة داخل Flutter، ولا توجد خدمة خلفية أو بيانات مواد معتمدة. الوثائق تميّز بين **متطلب مؤكد** و**اقتراح تصميم** و**قرار معلق** كي لا يتحول الافتراض إلى سلوك منشور.

## ترتيب القراءة

| الملف | الغرض |
| --- | --- |
| [01-product.md](01-product.md) | النطاق، المستخدمون، الرحلات، وسياسات المنتج |
| [02-architecture.md](02-architecture.md) | حدود Flutter والخادم، الطبقات، وهيكل الملفات |
| [03-curriculum-content.md](03-curriculum-content.md) | الأقسام والسنوات والفصول ونموذج المحتوى |
| [04-auth-security.md](04-auth-security.md) | Google والدور الإداري وربط الجهاز والتفويض |
| [05-media-offline.md](05-media-offline.md) | الفيديو والمرفقات والتشغيل والتنزيل المحمي |
| [06-admin-api.md](06-admin-api.md) | لوحة الإدارة داخل التطبيق وعقود API |
| [07-roadmap.md](07-roadmap.md) | المراحل، الأولويات، التبعيات، ومعايير إنجاز كل مرحلة |
| [08-quality.md](08-quality.md) | الاختبارات والأداء والمراقبة والإطلاق |
| [09-decisions.md](09-decisions.md) | القرارات المعلقة وسجل الافتراضات |
| [admin-dashboard/README.md](admin-dashboard/README.md) | خطة التصميم الكامل للوحة الإدارة داخل Flutter |
| [features/README.md](features/README.md) | دليل التنفيذ التفصيلي لكل قسم، ترتيب التبعيات، وبوابات التسليم |
| [implementation/google-oauth-setup.md](implementation/google-oauth-setup.md) | إعداد معرفات Google OAuth للعميل قبل ربط خادم API |
| [implementation/2026-09-26-pre-backend-status.md](implementation/2026-09-26-pre-backend-status.md) | حالة معاينتي الطالب والإدارة وتسجيل Google قبل الخادم |
| [implementation/2026-09-26-api-foundation.md](implementation/2026-09-26-api-foundation.md) | شريحة أساس الاتصال وتصنيف الأخطاء قبل تثبيت API |
| [implementation/2026-09-26-android-release-signing.md](implementation/2026-09-26-android-release-signing.md) | إعداد توقيع Android للإصدار دون مفتاح debug |
| [curricula/software.md](curricula/software.md) | قالب منهج قسم البرمجيات حسب السنة والفصل |
| [curricula/networks.md](curricula/networks.md) | قالب منهج قسم الشبكات حسب السنة والفصل |
| [future/README.md](future/README.md) | تقسيم الميزات المؤجلة إلى خطط مستقلة |

## حقائق ثابتة من الطلب

- فئتا المستخدمين: طالب وإدارة، ولا يوجد حساب أستاذ مستقل الآن.
- تسجيل الطالب عبر Google. الحساب مقيّد بجهاز نشط واحد.
- عرض المواد حسب السنة والفصل والقسم، مع إمكان ظهور المادة نفسها في أكثر من موضع.
- لكل مادة دورة واحدة وأستاذ واحد في النسخة الأولى؛ الإدارة تدير المحتوى.
- الدرس الأول من الدورة مجاني للتعريف بها، وبقية المحتوى حسب الاستحقاق.
- فيديوهات ودروس ومرفقات، وتنزيل فيديو للتشغيل داخل التطبيق دون إنترنت مع أقصى حماية عملية.
- لوحة إدارة داخل تطبيق Flutter، وليست موقع ويب.
- ملف شخصي؛ المنشورات/المقالات وأسئلة الدورات توسعات لاحقة.

## طريقة استعمال الخطط

ابدأ بالمراحل في `07-roadmap.md` ثم افتح [خطة القسم](features/README.md) و[عقد التنفيذ](features/00-execution-contract.md). لا تبدأ العمل على مرحلة قبل حسم قراراتها المانعة في `09-decisions.md`. كل تغيير في المتطلبات ينعكس أولاً في الملف المختص ثم في معايير القبول. لا تُنشئ قائمة مواد حقيقية أو أسعاراً أو آلية دفع دون بيانات معتمدة من صاحب المنتج.

## مصادر تقنية راجعتها الخطة بتاريخ 2026-09-26

- [Cloudflare Stream: تأمين البث والروابط الموقعة](https://developers.cloudflare.com/stream/viewing-videos/securing-your-stream/)
- [Cloudflare Stream: تنزيل MP4](https://developers.cloudflare.com/stream/viewing-videos/download-videos/)
- [Android Media3: رخص Widevine دون اتصال](https://developer.android.com/reference/androidx/media3/exoplayer/drm/OfflineLicenseHelper)
- [Apple: تشغيل وتخزين HLS دون اتصال](https://developer.apple.com/documentation/avfoundation/offline-playback-and-storage)
- [Apple: FairPlay Streaming](https://developer.apple.com/streaming/fps/FairPlayStreamingOverview.pdf)
- [Android: Play Integrity](https://developer.android.com/google/play/integrity/overview)
- [Apple: App Attest](https://developer.apple.com/documentation/DeviceCheck)

تحقق من الوثائق والأسعار وقدرات المزودين مجدداً عند التنفيذ؛ هذه التفاصيل قابلة للتغير.
