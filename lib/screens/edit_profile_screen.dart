import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qabool_app/theme.dart';
import 'package:qabool_app/services/auth_service.dart';
import 'package:qabool_app/services/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _bioController;
  late TextEditingController _regionController;
  late TextEditingController _religionController;
  late TextEditingController _professionController;
  late TextEditingController _educationController;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().currentUser;
    _firstNameController = TextEditingController(text: user?.firstName);
    _lastNameController = TextEditingController(text: user?.lastName);
    _bioController = TextEditingController(text: user?.bio);
    _regionController = TextEditingController(text: user?.region);
    _religionController = TextEditingController(text: user?.religion);
    _professionController = TextEditingController(text: user?.profession);
    _educationController = TextEditingController(text: user?.education);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    _regionController.dispose();
    _religionController.dispose();
    _professionController.dispose();
    _educationController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final updatedData = {
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'bio': _bioController.text,
        'gender': _selectedGender,
        'region': _regionController.text,
        'religion': _religionController.text,
        'profession': _professionController.text,
        'education': _educationController.text,
      };

      await context.read<ProfileService>().updateProfile(updatedData);
      // Also update currentUser in AuthService to reflect changes locally immediately
      await context.read<AuthService>().checkAuthStatus();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = QaboolTheme.primary;
    const accentGold = QaboolTheme.accentGold;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1616) : const Color(0xFFFDFCFB),
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text('SAVE', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('BASIC INFORMATION'),
              const SizedBox(height: 16),
              _buildTextField(controller: _firstNameController, label: 'First Name', icon: Icons.person),
              const SizedBox(height: 16),
              _buildTextField(controller: _lastNameController, label: 'Last Name', icon: Icons.person_outline),
              const SizedBox(height: 16),
              _buildGenderDropdown(),
              const SizedBox(height: 16),
              _buildTextField(controller: _bioController, label: 'Bio', icon: Icons.edit, maxLines: 3),
              const SizedBox(height: 32),
              
              _buildSectionTitle('LOCATION & BACKGROUND'),
              const SizedBox(height: 16),
              _buildTextField(controller: _regionController, label: 'Region/Location', icon: Icons.location_on),
              const SizedBox(height: 16),
              _buildTextField(controller: _religionController, label: 'Religion/Caste', icon: Icons.church),
              const SizedBox(height: 32),
              
              _buildSectionTitle('PROFESSIONAL'),
              const SizedBox(height: 16),
              _buildTextField(controller: _professionController, label: 'Profession', icon: Icons.work),
              const SizedBox(height: 16),
              _buildTextField(controller: _educationController, label: 'Education', icon: Icons.school),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: QaboolTheme.primary,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: QaboolTheme.primary),
        labelStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600]),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: QaboolTheme.primary.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: QaboolTheme.primary),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF2D2626) : Colors.white,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          if (label == 'First Name') return 'Required';
        }
        return null;
      },
    );
  }

  String? _selectedGender;

  Widget _buildGenderDropdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.read<AuthService>().currentUser;
    _selectedGender ??= user?.gender;

    return DropdownButtonFormField<String>(
      value: _selectedGender,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: 'Gender',
        prefixIcon: const Icon(Icons.people, color: QaboolTheme.primary),
        labelStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600]),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: QaboolTheme.primary.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: QaboolTheme.primary),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF2D2626) : Colors.white,
      ),
      items: ['Male', 'Female']
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: (val) {
        setState(() {
          _selectedGender = val;
        });
      },
    );
  }
}
