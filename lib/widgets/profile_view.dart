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
              final isLargeScreen = constraints.maxWidth > 900;
              
              if (isLargeScreen) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- LEFT COLUMN (Hero & Primary Info) ---
                    SizedBox(
                      width: 420,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDesktopHeroImage(context, isDark),
                            const SizedBox(height: 24),
                            _buildPrimaryInfoCard(isDark),
                            if (!widget.isMyProfile) ...[
                              const SizedBox(height: 24),
                              _buildActionCard(isDark, primaryColor),
                            ],
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    
                    // --- RIGHT COLUMN (Details) ---
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Profile Details',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : Colors.black87,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 32),
                            
                            // Detailed sections in Cards
                            _buildDetailCard(isDark, 'Bio', Icons.format_quote, _buildBioContent(isDark)),
                            const SizedBox(height: 24),
                            
                            _buildDetailCard(isDark, 'About me', Icons.person_outline, _buildAboutMeContent(isDark)),
                            const SizedBox(height: 24),

                            _buildDetailCard(isDark, 'Marriage Intentions', Icons.favorite_border, _buildMarriageIntentionsContent(isDark, primaryColor)),
                            const SizedBox(height: 24),
                            
                            _buildDetailCard(isDark, 'My faith', Icons.nightlight_round, _buildMyFaithContent(isDark)),
                            const SizedBox(height: 24),

                            _buildDetailCard(isDark, 'Education & Career', Icons.school_outlined, _buildEducationCareerContent(isDark)),
                            const SizedBox(height: 24),

                            _buildDetailCard(isDark, 'Interests & Personality', Icons.auto_awesome_outlined, Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInterestsContent(isDark),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Divider(),
                                ),
                                _buildPersonalityContent(isDark),
                              ],
                            )),
                            const SizedBox(height: 24),

                            _buildDetailCard(isDark, 'Languages & Ethnicity', Icons.translate, _buildLanguagesEthnicityContent(isDark)),
                            const SizedBox(height: 24),

                            _buildDetailCard(isDark, 'Preferences', Icons.tune, _buildPreferenceContent(isDark)),
                            
                            if (!widget.isMyProfile) ...[
                              const SizedBox(height: 48),
                              _buildSecondaryActions(isDark),
                            ],
                            
                            const SizedBox(height: 80),
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
                        _buildAboutMeSection(isDark),
                        _buildMarriageIntentionsSection(isDark, primaryColor),
                        _buildMyFaithSection(isDark),
                        _buildInterestsSection(isDark),
                        _buildPersonalitySection(isDark),
                        _buildEducationCareerSection(isDark),
                        _buildLanguagesEthnicitySection(isDark),
                        _buildBioSection(isDark),
                        _buildPreferenceSection(isDark),
                        if (!widget.isMyProfile) _buildSecondaryActions(isDark),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Floating Action Buttons at Bottom (Hidden for My Profile, only for mobile)
          if (!widget.isMyProfile)
            Consumer<NavigationService>(
              builder: (context, nav, _) {
                final isNavVisible = nav.isBottomNavVisible;
                final screenWidth = MediaQuery.of(context).size.width;
                if (screenWidth > 900) return const SizedBox.shrink(); // Action card handles it on desktop
                
                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  bottom: isNavVisible ? 85 : 20,
                  left: 0,
                  right: 0,
                  child: _buildBottomActions(primaryColor),
                );
              },
            ),
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
                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                const Text('Active today', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildImageBubble(widget.user.country, Icons.flag),
                  _buildImageBubble(widget.user.profession ?? "", Icons.work),
                  _buildImageBubble(widget.user.religion ?? "", Icons.nightlight_round),
                  _buildImageBubble(widget.user.ethnicity ?? "", Icons.public),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageBubble(String text, IconData icon) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black,
          letterSpacing: -0.5,
        ),
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
        _buildSectionHeader('About me', Icons.person_outline, isDark),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: _buildAboutMeContent(isDark),
        ),
      ],
    );
  }

  Widget _buildAboutMeContent(bool isDark) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildProfileBubble('🎂 ${widget.user.age} years', null, isDark),
        _buildProfileBubble('📏 ${widget.user.height?.toInt()} cm', null, isDark),
        _buildProfileBubble('⚖️ ${widget.user.weight?.toInt()} kg', null, isDark),
        _buildProfileBubble('💍 ${widget.user.maritalStatus ?? "Single"}', null, isDark),
        _buildProfileBubble('👶 ${widget.user.hasChildren ?? "No children"}', null, isDark),
      ],
    );
  }

  Widget _buildMarriageIntentionsSection(bool isDark, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Marriage Intentions', Icons.favorite, isDark),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: _buildMarriageIntentionsContent(isDark, primaryColor),
        ),
      ],
    );
  }

  Widget _buildMarriageIntentionsContent(bool isDark, Color primaryColor) {
    final value = double.tryParse(widget.user.marriageIntentions ?? "0.5") ?? 0.5;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Align(
                alignment: Alignment(value * 2 - 1, 0),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: QaboolTheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: QaboolTheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Match!', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
              Text('Agree together', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
              Text('4-12 months', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
            ],
          ),
        ],
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

  Widget _buildMyFaithSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('My faith', Icons.nightlight_round, isDark),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: _buildMyFaithContent(isDark),
        ),
      ],
    );
  }

  Widget _buildMyFaithContent(bool isDark) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildProfileBubble('🕌 ${widget.user.religion ?? "Not specified"}', null, isDark),
        if (widget.user.sect != null) _buildProfileBubble('🛐 ${widget.user.sect!}', null, isDark),
        if (widget.user.caste != null) _buildProfileBubble('👥 ${widget.user.caste!}', null, isDark),
      ],
    );
  }

  Widget _buildFuturePlansSection(bool isDark) {
    // Note: Originally preferences were placed here, now moved back to Preference Section.
    // If you have actual future plans data, add it here. Otherwise, shrink if empty.
    return const SizedBox.shrink();
  }

  Widget _buildInterestsSection(bool isDark) {
    if (widget.user.interests.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Interests', Icons.auto_awesome, isDark),
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
        _buildSectionHeader('Personality', Icons.psychology, isDark),
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

  Widget _buildEducationCareerSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Education and career', Icons.school, isDark),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: _buildEducationCareerContent(isDark),
        ),
      ],
    );
  }

  Widget _buildEducationCareerContent(bool isDark) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildProfileBubble('🎓 ${widget.user.education ?? "Not specified"}', null, isDark),
        _buildProfileBubble('💼 ${widget.user.profession ?? "Not specified"}', null, isDark),
      ],
    );
  }

  Widget _buildLanguagesEthnicitySection(bool isDark) {
    if (widget.user.languages.isEmpty && widget.user.grewUpIn == null && widget.user.ethnicity == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Languages and ethnicity', Icons.translate, isDark),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: _buildLanguagesEthnicityContent(isDark),
        ),
      ],
    );
  }

  Widget _buildLanguagesEthnicityContent(bool isDark) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        ...widget.user.languages.map((lang) => _buildProfileBubble(lang, Icons.translate, isDark)),
        if (widget.user.grewUpIn != null) _buildProfileBubble('Grew up in ${widget.user.grewUpIn}', null, isDark),
        if (widget.user.ethnicity != null) _buildProfileBubble('🌍 ${widget.user.ethnicity}', null, isDark),
      ],
    );
  }

  Widget _buildBioSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Bio', Icons.format_quote, isDark),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: _buildBioContent(isDark),
        ),
      ],
    );
  }

  Widget _buildBioContent(bool isDark) {
    return Text(
      widget.user.bio ?? "No bio provided.",
      style: TextStyle(
        fontSize: 15,
        height: 1.6,
        color: isDark ? Colors.white70 : Colors.black87,
      ),
    );
  }

  Widget _buildPreferenceSection(bool isDark) {
    final hasPreferences = widget.user.lookingForAge != null || 
                           widget.user.lookingForType != null || 
                           widget.user.lookingForProfession != null || 
                           widget.user.hasPastIssues || 
                           widget.user.acceptsPastIssues;

    if (!hasPreferences) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Preferences', Icons.tune, isDark),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: _buildPreferenceContent(isDark),
        ),
      ],
    );
  }

  Widget _buildPreferenceContent(bool isDark) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        if (widget.user.lookingForAge != null) _buildProfileBubble('🎂 Looking for ${widget.user.lookingForAge}', null, isDark),
        if (widget.user.lookingForType != null) _buildProfileBubble('💘 ${widget.user.lookingForType!}', null, isDark),
        if (widget.user.lookingForProfession != null) _buildProfileBubble('💼 ${widget.user.lookingForProfession!}', null, isDark),
        if (widget.user.hasPastIssues && widget.user.pastIssuesDetails != null) 
          _buildProfileBubble('⚠️ Past issues: ${widget.user.pastIssuesDetails}', null, isDark),
        if (widget.user.acceptsPastIssues && widget.user.acceptedPastIssuesDetails != null)
          _buildProfileBubble('✅ Accepts: ${widget.user.acceptedPastIssuesDetails}', null, isDark),
      ],
    );
  }

  // --- NEW DESKTOP HELPER WIDGETS ---

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
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
                  ],
                ),
              ),
            ),
          ),
          if (widget.isMyProfile)
            Positioned(
              top: 16,
              right: 16,
              child: FloatingActionButton.small(
                onPressed: () => Navigator.pushNamed(context, '/edit_profile'),
                backgroundColor: QaboolTheme.primary,
                child: const Icon(Icons.edit, size: 18, color: Colors.white),
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
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
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
            children: [
              Expanded(
                child: Text(
                  '${widget.user.firstName}, ${widget.user.age ?? ""}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              if (widget.user.verifiedStatus == 'active')
                const Icon(Icons.verified, color: Colors.blue, size: 28),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                widget.user.region ?? 'No location',
                style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.work_outline, widget.user.profession ?? 'Not specified', isDark),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.nightlight_round, widget.user.religion ?? 'Not specified', isDark),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.public, widget.user.ethnicity ?? 'Not specified', isDark),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 16, color: isDark ? Colors.white54 : Colors.black54),
        const SizedBox(width: 12),
        Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87)),
      ],
    );
  }

  Widget _buildActionCard(bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primaryColor.withOpacity(0.1)),
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
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
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
          const SizedBox(height: 24),
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
          TextButton.icon(
            onPressed: () {},
            icon: Icon(Icons.share, color: isDark ? Colors.white : Colors.black),
            label: Text('Share profile', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
          ),
          const Divider(),
          const SizedBox(height: 20),
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
