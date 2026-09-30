//================================================================
//                  Uses of this splash Screen : 
// 1. The branded loading screen the user sees first, and
// 2. A checkpoint that decides where the user should go next.

// It has a main flow, like where user will go next, like Login page, Student Dashboard, Warden Dashboard, etc.
//================================================================

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../widgets/app_logo.dart';
import '../student/student_dashboard.dart';
import '../warden/warden_dashboard.dart';
import 'login_screen.dart';

// It is statefull because we have an loading animation. else we can use stateless widget if we have to use an image only.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  String? _errorMessage;
  late AnimationController _loaderController;

  @override
  void initState() {
    super.initState();
    _loaderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    )..repeat();
    _checkAuthState();
  }

  // stops and destroys the animation controller, preventing memory/resource leaks.
  @override
  void dispose() {
    _loaderController.dispose();
    super.dispose();
  }

  // After the splash screen is shown then user should be navigated it is decided by this function.
  Future<void> _checkAuthState() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 1200));
      final currentUser = _authService.currentUser;

      if (currentUser == null) {
        _navigateToLogin();
        return;
      }

      final userModel = await _authService.getUserProfile(currentUser.uid);

      if (!mounted) return;

      if (userModel == null) {
        await _authService.signOut();
        _navigateToLogin();
        return;
      }

      if (userModel.isWarden) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const WardenDashboard()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const StudentDashboard()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to verify session. Please check your connection.';
        });
      }
    }
  }

  void _navigateToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo mark matching logo.svg
                  const AppLogo(
                    size: 80,
                    isDarkBackground: true,
                    borderRadius: 20,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'HOSTELGO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppConstants.appTagline,
                    style: TextStyle(
                      color: Colors.white.withAlpha((0.8 * 255).round()),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),

                  if (_errorMessage != null) ...[
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _checkAuthState,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ] else ...[
                    // Smooth animated loading line matching CSS .loader-bar
                    Container(
                      width: 52,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha((0.2 * 255).round()),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: AnimatedBuilder(
                        animation: _loaderController,
                        builder: (context, child) {
                          return Align(
                            alignment: Alignment(
                              -1.5 + (_loaderController.value * 3.0),
                              0.0,
                            ),
                            child: Container(
                              width: 22,
                              height: 4,
                              decoration: BoxDecoration(
                                color: const Color(0xFF99F6E4), // Mint accent
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const Positioned(
            bottom: 36,
            left: 0,
            right: 0,
            child: Text(
              'Hostel Outing Requests',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
