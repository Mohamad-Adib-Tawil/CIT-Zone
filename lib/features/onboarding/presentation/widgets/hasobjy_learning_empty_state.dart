import 'package:flutter/material.dart';

import '../theme/hasobjy_visual_scope.dart';
import 'hasobjy_figma_components.dart';

class HasobjyLearningEmptyState extends StatelessWidget {
  const HasobjyLearningEmptyState.home({super.key, bool coursesOnly = false})
    : title = 'لا يوجد محتوى لعرضه الآن',
      message = coursesOnly
          ? 'ستظهر كورساتك هنا عندما تتوفر.'
          : 'ستظهر موادك وآخر الدروس التي تابعتها هنا عندما تتوفر.',
      darkIcon = 'ba247',
      lightIcon = '6b548';

  const HasobjyLearningEmptyState.subjects({super.key})
    : title = 'لا توجد مواد متاحة',
      message = 'ستظهر هنا مواد الفصل الذي اخترته عند توفرها.',
      darkIcon = 'd7c97',
      lightIcon = 'aa30e';

  const HasobjyLearningEmptyState.lessons({super.key})
    : title = 'لا توجد دروس منشورة',
      message = 'ستظهر دروس هذه المادة هنا عند نشرها.',
      darkIcon = 'd589e',
      lightIcon = 'c18cf';

  const HasobjyLearningEmptyState.courses({
    super.key,
    required bool mine,
    required bool laterPage,
  }) : title = laterPage
           ? 'لا توجد كورسات في هذه الصفحة'
           : mine
           ? 'لا توجد كورسات مشترك بها حالياً'
           : 'لا توجد كورسات متاحة',
       message = laterPage
           ? 'يمكنك الرجوع إلى الصفحة السابقة.'
           : mine
           ? 'ستظهر كورساتك هنا بعد الاشتراك.'
           : 'ستظهر الكورسات هنا عند نشرها.',
       darkIcon = 'e9373',
       lightIcon = '41bff';

  final String title;
  final String message;
  final String darkIcon;
  final String lightIcon;

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          Container(
            width: 80,
            height: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: design.selectedSurface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: HasobjySvg(
              design.isLight ? lightIcon : darkIcon,
              width: 24,
              height: 24,
            ),
          ),
          Text(title, textAlign: TextAlign.center, style: design.title),
          Text(message, textAlign: TextAlign.center, style: design.bodyMedium),
        ],
      ),
    );
  }
}
