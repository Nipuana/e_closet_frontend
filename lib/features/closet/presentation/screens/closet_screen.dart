import 'package:flutter/material.dart';

import '../../../../common/widgets/tab_placeholder.dart';

class ClosetScreen extends StatelessWidget {
  const ClosetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TabPlaceholder(
      eyebrow: 'WARDROBE',
      title: 'Your closet',
      subtitle: 'Every piece you own, quietly catalogued.',
      icon: Icons.checkroom_outlined,
    );
  }
}
