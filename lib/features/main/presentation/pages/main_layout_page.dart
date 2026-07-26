import 'package:flutter/material.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../search/presentation/pages/search_page.dart';
import '../../../home/presentation/pages/add_product_page.dart';
import '../../../saved/presentation/pages/saved_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';

class MainLayoutPage extends StatefulWidget {
  const MainLayoutPage({super.key});

  @override
  State<MainLayoutPage> createState() => _MainLayoutPageState();
}

class _MainLayoutPageState extends State<MainLayoutPage> {
  int _currentIndex = 0;



  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(onSearchTapped: () => _onTabTapped(1)),
      SearchPage(isActive: _currentIndex == 1),
      const AddProductPage(),
      const SavedPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF0F4C3A),
          unselectedItemColor: const Color(0xFF5A5A5A),
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: _ActiveIcon(icon: Icons.home),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.search),
              activeIcon: _ActiveIcon(icon: Icons.search),
              label: 'Search',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline),
              activeIcon: _ActiveIcon(icon: Icons.add_circle),
              label: 'Create',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_border),
              activeIcon: _ActiveIcon(icon: Icons.bookmark),
              label: 'Saved',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: _ActiveIcon(icon: Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveIcon extends StatelessWidget {
  final IconData icon;

  const _ActiveIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0F4C3A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: Colors.white),
    );
  }
}
