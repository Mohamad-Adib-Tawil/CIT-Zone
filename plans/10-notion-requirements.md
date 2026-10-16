# 10 — متطلبات Hasobjy المنقولة من Notion

**الاعتماد والنقل المحلي:** 2026-10-15. هذا الملف وخطط الميزات وقاعدة البيانات يدمجون محتوى مساحة Hasobjy، بصرف النظر عن حالات سير المراجعة. [فهرس النسخة الأصلية](../docs/notion/README.md) يحفظ الصفحات والمرفقات والتصدير كما وصل.

## ترتيب المرجعية

تعليمات صاحب المنتج الأحدث أولاً، ثم المتطلبات المعتمدة في Notion. إذا تعارضت صفحات المصدر نثبت الفرق في D26 وما بعده، ولا تختار تفاصيل المنتج آلياً. النسخة الخام سجل مصدر لا تعدل لتوافق الخطة؛ التفاصيل المطبقة محلياً أدناه. أسماء وتقنيات Figma المعتمدة في D25 تبقى نافذة.

## النطاق الكامل

منصة واحدة لمعهد حلب، برنامج سنتين × فصلين، قسمان و28 مادة فريدة كتوصيف يحتاج قائمة رسمية. كتالوج مفتوح، كورسات تقنية مستقلة، Google وجهاز نشط واحد، ويب إدارة مستقل، دفع مادة/فصل/كورس، DRM/أوفلاين، PDF، تمارين، علامات/OCR، إعلانات وإشعارات، دعم، وقت وتقدم، تدقيق وإعدادات وإصدارات. لا Teacher Role أو ترتيب طلاب أو دعم لحظي. تعدد دورات/مدرسي المادة غير محسوم ولا يفرض قيد واحد من الخطة القديمة.

## قصص المستخدم ومعايير القبول المحلية

النصوص غير المتعارضة من قصص المصدر محفوظة هنا، وصيغ التعارض استبدلت صراحة بالتوضيح المعتمد الأحدث. معايير API والمنصات والاختبارات المفصلة في خطة الميزة المرتبطة.

## E1

### US-1.1 — تسجيل الدخول عبر Google

**بصفتي** طالباً جديداً **أريد** تسجيل الدخول بحساب Google فقط **حتى** أبدأ دون رقم هاتف أو رمز تحقق.

- [ ]  لا يوجد خيار تسجيل بالبريد/كلمة مرور أو الهاتف.
- [ ]  عند أول دخول يُنشأ الحساب وينتقل إلى نموذج إكمال الملف.
- [ ]  عند الدخول اللاحق يدخل مباشرة إلى الصفحة الرئيسية.

الخطة: [features/02-identity-devices.md](features/02-identity-devices.md). البيانات: `users, oauth_identities, student_profiles, student_term_enrollments, transcript_submissions`.

### US-1.2 — إكمال الملف الشخصي

الاسم والقسم والسنة (1 أو 2) والفصل إلزامية للمسار الأكاديمي. لا يدخل الطالب علاماته أو رسوبه ذاتياً؛ التفصيل المحدّث في تحليل النظام ألغى ذلك. يرفع الطالب القديم كشفاً رسمياً للتحقق والإدخال الإداري، بينما مسار الكورسات فقط الظاهر في Figma يحتاج قراراً مستقلاً (D25).

الخطة: [features/02-identity-devices.md](features/02-identity-devices.md). البيانات: `users, oauth_identities, student_profiles, student_term_enrollments, transcript_submissions`.

### US-1.3 — مواد الرسوب والحمل

تظهر مواد الإعادة من علامات معتمدة أدخلتها الإدارة أو كشف طالب قديم راجعته واعتمدته. لا اختيار ذاتي لإثبات الرسوب، ولا منح استحقاق من ملف الطالب. تمييز الإعادة وتذكير الفصل المقبل معتمدان؛ مدة استثناء الوصول والتكميلي D18.

الخطة: [features/02-identity-devices.md](features/02-identity-devices.md). البيانات: `users, oauth_identities, student_profiles, student_term_enrollments, transcript_submissions`.

## E2

### US-2.1 — جهاز واحد فقط

**بصفتي** مالك حساب **أريد** أن يعمل حسابي على جهاز واحد فقط **حتى** لا يُشارَك حسابي مع الآخرين.

- [ ]  محاولة الدخول من جهاز ثانٍ تُرفض برسالة واضحة.
- [ ]  لا يوجد استبدال تلقائي للجهاز.

الخطة: [features/02-identity-devices.md](features/02-identity-devices.md). البيانات: `devices, auth_sessions, device_change_requests, security_events`.

### US-2.2 — طلب تغيير الجهاز

**بصفتي** طالباً غيّرت هاتفي **أريد** طلب اعتماد جهاز جديد من الدعم **حتى** أستعيد الوصول.

- [ ]  أُرسل طلباً من التطبيق مع سبب التغيير.
- [ ]  يعتمد المسؤول الطلب يدوياً، فيُفعَّل الجهاز الجديد ويُعطَّل القديم.
- [ ]  أتلقى إشعاراً بالنتيجة.

الخطة: [features/02-identity-devices.md](features/02-identity-devices.md). البيانات: `devices, auth_sessions, device_change_requests, security_events`.

### US-2.3 — حماية المحتوى

الفيديو مشفر برخصة DRM للبث والتنزيل الداخلي ولا يصدر كملف واضح. منع الالتقاط/التسجيل يختبر بحسب قدرات المنصة، دون ضمان مطلق. PDF الأكاديمي مجاني قابل للتنزيل؛ PDF الكورس غير قابل للتصدير، مع عرض داخلي أو تخزين مشفر للأوفلاين حسب سياسة الحاوية، وصلاحية يحددها الخادم.

الخطة: [features/02-identity-devices.md](features/02-identity-devices.md). البيانات: `devices, auth_sessions, device_change_requests, security_events`.

## E3

### US-3.1 — تصفّح موادي

«مواد فصلي» توصية، و«كل المواد» يعرض كل المنشور في جميع الأقسام والسنوات والفصول. يمكن الاشتراك بأي مادة، حتى مادة نجح بها الطالب أو من قسم آخر. لا حجب بالمسار أو التقدم. مواد الإعادة المعتمدة مميزة، ولا تغير المرشحات هوية الطالب الأكاديمية.

الخطة: [features/04-courses-lessons.md](features/04-courses-lessons.md). البيانات: `learning_containers, subjects, courses, lessons, video_assets, pdf_documents, pdf_versions, lesson_ratings`.

### US-3.2 — مشاهدة درس

**بصفتي** طالباً **أريد** مشغّل فيديو بتحكم كامل **حتى** أتعلم بالسرعة المناسبة لي.

- [ ]  تسريع وإبطاء السرعة، وتقديم وإرجاع، وإعادة.
- [ ]  يُحفظ موضع المشاهدة وأتابع من حيث توقفت.

الخطة: [features/04-courses-lessons.md](features/04-courses-lessons.md). البيانات: `learning_containers, subjects, courses, lessons, video_assets, pdf_documents, pdf_versions, lesson_ratings`.

### US-3.3 — الفيديو الأول مجاناً

افتراض المعاينة درس واحد لكل قائمة/حاوية منشورة، ويمكن للإدارة زيادة free_preview_count إلى N. أول N دروس منشورة حسب الترتيب هي المعاينة؛ لا is_free_preview حر يترك للعميل. شروط تمارين المعاينة D22. عند تغيير الترتيب/العدد تراجع الرخص وواجهة العرض وتدقيق النشر.

الخطة: [features/04-courses-lessons.md](features/04-courses-lessons.md). البيانات: `learning_containers, subjects, courses, lessons, video_assets, pdf_documents, pdf_versions, lesson_ratings`.

### US-3.4 — ملفات PDF

**بصفتي** طالباً **أريد** الوصول إلى ملفات المواد (كاملة وحسب الجلسة) **حتى** أراجع بسهولة.

- [ ]  ملفات المواد مجانية للجميع.
- [ ]  يظهر إصدار الملف وتاريخ آخر تحديث.

الخطة: [features/04-courses-lessons.md](features/04-courses-lessons.md). البيانات: `learning_containers, subjects, courses, lessons, video_assets, pdf_documents, pdf_versions, lesson_ratings`.

### US-3.5 — تقييم الدرس

**بصفتي** طالباً **أريد** تقييم كل درس بخمس نجوم **حتى** تتحسن جودة المحتوى.

- [ ]  تقييم واحد لكل طالب لكل درس، قابل للتعديل.
- [ ]  لا توجد لوحة ترتيب للطلاب (مرفوضة).

---

الخطة: [features/04-courses-lessons.md](features/04-courses-lessons.md). البيانات: `learning_containers, subjects, courses, lessons, video_assets, pdf_documents, pdf_versions, lesson_ratings`.

## E4

### US-4.1 — أسئلة الاختيار من متعدد

**بصفتي** طالباً **أريد** حل أسئلة اختيار من متعدد تُصحَّح تلقائياً **حتى** أعرف مستواي فوراً.

- [ ]  تظهر النتيجة والإجابة الصحيحة مع الشرح بعد الإرسال.
- [ ]  لكل سؤال خيار صحيح واحد على الأقل.

الخطة: [features/14-exercises-ratings.md](features/14-exercises-ratings.md). البيانات: `exercises, mcq_options, exercise_attempts, code_submissions, ai_evaluations`.

### US-4.2 — تمارين كتابة الكود

**بصفتي** طالباً **أريد** كتابة كود وإرساله للتقييم **حتى** أعرف أين خطئي.

- [ ]  يُقيَّم الكود بواسطة Gemini API (وليس مُترجماً).
- [ ]  يحدد التقييم موضع الخطأ وسببه بدقة.
- [ ]  تُحفظ محاولاتي وتقييماتها.

---

الخطة: [features/14-exercises-ratings.md](features/14-exercises-ratings.md). البيانات: `exercises, mcq_options, exercise_attempts, code_submissions, ai_evaluations`.

## E5

### US-5.1 — اشتراك بمادة

**بصفتي** طالباً **أريد** الاشتراك بمادة واحدة لفصل **حتى** أدفع فقط ما أحتاجه.

- [ ]  يفتح الاشتراك كل فيديوهات المادة لذلك الفصل.
- [ ]  ينتهي عند نهاية الفصل مع استثناء المواد الراسبة/المحمّلة.

الخطة: [features/06-entitlements.md](features/06-entitlements.md). البيانات: `products, product_prices, payments, entitlements, vouchers, product_bundle_subjects`.

### US-5.2 — اشتراك بفصل كامل

**بصفتي** طالباً **أريد** الاشتراك بفصل كامل **حتى** أفتح كل موادّه بسعر أفضل.

- [ ]  تُفتح كل مواد قسمي وسنتي في ذلك الفصل.
- [ ]  ينتهي عند نهاية الفصل مع الاستثناء نفسه للمواد الراسبة.

الخطة: [features/06-entitlements.md](features/06-entitlements.md). البيانات: `products, product_prices, payments, entitlements, vouchers, product_bundle_subjects`.

### US-5.3 — الدفع عبر ShamCash

**بصفتي** طالباً **أريد** الدفع من داخل التطبيق عبر ShamCash **حتى** يُفتح المحتوى فوراً.

- [ ]  يتحقق النظام من العملية عبر API ويفعّل الصلاحية تلقائياً.
- [ ]  عند الفشل أو انتهاء المهلة تُعرض رسالة وخيارات بديلة.

الخطة: [features/06-entitlements.md](features/06-entitlements.md). البيانات: `products, product_prices, payments, entitlements, vouchers, product_bundle_subjects`.

### US-5.4 — الدفع اليدوي برمز QR

**بصفتي** طالباً لم ينجح الدفع الآلي معه **أريد** الدفع عبر QR ورفع الإيصال **حتى** يراجعه الدعم.

- [ ]  أرفع صورة الإيصال مع رقم العملية والمبلغ.
- [ ]  تظهر حالة الطلب: قيد المراجعة / مقبول / مرفوض مع السبب.

الخطة: [features/06-entitlements.md](features/06-entitlements.md). البيانات: `products, product_prices, payments, entitlements, vouchers, product_bundle_subjects`.

### US-5.5 — قسيمة مطبوعة

**بصفتي** طالباً **أريد** شراء قسيمة من المكتبة ومسح رمزها **حتى** أفعّل اشتراكي دون دفع إلكتروني.

- [ ]  يُمسح رمز QR داخل التطبيق فيُفعَّل المنتج المرتبط بالقسيمة.
- [ ]  لا يمكن استخدام القسيمة أكثر من مرة أو بعد إلغائها.

الخطة: [features/06-entitlements.md](features/06-entitlements.md). البيانات: `products, product_prices, payments, entitlements, vouchers, product_bundle_subjects`.

### US-5.6 — الكورسات

الكورسات مستقلة عن السنة والقسم والفصل وعن التقدم الأكاديمي. لكل كورس اشتراك ومدة/سياسة دوام صريحة قبل النشر التجاري، ومعاينة أول N (افتراض 1). PDF الكورس محمي لا يصدر خارج التطبيق، ويجوز تخزينه مشفراً داخله للأوفلاين وفق السياسة. استقبال حلول تمارين الكورسات مؤجل؛ يظهر المحتوى النظري للتمارين دون تقديم حلول حالياً.

الخطة: [features/06-entitlements.md](features/06-entitlements.md). البيانات: `products, product_prices, payments, entitlements, vouchers, product_bundle_subjects`.

## E6

### US-6.1 — تحميل للمشاهدة بلا إنترنت

ينزل الطالب المحتوى المسموح وقت الاتصال: فيديو مشفر برخصة DRM، وPDF أكاديمي مجاني، وPDF كورس مشفر داخلياً عند تفعيل سياسته. يستطيع حذف فيديو واحد/كل التنزيلات من الإعدادات. الخادم مصدر وقت الانتهاء؛ DRM يمنع التشغيل بعده باستخدام وقت موثوق، ويُنظف الكاش عند أول تشغيل/اتصال يسمح بالحذف. لا يمكن مسح هاتف غير متصل عن بعد لحظياً. التمارين والدفع والدعم وتحديث العلامات والإعلانات الجديدة تحتاج اتصالاً.

الخطة: [features/07-offline-downloads.md](features/07-offline-downloads.md). البيانات: `video_license_requests, offline_video_downloads, protected_pdf_licenses, offline_pdf_downloads, device_time_syncs`.

## E7

### US-7.1 — مزامنة العلامات الرسمية

المصدر الحالي صور جماعية ترفعها الإدارة، ثم OCR كمسودة، مطابقة بمعرف أكاديمي، مراجعة واعتماد. لا تكامل API مباشر مع الجامعة معتمد. تعرض العملي والنظري والمجموع والجلسة العادية/التكميلية. أوزان 60/40 أو 70/30 أو 100/0؛ حد النجاح 50 أو 60 لكل مادة مستقلاً عن الوزن، بعد اعتماد مصفوفة رسمية. لا يطبق الوزن مرتين على درجات موزونة مسبقاً؛ الغياب حالة منفصلة. حساب التراكمي واختيار محاولة الإعادة D18.

الخطة: [features/13-grades-ocr.md](features/13-grades-ocr.md). البيانات: `grade_import_batches, grade_import_rows, grades, grading_schemes, grade_revisions, transcript_submissions`.

### US-7.2 — طباعة كشف علاماتي

**بصفتي** طالباً **أريد** زر «طباعة كشف علاماتي» بعد نهاية الفصل **حتى** أحصل على PDF.

- [ ]  جدول بكل المواد وعلاماتها وصف مجموع نهائي.

الخطة: [features/13-grades-ocr.md](features/13-grades-ocr.md). البيانات: `grade_import_batches, grade_import_rows, grades, grading_schemes, grade_revisions, transcript_submissions`.

### US-7.3 — رفع كشف العلامات (حل مؤقت)

قناة انتقالية للطلاب القدامى المؤهلين إدارياً فقط: صورة/PDF رسمي خاص، قبول/رفض مع السبب والمراجع. الإدارة تتحقق وتدخل العلامات؛ لا نشر مباشر بمجرد الرفع أو من إدخال الطالب. لا يطلع طالب على صورة النتائج الجماعية أو وثيقة طالب آخر.

الخطة: [features/13-grades-ocr.md](features/13-grades-ocr.md). البيانات: `grade_import_batches, grade_import_rows, grades, grading_schemes, grade_revisions, transcript_submissions`.

## E8

### US-8.1 — إعلانات الجامعة

**بصفتي** طالباً **أريد** قسم إعلانات يعكس إعلانات الجامعة **حتى** لا يفوتني شيء.

- [ ]  إعلانات مثبّتة وأخرى بتاريخ انتهاء، مع مرفقات.

الخطة: [features/15-announcements-support-reports.md](features/15-announcements-support-reports.md). البيانات: `announcements, notification_templates, notifications, notification_recipients, exam_schedules`.

### US-8.2 — الإشعارات

**بصفتي** طالباً **أريد** إشعارات تنبيهية بسيطة (قالب أو قالبان فقط) **حتى** أتذكر المهم.

- [ ]  تذكير بالامتحانات يُرسَل يدوياً من المسؤول.
- [ ]  تذكير تلقائي بالمواد المحمّلة قبل الفصل المقبل.
- [ ]  إشعار بقرب بداية ونهاية الفصل وانتهاء الاشتراك.
- [ ]  يمكن تمييز المقروء من غير المقروء.

---

الخطة: [features/15-announcements-support-reports.md](features/15-announcements-support-reports.md). البيانات: `announcements, notification_templates, notifications, notification_recipients, exam_schedules`.

## E9

### US-9.1 — مراسلة الدعم

**بصفتي** طالباً **أريد** زر دعم داخل التطبيق **حتى** أراسل الإدارة بمشكلتي.

- [ ]  مراسلة غير لحظية، مع إمكانية إرفاق صور.
- [ ]  حالة المحادثة: مفتوحة / قيد المعالجة / محلولة.

الخطة: [features/15-announcements-support-reports.md](features/15-announcements-support-reports.md). البيانات: `support_conversations, support_messages, usage_sessions, exercise_attempts, grades`.

### US-9.2 — تقرير وقتي الأسبوعي

تقرير وقت أسبوعي في الملف من usage_sessions مع تجميع خادمي ومقاومة التكرار. لا تساوي مدة البقاء مدة تعلم. تعريف بداية الأسبوع والمنطقة الزمنية والعبور بين أسابيع/نشاط الخلفية D22؛ v_weekly_activity_inputs يعرض المدخلات إلى أن يعتمد التجميع النهائي.

الخطة: [features/15-announcements-support-reports.md](features/15-announcements-support-reports.md). البيانات: `support_conversations, support_messages, usage_sessions, exercise_attempts, grades`.

### US-9.3 — نسبة التقدم

إكمال الدرس الأكاديمي باجتياز تمارينه المنشورة دون شرط مشاهدة نسبة فيديو. تقدم المادة = الدروس المكتملة ÷ الدروس المنشورة المؤهلة. التقدم العام = المواد الناجحة ضمن خطة قسم الطالب ÷ إجمالي مواد خطته؛ مواد الأقسام الأخرى والكورسات التقنية لا تدخل فيه. النسب مشتقة، لا حقول يكتبها الطالب. حالة درس بلا تمارين والتعامل مع الإعادة/نسخ المنهج تحتاج قراراً؛ NULL يدل على عدم حسم السياسة ولا يعرض كـ0 مزيف.

الخطة: [features/15-announcements-support-reports.md](features/15-announcements-support-reports.md). البيانات: `support_conversations, support_messages, usage_sessions, exercise_attempts, grades`.

## E10

### US-10.1 — إدارة المحتوى

**بصفتي** مسؤولاً **أريد** رفع الدروس والملفات والأسئلة وتنظيمها **حتى** يبقى المحتوى محدّثاً.

- [ ]  إدارة المواد والجلسات والفيديوهات وإصدارات ملفات PDF.
- [ ]  أنشر وأخفي وأرتّب بدون حذف السجلات التاريخية.

الخطة: [features/09-admin-content.md](features/09-admin-content.md). البيانات: `admin_accounts, admin_audit_logs, app_settings, feature_flags, app_versions`.

### US-10.2 — إدارة الفصول والمنهج

**بصفتي** مسؤولاً **أريد** تحديد تواريخ بداية الفصول ونهايتها ومنهج كل قسم **حتى** تعمل الإشعارات وقفل الوصول تلقائياً.

الخطة: [features/09-admin-content.md](features/09-admin-content.md). البيانات: `admin_accounts, admin_audit_logs, app_settings, feature_flags, app_versions`.

### US-10.3 — إدارة المدفوعات

**بصفتي** مسؤولاً **أريد** مراجعة الإيصالات اليدوية ومنح اشتراكات استثنائية **حتى** أعالج الحالات الخاصة.

- [ ]  قبول/رفض الإيصال مع تسجيل السبب والمراجع.
- [ ]  منح يدوي مع سبب إلزامي.
- [ ]  إنشاء دفعات قسائم لنقاط بيع وتتبّع المستخدَم منها.

الخطة: [features/09-admin-content.md](features/09-admin-content.md). البيانات: `admin_accounts, admin_audit_logs, app_settings, feature_flags, app_versions`.

### US-10.4 — إدارة الأجهزة والطلاب

**بصفتي** مسؤولاً **أريد** اعتماد طلبات تغيير الجهاز وإدارة حسابات الطلاب **حتى** أضبط الأمان.

الخطة: [features/09-admin-content.md](features/09-admin-content.md). البيانات: `admin_accounts, admin_audit_logs, app_settings, feature_flags, app_versions`.

### US-10.5 — استيراد العلامات

**بصفتي** مسؤولاً **أريد** رفع صورة جدول العلامات وتحويلها عبر OCR ومراجعتها **حتى** تُسجَّل علامات الطلاب بدقة.

- [ ]  ربط أسطر الاستيراد بالطلاب مع مستوى الثقة، ومراجعة غير المطابقة يدوياً.
- [ ]  لا تُعتمد العلامات قبل المراجعة.

الخطة: [features/09-admin-content.md](features/09-admin-content.md). البيانات: `admin_accounts, admin_audit_logs, app_settings, feature_flags, app_versions`.

### US-10.6 — الإشعارات والإعلانات والدعم

**بصفتي** مسؤولاً **أريد** نشر الإعلانات وإرسال الإشعارات والرد على الدعم **حتى** أتواصل مع الطلاب.

الخطة: [features/09-admin-content.md](features/09-admin-content.md). البيانات: `admin_accounts, admin_audit_logs, app_settings, feature_flags, app_versions`.

### US-10.7 — التدقيق والإعدادات

**بصفتي** مسؤولاً **أريد** سجل تدقيق لكل إجراء إداري ومفاتيح تفعيل للميزات **حتى** أتتبع التغييرات وأتحكم بالإصدارات.

- [ ]  فرض تحديث التطبيق عند الحاجة.

---

الخطة: [features/09-admin-content.md](features/09-admin-content.md). البيانات: `admin_accounts, admin_audit_logs, app_settings, feature_flags, app_versions`.

## تغطية المصادر الأخرى

- تحليل النظام: حرية الشراء حتى بعد النجاح، PDF الأكاديمي ومساهمات الطلاب، المعاينة، التايم لاين، استثناء الإعادة، استقلال الكورسات، حماية PDF، وحدود الأوفلاين. دمج في الخطط 01/03/05/06/13/14/15 وD26.
- تعديلات الخطة: العلامات من صور لوحة الإدارة؛ المواد ترشيح؛ أسئلة استثناء الرسوب والتكميلي؛ عدم حسم عدد دورات/مدرسي المادة.
- SQL وERD: جميع جداول الوحدات A–I محفوظة محلياً. النسخة الخام في database/source؛ المخطط المحلي المعدل في database/schema.sql، ومعه قاموس ومخططات 9 وحدات.
- تدقيق قاعدة البيانات ومهمة العلامات: نطاق سنة 1..2، حد نجاح صريح، نظام علامات بإصدار، رخصة مشفرة، معاينة N، ومراجعة OCR ونسخ تعديلات العلامة.
- صور التغذية البصرية الست: محفوظة دون تعديل مع روابطها في صفحة المصدر. المرجع البصري الأحدث للطالب هو D25/Figma، ولا تستنتج سياسة أمنية أو مالية من صورة.
- مهام UI/API/Web/Flutter والتصوير: محفوظة بحالاتها كما صدرت، وروابطها موجودة في فهرس المصادر. لا نعتبر حالة Done في Notion دليلاً على ربط خدمة في الكود المحلي.
- صفحتا Untitled بلا متطلبات: محفوظتان في الأرشيف ولا نختلق لهما نطاقاً.

## بوابات القبول والقرارات

كل US أعلاه له مصدر وقاعدة وخطة وكيانات. تنفيذ API أو تطبيق الطالب أو لوحة الويب غير مطلوب في مهمة النقل هذه. اختبار SQL المحلي يثبت بناء المخطط وقيوداً محددة فقط؛ التفويض والتزامن في خادم الإنتاج وDRM والأجهزة لا تزال بوابات مستقلة. التراكمي والوقت الأسبوعي النهائي واستثناء الرسوب وتعدد دورات المادة تحتاج القرارات D18/D22/D23/D26؛ لا تعرض Views المدخلات بوصفها مؤشرات نهائية.

**عدد القصص المنقولة:** 35. مصدر القصص: [Notion](https://app.notion.com/p/3f8921ef52a981aabc61d1179a3a9e4b).
