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
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Top Image Section
                    _buildTopImage(context, isDark),

                    // 2. Your Similarities
                    _buildSimilaritiesSection(isDark),

                    // 3. About Me Section
                    _buildAboutMeSection(isDark),

                    // 4. Marriage Intentions
                    _buildMarriageIntentionsSection(isDark, primaryColor),

                    // 5. Education and Career
                    _buildEducationCareerSection(isDark),

                    // 6. Languages and Ethnicity
                    _buildLanguagesEthnicitySection(isDark),

                    // 7. Bio
                    _buildBioSection(isDark),

                    // 8. Verified Profile Placeholder
                    _buildVerifiedProfile(isDark),

                    // 9. Compliment Section
                    if (!widget.isMyProfile) _buildComplimentSection(context, isDark),

                    // 10. Secondary Actions (Favorite, Block, Report)
                    if (!widget.isMyProfile) _buildSecondaryActions(isDark),

                    const SizedBox(height: 100), // Reduced space for bottom buttons
                  ],
                ),
              ),
            ),
          ),

          // Floating Action Buttons at Bottom (Hidden for My Profile)
          if (!widget.isMyProfile)
            Consumer<NavigationService>(
              builder: (context, nav, _) {
                final isNavVisible = nav.isBottomNavVisible;
                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  bottom: isNavVisible ? 85 : 20, // Lowered positions
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
    
    // Adjust height based on screen size
    final imageHeight = isLargeScreen 
        ? MediaQuery.of(context).size.height * 0.7 
        : MediaQuery.of(context).size.height * 0.6;

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

  Widget _buildSimilaritiesSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your similarities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'You and ${widget.user.firstName} already share similarities. Explore your connection more.',
            style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 12),
          _buildInfoBubble('Grew up in ${widget.user.grewUpIn ?? "Bangladesh"}', isDark),
        ],
      ),
    );
  }

  Widget _buildAboutMeSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('About me', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildInfoBubble('${widget.user.height?.toInt() ?? "155"}cm', isDark, icon: Icons.height),
              _buildInfoBubble(widget.user.maritalStatus ?? "Single", isDark, icon: Icons.favorite_border),
              _buildInfoBubble(widget.user.hasChildren ?? "No children", isDark, icon: Icons.child_care),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMarriageIntentionsSection(bool isDark, Color primaryColor) {
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
            Text('${widget.user.firstName}\'s marriage intentions', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildMiniBubble('Family', Icons.people, isDark),
                const SizedBox(width: 8),
                _buildMiniBubble('Marriage', Icons.favorite, isDark),
              ],
            ),
            const SizedBox(height: 16),
            // Custom Slider-like UI
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
                ),
                Positioned(
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: const Icon(Icons.favorite, color: Colors.white, size: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Match!', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                Text('Agree together', style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600], fontSize: 10)),
                Text('4-12 months', style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600], fontSize: 10)),
              ],
            ),
          ],
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

  Widget _buildEducationCareerSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Education and career', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildInfoBubble(widget.user.education ?? "Not specified", isDark, icon: Icons.school_outlined),
              _buildInfoBubble(widget.user.profession ?? "Not specified", isDark, icon: Icons.work_outline),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguagesEthnicitySection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Languages and ethnicity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ...widget.user.languages.map((l) => _buildInfoBubble(l, isDark, icon: Icons.translate)),
              _buildInfoBubble('Grew up in ${widget.user.grewUpIn ?? "Bangladesh"}', isDark),
              _buildInfoBubble(widget.user.ethnicity ?? "Bangladeshi", isDark, icon: Icons.flag),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBioSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            widget.user.bio ?? "No bio provided.",
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
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
