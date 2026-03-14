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

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignUp() async {
    final auth = context.read<AuthService>();
    final chatService = context.read<ChatService>();
    try {
      await auth.register(
        email: _emailController.text,
        password: _passwordController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        gender: _selectedGender,
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
                          buildLabel('Region'),
                          TextField(
                              decoration: inputDecoration('City, Country')),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    buildLabel('Religion'),
                                    DropdownButtonFormField<String>(
                                      decoration: inputDecoration('Select'),
                                      items: [
                                        'Islam (Sunni)',
                                        'Islam (Shia)',
                                        'Islam (Other)'
                                      ]
                                          .map((e) => DropdownMenuItem(
                                              value: e, child: Text(e)))
                                          .toList(),
                                      onChanged: (val) {},
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
                                    TextField(
                                      decoration: inputDecoration('DD/MM/YYYY'),
                                      keyboardType: TextInputType.datetime,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          buildLabel('Race/Ethnicity'),
                          TextField(
                              decoration: inputDecoration('e.g. Arab, Asian')),
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
                                        Expanded(
                                          flex: 2,
                                          child: TextField(
                                            keyboardType: TextInputType.number,
                                            decoration: inputDecoration(
                                              'Value',
                                              borderRadius:
                                                  const BorderRadius.horizontal(
                                                      left:
                                                          Radius.circular(12)),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: InputDecorator(
                                            decoration: inputDecoration(
                                              '',
                                              borderRadius:
                                                  const BorderRadius.horizontal(
                                                      right:
                                                          Radius.circular(12)),
                                            ).copyWith(
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8),
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton<String>(
                                                value: 'cm',
                                                isExpanded: true,
                                                icon: const Icon(
                                                    Icons.arrow_drop_down),
                                                items: ['cm', 'ft']
                                                    .map((e) =>
                                                        DropdownMenuItem(
                                                            value: e,
                                                            child: Text(e)))
                                                    .toList(),
                                                onChanged: (val) {},
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
                                            keyboardType: TextInputType.number,
                                            decoration: inputDecoration(
                                              'Value',
                                              borderRadius:
                                                  const BorderRadius.horizontal(
                                                      left:
                                                          Radius.circular(12)),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: InputDecorator(
                                            decoration: inputDecoration(
                                              '',
                                              borderRadius:
                                                  const BorderRadius.horizontal(
                                                      right:
                                                          Radius.circular(12)),
                                            ).copyWith(
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8),
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton<String>(
                                                value: 'kg',
                                                isExpanded: true,
                                                icon: const Icon(
                                                    Icons.arrow_drop_down),
                                                items: ['kg', 'lbs']
                                                    .map((e) =>
                                                        DropdownMenuItem(
                                                            value: e,
                                                            child: Text(e)))
                                                    .toList(),
                                                onChanged: (val) {},
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
                              decoration:
                                  inputDecoration('Current occupation')),
                          const SizedBox(height: 16),
                          buildLabel('Studies / Education'),
                          TextField(
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
                          buildLabel('Tell us a bit about yourself'),
                          TextField(
                            maxLines: 4,
                            decoration: inputDecoration(
                                'Tell us a bit about yourself...'),
                          ),
                          const SizedBox(height: 24),
                          Divider(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0)),
                          const SizedBox(height: 24),

                          // Special Considerations
                          buildSectionHeader(
                              Icons.info, 'Special Considerations'),
                          buildLabel('Accessibility or Special Cases'),
                          TextField(
                            maxLines: 4,
                            decoration: inputDecoration(
                                "Please mention any physical accessibility requirements..."),
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
