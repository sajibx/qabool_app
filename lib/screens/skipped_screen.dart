import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qabool_app/services/profile_service.dart';
import 'package:qabool_app/models/user_model.dart';
import 'package:qabool_app/widgets/user_discovery_card.dart';
import 'package:qabool_app/theme.dart';

class SkippedScreen extends StatefulWidget {
  final bool isEmbedded;
  final VoidCallback? onBack;

  const SkippedScreen({super.key, this.isEmbedded = false, this.onBack});

  @override
  State<SkippedScreen> createState() => _SkippedScreenState();
}

class _SkippedScreenState extends State<SkippedScreen> {
  List<UserModel> _skippedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSkippedUsers();
  }

  Future<void> _fetchSkippedUsers() async {
    try {
      final users = await context.read<ProfileService>().getSkippedUsers();
      if (mounted) {
        setState(() {
          _skippedUsers = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = QaboolTheme.primary;

    return Scaffold(
      backgroundColor: widget.isEmbedded ? Colors.transparent : (isDark ? const Color(0xFF1A1616) : const Color(0xFFFDFCFB)),
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: const Text('Skipped Profiles', style: TextStyle(fontWeight: FontWeight.bold, color: QaboolTheme.primary)),
              centerTitle: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: QaboolTheme.primary, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
      body: Column(
        children: [
          if (widget.isEmbedded && widget.onBack != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 20),
                    onPressed: widget.onBack,
                  ),
                  const Text('Skipped Profiles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _skippedUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.block_flipped, size: 64, color: Colors.grey.withOpacity(0.5)),
                            const SizedBox(height: 16),
                            Text(
                              'No skipped profiles yet',
                              style: TextStyle(color: Colors.grey[600], fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _skippedUsers.length,
                    itemBuilder: (context, index) {
                      final user = _skippedUsers[index];
                      return UserDiscoveryCard(
                        user: user,
                        isGridMode: true,
                        onConnect: () {}, // Not used in grid mode for skip list usually
                        onFavorite: () {},
                        onSkip: () async {
                          try {
                            await context.read<ProfileService>().unskipUser(user.id);
                            _fetchSkippedUsers();
                          } catch (e) {
                             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

