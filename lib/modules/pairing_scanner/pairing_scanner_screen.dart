import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

import '../../services/remote/auth_service.dart';
import '../../supabase/supabase_client.dart';
import '../../widgets/pop_up_loading.dart';

class PairingScannerScreen extends StatefulWidget {
  const PairingScannerScreen({super.key});

  @override
  State<PairingScannerScreen> createState() => _PairingScannerScreenState();
}

class _PairingScannerScreenState extends State<PairingScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isProcessing = false;
  final _authService = AuthService();

  @override
  void reassemble() {
    super.reassemble();
    controller?.pauseCamera();
    controller?.resumeCamera();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (_isProcessing) return;
      setState(() => _isProcessing = true);

      final pairingCode = scanData.code;
      if (pairingCode == null || pairingCode.isEmpty) {
        setState(() => _isProcessing = false);
        return;
      }

      try {
        final user = SupabaseManager.client.auth.currentUser;
        final session = SupabaseManager.client.auth.currentSession;

        // ✅ Cek login state
        if (user == null || session == null) {
          throw Exception("User belum login di aplikasi mobile.");
        }

        final userId = user.id;
        final refreshToken = session.refreshToken ?? '';

        // ✅ Pastikan refreshToken tidak kosong
        if (refreshToken.isEmpty) {
          throw Exception(
            "Refresh token tidak ditemukan. Silakan login ulang.",
          );
        }

        final response = await _authService.pairWatch(
          pairingCode: pairingCode,
          refreshToken: refreshToken,
          userId: userId,
        );

        if (!mounted) return;
        if (response != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Smartwatch berhasil terhubung!')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Gagal pairing, coba lagi.')),
          );
        }
      } catch (e) {
        log("❌ Gagal pairing: $e");
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal pairing: $e')));
      }

      setState(() => _isProcessing = false);
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan QR Smartwatch")),
      body: Stack(
        children: [
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: Colors.blueAccent,
              borderRadius: 10,
              borderLength: 25,
              borderWidth: 8,
              cutOutSize: 250,
            ),
          ),
          if (_isProcessing) const Center(child: PopUpLoading()),
        ],
      ),
    );
  }
}
