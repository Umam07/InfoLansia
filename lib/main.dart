import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'constants/supabase_config.dart';
import 'theme.dart';
import 'screens/welcome_screen.dart';
import 'screens/dashboard_screen.dart';

import 'services/kader_auth_service.dart';
import 'services/network_connectivity_service.dart';
import 'services/sync_service.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
  );

  // Inisialisasi listener koneksi & auto-sync saat koneksi pulih
  await NetworkConnectivityService.instance.initialize(
    onRestored: () {
      debugPrint('[Main] Jaringan pulih, memulai sinkronisasi otomatis...');
      SyncService.instance.syncAll();
    },
  );

  final session = Supabase.instance.client.auth.currentSession;
  bool showDashboard = false;

  if (session != null && session.user.email != null) {
    // 1. Cek apakah kader telah terverifikasi secara lokal (Offline-friendly)
    final isVerifiedLocally = await KaderAuthService.isKaderVerifiedLocally();
    if (isVerifiedLocally) {
      showDashboard = true;
      // Picu re-validasi di latar belakang saat online (deteksi kader dinonaktifkan admin)
      KaderAuthService.revalidateCurrentKader();
    } else {
      // 2. Jika sesi ada tapi belum ada cache lokal, coba validasi online sekali
      final validation =
          await KaderAuthService.validateKaderOnline(session.user.email!);
      if (validation.isAllowed) {
        showDashboard = true;
      } else {
        await Supabase.instance.client.auth.signOut();
        try {
          await GoogleSignIn.instance.signOut();
        } catch (_) {}
      }
    }
  }

  // Pre-cache semua varian Google Fonts yang dipakai di app
  // agar tidak ada network request saat widget rebuild (keyboard muncul)
  await _prefetchFonts();
  
  runApp(MyApp(showDashboard: showDashboard));
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
  final bool showDashboard;
  const MyApp({super.key, required this.showDashboard});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Info Lansia',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: showDashboard ? const DashboardScreen() : const WelcomeScreen(),
    );
  }
}

