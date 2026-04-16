import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qabool_app/theme.dart';
import 'package:qabool_app/services/auth_service.dart';
import 'package:qabool_app/services/profile_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:qabool_app/services/api_service.dart';
import 'package:qabool_app/utils/image_utils.dart';

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
  late TextEditingController _weightController;
  late TextEditingController _heightCmController;
  late TextEditingController _heightFtController;
  late TextEditingController _heightInController;
  late TextEditingController _emailController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _currentCityController;
  late TextEditingController _languageController;

  bool _managedBySomeoneElse = false;
  bool _facingChallenges = false;
  bool _readyToQaboolChallenges = false;
  
  List<String> _selectedFacingChallenges = [];
  List<String> _selectedReadyToQaboolChallenges = [];

  final List<String> _challengeOptions = [
    'Age problem',
    'Sexual disorder',
    'Financial problem',
    'Divorced with/without children',
    'Widow',
    'Physical disability',
    'Already married',
    'Any other issue'
  ];
  
  DateTime? _selectedDob;
  String? _selectedGender;
  String? _selectedEthnicity;
  String? _selectedCountry;
  String? _selectedCity;
  String? _selectedReligion;
  String? _selectedMaritalStatus;
  String? _selectedMonthlyIncome;
  String? _selectedSiblings;
  String? _selectedFamilyMembers;
  String? _selectedLookingForAge;
  String? _selectedLookingForType;
  String? _selectedEducation;
  String _heightUnit = 'cm';
  String _weightUnit = 'kg';
  XFile? _pickedImage;

  List<String> _selectedPersonalityTraits = [];
  final List<String> _personalityOfferings = [
    '😊 Kind', '🧠 Intellectual', '🤣 Humorous', '🎨 Creative', '🤫 Introverted', '🗣️ Extroverted', '🧘 Calm', '⚡ Energetic', '🤝 Empathetic', '🧗 Adventurous'
  ];

  List<String> _selectedLifeStyle = [];
  final List<String> _lifestyleOfferings = [
    '🚭 Non-smoker', '🍽️ Halal only', '🕌 Praying five times', '🏋️ Fitness enthusiast', '🍳 Foodie', '✈️ Traveler', '🎮 Gamer', '🐈 Pet lover'
  ];

  List<String> _selectedInterests = [];
  final List<String> _availableInterests = [
    'Cooking', 'Traveling', 'Reading', 'Coding', 'Gaming', 
    'Music', 'Art', 'Sports', 'Photography', 'Fitness', 
    'Movies', 'Outdoors', 'Coffee', 'Animals', 'Gardening'
  ];

  late TextEditingController _grewUpInController;
   bool _isLoading = false;

  final Map<String, List<String>> _countryCities = {
    'Germany': ['Berlin', 'Munich', 'Hamburg', 'Frankfurt', 'Stuttgart'],
    'Bangladesh': ['Dhaka', 'Chittagong', 'Sylhet', 'Rajshahi', 'Khulna'],
    'Pakistan': ['Karachi', 'Lahore', 'Islamabad', 'Faisalabad', 'Multan'],
    'India': ['Mumbai', 'Delhi', 'Bangalore', 'Hyderabad', 'Chennai'],
    'Canada': ['Toronto', 'Vancouver', 'Montreal', 'Calgary', 'Ottawa'],
    'USA': ['New York', 'Los Angeles', 'Chicago', 'Houston', 'Miami'],
  };

  final List<String> _ethnicities = [
    'South Asian',
    'East Asian',
    'Asian',
    'Middle Eastern',
    'White / Caucasian',
    'Black / African',
    'Hispanic / Latino',
    'Mixed / Other',
  ];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().currentUser;
    _firstNameController = TextEditingController(text: user?.firstName);
    _lastNameController = TextEditingController(text: user?.lastName);
    _bioController = TextEditingController(text: user?.bio);
    _weightController = TextEditingController(text: user?.weight?.toStringAsFixed(1));
    _heightCmController = TextEditingController(text: user?.height?.toStringAsFixed(0));
    _heightFtController = TextEditingController();
    _heightInController = TextEditingController();
    _emailController = TextEditingController(text: user?.email);
    _phoneNumberController = TextEditingController(text: user?.phoneNumber);
    _currentCityController = TextEditingController(text: user?.currentCity);

    debugPrint('DEBUG: EditProfileScreen initState');
    debugPrint('DEBUG: user.bio: ${user?.bio}');
    debugPrint('DEBUG: user.phoneNumber: ${user?.phoneNumber}');

    _selectedDob = user?.dob;
    _selectedGender = user?.gender;
    _selectedEthnicity = user?.ethnicity;
    _selectedReligion = user?.religion;
    _selectedMaritalStatus = user?.maritalStatus;
    _selectedMonthlyIncome = user?.monthlyIncome?.toStringAsFixed(0);
    _selectedSiblings = user?.siblings?.toString();
    _selectedFamilyMembers = user?.familyMembers?.toString();
    _selectedLookingForAge = user?.lookingForAge;
    _selectedLookingForType = user?.lookingForType;
    _selectedEducation = user?.education;
    _grewUpInController = TextEditingController(text: user?.grewUpIn);
    
    _selectedFacingChallenges = List<String>.from(user?.facingChallengesList ?? [])
        .where((e) => _challengeOptions.any((opt) => opt.toLowerCase() == e.toLowerCase())).toList();
    _selectedReadyToQaboolChallenges = List<String>.from(user?.readyToQaboolChallengesList ?? [])
        .where((e) => _challengeOptions.any((opt) => opt.toLowerCase() == e.toLowerCase())).toList();
    _selectedInterests = List<String>.from(user?.interests ?? [])
        .where((e) => _availableInterests.any((opt) => opt.toLowerCase() == e.toLowerCase())).toList();
    _selectedPersonalityTraits = List<String>.from(user?.personalityTraits ?? [])
        .where((e) => _personalityOfferings.any((opt) => opt.toLowerCase() == e.toLowerCase())).toList();
    _selectedLifeStyle = List<String>.from(user?.lifeStyle ?? [])
        .where((e) => _lifestyleOfferings.any((opt) => opt.toLowerCase() == e.toLowerCase())).toList();

    _languageController = TextEditingController(text: user?.language);
    _facingChallenges = user?.facingChallenges ?? false;
    _readyToQaboolChallenges = user?.readyToQaboolChallenges ?? false;
    _managedBySomeoneElse = user?.managedBySomeoneElse ?? false;

    // Handle Region Decomposition
    if (user?.region != null && user!.region!.contains(',')) {
      final parts = user.region!.split(',');
      final cityPart = parts.first.trim();
      final countryPart = parts.last.trim();
      
      if (_countryCities.containsKey(countryPart)) {
        _selectedCountry = countryPart;
        if (_countryCities[countryPart]!.contains(cityPart)) {
          _selectedCity = cityPart;
        }
      }
    }

    // Initialize Ft/In if height exists
    if (user?.height != null) {
      final totalInches = user!.height! / 2.54;
      final feet = (totalInches / 12).floor();
      final inches = (totalInches % 12).round();
      _heightFtController.text = feet.toString();
      _heightInController.text = inches.toString();
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    _weightController.dispose();
    _heightCmController.dispose();
    _heightFtController.dispose();
    _heightInController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _currentCityController.dispose();
    _grewUpInController.dispose();
    _languageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _pickedImage = image);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: QaboolTheme.primary,
              primary: QaboolTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDob) {
      setState(() => _selectedDob = picked);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_firstNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('First Name is required')));
      return;
    }

    if (_bioController.text.isNotEmpty && _bioController.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bio must be at least 10 characters')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Height Conversion
      double? heightCm;
      if (_heightUnit == 'cm') {
        heightCm = double.tryParse(_heightCmController.text);
      } else {
        final ft = double.tryParse(_heightFtController.text) ?? 0;
        final inc = double.tryParse(_heightInController.text) ?? 0;
        heightCm = (ft * 30.48) + (inc * 2.54);
      }

      // Weight Conversion
      double? weightKg = double.tryParse(_weightController.text);
      if (_weightUnit == 'lbs' && weightKg != null) {
        weightKg = weightKg * 0.453592;
      }

      final updatedData = {
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        // Removed email from update to avoid potential 400 error (often restricted)
        'phoneNumber': _phoneNumberController.text,
        'bio': _bioController.text,
        'gender': _selectedGender,
        'dob': _selectedDob?.toIso8601String(),
        'ethnicity': _selectedEthnicity,
        'religion': _selectedReligion,
        'height': heightCm,
        'weight': weightKg,
        'maritalStatus': _selectedMaritalStatus,
        'currentCity': _currentCityController.text,
        'monthlyIncome': double.tryParse(_selectedMonthlyIncome ?? ""),
        'siblings': int.tryParse(_selectedSiblings ?? ""),
        'familyMembers': int.tryParse(_selectedFamilyMembers ?? ""),
        'lookingForAge': _selectedLookingForAge,
        'lookingForType': _selectedLookingForType,
        'education': _selectedEducation,
        'region': _selectedCountry != null && _selectedCity != null ? "${_selectedCity}, ${_selectedCountry}" : null,
        'personalityTraits': _selectedPersonalityTraits,
        'lifeStyle': _selectedLifeStyle,
        'interests': _selectedInterests,
        'grewUpIn': _grewUpInController.text,
        'managedBySomeoneElse': _managedBySomeoneElse,
        'facingChallenges': _facingChallenges,
        'facingChallengesList': _selectedFacingChallenges,
        'readyToQaboolChallenges': _readyToQaboolChallenges,
        'readyToQaboolChallengesList': _selectedReadyToQaboolChallenges,
        'language': _languageController.text,
      };

      final updatedUser = await context.read<ProfileService>().updateProfile(updatedData, image: _pickedImage);
      
      if (mounted) {
        await context.read<AuthService>().updateCurrentUser(updatedUser);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.replaceFirst('Exception: ', '');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: QaboolTheme.primary,
          ),
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
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              // Fallback to MainScreen which hosts the ProfileView
              Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
            }
          },
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
              const SizedBox(height: 16),
              
              // Profile Photo
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? const Color(0xFF2D2626) : Colors.grey[200],
                              border: Border.all(color: QaboolTheme.primary, width: 2),
                              image: _pickedImage != null
                                  ? DecorationImage(
                                      image: kIsWeb
                                          ? NetworkImage(_pickedImage!.path)
                                          : FileImage(File(_pickedImage!.path)) as ImageProvider,
                                      fit: BoxFit.cover,
                                    )
                                  : (context.read<AuthService>().currentUser?.profileImageUrl != null
                                      ? DecorationImage(
                                          image: NetworkImage(resolveImageUrl(context.read<AuthService>().currentUser!.profileImageUrl)),
                                          fit: BoxFit.cover,
                                        )
                                      : null),
                            ),
                            child: _pickedImage == null && context.read<AuthService>().currentUser?.profileImageUrl == null
                                ? const Icon(Icons.person, size: 50, color: QaboolTheme.primary)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: QaboolTheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Change Photo',
                      style: TextStyle(
                        fontSize: 12,
                        color: QaboolTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('BASIC INFORMATION'),
              const SizedBox(height: 16),
              _buildTextField(controller: _firstNameController, label: 'First Name', icon: Icons.person),
              const SizedBox(height: 16),
              _buildTextField(controller: _lastNameController, label: 'Last Name', icon: Icons.person_outline),
              const SizedBox(height: 16),
              _buildGenderDropdown(),
              const SizedBox(height: 16),

              // Date of Birth
              Text('Date of Birth', style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600], fontSize: 12)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDate(context),
                child: IgnorePointer(
                  child: _buildTextField(
                    controller: TextEditingController(
                      text: _selectedDob == null ? '' : "${_selectedDob!.day}/${_selectedDob!.month}/${_selectedDob!.year}",
                    ),
                    label: 'Date of Birth',
                    icon: Icons.calendar_today,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _buildTextField(controller: _bioController, label: 'Bio', icon: Icons.edit, maxLines: 3),
              const SizedBox(height: 32),

              _buildSectionTitle('CONTACT INFORMATION'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: 'Email Address',
                icon: Icons.email,
                enabled: false, // Email is typically read-only in profile
              ),
              const SizedBox(height: 16),
              _buildTextField(controller: _phoneNumberController, label: 'Phone Number', icon: Icons.phone),
              const SizedBox(height: 32),
              
              _buildSectionTitle('LOCATION & BACKGROUND'),
              const SizedBox(height: 16),

              // Country Dropdown
              _buildDropdownField(
                label: 'Country',
                icon: Icons.public,
                value: _selectedCountry,
                items: _countryCities.keys.toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCountry = val;
                    _selectedCity = null;
                  });
                },
              ),
              const SizedBox(height: 16),

              // City Dropdown
              _buildDropdownField(
                label: 'City',
                icon: Icons.location_city,
                value: _selectedCity,
                items: _selectedCountry != null ? _countryCities[_selectedCountry]! : [],
                onChanged: (val) => setState(() => _selectedCity = val),
              ),
              const SizedBox(height: 16),

              // Race/Ethnicity
              _buildDropdownField(
                label: 'Race/Ethnicity',
                icon: Icons.people_outline,
                value: _selectedEthnicity,
                items: _ethnicities,
                onChanged: (val) => setState(() => _selectedEthnicity = val),
              ),
              const SizedBox(height: 16),

              // Religion
              _buildDropdownField(
                label: 'Religion/Caste',
                icon: Icons.church,
                value: _selectedReligion,
                items: ['Islam (Sunni)', 'Islam (Shia)', 'Islam (Other)', 'Other'],
                onChanged: (val) => setState(() => _selectedReligion = val),
              ),
              const SizedBox(height: 16),
              _buildTextField(controller: _currentCityController, label: 'Current City', icon: Icons.home_work),
              const SizedBox(height: 32),

              _buildSectionTitle('FAMILY & SOCIAL'),
              const SizedBox(height: 16),
              _buildDropdownField(
                label: 'Marital Status',
                icon: Icons.favorite_border,
                value: _selectedMaritalStatus,
                items: ['Single', 'Divorced', 'Widowed', 'Separated'],
                onChanged: (val) => setState(() => _selectedMaritalStatus = val),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdownField(
                      label: 'Siblings',
                      icon: Icons.people_outline,
                      value: _selectedSiblings,
                      items: ['0', '1', '2', '3', '4', '5', '6+'],
                      onChanged: (val) => setState(() => _selectedSiblings = val),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdownField(
                      label: 'Family Members',
                      icon: Icons.group,
                      value: _selectedFamilyMembers,
                      items: ['1', '2', '3', '4', '5', '6', '7', '8+'],
                      onChanged: (val) => setState(() => _selectedFamilyMembers = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              _buildSectionTitle('FINANCIAL'),
              const SizedBox(height: 16),
              _buildDropdownField(
                label: 'Monthly Income (Euro)',
                icon: Icons.payments,
                value: _selectedMonthlyIncome,
                items: ['0', '500', '1000', '2000', '3000', '4000', '5000', '7500', '10000'],
                onChanged: (val) => setState(() => _selectedMonthlyIncome = val),
              ),
              const SizedBox(height: 32),

              _buildSectionTitle('PHYSICAL ATTRIBUTES'),
              const SizedBox(height: 16),

              // Height
              Text('Height', style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600], fontSize: 12)),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (_heightUnit == 'cm')
                    Expanded(
                      flex: 2,
                      child: _buildTextField(controller: _heightCmController, label: 'cm', icon: Icons.height),
                    )
                  else ...[
                    Expanded(
                      child: _buildTextField(controller: _heightFtController, label: 'ft', icon: Icons.height),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTextField(controller: _heightInController, label: 'in', icon: Icons.straighten),
                    ),
                  ],
                  const SizedBox(width: 8),
                  _buildUnitSelector(_heightUnit, (val) => setState(() => _heightUnit = val!), ['cm', 'ft']),
                ],
              ),
              const SizedBox(height: 16),

              // Weight
              Text('Weight', style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600], fontSize: 12)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildTextField(controller: _weightController, label: 'Weight', icon: Icons.monitor_weight),
                  ),
                  const SizedBox(width: 8),
                  _buildUnitSelector(_weightUnit, (val) => setState(() => _weightUnit = val!), ['kg', 'lbs']),
                ],
              ),
              const SizedBox(height: 32),
              
              _buildSectionTitle('EDUCATION & LANGUAGE'),
              const SizedBox(height: 16),
              _buildDropdownField(
                label: 'Education',
                icon: Icons.school,
                value: _selectedEducation,
                items: ['High School', 'Bachelors Degree', 'Masters Degree', 'PhD', 'Other'],
                onChanged: (val) => setState(() => _selectedEducation = val),
              ),
              const SizedBox(height: 16),
              _buildTextField(controller: _languageController, label: 'Native/Preferred Language', icon: Icons.translate),
              const SizedBox(height: 32),

              _buildSectionTitle('MANAGEMENT & CHALLENGES'),
              const SizedBox(height: 16),
              
              SwitchListTile(
                title: Text('Managed by a Representative', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14)),
                subtitle: Text('Toggle if your parents/representative manages this account', style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600], fontSize: 12)),
                secondary: Icon(Icons.supervisor_account, color: primaryColor),
                value: _managedBySomeoneElse,
                activeColor: primaryColor,
                onChanged: (val) => setState(() => _managedBySomeoneElse = val),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),

              SwitchListTile(
                title: Text('Is Facing Challenges', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14)),
                subtitle: Text('Toggle if you are facing any personal challenges', style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600], fontSize: 12)),
                secondary: Icon(Icons.warning_amber_rounded, color: primaryColor),
                value: _facingChallenges,
                activeColor: primaryColor,
                onChanged: (val) => setState(() => _facingChallenges = val),
                contentPadding: EdgeInsets.zero,
              ),
              if (_facingChallenges) ...[
                const SizedBox(height: 8),
                _buildMultiSelect(
                  title: 'Your Challenges (Max 5)',
                  offerings: _challengeOptions,
                  selectedList: _selectedFacingChallenges,
                  maxSelect: 5,
                  onChanged: (list) => setState(() => _selectedFacingChallenges = list),
                ),
              ],
              const SizedBox(height: 16),

              SwitchListTile(
                title: Text('Ready to Qabool Challenges', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14)),
                subtitle: Text('Toggle if you are ready to accept partner with challenges', style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600], fontSize: 12)),
                secondary: Icon(Icons.volunteer_activism_outlined, color: primaryColor),
                value: _readyToQaboolChallenges,
                activeColor: primaryColor,
                onChanged: (val) => setState(() => _readyToQaboolChallenges = val),
                contentPadding: EdgeInsets.zero,
              ),
              if (_readyToQaboolChallenges) ...[
                const SizedBox(height: 8),
                _buildMultiSelect(
                  title: 'Ready to Qabool Challenges (Max 5)',
                  offerings: _challengeOptions,
                  selectedList: _selectedReadyToQaboolChallenges,
                  maxSelect: 5,
                  onChanged: (newList) {
                    setState(() {
                      _selectedReadyToQaboolChallenges = newList;
                    });
                  },
                ),
              ],
              const SizedBox(height: 32),



              _buildSectionTitle('PROFILE BUBBLES'),
              const SizedBox(height: 16),
              _buildTextField(controller: _grewUpInController, label: 'Where did you grow up?', icon: Icons.flag),
              const SizedBox(height: 24),
              _buildMultiSelect(
                title: 'Personality Traits',
                offerings: _personalityOfferings,
                selectedList: _selectedPersonalityTraits,
                maxSelect: 5,
                onChanged: (list) => setState(() => _selectedPersonalityTraits = list),
              ),
              const SizedBox(height: 16),
              _buildMultiSelect(
                title: 'Life Style',
                offerings: _lifestyleOfferings,
                selectedList: _selectedLifeStyle,
                maxSelect: 5,
                onChanged: (list) => setState(() => _selectedLifeStyle = list),
              ),
              const SizedBox(height: 16),
              _buildMultiSelect(
                title: 'Interests',
                offerings: _availableInterests,
                selectedList: _selectedInterests,
                maxSelect: 5,
                onChanged: (list) => setState(() => _selectedInterests = list),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMultiSelect({
    required String title,
    required List<String> offerings,
    required List<String> selectedList,
    required int maxSelect,
    required Function(List<String>) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pColor = QaboolTheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title.toUpperCase()),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: offerings.map((item) {
            // Case-insensitive check to ensure robustness
            final bool isSelected = selectedList.any((e) => e.toLowerCase() == item.toLowerCase());
            
            return GestureDetector(
              onTap: () {
                final newList = List<String>.from(selectedList);
                if (isSelected) {
                  newList.removeWhere((e) => e.toLowerCase() == item.toLowerCase());
                } else {
                  // Only count items that are actually in the current offerings
                  final validCount = newList.where((e) => offerings.any((opt) => opt.toLowerCase() == e.toLowerCase())).length;
                  
                  if (validCount < maxSelect) {
                    newList.add(item);
                  } else {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Maximum $maxSelect items allowed for $title'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        backgroundColor: pColor,
                      ),
                    );
                    return;
                  }
                }
                onChanged(newList);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? pColor 
                      : (isDark ? const Color(0xFF2D2626) : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected 
                        ? pColor 
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      const Icon(Icons.check, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      item,
                      style: TextStyle(
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
      ],
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
    bool enabled = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      enabled: enabled,
      style: TextStyle(color: enabled ? (isDark ? Colors.white : Colors.black87) : Colors.grey),
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

  Widget _buildGenderDropdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.read<AuthService>().currentUser;
    _selectedGender ??= user?.gender;

    final dropdownItems = ['Male', 'Female'];
    if (_selectedGender != null && !dropdownItems.contains(_selectedGender)) {
      dropdownItems.add(_selectedGender!);
    }

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
      items: dropdownItems
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: (val) {
        setState(() {
          _selectedGender = val;
        });
      },
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dropdownItems = List<String>.from(items);
    if (value != null && !dropdownItems.contains(value)) {
      dropdownItems.add(value);
    }

    return DropdownButtonFormField<String>(
      value: value,
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
      items: dropdownItems.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildUnitSelector(String value, Function(String?) onChanged, List<String> units) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      flex: 1,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D2626) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: QaboolTheme.primary.withOpacity(0.3)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down, color: QaboolTheme.primary),
            items: units.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}
