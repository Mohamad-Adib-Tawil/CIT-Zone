# Google عبر Firebase — 2026-10-26

المسؤول Flutter: Mohamad Adib Tawil مع Codex؛ Backend: Mohammad Mokhmaljy مع Claude Code.

## خطة التنفيذ

1. قراءة التنسيق ومهمة Backend؛ تحديث Notion أولاً باعتماد BE-AUTH-FIREBASE (تمت القراءة والحفظ عبر Brave؛ MCP404). آخر تحديث مقروء تذكير25 أكتوبر، ولا تسليم Claude أحدث ظاهر.
2. اعتماد Firebase Authentication مع Google Cloud project `cit-learn-dc483`؛ Google provider مفعل حياً26 أكتوبر. إضافة firebase_core وfirebase_auth فقط إلى pubspec ثم قفل الحل؛ لا Messaging/Analytics.
3. Google credential → Firebase Auth → هوية بلا أسرار للعرض. تهيئة Firebase كسولة داخل data مع إعداد Android/iOS الرسمي؛ استعادة Firebase user مع reload والتحقق من google.com، وخروج المزودين.
4. تجهيز Firebase ID token حديث وبيانات Google في data عبر عقد مستقل. لا رمز في Cubit/Router/السجلات أو قاعدة محلية. لا إرسال تلقائي قبل تسليم method/path/request/response/device/error contract؛ endpoint القديم لا يفترض أنه يقبل الرمز الجديد.
5. تحديث التصميم المحلي للبيانات دون نشره، وتكليف Backend بالـmigration والتحقق والإبطال والتزامن وإصدار جلسة Hasobjy.
6. اختبار التحويل والاستعادة والفشل والخروج وانفصال id_google/firebase_uid وتجهيز الطلب، ثم format/analyze/test وبناء Android ARM32/64 وiOS simulator عند توفر الأدوات.

## عقد الهوية

`id_google` هو Google provider UID، و`firebase_uid` هو Firebase user UID (أي sub لرمز Firebase)، و`users.id` داخلي مستقل. الاسم والبريد والصورة والتحقق من البريد متاحة وفق المزود؛ given/family/locale اختيارية إن وفرها مصدر موثوق. لا هاتف/ميلاد/جنس/عنوان مفترض، ولا scopes إضافية أو People API. locale الحالية في users لغة التطبيق وتختلف عن google_locale.

مقترح تسليم فقط: `{firebase_id_token, google_profile:{id_google,firebase_uid,email,email_verified,display_name,photo_url}}`. الخادم يتجاهل الهوية المدعاة ويستخرجها من Firebase Admin؛ لا يربط حسابين بالبريد. يحفظ profile موثوقاً فقط، مع upsert ذري وقيود فريدة. الجدول المحلي الأصلي يستعمل oauth_identities.provider_subject وليس google_sub؛ يراجع Backend مخططه الفعلي عند الترحيل.

## الملفات والحالات

ملفات auth/domain للهوية فقط، auth/data لبوابة Google/Firebase وإعدادها وتجهيز الإثبات، DI لتسجيل بوابة Firebase الجديدة، pubspec/lock، إعدادات native اللازمة، اختبارات auth/architecture. تعديل amendments ثم build.py يعيد SQL/ERD/القاموس. الخطط04/09/10/13/ميزة02 وعقد التنفيذ والتنسيق تُحدث بالتغيير المحدود.

الحالات: إلغاء Google، نقص الرمز، فشل Firebase/الشبكة/الإعداد، حساب غير Google/معطل، استعادة بلا حساب، خروج أحد المزودين يفشل، token حديث لا يخص الحساب المتوقع. لا نجاح API محلي أو صلاحيات أو ربط جهاز. الشكل الحالي بلا تعديل؛ لا عمل بصري جديد ولا ادعاء مطابقة Figma.

## تسليم Backend

[المهمة القائمة](https://app.notion.com/p/401921ef52a98069924adeeea40a446a) محفوظة على Mohammad Mokhmaljy وTODO لحين بدء عمله. أضيف اعتماد26 أكتوبر دون محو السابق. يلزم Firebase Admin verifyIdToken مع checkRevoked والتحقق من project/iss/aud/exp/google.com ثم استخراج Google UID من هوية موثوقة؛ توثيق auth/session-state/refresh/logout/device وإصدار جلسة Hasobjy واختبارات الرفض والتزامن. أسرار الخدمة في الخادم فقط.

## أثر الأداء والقبول

التهيئة عند أول استخدام auth، لا DB/PDF/FCM/Analytics. Firebase SDK يدير جلسة هويته وفق Keychain/التخزين الأصلي؛ لا نخزن رموزه يدوياً. اتصال Firebase وتحديث الهوية مطلوبان؛ لا استعادة تمنح محتوى دون API. يبقى API24/iOS15؛ الحجم والبدء والذاكرة على أجهزة2GB/profile/release بحاجة قياس حقيقي، ونجاح المحاكي لا يثبتهما. لا DRM ضمن الشريحة.

القبول المستقل: Google يوقع عبر Firebase، بيانات صحيحة وتمييز المعرفات، رمز Firebase جاهز عبر data فقط، استعادة/خروج واختبارات رفض ناجحة؛ ربط API ومزامنة users إنتاجياً يبقيان معلقين حتى تسليم Backend، بتوجيه المستخدم.

## نتيجة التنفيذ

نُفّذ المستقل وفق هذه الخطة؛575 اختبارFlutter و7اختبارات أدوات، تحليل/تنسيق/بنية/توليد حتمي وفحصSQL محلي ناجحة. بُني Android ARM32/64 وiOS simulator، ونجح اختبار تهيئةFirebase الأصلي على iOS27.1. [التقرير والملفات وحدود القبول](../../reports/firebase-auth-2026-10-26/README.md). ربطAPI/حفظusers إنتاجياً ودخولGoogle بحساب فعلي وتوقيعrelease/قياساتالأجهزة ما زالت غير مثبتة؛ لا تغيير لشكل الواجهة.
