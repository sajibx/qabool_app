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
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();
  final GlobalKey<DiscoveryScreenState> _discoveryKey = GlobalKey<DiscoveryScreenState>();
  final GlobalKey<MessagesScreenState> _messagesKey = GlobalKey<MessagesScreenState>();
  int _currentIndex = 0;

  // The screens we will navigate between
  late final List<Widget> _screens = [
    HomeScreen(
      key: _homeKey,
      onNavigate: (index) => _onItemTapped(index),
    ),
    DiscoveryScreen(key: _discoveryKey),
    MessagesScreen(key: _messagesKey),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    if (_currentIndex == index) {
      if (index == 0) {
        _homeKey.currentState?.refreshData();
      } else if (index == 1) {
        _discoveryKey.currentState?.refreshData();
      } else if (index == 2) {
        _messagesKey.currentState?.refreshData();
      }
    }
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

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLargeScreen = constraints.maxWidth > 900;

          return Row(
            children: [
              if (isLargeScreen)
                // Desktop Sidebar
                Container(
                  width: 280,
                  decoration: BoxDecoration(
                    color: isDark ? bgDark : Colors.white,
                    border: Border(
                      right: BorderSide(
                        color: isDark ? const Color(0xFF1E293B) : primaryColor.withOpacity(0.1),
                      ),
                    ),
                  ),
                  child: SafeArea(
                    child: Consumer<ChatService>(
                      builder: (context, chatService, _) {
                        final totalUnread = chatService.totalUnreadCount;
                        return Column(
                          children: [
                            const SizedBox(height: 32),
                            // Logo/Brand Area
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Row(
                                children: [
                                  Icon(Icons.favorite, color: primaryColor, size: 32),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Qabool',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: isDark ? Colors.white : Colors.black,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 48),
                            // Nav Items
                            _buildSidebarItem(Icons.home_outlined, Icons.home, 'Home', 0, accentGold, primaryColor, isDark),
                            _buildSidebarItem(Icons.explore_outlined, Icons.explore, 'Discover', 1, accentGold, primaryColor, isDark),
                            _buildSidebarItem(Icons.chat_bubble_outline, Icons.chat_bubble, 'Messages', 2, accentGold, primaryColor, isDark, badgeCount: totalUnread > 0 ? totalUnread : null),
                            _buildSidebarItem(Icons.person_outline, Icons.person, 'Profile', 3, accentGold, primaryColor, isDark),
                            const Spacer(),
                            // Logout or version info could go here
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'v1.0.0',
                                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              
              // Main Content
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: _screens,
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          if (MediaQuery.of(context).size.width > 900) return const SizedBox.shrink();
          
          return Container(
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
          );
        },
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, IconData activeIcon, String label, int index, Color sColor, Color pColor, bool isDark, {int? badgeCount}) {
    final isActive = _currentIndex == index;
    final activeColor = isDark ? pColor : sColor;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => _onItemTapped(index),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? activeColor.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(isActive ? activeIcon : icon, color: isActive ? activeColor : Colors.grey[500], size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isActive ? activeColor : (isDark ? Colors.grey[300] : Colors.grey[700]),
                    fontSize: 16,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
              if (badgeCount != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? activeColor : Colors.grey[400],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
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
