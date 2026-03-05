import 'package:flutter/material.dart';
import 'package:medical_simplified/features/auth/presentation/home/book_store_screen.dart';
import 'package:medical_simplified/features/auth/presentation/courses/courses_screen.dart';
import 'package:medical_simplified/features/auth/presentation/home/syllabus_screen.dart';
import 'package:medical_simplified/features/auth/presentation/home/test_series_screen.dart';
import 'feature_card.dart';

class FeatureGrid extends StatelessWidget {
  const FeatureGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FeatureTile(
          icon: Icons.school_outlined,
          title: 'Courses',
          subtitle: 'Video lectures, practice & concepts',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CoursesScreen()),
          ),
        ),
        const SizedBox(height: 12),
        FeatureTile(
          icon: Icons.assignment_turned_in_outlined,
          title: 'Test Series',
          subtitle: 'Mock exams with performance analysis',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TestSeriesScreen()),
          ),
        ),
        const SizedBox(height: 12),
        FeatureTile(
          icon: Icons.menu_book_outlined,
          title: 'Book Store',
          subtitle: 'Notes & reference materials',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BookStoreScreen()),
          ),
        ),
        const SizedBox(height: 12),
        FeatureTile(
          icon: Icons.article_outlined,
          title: 'Syllabus',
          subtitle: 'Structured curriculum & topics',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SyllabusScreen()),
          ),
        ),
      ],
    );
  }
}
