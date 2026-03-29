import 'package:flutter/material.dart';
import 'package:qabool_app/theme.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/profile_service.dart';
import 'profile_screen.dart';
import '../theme.dart';
import '../utils/image_utils.dart';

class FavoritesScreen extends StatefulWidget {
  final bool isEmbedded;
  final VoidCallback? onBack;

  const FavoritesScreen({
    super.key,
    this.isEmbedded = false,
    this.onBack,
  });

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = QaboolTheme.primary;
    
    final content = DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.only(top: widget.isEmbedded ? 0 : MediaQuery.of(context).padding.top),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                AppBar(
                  title: const Text(
                    'Favorites',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: -0.5,
                      color: QaboolTheme.primary,
                    ),
                  ),
                  centerTitle: true,
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  leading: widget.isEmbedded 
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                        onPressed: widget.onBack,
                        color: QaboolTheme.primary,
                      )
                    : (Navigator.canPop(context) ? const BackButton() : null),
                ),
                TabBar(
                  tabs: const [
                    Tab(text: 'My Favorites'),
                    Tab(text: 'Who Liked Me'),
                  ],
                  labelColor: primaryColor,
                  unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
                  indicatorColor: primaryColor,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  dividerColor: Colors.transparent,
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                FavoritesList(type: 'my', isEmbedded: widget.isEmbedded),
                FavoritesList(type: 'by-whom', isEmbedded: widget.isEmbedded),
              ],
            ),
          ),
        ],
      ),
    );

    if (widget.isEmbedded) {
      return Material(
        color: Colors.transparent,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1616) : const Color(0xFFFDFCFB),
      body: content,
    );
  }
}

class FavoritesList extends StatefulWidget {
  final String type;
  final bool isEmbedded;
  const FavoritesList({super.key, required this.type, this.isEmbedded = false});

  @override
  State<FavoritesList> createState() => _FavoritesListState();
}

class _FavoritesListState extends State<FavoritesList> {
  late Future<List<UserModel>> _future;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _future = widget.type == 'my' 
        ? context.read<ProfileService>().getMyFavorites() 
        : context.read<ProfileService>().getUsersWhoFavoritedMe();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return FutureBuilder<List<UserModel>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: QaboolTheme.primary,
              strokeWidth: 2,
            ),
          );
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: QaboolTheme.primary)));
        }
        
        final profiles = snapshot.data ?? [];
        if (profiles.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.type == 'my' ? Icons.favorite_border : Icons.people_outline,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  widget.type == 'my' ? 'No favorites added' : 'No one has favorited you yet',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        final isLargeScreen = MediaQuery.of(context).size.width > 800;

        if (isLargeScreen && !widget.isEmbedded) {
          return GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3.5,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
            ),
            itemCount: profiles.length,
            itemBuilder: (context, index) => _buildUserCard(profiles[index], isDark),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          itemCount: profiles.length,
          itemBuilder: (context, index) => _buildUserCard(profiles[index], isDark),
        );
      },
    );
  }

  Widget _buildUserCard(UserModel profile, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: QaboolTheme.accentGold.withOpacity(0.5), width: 1.5),
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundImage: profile.profileImageUrl != null 
                  ? NetworkImage(resolveImageUrl(profile.profileImageUrl!)) 
                  : null,
              child: profile.profileImageUrl == null 
                  ? const Icon(Icons.person, color: QaboolTheme.primary) 
                  : null,
            ),
          ),
          title: Text(
            profile.fullName,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                '${profile.age ?? "?"} • ${profile.religion ?? "Not specified"}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                profile.profession ?? 'No profession mentioned',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                ),
              ),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: QaboolTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chevron_right_rounded, color: QaboolTheme.primary, size: 20),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfileScreen(user: profile)),
            );
          },
        ),
      ),
    );
  }
}
