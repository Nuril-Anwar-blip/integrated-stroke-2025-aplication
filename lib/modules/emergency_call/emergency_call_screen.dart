import 'package:flutter/material.dart';
import 'dart:async';

class EmergencyCallScreen extends StatefulWidget {
  const EmergencyCallScreen({Key? key}) : super(key: key);

  @override
  _EmergencyCallScreenState createState() => _EmergencyCallScreenState();
}

class _EmergencyCallScreenState extends State<EmergencyCallScreen> {
  late Timer _timer;
  int _countdown = 3; // Countdown dimulai dari 3 sesuai gambar
  bool _isCalling = false;

  @override
  void initState() {
    super.initState();

    // Timer untuk mengurangi angka countdown setiap detik
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isCalling = true;
        });
        // TODO: Tambahkan logika untuk memulai panggilan darurat di sini
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black54),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Icon(Icons.favorite, color: Colors.red),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shadowColor: Colors.grey.withOpacity(0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 40.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Judul
                  Text(
                    'Panggilan Darurat',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Ikon-ikon utama
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: const [
                      Icon(
                        Icons.phone_in_talk_rounded,
                        color: Colors.red,
                        size: 48,
                      ),
                      Icon(
                        Icons.local_hospital_rounded,
                        color: Colors.red,
                        size: 48,
                      ),
                      Icon(
                        Icons.family_restroom_rounded,
                        color: Colors.red,
                        size: 48,
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // Tampilan Countdown atau Status Memanggil
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isCalling
                        ? _buildCallingStatus()
                        : _buildCountdownStatus(),
                  ),

                  const SizedBox(height: 48),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Ikon Aksi di Bawah
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget untuk status countdown
  Widget _buildCountdownStatus() {
    return Column(
      key: const ValueKey('countdown'),
      children: [
        const Text(
          'SOS DIMULAI DALAM',
          style: TextStyle(
            fontSize: 18,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: Text(
            '$_countdown',
            key: ValueKey<int>(_countdown), // Kunci penting untuk animasi
            style: TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'DETIK',
          style: TextStyle(
            fontSize: 18,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Widget untuk status "memanggil"
  Widget _buildCallingStatus() {
    return Column(
      key: const ValueKey('calling'),
      children: [
        SizedBox(
          height: 32,
          width: 32,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
        const SizedBox(height: 24),
        Text(
          'Menghubungi Bantuan...',
          style: TextStyle(
            fontSize: 18,
            color: Colors.blue.shade800,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Widget untuk tombol-tombol aksi di bagian bawah
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        IconButton(
          icon: Icon(
            Icons.home_outlined,
            color: Colors.grey.shade600,
            size: 28,
          ),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.mail_outline, color: Colors.grey.shade600, size: 28),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.mic_none, color: Colors.grey.shade600, size: 28),
          onPressed: () {},
        ),
        // Tombol batalkan panggilan dibuat lebih menonjol
        InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: () {
            _timer.cancel(); // Membatalkan timer jika ditekan
            Navigator.of(context).pop();
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red,
            ),
            child: const Icon(Icons.call_end, color: Colors.white, size: 28),
          ),
        ),
      ],
    );
  }
}
