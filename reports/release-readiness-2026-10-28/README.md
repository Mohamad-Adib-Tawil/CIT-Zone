# مراجعة جاهزية Hasobjy — 2026-10-28

المراجع: Mohamad Adib Tawil مع Codex. النطاق: Notion وAPI وFigma وFirebase وفحوص Flutter؛ مراجعة دون تنفيذ ميزات أو نشر. أصل التحليل والتصميم وSQL لمسار Mohammad Mokhmaljy مع Claude محفوظ. تغييرات checkout السابقة ليست منسوبة إلى هذه الجولة.

## النتيجة

**غير جاهز للنشر.** أخطاء خادم حية في الإعدادات والجلسة، ولا تسليم BE-AUTH-FIREBASE أو جلسة Hasobjy/كتالوج إنتاجي مربوط في Flutter. الإشعارات والوسائط المحمية والتوقيع وقبول الأجهزة تبقى بوابات مستقلة.

## Notion: القراءة الحية

موصل Notion أعاد404 للمهمة والتنسيق؛ تمت القراءة من Brave المسجل بدلاً منه، بما فيها أسفل الصفحات المحملة تدريجياً. هذا فحص الصفحات المرتبطة ولوحة المشروع، وليس تدقيق كل صفحة ومرفق في المساحة أو تحديد تاريخ إنشاء مستند غير مؤرخ.

- [التنسيق](https://app.notion.com/p/3fb921ef52a98054914bf51b7fda3f85): أحدث اعتماد ظاهر26 أكتوبر Google→Firebase→API؛ لا تسليم Backend أحدث أو إقرار Claude ظاهر.
- [مهمة عقد Backend](https://app.notion.com/p/401921ef52a98069924adeeea40a446a): TODO، Mohammad Mokhmaljy. اعتماد BE-AUTH-FIREBASE26 أكتوبر موجود؛ مقترح body ما زال تحت المراجعة، ولا response DTO أو commit/بيئة اختبار/قبول موثق جديد ظاهر.
- [سياسة الإصدار الخادمية](https://app.notion.com/p/401921ef52a9803da95dca4cba51fe68): TODO؛ latest/minimum وقرار السماح/التحديث لم تسلّم هنا.
- [Google](https://app.notion.com/p/3fc921ef52a980469fd2ff5dc8495131): In Progress؛ تسليم Flutter26 أكتوبر مع بوابات Backend وrelease والحساب الفعلي باقية.
- [Student API](https://app.notion.com/p/3fe921ef52a9812cacd8d6f615c1ed9a): In Review؛ قائمة طرق ومسارات ووظائف، وليست عقد JSON كامل. وصف Google ID token الأقدم يقرأ مع اعتماد Firebase26 أكتوبر الذي تجاوزه.
- [التوصيف التفصيلي للقاعدة](https://app.notion.com/p/404921ef52a9815ea1f8eae28bdad808): ظهر في اللوحة بحالة Done، دون assignee/date. يوثق76 جدولاً/630حقلاً/141علاقة ويذكر Neon؛ لم نتحقق من مزود أو مخطط الإنتاج. يتضمن بند v_lesson_completion شرط مشاهدة مقابل مدة مع التمارين، خلاف القاعدة المعتمدة بأن الإكمال بالتمارين دون شرط مشاهدة (D27 يترك الدرس بلا تمارين مفتوحاً). يذكر lessons.is_free_preview خلاف تقييد المعاينة أول N منشورة، وافتراضي pass_mark60 خلاف عدم افتراض حد عام. يحتوي أيضاً بنوداً غير مؤشرة للجهاز والهاتف. يلزم توفيق الوثيقة مع القرارات والمخطط الفعلي قبل اعتماد التنفيذ؛ لم نغير سياسة أو SQL أو المصدر.

## API: نتائج فعلية

الهدف https://hasobjy-system-api.vercel.app/api/v1. تفاصيل UTC والترويسات وrequestId محفوظة في api-probe.json وapi-recheck.json. الجولة الأولى12طلبGET: اثنان200 وعشرة500؛ ليست نسبة توافر أو اختبار تحميل. الإعادة3طلبات بترويسات X-Device-Id اصطناعي وX-Platform وX-App-Version: health200، config500، session-state500.

- GET health:200، status=ok وdatabase=up.
- GET app/config:500 INTERNAL، حتى مع android/ios والنسخة؛ يمنع قراءة بوابة الإعدادات وسياسة الإصدار.
- GET legal/terms:200 لكن version=0 وbody فارغ وpublishedAt=null؛ لا شروط منشورة في هذه الاستجابة.
- GET me/session-state وacademic/departments وme/registration-summary وme/device وme/device-change-requests/current:500 دون هوية. session-state أعاد500 أيضاً مع Bearer اصطناعي غير صالح؛ لم نحصل على رفض مصادقة سليم في هذه العينة.
- GET openapi.json:500؛ لا يثبت غياب توثيق في مسار آخر.

السبب الجذري غير معروف: يلزم من مالك Backend فحص سجلات Vercel حسب requestId. مثال إعادة config:19ae1ec6-63a6-48d8-9f94-0fef206855d9، session:5ba1e1a5-5823-4ed5-a34a-ee7ee72dcd0d. لم تتوفر شيفرة/سجلات الخادم في هذا checkout. لا نجزم بخلل قاعدة أو Firebase من رسالة INTERNAL العامة. النتائج تختلف عن لقطة24 أكتوبر المحلية التي سجلت config200 والمحمي401.

لم نرسل رمز مستخدم أو بيانات شخصية، ولم ننفذ POST/PUT/DELETE أو دفعاً أو إنشاء مستخدم. لا حساب اختبار أو عقد جلسة مثبت متاح؛ نجاح الدخول والتجديد والإبطال والجهاز والصلاحيات والمدفوعات والوسائط لم يختبر. رفض الوصول أو health لا يعوض اختبارات النجاح والعزل.

## Figma

جلب MCP حي لصفحات الطالب1:4 و1:5 و68:2 و69:2 و80:2 و85:2 و91:2:97إطاراً مباشراً. node IDs والأسماء مطابقة لجرد24 أكتوبر (لا إضافات/حذف/تسمية مختلفة). هذا لا ينفي تغييرات داخل الطبقات أو الأصول؛ لم نفحص كل خاصية لكل إطار.

F02 في80:113 و198:9601: حفظت الصورتان الحاليتان390×844، ومقارنة pixels متطابقة (figma-F02-comparison.json). التكرار ليس فرقاً بصرياً حالياً؛ يبقى اختيار العقدة المرجعية لدى صاحب التصميم. لا A-S02 أو B-S02 ضمن الجرد. لم نعد تشغيل كل شاشة ومقارنة Flutter بصرياً، فلا اعتماد مطابقة شاملة أو قبول responsive جديد.

## Firebase والمنصات والكود

قراءة Console الحية: cit-learn-dc483، Android/iOS com.devmind.cit.learn، Google Enabled، قائمة Authentication Users خالية، FCMv1 Enabled. لا مفاتيح ولا شهادات APNs للتطوير أو الإنتاج. Team ID وApp Store ID غير محددين في إعداد iOS المعروض. حساب جلسة Console وبريد الدعم شخصيان ظاهران؛ لا يثبت ذلك ملكية/IAM أو إدارة حساب المنصة المخصص، ولم نغيرهما.

الكود المحلي يهيئ Firebase ويستخدم firebase_auth خلف data، لكن app_router يوجه الهوية إلى googleIdentity؛ لا تبادل API أو جلسة Hasobjy في المسار. createStudentPreviewCubit يستخدم DemoStudentRepository تحت حراسة debug فقط. لا firebase_messaging في pubspec، ولا aps-environment في entitlements، وandroid/key.properties غائب. عقود playback/downloads ليست مشغل DRM أو أوفلاين مقبولاً.

## التحقق المحلي الحالي

- Flutter3.47.2 عبر FVM؛ pub get --enforce-lockfile ناجح.
- format155ملفاً بلا تغيير، analyze بلا ملاحظات،575اختبارFlutter ناجحاً.
- حدود البنية ناجحة،7اختبارات أدوات ناجحة، توليد حتمي3ملفات ناجح.
- السجلات المنفصلة في هذا المجلد. لم يعد بناءAndroid/iOS أو توقيعrelease أو تشغيل جهاز حقيقي/محاكي أو قياس2GB أو دفع/DRM/FCM حي اليوم. نتائج البناء26 أكتوبر تاريخية وليست فحوص هذه الجولة.

## ترتيب إزالة الموانع

1. Mokhmaljy/Backend: تشخيص500بالسجلات وإصلاح config/auth middleware والمسارات المتأثرة، ثم إعادة GET واختبارات401/403 الصحيحة؛ نشر الشروط المعتمدة.
2. تسليم BE-AUTH-FIREBASE وعقد session/device/refresh/logout واختبارات نجاح ورفض وعزل وحساب اختبار آمن؛ توفيق توصيف البيانات مع القرارات.
3. Tawil/Flutter: ربط الجلسة والتوجيه ثم المجموعات الحقيقية، مع استكمال FCM/APNs والوسائط حسب العقود والقرارات.
4. توقيعrelease/OAuth وتوزيع داخلي، قبول أجهزة ضعيفة وحقيقية ومقارنات بصرية وخصوصية ومتاجر قبل النشر العام.

ملفات هذه الجولة: هذا التقرير وJSON والفحوص والصورتان في reports/release-readiness-2026-10-28، ولوحة ملخص خارج المستودع. لا تعديل شيفرة التطبيق أو حالات مهام الطرف الآخر، ولا commit/push/نشر.
