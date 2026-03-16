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
      final profiles = await profileService.getDiscoveryList(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        religion: _selectedReligion,
        region: _selectedLocation,
      );
      if (mounted) {
        final currentUser = authService.currentUser;
        setState(() {
          _profiles = profiles.where((p) {
            // Filter out self
            if (p.id == currentUser?.id) return false;
            
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
            ],
          ),
        ),
      ],
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
                crossAxisCount: MediaQuery.of(context).size.width > 1400 ? 5 : (MediaQuery.of(context).size.width > 900 ? 3 : (MediaQuery.of(context).size.width > 600 ? 2 : 2)),
                childAspectRatio: 0.53, // Made taller to match Home page proportions
                mainAxisSpacing: 24,
                crossAxisSpacing: 24,
              ),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
              itemCount: _profiles.length,
              itemBuilder: (context, index) {
                final profile = _profiles[index];
                return _buildProfileCard(
                  profile: profile,
                  isDark: isDark,
                  cardBg: isDark ? cardBgDark : cardBgLight,
                  primaryColor: primaryColor,
                  accentGold: accentGold,
                );
              },
            ),
          );
  }

  void _showAgeFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Age Range', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
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
      ),
    );
  }

  void _showReligionFilter() {
    final religions = ['Islam (Sunni)', 'Islam (Shia)', 'Islam (Other)', 'Christianity', 'Hinduism', 'Sikhism', 'Buddhism', 'Other'];
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildSelectionList('Select Religion', religions, _selectedReligion, (val) {
        setState(() => _selectedReligion = val);
        _fetchProfiles();
      }),
    );
  }

  void _showEducationFilter() {
    final edus = ['Bachelors', 'Masters', 'PhD', 'Diploma', 'High School'];
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildSelectionList('Select Education', edus, _selectedEducation, (val) {
        setState(() => _selectedEducation = val);
        _fetchProfiles();
      }),
    );
  }

  void _showLocationFilter() {
    final locs = ['Bangladesh', 'India', 'Germany', 'Pakistan', 'Canada', 'USA'];
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildSelectionList('Select Location', locs, _selectedLocation, (val) {
        setState(() => _selectedLocation = val);
        _fetchProfiles();
      }),
    );
  }

  Widget _buildSelectionList(String title, List<String> options, String? current, Function(String?) onSelected) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
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

  Widget _buildProfileCard({
    required UserModel profile,
    required bool isDark,
    required Color cardBg,
    required Color primaryColor,
    required Color accentGold,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(user: profile),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              // No fixed flex, let it take all available space
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: resolveImageUrl(profile.profileImageUrl),
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            color: primaryColor,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person,
                                size: 40,
                                color: isDark ? Colors.grey[600] : Colors.grey[400]),
                            const SizedBox(height: 4),
                            Text(
                              'No Image',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? Colors.grey[600] : Colors.grey[400],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (profile.isOnline)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          final profileService = context.read<ProfileService>();
                          final wasFavorited = profile.isFavorited;
                          try {
                            // Optimistic update
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
                            
                            // Background sync without full refresh
                            _fetchProfiles(silent: true);
                          } catch (e) {
                            // Rollback
                            setState(() {
                              final index = _profiles.indexWhere((p) => p.id == profile.id);
                              if (index != -1) {
                                _profiles[index] = _profiles[index].copyWith(isFavorited: wasFavorited);
                              }
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            profile.isFavorited ? Icons.favorite : Icons.favorite_border,
                            color: profile.isFavorited ? const Color(0xFFFF7074) : Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              // Removed Expanded to let content define height and prevent overflow
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                    if (profile.isOnline) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'ACTIVE NOW',
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      '${profile.firstName}, ${profile.age ?? ""}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey[900],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.profession ?? 'Member',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 10, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${profile.city}, ${profile.country}',
                            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8), // Reduced from Spacer/12
                    SizedBox(
                      height: 32,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (profile.connectionStatus == 'PENDING_SENT' || profile.connectionStatus == 'PENDING')
                          ? null 
                          : () async {
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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Failed to open chat: $e")),
                                );
                              }
                            }
                          } else if (profile.connectionStatus == 'PENDING_RECEIVED') {
                            // Navigate to profile to let user respond
                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProfileScreen(user: profile),
                                ),
                              );
                            }
                          } else {
                            try {
                              final connectionService = context.read<ConnectionService>();
                              await connectionService.sendConnectionRequest(profile.id);
                              
                              if (mounted) {
                                setState(() {
                                  final index = _profiles.indexWhere((p) => p.id == profile.id);
                                  if (index != -1) {
                                    _profiles[index] = _profiles[index].copyWith(connectionStatus: 'PENDING_SENT');
                                  }
                                });
                              }
                              
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Connection request sent!')),
                              );
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to send request: $e')),
                                );
                              }
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: profile.connectionStatus == 'ACCEPTED' 
                              ? const Color(0xFF2ECC71) 
                              : (profile.connectionStatus == 'PENDING_RECEIVED' 
                                  ? QaboolTheme.accentGold 
                                  : (profile.connectionStatus == 'PENDING_SENT' || profile.connectionStatus == 'PENDING' ? Colors.grey : primaryColor)),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          profile.connectionStatus == 'ACCEPTED' 
                              ? 'MESSAGE' 
                              : (profile.connectionStatus == 'PENDING_RECEIVED' 
                                  ? 'RESPOND' 
                                  : (profile.connectionStatus == 'PENDING_SENT' || profile.connectionStatus == 'PENDING' ? 'PENDING' : 'CONNECT')),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
}
