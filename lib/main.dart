import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/user/home_screen.dart';
import 'screens/admin/admin_home.dart';
import 'services/auth_service.dart';
import 'utils/constants.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Absensi Triple DES Offline',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: AppConstants.primaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.primaryColor,
          primary: AppConstants.primaryColor,
          secondary: AppConstants.secondaryColor,
          surface: AppConstants.backgroundColor,
        ),
        scaffoldBackgroundColor: AppConstants.backgroundColor,
        cardColor: AppConstants.cardColor,
        // Premium modern fonts and configurations
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(elevation: 0, centerTitle: true),
      ),
      home: const AuthSessionChecker(),
    );
  }
}

/// Helper Widget to automatically check user session and redirect on startup
class AuthSessionChecker extends StatefulWidget {
  const AuthSessionChecker({Key? key}) : super(key: key);

  @override
  State<AuthSessionChecker> createState() => _AuthSessionCheckerState();
}

class _AuthSessionCheckerState extends State<AuthSessionChecker> {
  final _authService = AuthService();
  bool _checkingSession = true;
  Widget _targetScreen = const LoginScreen();

  @override
  void initState() {
    super.initState();
    _checkActiveSession();
  }

  void _checkActiveSession() async {
    try {
      final user = await _authService.getUserSession();
      if (user != null) {
        if (user.isAdmin) {
          _targetScreen = const AdminHomeScreen();
        } else {
          _targetScreen = const UserHomeScreen();
        }
      }
    } catch (_) {
      // Keep target as LoginScreen
    } finally {
      setState(() {
        _checkingSession = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSession) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppConstants.primaryColor),
              SizedBox(height: 16),
              Text(
                "Memeriksa Sesi...",
                style: TextStyle(
                  color: AppConstants.textLight,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _targetScreen;
  }
}
