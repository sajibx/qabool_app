import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/profile_service.dart';
import 'profile_screen.dart';
import '../theme.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    final pService = context.read<ProfileService>();
    await Future.wait([
      pService.getMyFavorites(),
      pService.getUsersWhoFavoritedMe(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF1A1616) : const Color(0xFFFDFCFB),
        appBar: AppBar(
          title: const Text('Favorites', style: TextStyle(fontWeight: FontWeight.bold, color: QaboolTheme.primary)),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'My Favorites'),
              Tab(text: 'Who Liked Me'),
            ],
            labelColor: QaboolTheme.primary,
            indicatorColor: QaboolTheme.primary,
          ),
        ),
        body: const TabBarView(
          children: [
            FavoritesList(type: 'my'),
            FavoritesList(type: 'by-whom'),
          ],
        ),
      ),
    );
  }
}

class FavoritesList extends StatelessWidget {
  final String type;
  const FavoritesList({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserModel>>(
      future: type == 'my' 
          ? context.read<ProfileService>().getMyFavorites() 
          : context.read<ProfileService>().getUsersWhoFavoritedMe(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final profiles = snapshot.data ?? [];
        if (profiles.isEmpty) {
          return Center(
            child: Text(
              type == 'my' ? 'No favorites added' : 'No one has favorited you yet',
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: profiles.length,
          itemBuilder: (context, index) {
            final profile = profiles[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: profile.profileImageUrl != null 
                      ? NetworkImage(profile.profileImageUrl!) 
                      : null,
                  child: profile.profileImageUrl == null ? const Icon(Icons.person) : null,
                ),
                title: Text(profile.fullName),
                subtitle: Text(profile.religion ?? 'No religion specified'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfileScreen(user: profile)),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
