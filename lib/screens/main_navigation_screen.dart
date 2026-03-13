import 'package:flutter/material.dart';
import 'package:qabool_app/theme.dart';
import 'package:provider/provider.dart';
import 'package:qabool_app/services/chat_service.dart';
import 'package:qabool_app/screens/home_screen.dart';
import 'package:qabool_app/screens/discovery_screen.dart';
import 'package:qabool_app/screens/messages_screen.dart';
import 'package:qabool_app/screens/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // The screens we will navigate between
  final List<Widget> _screens = [
    const HomeScreen(),
    const DiscoveryScreen(),
    const MessagesScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = QaboolTheme.primary; // Gold
    const accentGold = QaboolTheme.accentGold;
    const bgDark = Color(0xFF1A1616);

    // We are maintaining the custom bottom nav bar design
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? bgDark : Colors.white,
          border: Border(
              top: BorderSide(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : primaryColor.withOpacity(0.1))),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5))
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: SafeArea(
          child: Consumer<ChatService>(
            builder: (context, chatService, _) {
              final totalUnread = chatService.totalUnreadCount;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNavItem(
                      Icons.home, 'Home', 0, accentGold, primaryColor, isDark),
                  _buildNavItem(Icons.explore, 'Discover', 1, accentGold,
                      primaryColor, isDark),
                  _buildNavItem(Icons.chat_bubble, 'Messages', 2, accentGold,
                      primaryColor, isDark, badgeCount: totalUnread > 0 ? totalUnread : null),
                  _buildNavItem(Icons.account_circle, 'Profile', 3, accentGold,
                      primaryColor, isDark),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, Color sColor,
      Color pColor, bool isDark,
      {int? badgeCount}) {
    final isActive = _currentIndex == index;
    final activeColor = isDark ? pColor : sColor;
    final color =
        isActive ? activeColor : (isDark ? Colors.grey[600] : Colors.grey[400]);

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque, // Ensures the entire column is tapable
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 4),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          if (badgeCount != null)
            Positioned(
              top: -2,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? pColor : sColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      width: 2),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
