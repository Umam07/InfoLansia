import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'constants/supabase_config.dart';
import 'theme.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
  );

  // Pre-cache semua varian Google Fonts yang dipakai di app
  // agar tidak ada network request saat widget rebuild (keyboard muncul)
  await _prefetchFonts();
  
  runApp(const MyApp());
}

/// Pre-fetch all Google Fonts variants used throughout the app
/// so they're cached before any screen needs them.
/// This prevents jank/lag when keyboard appears and widgets rebuild.
Future<void> _prefetchFonts() async {
  // Semua weight yang digunakan di seluruh app
  final weights = [
    FontWeight.w400,
    FontWeight.w500,
    FontWeight.w600,
    FontWeight.w700,
    FontWeight.w800,
  ];

  final List<TextStyle> styles = [];
  for (final weight in weights) {
    // Normal style
    styles.add(GoogleFonts.plusJakartaSans(fontWeight: weight));
    // Italic style
    styles.add(GoogleFonts.plusJakartaSans(fontWeight: weight, fontStyle: FontStyle.italic));
  }

  // Await pendingFonts loading
  await GoogleFonts.pendingFonts(styles);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Posyandu Cloud',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    );
  }
}
