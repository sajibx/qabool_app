import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:qabool_app/theme.dart';
import 'package:provider/provider.dart';
import 'package:qabool_app/services/auth_service.dart';
import 'package:qabool_app/services/chat_service.dart';
import 'package:qabool_app/services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
   final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _obscurePassword = true;
  String? _selectedGender;
  DateTime? _selectedDob;
  String? _selectedEthnicity;
  String? _selectedCountry;
  String? _selectedCountryCode;
  String? _selectedCity;
  String? _selectedReligion;
  XFile? _pickedImage;
  
  String _heightUnit = 'cm';
  String _weightUnit = 'kg';

  final _heightCmController = TextEditingController();
  final _heightFtController = TextEditingController();
  final _heightInController = TextEditingController();
  final _weightController = TextEditingController();
  final _educationController = TextEditingController();
  final _bioController = TextEditingController();
  final _currentCityController = TextEditingController();
  final _sectController = TextEditingController();
  final _casteController = TextEditingController();
  final _otherRequirementsController = TextEditingController();
  
  String? _selectedMaritalStatus;
  String? _selectedMonthlyIncome;
  String? _selectedSiblings;
  String? _selectedFamilyMembers;
  String? _selectedLookingForType;
  String? _selectedLookingForAge;
  List<String> _selectedInterests = [];
  
  bool _managedBySomeoneElse = false;
  bool _facingChallenges = false;
  List<String> _selectedFacingChallenges = [];
  bool _readyToQaboolChallenges = false;
  List<String> _selectedReadyToQaboolChallenges = [];
  String? _selectedLanguage;

  // New Requirement Fields
  int? _reqMinAge;
  String _reqHeightUnit = 'cm';
  final _reqHeightCmController = TextEditingController();
  final _reqHeightFtController = TextEditingController();
  final _reqHeightInController = TextEditingController();
  double? _reqMinWeight;
  double? _reqMaxWeight;

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

  List<String> _missingFields = [];

  final List<String> _pastIssuesOptions = [
    'Divorced', 'Widowed', 'Separated', 'Other'
  ];

  final List<String> _availableInterests = [
    'Cooking', 'Traveling', 'Reading', 'Coding', 'Gaming', 
    'Music', 'Art', 'Sports', 'Photography', 'Fitness', 
    'Movies', 'Outdoors', 'Coffee', 'Animals', 'Gardening',
    'Politics', 'History', 'Movie Buff', 'Tech Enthusiast', 'Volunteer Work', 
    'Dancing', 'Chess', 'Meditation', 'Yoga', 'Podcasts', 
    'Financial Literacy', 'Fashion', 'Astronomy', 'Architecture', 'Interior Design', 
    'Philosophy', 'Sustainability', 'Languages', 'Hiking', 'Camping', 
    'Coffee Lover', 'Tea Enthusiast', 'Foodie', 'Public Speaking', 'Blogging',
    'Painting', 'Sculpting', 'Martial Arts', 'Entrepreneurship', 'DIY Projects'
  ];

  final Map<String, List<String>> _religionSects = {
    'Islam': ['Sunni', 'Shia', 'Ahmadiyya', 'Other'],
    'Christianity': ['Catholic', 'Protestant', 'Orthodox', 'Other'],
    'Hinduism': ['Vaishnavism', 'Shaivism', 'Shaktism', 'Smartism', 'Other'],
    'Sikhism': ['Khalsa', 'Sahajdhari', 'Other'],
    'Buddhism': ['Theravada', 'Mahayana', 'Vajrayana', 'Other'],
    'Other': ['Other'],
  };

  final Map<String, List<String>> _religionCastes = {
    'Islam': ['Sheikh', 'Syed', 'Mughal', 'Pathan', 'Malik', 'Other'],
    'Hinduism': ['Brahmin', 'Kshatriya', 'Vaishya', 'Shudra', 'Other'],
    'Christianity': ['None', 'Other'],
    'Other': ['Other'],
  };

  String? _selectedSect;
  String? _selectedCaste;

  List<String> _selectedPersonalityTraits = [];
  final List<String> _personalityOfferings = [
    '😊 Kind', '🧠 Intellectual', '🤣 Humorous', '🎨 Creative', '🤫 Introverted', '🗣️ Extroverted', '🧘 Calm', '⚡ Energetic', '🤝 Empathetic', '🧗 Adventurous'
  ];

  List<String> _selectedLifeStyle = [];
  final List<String> _lifestyleOfferings = [
    '🚭 Non-smoker', '🍽️ Halal only', '🕌 Praying five times', '🏋️ Fitness enthusiast', '🍳 Foodie', '✈️ Traveler', '🎮 Gamer', '🐈 Pet lover'
  ];

  final _grewUpInController = TextEditingController();

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _pickedImage = image);
    }
  }

  final Map<String, List<String>> _countryCities = {
    'Germany': ['Berlin', 'Munich', 'Hamburg', 'Frankfurt', 'Stuttgart'],
    'Bangladesh': ['Dhaka', 'Chittagong', 'Sylhet', 'Rajshahi', 'Khulna'],
    'Pakistan': ['Karachi', 'Lahore', 'Islamabad', 'Faisalabad', 'Multan'],
    'India': ['Mumbai', 'Delhi', 'Bangalore', 'Hyderabad', 'Chennai'],
    'Canada': ['Toronto', 'Vancouver', 'Montreal', 'Ottawa', 'Calgary'],
    'USA': ['New York', 'Los Angeles', 'Chicago', 'Houston', 'Miami'],
  };
  
  final Map<String, String> _countryCodes = {
    'Germany': '+49',
    'Bangladesh': '+880',
    'Pakistan': '+92',
    'India': '+91',
    'Canada': '+1',
    'USA': '+1',
  };

  final List<String> _ethnicities = [
    'Arab', 'Asian', 'Caucasian', 'African', 'Hispanic', 
    'Bengali', 'Punjabi', 'Sindhi', 'Pashtun', 'Other'
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _heightCmController.dispose();
    _heightFtController.dispose();
    _heightInController.dispose();
    _weightController.dispose();
    _educationController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _currentCityController.dispose();
    _sectController.dispose();
    _casteController.dispose();
    _grewUpInController.dispose();
    _otherRequirementsController.dispose();
    _reqHeightCmController.dispose();
    _reqHeightFtController.dispose();
    _reqHeightInController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
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

  String _toCamelCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  void _handleSignUp(AuthService auth) async {
    debugPrint('SignUp: _handleSignUp called');
    
    // 1. Mandatory Field Validation
    final Map<String, bool> validationMap = {
      'First Name': _firstNameController.text.isNotEmpty,
      'Last Name': _lastNameController.text.isNotEmpty,
      'Email': _emailController.text.isNotEmpty,
      'Password': _passwordController.text.isNotEmpty,
      'Gender': _selectedGender != null,
      'Country': _selectedCountry != null,
      'City': _selectedCity != null,
      'Date of Birth': _selectedDob != null,
      'Race/Ethnicity': _selectedEthnicity != null,
      'Religion': _selectedReligion != null,
      'Phone Code': _selectedCountryCode != null,
      'Phone Number': _phoneController.text.isNotEmpty,
      'Weight': _weightController.text.isNotEmpty,
      'Education': _educationController.text.isNotEmpty,
      'Marital Status': _selectedMaritalStatus != null,
      'Current City': _currentCityController.text.isNotEmpty,
      'Siblings': _selectedSiblings != null,
      'Family Members': _selectedFamilyMembers != null,
      'Partner (Age)': _selectedLookingForAge != null,
      'Sect': _selectedSect != null,
      'Caste': _selectedCaste != null,
    };

    final List<String> missingFields = validationMap.entries
        .where((e) => !e.value)
        .map((e) => e.key)
        .toList();

    setState(() {
      _missingFields = missingFields;
    });

    if (missingFields.isNotEmpty) {
      debugPrint('SignUp: Mandatory fields validation failed: $missingFields');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill: ${missingFields.join(", ")}'),
          backgroundColor: QaboolTheme.primary,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(label: 'OK', textColor: Colors.white, onPressed: () {}),
        ),
      );
      return;
    }
    debugPrint('SignUp: Mandatory fields OK');

    // 2. Height Validation
    if (_heightUnit == 'cm') {
      if (_heightCmController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your height')),
        );
        return;
      }
    } else {
      if (_heightFtController.text.isEmpty || _heightInController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your height in feet and inches')),
        );
        return;
      }
    }

    // 3. Min Length Validation (Bio & Special Considerations)
    if (_bioController.text.length < 10) {
      debugPrint('SignUp: Bio validation failed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bio must be at least 10 characters')),
      );
      return;
    }
    debugPrint('SignUp: All validations passed');

    // 4. Data Processing & Registration
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

      await auth.register(
        email: _emailController.text,
        password: _passwordController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        gender: _selectedGender,
        dob: _selectedDob?.toIso8601String(),
        ethnicity: _selectedEthnicity,
        height: heightCm,
        weight: weightKg,
        education: _educationController.text,
        bio: _bioController.text,
        region: _selectedCountry != null && _selectedCity != null ? "${_selectedCity}, ${_selectedCountry}" : null,
        phoneNumber: "${_selectedCountryCode}${_phoneController.text}",
        maritalStatus: _selectedMaritalStatus,
        currentCity: _currentCityController.text,
        monthlyIncome: double.tryParse(_selectedMonthlyIncome ?? ""),
        siblings: int.tryParse(_selectedSiblings ?? ""),
        familyMembers: int.tryParse(_selectedFamilyMembers ?? ""),
        lookingForAge: _selectedLookingForAge,
        lookingForType: _selectedLookingForType,
        interests: _selectedInterests,
        personalityTraits: _selectedPersonalityTraits,
        lifeStyle: _selectedLifeStyle,
        grewUpIn: _grewUpInController.text,
        religion: _selectedReligion,
        religionSect: _selectedSect,
        religionCast: _selectedCaste,
        otherRequirements: _otherRequirementsController.text,
        managedBySomeoneElse: _managedBySomeoneElse,
        facingChallenges: _facingChallenges,
        facingChallengesList: _selectedFacingChallenges,
        readyToQaboolChallenges: _readyToQaboolChallenges,
        readyToQaboolChallengesList: _selectedReadyToQaboolChallenges,
        language: _selectedLanguage,
        lookingForMinAge: _reqMinAge,
        lookingForMinHeight: _reqHeightUnit == 'cm' 
            ? double.tryParse(_reqHeightCmController.text) 
            : (double.tryParse(_reqHeightFtController.text) ?? 0) * 30.48 + (double.tryParse(_reqHeightInController.text) ?? 0) * 2.54,
        lookingForMinWeight: _reqMinWeight,
        lookingForMaxWeight: _reqMaxWeight,
        profileImage: _pickedImage,
      );
      if (!mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Text('Registration Successful'),
            ],
          ),
          content: const Text(
            'Your account has been created successfully! Please wait for admin approval before you can sign in and start your journey.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              },
              child: const Text(
                'GOT IT',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('SignUp: Registration failed with error: $e');
      String message = 'Registration failed';
      
      if (e is DioException) {
        if (e.response?.statusCode == 409) {
          message = 'This email is already registered. Please try logging in.';
        } else if (e.response?.data != null && e.response?.data is Map) {
          final data = e.response?.data as Map;
          if (data.containsKey('message')) {
            message = data['message'].toString();
          } else {
            message = 'Server error. Please try again later.';
          }
        } else {
          message = 'Server error. Please try again later.';
        }
      } else {
        message = e.toString();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: QaboolTheme.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Using color extraction from tailwind config in HTML
    const pColor = QaboolTheme.primary; // #d4af35 (Gold)
    const aColor = QaboolTheme.primary; // Deep Maroon

    Widget buildSectionHeader(IconData icon, String title) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          children: [
            Icon(icon, color: pColor, size: 24),
            const SizedBox(width: 8),
            Text(
              title.toUpperCase(),
              style: TextStyle(
                color: isDark ? pColor : aColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }
    InputDecoration inputDecoration(String hint,
        {Widget? suffixIcon, BorderRadius? borderRadius}) {
      final radius = borderRadius ?? BorderRadius.circular(12);
      return InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(
              color:
                  isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(
              color:
                  isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: pColor.withOpacity(0.5), width: 2),
        ),
        suffixIcon: suffixIcon,
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon:
                        Icon(Icons.arrow_back, color: isDark ? pColor : aColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Complete Your Profile',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? pColor : aColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balancing
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 32.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Title
                          Text(
                            'Join Qabool',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark ? pColor : aColor,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Let us help you find your blessed union with a detailed profile.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Photo Upload
                          Center(
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: _pickImage,
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: 128,
                                        height: 128,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isDark
                                              ? const Color(0xFF1E293B)
                                              : const Color(0xFFF1F5F9),
                                          border: Border.all(
                                            color: pColor,
                                            width: 2,
                                          ),
                                          image: _pickedImage != null
                                              ? DecorationImage(
                                                  image: kIsWeb
                                                      ? NetworkImage(_pickedImage!.path)
                                                      : FileImage(File(_pickedImage!.path)) as ImageProvider,
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                        ),
                                        child: _pickedImage == null
                                            ? const Icon(Icons.add_a_photo,
                                                size: 40, color: QaboolTheme.primary)
                                            : null,
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: const BoxDecoration(
                                            color: QaboolTheme.primary,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.edit,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Profile Picture',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                                RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[500]),
                                    children: [
                                      const TextSpan(
                                          text:
                                              'Add a photo to increase your match chances by '),
                                      TextSpan(
                                        text: '80%',
                                        style: TextStyle(
                                            color: isDark ? pColor : aColor,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                          const SizedBox(height: 32),

                          // Contact & Credentials
                          buildSectionHeader(
                              Icons.account_circle, 'Contact & Credentials'),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('First Name', isDark),
                                    TextField(
                                        controller: _firstNameController,
                                        decoration:
                                            inputDecoration('First Name')),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('Last Name', isDark),
                                    TextField(
                                        controller: _lastNameController,
                                        decoration:
                                            inputDecoration('Last Name')),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildLabel('Gender', isDark),
                          DropdownButtonFormField<String>(
                            value: _selectedGender,
                            decoration: inputDecoration('Select Gender'),
                            items: ['Male', 'Female']
                                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedGender = val;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: const Text('Managed by a Representative?'),
                            subtitle: const Text('e.g. Profile managed by parents or siblings'),
                            value: _managedBySomeoneElse,
                            activeColor: QaboolTheme.primary,
                            onChanged: (val) => setState(() => _managedBySomeoneElse = val),
                          ),
                          const SizedBox(height: 16),
                          _buildLabel('Email Address', isDark),
                          TextField(
                              controller: _emailController,
                              decoration: inputDecoration('name@example.com')),
                          const SizedBox(height: 16),
                          _buildLabel('Password', isDark),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: inputDecoration(
                              'Min. 8 characters',
                              suffixIcon: IconButton(
                                icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.grey[400]),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildLabel('Phone Number', isDark),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<String>(
                                  value: _selectedCountryCode,
                                  decoration: inputDecoration('Code'),
                                  isExpanded: true,
                                  items: _countryCodes.entries
                                      .map((e) => DropdownMenuItem(
                                            value: e.value,
                                            child: Text("${e.key} (${e.value})", 
                                                style: const TextStyle(fontSize: 12)),
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedCountryCode = val;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: inputDecoration('Number'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Divider(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0)),
                          const SizedBox(height: 24),

                          // Personal Attributes
                          buildSectionHeader(
                              Icons.person_search, 'Personal Attributes'),
                          
                          // Country Dropdown
                          _buildLabel('Country', isDark),
                          DropdownButtonFormField<String>(
                            value: _selectedCountry,
                            decoration: inputDecoration('Select Country'),
                            items: _countryCities.keys
                                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedCountry = val;
                                _selectedCity = null; // Reset city when country changes
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          // City Dropdown
                          _buildLabel('City (Region)', isDark),
                          DropdownButtonFormField<String>(
                            value: _selectedCity,
                            decoration: inputDecoration('Select City'),
                            items: (_selectedCountry != null
                                    ? _countryCities[_selectedCountry]!
                                    : <String>[])
                                .map((city) =>
                                    DropdownMenuItem(value: city, child: Text(city)))
                                .toList(),
                            onChanged: (val) {
                              setState(() => _selectedCity = val);
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildLabel('Race/Ethnicity', isDark),
                          DropdownButtonFormField<String>(
                            value: _selectedEthnicity,
                            decoration: inputDecoration('Select Ethnicity'),
                            items: _ethnicities
                                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                            onChanged: (val) => setState(() => _selectedEthnicity = val),
                          ),

                                
                                const SizedBox(height: 16),
                                // Age (DOB)
                                _buildLabel('Date of Birth (Age)', isDark),
                                InkWell(
                                  onTap: () => _selectDate(context),
                                  child: IgnorePointer(
                                    child: TextField(
                                      decoration: inputDecoration(
                                        _selectedDob == null
                                            ? 'Select Date'
                                            : "${_selectedDob!.day}/${_selectedDob!.month}/${_selectedDob!.year}",
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Height
                                _buildLabel('Height', isDark),
                                Row(
                                  children: [
                                    if (_heightUnit == 'cm')
                                      Expanded(
                                        flex: 2,
                                        child: TextField(
                                          controller: _heightCmController,
                                          keyboardType: TextInputType.number,
                                          decoration: inputDecoration('cm'),
                                        ),
                                      )
                                    else ...[
                                      Expanded(
                                        child: TextField(
                                          controller: _heightFtController,
                                          keyboardType: TextInputType.number,
                                          decoration: inputDecoration('ft'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          controller: _heightInController,
                                          keyboardType: TextInputType.number,
                                          decoration: inputDecoration('in'),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 1,
                                      child: InputDecorator(
                                        decoration: inputDecoration(
                                          '',
                                          borderRadius: BorderRadius.circular(12),
                                        ).copyWith(
                                          contentPadding:
                                              const EdgeInsets.symmetric(horizontal: 8),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: _heightUnit,
                                            isExpanded: true,
                                            icon: const Icon(Icons.arrow_drop_down),
                                            items: ['cm', 'ft']
                                                .map((e) => DropdownMenuItem(
                                                    value: e, child: Text(e)))
                                                .toList(),
                                            onChanged: (val) {
                                              if (val != null) {
                                                setState(() => _heightUnit = val);
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Weight
                                _buildLabel('Weight', isDark),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: TextField(
                                        controller: _weightController,
                                        keyboardType: TextInputType.number,
                                        decoration: inputDecoration('Value'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 1,
                                      child: InputDecorator(
                                        decoration: inputDecoration(
                                          '',
                                          borderRadius: BorderRadius.circular(12),
                                        ).copyWith(
                                          contentPadding:
                                              const EdgeInsets.symmetric(horizontal: 8),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: _weightUnit,
                                            isExpanded: true,
                                            icon: const Icon(Icons.arrow_drop_down),
                                            items: ['kg', 'lbs']
                                                .map((e) => DropdownMenuItem(
                                                    value: e, child: Text(e)))
                                                .toList(),
                                            onChanged: (val) {
                                              if (val != null) {
                                                setState(() => _weightUnit = val);
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                          const SizedBox(height: 24),
                          Divider(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0)),
                          const SizedBox(height: 24),

                          // Requirement Section (Moving requested fields here)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isDark ? Colors.white10 : Colors.grey[300]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.assignment_turned_in, color: pColor, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'REQUIREMENT',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: isDark ? pColor : aColor,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Education
                                _buildLabel('Education', isDark),
                                DropdownButtonFormField<String>(
                                  value: _educationController.text.isEmpty ? null : _educationController.text,
                                  decoration: inputDecoration('Highest degree earned'),
                                  items: [
                                    'High School', 'Associate Degree', 'Bachelors Degree', 
                                    'Masters Degree', 'PhD', 'Other'
                                  ]
                                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                      .toList(),
                                  onChanged: (val) => setState(() => _educationController.text = val ?? ''),
                                ),
                                const SizedBox(height: 16),

                                // City
                                _buildLabel('Current City', isDark),
                                TextField(
                                  controller: _currentCityController,
                                  decoration: inputDecoration('e.g. London, UK'),
                                ),
                                const SizedBox(height: 16),

                                // Religion
                                DropdownButtonFormField<String>(
                                  value: _selectedReligion,
                                  decoration: inputDecoration('Select Religion'),
                                  items: ['Islam', 'Christianity', 'Hinduism', 'Sikhism', 'Buddhism', 'Other']
                                      .map((e) => DropdownMenuItem(
                                          value: e, child: Text(e)))
                                      .toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedReligion = val;
                                      _selectedSect = null;
                                      _selectedCaste = null;
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),

                                if (_selectedReligion != null) ...[
                                  // Sect
                                  _buildLabel('Sect', isDark),
                                  DropdownButtonFormField<String>(
                                    value: _selectedSect,
                                    decoration: inputDecoration('Select Sect'),
                                    items: (_religionSects[_selectedReligion] ?? ['Other'])
                                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                        .toList(),
                                    onChanged: (val) => setState(() => _selectedSect = val),
                                  ),
                                  const SizedBox(height: 16),

                                  // Caste
                                  _buildLabel('Caste', isDark),
                                  DropdownButtonFormField<String>(
                                    value: _selectedCaste,
                                    decoration: inputDecoration('Select Caste'),
                                    items: (_religionCastes[_selectedReligion] ?? ['Other'])
                                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                        .toList(),
                                    onChanged: (val) => setState(() => _selectedCaste = val),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                // Partner Age
                                _buildLabel('Min Age', isDark),
                                DropdownButtonFormField<int>(
                                  value: _reqMinAge,
                                  decoration: inputDecoration('Select Min Age'),
                                  items: List.generate(83, (i) => i + 18)
                                      .map((e) => DropdownMenuItem(value: e, child: Text(e.toString())))
                                      .toList(),
                                  onChanged: (val) => setState(() => _reqMinAge = val),
                                ),
                                const SizedBox(height: 16),

                                _buildLabel('Age Range (Display)', isDark),
                                DropdownButtonFormField<String>(
                                  value: _selectedLookingForAge,
                                  decoration: inputDecoration('Select Age Range'),
                                  items: ['18-25', '25-35', '35-45', '45-55', '55+']
                                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                      .toList(),
                                  onChanged: (val) => setState(() => _selectedLookingForAge = val),
                                ),
                                const SizedBox(height: 16),

                                // Partner Height
                                _buildLabel('Height', isDark),
                                Row(
                                  children: [
                                    if (_reqHeightUnit == 'cm')
                                      Expanded(
                                        flex: 2,
                                        child: TextField(
                                          controller: _reqHeightCmController,
                                          keyboardType: TextInputType.number,
                                          decoration: inputDecoration('cm'),
                                        ),
                                      )
                                    else ...[
                                      Expanded(
                                        child: TextField(
                                          controller: _reqHeightFtController,
                                          keyboardType: TextInputType.number,
                                          decoration: inputDecoration('ft'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          controller: _reqHeightInController,
                                          keyboardType: TextInputType.number,
                                          decoration: inputDecoration('in'),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 1,
                                      child: InputDecorator(
                                        decoration: inputDecoration(
                                          '',
                                          borderRadius: BorderRadius.circular(12),
                                        ).copyWith(
                                          contentPadding:
                                              const EdgeInsets.symmetric(horizontal: 8),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: _reqHeightUnit,
                                            isExpanded: true,
                                            icon: const Icon(Icons.arrow_drop_down),
                                            items: ['cm', 'ft']
                                                .map((e) => DropdownMenuItem(
                                                    value: e, child: Text(e)))
                                                .toList(),
                                            onChanged: (val) {
                                              if (val != null) {
                                                setState(() => _reqHeightUnit = val);
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Partner Weight
                                _buildLabel('Partner Weight (kg)', isDark),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<double>(
                                        value: _reqMinWeight,
                                        decoration: inputDecoration('Min kg'),
                                        isExpanded: true,
                                        items: List.generate(121, (i) => (i + 30).toDouble())
                                            .map((e) => DropdownMenuItem(value: e, child: Text(e.toInt().toString())))
                                            .toList(),
                                        onChanged: (val) => setState(() => _reqMinWeight = val),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: DropdownButtonFormField<double>(
                                        value: _reqMaxWeight,
                                        decoration: inputDecoration('Max kg'),
                                        isExpanded: true,
                                        items: List.generate(121, (i) => (i + 30).toDouble())
                                            .map((e) => DropdownMenuItem(value: e, child: Text(e.toInt().toString())))
                                            .toList(),
                                        onChanged: (val) => setState(() => _reqMaxWeight = val),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),



                                // Income
                                _buildLabel('Monthly Income', isDark),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: _selectedMonthlyIncome,
                                        decoration: inputDecoration('Select Income'),
                                        items: ['0', '500', '1000', '2000', '3000', '4000', '5000', '7500', '10000']
                                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                            .toList(),
                                        onChanged: (val) => setState(() => _selectedMonthlyIncome = val),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Euro',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildLabel('Other Requirements', isDark),
                                TextField(
                                  controller: _otherRequirementsController,
                                  maxLines: 3,
                                  decoration: inputDecoration('Additional requirements for your partner...'),
                                ),
                                const SizedBox(height: 16),
                                _buildLabel('Preferred Language', isDark),
                                DropdownButtonFormField<String>(
                                  value: _selectedLanguage,
                                  decoration: inputDecoration('Select Language'),
                                  items: ['English', 'Bengali', 'Hindi', 'Urdu', 'Arabic', 'French', 'German', 'Spanish', 'Other']
                                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                      .toList(),
                                  onChanged: (val) => setState(() => _selectedLanguage = val),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Divider(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0)),
                          const SizedBox(height: 24),

                          const SizedBox(height: 16),

                          buildSectionHeader(Icons.home, 'Household & Additional Info'),
                          _buildLabel('Marital Status', isDark),
                          DropdownButtonFormField<String>(
                            value: _selectedMaritalStatus,
                            decoration: inputDecoration('Select Status'),
                            items: ['Single', 'Divorced', 'Widowed', 'Separated']
                                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                            onChanged: (val) => setState(() => _selectedMaritalStatus = val),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('Siblings', isDark),
                                    DropdownButtonFormField<String>(
                                      value: _selectedSiblings,
                                      decoration: inputDecoration('Select'),
                                      items: ['0', '1', '2', '3', '4', '5', '6+']
                                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                          .toList(),
                                      onChanged: (val) => setState(() => _selectedSiblings = val),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('Family Members', isDark),
                                    DropdownButtonFormField<String>(
                                      value: _selectedFamilyMembers,
                                      decoration: inputDecoration('Select'),
                                      items: ['1', '2', '3', '4', '5', '6', '7', '8+']
                                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                          .toList(),
                                      onChanged: (val) => setState(() => _selectedFamilyMembers = val),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          const SizedBox(height: 24),

                          // Issues & Challenges
                          buildSectionHeader(Icons.warning_amber_rounded, 'Issues & Challenges'),
                          
                          // Facing Challenges
                          SwitchListTile(
                            title: const Text('Do you face any issues/challenges?'),
                            subtitle: const Text('e.g. physical disability, divorced, etc.'),
                            value: _facingChallenges,
                            activeColor: QaboolTheme.primary,
                            onChanged: (val) => setState(() => _facingChallenges = val),
                          ),
                          if (_facingChallenges)
                            _buildMultiSelect(
                              title: 'Your Challenges',
                              offerings: _challengeOptions,
                              selectedList: _selectedFacingChallenges,
                              maxSelect: 5,
                              onChanged: (list) => _selectedFacingChallenges = list,
                              isDark: isDark,
                              pColor: pColor,
                              aColor: aColor,
                            ),
                          const SizedBox(height: 16),

                          // Ready to Qabool Challenges
                          SwitchListTile(
                            title: const Text('Ready to accept partner with challenges?'),
                            subtitle: const Text('Show you are open to specific situations'),
                            value: _readyToQaboolChallenges,
                            activeColor: QaboolTheme.primary,
                            onChanged: (val) => setState(() => _readyToQaboolChallenges = val),
                          ),
                          if (_readyToQaboolChallenges)
                            _buildMultiSelect(
                              title: 'Accepted Challenges',
                              offerings: _challengeOptions,
                              selectedList: _selectedReadyToQaboolChallenges,
                              maxSelect: 5,
                              onChanged: (list) => _selectedReadyToQaboolChallenges = list,
                              isDark: isDark,
                              pColor: pColor,
                              aColor: aColor,
                            ),
                          const SizedBox(height: 24),
                          Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          const SizedBox(height: 24),

                          // Profile Details
                          buildSectionHeader(Icons.bubble_chart, 'Profile Details'),
                          _buildMultiSelect(
                            title: 'Personality Traits',
                            offerings: _personalityOfferings,
                            selectedList: _selectedPersonalityTraits,
                            maxSelect: 5,
                            onChanged: (list) => _selectedPersonalityTraits = list,
                            isDark: isDark,
                            pColor: pColor,
                            aColor: aColor,
                          ),
                          const SizedBox(height: 24),
                          Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          const SizedBox(height: 24),

                          // Bio
                          buildSectionHeader(Icons.description, 'Bio'),
                          _buildLabel('Tell us a bit about yourself (Min 10 characters)', isDark),
                          TextField(
                            controller: _bioController,
                            maxLines: 4,
                            decoration: inputDecoration('Tell us about yourself...'),
                          ),
                          const SizedBox(height: 24),
                          Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          const SizedBox(height: 24),

                          Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          const SizedBox(height: 24),

                          _buildMultiSelect(
                            title: 'Interests',
                            offerings: _availableInterests,
                            selectedList: _selectedInterests,
                            maxSelect: 15,
                            onChanged: (list) => _selectedInterests = list,
                            isDark: isDark,
                            pColor: pColor,
                            aColor: aColor,
                          ),
                          const SizedBox(height: 32),

                          if (_missingFields.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.withOpacity(0.5)),
                              ),
                              child: Text(
                                'Please fill all mandatory fields: ${_missingFields.join(", ")}',
                                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                            ),

                          // Create Account Button
                          Consumer<AuthService>(
                            builder: (context, auth, _) {
                              return ElevatedButton(
                                onPressed: auth.isLoading ? null : () => _handleSignUp(auth),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: QaboolTheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 4,
                                ),
                                child: auth.isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text('Create Account',
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold)),
                                          SizedBox(width: 8),
                                          Icon(Icons.how_to_reg),
                                        ],
                                      ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),

                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? Colors.grey[400] : Colors.grey[500]),
                              children: [
                                const TextSpan(text: 'By joining, you agree to our '),
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: TextStyle(
                                    color: QaboolTheme.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: TextStyle(
                                  fontSize: 16,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600]),
                              children: [
                                const TextSpan(text: 'Already have an account? '),
                                TextSpan(
                                  text: 'Sign In',
                                  style: TextStyle(
                                    color: QaboolTheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
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
    required bool isDark,
    required Color pColor,
    required Color aColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('$title (Select Max $maxSelect)', isDark),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: offerings.map((item) {
            // Case-insensitive check to ensure robustness
            final bool isSelected = selectedList.any((e) => e.toLowerCase() == item.toLowerCase());
            
            return FilterChip(
              label: Text(item),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  final newList = List<String>.from(selectedList);
                  if (selected) {
                    // Only count items that are actually in the current offerings
                    final validCount = newList.where((e) => offerings.any((opt) => opt.toLowerCase() == e.toLowerCase())).length;
                    
                    if (validCount < maxSelect) {
                      newList.add(item);
                    } else {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('You can select a maximum of $maxSelect $title')),
                      );
                      return;
                    }
                  } else {
                    newList.removeWhere((e) => e.toLowerCase() == item.toLowerCase());
                  }
                  onChanged(newList);
                });
              },
              selectedColor: pColor.withOpacity(0.3),
              checkmarkColor: pColor,
              labelStyle: TextStyle(
                color: isSelected ? pColor : (isDark ? Colors.white : Colors.black87),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? pColor : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 4.0),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: isDark ? Colors.grey[300] : Colors.grey[700],
        ),
      ),
    );
  }
}
