import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../modules/consultation/consultation_screen.dart';

class ChatHelper {
  static Future<void> openChatWithPharmacist({
    required BuildContext context,
    required String pharmacistId,
    required String pharmacistName,
  }) async {
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;
    
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu')),
      );
      return;
    }

    try {
      // Cek apakah room sudah ada
      final existing = await supabase
          .from('chat_rooms')
          .select('id')
          .eq('patient_id', currentUser.id)
          .eq('pharmacist_id', pharmacistId)
          .maybeSingle();

      String roomId;
      if (existing != null) {
        roomId = existing['id'].toString();
      } else {
        // Buat room baru
        final newRoom = await supabase
            .from('chat_rooms')
            .insert({
              'patient_id': currentUser.id,
              'pharmacist_id': pharmacistId,
            })
            .select('id')
            .single();
        roomId = newRoom['id'].toString();
      }

      // Navigate ke chat room
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ConsultationScreen(
              roomId: roomId,
              recipientId: pharmacistId,
              recipientName: pharmacistName,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka chat: $e')),
        );
      }
    }
  }
}

