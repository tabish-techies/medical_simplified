import 'package:flutter/material.dart';
import '../placeholder_tab_view.dart';

class TestSeriesTab extends StatelessWidget {
  const TestSeriesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderTabView(
      title: 'No Tests Available',
      subtitle: 'You haven\'t enrolled in any test series.',
      icon: Icons.quiz_outlined,
    );
  }
}
