import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qabool_app/theme.dart';
import 'package:qabool_app/screens/login_screen.dart';
import 'package:qabool_app/screens/sign_up_screen.dart';
import 'package:qabool_app/screens/main_navigation_screen.dart';
import 'package:qabool_app/services/api_service.dart';
import 'package:qabool_app/services/auth_service.dart';
import 'package:qabool_app/services/profile_service.dart';
import 'package:qabool_app/services/chat_service.dart';
import 'package:qabool_app/services/connection_service.dart';
import 'package:qabool_app/widgets/floating_chat_overlay.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final apiService = ApiService();
  final authService = AuthService(apiService);
  final profileService = ProfileService(apiService);
  final chatService = ChatService(apiService);
  final connectionService = ConnectionService(apiService);
  // Set up logout callback to disconnect socket
  // Set up logout callback to disconnect socket and clear states
  authService.onLogout = () {
    chatService.disconnectSocket();
    chatService.clearData();
    connectionService.clearData();
    profileService.clearData(); // If implemented
  };

  // Check initial auth status
  await authService.checkAuthStatus();
  
  // Initialize socket if token exists
  final token = await apiService.getToken();
  if (token != null) {
    chatService.initSocket(token);
  }

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: apiService),
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider.value(value: profileService),
        ChangeNotifierProvider.value(value: chatService),
        ChangeNotifierProvider.value(value: connectionService),
      ],
      child: const QaboolApp(),
    ),
  );
}

class QaboolApp extends StatelessWidget {
  const QaboolApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    
    return MaterialApp(
      title: 'Qabool App',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: QaboolTheme.lightTheme,
      darkTheme: QaboolTheme.darkTheme,
      themeMode: ThemeMode.light,
      builder: (context, child) {
        return FloatingChatOverlay(child: child!);
      },
      initialRoute: authService.isAuthenticated ? '/main' : '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/main': (context) => const MainNavigationScreen(),
      },
    );
  }
}
