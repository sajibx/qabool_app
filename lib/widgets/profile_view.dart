import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:qabool_app/models/user_model.dart';
import 'package:qabool_app/theme.dart';
import 'package:qabool_app/utils/image_utils.dart';
import 'package:qabool_app/services/navigation_service.dart';
import 'package:flutter/rendering.dart';

class ProfileView extends StatefulWidget {
  final UserModel user;
  final VoidCallback? onConnect;
  final VoidCallback? onFavorite;
  final VoidCallback? onSkip;
  final VoidCallback? onRewind;
  final VoidCallback? onBlock;
  final VoidCallback? onReport;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onCancel;
  final bool isMyProfile;

  const ProfileView({
    super.key,
    required this.user,
    this.onConnect,
    this.onFavorite,
    this.onSkip,
    this.onRewind,
    this.onBlock,
    this.onReport,
    this.onAccept,
    this.onReject,
    this.onCancel,
    this.isMyProfile = false,
  });

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late ScrollController _scrollController;
  bool _isScrollingDown = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      if (!_isScrollingDown) {
        _isScrollingDown = true;
        context.read<NavigationService>().setBottomNavVisible(false);
      }
    } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      if (_isScrollingDown) {
        _isScrollingDown = false;
        context.read<NavigationService>().setBottomNavVisible(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = QaboolTheme.primary;
    final backgroundColor = isDark ? QaboolTheme.backgroundDark : Colors.white;

    return Container(
      color: backgroundColor,
      child: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isExtraWide = constraints.maxWidth > 1200;
              final isLargeScreen = constraints.maxWidth > 800;
              
              if (isLargeScreen) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- LEFT COLUMN (Scrollable Details) ---
                    Expanded(
                      flex: isExtraWide ? 6 : 5,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: EdgeInsets.symmetric(
                          horizontal: isExtraWide ? 100 : 60, 
                          vertical: 32
                        ),
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Profile Details',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : Colors.black87,
                                letterSpacing: -1.0,
                              ),
                            ),
                            const SizedBox(height: 40),
                            
                            // Info Grid (Gender, Age, etc)
                            _buildInfoGrid(isDark, true),
                            const SizedBox(height: 40),

                            // Requirement section
                            _buildDetailCard(isDark, 'Requirement', Icons.assignment_turned_in_outlined, _buildRequirementSection(isDark, true)),
                            const SizedBox(height: 32),

                            // Interests
                            _buildInterestsSection(isDark),
                            const SizedBox(height: 24),

                            // Personality
                            _buildPersonalitySection(isDark),
                            const SizedBox(height: 32),

                            // Challenges
                            _buildChallengesSection(isDark),
                            const SizedBox(height: 60),
                            
                            Center(child: _buildIssuesBadges(isDark)),
                            const SizedBox(height: 40),

                            if (!widget.isMyProfile) _buildSecondaryActions(isDark),
                            const SizedBox(height: 60),
                          ],
                        ),
                      ),
                    ),

                    // --- RIGHT COLUMN (DP & Bio) ---
                    Expanded(
                      flex: isExtraWide ? 4 : 5,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Absolute right panel DP
                            _buildDesktopHeroImage(context, isDark),
                            const SizedBox(height: 32),
                            

                            // Bio section
                            Text(
                              'ABOUT ME',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildAboutMeContent(isDark),
                            
                            const SizedBox(height: 40),
                            
                            if (!widget.isMyProfile) 
                              _buildActionCard(isDark, primaryColor),
                            const SizedBox(height: 60),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }

              // --- MOBILE/TABLET VIEW (Existing single column) ---
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopImage(context, isDark),
                        if (!widget.isMyProfile) _buildReadyToQaboolCard(isDark),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: _buildAboutMeSection(isDark),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
                          child: _buildDetailCard(isDark, 'Requirement', Icons.assignment_turned_in_outlined, _buildRequirementSection(isDark, false)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: _buildInterestsSection(isDark),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: _buildPersonalitySection(isDark),
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: _buildChallengesSection(isDark),
                        ),
                        const SizedBox(height: 48),
                        Center(child: _buildIssuesBadges(isDark)),
                        const SizedBox(height: 28),
                        if (!widget.isMyProfile) _buildSecondaryActions(isDark),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

           // Floating Action Buttons at Bottom (REMOVED)
        ],
      ),
    );
  }

  Widget _buildTopImage(BuildContext context, bool isDark) {
    final imageUrl = getVersionedImageUrl(widget.user.profileImageUrl, widget.user.updatedAt);
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 800;
    
    // Adjust height based on screen size (increased by 15%)
    final imageHeight = isLargeScreen 
        ? MediaQuery.of(context).size.height * 1.05 
        : MediaQuery.of(context).size.height * 1.2;

    return Stack(
      children: [
        Hero(
          tag: 'user_profile_${widget.user.id}',
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            height: imageHeight,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        // Gradient overlay for text readability
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
                stops: const [0.0, 0.2, 0.7, 1.0],
              ),
            ),
          ),
        ),
        // Active Status
        Positioned(
          top: 20,
          left: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: widget.user.lastSeenStatus.contains('now') || widget.user.lastSeenStatus.contains('today') 
                      ? Colors.green 
                      : Colors.grey, 
                    shape: BoxShape.circle
                  ),
                ),
                const SizedBox(width: 6),
                Text(widget.user.lastSeenStatus, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        // Name and Info Overlay
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                   Container(
                    constraints: BoxConstraints(maxWidth: isLargeScreen ? 600 : screenWidth * 0.7),
                    child: Text(
                      '${widget.user.firstName} ${widget.user.age ?? ""}',
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (widget.user.verifiedStatus == 'active')
                    const Icon(Icons.verified, color: Colors.blue, size: 24),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '6KM AWAY, ${widget.user.currentCity?.toUpperCase() ?? ""}, ${widget.user.country.toUpperCase()}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        if (widget.isMyProfile)
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton.small(
              onPressed: () => Navigator.pushNamed(context, '/edit_profile'),
              backgroundColor: QaboolTheme.primary,
              child: const Icon(Icons.edit, size: 18, color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildReadyToQaboolCard(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.grey[400] : const Color(0xFF64748B);
    
    final status = widget.user.connectionStatus;
    final isReceived = status == 'PENDING_RECEIVED';
    final isSent = status == 'PENDING_SENT' || status == 'PENDING';
    
    String title = 'Whom are you ready to qabool?';
    String subtitle = isReceived 
        ? '${widget.user.firstName} sent you a request!' 
        : isSent 
            ? 'Waiting for response...' 
            : 'Is ${widget.user.gender?.toLowerCase() == 'male' ? 'he' : 'she'} your perfect match?';
    
    IconData primaryIcon = isReceived ? Icons.check : isSent ? Icons.access_time : Icons.favorite_border;
    IconData secondaryIcon = Icons.close;
    
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildReadyActionButton(
                icon: secondaryIcon,
                color: const Color(0xFFF43F5E),
                onTap: isSent 
                    ? (widget.onCancel ?? () {}) 
                    : isReceived 
                        ? (widget.onReject ?? () {}) 
                        : (widget.onSkip ?? () {}),
              ),
              const SizedBox(width: 12),
              _buildReadyActionButton(
                icon: primaryIcon,
                color: isReceived 
                    ? const Color(0xFF2ECC71) 
                    : isSent 
                        ? Colors.grey 
                        : QaboolTheme.primary,
                onTap: isSent ? () {} : (isReceived ? (widget.onAccept ?? () {}) : (widget.onConnect ?? () {})),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReadyActionButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }


  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: QaboolTheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: QaboolTheme.primary.withOpacity(0.15), width: 1.0),
            ),
            child: Icon(icon, size: 18, color: QaboolTheme.primary),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileBubble(String text, IconData? icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : const Color(0xFFF3F4F6), // Very light grey
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: isDark ? Colors.white70 : Colors.black87),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutMeSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('About me', Icons.badge_outlined, isDark),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAboutMeContent(isDark),
              const SizedBox(height: 12), // Reduced from 24
              _buildInfoGrid(isDark, false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRequirementSection(bool isDark, bool isLargeScreen) {
    String ageRange = 'N/A';
    if (widget.user.lookingForMinAge != null && widget.user.lookingForMaxAge != null) {
      ageRange = '${widget.user.lookingForMinAge}-${widget.user.lookingForMaxAge}';
    } else if (widget.user.lookingForMinAge != null) {
      ageRange = '${widget.user.lookingForMinAge}+';
    }

    final List<_RequirementData> items = [
      _RequirementData(Icons.cake_outlined, 'Partner Age', ageRange),
      _RequirementData(Icons.school_outlined, 'Partner Education', widget.user.lookingForEducation ?? 'N/A'),
      _RequirementData(Icons.location_city_outlined, 'City', widget.user.currentCity ?? 'N/A'),
      _RequirementData(Icons.mosque_outlined, 'Partner Religion', widget.user.lookingForReligion ?? 'N/A'),
      _RequirementData(Icons.account_balance_outlined, 'Partner Sect', widget.user.lookingForReligionSect ?? 'N/A'),
      _RequirementData(Icons.groups_outlined, 'Partner Caste', widget.user.lookingForReligionCast ?? 'N/A'),
      _RequirementData(Icons.height, 'Min Partner Height', widget.user.lookingForMinHeight != null ? '${widget.user.lookingForMinHeight?.toInt()}cm' : 'N/A'),
      _RequirementData(Icons.monitor_weight_outlined, 'Max Partner Weight', widget.user.lookingForMaxWeight != null ? '${widget.user.lookingForMaxWeight?.toInt()}kg' : 'N/A'),
      _RequirementData(Icons.family_restroom_outlined, 'Partner Marital Status', widget.user.lookingForMaritalStatus ?? 'N/A'),
      _RequirementData(Icons.payments_outlined, 'Partner Income', widget.user.lookingForMonthlyIncome != null ? '€${widget.user.lookingForMonthlyIncome?.toInt()}' : 'N/A'),
      _RequirementData(Icons.language_outlined, 'Language', widget.user.language ?? 'N/A'),
      _RequirementData(Icons.person_outline, 'Partner Type', widget.user.lookingForType ?? 'N/A'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final double itemWidth = (constraints.maxWidth - 24) / 2; // 2 columns, 24 spacing
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 24,
              runSpacing: 24,
              children: items.map((item) => SizedBox(
                width: itemWidth,
                child: _buildPolishedRequirementItem(item, isDark),
              )).toList(),
            ),
            if (widget.user.otherRequirements != null && widget.user.otherRequirements!.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildNestedOtherRequirementsBox(isDark),
            ],
          ],
        );
      },
    );
  }

  Widget _buildNestedOtherRequirementsBox(bool isDark) {
    final boxBg = isDark ? Colors.black.withOpacity(0.2) : const Color(0xFFF1F5F9);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: boxBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment_outlined, size: 18, color: QaboolTheme.primary),
              const SizedBox(width: 8),
              Text(
                'OTHER REQUIREMENTS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.user.otherRequirements!,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolishedRequirementItem(_RequirementData item, bool isDark) {
    String val = item.value;
    if (val.isEmpty || val == 'null') val = 'N/A';
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: QaboolTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(item.icon, size: 16, color: QaboolTheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
              ),
              Text(
                val,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

   Widget _buildInfoGrid(bool isDark, bool isLargeScreen) {
    final List<Widget> items = [
      _buildInfoCard(Icons.wc, 'GENDER', widget.user.gender ?? 'N/A', isDark, isLargeScreen),
      _buildInfoCard(Icons.cake, 'AGE', widget.user.displayAge.toString(), isDark, isLargeScreen),
      _buildInfoCard(Icons.favorite_border, 'MARITAL STATUS', widget.user.maritalStatus ?? 'N/A', isDark, isLargeScreen),
      _buildInfoCard(Icons.monitor_weight_outlined, 'WEIGHT', widget.user.weight != null ? '${widget.user.weight?.toInt()}kg' : 'N/A', isDark, isLargeScreen),
      _buildInfoCard(Icons.height, 'HEIGHT', widget.user.height != null ? '${widget.user.height?.toInt()}cm' : 'N/A', isDark, isLargeScreen),
      _buildInfoCard(Icons.location_city, 'CURRENT CITY', widget.user.currentCity ?? 'N/A', isDark, isLargeScreen),
      _buildInfoCard(Icons.school_outlined, 'EDUCATION', widget.user.education ?? 'N/A', isDark, isLargeScreen),
      _buildInfoCard(Icons.mosque_outlined, 'RELIGION', widget.user.religion ?? 'N/A', isDark, isLargeScreen),
      _buildInfoCard(Icons.account_balance, 'SECT', widget.user.religionSect ?? 'N/A', isDark, isLargeScreen),
      _buildInfoCard(Icons.groups_outlined, 'CASTE', widget.user.religionCast ?? 'N/A', isDark, isLargeScreen),
      _buildInfoCard(Icons.payments_outlined, 'MONTHLY INCOME', widget.user.monthlyIncome != null ? '€${widget.user.monthlyIncome?.toInt()}' : 'N/A', isDark, isLargeScreen),
      _buildInfoCard(Icons.people_outline, 'SIBLINGS', widget.user.siblings?.toString() ?? 'N/A', isDark, isLargeScreen),
      _buildInfoCard(Icons.family_restroom_outlined, 'FAMILY MEMBERS', widget.user.familyMembers?.toString() ?? 'N/A', isDark, isLargeScreen),
      _buildInfoCard(Icons.public, 'NATIONALITY', widget.user.country, isDark, isLargeScreen),
      _buildInfoCard(Icons.language, 'LANGUAGE', widget.user.language ?? 'N/A', isDark, isLargeScreen),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final double itemWidth = (constraints.maxWidth - (2 * 12)) / 3; // 3 columns, 12 spacing
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((item) => SizedBox(width: itemWidth, child: item)).toList(),
        );
      },
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value, bool isDark, bool isLargeScreen) {
    if (value.isEmpty || value == 'null') value = 'N/A';
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isLargeScreen ? 12 : 8, vertical: 10), 
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(40), 
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: QaboolTheme.primary, size: 14),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutMeContent(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
      ),
      child: Text(
        widget.user.bio ?? "No bio provided.",
        style: TextStyle(
          fontSize: 15,
          height: 1.8,
          letterSpacing: 0.3,
          color: isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF334155),
        ),
      ),
    );
  }

  Widget _buildMiniBubble(String text, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isDark ? Colors.white : Colors.black),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildInterestsSection(bool isDark) {
    if (widget.user.interests.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Interests', Icons.auto_awesome_outlined, isDark),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: _buildInterestsContent(isDark),
        ),
      ],
    );
  }

  Widget _buildInterestsContent(bool isDark) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: widget.user.interests.take(15).map((interest) {
        return _buildProfileBubble(interest, null, isDark);
      }).toList(),
    );
  }

  Widget _buildPersonalitySection(bool isDark) {
    if (widget.user.personalityTraits.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Personality', Icons.psychology_outlined, isDark),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: _buildPersonalityContent(isDark),
        ),
      ],
    );
  }

  Widget _buildPersonalityContent(bool isDark) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: widget.user.personalityTraits.map((trait) {
        return _buildProfileBubble(trait, null, isDark);
      }).toList(),
    );
  }

  // Removed _buildReadyToQaboolSummary and _buildStatusIndicator as per request

  Widget _buildChallengesSection(bool isDark) {
    if (widget.user.readyToQaboolChallengesList.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Whom are you ready to qabool', Icons.volunteer_activism_outlined, isDark),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: _buildChallengesContent(isDark),
        ),
      ],
    );
  }

  Widget _buildChallengesContent(bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subHeaderStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w900,
      color: textColor.withOpacity(0.7),
      letterSpacing: 0.5,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.user.readyToQaboolChallenges) ...[
          if (widget.user.readyToQaboolChallengesList.isNotEmpty)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: widget.user.readyToQaboolChallengesList.map((item) {
                return _buildProfileBubble(item, null, isDark);
              }).toList(),
            )
          else
            Text(
              'Open to all situations',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: textColor.withOpacity(0.5),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildDesktopHeroImage(BuildContext context, bool isDark) {
    final imageUrl = getVersionedImageUrl(widget.user.profileImageUrl, widget.user.updatedAt);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          CachedNetworkImage(
            imageUrl: imageUrl,
            height: 520,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          // Gradient Overlay (Darker at bottom for text readability)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.85),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),

          // User Info Overlay
          Positioned(
            bottom: 24,
            left: 24,
            right: 80, // Space for the edit button
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        widget.user.firstName.toLowerCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22, // Reduced from 40
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.user.verifiedStatus == 'active') ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified, color: Color(0xFF3498DB), size: 16), // Reduced from 28
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white, size: 10), // Reduced from 16
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '6KM AWAY, ${widget.user.currentCity?.toUpperCase() ?? ""}, ${widget.user.country.toUpperCase()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8, // Reduced from 12
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (widget.isMyProfile)
            Positioned(
              bottom: 24,
              right: 24,
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: FloatingActionButton.small(
                  onPressed: () => Navigator.pushNamed(context, '/edit_profile'),
                  backgroundColor: const Color(0xFF9E1B1B), 
                  elevation: 0, 
                  shape: const CircleBorder(), // Explicitly circular
                  child: const Icon(Icons.edit, size: 16, color: Colors.white), // Reduced icon size
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPrimaryInfoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  '${widget.user.firstName}, ${widget.user.age ?? ""}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.user.verifiedStatus == 'active')
                const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Icon(Icons.verified, color: Colors.blue, size: 28),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 16, color: isDark ? Colors.white54 : Colors.black54),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text, 
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onConnect,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Connect with Me', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onFavorite,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Favorite'),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.outlined(
                onPressed: widget.onSkip,
                icon: const Icon(Icons.close),
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(bool isDark, String title, IconData icon, Widget content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 24, color: QaboolTheme.primary),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }

  Widget _buildVerifiedProfile(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.verified, color: Colors.blue),
            const SizedBox(width: 12),
            const Text('Verified profile', style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Icon(Icons.info_outline, color: isDark ? Colors.white54 : Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildComplimentSection(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('COMPLIMENT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.grey)),
            const SizedBox(height: 8),
            Text('Don\'t wait, chat with ${widget.user.firstName} now.', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              maxLines: 4,
              cursorColor: QaboolTheme.primary,
              decoration: InputDecoration(
                hintText: 'Let them know what you like about their profile',
                hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey[400]),
                fillColor: isDark ? Colors.black : Colors.white,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBCB8CC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
                child: const Text('Submit', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryActions(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSecondaryActionButton(Icons.star_outline, 'Favourite', isDark, onTap: widget.onFavorite),
              _buildSecondaryActionButton(Icons.block, 'Block', isDark, onTap: widget.onBlock),
              _buildSecondaryActionButton(Icons.flag_outlined, 'Report', isDark, onTap: widget.onReport),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIssuesBadges(bool isDark) {
    if (!widget.user.managedBySomeoneElse && !widget.user.facingChallenges) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          if (widget.user.managedBySomeoneElse)
            _buildBadge(
              icon: Icons.verified_user_outlined,
              label: 'REPRESENTATIVE',
              color: const Color(0xFFD4AF37), // Gold
              isDark: isDark,
            ),
          if (widget.user.facingChallenges)
            _buildBadge(
              icon: Icons.warning_amber_rounded,
              label: 'CHALLENGES',
              color: QaboolTheme.primary,
              isDark: isDark,
            ),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.4), width: 1.0),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryActionButton(IconData icon, String label, bool isDark, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 28, color: isDark ? Colors.white70 : Colors.black87),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildBottomActions(Color primaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCircularButton(Icons.close, const Color(0xFF3B3B3B), 65, widget.onSkip ?? () {}),
        const SizedBox(width: 20),
        _buildCircularButton(Icons.star_outline, const Color(0xFF4A4E69), 65, widget.onFavorite ?? () {}),
        const SizedBox(width: 20),
        _buildCircularButton(Icons.check, const Color(0xFFFF4B6E), 65, widget.onConnect ?? () {}, isMain: true),
      ],
    );
  }

  Widget _buildCircularButton(IconData icon, Color bgColor, double size, VoidCallback onTap, {bool isMain = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.4),
      ),
    );
  }

  Widget _buildInfoBubble(String text, bool isDark, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: isDark ? Colors.white70 : Colors.black54),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _RequirementData {
  final IconData icon;
  final String label;
  final String value;
  _RequirementData(this.icon, this.label, this.value);
}
