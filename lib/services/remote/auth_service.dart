import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';
import '../local/auth_local_service.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  /// Login user and insert pending profile if exists.
  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session != null) {
        await AuthLocalService.setLoggedIn(true);
        await _insertPendingProfileIfExists();
      }

      return response;
    } on AuthException catch (e) {
      throw Exception('Email atau password salah: ${e.message}');
    } catch (e) {
      throw Exception('Gagal melakukan login: $e');
    }
  }

  /// Register user. If signUp returns a session, insert profile immediately.
  /// If signUp does not return a session (email confirmation flow), save pending
  /// profile locally and insert after the user logs in.
  Future<AuthResponse> register({
    required UserModel user,
    required String password,
    String? pharmacistCode,
  }) async {
    final role = (pharmacistCode != null && pharmacistCode.isNotEmpty)
        ? 'apoteker'
        : 'pasien';

    try {
      dynamic invitationId;
      final String? trimmedCode = pharmacistCode?.trim();
      if (role == 'apoteker' && trimmedCode != null && trimmedCode.isNotEmpty) {
        Map<String, dynamic>? invitation;
        final candidateColumns = <String>[
          'code',
          'token',
          'invite_code',
          'admin_token',
          'kode',
          'kode_token',
          'registration_code',
        ];

        for (final col in candidateColumns) {
          try {
            final List<dynamic> rows = await _supabase
                .from('pharmacist_invitations')
                .select('id')
                .eq(col, trimmedCode)
                .eq('is_used', false)
                .limit(1);
            if (rows.isNotEmpty) {
              invitation = Map<String, dynamic>.from(rows.first as Map);
              break;
            }
          } catch (_) {}
        }

        if (invitation == null) {
          throw Exception(
            'Kode registrasi apoteker tidak valid atau sudah digunakan.',
          );
        }
        invitationId = invitation['id'];
      }

      final authResponse = await _supabase.auth.signUp(
        email: user.email,
        password: password,
      );

      if (authResponse.user != null) {
        final Map<String, dynamic> profileData = user.toMap()
          ..addAll({'role': role});

        if (authResponse.session != null) {
          // session available -> can insert now
          profileData['id'] = authResponse.user!.id;
          await _supabase.from('users').insert(profileData);
          if (role == 'apoteker' &&
              trimmedCode != null &&
              trimmedCode.isNotEmpty) {
            if (invitationId != null) {
              try {
                await _supabase
                    .from('pharmacist_invitations')
                    .update({'is_used': true})
                    .eq('id', invitationId);
              } catch (_) {}
            } else {
              for (final col in [
                'code',
                'token',
                'invite_code',
                'admin_token',
                'kode',
                'kode_token',
                'registration_code',
              ]) {
                try {
                  final updated = await _supabase
                      .from('pharmacist_invitations')
                      .update({'is_used': true})
                      .eq(col, trimmedCode)
                      .eq('is_used', false)
                      .select();
                  if (updated is List && updated.isNotEmpty) {
                    break;
                  }
                } catch (_) {}
              }
            }
          }
          await AuthLocalService.setLoggedIn(true);
        } else {
          // no session -> save pending and insert after login
          await _savePendingProfile(profileData);
        }
      }

      return authResponse;
    } on AuthException catch (e) {
      throw Exception('Gagal mendaftar: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  /// Sign out user
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    await AuthLocalService.clearLogin();
  }

  /// Save pending profile locally (used when signUp requires email confirmation)
  Future<void> _savePendingProfile(Map<String, dynamic> profileData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_profile', jsonEncode(profileData));
    } catch (e) {
      // ignore silently, not critical
    }
  }

  /// If a pending profile exists locally and user is authenticated, insert it.
  Future<void> _insertPendingProfileIfExists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pending = prefs.getString('pending_profile');
      if (pending == null) return;

      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;

      final Map<String, dynamic> profileData = Map<String, dynamic>.from(
        jsonDecode(pending),
      );
      profileData['id'] = currentUser.id;

      // check existing profile
      final existing = await _supabase
          .from('users')
          .select()
          .eq('id', currentUser.id)
          .maybeSingle();
      if (existing == null) {
        await _supabase.from('users').insert(profileData);
      }

      await prefs.remove('pending_profile');
    } catch (e) {
      // log but don't crash
      print('Failed to insert pending profile: $e');
    }
  }

  /// Pairing helper (kept from original code)
  Future<dynamic> pairWatch({
    required String pairingCode,
    required String refreshToken,
    required String userId,
  }) async {
    try {
      final existingUser = await _supabase
          .from('pairings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (existingUser != null) {
        if (existingUser['pairing_code'] != pairingCode) {
          final targetRow = await _supabase
              .from('pairings')
              .select()
              .eq('pairing_code', pairingCode)
              .maybeSingle();

          if (targetRow != null) {
            await _supabase.from('pairings').delete().eq("user_id", userId);

            final response = await _supabase
                .from('pairings')
                .update({"user_id": userId, "refresh_token": refreshToken})
                .eq("pairing_code", pairingCode)
                .select();
            return response;
          } else {
            final response = await _supabase
                .from('pairings')
                .update({
                  "pairing_code": pairingCode,
                  "refresh_token": refreshToken,
                })
                .eq("user_id", userId)
                .select();
            return response;
          }
        } else {
          final response = await _supabase
              .from('pairings')
              .update({"refresh_token": refreshToken})
              .eq("user_id", userId)
              .select();
          return response;
        }
      } else {
        final response = await _supabase
            .from('pairings')
            .update({"refresh_token": refreshToken, "user_id": userId})
            .eq("pairing_code", pairingCode)
            .select();
        return response;
      }
    } catch (e) {
      rethrow;
    }
  }
}
