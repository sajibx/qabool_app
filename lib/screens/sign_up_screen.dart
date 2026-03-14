import 'package:flutter/material.dart';
import 'package:qabool_app/theme.dart';
import 'package:provider/provider.dart';
import 'package:qabool_app/services/auth_service.dart';
import 'package:qabool_app/services/chat_service.dart';
import 'package:qabool_app/services/api_service.dart';

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
  bool _obscurePassword = true;
  String? _selectedGender;
  DateTime? _selectedDob;
  String? _selectedEthnicity;
  String? _selectedCountry;
  String? _selectedCity;
  String? _selectedReligion;
  
  String _heightUnit = 'cm';
  String _weightUnit = 'kg';

  final _heightCmController = TextEditingController();
  final _heightFtController = TextEditingController();
  final _heightInController = TextEditingController();
  final _weightController = TextEditingController();
  final _jobController = TextEditingController();
  final _educationController = TextEditingController();
  final _bioController = TextEditingController();
  final _specialController = TextEditingController();

  final Map<String, List<String>> _countryCities = {
    'Germany': ['Berlin', 'Munich', 'Hamburg', 'Frankfurt', 'Stuttgart'],
    'Bangladesh': ['Dhaka', 'Chittagong', 'Sylhet', 'Rajshahi', 'Khulna'],
    'Pakistan': ['Karachi', 'Lahore', 'Islamabad', 'Faisalabad', 'Multan'],
    'India': ['Mumbai', 'Delhi', 'Bangalore', 'Hyderabad', 'Chennai'],
    'Canada': ['Toronto', 'Vancouver', 'Montreal', 'Ottawa', 'Calgary'],
    'USA': ['New York', 'Los Angeles', 'Chicago', 'Houston', 'Miami'],
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
    _jobController.dispose();
    _educationController.dispose();
    _bioController.dispose();
    _specialController.dispose();
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

  void _handleSignUp() async {
    final auth = context.read<AuthService>();
    
    // 1. Mandatory Field Validation
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _selectedGender == null ||
        _selectedCountry == null ||
        _selectedCity == null ||
        _selectedDob == null ||
        _selectedEthnicity == null ||
        _selectedReligion == null ||
        _weightController.text.isEmpty ||
        _jobController.text.isEmpty ||
        _educationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all mandatory fields')),
      );
      return;
    }

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bio must be at least 10 characters')),
      );
      return;
    }
    if (_specialController.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Special considerations must be at least 10 characters')),
      );
      return;
    }

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
        religion: _selectedReligion,
        height: heightCm,
        weight: weightKg,
        profession: _jobController.text,
        education: _educationController.text,
        bio: _bioController.text,
        specialConsiderations: _specialController.text,
        region: "${_selectedCity}, ${_selectedCountry}",
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
    } on Exception catch (e) {
      String message = 'Registration failed';
      if (e.toString().contains('409')) {
        message = 'This email is already registered. Please try logging in.';
      } else {
        message = e.toString().contains('DioException') ? 'Server error. Please try again later.' : e.toString();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.redAccent,
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

    Widget buildLabel(String text) {
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
                    onPressed: () {
                      if (Navigator.canPop(context)) Navigator.pop(context);
                    },
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
                                Stack(
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
                                      ),
                                      child: const Icon(Icons.add_a_photo,
                                          size: 48, color: Colors.grey),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: aColor,
                                          border: Border.all(
                                              color: isDark
                                                  ? const Color(0xFF0F172A)
                                                  : Colors.white,
                                              width: 2),
                                          boxShadow: const [
                                            BoxShadow(
                                                color: Colors.black26,
                                                blurRadius: 4,
                                                offset: Offset(0, 2)),
                                          ],
                                        ),
                                        child: const Icon(Icons.upload,
                                            color: Colors.white, size: 20),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                GestureDetector(
                                  onTap: () {},
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Upload Photo',
                                        style: TextStyle(
                                            color: isDark ? pColor : aColor,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
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
                                    buildLabel('First Name'),
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
                                    buildLabel('Last Name'),
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
                          buildLabel('Gender'),
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
                          buildLabel('Email Address'),
                          TextField(
                              controller: _emailController,
                              decoration: inputDecoration('name@example.com')),
                          const SizedBox(height: 16),
                          buildLabel('Password'),
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
                          buildLabel('Country'),
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
                          buildLabel('City'),
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
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    buildLabel('Religion'),
                                    DropdownButtonFormField<String>(
                                      value: _selectedReligion,
                                      decoration: inputDecoration('Select'),
                                      items: [
                                        'Islam (Sunni)',
                                        'Islam (Shia)',
                                        'Islam (Other)'
                                      ]
                                          .map((e) => DropdownMenuItem(
                                              value: e, child: Text(e)))
                                          .toList(),
                                      onChanged: (val) => setState(() => _selectedReligion = val),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    buildLabel('Date of Birth'),
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
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          buildLabel('Race/Ethnicity'),
                          DropdownButtonFormField<String>(
                            value: _selectedEthnicity,
                            decoration: inputDecoration('Select Ethnicity'),
                            items: _ethnicities
                                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                            onChanged: (val) => setState(() => _selectedEthnicity = val),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    buildLabel('Height'),
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
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    buildLabel('Weight'),
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
                                  ],
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

                          // Professional & Educational
                          buildSectionHeader(
                              Icons.school, 'Professional & Educational'),
                          buildLabel('Work / Profession'),
                          TextField(
                              controller: _jobController,
                              decoration:
                                  inputDecoration('Current occupation')),
                          const SizedBox(height: 16),
                          buildLabel('Studies / Education'),
                          TextField(
                              controller: _educationController,
                              decoration:
                                  inputDecoration('Highest degree earned')),
                          const SizedBox(height: 24),
                          Divider(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0)),
                          const SizedBox(height: 24),

                          // Bio
                          buildSectionHeader(Icons.description, 'Bio'),
                          buildLabel('Tell us a bit about yourself (Min 10 characters)'),
                          TextField(
                            controller: _bioController,
                            maxLines: 4,
                            decoration: inputDecoration('Tell us about yourself...'),
                          ),
                          const SizedBox(height: 24),
                          Divider(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0)),
                          const SizedBox(height: 24),

                          // Special Considerations
                          buildSectionHeader(Icons.info, 'Special Considerations'),
                          buildLabel('Accessibility or Special Cases (Min 10 characters)'),
                          TextField(
                            controller: _specialController,
                            maxLines: 4,
                            decoration: inputDecoration(
                                "Physical accessibility requirements, etc..."),
                          ),
                          const SizedBox(height: 32),

                          // Create Account Button
                           Consumer<AuthService>(
                             builder: (context, auth, _) {
                               return ElevatedButton(
                                 onPressed: auth.isLoading ? null : _handleSignUp,
                                 style: ElevatedButton.styleFrom(
                                   backgroundColor: aColor,
                                   foregroundColor: Colors.white,
                                   padding: const EdgeInsets.symmetric(vertical: 16),
                                   shape: RoundedRectangleBorder(
                                       borderRadius: BorderRadius.circular(12)),
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
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[500]),
                              children: [
                                const TextSpan(
                                    text: 'By joining, you agree to our '),
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: TextStyle(
                                    color: isDark ? pColor : aColor,
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
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600]),
                              children: [
                                const TextSpan(
                                    text: 'Already have an account? '),
                                TextSpan(
                                  text: 'Sign In',
                                  style: TextStyle(
                                    color: isDark ? pColor : aColor,
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
}
