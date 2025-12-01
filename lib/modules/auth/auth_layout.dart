import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // ✅ Tambahkan ini

import '../../widgets/base_screen.dart';

class AuthLayout extends StatelessWidget {
  final String title;
  final String desc;
  final Widget formField;
  final double marginTop;
  final bool showBackButton;
  final VoidCallback? onBack;
  const AuthLayout({
    super.key,
    required this.title,
    required this.desc,
    required this.formField,
    required this.marginTop,
    this.showBackButton = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;

    return BaseScreen(
      appBar: showBackButton
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: onBack ?? () => Navigator.pop(context),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              foregroundColor: Colors.white,
            )
          : null,
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      horizontalPadding: 0,
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A7AC1), Color(0xFF0E5FAF), Color(0xFF113A73)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, marginTop, 24, 24 + viewInsets),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AuthHeader(title: title, desc: desc),
                const SizedBox(height: 24),
                _FormContainer(child: formField),
                const SizedBox(height: 12),
                const _SupportContact(), // ✅ sudah kita ubah
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthHeader extends StatelessWidget {
  const _AuthHeader({required this.title, required this.desc});

  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.verified_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Terhubung dengan tenaga kesehatan',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          desc,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            _HeaderChip(label: 'Data Aman'),
            _HeaderChip(label: 'Realtime'),
            _HeaderChip(label: 'Support 24/7'),
          ],
        ),
      ],
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FormContainer extends StatelessWidget {
  const _FormContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SupportContact extends StatelessWidget {
  const _SupportContact();

  /// ✅ Fungsi untuk buka WhatsApp
  Future<void> _openWhatsApp(BuildContext context) async {
    const phone = "6285879571393";
    final message = Uri.encodeComponent(
      "Halo! Saya butuh bantuan dengan aplikasi Smart Stroke.",
    );
    final url = Uri.parse("https://wa.me/$phone?text=$message");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Gagal membuka WhatsApp")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Ada kendala saat masuk?',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => _openWhatsApp(context),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(
                0.25,
              ), // 💚 hijau agar khas WhatsApp
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.support_agent, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Hubungi via WhatsApp',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
