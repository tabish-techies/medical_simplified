import 'package:flutter/material.dart';
import '../placeholder_tab_view.dart';

class SyllabusTab extends StatelessWidget {
  const SyllabusTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderTabView(
      title: 'Syllabus Empty',
      subtitle: 'No syllabus content available at the moment.',
      icon: Icons.assignment_outlined,
    );
  }
}
