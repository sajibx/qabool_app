import 'package:flutter/material.dart';
import 'package:qabool_app/theme.dart';
import 'package:provider/provider.dart';
import 'package:qabool_app/services/chat_service.dart';
import 'package:qabool_app/screens/home_screen.dart';
import 'package:qabool_app/screens/discovery_screen.dart';
import 'package:qabool_app/screens/messages_screen.dart';
import 'package:qabool_app/screens/profile_screen.dart';
import 'package:qabool_app/widgets/floating_chat_window.dart';
import 'package:qabool_app/models/chat_model.dart';
import 'package:qabool_app/models/user_model.dart';
import 'package:qabool_app/services/api_service.dart';

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
  bool _isSidebarCollapsed = false;

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

  @override
  void initState() {
    super.initState();
    // Initialize activity state for the global overlay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatService>().setMessagesPageActive(_currentIndex == 2);
    });
  }

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
    // Update global messages page activity state
    context.read<ChatService>().setMessagesPageActive(index == 2);
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
          final isLargeScreen = constraints.maxWidth > 800;

          return Row(
            children: [
              if (isLargeScreen)
                // Desktop Sidebar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: _isSidebarCollapsed ? 80 : 280,
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
                            const SizedBox(height: 16),
                            // Burger Menu Toggle
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: _isSidebarCollapsed ? 0 : 16),
                              child: Align(
                                alignment: _isSidebarCollapsed ? Alignment.center : Alignment.centerLeft,
                                child: IconButton(
                                  icon: Icon(Icons.menu, color: isDark ? Colors.white70 : Colors.black87),
                                  onPressed: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Logo/Brand Area
                            SizedBox(
                              height: 60,
                              child: ClipRect(
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                  opacity: _isSidebarCollapsed ? 0 : 1,
                                  child: _isSidebarCollapsed 
                                    ? const SizedBox.shrink()
                                  : Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24),
                                      child: Row(
                                        children: [
                                          Icon(Icons.favorite, color: primaryColor, size: 32),
                                          const SizedBox(width: 12),
                                          const Text(
                                            'Qabool',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.black, // fallback, handled by text theme
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                              ),
                            ),
                            ),
                            SizedBox(height: _isSidebarCollapsed ? 16 : 48),
                            // Nav Items
                            _buildSidebarItem(Icons.home_outlined, Icons.home, 'Qabool', 0, accentGold, primaryColor, isDark),
                            _buildSidebarItem(Icons.explore_outlined, Icons.explore, 'Explore', 1, accentGold, primaryColor, isDark),
                            _buildSidebarItem(Icons.chat_bubble_outline, Icons.chat_bubble, 'Chat', 2, accentGold, primaryColor, isDark, badgeCount: totalUnread > 0 ? totalUnread : null),
                            _buildSidebarItem(Icons.person_outline, Icons.person, 'Profile', 3, accentGold, primaryColor, isDark),
                            const Spacer(),
                            // version info
                            if (!_isSidebarCollapsed)
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                                opacity: _isSidebarCollapsed ? 0 : 1,
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    'v1.0.0',
                                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                  ),
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
          if (MediaQuery.of(context).size.width > 800) return const SizedBox.shrink();
          
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
                          Icons.favorite, 'Qabool', 0, QaboolTheme.primary,
                          primaryColor, isDark),
                      _buildNavItem(Icons.explore, 'Explore', 1, QaboolTheme.primary,
                          primaryColor, isDark),
                      _buildNavItem(Icons.chat_bubble, 'Chat', 2, QaboolTheme.primary,
                          primaryColor, isDark,
                          badgeCount: totalUnread > 0 ? totalUnread : null),
                      _buildNavItem(Icons.person, 'Profile', 3, QaboolTheme.primary,
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
      padding: EdgeInsets.symmetric(horizontal: _isSidebarCollapsed ? 8 : 16, vertical: 4),
      child: InkWell(
        onTap: () => _onItemTapped(index),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.symmetric(horizontal: _isSidebarCollapsed ? 0 : 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? activeColor.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: _isSidebarCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(isActive ? activeIcon : icon, color: isActive ? activeColor : Colors.grey[500], size: 24),
                  if (_isSidebarCollapsed && badgeCount != null)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: QaboolTheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
              // Animated Label and Badge
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                width: _isSidebarCollapsed ? 0 : 160,
                child: ClipRect(
                  child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 110,
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isActive ? activeColor : (isDark ? Colors.grey[300] : Colors.grey[700]),
                            fontSize: 16,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (badgeCount != null)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
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
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
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
