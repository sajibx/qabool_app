import 'package:flutter/material.dart';
import 'package:qabool_app/theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:qabool_app/services/auth_service.dart';
import 'package:qabool_app/services/chat_service.dart';
import 'package:qabool_app/services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final auth = context.read<AuthService>();
    final chatService = context.read<ChatService>();
    try {
      await auth.login(_emailController.text, _passwordController.text);
      if (!mounted) return;
      
      final token = await context.read<ApiService>().getToken();
      if (token != null) chatService.initSocket(token);
      
      Navigator.pushReplacementNamed(context, '/main');
    } on Exception catch (e) {
      String message = 'Login failed';
      if (e.toString().contains('401')) {
        message = 'Invalid email or password. Please try again.';
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1024;

    return Scaffold(
      body: Row(
        children: [
          // Main Content
          Expanded(
            flex: isLargeScreen ? 2 : 1,
            child: SafeArea(
              child: Column(
                children: [
                  // Top Navigation
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          },
                        ),
                        const Expanded(
                          child: Text(
                            'Login to Qabool',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 48), // Balance for centering
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1),

                  // Scrollable form area
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 32.0),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Hero/Branding
                            Center(
                              child: Container(
                                width: 112,
                                height: 112,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: QaboolTheme.primary.withOpacity(0.05),
                                  border: Border.all(
                                    color: QaboolTheme.accentGold
                                        .withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl:
                                        'https://lh3.googleusercontent.com/aida-public/AB6AXuCQNkB3_Xo85js-pXMyuaOCGrioNQ7iIz8NoIP7Jd08HdmMCHdjFnh-CuD5esD0XUKVsUb20cAaTyhK6mJXWVWLo8mNhaqbK2vinMQDSJdLOIfEW8G0REkP10r_x4KOs1kMpv8wMIhMLSmO-4nvc5g6QrG70RDYTZMUpv3P9WELcEZ-YMCeHCxGVU9MrVRB-EDGXzaAuLDNQBtg8glclPxZ_a9KpceZ2HEUvvMsRw_NqWUenn3cB7zzlU3ucUBHxOHB_0olv8zSBiCK',
                                    fit: BoxFit.contain,
                                    placeholder: (context, url) =>
                                        const CircularProgressIndicator(),
                                    errorWidget: (context, url, error) =>
                                        const Icon(Icons.error),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Qabool',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Find your soulmate today',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[500],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 40),

                            // Form Fields
                            Text(
                              'Email or Phone Number',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.grey[300]
                                    : Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                hintText: 'Enter your email',
                                filled: true,
                                fillColor: isDark
                                    ? const Color(0xFF1E293B)
                                    : Colors.white,
                                contentPadding: const EdgeInsets.all(16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: QaboolTheme.primary,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Password',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.grey[300]
                                        : Colors.grey[700],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {},
                                  child: const Text(
                                    'Forgot password?',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: QaboolTheme.primary,
                                    ),
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                hintText: '••••••••',
                                filled: true,
                                fillColor: isDark
                                    ? const Color(0xFF1E293B)
                                    : Colors.white,
                                contentPadding: const EdgeInsets.all(16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: QaboolTheme.primary,
                                    width: 2,
                                  ),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Colors.grey[400],
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                                                         Consumer<AuthService>(
                                builder: (context, auth, _) {
                                  return ElevatedButton(
                                    onPressed: auth.isLoading ? null : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: QaboolTheme.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
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
                                        : const Text(
                                            'Log In',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold),
                                          ),
                                  );
                                },
                              ),

                            // Divider
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Row(
                                children: [
                                  Expanded(
                                      child: Divider(
                                          color: isDark
                                              ? const Color(0xFF334155)
                                              : const Color(0xFFE2E8F0))),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: Text(
                                      'NEW TO QABOOL?',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 1,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                      child: Divider(
                                          color: isDark
                                              ? const Color(0xFF334155)
                                              : const Color(0xFFE2E8F0))),
                                ],
                              ),
                            ),

                            // Sign Up Button
                            OutlinedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/signup');
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: QaboolTheme.primary,
                                side: const BorderSide(
                                    color: QaboolTheme.primary, width: 2),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Sign Up Now',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 24),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Already have an account? ',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(context,
                                        '/signup'); // Or pop depending on desired flow
                                  },
                                  child: const Text(
                                    'Sign In',
                                    style: TextStyle(
                                      color: QaboolTheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Visual Element (Large Screen Only)
          if (isLargeScreen)
            Expanded(
              flex: 1,
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuDwOsb2tTh6jwLW0Qqp3VyLDqDik4kWO2AfCDdp_s0pDmZ8MnT--MRJOJwyw7w7GdBg-yN4nyZaYAhNyTdQmQEyJNsMyqN16ErJmj1dyBlqo5lt2NftAWPaxNl7BaNu0UvjEYWX5ZOtCN5NzfLAk3dtRKdjnzPQSVMJg0S8c9cAQ9g49tT3ZqToAKewFWisGoRccY7eAjch8Mx4xJsveCYrFNPv1wKhwTAJWMeMfG6ovThdUBGykgi3zaQAFQAxPrY8eeyTgcXVSkDD'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  color: QaboolTheme.primary.withOpacity(0.2),
                  padding: const EdgeInsets.all(48),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Start your journey on Qabool',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: QaboolTheme.primary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '"Love is not about finding the perfect person, but by learning to see an imperfect person perfectly."',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF334155),
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: QaboolTheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Trusted by Millions',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    'Verified matrimony profiles',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
    );
  }
}
