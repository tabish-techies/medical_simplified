import 'package:flutter/material.dart';
import '../../data/auth_repository.dart';
import '../profile/profile_screen.dart';
import '../my_courses/my_courses_screen.dart';
import 'home_screen.dart';

class MainScreen extends StatefulWidget {
  final AuthRepository authRepository;

  const MainScreen({super.key, required this.authRepository});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  static const Color _primaryBlue = Color(0xFF4F7CFF);

  @override
  void initState() {
    super.initState();

    _pages = [
      HomeScreen(authRepository: widget.authRepository),
      const MyCoursesScreen(),
      ProfileScreen(authRepository: widget.authRepository),
    ];
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
  index: _selectedIndex,
  children: _pages,
),

      /// 🔵 Consistent Bottom Navigation
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          backgroundColor: Colors.white,

          selectedItemColor: _primaryBlue,
          unselectedItemColor: Colors.grey.shade500,

          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
          ),

          showUnselectedLabels: true,

          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              activeIcon: Icon(Icons.menu_book),
              label: 'My Purchases',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
