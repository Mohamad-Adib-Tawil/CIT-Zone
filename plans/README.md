# خطط CIT Zone

هذه الوثائق هي مواصفات بدء التنفيذ لتطبيق تعليمي لطلاب معهد الحاسوب. توجد الآن معاينتا طالب وإدارة داخل Flutter، ولا توجد خدمة خلفية أو بيانات مواد معتمدة. الوثائق تميّز بين **متطلب مؤكد** و**اقتراح تصميم** و**قرار معلق** كي لا يتحول الافتراض إلى سلوك منشور.

## ترتيب القراءة

| الملف | الغرض |
| --- | --- |
| [00-system-study.md](00-system-study.md) | ملخص النظام والأدوار والمزايا وحالات الاستخدام والقرارات المطلوبة |
| [01-product.md](01-product.md) | النطاق، المستخدمون، الرحلات، وسياسات المنتج |
| [02-architecture.md](02-architecture.md) | حدود Flutter والخادم، الطبقات، وهيكل الملفات |
| [03-curriculum-content.md](03-curriculum-content.md) | الأقسام والسنوات والفصول ونموذج المحتوى |
| [04-auth-security.md](04-auth-security.md) | Google والدور الإداري وربط الجهاز والتفويض |
| [05-media-offline.md](05-media-offline.md) | الفيديو والمرفقات والتشغيل والتنزيل المحمي |
| [06-admin-api.md](06-admin-api.md) | لوحة الويب الإدارية وعقود API |
| [07-roadmap.md](07-roadmap.md) | المراحل، الأولويات، التبعيات، ومعايير إنجاز كل مرحلة |
| [08-quality.md](08-quality.md) | الاختبارات والأداء والمراقبة والإطلاق |
| [09-decisions.md](09-decisions.md) | القرارات المعلقة وسجل الافتراضات |
| [admin-dashboard/README.md](admin-dashboard/README.md) | خطة لوحة الويب الإدارية المستقلة |
| [features/13-grades-ocr.md](features/13-grades-ocr.md) | استيراد العلامات من الصور واعتمادها وكشف PDF |
| [features/14-exercises-ratings.md](features/14-exercises-ratings.md) | MCQ وGemini وتقييم الدروس |
| [features/15-announcements-support-reports.md](features/15-announcements-support-reports.md) | الإعلانات والإشعارات والدعم والوقت الأسبوعي |
| [features/README.md](features/README.md) | دليل التنفيذ التفصيلي لكل قسم، ترتيب التبعيات، وبوابات التسليم |
| [implementation/google-oauth-setup.md](implementation/google-oauth-setup.md) | إعداد معرفات Google OAuth للعميل قبل ربط خادم API |
| [implementation/2026-09-26-pre-backend-status.md](implementation/2026-09-26-pre-backend-status.md) | حالة معاينتي الطالب والإدارة وتسجيل Google قبل الخادم |
| [implementation/2026-09-26-api-foundation.md](implementation/2026-09-26-api-foundation.md) | شريحة أساس الاتصال وتصنيف الأخطاء قبل تثبيت API |
| [implementation/2026-09-26-android-release-signing.md](implementation/2026-09-26-android-release-signing.md) | إعداد توقيع Android للإصدار دون مفتاح debug |
| [curricula/software.md](curricula/software.md) | قالب منهج قسم البرمجيات حسب السنة والفصل |
| [curricula/networks.md](curricula/networks.md) | قالب منهج قسم الشبكات حسب السنة والفصل |
| [future/README.md](future/README.md) | تقسيم الميزات المؤجلة إلى خطط مستقلة |

## النطاق المعتمد في 2026-10-08

- منصة واحدة مستقلة لمعهد الحاسوب في حلب؛ الطالب Flutter والإدارة ويب مستقل متجاوب، وتقنية الويب غير محددة.
- 28 مادة فريدة في القسمين؛ رؤية القسم والمواد المشتركة مفوضة من الخادم، والمواضع الفعلية تنتظر المنهج.
- Google إلزامي، ملف أكاديمي وجهاز نشط واحد ونقل يدوي مفوض عبر الدعم، وصلاحية أدمن واحدة دون Teacher Role.
- PDF كامل/جلسة مجاني، أخبار وإعلانات، وأول فيديو لكل قائمة معتمدة مجاني؛ باقي الفيديو باشتراك مادة/فصل.
- انتهاء الحقوق بنهاية الفصل واستثناء رسوب يحتاج شروطاً معتمدة، ودفع بأولوية ShamCash API إن توفر ثم QR وإيصال، وقسائم خيار محتمل.
- فيديو DRM وتنزيل داخلي مرخص دون تصدير؛ حماية الشاشة تخضع لاختبارات قدرات المنصة ولا تضمن منع التسريب.
- MCQ وGemini للكود دون compiler، تقييمات دروس، إشعارات ودعم غير متزامن ووقت أسبوعي.
- علامات من صور تدخل في لوحة الويب، OCR ثم مراجعة ومطابقة واعتماد وكشف PDF؛ لا مزامنة مباشرة مع الجامعة.

اقرأ سجل [اعتماد المواصفات](09-decisions.md) و[بطاقة تحديث الخطط](implementation/2026-10-08-plan-revision.md). وثائق `implementation/2026-09-26-*` تصف حالة تاريخية ولا تحدد نطاق الإنتاج الجديد. الكود الحالي لم يُرحّل لهذه المواصفات بعد.

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
