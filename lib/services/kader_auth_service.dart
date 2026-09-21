import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

class KaderAuthResult {
  final bool isAllowed;
  final String? errorMessage;
  final Map<String, dynamic>? kaderData;

  const KaderAuthResult({
    required this.isAllowed,
    this.errorMessage,
    this.kaderData,
  });
}

class KaderAuthService {
  static const String _prefIsVerified = 'kader_is_verified';
  static const String _prefEmail = 'kader_email';
  static const String _prefNama = 'kader_nama';
  static const String _prefPeran = 'kader_peran';
  static const String _prefPosyanduId = 'kader_posyandu_id';
  static const String _prefLastVerifiedAt = 'kader_last_verified_at';

  /// Validasi email kader ke tabel kader_terdaftar di Supabase
  static Future<KaderAuthResult> validateKaderOnline(String email) async {
    try {
      final cleanEmail = email.trim().toLowerCase();
      final response = await Supabase.instance.client
          .from('kader_terdaftar')
          .select()
          .ilike('email', cleanEmail)
          .maybeSingle();

      if (response == null) {
        return const KaderAuthResult(
          isAllowed: false,
          errorMessage:
              'Email Anda belum terdaftar sebagai kader. Hubungi admin Posyandu Sakura untuk pendaftaran.',
        );
      }

      final bool statusAktif = response['status_aktif'] == true;
      if (!statusAktif) {
        return const KaderAuthResult(
          isAllowed: false,
          errorMessage:
              'Status kader Anda saat ini nonaktif. Silakan hubungi Bidan Pembina atau Admin Posyandu Sakura.',
        );
      }

      // Simpan status verifikasi ke penyimpanan lokal untuk sesi offline
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefIsVerified, true);
      await prefs.setString(_prefEmail, cleanEmail);
      await prefs.setString(_prefNama, response['nama']?.toString() ?? '');
      await prefs.setString(_prefPeran, response['peran']?.toString() ?? 'kader');
      await prefs.setString(
          _prefPosyanduId, response['posyandu_id']?.toString() ?? 'RW-06-SAKURA');
      await prefs.setString(
          _prefLastVerifiedAt, DateTime.now().toIso8601String());

      return KaderAuthResult(
        isAllowed: true,
        kaderData: response,
      );
    } catch (e) {
      debugPrint('Error validating kader online: $e');
      return KaderAuthResult(
        isAllowed: false,
        errorMessage: 'Terjadi kendala saat memeriksa pendaftaran kader: $e',
      );
    }
  }

  /// Cek apakah pengguna saat ini berstatus kader terverifikasi secara lokal (Offline mode)
  static Future<bool> isKaderVerifiedLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final isVerified = prefs.getBool(_prefIsVerified) ?? false;
    final currentSession = Supabase.instance.client.auth.currentSession;
    return isVerified && currentSession != null;
  }

  /// Ambil data ringkasan kader tersimpan di lokal
  static Future<Map<String, String>> getCachedKaderProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getString(_prefEmail) ?? '',
      'nama': prefs.getString(_prefNama) ?? '',
      'peran': prefs.getString(_prefPeran) ?? 'kader',
      'posyandu_id': prefs.getString(_prefPosyanduId) ?? 'RW-06-SAKURA',
      'last_verified_at': prefs.getString(_prefLastVerifiedAt) ?? '',
    };
  }

  /// Re-validasi status kader saat online (deteksi jika kader dinonaktifkan admin)
  static Future<bool> revalidateCurrentKader() async {
    final currentSession = Supabase.instance.client.auth.currentSession;
    if (currentSession == null || currentSession.user.email == null) {
      await clearLocalSession();
      return false;
    }

    final email = currentSession.user.email!;
    final result = await validateKaderOnline(email);

    if (!result.isAllowed) {
      // Kader telah dinonaktifkan atau dihapus oleh admin!
      await clearLocalSession();
      await Supabase.instance.client.auth.signOut();
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
      return false;
    }

    return true;
  }

  /// Bersihkan data sesi kader lokal
  static Future<void> clearLocalSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefIsVerified);
    await prefs.remove(_prefEmail);
    await prefs.remove(_prefNama);
    await prefs.remove(_prefPeran);
    await prefs.remove(_prefPosyanduId);
    await prefs.remove(_prefLastVerifiedAt);
  }
}
