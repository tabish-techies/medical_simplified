import 'package:flutter/material.dart';
import 'tabs/purchased_courses_tab.dart';
import 'tabs/purchased_notes_tab.dart';
import 'tabs/test_series_tab.dart';
import 'tabs/purchased_syllabus_tab.dart';

// --- UI CONSTANTS ---
const Color kPrimaryColor = Color(0xFF2563EB); // Professional Royal Blue
const Color kBackgroundColor = Color(0xFFF8F9FC); // Very light grey/blue background
const Color kCardColor = Colors.white;
const Color kTextPrimary = Color(0xFF1E293B);
const Color kTextSecondary = Color(0xFF64748B);
const double kRadius = 16.0;

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final ScrollController _tabScrollController = ScrollController();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabSelection);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    _tabScrollController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _selectedIndex = _tabController.index;
      });
    } else {
      if (_selectedIndex != _tabController.index) {
        setState(() {
          _selectedIndex = _tabController.index;
        });
      }
    }
  }

  // --- UI WIDGETS ---

  Widget _buildCustomTabBar() {
    final tabs = ['Courses', 'Notes', 'Test Series', 'Syllabus'];

    return Container(
      height: 70, // Slightly taller for padding
      color: Colors.white,
      child: Column(
        children: [
          Expanded(
            child: Scrollbar(
              controller: _tabScrollController,
              thumbVisibility: true,
              thickness: 3,
              radius: const Radius.circular(3),
              // Make scrollbar subtle
              trackVisibility: false,
              child: ListView.builder(
                controller: _tabScrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: tabs.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: InkWell(
                        onTap: () {
                          _tabController.animateTo(index);
                          setState(() => _selectedIndex = index);
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? kPrimaryColor : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: isSelected ? kPrimaryColor : Colors.grey.shade300, width: 1),
                          ),
                          child: Text(
                            tabs[index],
                            style: TextStyle(
                              color: isSelected ? Colors.white : kTextSecondary,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor, // Light professional background
      appBar: AppBar(
        title: const Text(
          'My Learning',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: kTextPrimary),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: kTextPrimary,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: Column(
        children: [
          _buildCustomTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [PurchasedCoursesTab(), PurchasedNotesTab(), TestSeriesTab(), PurchasedSyllabusTab()],
            ),
          ),
        ],
      ),
    );
  }
}
