import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'screens/auth/splash_screen.dart';
import 'utils/app_colors.dart';
import 'utils/constants.dart';

void main() async {
  //internal connection between Dart code and the actual device 
  //before certain platform operations can run
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  //Configuration of top status bar and bottom navigation bar, 
  //including color and icon brightness
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      // Automatically selects the appropriate Firebase configuration 
      //based on the current platform (iOS, Android, Web, etc.)
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init note: $e');
  }

  // Start the flutter Interface
  // HostelGatePassApp is the root widget of the application, which is
  // a stateless widget that defines the overall structure and theme of the app.
  runApp(const HostelGatePassApp());
}

// this is the root widgetof the application.
//It is the stateless widget that defines the overall structure and theme of the app.
class HostelGatePassApp extends StatelessWidget {
  const HostelGatePassApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(Theme.of(context).textTheme);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          surfaceContainerLowest: AppColors.background,
        ),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: textTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          titleTextStyle: GoogleFonts.plusJakartaSans(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.statusRejected, width: 1.5),
          ),
          hintStyle: TextStyle(
            color: AppColors.textMuted,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// Summary of the code : 
// Responsibilities of main.dart : 
// 1. Prepare Flutter.
// 2. Configure the device status bar.
// 3. Initialize Firebase.
// 4. Define global visual rules (theme, colors, fonts, component defaults).
// 5. Launch the splash screen.