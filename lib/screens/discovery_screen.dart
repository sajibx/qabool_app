import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:qabool_app/theme.dart';
import 'package:qabool_app/services/profile_service.dart';
import 'package:qabool_app/services/connection_service.dart';
import 'package:qabool_app/utils/image_utils.dart';
import 'package:qabool_app/services/chat_service.dart';
import 'package:qabool_app/models/user_model.dart';
import 'package:qabool_app/screens/chat_screen.dart';
import 'package:qabool_app/screens/profile_screen.dart';
import 'package:qabool_app/widgets/user_discovery_card.dart';
import 'package:qabool_app/services/auth_service.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => DiscoveryScreenState();
}

class DiscoveryScreenState extends State<DiscoveryScreen> {
  bool _isLoading = true;
  List<UserModel> _profiles = [];
  
  // Search and Filter State
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showConnected = true;
  
  String? _selectedReligion;
  String? _selectedLocation;
  RangeValues _ageRange = const RangeValues(18, 80);
  String? _selectedEducation;

  Future<void> refreshData() async {
    await _fetchProfiles();
  }

  @override
  void initState() {
    super.initState();
    _fetchProfiles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfiles({bool silent = false}) async {
    if (mounted && !silent) setState(() => _isLoading = true);
    final profileService = context.read<ProfileService>();
    final authService = context.read<AuthService>();
    try {
      final profiles = await profileService.getDiscoverUsers();
      if (mounted) {
        final currentUser = authService.currentUser;
        setState(() {
          _profiles = profiles.where((p) {
            // Filter out self
            if (p.id == currentUser?.id) return false;

            // Show all users (connected and new) by default, but hide if toggle is off
            if (!_showConnected && p.connectionStatus == 'ACCEPTED') return false;

            // Filter based on past issues preferences
            if (currentUser != null && !currentUser.acceptsPastIssues && p.hasPastIssues) {
              return false;
            }
            
            // If current user has gender set, show only opposite gender (strict)
            if (currentUser?.gender != null) {
              if (currentUser!.gender == 'Male') {
                if (p.gender != 'Female') return false;
              } else if (currentUser.gender == 'Female') {
                if (p.gender != 'Male') return false;
              }
            }

            // Local filters for fields not supported by backend yet
            if (p.age != null && (p.age! < _ageRange.start || p.age! > _ageRange.end)) {
              return false;
            }
            
            if (_selectedEducation != null && p.education != _selectedEducation) {
              return false;
            }
            
            return true;
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profiles: $e')),
        );
      }
    }
  }

  Future<void> _handleConnect(UserModel profile) async {
    if (profile.connectionStatus == 'ACCEPTED') {
      try {
        final chatService = context.read<ChatService>();
        final chat = await chatService.createChat(profile.id);
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                chatId: chat.id,
                otherUser: profile,
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to open chat: $e")));
        }
      }
    } else if (profile.connectionStatus == 'PENDING_RECEIVED') {
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(user: profile)));
      }
    } else {
      try {
        final connectionService = context.read<ConnectionService>();
        await connectionService.sendConnectionRequest(profile.id);
        if (mounted) {
          setState(() {
            final idx = _profiles.indexWhere((p) => p.id == profile.id);
            if (idx != -1) {
              _profiles[idx] = _profiles[idx].copyWith(connectionStatus: 'PENDING_SENT');
            }
          });
        }
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connection request sent!')));
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send request: $e')));
        }
      }
    }
  }

  Future<void> _handleFavorite(UserModel profile) async {
    final profileService = context.read<ProfileService>();
    final wasFavorited = profile.isFavorited;
    try {
      setState(() {
        final index = _profiles.indexWhere((p) => p.id == profile.id);
        if (index != -1) {
          _profiles[index] = _profiles[index].copyWith(isFavorited: !wasFavorited);
        }
      });
      if (wasFavorited) {
        await profileService.unfavoriteUser(profile.id);
      } else {
        await profileService.favoriteUser(profile.id);
      }
      _fetchProfiles(silent: true);
    } catch (e) {
      setState(() {
        final index = _profiles.indexWhere((p) => p.id == profile.id);
        if (index != -1) {
          _profiles[index] = _profiles[index].copyWith(isFavorited: wasFavorited);
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _handleSkip(UserModel profile) {
    setState(() {
      _profiles.removeWhere((p) => p.id == profile.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Skipped ${profile.firstName}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const primaryColor = QaboolTheme.primary;
    const accentGold = QaboolTheme.accentGold;
    const bgLight = QaboolTheme.backgroundLight;
    const bgDark = QaboolTheme.backgroundDark;
    const cardBgLight = Colors.white;
    const cardBgDark = Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: isDark ? bgDark : bgLight,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLargeScreen = constraints.maxWidth > 900;

            if (isLargeScreen) {
              return Row(
                children: [
                  // Main Content (Suggested Profile Section) - Moved from right
                  Expanded(
                    child: Column(
                      children: [
                        _buildSearchBar(isDark, primaryColor, bgDark),
                        Expanded(
                          child: _buildGrid(isDark, primaryColor, accentGold, cardBgLight, cardBgDark),
                        ),
                      ],
                    ),
                  ),
                  // Divider
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: primaryColor.withOpacity(0.1),
                  ),
                  // Sidebar Filters (Promoted to Right side)
                  SizedBox(
                    width: 300,
                    child: _buildSidebarFilters(isDark, primaryColor, accentGold, bgDark, cardBgDark),
                  ),
                ],
              );
            }

            // Mobile View
            return Column(
              children: [
                _buildMobileFilters(isDark, primaryColor, accentGold, bgDark),
                Expanded(
                  child: _buildGrid(isDark, primaryColor, accentGold, cardBgLight, cardBgDark),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark, Color primaryColor, Color bgDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: isDark ? bgDark : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: primaryColor.withOpacity(0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search people...',
                  hintStyle: TextStyle(fontSize: 14, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  border: InputBorder.none,
                  prefixIcon: const Icon(Icons.search, size: 20, color: QaboolTheme.primary),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                            _fetchProfiles();
                          },
                        )
                      : null,
                ),
                onChanged: (val) {
                  _searchQuery = val;
                  _fetchProfiles();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFilters(bool isDark, Color primaryColor, Color accentGold, Color bgDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: isDark ? bgDark : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: primaryColor.withOpacity(0.1),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (_isSearching)
              Container(
                width: 200,
                margin: const EdgeInsets.only(right: 12),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle: const TextStyle(fontSize: 14),
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search, size: 20, color: primaryColor),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () {
                        setState(() {
                          _isSearching = false;
                          _searchController.clear();
                          _searchQuery = '';
                        });
                        _fetchProfiles();
                      },
                    ),
                  ),
                  onChanged: (val) {
                    _searchQuery = val;
                    _fetchProfiles();
                  },
                ),
              )
            else
              IconButton(
                icon: Icon(Icons.search, color: primaryColor, size: 28),
                onPressed: () => setState(() => _isSearching = true),
                padding: const EdgeInsets.only(right: 16),
                constraints: const BoxConstraints(),
              ),
            
            _buildFilterButton('Age', _ageRange != const RangeValues(18, 80), () => _showAgeFilter(), primaryColor, accentGold, isDark),
            const SizedBox(width: 8),
            _buildFilterButton('Religion', _selectedReligion != null, () => _showReligionFilter(), primaryColor, accentGold, isDark),
            const SizedBox(width: 8),
            _buildFilterButton('Education', _selectedEducation != null, () => _showEducationFilter(), primaryColor, accentGold, isDark),
            const SizedBox(width: 8),
            _buildFilterButton('Location', _selectedLocation != null, () => _showLocationFilter(), primaryColor, accentGold, isDark),
            const SizedBox(width: 8),
            _buildFilterButton(
              _showConnected ? 'Connected: On' : 'Connected: Off',
              _showConnected,
              () {
                setState(() => _showConnected = !_showConnected);
                _fetchProfiles();
              },
              primaryColor,
              accentGold,
              isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarFilters(bool isDark, Color primaryColor, Color accentGold, Color bgDark, Color cardBgDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Text(
            'Filters',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildSidebarFilterItem(
                'Age Range',
                '${_ageRange.start.toInt()} - ${_ageRange.end.toInt()}',
                _ageRange != const RangeValues(18, 80),
                () => _showAgeFilter(),
                isDark,
                primaryColor,
              ),
              _buildSidebarFilterItem(
                'Religion',
                _selectedReligion ?? 'All Religions',
                _selectedReligion != null,
                () => _showReligionFilter(),
                isDark,
                primaryColor,
              ),
              _buildSidebarFilterItem(
                'Education',
                _selectedEducation ?? 'Any Education',
                _selectedEducation != null,
                () => _showEducationFilter(),
                isDark,
                primaryColor,
              ),
              _buildSidebarFilterItem(
                'Location',
                _selectedLocation ?? 'Everywhere',
                _selectedLocation != null,
                () => _showLocationFilter(),
                isDark,
                primaryColor,
              ),
              const SizedBox(height: 24),
              if (_ageRange != const RangeValues(18, 80) || _selectedReligion != null || _selectedEducation != null || _selectedLocation != null)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _ageRange = const RangeValues(18, 80);
                      _selectedReligion = null;
                      _selectedEducation = null;
                      _selectedLocation = null;
                    });
                    _fetchProfiles();
                  },
                  child: const Text('Reset All Filters', style: TextStyle(color: QaboolTheme.primary)),
                ),
              const Divider(height: 32),
              _buildSidebarToggleItem(
                'Show Connected',
                _showConnected,
                (val) {
                  setState(() => _showConnected = val);
                  _fetchProfiles();
                },
                isDark,
                primaryColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarToggleItem(String title, bool value, Function(bool) onChanged, bool isDark, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          SizedBox(
            height: 24,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: QaboolTheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarFilterItem(String title, String value, bool isActive, VoidCallback onTap, bool isDark, Color primaryColor) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? primaryColor.withOpacity(0.1) : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? primaryColor : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? primaryColor : (isDark ? Colors.grey[400] : Colors.grey[600]),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: isActive ? primaryColor : Colors.grey[400],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(bool isDark, Color primaryColor, Color accentGold, Color cardBgLight, Color cardBgDark) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _profiles.isEmpty
            ? const Center(child: Text('No profiles found Match your criteria'))
            : RefreshIndicator(
            onRefresh: refreshData,
            color: primaryColor,
            child: GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 3 : (MediaQuery.of(context).size.width > 800 ? 2 : 2),
                childAspectRatio: 0.55, // Taller cards
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
              itemCount: _profiles.length,
              itemBuilder: (context, index) {
                final profile = _profiles[index];
                return UserDiscoveryCard(
                  user: profile,
                  isGridMode: true,
                  onConnect: () => _handleConnect(profile),
                  onFavorite: () => _handleFavorite(profile),
                  onSkip: () => _handleSkip(profile),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(user: profile)));
                  },
                );
              },
            ),
          );
  }

  void _showFilterDialog(String title, Widget content) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;
    
    if (isDesktop) {
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Dismiss',
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, anim1, anim2) {
          return Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 400,
                height: double.infinity,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(-5, 0)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                        ],
                      ),
                    ),
                    Expanded(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 24), child: content)),
                  ],
                ),
              ),
            ),
          );
        },
        transitionBuilder: (context, anim1, anim2, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(anim1),
            child: child,
          );
        },
      );
    } else {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (context) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              content,
            ],
          ),
        ),
      );
    }
  }

  void _showAgeFilter() {
    _showFilterDialog(
      'Select Age Range',
      StatefulBuilder(
        builder: (context, setModalState) => Column(
          children: [
            RangeSlider(
              values: _ageRange,
              min: 18,
              max: 80,
              divisions: 62,
              labels: RangeLabels(_ageRange.start.round().toString(), _ageRange.end.round().toString()),
              activeColor: QaboolTheme.primary,
              onChanged: (values) {
                setModalState(() => _ageRange = values);
                setState(() => _ageRange = values);
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _fetchProfiles();
              },
              style: ElevatedButton.styleFrom(backgroundColor: QaboolTheme.primary, minimumSize: const Size(double.infinity, 45)),
              child: const Text('Apply', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  void _showReligionFilter() {
    final religions = ['Islam (Sunni)', 'Islam (Shia)', 'Islam (Other)', 'Christianity', 'Hinduism', 'Sikhism', 'Buddhism', 'Other'];
    _showFilterDialog(
      'Select Religion',
      _buildSelectionList(null, religions, _selectedReligion, (val) {
        setState(() => _selectedReligion = val);
        Navigator.pop(context);
        _fetchProfiles();
      }),
    );
  }

  void _showEducationFilter() {
    final education = ['High School', 'Bachelor\'s', 'Master\'s', 'PhD', 'Other'];
    _showFilterDialog(
      'Select Education',
      _buildSelectionList(null, education, _selectedEducation, (val) {
        setState(() => _selectedEducation = val);
        Navigator.pop(context);
        _fetchProfiles();
      }),
    );
  }

  void _showLocationFilter() {
    final locations = ['London', 'New York', 'Daka', 'Dubai', 'Toronto', 'Sydney'];
    _showFilterDialog(
      'Select Location',
      _buildSelectionList(null, locations, _selectedLocation, (val) {
        setState(() => _selectedLocation = val);
        Navigator.pop(context);
        _fetchProfiles();
      }),
    );
  }

  Widget _buildSelectionList(String? title, List<String> options, String? current, Function(String?) onSelected) {
    return Container(
      padding: title != null ? const EdgeInsets.all(24) : EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
          ],
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: options.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return ListTile(
                    title: const Text('All'),
                    leading: Radio<String?>(value: null, groupValue: current, onChanged: (v) {
                      onSelected(null);
                      Navigator.pop(context);
                    }),
                    onTap: () {
                      onSelected(null);
                      Navigator.pop(context);
                    },
                  );
                }
                final opt = options[index - 1];
                return ListTile(
                  title: Text(opt),
                  leading: Radio<String?>(value: opt, groupValue: current, onChanged: (v) {
                    onSelected(opt);
                    Navigator.pop(context);
                  }),
                  onTap: () {
                    onSelected(opt);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(
      String label, bool isActive, VoidCallback onTap, Color primaryColor, Color secondaryColor, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? primaryColor : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? primaryColor : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : (isDark ? Colors.grey[300] : Colors.grey[700]),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down,
                size: 16, color: isActive ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[600])),
          ],
        ),
      ),
    );
  }

}
